#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(SelectionTable)

void SelectionTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), get(data, "bus"));
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
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
        } else if (kv.key == "selection_hash") {
            if (CHECKTYPE(kv.value, tINT))
                selection_hash = kv.value.i;
        } else if (kv.key == "hash_dist") {
            HashDistribution::parse(hash_dist, kv.value);
            if (hash_dist.size() > 1)
                error(kv.key.lineno, "More than one hast_dist in a selection table not supported");
        } else if (kv.key == "maprams") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_maprams(&kv.value.vec);
        } else if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::Selection, kv.value.map);
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
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
            p4_table = P4Table::get(P4Table::Selection, p4_info); }
    fini(p4_info);
    alloc_rams(true, stage->sram_use);
}

void SelectionTable::pass1() {
    LOG1("### Selection table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Selection, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    if (param < 0 || param > (resilient_hash ? 7 : 2))
        error(mode_lineno, "Invalid %s hash param %d",
              resilient_hash ? "resilient" : "fair", param);
    min_words = INT_MAX;
    max_words = 0;
    if (pool_sizes.empty()) min_words = max_words = 1;
    else for (int size : pool_sizes) {
        int words = (size + SELECTOR_PORTS_PER_WORD - 1)/SELECTOR_PORTS_PER_WORD;
        if (words < min_words) min_words = words;
        if (words > max_words) max_words = words; }
    stage->table_use[gress] |= Stage::USE_SELECTOR;
    if (max_words > 1) {
        stage->table_use[gress] |= Stage::USE_WIDE_SELECTOR;
        for (auto &hd : hash_dist)
            hd.xbar_use = HashDistribution::HASHMOD_DIVIDEND; }
    for (auto &hd : hash_dist)
        hd.pass1(this);
}

void SelectionTable::pass2() {
    LOG1("### Selection table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    if (selection_hash < 0 && (selection_hash = input_xbar->hash_group()) < 0)
        error(lineno, "No selection_hash in selector table %s", name());
}

void SelectionTable::write_merge_regs(MatchTable *match, int type, int bus,
    const std::vector<Call::Arg> &args)
{
    auto &merge = stage->regs.rams.match.merge;
    merge.mau_physical_to_meter_alu_ixbar_map[type][bus/8U].set_subfield(
        4 | meter_group(), 3*(bus%8U), 3);
    if (match->action_call())
        /*merge.mau_selector_action_entry_size[type][bus] = match->action_call()->format->log2size - 3*/;
    else if (options.match_compiler)
        return; // compiler skips the rest if no action table
    merge.mau_payload_shifter_enable[type][bus].meter_adr_payload_shifter_en = 1;
    //if (args.size() > 1)
    //    merge.mau_bus_hash_group_ctl[type][bus/4].set_subfield(
    //        1 << BusHashGroup::SELECTOR_MOD, 5 * (bus%4), 5);
    merge.mau_meter_adr_type_position[type][bus] = 24;
    if (match->action_call().args.size() > 1) {
        int bits = per_flow_enable ? 17 : 16;
        /* FIXME -- regs need to stabilize */
        merge.mau_meter_adr_mask[type][bus] = ((1U << bits) - 1) << 7; }
    merge.mau_meter_adr_default[type][bus] = (4U << 24) | (per_flow_enable ? 0 : (1U << 23));
    if (per_flow_enable) {
        /* FIXME -- regs need to stabilize */
        merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = 23; }
    //if (!hash_dist.empty()) {
    //    /* from HashDistributionResourceAllocation.write_config: */
    //    merge.mau_bus_hash_group_sel[type][bus/8].set_subfield(hash_dist[0].id | 8, 4*(bus%8), 4); }
}

void SelectionTable::write_regs() {
    LOG1("### Selection table " << name() << " write_regs");
    if (input_xbar) input_xbar->write_regs();
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  stage->regs.rams.map_alu;
    DataSwitchboxSetup swbox(stage, home->row/2U);
    int minvpn = 1000000, maxvpn = -1;
    if (options.match_compiler) {
        minvpn = 0;
        maxvpn = layout_size() - 2;
    } else
        for (Layout &logical_row : layout)
            for (auto v : logical_row.vpns) {
                if (v < minvpn) minvpn = v;
                if (v > maxvpn) maxvpn = v; }
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2U;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        /* FIXME factor vpn/mapram stuff with counter.cpp */
        auto vpn = logical_row.vpns.begin();
        auto mapram = logical_row.maprams.begin();
        auto &map_alu_row =  map_alu.row[row];
        LOG2("# DataSwitchbox.setup(" << row << ") home=" << home->row/2U);
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[logical_col + 6*side];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            unitram_config.unitram_type = UnitRam::SELECTOR;
            unitram_config.unitram_logical_table = logical_id;
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
                ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::STATISTICS;
                ram.unit_ram_ctl.match_ram_read_data_mux_select = UnitRam::DataMux::STATISTICS;
                ram_address_mux_ctl.ram_stats_meter_adr_mux_select_meter = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
                ram_address_mux_ctl.synth2port_radr_mux_select_home_row = 1;
            } else {
                ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::OVERFLOW;
                ram.unit_ram_ctl.match_ram_read_data_mux_select = UnitRam::DataMux::OVERFLOW;
                ram_address_mux_ctl.ram_oflo_adr_mux_select_oflo = 1;
                ram_address_mux_ctl.ram_ofo_stats_mux_select_oflo = 1;
                ram_address_mux_ctl.synth2port_radr_mux_select_oflo = 1; }
            ram_address_mux_ctl.map_ram_wadr_mux_select = MapRam::Mux::SYNTHETIC_TWO_PORT;
            ram_address_mux_ctl.map_ram_wadr_mux_enable = 1;
            ram_address_mux_ctl.map_ram_radr_mux_select_smoflo = 1;

            swbox.setup_col(logical_col);

            auto &mapram_config = map_alu_row.adrmux.mapram_config[*mapram];
            //auto &mapram_ctl = map_alu_row.adrmux.mapram_ctl[*mapram];
            mapram_config.mapram_type = MapRam::SELECTOR_SIZE;
            mapram_config.mapram_logical_table = logical_id;
            mapram_config.mapram_vpn_members = 0;
            if (!options.match_compiler) // FIXME -- compiler doesn't set this?
                mapram_config.mapram_vpn = *vpn;
            if (gress == INGRESS)
                mapram_config.mapram_ingress = 1;
            else
                mapram_config.mapram_egress = 1;
            mapram_config.mapram_enable = 1;
            //if (!options.match_compiler) // FIXME -- compiler doesn't set this?
            //    mapram_ctl.mapram_vpn_limit = maxvpn;
            if (gress) {
                stage->regs.cfg_regs.mau_cfg_mram_thread[*mapram/3U] |= 1U << (*mapram%3U*8U + row);
                stage->regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row); }
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            auto &vh_adr_xbar = stage->regs.rams.array.row[row].vh_adr_xbar;
            setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + logical_row.bus],
                         selection_hash);
            vh_adr_xbar.alu_hashdata_bytemask.alu_hashdata_bytemask_right =
                bitmask2bytemask(input_xbar->hash_group_bituse());
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
        } else {
            auto &adr_ctl = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if (home->row >= 8 && logical_row.row < 8) {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = 0;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::OVERFLOW;
                push_on_overflow = true;
            } else {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = home->row % 8;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::METER; }
            adr_ctl.adr_dist_oflo_adr_xbar_enable = 1; } }

    unsigned meter_group = home->row/4U;
    auto &selector_ctl = map_alu.meter_group[meter_group].selector.selector_alu_ctl;
    selector_ctl.sps_nonlinear_hash_enable = non_linear_hash ? 1 : 0;
    if (resilient_hash)
        selector_ctl.resilient_hash_enable = param;
    else
        selector_ctl.selector_fair_hash_select = param;
    selector_ctl.resilient_hash_mode = resilient_hash ? 1 : 0;
    selector_ctl.selector_enable = 1;
    auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[meter_group];
    delay_ctl.meter_alu_right_group_delay = 13 + meter_group/2 + stage->tcam_delay(gress);
    delay_ctl.meter_alu_right_group_enable = resilient_hash ? 3 : 1;
    /* FIXME -- error_ctl should be configurable */
    auto &error_ctl = map_alu.meter_alu_group_error_ctl[meter_group];
    error_ctl.meter_alu_group_ecc_error_enable = 1;
    error_ctl.meter_alu_group_sel_error_enable = 1;
    error_ctl.meter_alu_group_thread = gress;

    auto &merge = stage->regs.rams.match.merge;
    auto &adrdist = stage->regs.rams.match.adrdist;
    for (MatchTable *m : match_tables) {
        adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id] = 1 << meter_group;
        //auto &icxbar = adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id];
        //icxbar.address_distr_to_logical_rows = 1 << home->row;
        //icxbar.address_distr_to_overflow = push_on_overflow;
        if (auto &act = m->get_action())
            /* FIXME -- can't be attached to mutliple tables with different format sizes? */
            merge.mau_selector_action_entry_size[meter_group] = act->format->log2size - 3;
        adrdist.mau_ad_meter_virt_lt[meter_group] |= 1U << m->logical_id;
        adrdist.movereg_ad_meter_alu_to_logical_xbar_ctl[m->logical_id/8U].set_subfield(
            4 | meter_group, 3*(m->logical_id % 8U), 3);
        if (max_words > 1)
            merge.mau_logical_to_meter_alu_map.set_subfield( 16 | m->logical_id, 5*meter_group, 5);
        merge.mau_meter_alu_to_logical_map[m->logical_id/8U].set_subfield(
            4 | meter_group, 3*(m->logical_id % 8U), 3); }
    if (max_words == 1)
        adrdist.movereg_meter_ctl[meter_group].movereg_ad_meter_shift = 7;
    if (push_on_overflow)
        adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::METER;
    adrdist.packet_action_at_headertime[1][meter_group] = 1;
    for (auto &hd : hash_dist)
        hd.write_regs(this, 0, non_linear_hash);
    if (gress == INGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << meter_group;
    } else {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << meter_group; }
}

void SelectionTable::gen_tbl_cfg(json::vector &out) {
    json::map &tbl = *base_tbl_cfg(out, "selection", 1024);
    tbl["selection_type"] = resilient_hash ? "resilient" : "fair";
    tbl["enable_sps_scrambling"] = non_linear_hash;
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "selection", 1024);
    stage_tbl["how_referenced"] = indirect ? "indirect" : "direct";
    add_pack_format(stage_tbl, 128, 1, 1);
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("sram", true);
    stage_tbl["stage_table_handle"] = logical_id;
}
