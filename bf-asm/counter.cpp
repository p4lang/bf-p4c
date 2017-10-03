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
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
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
    AttachedTable::pass1();
}

void CounterTable::pass2() {
    LOG1("### Counter table " << name() << " pass2");
}

static int counter_size[]         = { 0, 0, 1, 2, 3, 0, 4 };
static int counter_masks[]        = { 0, 7, 3, 4, 1, 0, 0 };
static int counter_shifts[]       = { 0, 3, 2, 1, 1, 0, 0 };
static int counter_hole_swizzle[] = { 0, 0, 0, 1, 0, 0, 2 };

int CounterTable::direct_shiftcount() {
    return 64 + 7 - counter_shifts[format->groups()];
}

int CounterTable::indirect_shiftcount() {
    return 7 - counter_shifts[format->groups()];
}

template<class REGS> void CounterTable::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge =  regs.rams.match.merge;
    //per_flow_enable_bit = 19;
    ///* FIXME -- This should be cleaner -- rather than checking the match table type, have
    // * the pfe bit stored in the CounterTable and hve the match table set it in some pass?
    // * Should be using the top bit from the counter index field in the match foramt?
    // * Or add a second arg to the stats/counter call in the match table specifying which bit?  */
    //if (per_flow_enable && dynamic_cast<HashActionTable *>(match)) {
    //    per_flow_enable_bit = 7; }
    //if (options.match_compiler && dynamic_cast<HashActionTable *>(match)) {
    //    /* FIXME -- for some reason the compiler does not set the stats_adr_mask
    //     * for hash_action tables.  Is it not needed? */
    //} else
    //    merge.mau_stats_adr_mask[type][bus] = 0xfffff & ~counter_masks[format->groups()];
    //merge.mau_stats_adr_hole_swizzle_mode[type][bus] = counter_hole_swizzle[format->groups()];
    //merge.mau_stats_adr_default[type][bus] = per_flow_enable ? 0 : (1U << per_flow_enable_bit);
    //if (per_flow_enable)
    //    merge.mau_stats_adr_per_entry_en_mux_ctl[type][bus] = per_flow_enable_bit;

    unsigned stats_adr_default = 0;
    unsigned stats_adr_mask = ((1U <<  STAT_ADDRESS_BITS) - 1) & ~counter_masks[format->groups()];
    unsigned pfe = per_flow_enable_bit;
    if (per_flow_enable) {
        stats_adr_mask = ((1U <<  address_bits) - 1) << (counter_shifts[format->groups()]);
        pfe += counter_shifts[format->groups()];
    } else {
        //pfe = STATISTICS_PER_FLOW_ENABLE_START_BIT;
        pfe = 0; // Does pfe value get picked up in default case?
        stats_adr_default = 1U << (STAT_ADDRESS_BITS - 1); }
    // FIXME: Should be cleaner, separate function to indicate addressing 
    if (match->to<HashActionTable>()) {
        merge.mau_stats_adr_mask[type][bus] = 0;
    } else
        merge.mau_stats_adr_mask[type][bus] = stats_adr_mask;
    merge.mau_stats_adr_default[type][bus] = stats_adr_default; 
    merge.mau_stats_adr_per_entry_en_mux_ctl[type][bus] = pfe;
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
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            swbox.setup_row_col(row, col, *vpn);
            write_mapram_regs(regs, row, *mapram, *vpn, MapRam::STATISTICS);
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            ++mapram, ++vpn; }
        if (&logical_row == home) {
            int stats_group_index = row/2;
            auto &stat_ctl = map_alu.stats_wrap[stats_group_index].stats.statistics_ctl;
            stat_ctl.stats_entries_per_word = format->groups();
            if (type & BYTES) stat_ctl.stats_process_bytes = 1;
            if (type & PACKETS) stat_ctl.stats_process_packets = 1;
            stat_ctl.lrt_enable = 0;
            stat_ctl.stats_alu_egress = gress;
            stat_ctl.stats_bytecount_adjust = 0; // TODO
            stat_ctl.stats_alu_error_enable = 0; // TODO
            regs.cfg_regs.mau_cfg_stats_alu_lt[stats_group_index] = logical_id;
            //setup_muxctl(adrdist.stats_alu_phys_to_logical_ixbar_ctl[row/2], logical_id);
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
                adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::STATISTICS; }
            adr_ctl.adr_dist_oflo_adr_xbar_enable = 1;
        }
    }
    int stats_group_index = home->row/4U;
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
    } else
        adrdist.packet_action_at_headertime[0][stats_group_index] = 1;
    if (push_on_overflow) {
        adrdist.deferred_oflo_ctl = 1 << ((home->row-8)/2U);
        adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::STATISTICS; }
}

void CounterTable::gen_tbl_cfg(json::vector &out) {
    if (options.new_ctx_json) {
        // FIXME -- factor common Synth2Port stuff
        int size = (layout_size() - 1)*1024*format->groups();
        json::map &tbl = *base_tbl_cfg(out, "statistics", size);
        json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "statistics", size);
        tbl["enable_pfe"] = per_flow_enable;
        tbl["pfe_bit_position"] = per_flow_enable_bit;
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
    } else {
        // FIXME -- factor common Synth2Port stuff
        int size = (layout_size() - 1)*1024*format->groups();
        json::map &tbl = *base_tbl_cfg(out, "statistics", size);
        json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "statistics", size);
        if (auto *f = lookup_field("bytes"))
            stage_tbl["byte_width"] = f->size;
        else
            stage_tbl["byte_width"] = 0L;
        if (auto *f = lookup_field("packets"))
            stage_tbl["pkt_width"] = f->size;
        else
            stage_tbl["pkt_width"] = 0L;
        switch (type) {
        case PACKETS: tbl["statistics_type"] = "packets";
                      stage_tbl["stat_type"] = "packets"; break;
        case BYTES: tbl["statistics_type"] = "bytes";
                    stage_tbl["stat_type"] = "bytes"; break;
        case BOTH: tbl["statistics_type"] = "packets_and_bytes";
                   stage_tbl["stat_type"] = "packets_and_bytes"; break;
        default: break; }
        tbl["lrt_enable"] = false;
        tbl["saturating"] = false;  // FIXME?
        stage_tbl["default_lower_huffman_bits_included"] = 0; }
}
