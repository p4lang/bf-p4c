#include "algorithm.h"
#include "input_xbar.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(CounterTable)

void CounterTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(fmt->map);
    } else
        error(lineno, "No format specified in table %s", name());
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            /* done above to be done before vpns */
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec, true);
        } else if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::Statistics, kv.value.map);
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else if (kv.key == "maprams") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_maprams(&kv.value.vec);
        } else if (kv.key == "count") {
            if (kv.value == "bytes")
                type = BYTES;
            else if (kv.value == "packets")
                type = PACKETS;
            else if (kv.value == "both" || kv.value == "packets_and_bytes")
                type = BOTH;
            else error(kv.value.lineno, "Unknown counter type %s", value_desc(kv.value));
        } else if (kv.key == "per_flow_enable") {
            per_flow_enable = get_bool(kv.value);
        } else if (kv.key == "row" || kv.key == "logical_row" ||
                   kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    if (p4_info.size) {
        if (p4_table)
            error(p4_info[0].key.lineno, "old and new p4 table info in %s", name());
        else
            p4_table = P4Table::get(P4Table::Statistics, p4_info); }
    fini(p4_info);
    alloc_rams(true, stage->sram_use);
}

void CounterTable::pass1() {
    LOG1("### Counter table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Statistics, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    //stage->table_use[gress] |= Stage::USE_SELECTOR;
    int prev_row = -1;
    for (auto &row : layout) {
        if (prev_row >= 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        else
            need_bus(lineno, stage->stats_bus_use, row.row, "Statistics data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        prev_row = row.row; }
}

void CounterTable::pass2() {
    LOG1("### Counter table " << name() << " pass2");
}

static int counter_masks[] = { 0, 7, 3, 4, 1, 0, 0 };
static int counter_shifts[] = { 0, 3, 2, 2, 1, 0, 2 };

int CounterTable::direct_shiftcount() {
    return 64 + 7 - counter_shifts[format->groups()];
}

void CounterTable::write_merge_regs(int type, int bus) {
    auto &merge =  stage->regs.rams.match.merge;
    merge.mau_stats_adr_mask[type][bus] = 0xfffff & ~counter_masks[format->groups()];
    merge.mau_stats_adr_default[type][bus] = per_flow_enable ? 0 : (1U << 19);
    if (per_flow_enable)
        merge.mau_stats_adr_per_entry_en_mux_ctl[type][bus] = 19;
}

void CounterTable::write_regs() {
    LOG1("### Counter table " << name() << " write_regs");
    // FIXME -- factor common AttachedTable::write_regs
    // FIXME -- factor common StatsTable::write_regs
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  stage->regs.rams.map_alu;
    auto &swbox = stage->regs.rams.array.switchbox.row;
    unsigned prev_row = home->row/2U;
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2U;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        assert(side == 1);      /* no map rams or alus on left side anymore */
        /* FIXME factor vpn/mapram stuff with selection.cpp */
        auto vpn = logical_row.vpns.begin();
        int maxvpn = -1;
        if (options.match_compiler)
            maxvpn = layout_size() - 1;
        else
            for (auto v : logical_row.vpns) if (v > maxvpn) maxvpn = v;
        auto mapram = logical_row.maprams.begin();
        auto &map_alu_row =  map_alu.row[row];
        int syn2port_bus = &logical_row == home ? 0 : 1;
        auto &syn2port_members = map_alu_row.i2portctl.synth2port_hbus_members[syn2port_bus][side];
        auto &syn2port_ctl = map_alu_row.i2portctl.synth2port_fabric_ctl[0][side];
        while (prev_row != row) {
            auto &prev_syn2port_ctl=map_alu.row[prev_row].i2portctl.synth2port_fabric_ctl[0][side];
            if (prev_row == home->row/2U) {
                swbox[prev_row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_stats_wr_r_i = 1;
                map_alu.row[prev_row].wadr_swbox.ctl.b_oflo_wadr_o_mux_select
                    .b_oflo_wadr_o_sel_r_stats_wadr_i = 1;
                prev_syn2port_ctl.stats_to_vbus_below = 1;
            } else {
                swbox[prev_row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_b_i = 1;
                swbox[prev_row].ctl.b_oflo_wr_o_mux_select.b_oflo_wr_o_sel_oflo_wr_t_i = 1;
                map_alu.row[prev_row].wadr_swbox.ctl.b_oflo_wadr_o_mux_select
                    .b_oflo_wadr_o_sel_t_oflo_wadr_i = 1;
                prev_syn2port_ctl.synth2port_connect_below2above = 1; }
            prev_syn2port_ctl.synth2port_connect_below = 1;
            if (--prev_row == row) {
                swbox[row].ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_r_i = 1;
                swbox[row].ctl.r_oflo_wr_o_mux_select = 1;
                map_alu.row[prev_row].wadr_swbox.ctl.r_oflo_wadr_o_mux_select = 1;
                syn2port_ctl.oflo_to_vbus_above = 1;
                syn2port_ctl.synth2port_connect_above = 1; } }
        for (int logical_col : logical_row.cols) {
            unsigned sram_col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[sram_col];
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::STATISTICS;
            ram.unit_ram_ctl.match_ram_read_data_mux_select = &logical_row == home
                ? UnitRam::DataMux::STATISTICS : UnitRam::DataMux::OVERFLOW;
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            unitram_config.unitram_type = UnitRam::STATISTICS;
            if (!options.match_compiler) // FIXME -- compiler doesn't set this?
                unitram_config.unitram_vpn = *vpn;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;

            auto &ram_address_mux_ctl = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            ram_address_mux_ctl.ram_unitram_adr_mux_select = UnitRam::AdrMux::STATS_METERS;
            if (&logical_row == home) {
                ram_address_mux_ctl.ram_stats_meter_adr_mux_select_stats = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            } else {
                ram_address_mux_ctl.ram_oflo_adr_mux_select_oflo = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_oflo = 1; }
            ram_address_mux_ctl.map_ram_wadr_mux_select = MapRam::Mux::SYNTHETIC_TWO_PORT;
            ram_address_mux_ctl.map_ram_wadr_mux_enable = 1;
            ram_address_mux_ctl.map_ram_radr_mux_select_smoflo = 1;

            syn2port_members |= 1U << logical_col;

            auto &mapram_config = map_alu_row.adrmux.mapram_config[*mapram];
            auto &mapram_ctl = map_alu_row.adrmux.mapram_ctl[*mapram++];
            mapram_config.mapram_type = MapRam::STATISTICS;
            mapram_config.mapram_vpn_members = 0;
            if (!options.match_compiler) // FIXME -- compiler doesn't set this?
                mapram_config.mapram_vpn = *vpn;
            if (gress == INGRESS)
                mapram_config.mapram_ingress = 1;
            else
                mapram_config.mapram_egress = 1;
            mapram_config.mapram_enable = 1;
            //if (!options.match_compiler) // FIXME -- compiler doesn't set this?
                mapram_ctl.mapram_vpn_limit = maxvpn;
            ++vpn; }
        if (&logical_row == home) {
            swbox[row].ctl.r_stats_alu_o_mux_select.r_stats_alu_o_sel_stats_rd_r_i = 1;
            auto &stat_ctl = map_alu.stats_wrap[row/2].stats.statistics_ctl;
            stat_ctl.stats_entries_per_word = format->groups();
            if (type & BYTES) stat_ctl.stats_process_bytes = 1;
            if (type & PACKETS) stat_ctl.stats_process_packets = 1;
            stat_ctl.lrt_enable = 0;
            if (gress == EGRESS) stat_ctl.stats_alu_egress = 1;
        } else {
            auto &adr_ctl = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if (home->row >= 8 && logical_row.row < 8) {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = 0;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::OVERFLOW;
                push_on_overflow = true;
            } else {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = home->row % 8;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::STATISTICS; }
            adr_ctl.adr_dist_oflo_adr_xbar_enable = 1;
        }
    }
    for (MatchTable *m : match_tables) {
        auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_stats_adr_icxbar_ctl[m->logical_id];
        icxbar.address_distr_to_logical_rows = 1U << home->row;
        icxbar.address_distr_to_overflow = push_on_overflow;
    }
}

void CounterTable::gen_tbl_cfg(json::vector &out) {
    int size = (layout_size() - 1)*1024*format->groups();
    json::map &tbl = *base_tbl_cfg(out, "statistics", size);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "statistics", size);
    stage_tbl["how_referenced"] = indirect ? "indirect" : "direct";
    add_pack_format(stage_tbl, 128, 1, format->groups());
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(true);
    stage_tbl["stage_table_handle"] = 0L;
    tbl.erase("p4_selection_tables");
    tbl.erase("p4_action_data_tables");
    switch (type) {
    case PACKETS: tbl["statistics_type"] = "packets"; break;
    case BYTES: tbl["statistics_type"] = "bytes"; break;
    case BOTH: tbl["statistics_type"] = "packets_and_bytes"; break;
    default: break; }
}
