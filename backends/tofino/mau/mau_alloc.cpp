#include "mau_alloc.h"

#include "backends/tofino/common/utils.h"
#include "backends/tofino/mau/gateway.h"
#include "backends/tofino/mau/handle_assign.h"
#include "backends/tofino/mau/attached_output.h"
#include "backends/tofino/mau/dump_json_graph.h"
#include "backends/tofino/mau/check_duplicate.h"
#include "backends/tofino/mau/table_seqdeps.h"
#include "backends/tofino/mau/split_gateways.h"
#include "backends/tofino/mau/table_placement.h"
#include "backends/tofino/mau/ixbar_expr.h"
#include "backends/tofino/mau/remove_noop_gateway.h"
#include "backends/tofino/phv/mau_backtracker.h"

int TableAllocPass::table_placement_round = 1;

TableAllocPass::TableAllocPass(const BFN_Options& options, PhvInfo& phv, DependencyGraph &deps,
                               TableSummary &summary, Util::JsonObject* jsonGraph,
                               MauBacktracker &mau_backtracker)
    : Logging::PassManager("table_placement_"), att_info(phv), options(options) {
    lc = LayoutChoices::create(phv, deps.red_info, att_info);
    siaa = new SharedIndirectAttachedAnalysis(mutex, ignore, action_mutex, *lc);
    addPasses({
        new GatewayOpt(phv),   // must be before TableLayout?  or just TablePlacement?
        new TableLayout(phv, *lc, att_info),  // catches IXBar::realign backtracks
        new AssignActionHandle(phv),
        new MeterALU::Format(phv, *lc),
        new TableFindSeqDependencies(phv),
        new FindDependencyGraph(phv, deps),
        new SpreadGatewayAcrossSeq(phv),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies(phv),
        new CheckTableNameDuplicate,
        new FindDependencyGraph(phv, deps, &options, "", "Before Table Placement", &summary),
        new DumpJsonGraph(deps, jsonGraph, "Before Table Placement", false),
        &ignore,
        &mutex,
        &action_mutex,
        siaa,
        new DumpPipe("Before TablePlacement"),
        new TablePlacement(options, deps, mutex, phv, *lc,
                            *siaa, att_info, summary, mau_backtracker),
        new DumpPipe("After TablePlacement"),
        new FindDependencyGraph(phv, deps, &options, "", "After Table Placement", &summary),
        new TableDependencyGraphSummary(deps),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies(phv),  // not needed?
        new AssignCounterLRTValues(),
        new CheckTableNameDuplicate,
        new AdjustIXBarExpression,
        // RemoveNoopGateway can be removed after MultipleApply2 is in
        new PassIf(
            [&options] {
                return !Device::hasLongBranches() || options.disable_long_branch;
            },
            { new RemoveNoopGateway })
    });

    setName("Table Alloc");
}
