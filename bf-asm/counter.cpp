#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(CounterTable)

void CounterTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::Statistics);
    if (!format)
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data, true)) {
        if (common_setup(kv, data, P4Table::Statistics)) {
        } else if (kv.key == "count") {
            if (kv.value == "bytes")
                type = BYTES;
            else if (kv.value == "packets")
                type = PACKETS;
            else if (kv.value == "both" || kv.value == "packets_and_bytes")
                type = BOTH;
            else error(kv.value.lineno, "Unknown counter type %s", value_desc(kv.value));
        } else if (kv.key == "lrt") {
            if (!CHECKTYPE2(kv.value, tVEC, tMAP)) continue;
            collapse_list_of_maps(kv.value, true);
            if (kv.value.type == tVEC) {
                for (auto &el : kv.value.vec)
                    lrt.emplace_back(el);
            } else if (kv.value.map.size >= 1 && kv.value.map[0].key.type == tSTR) {
                lrt.emplace_back(kv.value);
            } else {
                for (auto &el : kv.value.map) {
                    if (!CHECKTYPE2(el.key, tINT, tBIGINT) || !CHECKTYPE(el.value, tINT))
                        break;
                    if (el.key.type == tBIGINT) {
                        if (el.key.bigi.size != 1)
                            error(el.key.lineno, "Threshold too large\n");
                        lrt.emplace_back(el.key.lineno, el.key.bigi.data[0], el.value.i);
                    } else {
                        lrt.emplace_back(el.key.lineno, el.key.i, el.value.i); } } }
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use);
}

CounterTable::lrt_params::lrt_params(const value_t &m)
: lineno(m.lineno), threshold(-1), interval(-1) {
    if (CHECKTYPE(m, tMAP)) {
        for (auto &kv : MapIterChecked(m.map, true)) {
            if (kv.key == "threshold") {
                if (kv.value.type == tBIGINT && kv.value.bigi.size == 1)
                    threshold = kv.value.bigi.data[0];
                else if (CHECKTYPE(kv.value, tINT))
                    threshold = kv.value.i;
            } else if (kv.key == "interval") {
                if (CHECKTYPE(kv.value, tINT))
                    interval = kv.value.i;
            } else
                warning(kv.key.lineno, "ignoring unknown item %s in lrt params",
                        value_desc(kv.key)); }
        if (threshold < 0) error(m.lineno, "No threshold in lrt params");
        if (interval < 0) error(m.lineno, "No interval in lrt params"); }
}

void CounterTable::pass1() {
    LOG1("### Counter table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Statistics, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    //stage->table_use[timing_thread(gress)] |= Stage::USE_SELECTOR;
    int prev_row = -1;
    for (auto &row : layout) {
        if (prev_row >= 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        else
            need_bus(lineno, stage->stats_bus_use, row.row, "Statistics data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        prev_row = row.row; }
    Synth2Port::pass1();
    for (auto &l : lrt) {
        if (l.threshold > MAX_LRT_THRESHOLD)
            error(l.lineno, "lrt threshold too large");
        else if ((l.threshold & 0xf) != 0)
            error(l.lineno, "lrt threshold must be a mulitple of 16");
        if (type & BYTES) {
            if (l.interval > MAX_LRT_BYTE_INTERVAL)
                error(l.lineno, "lrt interval too large");
            else if ((l.interval & 0xff) != 0)
                error(l.lineno, "lrt interval must be a mulitple of 256 when measuring bytes");
        } else if (l.interval > MAX_LRT_PACKET_INTERVAL)
            error(l.lineno, "lrt interval too large"); }
    if (lrt.size() > MAX_LRT_ENTRIES)
        error(lrt[0].lineno, "Too many lrt entries (max %d)", MAX_LRT_ENTRIES);
}

void CounterTable::pass2() {
    LOG1("### Counter table " << name() << " pass2");
    if (logical_id < 0)
        warning(lineno, "counter %s appears unused by any table", name());
}

void CounterTable::pass3() {
    LOG1("### Counter table " << name() << " pass3");
}

static int counter_size[]         = { 0, 0, 1, 2, 3, 0, 4 };
static int counter_masks[]        = { 0, 7, 3, 4, 1, 0, 0 };
static int counter_shifts[]       = { 0, 3, 2, 3, 1, 0, 2 };
static int counter_hole_swizzle[] = { 0, 0, 0, 1, 0, 0, 2 };

int CounterTable::direct_shiftcount() const {
    return 64 + STAT_ADDRESS_ZERO_PAD - counter_shifts[format->groups()];
}

int CounterTable::indirect_shiftcount() const {
    return STAT_ADDRESS_ZERO_PAD - counter_shifts[format->groups()];
}

int CounterTable::address_shift() const {
    return counter_shifts[format->groups()];
}

unsigned CounterTable::determine_shiftcount(Table::Call &call, int group, int word,
        int tcam_shift) const {
    if (call.args[0].name() && strcmp(call.args[0].name(), "$DIRECT") == 0) {
        return direct_shiftcount() + tcam_shift;
    } else if (call.args[0].field()) {
        assert(call.args[0].field()->by_group[group]->bit(0)/128U == word);
        return call.args[0].field()->by_group[group]->bit(0)%128U + indirect_shiftcount();
    } else if (call.args[1].field()) {
        return call.args[1].field()->bit(0) + STAT_ADDRESS_ZERO_PAD;
    }
    return 0;
}

template<class REGS> void CounterTable::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge =  regs.rams.match.merge;
    unsigned adr_mask = 0;
    unsigned per_entry_en_mux_ctl = 0;
    unsigned adr_default = 0;

    if (args[0].type == Table::Call::Arg::Name && strcmp(args[0].name(), "$DIRECT") == 0) {
        adr_mask |= ((1U << STAT_ADDRESS_BITS) - 1) & ~counter_masks[format->groups()];
    } else if (args[0].type == Table::Call::Arg::Field) {
        auto addr = args[0].field();
        auto address_bits = addr->size;
        adr_mask |= ((1U << address_bits) - 1) << (counter_shifts[format->groups()]); 
    }

    
    if (args[1].type == Table::Call::Arg::Name && strcmp(args[1].name(), "$DEFAULT") == 0) {
        adr_default = (1U << STATISTICS_PER_FLOW_ENABLE_START_BIT); 
    } else if (args[1].type == Table::Call::Arg::Field) {
        if (args[0].type == Table::Call::Arg::Field) {
            per_entry_en_mux_ctl = args[1].field()->bit(0) - args[0].field()->bit(0) ;
            per_entry_en_mux_ctl += counter_shifts[format->groups()];
        } else if (args[0].type == Table::Call::Arg::HashDist) {
            per_entry_en_mux_ctl = 0;
        }
    }

    merge.mau_stats_adr_mask[type][bus] = adr_mask;
    merge.mau_stats_adr_default[type][bus] = adr_default;
    merge.mau_stats_adr_per_entry_en_mux_ctl[type][bus] = per_entry_en_mux_ctl;
    merge.mau_stats_adr_hole_swizzle_mode[type][bus] = counter_hole_swizzle[format->groups()];
}

template<class REGS> void CounterTable::write_regs(REGS &regs) {
    LOG1("### Counter table " << name() << " write_regs");
    // FIXME -- factor common AttachedTable::write_regs
    // FIXME -- factor common Synth2Port::write_regs
    // FIXME -- factor common MeterTable::write_regs
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
        /* FIXME factor vpn/mapram stuff with selection.cpp */
        auto vpn = logical_row.vpns.begin();
        auto mapram = logical_row.maprams.begin();
        auto &map_alu_row =  map_alu.row[row];
        LOG2("# DataSwitchbox.setup(" << row << ") home=" << home->row/2U);
        if (&logical_row == home) {
            if (swbox.get_home_row() != row)
                swbox.setup_row(swbox.get_home_row()); }
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            swbox.setup_row_col(row, col, *vpn);
            write_mapram_regs(regs, row, *mapram, *vpn, MapRam::STATISTICS);
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            int stats_group_index = swbox.get_home_row()/2;
            auto &stats = map_alu.stats_wrap[stats_group_index].stats;
            auto &stat_ctl = stats.statistics_ctl;
            stat_ctl.stats_entries_per_word = format->groups();
            if (type & BYTES) stat_ctl.stats_process_bytes = 1;
            if (type & PACKETS) stat_ctl.stats_process_packets = 1;
            if (lrt.size() > 0) {
                stat_ctl.lrt_enable = 1;
                int idx = 0;
                for (auto &l : lrt) {
                    stats.lrt_threshold[idx] = l.threshold / 16U;
                    if (type & BYTES)
                        stats.lrt_update_interval[idx] = l.interval / 256U;
                    else
                        stats.lrt_update_interval[idx] = l.interval;
                    ++idx; } }
            stat_ctl.stats_alu_egress = gress;
            stat_ctl.stats_bytecount_adjust = 0; // TODO
            stat_ctl.stats_alu_error_enable = 0; // TODO
            if (logical_id >= 0)
                regs.cfg_regs.mau_cfg_stats_alu_lt[stats_group_index] = logical_id;
                //setup_muxctl(adrdist.stats_alu_phys_to_logical_ixbar_ctl[row/2], logical_id);
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
            map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
        } else {
            auto &adr_ctl = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if (swbox.get_home_row_logical() >= 8 && logical_row.row < 8) {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = 0;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::OVERFLOW;
                push_on_overflow = true;
            } else {
                adr_ctl.adr_dist_oflo_adr_xbar_source_index = swbox.get_home_row_logical() % 8;
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::STATISTICS; }
            adr_ctl.adr_dist_oflo_adr_xbar_enable = 1;
        }
    }
    int stats_group_index = swbox.get_home_row()/2;
    bool run_at_eop = this->run_at_eop();
    for (MatchTable *m : match_tables)
        run_at_eop = run_at_eop || m->run_at_eop();
    auto &movereg_stats_ctl = adrdist.movereg_stats_ctl[stats_group_index];
    for (MatchTable *m : match_tables) {
        adrdist.adr_dist_stats_adr_icxbar_ctl[m->logical_id] |= 1U << stats_group_index;
        auto &dump_ctl = regs.cfg_regs.stats_dump_ctl[m->logical_id];
        dump_ctl.stats_dump_entries_per_word = format->groups();
        if (type == BYTES || type == BOTH)
            dump_ctl.stats_dump_has_bytes = 1;
        if (type == PACKETS || type == BOTH)
            dump_ctl.stats_dump_has_packets = 1;
        dump_ctl.stats_dump_size = layout_size() - 2;  // FIXME
        if (direct) {
            adrdist.movereg_ad_direct[MoveReg::STATS] |= 1U << m->logical_id;
            if (m->is_ternary())
                movereg_stats_ctl.movereg_stats_ctl_tcam = 1; }
        movereg_stats_ctl.movereg_stats_ctl_lt = m->logical_id;
        adrdist.movereg_ad_stats_alu_to_logical_xbar_ctl[m->logical_id/8U]
            .set_subfield(4+stats_group_index, 3*(m->logical_id%8U), 3);
        adrdist.mau_ad_stats_virt_lt[stats_group_index] |= 1U << m->logical_id; }
    movereg_stats_ctl.movereg_stats_ctl_size = counter_size[format->groups()];
    movereg_stats_ctl.movereg_stats_ctl_direct = direct;
    if (run_at_eop) {
        adrdist.deferred_ram_ctl[MoveReg::STATS][stats_group_index].deferred_ram_en = 1;
        adrdist.deferred_ram_ctl[MoveReg::STATS][stats_group_index].deferred_ram_thread = gress;
        if (gress)
            regs.cfg_regs.mau_cfg_dram_thread |= 1 << stats_group_index;
        movereg_stats_ctl.movereg_stats_ctl_deferred = 1;
        adrdist.stats_bubble_req[gress].bubble_req_1x_class_en |= 1 << (4 + stats_group_index);
    } else {
        adrdist.packet_action_at_headertime[0][stats_group_index] = 1;
        adrdist.stats_bubble_req[gress].bubble_req_1x_class_en |= 1 << stats_group_index;
    }
    if (push_on_overflow) {
        adrdist.deferred_oflo_ctl = 1 << ((home->row-8)/2U);
        adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::STATISTICS; }
}

void CounterTable::gen_tbl_cfg(json::vector &out) const {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1)*1024*format->groups();
    json::map &tbl = *base_tbl_cfg(out, "statistics", size);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "statistics", size);
    add_alu_index(stage_tbl, "stats_alu_index");
    // FIXME: Eliminated by DRV-1856
    tbl["enable_pfe"] = per_flow_enable;
    tbl["pfe_bit_position"] = per_flow_enable_bit();
    if (auto *f = lookup_field("bytes"))
        tbl["byte_counter_resolution"] = f->size;
    else
        tbl["byte_counter_resolution"] = 0L;
    if (auto *f = lookup_field("packets"))
        tbl["packet_counter_resolution"] = f->size;
    else
        tbl["packet_counter_resolution"] = 0L;
    switch (type) {
    case PACKETS: tbl["statistics_type"] = "packets"; break;
    case BYTES: tbl["statistics_type"] = "bytes"; break;
    case BOTH: tbl["statistics_type"] = "packets_and_bytes"; break;
    default: break; }
    if (context_json)
        stage_tbl.merge(*context_json);
}
