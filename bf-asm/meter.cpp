#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(MeterTable)

void MeterTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::Stateful);
    for (auto &kv : MapIterChecked(data, true)) {
        if (common_setup(kv, data, P4Table::Meter)) {
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "color_aware") {
            if (kv.value == "per_flow")
                color_aware = color_aware_per_flow_enable = true;
            else
                color_aware = get_bool(kv.value);
        } else if (kv.key == "color_maprams") {
            if (CHECKTYPE(kv.value, tMAP)) {
                setup_layout(color_maprams, get(kv.value.map, "row"),
                             get(kv.value.map, "column"), get(kv.value.map, "bus"));
                if (auto *vpn = get(kv.value.map, "vpn"))
                    if (CHECKTYPE(*vpn, tVEC))
                        setup_vpns(color_maprams, &vpn->vec, true); }
        } else if (kv.key == "hash_dist") {
            // parsed in common_init_setup
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
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use);
}

void MeterTable::pass1() {
    LOG1("### Meter table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Meter, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
    if (color_maprams.empty())
        error(lineno, "Missing color_maprams in meter table %s", name());
    if (!no_vpns && !color_maprams.empty() && color_maprams[0].vpns.empty())
        setup_vpns(color_maprams, 0);
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    stage->table_use[gress] |= Stage::USE_METER;
    if (type == LPF || type == RED)
        stage->table_use[gress] |= Stage::USE_METER_LPF_RED;
    for (auto &hd : hash_dist)
        hd.pass1(this);
    if (input_xbar) input_xbar->pass1();
    int prev_row = -1;
    for (auto &row : layout) {
        if (prev_row >= 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        else
            need_bus(lineno, stage->meter_bus_use, row.row, "Meter data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        prev_row = row.row; }
    AttachedTable::pass1();
}

void MeterTable::pass2() {
    LOG1("### Meter table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2();
}

int MeterTable::direct_shiftcount() {
    return 64;
}

template<class REGS> void MeterTable::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge = regs.rams.match.merge;
    assert(args.size() <= 1);
    //if (args.empty()) { // direct access
    //    merge.mau_meter_adr_mask[type][bus] =  0x7fff80;
    //} else if (args[0].type == Call::Arg::Field) {
    //    // indirect access via overhead field
    //    int bits = args[0].size() - 3;
    //    if (per_flow_enable) --bits;
    //    merge.mau_meter_adr_mask[type][bus] = 0x700000 | (~(~0u << bits) << 7);
    //} else if (args[0].type == Call::Arg::HashDist) {
    //    // indirect access via hash_dist
    //    merge.mau_meter_adr_mask[type][bus] = 0x7fff80; }
    //if (!color_aware)
    //    merge.mau_meter_adr_default[type][bus] |= 2 << 24;
    //else if (!color_aware_per_flow_enable)
    //    merge.mau_meter_adr_default[type][bus] |= 6 << 24;
    //if (!per_flow_enable)
    //    merge.mau_meter_adr_default[type][bus] |= 1 << 23;
    //if (per_flow_enable)
    //    merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = 16;
    //if (color_aware && color_aware_per_flow_enable)
    //    merge.mau_meter_adr_type_position[type][bus] = per_flow_enable ? 16 : 17;
    //else
    //    merge.mau_meter_adr_type_position[type][bus] = 24;
    //merge.mau_idletime_adr_mask[type][bus] = type ? 0x7fff0 : 0xffff0;
    //merge.mau_idletime_adr_default[type][bus] = per_flow_enable ? 0 : 0x100000;

    // FIXME - Sets up the meter default regs, need to factor in index
    // constants. Check glass code :
    // (target/tofino/device/pipeline/mau/address_and_data_structures.py)
    unsigned meter_adr = 0x0;
    if (!color_aware)
        meter_adr |= (METER_LPF_COLOR_BLIND << METER_TYPE_START_BIT);
    else if (!color_aware_per_flow_enable)
        meter_adr |= (METER_COLOR_AWARE << METER_TYPE_START_BIT);
    if (!per_flow_enable)
        meter_adr |= (1U << METER_PER_FLOW_ENABLE_START_BIT);
    merge.mau_meter_adr_default[type][bus] |= meter_adr;

    unsigned meter_adr_mask = 0x0;
    unsigned ptr_bits = 0;
    unsigned base_width = 0;
    unsigned base_mask = 0x0;
    unsigned type_mask = (1U << METER_TYPE_BITS) - 1;
    unsigned full_mask = (1U << METER_ADDRESS_BITS) - 1;
    if (args.empty()) { // direct access
        ptr_bits = METER_ADDRESS_BITS - METER_TYPE_BITS - 1 - METER_LOWER_HUFFMAN_BITS;
        if (!match->to<ExactMatchTable>())
            ptr_bits -= 1; // Ternary tables have one less address bit to consider for meters
    } else {
        ptr_bits = METER_ADDRESS_BITS - METER_LOWER_HUFFMAN_BITS;
        if (!per_flow_enable)
            ptr_bits -=1;
        if ((!color_aware) || (!color_aware_per_flow_enable))
            ptr_bits -= METER_TYPE_BITS; }

    if (color_aware && color_aware_per_flow_enable) {
        base_width = ptr_bits - METER_TYPE_BITS;
        if (per_flow_enable)
            base_width -= 1;
        base_mask = (1U << base_width) - 1;
        meter_adr_mask = base_mask << METER_LOWER_HUFFMAN_BITS;
        meter_adr_mask |= (type_mask << METER_TYPE_START_BIT);
        meter_adr_mask &= full_mask;
    } else {
        base_width = ptr_bits;
        if (per_flow_enable)
            base_width -= 1;
        base_mask = (1U << base_width) - 1;
        meter_adr_mask = base_mask << METER_LOWER_HUFFMAN_BITS;
        meter_adr_mask &= full_mask; }
    if (match->to<HashActionTable>()) {
        merge.mau_stats_adr_mask[type][bus] = 0;
    } else
        merge.mau_meter_adr_mask[type][bus] |= meter_adr_mask;

    if (!per_flow_enable) {
        //ptr_bits += METER_LOWER_HUFFMAN_BITS; //When should these be added?
        if (!color_aware)
            per_flow_enable_bit = ptr_bits - 1;
        else if (!color_aware_per_flow_enable)
            per_flow_enable_bit = ptr_bits - METER_TYPE_BITS - 1;
        else
            per_flow_enable_bit = ptr_bits - 1; }
    merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = per_flow_enable_bit;

    unsigned meter_adr_type = 0;
    if (!color_aware)
        meter_adr_type = METER_ADDRESS_BITS - METER_TYPE_BITS;
    else if (color_aware_per_flow_enable)
        meter_adr_type = ptr_bits - METER_TYPE_BITS + METER_LOWER_HUFFMAN_BITS;
    else meter_adr_type = METER_ADDRESS_BITS - METER_TYPE_BITS;
    merge.mau_meter_adr_type_position[type][bus] = meter_adr_type;

}

template<class REGS>
void MeterTable::write_regs(REGS &regs) {
    LOG1("### Meter table " << name() << " write_regs");
    if (input_xbar) input_xbar->write_regs(regs);
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  regs.rams.map_alu;
    auto &adrdist = regs.rams.match.adrdist;
    DataSwitchboxSetup<REGS> swbox(regs, this);
    int minvpn, maxvpn;
    layout_vpn_bounds(minvpn, maxvpn, true);
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2U;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        assert(side == 1);      /* no map rams or alus on left side anymore */
        auto vpn = logical_row.vpns.begin();
        auto mapram = logical_row.maprams.begin();
        auto &map_alu_row =  map_alu.row[row];
        LOG2("# DataSwitchbox.setup(" << row << ") home=" << home->row/2U);
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            swbox.setup_row_col(row, col, *vpn);
            write_mapram_regs(regs, row, *mapram, *vpn, MapRam::METER);
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            int meter_group_index = row/2U;
            auto &meter_ctl = map_alu.meter_group[meter_group_index].meter.meter_ctl;
            meter_ctl.meter_bytecount_adjust = 0; // FIXME
            meter_ctl.meter_rng_enable = 0; // FIXME
            auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[meter_group_index];
            delay_ctl.meter_alu_right_group_delay = METER_ALU_GROUP_DATA_DELAY + row/4 + stage->tcam_delay(gress);
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
            auto &error_ctl = map_alu.meter_alu_group_error_ctl[meter_group_index];
            error_ctl.meter_alu_group_ecc_error_enable = 1;
            error_ctl.meter_alu_group_thread = gress;
            auto &meter_sweep_ctl = adrdist.meter_sweep_ctl[meter_group_index];
            // The driver will manage turning on the meter sweep enable,
            // so the compiler should not configure this value (check glass
            // code)
            //meter_sweep_ctl.meter_sweep_en = 1;
            meter_sweep_ctl.meter_sweep_offset = minvpn;
            meter_sweep_ctl.meter_sweep_size = maxvpn;
            meter_sweep_ctl.meter_sweep_remove_hole_pos = 0; // FIXME
            meter_sweep_ctl.meter_sweep_remove_hole_en = 0; // FIXME
            meter_sweep_ctl.meter_sweep_interval = sweep_interval;
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
            auto &movereg_meter_ctl = adrdist.movereg_meter_ctl[meter_group_index];
            if (run_at_eop()) movereg_meter_ctl.movereg_meter_ctl_deferred = 1;
            movereg_meter_ctl.movereg_ad_meter_shift = 7;
            movereg_meter_ctl.movereg_meter_ctl_lt = logical_id;
            if (direct) {
                movereg_meter_ctl.movereg_meter_ctl_direct = 1;
                adrdist.movereg_ad_direct[1] |= 1U << logical_id; }
            // FIXME -- should these be set for all match tables attached to?
            movereg_meter_ctl.movereg_meter_ctl_color_en = 1;
            adrdist.movereg_ad_meter_alu_to_logical_xbar_ctl[logical_id/8U]
                .set_subfield(4 | meter_group_index, 3 * (logical_id%8U), 3);
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
    auto &merge = regs.rams.match.merge;
    int color_map_color = color_maprams.empty() ? 0 : (color_maprams[0].row & 2) >> 1;
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
            if (&row == &color_maprams[0])
                mapram_config.mapram_color_bus_select = MapRam::ColorBus::COLOR;
            else
                mapram_config.mapram_color_bus_select = MapRam::ColorBus::OVERFLOW;
            mapram_config.mapram_type = MapRam::COLOR;
            mapram_config.mapram_logical_table = logical_id;
            mapram_config.mapram_vpn = *vpn;
            mapram_config.mapram_parity_generate = 0;
            mapram_config.mapram_parity_check = 0;
            mapram_config.mapram_ecc_check = 1;
            mapram_config.mapram_ecc_generate = 1;
            if (gress == INGRESS)
                mapram_config.mapram_ingress = 1;
            else
                mapram_config.mapram_egress = 1;
            mapram_config.mapram_enable = 1;
            if (row.row != home->row/2) { /* ALU home row */
                mapram_config.mapram_color_write_bus_select = 1; }
            auto &ram_address_mux_ctl = map_alu_row.adrmux.ram_address_mux_ctl[1][col];
            if (row.row == home->row/2) { /* ALU home row */
                ram_address_mux_ctl.synth2port_radr_mux_select_home_row = 1;
            } else {
                ram_address_mux_ctl.synth2port_radr_mux_select_oflo = 1; }
            map_alu_row.i2portctl.synth2port_ctl.synth2port_mapram_color |= 1U << col;
            ram_address_mux_ctl.map_ram_wadr_shift = 1;
            ram_address_mux_ctl.map_ram_wadr_mux_select = MapRam::Mux::COLOR;
            ram_address_mux_ctl.map_ram_wadr_mux_enable = 1;
            ram_address_mux_ctl.map_ram_radr_mux_select_color = 1;
            ram_address_mux_ctl.ram_stats_meter_adr_mux_select_idlet = 1;
            ram_address_mux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            setup_muxctl(map_alu_row.vh_xbars.adr_dist_idletime_adr_xbar_ctl[col], row.bus);
            if (gress)
                regs.cfg_regs.mau_cfg_mram_thread[col/3U] |= 1U << (col%3U*8U + row.row);
            ++vpn; } }
    for (MatchTable *m : match_tables) {
        adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id] |= 1U << (home->row/4U);
        //auto &icxbar = adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id];
        //icxbar.address_distr_to_logical_rows = 1U << home->row;
        //icxbar.address_distr_to_overflow = push_on_overflow;
        //if (direct)
        //    regs.cfg_regs.mau_cfg_lt_meter_are_direct |= 1 << m->logical_id;
        if (!color_maprams.empty()) {
            merge.mau_mapram_color_map_to_logical_ctl[m->logical_id/8].set_subfield(
                0x4 | (color_maprams[0].row/2U), 3 * (m->logical_id%8U), 3);
            // FIXME -- this bus_index calculation is probably wrong
            int bus_index = color_maprams[0].bus;
            if (color_maprams[0].row >= 4) bus_index += 10;
            adrdist.adr_dist_idletime_adr_oxbar_ctl[bus_index/4]
                .set_subfield(m->logical_id | 0x10, 5 * (bus_index%4), 5); }
        // FIXME -- color map should be programmable, rather than fixed
        adrdist.meter_color_output_map[m->logical_id].set_subfield(0,  0, 8);  // green
        adrdist.meter_color_output_map[m->logical_id].set_subfield(1,  8, 8);  // yellow
        adrdist.meter_color_output_map[m->logical_id].set_subfield(1, 16, 8);  // yellow
        adrdist.meter_color_output_map[m->logical_id].set_subfield(3, 24, 8);  // red
        adrdist.movereg_idle_ctl[m->logical_id].movereg_idle_ctl_mc = 1;
        if (type != LPF)
            adrdist.meter_enable |= 1U << m->logical_id;
        /*auto &movereg_ad_ctl = adrdist.movereg_ad_ctl[m->logical_id];
        movereg_ad_ctl.movereg_meter_deferred = 1;
        if (!color_maprams.empty())
            movereg_ad_ctl.movereg_ad_idle_as_mc = 1;
        else
            movereg_ad_ctl.movereg_ad_stats_as_mc = 1;
        movereg_ad_ctl.movereg_ad_direct_meter = direct;
        movereg_ad_ctl.movereg_ad_meter_shift = 7; */
        meter_color_logical_to_phys(regs, m->logical_id, home->row/4U);
        adrdist.mau_ad_meter_virt_lt[home->row/4U] |= 1 << m->logical_id; }
    adrdist.deferred_ram_ctl[1][home->row/4U].deferred_ram_en = 1;
    adrdist.deferred_ram_ctl[1][home->row/4U].deferred_ram_thread = gress;
    if (gress)
        regs.cfg_regs.mau_cfg_dram_thread |= 0x10 << (home->row/4U);
    if (push_on_overflow) {
        adrdist.deferred_oflo_ctl = 1 << ((home->row-8)/2U);
        adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::METER; }
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 1, false);
    if (gress == INGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << home->row/4U;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << home->row/4U;
    } else {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << home->row/4U;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << home->row/4U; }
}

template<> void MeterTable::meter_color_logical_to_phys(Target::Tofino::mau_regs &regs,
                                                        int logical_id, int alu) {
    auto &adrdist = regs.rams.match.adrdist;
    setup_muxctl(adrdist.meter_color_logical_to_phys_ixbar_ctl[logical_id], alu);
}

#if HAVE_JBAY
template<> void MeterTable::meter_color_logical_to_phys(Target::JBay::mau_regs &regs,
                                                        int logical_id, int alu) {
    auto &adrdist = regs.rams.match.adrdist;
    adrdist.meter_color_logical_to_phys_icxbar_ctl[logical_id] |= 1 << alu;
}
#endif // HAVE_JBAY

void MeterTable::gen_tbl_cfg(json::vector &out) {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1)*1024;
    json::map &tbl = *base_tbl_cfg(out, "meter", size);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "meter", size);
    stage_tbl["color_map_ram_resource_allocation"] =
            gen_memory_resource_allocation_tbl_cfg("map_ram", color_maprams);
    stage_tbl["meter_sweep_interval"] = sweep_interval;
    switch (type) {
    case STANDARD: tbl["meter_type"] = "standard"; break;
    case LPF: tbl["meter_type"] = "lpf"; break;
    case RED: tbl["meter_type"] = "red"; break;
    default: break; }
    switch (count) {
    case PACKETS: tbl["meter_granularity"] = "packets"; break;
    case BYTES: tbl["meter_granularity"] = "bytes"; break;
    default: break; }
    tbl["enable_color_aware"] = color_aware;
    tbl["enable_color_aware_pfe"] = color_aware_per_flow_enable;
    tbl["enable_pfe"] = per_flow_enable;
    tbl["pfe_bit_position"] = per_flow_enable_bit;
    tbl["color_aware_pfe_address_type_bit_position"] = 0; //FIXME
    stage_tbl["default_lower_huffman_bits_included"] = METER_LOWER_HUFFMAN_BITS;
    add_meter_alu_index(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
}

