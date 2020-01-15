#include "phv_analysis.h"
#include "bf-p4c/phv/add_initialization.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/parde_phv_constraints.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/table_phv_constraints.h"
#include "bf-p4c/phv/trivial_alloc.h"
#include "bf-p4c/phv/add_special_constraints.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/phv/analysis/dark.h"
#include "bf-p4c/phv/analysis/deparser_zero.h"
#include "bf-p4c/phv/analysis/memoize_min_stage.h"
#include "bf-p4c/phv/analysis/jbay_phv_analysis.h"
#include "bf-p4c/phv/analysis/mocha.h"
#include "bf-p4c/phv/analysis/mutex_overlay.h"
#include "bf-p4c/mau/action_mutex.h"

class PhvInfo;

PHV_AnalysisPass::PHV_AnalysisPass(
        const BFN_Options &options,
        PhvInfo &phv,
        PhvUse &uses,
        const ClotInfo& clot,
        FieldDefUse &defuse,
        DependencyGraph &deps,
        const DeparserCopyOpt &decaf,
        MauBacktracker& alloc)
    : Logging::PassManager("phv_allocation_"),
      table_alloc(alloc),
      pragmas(phv),
      field_to_parser_states(phv),
      parser_critical_path(phv),
      critical_path_clusters(parser_critical_path),
      pack_conflicts(phv, deps, table_mutex, alloc, action_mutex),
      action_constraints(phv, uses, pack_conflicts, tableActionsMap, deps),
      domTree(flowGraph),
      meta_live_range(phv, deps, defuse, pragmas, uses, alloc),
      dark_live_range(phv, clot, deps, defuse, pragmas, uses, action_constraints, domTree,
              tableActionsMap, alloc),
      meta_init(phv, defuse, deps, pragmas.pa_no_init(), meta_live_range, action_constraints,
              domTree, alloc),
      clustering(phv, uses, pack_conflicts, pragmas.pa_container_sizes(), action_constraints),
      strided_headers(phv) {
    if (options.trivial_phvalloc) {
        addPasses({
            new PHV::TrivialAlloc(phv)});
    } else {
        addPasses({
            // Identify uses of fields in MAU, PARDE
            &uses,
            new PhvInfo::DumpPhvFields(phv, uses),
            // Determine candidates for mocha PHVs.
            Device::phvSpec().hasContainerKind(PHV::Kind::mocha)
                ? new CollectMochaCandidates(phv, uses) : nullptr,
            Device::phvSpec().hasContainerKind(PHV::Kind::dark)
                ? new CollectDarkCandidates(phv, uses) : nullptr,
            // Pragmas need to be run here because the later passes may add constraints encoded as
            // pragmas to various fields after the initial pragma processing is done.
            // parse and fold PHV-related pragmas
            &pragmas,
            // Identify fields for deparsed-zero optimization
            new DeparserZeroOptimization(phv, defuse, pragmas.pa_deparser_zero(), clot),
            // Produce pairs of mutually exclusive header fields, e.g. (arpSrc, ipSrc)
            new MutexOverlay(phv, pragmas),
            // map fields to parser states
            &field_to_parser_states,
            // calculate ingress/egress parser's critical path
            &parser_critical_path,
            // Refresh dependency graph for live range analysis
            new FindDependencyGraph(phv, deps, "", "Just Before PHV allocation"),
            new MemoizeMinStage(phv, deps),
            // Refresh defuse
            &defuse,
            // Analysis of operations on PHV fields.
            // XXX(Deep): Combine with ActionPhvConstraints?
            new PHV_Field_Operations(phv),
            // Mutually exclusive tables information
            &table_mutex,
            // Mutually exclusive action information
            &action_mutex,
            // Collect list of fields that cannot be packed together based on the previous round of
            // table allocation (only useful if we backtracked from table placement to PHV
            // allocation)
            &pack_conflicts,
            &action_constraints,
            // Collect constraints related to the way fields are used in tables.
            new TablePhvConstraints(phv, action_constraints, pack_conflicts),
            // Collect constraints related to the way fields are used in the parser/deparser.
            new PardePhvConstraints(phv, pragmas.pa_container_sizes()),
            &critical_path_clusters,
            // This has to be the last pass in the analysis phase as it adds artificial constraints
            // to fields and uses results of some of the above passes (specifically
            // action_constraints).
            new AddSpecialConstraints(phv, pragmas, action_constraints, decaf),
            // build dominator tree for the program, also populates the flow graph internally.
            &domTree,
            &tableActionsMap,
            // Determine `ideal` live ranges for metadata fields in preparation for live range
            // shrinking that will be effected during and post AllocatePHV.
            &meta_live_range,
            (Device::phvSpec().hasContainerKind(PHV::Kind::dark) &&
             !options.disable_dark_allocation)
                ? &dark_live_range : nullptr,
            // Metadata initialization pass should be run after the metadata live range is
            // calculated.
            &meta_init,
            // Determine parser constant extract constraints, to be run before Clustering.
            Device::currentDevice() == Device::TOFINO ? new TofinoParserConstantExtract(phv) :
                nullptr,
            // From this point on, we are starting to transform the PHV related data structures.
            // Before this is all analysis that collected constraints for PHV allocation to use.
            &clustering,
            new PhvInfo::DumpPhvFields(phv, uses),
            &table_ids,

            &strided_headers,

            new AllocatePHV(clustering, uses, defuse, clot, pragmas, phv, action_constraints,
                    field_to_parser_states, parser_critical_path, critical_path_clusters,
                    table_alloc, meta_init, dark_live_range, table_ids,
                    strided_headers),
            new AddSliceInitialization(phv, defuse, deps, meta_live_range),
            &defuse
        }); }

    setName("PHV Analysis");
}
