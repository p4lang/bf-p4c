/* mau table template specializations for flatrock -- #included directly in match_tables.cpp */

template<> void MatchTable::write_next_table_regs(Target::Flatrock::mau_regs &regs, Table *tbl) {
    auto &mrd = regs.ppu_mrd;
    auto &pred_map = mrd.mrd_pred_map_erf.mrd_pred_map;
    if (!hit_next.empty() || !extra_next_lut.empty()) {
        int i = 0;
        for (auto &n : hit_next) {
            pred_map[logical_id][i].gl_pred_vec = n.next_in_stage(stage->stageno + 1);
            pred_map[logical_id][i].long_branch |= n.long_branch_tags();
            pred_map[logical_id][i].next_table = n.next_table_id();
            pred_map[logical_id][i].pred_vec = n.next_in_stage(stage->stageno) >> 1;
            ++i; }
        for (auto &n : extra_next_lut) {
            pred_map[logical_id][i].gl_pred_vec = n.next_in_stage(stage->stageno + 1);
            pred_map[logical_id][i].long_branch |= n.long_branch_tags();
            pred_map[logical_id][i].next_table = n.next_table_id();
            pred_map[logical_id][i].pred_vec = n.next_in_stage(stage->stageno) >> 1;
            ++i; }
        // is this needed?  The model complains if we leave the unused slots as 0
        while (i < Target::NEXT_TABLE_SUCCESSOR_TABLE_DEPTH())
            pred_map[logical_id][i++].next_table = 0x1ff; }
    pred_map[logical_id][16].gl_pred_vec = miss_next.next_in_stage(stage->stageno + 1);
    pred_map[logical_id][16].long_branch |= miss_next.long_branch_tags();
    pred_map[logical_id][16].next_table = miss_next.next_table_id();
    pred_map[logical_id][16].pred_vec = miss_next.next_in_stage(stage->stageno) >> 1;
}

template<> void MatchTable::write_regs(Target::Flatrock::mau_regs &regs, int type, Table *result) {
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
    /* DANGER -- you might think we should call write_regs on other related things here
     * (actions, hash_dist, idletime, gateway) rather than just input_xbar, but those are
     * all called by the various callers of this method.  Not clear why input_xbar is
     * different */

    int dconfig = 0;  // FIXME -- some parts of this support selecting config based on
    // dconfig bits -- for now we just use config 0

    auto &mrd = regs.ppu_mrd.rf;
    auto &minput = regs.ppu_minput.rf;
    if (gress == GHOST) {
        mrd.mrd_pred_cfg.gst_tables |= 1 << logical_id;
        minput.minput_mpr.gst_tables |= 1 << logical_id;
    } else {
        mrd.mrd_pred_cfg.main_tables |= 1 << logical_id;
        minput.minput_mpr.main_tables |= 1 << logical_id; }
    if (always_run || pred.empty()) {
        minput.minput_mpr.always_run = 1 << logical_id;
    } else {
        // FIXME -- need to figure out when the table needs to be powered due to a predecessor
        // that might enable it.  For now power all
        minput.minput_mpr.always_run = 1 << logical_id;
    }

    // these xbars are "backwards" (because they are oxbars?) -- l2p maps physical to logical
    // and p2l maps logical to physical
    mrd.mrd_l2p_xbar[physical_id].en = 1;
    mrd.mrd_l2p_xbar[physical_id].logical_table = logical_id;
    mrd.mrd_p2l_xbar[logical_id].en = 1;
    mrd.mrd_p2l_xbar[logical_id].phy_table = physical_id;
    if (get_actions()) {
        mrd.mrd_imem_cfg.active_en |= 1 << physical_id;
        mrd.mrd_imem_delay[physical_id].delay = 1; }   // FIXME -- what is the delay?
    minput.minput_mpr_act[logical_id].activate = 1 << physical_id;

    /* action/imem setup */
    // FIXME -- factor with common code in MatchTable::write_common_regs
    auto &imem_map = regs.ppu_mrd.mrd_imem_map_erf.mrd_imem_map[physical_id];
    Actions *actions = action && action->actions ? action->actions.get() : this->actions.get();
    unsigned adr_default = 0;
    auto instr_call = instruction_call();
    if (instr_call.args[0] == "$DEFAULT") {
        for (auto it = actions->begin(); it != actions->end(); it++) {
            if (it->code != -1) {
                adr_default |= it->addr;
                break;
            }
        }
        imem_map[12].data = adr_default;
    } else if (auto *action_field = instr_call.args[0].field()) {
        if (actions->max_code < ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
            mrd.mrd_imem_pld[physical_id].map_en[dconfig] = 1;
            for (auto &act : *actions)
                if ((act.name != result->default_action) || !result->default_only_action)
                    imem_map[act.code].data = act.addr; }
        mrd.mrd_imem_ext[physical_id].ext_start[dconfig] = action_field->immed_bit(0);
        mrd.mrd_imem_ext[physical_id].ext_size[dconfig] = action_field->size; }

    if (action_bus) action_bus->write_regs(regs, this);

    write_next_table_regs(regs, result);
}
