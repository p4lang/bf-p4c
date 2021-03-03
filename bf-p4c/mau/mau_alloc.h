#ifndef EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_

#include "ir/ir.h"
#include "lib/json.h"

#include "bf-p4c-options.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/payload_gateway.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_layout.h"

class TableSummary;

class TableAllocPass : public Logging::PassManager {
 private:
    IgnoreTableDeps                     ignore;
    LayoutChoices                       lc;
    SharedIndirectAttachedAnalysis      siaa;
    SplitAttachedInfo                   att_info;
    TablesMutuallyExclusive             mutex;
    ActionMutuallyExclusive             action_mutex;
    bool                                disable_long_branch;

 public:
    static int table_placement_round;
    TableAllocPass(const BFN_Options& options, PhvInfo& phv,
                    DependencyGraph &deps, TableSummary &, Util::JsonObject*);
    void setDisableLongBranch() { disable_long_branch = true; }
};


#endif /* EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_ */
