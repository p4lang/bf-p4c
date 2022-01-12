#include "bf-p4c/phv/analysis/memoize_min_stage.h"

Visitor::profile_t MemoizeStage::init_apply(const IR::Node* root) {
    PhvInfo::clearMinStageInfo();
    LOG4("Printing dependency graph");
    LOG4(dg);
    PhvInfo::setDeparserStage(dg.max_min_stage + 1);

    PhvInfo::clearPhysicalStageInfo();
    return Inspector::init_apply(root);
}

bool MemoizeStage::preorder(const IR::MAU::Table* tbl) {
    cstring tblName = TableSummary::getTableName(tbl);
    LOG2("\t" << dg.min_stage(tbl) << " : " << tblName << ", backend name: " << tbl->name);
    PhvInfo::addMinStageEntry(tbl, dg.min_stage(tbl));

    if (backtracker.hasTablePlacement()) {
        const auto& stages = backtracker.stage(tbl, true);
        PhvInfo::setPhysicalStages(tbl, {stages.begin(), stages.end()});
    }
    return true;
}
