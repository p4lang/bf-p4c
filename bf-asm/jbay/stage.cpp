/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

template<> void Stage::write_regs(Target::JBay::mau_regs &regs) {
    write_common_regs<Target::JBay>(regs);
    auto &merge = regs.rams.match.merge;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno == 0) {
            merge.predication_ctl[gress].start_table_fifo_delay0 = pred_cycle(gress) - 2;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else if (stage_dep[gress] == MATCH_DEP) {
            merge.predication_ctl[gress].start_table_fifo_delay0 =
                this[-1].pipelength(gress) - this[-1].pred_cycle(gress) + pred_cycle(gress) - 3;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else {
            assert(stage_dep[gress] == ACTION_DEP);
            merge.predication_ctl[gress].start_table_fifo_delay0 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 0; }
        if (stageno != 0)
            regs.dp.cur_stage_dependency_on_prev[gress] = stage_dep[gress] != MATCH_DEP;
        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = this[1].stage_dep[gress] != MATCH_DEP;
        else if (AsmStage::numstages() < Target::JBay::NUM_MAU_STAGES)
            regs.dp.next_stage_dependency_on_cur[gress] = 1;
        /* FIXME -- making this depend on the dependency of the next stage seems wrong */
        auto &deferred_eop_bus_delay = regs.rams.match.adrdist.deferred_eop_bus_delay[gress];
        deferred_eop_bus_delay.eop_internal_delay_fifo = pred_cycle(gress) + 2;
        if (stageno == AsmStage::numstages()-1) {
            if (AsmStage::numstages() < Target::JBay::NUM_MAU_STAGES)
                deferred_eop_bus_delay.eop_output_delay_fifo = 1;
            else
                deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 2;
        } else if (this[1].stage_dep[gress] == MATCH_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 2;
        else
            deferred_eop_bus_delay.eop_output_delay_fifo = 1;
        deferred_eop_bus_delay.eop_delay_fifo_en = 1;
        if (stageno != AsmStage::numstages()-1 && this[1].stage_dep[gress] == MATCH_DEP)
            merge.mpr_thread_delay[gress] = pipelength(gress) - pred_cycle(gress) - 4;
        else
            merge.mpr_thread_delay[gress] = 0; }

    if (stageno == 0) {
        /* MFerrera: "After some debug on the emulator, we've found a programming issue due to
        * incorrect documentation and CSR description of match_ie_input_mux_sel in JBAY"
        * MAU Stage 0 must always be configured to source iPHV from Parser-Arbiter
        * Otherwise, MAU stage 0 is configured as match-dependent on Parser-Arbiter */
        regs.dp.match_ie_input_mux_sel |= 3;
    }
    merge.mpr_stage = stageno;
    merge.pred_stage_id = stageno;
    if (stageno != AsmStage::numstages()-1) {
        merge.mpr_bus_dep.mpr_bus_dep_egress = this[1].stage_dep[EGRESS] != MATCH_DEP;
        merge.mpr_bus_dep.mpr_bus_dep_ingress = this[1].stage_dep[INGRESS] != MATCH_DEP;
    }

    bitvec in_use = match_use[INGRESS] | action_use[INGRESS] | action_set[INGRESS];
    bitvec eg_use = match_use[EGRESS] | action_use[EGRESS] | action_set[EGRESS];
    /* FIXME -- if the regs are live across a stage (even if not used in that stage) they
     * need to be set in the thread registers.  For now we just assume if they are used
     * anywhere, they need to be marked as live */
    in_use |= Phv::use(INGRESS);
    eg_use |= Phv::use(EGRESS);
    static const int phv_use_transpose[2][14] = {
        {  0,  1,  2,  3,  8,  9, 10, 11, 16, 17, 18, 19, 20, 21 },
        {  4,  5,  6,  7, 12, 13, 14, 15, 22, 23, 24, 25, 26, 27 } };
    // FIXME -- this code depends on the Phv::Register uids matching the
    // FIXME -- mau encoding of phv containers. (FIXME-PHV)
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 14; j++) {
            regs.dp.phv_ingress_thread[i][j] = regs.dp.phv_ingress_thread_imem[i][j] =
                in_use.getrange(10*phv_use_transpose[i][j], 10);
            regs.dp.phv_egress_thread[i][j] = regs.dp.phv_egress_thread_imem[i][j] =
                eg_use.getrange(10*phv_use_transpose[i][j], 10); } }

}
