/* mau table template specializations for flatrock -- #included directly in match_tables.cpp */

template<> void MatchTable::write_next_table_regs(Target::Flatrock::mau_regs &regs, Table *tbl) {
    error(lineno, "%s:%d: Flatrock match_table not implemented yet!", __FILE__, __LINE__);
}

template<> void MatchTable::write_regs(Target::Flatrock::mau_regs &regs, int type, Table *result) {
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
    auto &mrd = regs.ppu_mrd.rf;
    auto &minput = regs.ppu_minput.rf;
    if (gress == GHOST) {
        mrd.mrd_pred_cfg.gst_tables |= 1 << logical_id;
        minput.minput_mpr.gst_tables |= 1 << logical_id;
    } else {
        mrd.mrd_pred_cfg.main_tables |= 1 << logical_id;
        minput.minput_mpr.main_tables |= 1 << logical_id; }
    if (always_run || pred.empty())
        minput.minput_mpr.always_run = 1;
    mrd.mrd_l2p_xbar[physical_id].en = 1;
    mrd.mrd_l2p_xbar[physical_id].logical_table = logical_id;
    mrd.mrd_p2l_xbar[logical_id].en = 1;
    mrd.mrd_p2l_xbar[logical_id].phy_table = physical_id;
    if (get_actions())
        mrd.mrd_imem_cfg.active_en |= 1 << physical_id;
    minput.minput_mpr_act[logical_id].activate = 1 << physical_id;

    /* action/imem setup */
    // FIXME -- factor with common code in MatchTable::write_common_regs
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
    }
    regs.ppu_mrd.mrd_imem_map_erf.mrd_imem_map[physical_id][12].data = adr_default;
}
