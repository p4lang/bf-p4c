#include "mau_alloc.h"

#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/handle_assign.h"
#include "bf-p4c/mau/attached_output.h"
#include "bf-p4c/mau/check_duplicate.h"
#include "bf-p4c/mau/table_seqdeps.h"
#include "bf-p4c/mau/split_gateways.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/mau/remove_noop_gateway.h"

TableAllocPass::TableAllocPass(const BFN_Options& options, PhvInfo& phv, DependencyGraph &deps,
                               TableSummary &summary)
    : Logging::PassManager("table_placement_"), siaa(mutex) {
        addPasses({
            new GatewayOpt(phv),   // must be before TableLayout?  or just TablePlacement?
            new TableLayout(phv, lc),
            new AssignActionHandle(phv),
            new MeterALU::Format(phv, lc),
            new TableFindSeqDependencies(phv),
            new FindDependencyGraph(phv, deps),
            new SpreadGatewayAcrossSeq(phv),
            new CheckTableNameDuplicate,
            new TableFindSeqDependencies(phv),
            new CheckTableNameDuplicate,
            new FindDependencyGraph(phv, deps, "", "Before Table Placement"),
            &mutex,
            &siaa,
            new DumpPipe("Before TablePlacement"),
            new TablePlacement(options, &deps, mutex, phv, lc, siaa, summary),
            new CheckTableNameDuplicate,
            new TableFindSeqDependencies(phv),  // not needed?
            new AssignCounterLRTValues(),
            new CheckTableNameDuplicate,
            new AdjustIXBarExpression,
            new RemoveNoopGateway
        });

    setName("Table Alloc");
}
