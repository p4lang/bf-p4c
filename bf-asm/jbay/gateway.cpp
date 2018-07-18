/* gateway template specializations for jbay -- #included directly in gateway.cpp */

template<> void GatewayTable::standalone_write_regs(Target::JBay::mau_regs &regs) {
    // FIXME -- factor this with JBay MatchTable::write_regs
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
