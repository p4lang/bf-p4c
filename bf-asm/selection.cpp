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
    setup_layout(layout, row, get(data, "column"), get(data, "bus"), 0);
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
            if (CHECKTYPE(kv.value, tSTR)) {
                per_flow_enable = true;
                per_flow_enable_param = kv.value.s; }
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
            setup_maprams(kv.value);
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
    if (input_xbar) input_xbar->pass1();
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
    stage->table_use[timing_thread(gress)] |= Stage::USE_SELECTOR;
    if (max_words > 1) {
        stage->table_use[timing_thread(gress)] |= Stage::USE_WIDE_SELECTOR;
        for (auto &hd : hash_dist)
            hd.xbar_use |= HashDistribution::HASHMOD_DIVIDEND; }
    for (auto &hd : hash_dist)
        hd.pass1(this);
    bool home = true;  // first layout row is home row
    for (Layout &row : layout) {
        if (home)
            need_bus(row.lineno, stage->selector_adr_bus_use, row.row|3, "Selector Address");
        need_bus(row.lineno, stage->selector_adr_bus_use, row.row, "Selector Address");
        if ((row.row & 2) == 0)  // even phy rows wired together
            need_bus(row.lineno, stage->selector_adr_bus_use, row.row^1, "Selector Address");
        home = false; }
    AttachedTable::pass1();
}

void SelectionTable::pass2() {
    LOG1("### Selection table " << name() << " pass2");
    if (input_xbar) {
        input_xbar->pass2();
        if (selection_hash < 0 && (selection_hash = input_xbar->hash_group()) < 0)
            error(lineno, "No selection_hash in selector table %s", name());
    } else {
        error(lineno, "No input xbar in selector table %s", name()); }
}

void SelectionTable::pass3() {
    LOG1("### Selection table " << name() << " pass3");
}

int SelectionTable::indirect_shiftcount() const {
    return METER_ADDRESS_ZERO_PAD - 7;  // selectors always start at bit 7 address
}

unsigned SelectionTable::per_flow_enable_bit(MatchTable *match) const {
    if (!per_flow_enable)
        return SELECTOR_PER_FLOW_ENABLE_START_BIT;
    else
        return AttachedTable::per_flow_enable_bit(match);
}

unsigned SelectionTable::determine_shiftcount(Table::Call &call, int group, unsigned word,
        int tcam_shift) const {
    return determine_meter_shiftcount(call, group, word, tcam_shift);
}

template<class REGS> void SelectionTable::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge = regs.rams.match.merge;
    setup_physical_alu_map(regs, type, bus, meter_group());
    merge.mau_payload_shifter_enable[type][bus].meter_adr_payload_shifter_en = 1;

    unsigned adr_mask = 0U;
    unsigned per_entry_en_mux_ctl = 0U;
    unsigned adr_default = 0U;
    unsigned meter_type_position = 0U;
    AttachedTable::determine_meter_merge_regs(match, type, bus, args, METER_SELECTOR,
            adr_mask, per_entry_en_mux_ctl, adr_default, meter_type_position);
    merge.mau_meter_adr_default[type][bus] = adr_default;
    merge.mau_meter_adr_mask[type][bus] = adr_mask;
    merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = per_entry_en_mux_ctl;
    merge.mau_meter_adr_type_position[type][bus] = meter_type_position;
}
template<> void SelectionTable::setup_physical_alu_map(Target::Tofino::mau_regs &regs,
                                                       int type, int bus, int alu) {
    auto &merge = regs.rams.match.merge;
    merge.mau_physical_to_meter_alu_ixbar_map[type][bus/8U].set_subfield(4 | alu, 3*(bus%8U), 3);
}
#if HAVE_JBAY
template<> void SelectionTable::setup_physical_alu_map(Target::JBay::mau_regs &regs,
                                                       int type, int bus, int alu) {
    auto &merge = regs.rams.match.merge;
    merge.mau_physical_to_meter_alu_icxbar_map[type][bus/8U] |= (1U << alu) << (4 * (bus%8U));
}
#endif // HAVE_JBAY

template<class REGS>
void SelectionTable::write_regs(REGS &regs) {
    LOG1("### Selection table " << name() << " write_regs");
    if (input_xbar) input_xbar->write_regs(regs);
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  regs.rams.map_alu;
    DataSwitchboxSetup<REGS> swbox(regs, this);
    int minvpn, maxvpn;
    layout_vpn_bounds(minvpn, maxvpn, true);
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
            swbox.setup_row_col(row, col, *vpn);
            write_mapram_regs(regs, row, *mapram, *vpn, MapRam::SELECTOR_SIZE);
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            auto &vh_adr_xbar = regs.rams.array.row[row].vh_adr_xbar;
            setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[SELECTOR_VHXBAR_HASH_BUS_INDEX],
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
    delay_ctl.meter_alu_right_group_delay = Target::METER_ALU_GROUP_DATA_DELAY() + meter_group/2 + stage->tcam_delay(gress);
    delay_ctl.meter_alu_right_group_enable = resilient_hash ? 3 : 1;
    /* FIXME -- error_ctl should be configurable */
    auto &error_ctl = map_alu.meter_alu_group_error_ctl[meter_group];
    error_ctl.meter_alu_group_ecc_error_enable = 1;
    error_ctl.meter_alu_group_sel_error_enable = 1;
    error_ctl.meter_alu_group_thread = gress;

    auto &merge = regs.rams.match.merge;
    auto &adrdist = regs.rams.match.adrdist;
    for (MatchTable *m : match_tables) {
        adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id] = 1 << meter_group;
        //auto &icxbar = adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id];
        //icxbar.address_distr_to_logical_rows = 1 << home->row;
        //icxbar.address_distr_to_overflow = push_on_overflow;
        if (auto &act = m->get_action()) {
            /* FIXME -- can't be attached to mutliple tables ? */
            unsigned fmt = 3;
            fmt = std::max(fmt, act->format->log2size);
            if (auto at = dynamic_cast<ActionTable *>(&(*act)))
                for (auto &f: at->get_action_formats()) fmt = std::max(fmt, f.second->log2size);
            merge.mau_selector_action_entry_size[meter_group] = fmt - 3; } //val in bytes
        adrdist.mau_ad_meter_virt_lt[meter_group] |= 1U << m->logical_id;
        adrdist.movereg_ad_meter_alu_to_logical_xbar_ctl[m->logical_id/8U].set_subfield(
            4 | meter_group, 3*(m->logical_id % 8U), 3);
        setup_logical_alu_map(regs, m->logical_id, meter_group); }
    if (max_words == 1)
        adrdist.movereg_meter_ctl[meter_group].movereg_ad_meter_shift = 7;
    if (push_on_overflow)
        adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::METER;
    adrdist.packet_action_at_headertime[1][meter_group] = 1;
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 0, non_linear_hash);
    if (gress == INGRESS || gress == GHOST) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << meter_group;
    } else if (gress == EGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << meter_group; }
    if (gress == EGRESS) {
        regs.rams.map_alu.meter_group[meter_group].meter.meter_ctl.meter_alu_egress = 1;
    }
}

template<> void SelectionTable::setup_logical_alu_map(Target::Tofino::mau_regs &regs,
                                                      int logical_id, int alu) {
    auto &merge = regs.rams.match.merge;
    if (max_words > 1)
        merge.mau_logical_to_meter_alu_map.set_subfield( 16 | logical_id, 5*alu, 5);
    merge.mau_meter_alu_to_logical_map[logical_id/8U].set_subfield(
        4 | alu, 3*(logical_id % 8U), 3);
}
#if HAVE_JBAY
template<> void SelectionTable::setup_logical_alu_map(Target::JBay::mau_regs &regs,
                                                      int logical_id, int alu) {
    auto &merge = regs.rams.match.merge;
    merge.mau_logical_to_meter_alu_map[logical_id/8U] |= (1U << alu) << ((logical_id%8U) * 4);
    merge.mau_meter_alu_to_logical_map[logical_id/8U].set_subfield(
        4 | alu, 3*(logical_id % 8U), 3);
}
#endif // HAVE_JBAY

void SelectionTable::gen_tbl_cfg(json::vector &out) const {
    json::map &tbl = *base_tbl_cfg(out, "selection", 1024);
    tbl["selection_type"] = resilient_hash ? "resilient" : "fair";
    tbl["selector_name"] = p4_table ? p4_table->p4_name() : "undefined";
    tbl["selection_key_name"] = "undefined"; /// FIXME!
    tbl["how_referenced"] = indirect ? "indirect" : "direct";
    if (pool_sizes.size() > 0)
        tbl["max_port_pool_size"] = *std::max_element(std::begin(pool_sizes), std::end(pool_sizes));
    for (MatchTable *m : match_tables)
        if (auto &act = m->get_action())
            if (auto at = dynamic_cast<ActionTable *>(&(*act))) {
                tbl["bound_to_action_data_table_handle"] = act->handle();
                break; }
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "selection", 1024);
    add_pack_format(stage_tbl, 128, 1, 1);
    stage_tbl["memory_resource_allocation"] =
        gen_memory_resource_allocation_tbl_cfg("sram", layout, true);
    add_alu_index(stage_tbl, "meter_alu_index");
    if (context_json)
        stage_tbl.merge(*context_json);
}
