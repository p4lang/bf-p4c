#include "phv_analysis.h"
#include "bf-p4c/common/live_range_overlay.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/trivial_alloc.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "bf-p4c/phv/analysis/jbay_phv_analysis.h"

class PhvInfo;

PHV_AnalysisPass::PHV_AnalysisPass(
    const BFN_Options &options,
    PhvInfo &phv, PhvUse &uses, const ClotInfo& clot,
    FieldDefUse &defuse, DependencyGraph &deps)
    : clustering(phv, uses),
      parser_critical_path(phv),
      critical_path_clusters(parser_critical_path),
      pack_conflicts(phv, deps, table_mutex, table_alloc/*, action_mutex*/),
      action_constraints(phv, pack_conflicts),
      pragmas(phv, options) {
    if (options.trivial_phvalloc) {
        addPasses({
            new PHV::TrivialAlloc(phv)});
    } else {
        addPasses({
            // XXX(cole): TODO: insert a pass here that explicitly clears all
            // PHV allocation state (in preparation for backtracking).
            &table_alloc,          // populates table placement information and start of
                                   // backtracking
            &uses,                 // use of field in mau, parde
            new ParserOverlay(phv, mutually_exclusive_field_ids),
                                   // produce pairs of mutually exclusive header
                                   // fields, eg. (arpSrc, ipSrc)
            &parser_critical_path,
                                   // calculate ingress/egress parser's critical path
            new FindDependencyGraph(phv, deps),
                                   // refresh dependency graph for live range
                                   // analysis
            &defuse,               // refresh defuse
            new LiveRangeOverlay(phv, deps, defuse, mutually_exclusive_field_ids),
                                   // produce pairs of fields that are never live
                                   // in the same stage
            new PHV_Field_Operations(phv),  // PHV field operations analysis
            &clustering,           // cluster analysis
            new PhvInfo::DumpPhvFields(phv, uses),
            &critical_path_clusters,
            &table_mutex,
            // &action_mutex,
            &pack_conflicts,       // collect list of fields that cannot be packed together based on
                                   // first round of table allocation (only useful if we backtracked
                                   // from table placement to PHV allocation)
            &action_constraints,
#if HAVE_JBAY
            options.jbay_analysis ? new JbayPhvAnalysis(phv, uses, deps, defuse, action_constraints)
                : nullptr,
#endif      // HAVE_JBAY
            &pragmas,
            new AllocatePHV(mutually_exclusive_field_ids, clustering, uses, clot,
                            pragmas, phv,
                            action_constraints, critical_path_clusters),

            new PHV::ValidateAllocation(phv, clot, mutually_exclusive_field_ids),
            new PHV::ValidateActions(phv, false, true, false)
        }); }

    setName("PHV Analysis");
}
