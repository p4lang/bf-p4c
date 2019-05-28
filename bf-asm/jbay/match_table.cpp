/* mau table template specializations for jbay -- #included directly in match_tables.cpp */

/**  Write next table setup, which is JBay-specific.  `tbl` here is the ternary indirect
 * table if there is one, or the match table otherwise */
template<> void MatchTable::write_next_table_regs(Target::JBay::mau_regs &regs, Table *tbl) {
    auto &merge = regs.rams.match.merge;
    if (!hit_next.empty() || !extra_next_lut.empty()) {
        merge.next_table_map_en |= (1U << logical_id);
        int i = 0;
        for (auto &n : hit_next) {
            merge.pred_map_loca[logical_id][i].pred_map_loca_next_table = n.next_table_id();
            merge.pred_map_loca[logical_id][i].pred_map_loca_exec
                = n.next_in_stage(stage->stageno) >> 1;
            merge.pred_map_glob[logical_id][i].pred_map_glob_exec
                = n.next_in_stage(stage->stageno + 1);
            int lbt = n.long_branch_tag();
            if (lbt >= 0)
                merge.pred_map_glob[logical_id][i].pred_map_long_brch |= 1 << lbt;
            ++i; }
        for (auto &n : extra_next_lut) {
            merge.pred_map_loca[logical_id][i].pred_map_loca_next_table = n.next_table_id();
            merge.pred_map_loca[logical_id][i].pred_map_loca_exec
                = n.next_in_stage(stage->stageno) >> 1;
            merge.pred_map_glob[logical_id][i].pred_map_glob_exec
                = n.next_in_stage(stage->stageno + 1);
            int lbt = n.long_branch_tag();
            if (lbt >= 0)
                merge.pred_map_glob[logical_id][i].pred_map_long_brch |= 1 << lbt;
            ++i; }
        // is this needed?  The model complains if we leave the unused slots as 0
        while(i < NEXT_TABLE_SUCCESSOR_TABLE_DEPTH)
            merge.pred_map_loca[logical_id][i++].pred_map_loca_next_table = 0x1ff; }

    merge.next_table_format_data[logical_id].match_next_table_adr_mask = next_table_adr_mask;
    merge.next_table_format_data[logical_id].match_next_table_adr_miss_value
            = miss_next.next_table_id();
    merge.pred_miss_exec[logical_id].pred_miss_loca_exec
            = miss_next.next_in_stage(stage->stageno) >> 1;
    merge.pred_miss_exec[logical_id].pred_miss_glob_exec
            = miss_next.next_in_stage(stage->stageno + 1);
    int lbt = miss_next.long_branch_tag();
    if (lbt >= 0)
        merge.pred_miss_long_brch[logical_id] = 1 << lbt;
}

template<> void MatchTable::write_regs(Target::JBay::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::JBay>(regs, type, result);
    // FIXME -- factor this with JBay GatewayTable::standalone_write_regs
    auto &merge = regs.rams.match.merge;
    if (gress == GHOST)
        merge.pred_ghost_thread |= 1 << logical_id;
    merge.pred_glob_exec_thread[gress] |= 1 << logical_id;
    if (always_run || pred.empty())
        merge.pred_always_run[gress] |= 1 << logical_id;
    // FIXME -- should set this only if pred is empty or contains tables in the current stage?
    // FIXME -- if all pred tables are in earlier stages, then mpr_next_table_lut and/or
    // FIXME -- mpr_glob_exec_lut should be used instead?
    merge.mpr_always_run |= 1 << logical_id;

    if (long_branch_input >= 0)
        setup_muxctl(merge.pred_long_brch_lt_src[logical_id], long_branch_input);

    bool is_branch = (miss_next.next_table() != nullptr);
    if (!is_branch)
        for (auto &n : hit_next)
            if (n.next_table() != nullptr) {
                is_branch = true;
                break; }
    if (!is_branch)
        for (auto &n : extra_next_lut)
            if (n.next_table() != nullptr) {
                is_branch = true;
                break; }

    if (result == nullptr)
        result = this;

    if (result->get_format_field_size("next") > 3)
        is_branch = true;

    if (is_branch)
        merge.pred_is_a_brch |= 1 << logical_id;

    merge.mpr_glob_exec_thread |= merge.logical_table_thread[0].logical_table_thread_egress &
                                  ~merge.logical_table_thread[0].logical_table_thread_ingress &
                                  ~merge.pred_ghost_thread;
}
