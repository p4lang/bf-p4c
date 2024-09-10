#ifndef EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_

#include "ir/ir.h"
#include "lib/json.h"

#include "bf-p4c-options.h"
#include "backends/tofino/logging/pass_manager.h"
#include "backends/tofino/mau/payload_gateway.h"
#include "backends/tofino/mau/table_dependency_graph.h"
#include "backends/tofino/mau/table_mutex.h"
#include "backends/tofino/mau/table_layout.h"
#include "backends/tofino/phv/mau_backtracker.h"

class TableSummary;

class TableAllocPass : public Logging::PassManager {
 private:
    IgnoreTableDeps                     ignore;
    SplitAttachedInfo                   att_info;
    TablesMutuallyExclusive             mutex;
    ActionMutuallyExclusive             action_mutex;
    const BFN_Options&                  options;
    LayoutChoices                       *lc = nullptr;
    SharedIndirectAttachedAnalysis      *siaa = nullptr;

 public:
    static int table_placement_round;
    TableAllocPass(const BFN_Options& options, PhvInfo& phv,
                    DependencyGraph &deps, TableSummary &, Util::JsonObject*,
                    MauBacktracker &mau_backtracker);
};


#endif /* EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_ */
