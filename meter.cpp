#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(MeterTable)

void MeterTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), get(data, "bus"));
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "vpns") {
            if (kv.value == "null")
                no_vpns = true;
            else if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(layout, &kv.value.vec, true);
        } else if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::Meter, kv.value.map);
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else if (kv.key == "maprams") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_maprams(&kv.value.vec);
        } else if (kv.key == "color_aware") {
            if (kv.value == "per_flow")
                color_aware = color_aware_per_flow_enable = true;
            else
                color_aware = get_bool(kv.value);
        } else if (kv.key == "color_maprams") {
            if (CHECKTYPE(kv.value, tMAP))
                setup_layout(color_maprams, get(kv.value.map, "row"),
                             get(kv.value.map, "column"), get(kv.value.map, "bus"));
                if (auto *vpn = get(kv.value.map, "vpn"))
                    if (CHECKTYPE(*vpn, tVEC))
                        setup_vpns(color_maprams, &vpn->vec, true);
        } else if (kv.key == "hash_dist") {
            HashDistribution::parse(hash_dist, kv.value);
            for (auto &hd : hash_dist) hd.meter_pre_color = true;
            if (hash_dist.size() > 1)
                error(kv.key.lineno, "More than one hast_dist in a meter table not supported");
        } else if (kv.key == "type") {
            if (kv.value == "standard")
                type = STANDARD;
            else if (kv.value == "lpf")
                type = LPF;
            else if (kv.value == "red")
                type = RED;
            else error(kv.value.lineno, "Unknown meter type %s", value_desc(kv.value));
        } else if (kv.key == "count") {
            if (kv.value == "bytes")
                count = BYTES;
            else if (kv.value == "packets")
                count = PACKETS;
            else error(kv.value.lineno, "Unknown meter count %s", value_desc(kv.value));
        } else if (kv.key == "sweep_interval") {
            if (CHECKTYPE(kv.value, tINT))
                sweep_interval = kv.value.i;
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
            p4_table = P4Table::get(P4Table::Meter, p4_info); }
    fini(p4_info);
    alloc_rams(true, stage->sram_use);
}

void MeterTable::pass1() {
    LOG1("### Meter table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Statistics, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
    if (!no_vpns && !color_maprams.empty() && color_maprams[0].vpns.empty())
        setup_vpns(color_maprams, 0);
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    stage->table_use[gress] |= Stage::USE_METER;
    for (auto &hd : hash_dist)
        hd.pass1(this);
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
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

void MeterTable::pass2() {
    LOG1("### Meter table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
}

int MeterTable::direct_shiftcount() {
    return 64;
}

void MeterTable::write_merge_regs(MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge = stage->regs.rams.match.merge;
    if (args.empty()) { // direct access
        merge.mau_meter_adr_mask[type][bus] =  0x7fff80;
    } else { // indirect access
        assert(args.size() == 1 && args[0].type == Call::Arg::Field);
        int bits = args[0].size() - 3;
        if (per_flow_enable) --bits;
        merge.mau_meter_adr_mask[type][bus] = 0x700000 | (~(~0u << bits) << 7); }
    if (!color_aware)
        merge.mau_meter_adr_default[type][bus] |= 2 << 24;
    else if (!color_aware_per_flow_enable)
        merge.mau_meter_adr_default[type][bus] |= 6 << 24;
    if (!per_flow_enable)
        merge.mau_meter_adr_default[type][bus] |= 1 << 23;
    if (per_flow_enable)
        merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = 16;
    if (color_aware && color_aware_per_flow_enable)
        merge.mau_meter_adr_type_position[type][bus] = per_flow_enable ? 16 : 17;
    else
        merge.mau_meter_adr_type_position[type][bus] = 24;
    merge.mau_idletime_adr_mask[type][bus] = type ? 0x7fff0 : 0xffff0;
    merge.mau_idletime_adr_default[type][bus] = per_flow_enable ? 0 : 0x100000;
}

void MeterTable::write_regs() {
    LOG1("### Meter table " << name() << " write_regs");
    if (input_xbar) input_xbar->write_regs();
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  stage->regs.rams.map_alu;
    auto &adrdist = stage->regs.rams.match.adrdist;
    DataSwitchboxSetup swbox(stage, home->row/2U);
    int maxvpn = -1, minvpn = -1;
    if (options.match_compiler)
        minvpn = 0, maxvpn = layout_size() - 1;
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2U;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        assert(side == 1);      /* no map rams or alus on left side anymore */
        auto vpn = logical_row.vpns.begin();
        if (!options.match_compiler)
            for (auto v : logical_row.vpns) {
                if (v > maxvpn) maxvpn = v;
                if (v < minvpn || minvpn < 0) minvpn = v; }
        auto mapram = logical_row.maprams.begin();
        auto &map_alu_row =  map_alu.row[row];
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[logical_col + 6*side];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            unitram_config.unitram_type = UnitRam::METER;
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
            auto &mapram_ctl = map_alu_row.adrmux.mapram_ctl[*mapram];
            mapram_config.mapram_type = MapRam::METER;
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
                mapram_ctl.mapram_vpn_limit = maxvpn;
            if (gress) {
                stage->regs.cfg_regs.mau_cfg_mram_thread[*mapram/3U] |= 1U << (*mapram%3U*8U + row);
                stage->regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row); }
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            auto &meter_ctl = map_alu.meter_group[row/2U].meter.meter_ctl;
            meter_ctl.meter_bytecount_adjust = 0; // FIXME
            meter_ctl.meter_rng_enable = 0; // FIXME
            auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[row/2U];
            delay_ctl.meter_alu_right_group_delay = 10 + stage->tcam_delay(gress);
            switch (type) {
                case LPF:
                    meter_ctl.lpf_enable = 1;
                    delay_ctl.meter_alu_right_group_enable = 1;
                    break;
                case RED:
                    meter_ctl.lpf_enable = 1;
                    meter_ctl.red_enable = 1;
                    delay_ctl.meter_alu_right_group_enable = 1;
                    break;
                default:
                    meter_ctl.meter_enable = 1;
                    break; }
            if (count == BYTES)
                meter_ctl.meter_byte = 1;
            if (gress == EGRESS)
                meter_ctl.meter_alu_egress = 1;
            meter_ctl.meter_rng_enable = 0; // TODO
            setup_muxctl(adrdist.meter_alu_phys_to_logical_ixbar_ctl[row/2U], logical_id);
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
    auto &merge = stage->regs.rams.match.merge;
    int color_map_color = (color_maprams[0].row & 2) >> 1;
    for (Layout &row : color_maprams) {
        if (&row == &color_maprams[0]) { /* color mapram home row */
            if (color_map_color)
                map_alu.mapram_color_switchbox.row[row.row].ctl.r_color1_mux_select
                    .r_color1_sel_color_r_i = 1;
            else
                map_alu.mapram_color_switchbox.row[row.row].ctl.r_color0_mux_select
                    .r_color0_sel_color_r_i = 1;
        } else if (row.row / 4U == color_maprams[0].row / 4U) { /* same half as home */
            if (color_map_color)
                map_alu.mapram_color_switchbox.row[row.row].ctl.r_color1_mux_select
                    .r_color1_sel_oflo_color_r_i = 1;
            else
                map_alu.mapram_color_switchbox.row[row.row].ctl.r_color0_mux_select
                    .r_color0_sel_oflo_color_r_i = 1;
        } else { /* other half from home */
            map_alu.mapram_color_switchbox.row[row.row].ctl.t_oflo_color_o_mux_select = 1;
            merge.mau_match_central_mapram_read_color_oflo_ctl |= 1U << color_map_color;
        }
        if (row.row != home->row/2) { /* ALU home row */
            map_alu.mapram_color_write_switchbox[home->row/4U].ctl.b_oflo_color_write_o_mux_select
                .b_oflo_color_write_o_sel_r_color_write_i = 1;
            map_alu.mapram_color_write_switchbox[row.row/2U].ctl.r_oflo_color_write_o_mux_select=1;
            assert(home->row/4U >= row.row/2U);
            for (unsigned i = home->row/4U; i > row.row/2U; i--)
                map_alu.mapram_color_write_switchbox[i].ctl.b_oflo_color_write_o_mux_select
                    .b_oflo_color_write_o_sel_t_oflo_color_write_i = 1; }
        auto &map_alu_row =  map_alu.row[row.row];
        auto vpn = row.vpns.begin();
        for (int col : row.cols) {
            auto &mapram_config = map_alu_row.adrmux.mapram_config[col];
            mapram_config.mapram_type = MapRam::COLOR;
            mapram_config.mapram_logical_table = logical_id;
            mapram_config.mapram_vpn = *vpn;
            if (gress == INGRESS)
                mapram_config.mapram_ingress = 1;
            else
                mapram_config.mapram_egress = 1;
            mapram_config.mapram_enable = 1;
            if (&row == &color_maprams[0])
                mapram_config.mapram_color_bus_select = MapRam::ColorBus::COLOR;
            else
                mapram_config.mapram_color_bus_select = MapRam::ColorBus::OVERFLOW;
            auto &ram_address_mux_ctl = map_alu_row.adrmux.ram_address_mux_ctl[1][col];
            if (&row == &color_maprams[0]) { /* color mapram home row */
                ram_address_mux_ctl.synth2port_radr_mux_select_home_row = 1; }
            ram_address_mux_ctl.map_ram_wadr_shift = 1;
            ram_address_mux_ctl.map_ram_wadr_mux_select = MapRam::Mux::COLOR;
            ram_address_mux_ctl.map_ram_wadr_mux_enable = 1;
            ram_address_mux_ctl.map_ram_radr_mux_select_color = 1;
            ram_address_mux_ctl.ram_stats_meter_adr_mux_select_idlet = 1;
            ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            setup_muxctl(map_alu_row.vh_xbars.adr_dist_idletime_adr_xbar_ctl[col], row.bus);
            if (gress)
                stage->regs.cfg_regs.mau_cfg_mram_thread[col/3U] |= 1U << (col%3U*8U + row.row);
            ++vpn; } }
    for (MatchTable *m : match_tables) {
        auto &icxbar = adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id];
        icxbar.address_distr_to_logical_rows = 1U << home->row;
        icxbar.address_distr_to_overflow = push_on_overflow;
        //if (direct)
        //    stage->regs.cfg_regs.mau_cfg_lt_meter_are_direct |= 1 << m->logical_id;
        merge.mau_mapram_color_map_to_logical_ctl[m->logical_id/8].set_subfield(
            0x4 | (color_maprams[0].row/2U), 3 * (m->logical_id%8U), 3);
        // FIXME -- this bus_index calculation is probably wrong
        int bus_index = color_maprams[0].bus;
        if (color_maprams[0].row >= 4) bus_index += 10;
        adrdist.adr_dist_idletime_adr_oxbar_ctl[bus_index/4]
            .set_subfield(m->logical_id | 0x10, 5 * (bus_index%4), 5);
        // FIXME -- color map should be programmable, rather than fixed
        adrdist.meter_color_output_map[m->logical_id] = 0x2010100;
        if (type != LPF)
            adrdist.meter_enable |= 1U << m->logical_id;
        auto &meter_sweep_ctl = adrdist.meter_sweep_ctl[m->logical_id];
        meter_sweep_ctl.meter_sweep_en = 1;
        meter_sweep_ctl.meter_sweep_offset = minvpn;
        meter_sweep_ctl.meter_sweep_size = maxvpn;
        meter_sweep_ctl.meter_sweep_remove_hole_pos = 0; // FIXME
        meter_sweep_ctl.meter_sweep_remove_hole_en = 0; // FIXME
        meter_sweep_ctl.meter_sweep_interval = sweep_interval;
        auto &movereg_ad_ctl = adrdist.movereg_ad_ctl[m->logical_id];
        movereg_ad_ctl.movereg_meter_deferred = 1;
        if (!color_maprams.empty())
            movereg_ad_ctl.movereg_ad_idle_as_mc = 1;
        else
            movereg_ad_ctl.movereg_ad_stats_as_mc = 1;
        movereg_ad_ctl.movereg_ad_direct_meter = direct;
        movereg_ad_ctl.movereg_ad_meter_shift = 7; }
    adrdist.deferred_ram_ctl[1][home->row/4].deferred_ram_en = 1;
    adrdist.deferred_ram_ctl[1][home->row/4].deferred_ram_thread = gress;
    if (gress)
        stage->regs.cfg_regs.mau_cfg_dram_thread |= 0x10 << (home->row/4);
    if (push_on_overflow)
        adrdist.deferred_oflo_ctl = 1 << ((home->row-8)/2U);
    for (auto &hd : hash_dist)
        hd.write_regs(this, 1, false);
}

void MeterTable::gen_tbl_cfg(json::vector &out) {
    int size = (layout_size() - 1)*1024;
    json::map &tbl = *base_tbl_cfg(out, "meter", size);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "meter", size);
    stage_tbl["how_referenced"] = indirect ? "indirect" : "direct";
    add_pack_format(stage_tbl, 128, 1, 1);
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("sram", true);
    stage_tbl["stage_table_handle"] = logical_id;
    stage_tbl["meter_sweep_interval"] = sweep_interval;
    tbl.erase("p4_selection_tables");
    tbl.erase("p4_action_data_tables");
    switch (type) {
    case STANDARD: tbl["meter_type"] = "standard"; break;
    case LPF: tbl["meter_type"] = "lpf"; break;
    case RED: tbl["meter_type"] = "red"; break;
    default: break; }
    switch (count) {
    case PACKETS: tbl["meter_granularity"] = "packets"; break;
    case BYTES: tbl["meter_granularity"] = "bytes"; break;
    default: break; }
    tbl["enable_per_flow_enable"] = per_flow_enable;
    tbl["enable_color_aware"] = color_aware;
    tbl["enable_color_aware_per_flow_enable"] = color_aware_per_flow_enable;
}
