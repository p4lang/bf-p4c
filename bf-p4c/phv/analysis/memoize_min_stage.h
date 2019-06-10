#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_

#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/phv_fields.h"

class MemoizeMinStage : public Inspector {
 private:
    PhvInfo& phv;
    const DependencyGraph& dg;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;

 public:
    explicit MemoizeMinStage(PhvInfo& p, const DependencyGraph& d)
        : phv(p), dg(d) { }
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_ANALYSIS_MEMOIZE_MIN_STAGE_H_  */
