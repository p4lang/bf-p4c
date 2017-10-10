/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

template<> void Stage::write_regs(Target::JBay::mau_regs &regs) {
    write_common_regs<Target::JBay>(regs);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (stageno != 0)
            regs.dp.cur_stage_dependency_on_prev[gress] = stage_dep[gress] != MATCH_DEP;
        if (stageno != AsmStage::numstages()-1)
            regs.dp.next_stage_dependency_on_cur[gress] = this[1].stage_dep[gress] != MATCH_DEP;
        else if (AsmStage::numstages() < Target::JBay::NUM_MAU_STAGES)
            regs.dp.next_stage_dependency_on_cur[gress] = 1; }
    auto &merge = regs.rams.match.merge;
    merge.mpr_stage = stageno;
    merge.pred_stage_id = stageno;
    if (stageno != AsmStage::numstages()-1) {
        merge.mpr_bus_dep.mpr_bus_dep_egress = this[1].stage_dep[EGRESS] != MATCH_DEP;
        merge.mpr_bus_dep.mpr_bus_dep_ingress = this[1].stage_dep[INGRESS] != MATCH_DEP;
    }
}
