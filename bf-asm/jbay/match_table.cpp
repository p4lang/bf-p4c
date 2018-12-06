/* mau table template specializations for jbay -- #included directly in match_tables.cpp */

template<> void MatchTable::setup_next_table_map(Target::JBay::mau_regs &regs, Table *tbl) {
    if (tbl->get_hit_next().empty())
        return;
    auto &merge = regs.rams.match.merge;
    merge.next_table_map_en |= (1U << logical_id);
    int i = 0;
    for (auto &n : tbl->get_hit_next())
        merge.pred_map_loca[logical_id][i++].pred_map_loca_next_table = n ? n->table_id() : 0x1ff;
    // is this needed?  The model complains if we leave the unused slots as 0
    while(i < 8)
        merge.pred_map_loca[logical_id][i++].pred_map_loca_next_table = 0x1ff;
}

template<> void MatchTable::write_regs(Target::JBay::mau_regs &regs, int type, Table *result) {
    write_common_regs<Target::JBay>(regs, type, result);
    // FIXME -- factor this with JBay GatewayTable::standalone_write_regs
    auto &merge = regs.rams.match.merge;
    if (gress == GHOST)
            merge.pred_ghost_thread |= 1 << logical_id;
    if (pred.empty())
        merge.pred_always_run[gress] |= 1 << logical_id;
    // FIXME -- should set this only if pred is empty or contains tables in the current stage?
    // FIXME -- if all pred tables are in earlier stages, then mpr_next_table_lut and/or
    // FIXME -- mpr_glob_exec_lut should be used instead?
    merge.mpr_always_run |= 1 << logical_id;

    merge.pred_is_a_brch |= 1 << logical_id;

    merge.mpr_glob_exec_thread |= merge.logical_table_thread[0].logical_table_thread_egress &
                                  ~merge.logical_table_thread[0].logical_table_thread_ingress &
                                  ~merge.pred_ghost_thread;
}
