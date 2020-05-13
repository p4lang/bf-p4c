/* gateway template specializations for jbay -- #included directly in gateway.cpp */

template<> void GatewayTable::write_next_table_regs(Target::JBay::mau_regs &regs) {
    auto &merge = regs.rams.match.merge;
    if (need_next_map_lut)
        merge.next_table_map_en_gateway |= 1U << logical_id;
    int idx = 3;
    for (auto &line : table) {
        BUG_CHECK(idx >= 0);
        if (!line.run_table) {
            if (need_next_map_lut)
                merge.gateway_next_table_lut[logical_id][idx] = line.next_map_lut;
            else
                merge.gateway_next_table_lut[logical_id][idx] = line.next.next_table_id(); }
        --idx; }
    if (!miss.run_table) {
        if (need_next_map_lut)
            merge.gateway_next_table_lut[logical_id][4] = miss.next_map_lut;
        else
            merge.gateway_next_table_lut[logical_id][4] = miss.next.next_table_id(); }
    if (!match_table && need_next_map_lut) {
        // Factor with common code in jbay/match_table.cpp write_next_table_regs
        merge.next_table_map_en |= 1U << logical_id;
        int i = 0;
        for (auto &n : extra_next_lut) {
            merge.pred_map_loca[logical_id][i].pred_map_loca_next_table = n.next_table_id();
            merge.pred_map_loca[logical_id][i].pred_map_loca_exec
                = n.next_in_stage(stage->stageno) >> 1;
            merge.pred_map_glob[logical_id][i].pred_map_glob_exec
                = n.next_in_stage(stage->stageno + 1);
            merge.pred_map_glob[logical_id][i].pred_map_long_brch |= n.long_branch_tags();
            ++i; }
        // is this needed?  The model complains if we leave the unused slots as 0
        while(i < NEXT_TABLE_SUCCESSOR_TABLE_DEPTH)
            merge.pred_map_loca[logical_id][i++].pred_map_loca_next_table = 0x1ff; }
}

template<> void GatewayTable::standalone_write_regs(Target::JBay::mau_regs &regs) {
    // FIXME -- factor this with JBay MatchTable::write_regs
    auto &merge = regs.rams.match.merge;
    if (gress == GHOST)
        merge.pred_ghost_thread |= 1 << logical_id;
    merge.pred_glob_exec_thread[gress] |= 1 << logical_id;
    if (always_run || pred.empty())
        merge.pred_always_run[gress] |= 1 << logical_id;

    if (long_branch_input >= 0)
        setup_muxctl(merge.pred_long_brch_lt_src[logical_id], long_branch_input);

    bool is_branch = (miss_next.next_table() != nullptr) || !need_next_map_lut;
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
    if (is_branch)
        merge.pred_is_a_brch |= 1 << logical_id;

    merge.mpr_glob_exec_thread |= merge.logical_table_thread[0].logical_table_thread_egress &
                                ~merge.logical_table_thread[0].logical_table_thread_ingress &
                                ~merge.pred_ghost_thread;
}