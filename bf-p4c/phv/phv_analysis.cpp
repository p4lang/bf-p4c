#include "phv_analysis.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/parde_phv_constraints.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/table_phv_constraints.h"
#include "bf-p4c/phv/trivial_alloc.h"
#include "bf-p4c/phv/add_special_constraints.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/phv/analysis/deparser_zero.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "bf-p4c/phv/analysis/jbay_phv_analysis.h"
#include "bf-p4c/phv/analysis/dark.h"
#include "bf-p4c/phv/analysis/mocha.h"
#include "bf-p4c/mau/action_mutex.h"

class PhvInfo;

PHV_AnalysisPass::PHV_AnalysisPass(
        const BFN_Options &options,
        PhvInfo &phv,
        PhvUse &uses,
        const ClotInfo& clot,
        FieldDefUse &defuse,
        DependencyGraph &deps,
        MauBacktracker& alloc)
    : Logging::PassManager("phv_allocation_"),
      table_alloc(alloc),
      clustering(phv, uses, pack_conflicts),
      parser_critical_path(phv),
      critical_path_clusters(parser_critical_path),
      pack_conflicts(phv, deps, table_mutex, table_alloc, action_mutex),
      action_constraints(phv, pack_conflicts),
      pragmas(phv, options),
      meta_live_range(phv, deps, defuse, pragmas, uses, table_alloc),
      meta_init(phv, defuse, deps, pragmas.pa_no_init(), meta_live_range, action_constraints) {
    if (options.trivial_phvalloc) {
        addPasses({
            new PHV::TrivialAlloc(phv)});
    } else {
        addPasses({
            &uses,                 // use of field in mau, parde
            new PhvInfo::DumpPhvFields(phv, uses),
#if HAVE_JBAY
            // Determine candidates for mocha PHVs.
            new CollectMochaCandidates(phv, uses),
            new CollectDarkCandidates(phv, uses),
#endif
            &pragmas,              // parse and fold PHV-related pragmas
            new DeparserZeroOptimization(phv, pragmas.pa_deparser_zero(), clot),
                                   // identify fields for deparsed zero optimization
            new ParserOverlay(phv, pragmas),
                                   // produce pairs of mutually exclusive header
                                   // fields, eg. (arpSrc, ipSrc)
            &parser_critical_path,
                                   // calculate ingress/egress parser's critical path
            new FindDependencyGraph(phv, deps),
                                   // refresh dependency graph for live range
                                   // analysis
            &defuse,               // refresh defuse
            new PHV_Field_Operations(phv),  // PHV field operations analysis
            &table_mutex,          // Table mutual exclusion information
            &action_mutex,         // Mutually exclusive action information
            &pack_conflicts,       // collect list of fields that cannot be packed together based on
                                   // first round of table allocation (only useful if we backtracked
                                   // from table placement to PHV allocation)
            new TablePhvConstraints(phv),
            new PardePhvConstraints(phv, pragmas.pa_container_sizes()),
            &critical_path_clusters,
            &action_constraints,

            // This has to be the last pass in the analysis phase as it adds artificial constraints
            // to fields and uses results of some of the above passes (specifically
            // action_constraints).
            new AddSpecialConstraints(phv, pragmas, action_constraints),

            // Determine `ideal` live ranges for metadata fields in preparation for live range
            // shrinking that will be effected during and post AllocatePHV.
            &meta_live_range,
            // Metadata initialization pass should be run after the metadata live range is
            // calculated.
            &meta_init,

#if HAVE_JBAY
            options.jbay_analysis ? new JbayPhvAnalysis(phv, uses, deps, defuse, action_constraints)
                : nullptr,
#endif
            // From this point on, we are starting to transform the PHV related data structures.
            // Before this is all analysis that collected constraints for PHV allocation to use.
            &clustering,           // cluster analysis
            new PhvInfo::DumpPhvFields(phv, uses),
            new AllocatePHV(clustering, uses, defuse, clot, pragmas, phv, action_constraints,
                    critical_path_clusters, meta_init),
            new AddMetadataInitialization(phv, defuse, meta_live_range),
            &defuse
        }); }

    setName("PHV Analysis");
}
