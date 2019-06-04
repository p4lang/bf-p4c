#include "bf-p4c/phv/analysis/dark_overlay_deps.h"

Visitor::profile_t MemoizeMinStage::init_apply(const IR::Node* root) {
    PhvInfo::clearMinStageInfo();
    LOG4("Printing dependency graph");
    LOG4(dg);
    PhvInfo::setDeparserStage(dg.max_min_stage + 1);

    for (auto& f : phv) {
        LOG4("Field: " << f.name);
        auto allocs = f.get_alloc();
        for (auto& slice : allocs)
            LOG4("  Slice: " << slice);
    }

    return Inspector::init_apply(root);
}

bool MemoizeMinStage::preorder(const IR::MAU::Table* tbl) {
    cstring tblName = TableSummary::getTableName(tbl);
    LOG2("\t" << dg.min_stage(tbl) << " : " << tblName << ", backend name: " << tbl->name);
    PhvInfo::addMinStageEntry(tblName, dg.min_stage(tbl));
    return true;
}

AddDarkOverlayDeps::AddDarkOverlayDeps(
        PhvInfo& p,
        const MapTablesToActions& /* m */,
        const DependencyGraph& d) {
    addPasses({
        new MemoizeMinStage(p, d)
    });
}
