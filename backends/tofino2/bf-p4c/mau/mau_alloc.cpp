#include "mau_alloc.h"

#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/handle_assign.h"
#include "bf-p4c/mau/attached_output.h"
#include "bf-p4c/mau/dump_json_graph.h"
#include "bf-p4c/mau/check_duplicate.h"
#include "bf-p4c/mau/table_seqdeps.h"
#include "bf-p4c/mau/split_gateways.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/mau/remove_noop_gateway.h"
#include "bf-p4c/phv/mau_backtracker.h"

int TableAllocPass::table_placement_round = 1;

TableAllocPass::TableAllocPass(const BFN_Options& options, PhvInfo& phv, DependencyGraph &deps,
                               TableSummary &summary, Util::JsonObject* jsonGraph,
                               MauBacktracker &mau_backtracker)
    : Logging::PassManager("table_placement_"_cs), att_info(phv), options(options) {
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
        new FindDependencyGraph(phv, deps, &options, ""_cs, "Before Table Placement"_cs, &summary),
        new DumpJsonGraph(deps, jsonGraph, "Before Table Placement"_cs, false),
        &ignore,
        &mutex,
        &action_mutex,
        siaa,
        new DumpPipe("Before TablePlacement"_cs),
        new TablePlacement(options, deps, mutex, phv, *lc,
                            *siaa, att_info, summary, mau_backtracker),
        new DumpPipe("After TablePlacement"_cs),
        new FindDependencyGraph(phv, deps, &options, ""_cs, "After Table Placement"_cs, &summary),
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
