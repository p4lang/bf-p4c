/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

template<> void Stage::write_concurrency_regs(Target::JBay::mau_regs &regs, gress_t gress) {
    if (stageno != 0)
        regs.dp.cur_stage_dependency_on_prev[gress] = stage_dep[gress] != MATCH_DEP;
    if (stageno != AsmStage::numstages()-1)
        regs.dp.next_stage_dependency_on_cur[gress] = this[1].stage_dep[gress] != MATCH_DEP;
    else if (AsmStage::numstages() < NUM_MAU_STAGES)
        regs.dp.next_stage_dependency_on_cur[gress] = 1;
}
