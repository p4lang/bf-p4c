#include "phv_analysis.h"

#include <initializer_list>

#include "bf-p4c/phv/add_initialization.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/parde_phv_constraints.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/table_phv_constraints.h"
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
#include "bf-p4c/logging/event_logger.h"
#include "ir/visitor.h"

class PhvInfo;

PHV_AnalysisPass::PHV_AnalysisPass(
        const BFN_Options &options,
        PhvInfo &phv,
        PhvUse &uses,
        const ClotInfo& clot,
        FieldDefUse &defuse,
        DependencyGraph &deps,
        const DeparserCopyOpt &decaf,
        MauBacktracker& alloc,
        CollectPhvLoggingInfo *phvLoggingInfo)
    : Logging::PassManager("phv_allocation_"),
      phv_i(phv),
      uses_i(uses),
      clot_i(clot),
      defuse_i(defuse),
      deps_i(deps),
      options_i(options),
      table_alloc(alloc),
      pragmas(phv),
      field_to_parser_states(phv),
      parser_critical_path(phv),
      critical_path_clusters(parser_critical_path),
      pack_conflicts(phv, deps, table_mutex, alloc, action_mutex, pragmas.pa_no_pack()),
      action_constraints(phv, uses, pack_conflicts, tableActionsMap, deps),
      domTree(flowGraph),
      meta_live_range(phv, deps, defuse, pragmas, uses, alloc),
      dark_live_range(phv, clot, deps, defuse, pragmas, uses, action_constraints, domTree,
              tableActionsMap, alloc),
      meta_init(phv, defuse, deps, pragmas.pa_no_init(), meta_live_range, action_constraints,
                domTree, alloc),
      clustering(phv, uses, pack_conflicts, pragmas.pa_container_sizes(), pragmas.pa_byte_pack(),
                 action_constraints),
      strided_headers(phv),
      physical_liverange_db(&alloc, &defuse, phv, pragmas),
      source_tracker(phv),
      utils(phv, clot, clustering, uses, defuse, action_constraints, meta_init, dark_live_range,
            field_to_parser_states, parser_critical_path, parser_info, strided_headers,
            physical_liverange_db, source_tracker, pragmas, settings) {
        auto* validate_allocation = new PHV::ValidateAllocation(phv, clot, physical_liverange_db);
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
            new MutexOverlay(phv, pragmas, uses),
            // map fields to parser states
            &field_to_parser_states,
            // calculate ingress/egress parser's critical path
            &parser_critical_path,
            // Refresh dependency graph for live range analysis
            new FindDependencyGraph(phv, deps, &options, "", "Just Before PHV allocation"),
            new MemoizeStage(deps, alloc),
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
            &table_ids,
            &strided_headers,
            &parser_info,
            phvLoggingInfo,
            &physical_liverange_db,
            &source_tracker,
            new PhvInfo::DumpPhvFields(phv, uses),
            // From this point on, we are starting to transform the PHV related data structures.
            // Before this is all analysis that collected constraints for PHV allocation to use.
            // &table_friendly_packing_backtracker,    // <---
            &clustering,                               //    |
            new AllocatePHV(utils, alloc, phv),        // ----
            new AddSliceInitialization(phv, defuse, deps, meta_live_range),
            &defuse,
            phvLoggingInfo,
            // Validate results of PHV allocation.
            new VisitFunctor([=](){
                validate_allocation->set_physical_liverange_overlay(
                        settings.physical_liverange_overlay);
            }),
            validate_allocation
        });

    phvLoggingInfo->superclusters = &clustering.cluster_groups();
    phvLoggingInfo->pragmas = &pragmas;
    EventLogger::get().iterationChange(invocationCount, EventLogger::AllocPhase::PhvAllocation);
    setName("PHV Analysis");
}

void PHV_AnalysisPass::end_apply() {
    Logging::PassManager::end_apply();
}

namespace {

class IncrementalPHVAllocPass : public Logging::PassManager {
 public:
    IncrementalPHVAllocPass(const std::initializer_list<VisitorRef>& visitors)
        : Logging::PassManager("phv_incremental_allocation_") {
        addPasses(visitors);
    }
};

}  // namespace

Visitor* PHV_AnalysisPass::make_incremental_alloc_pass(
    const ordered_set<PHV::Field *> &temp_vars) {
    return new IncrementalPHVAllocPass({
         &tableActionsMap,
         &uses_i,
         // Refresh dependency graph for live range analysis
         new FindDependencyGraph(phv_i, deps_i, &options_i, "",
                                 "Just Before Incremental PHV allocation"),
         // XXX(yumin): MemoizeMinStage will corrupt existing allocslice liverange, because
         // deparser stage is marked as last stage + 1. DO NOT run it.
         &defuse_i,
         &table_mutex,
         &action_mutex,
         &pack_conflicts, &action_constraints,
         new TablePhvConstraints(phv_i, action_constraints, pack_conflicts),
         // &meta_live_range,
         // LiveRangeShrinking pass has its own MapTablesToActions pass, have to rerun it.
         &meta_init,
         // conservative settings to ensure that Redo tableplacement will produce the same result.
         [this]() {
             this->set_trivial_alloc(false);
             this->set_no_code_change(true);
             this->set_physical_liverange_overlay(false);
         },
         new IncrementalPHVAllocation(temp_vars, utils, phv_i)
        });
}
