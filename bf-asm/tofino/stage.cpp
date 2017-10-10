/* mau stage template specializations for tofino -- #included directly in top-level stage.cpp */

template<> void Stage::write_regs(Target::Tofino::mau_regs &regs) {
    write_common_regs<Target::Tofino>(regs);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno != 0) {
            regs.dp.cur_stage_dependency_on_prev[gress] = MATCH_DEP - stage_dep[gress];
            if (stage_dep[gress] == CONCURRENT)
                regs.dp.stage_concurrent_with_prev |= 1U << gress; }
        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = MATCH_DEP - this[1].stage_dep[gress];
        else if (AsmStage::numstages() < Target::Tofino::NUM_MAU_STAGES)
            regs.dp.next_stage_dependency_on_cur[gress] = 2;
    }
}
