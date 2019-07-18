#ifndef EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_layout.h"

class TableSummary;

class TableAllocPass : public Logging::PassManager {
 private:
    TablesMutuallyExclusive mutex;
    SharedIndirectAttachedAnalysis siaa;
    LayoutChoices           lc;

 public:
    TableAllocPass(const BFN_Options& options, PhvInfo& phv, DependencyGraph &deps, TableSummary &);
};

#endif /* EXTENSIONS_BF_P4C_MAU_MAU_ALLOC_H_ */
