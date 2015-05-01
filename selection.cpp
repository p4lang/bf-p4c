#include "algorithm.h"
#include "input_xbar.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(SelectionTable)

void SelectionTable::setup(VECTOR(pair_t) &data) {
    non_linear_hash = false;
    resilient_hash = false;
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), get(data, "bus"));
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "mode") {
            mode_lineno = kv.value.lineno;
            if (CHECKTYPEPM(kv.value, tCMD, kv.value.vec.size == 2 && kv.value[1].type == tINT,
                            "hash mode and int param"))
            {
                if (kv.value[0] == "resilient")
                    resilient_hash = true;
                else if (kv.value[0] == "fair")
                    resilient_hash = false;
                else error(kv.value.lineno, "Unknown hash mode %s", kv.value[0].s);
                param = kv.value[1].i; }
        } else if (kv.key == "non_linear") {
            non_linear_hash = get_bool(kv.value);
        } else if (kv.key == "per_flow_enable") {
            per_flow_enable = get_bool(kv.value);
        } else if (kv.key == "pool_sizes") {
            if (CHECKTYPE(kv.value, tVEC))
                for (value_t &v : kv.value.vec)
                    if (CHECKTYPE(v, tINT))
                        pool_sizes.push_back(v.i);
        } else if (kv.key == "p4_table") {
            if (CHECKTYPE(kv.value, tSTR))
                p4_table = kv.value.s;
        } else if (kv.key == "p4_table_size") {
            if (CHECKTYPE(kv.value, tINT))
                p4_table_size = kv.value.i;
        } else if (kv.key == "handle") {
            if (CHECKTYPE(kv.value, tINT))
                handle = kv.value.i;
        } else if (kv.key == "row" || kv.key == "logical_row" ||
                   kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use);
}

void SelectionTable::pass1() {
    LOG1("### Selection table " << name() << " pass1");
    if (layout.size() != 1 || layout[0].cols.size() != 1)
        error(layout[0].lineno, "Select table with more than 1 RAM not supported");
    alloc_vpns();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    stage->table_use[gress] |= Stage::USE_SELECTOR;
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, 128);
    if (param < 0 || param > (resilient_hash ? 7 : 2))
        error(mode_lineno, "Invalid %s hash param %d",
              resilient_hash ? "resilient" : "fair", param);
    min_words = INT_MAX;
    max_words = 0;
    if (pool_sizes.empty()) min_words = max_words = 1;
    else for (int size : pool_sizes) {
        int words = (size + 119)/120;
        if (words < min_words) min_words = words;
        if (words > max_words) max_words = words; }
}

void SelectionTable::pass2() {
    LOG1("### Selection table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, 128);
}

void SelectionTable::write_merge_regs(int type, int bus, Table *action, bool indirect) {
    auto &merge = stage->regs.rams.match.merge;
    merge.mau_selector_action_entry_size[type][bus] = action->format->log2size - 3;
    merge.mau_bus_hash_group_ctl[type][bus/4] |= 0; // FIXME
    merge.mau_meter_adr_type_position[type][bus] = 24;
    if (indirect) {
        int bits = per_flow_enable ? 17 : 16;
        /* FIXME -- regs need to stabilize */
        merge.mau_meter_adr_mask[type][bus] = ((1U << bits) - 1) << 7;
    }
    merge.mau_meter_adr_default[type][bus] = (4U << 24) | (per_flow_enable ? 0 : (1U << 23));
    if (per_flow_enable) {
        /* FIXME -- regs need to stabilize */
        merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = 23;
    }
}

void SelectionTable::write_regs() {
    LOG1("### Selection table " << name() << " write_regs");
    if (input_xbar) input_xbar->write_regs();
    Layout *home = &layout[0];
    unsigned logical_row_use = 0;
    bool push_on_overflow = false;
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        auto vpn = logical_row.vpns.begin();
        auto &map_alu =  stage->regs.rams.map_alu;
        auto &map_alu_row =  map_alu.row[row];
        unsigned meter_group = row/2;
        // FIXME meter_group based stuff should only be set once (on the home row?)
        // FIXME rather than for every column of every row
        logical_row_use |= 1U << logical_row.row;
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[col];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::NONE;
            ram.unit_ram_ctl.match_ram_read_data_mux_select = UnitRam::DataMux::STATISTICS;
            unitram_config.unitram_type = UnitRam::SELECTOR;
            unitram_config.unitram_vpn = *vpn++;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;
            auto &vh_adr_xbar = stage->regs.rams.array.row[row].vh_adr_xbar;
            vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + logical_row.bus]
                .enabled_3bit_muxctl_select = input_xbar->hash_group();
            vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + logical_row.bus]
                .enabled_3bit_muxctl_enable = 1;
            vh_adr_xbar.alu_hashdata_bytemask.alu_hashdata_bytemask_right =
                bitmask2bytemask(input_xbar->hash_group_bituse());
            auto &selector_ctl = map_alu.meter_group[meter_group].selector.selector_alu_ctl;
            selector_ctl.sps_nonlinear_hash_enable = non_linear_hash ? 1 : 0;
            if (resilient_hash)
                selector_ctl.resilient_hash_enable = param;
            else
                selector_ctl.selector_fair_hash_select = param;
            selector_ctl.resilient_hash_mode = resilient_hash ? 1 : 0;
            selector_ctl.selector_enable = 1;
            auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[meter_group];
            delay_ctl.meter_alu_right_group_delay = 
                stage->table_use[gress] & Stage::USE_TCAM ? 13 : 9;
            delay_ctl.meter_alu_right_group_enable = resilient_hash ? 3 : 1;
            delay_ctl.meter_alu_right_group_sel = 1;
            auto &ram_address_mux_ctl = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            ram_address_mux_ctl.ram_unitram_adr_mux_select = UnitRam::AdrMux::STATS_METERS;
            if (&logical_row == home) {
                ram_address_mux_ctl.ram_stats_meter_adr_mux_select_meter = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            } else {
                ram_address_mux_ctl.ram_oflo_adr_mux_select_oflo = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_oflo = 1; }
        }
        if (&logical_row != home) {
            auto &adr_ctl = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if (home->row >= 8 && logical_row.row < 8) {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = 0;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::OVERFLOW;
                push_on_overflow = true;
            } else {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = home->row % 8;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::METER; }
            adr_ctl.adr_dist_oflo_adr_xbar_enable = 1; } }
    for (MatchTable *m : match_tables) {
        auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id];
        icxbar.address_distr_to_logical_rows = logical_row_use;
        icxbar.address_distr_to_overflow = push_on_overflow;
    }
}

void SelectionTable::gen_tbl_cfg(json::vector &out) {
}
