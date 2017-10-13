/* mau stage template specializations for tofino -- #included directly in top-level stage.cpp */

template<> void Stage::write_regs(Target::Tofino::mau_regs &regs) {
    write_common_regs<Target::Tofino>(regs);
    auto &merge = regs.rams.match.merge;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno == 0) {
            merge.predication_ctl[gress].start_table_fifo_delay0 = pred_cycle(gress) - 1;
            merge.predication_ctl[gress].start_table_fifo_delay1 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
        } else switch (stage_dep[gress]) {
        case MATCH_DEP:
            merge.predication_ctl[gress].start_table_fifo_delay0 =
                this[-1].pipelength(gress) - this[-1].pred_cycle(gress) + pred_cycle(gress) - 1;
            merge.predication_ctl[gress].start_table_fifo_delay1 =
                this[-1].pipelength(gress) - this[-1].pred_cycle(gress);
            merge.predication_ctl[gress].start_table_fifo_enable = 3;
            break;
        case ACTION_DEP:
            merge.predication_ctl[gress].start_table_fifo_delay0 = 1;
            merge.predication_ctl[gress].start_table_fifo_delay1 = 0;
            merge.predication_ctl[gress].start_table_fifo_enable = 1;
            break;
        case CONCURRENT:
            merge.predication_ctl[gress].start_table_fifo_enable = 0;
            break;
        default:
            assert(0); }
        if (stageno != 0) {
            regs.dp.cur_stage_dependency_on_prev[gress] = MATCH_DEP - stage_dep[gress];
            if (stage_dep[gress] == CONCURRENT)
                regs.dp.stage_concurrent_with_prev |= 1U << gress; }
        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = MATCH_DEP - this[1].stage_dep[gress];
        else if (AsmStage::numstages() < Target::Tofino::NUM_MAU_STAGES)
            regs.dp.next_stage_dependency_on_cur[gress] = 2;
        /* FIXME -- making this depend on the dependency of the next stage seems wrong */
        auto &deferred_eop_bus_delay = regs.rams.match.adrdist.deferred_eop_bus_delay[gress];
        if (stageno == AsmStage::numstages()-1) {
            if (AsmStage::numstages() < Target::Tofino::NUM_MAU_STAGES)
                deferred_eop_bus_delay.eop_output_delay_fifo = 0;
            else
                deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 1;
        } else if (this[1].stage_dep[gress] == MATCH_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = pipelength(gress) - 1;
        else if (this[1].stage_dep[gress] == ACTION_DEP)
            deferred_eop_bus_delay.eop_output_delay_fifo = 1;
        else
            deferred_eop_bus_delay.eop_output_delay_fifo = 0;
        deferred_eop_bus_delay.eop_delay_fifo_en = 1;
    }

    bitvec in_use = match_use[INGRESS] | action_use[INGRESS] | action_set[INGRESS];
    bitvec eg_use = match_use[EGRESS] | action_use[EGRESS] | action_set[EGRESS];
    if (options.match_compiler) {
        /* the glass compiler occasionally programs extra uses of random registers on
         * busses where it doesn't actually use them.  Sometimes, these regs
         * are in use by the other thread, so rely on the deparser to correctly
         * set the Phv::use info and strip out registers it says are used by
         * the other thread */
        in_use -= Deparser::PhvUse(EGRESS);
        eg_use -= Deparser::PhvUse(INGRESS); }
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
            regs.dp.phv_ingress_thread_alu[i][j] = regs.dp.phv_ingress_thread_imem[i][j] =
            regs.dp.phv_ingress_thread[i][j] = in_use.getrange(8*phv_use_transpose[i][j], 8);
            regs.dp.phv_egress_thread_alu[i][j] = regs.dp.phv_egress_thread_imem[i][j] =
            regs.dp.phv_egress_thread[i][j] = eg_use.getrange(8*phv_use_transpose[i][j], 8); } }
}
