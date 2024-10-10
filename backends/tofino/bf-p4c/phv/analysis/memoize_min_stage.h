#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_

#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"

// MemoizeStage save table stage mapping to static vairables of PhvInfo object,
// both physical stage and min stage.
class MemoizeStage : public Inspector {
 private:
    const DependencyGraph& dg;  // for min stages
    const MauBacktracker& backtracker;  // for physical stages

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;

 public:
    explicit MemoizeStage(const DependencyGraph& d, const MauBacktracker& backtracker)
        : dg(d), backtracker(backtracker) {}
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_  */
