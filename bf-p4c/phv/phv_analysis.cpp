#include "phv_analysis.h"
#include "bf-p4c/common/live_range_overlay.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/phv/allocate_virtual_containers.h"
#include "bf-p4c/phv/check_fitting.h"
#include "bf-p4c/phv/cluster_phv_bind.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/cluster_phv_slicing.h"
#include "bf-p4c/phv/cluster_phv_overlay.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_analysis_api.h"
#include "bf-p4c/phv/phv_analysis_validate.h"
#include "bf-p4c/phv/phv_assignment_validate.h"
#include "bf-p4c/phv/trivial_alloc.h"
#include "bf-p4c/phv/validate_allocation.h"

PHV_AnalysisPass::PHV_AnalysisPass(
    const BFN_Options &options,
    PhvInfo &phv, PhvUse &uses,
    FieldDefUse &defuse, DependencyGraph &deps)
    : cluster(phv, uses),
      cluster_phv_req(cluster),
      cluster_phv_interference(cluster_phv_req, mutually_exclusive_field_ids),
      action_constraints(phv),
      cluster_phv_mau(cluster_phv_req, action_constraints) {
    if (options.trivial_phvalloc) {
        addPasses({
            new PHV::TrivialAlloc(phv)});
    } else {
        addPasses({
            &uses,                 // use of field in mau, parde
            &cluster,              // cluster analysis
            new ParserOverlay(phv, mutually_exclusive_field_ids),
                                   // produce pairs of mutually exclusive header
                                   // fields, eg. (arpSrc, ipSrc)
            new FindDependencyGraph(phv, deps),
                                   // refresh dependency graph for live range
                                   // analysis
            &defuse,               // refresh defuse
            new LiveRangeOverlay(phv, deps, defuse, mutually_exclusive_field_ids),
                                   // produce pairs of fields that are never live
                                   // in the same stage
            new PHV_Field_Operations(phv),  // PHV field operations analysis
            &cluster_phv_req,      // cluster PHV requirements analysis
            options.phv_interference?
                &cluster_phv_interference: nullptr,
                                   // cluster PHV interference graph analysis
            new PhvInfo::DumpPhvFields(phv, uses),
            &action_constraints,   // collect constraints imposed by actions
            &cluster_phv_mau,      // cluster PHV container placements
                                   // first cut PHV MAU Group assignments
                                   // produces cohabit fields for Table Placement
            options.phv_slicing?
                new Cluster_Slicing(phv, cluster_phv_mau): nullptr,
                                   // slice clusters into smaller clusters
                                   // attempt packing with reduced width requirements
                                   // slicing improves overlay possibilities due to less width
                                   // although number & mutual exclusion of fields don't change
                                   // TODO: Cluster Slicing should recursively slice further as
                                   // needed; further slicing unallocated clusters
                                   // improves chances of packing and/or overlay.
                                   // implement as {(Slicing)+,Overlay} or {Slicing,Overlay}+
            options.phv_overlay?
                new Cluster_PHV_Overlay(cluster_phv_mau, cluster_phv_interference): nullptr,
                                   // overlay clusters to MAU groups
                                   // need cluster_phv_interference
                                   // func mutually_exclusive(f1, f2)
                                   // overlay unallocated clusters to clusters & MAU groups
            options.ignorePHVOverflow ? new AllocateVirtualContainers(phv, uses) : nullptr,
                                   // Remove any fields not fully allocated and allocate them
                                   // into virtual containers instead
            new Build_PHV_Analysis_APIs(phv, uses),
                                   // populate field_container_map in the PHV_Analysis_API
                                   // attached to each PhvInfo::Field object in phv
            new PHV_Bind(phv, uses, cluster_phv_mau),
                                   // fields bound to PHV containers
                                   // later passes assume that phv alloc info
                                   // is sorted in field bit order, msb first
                                   // sorting done by phv_bind
            new PHV_Analysis_Validate(phv, cluster_phv_mau, uses),
                                   // phv analysis results validation
            new PHV_Assignment_Validate(phv),
                                   // phv assignment results validation
            new CheckFitting(phv, uses, options.ignorePHVOverflow),
                                   // fail if there are clusters remaining that have not
                                   // been assigned to container groups; only warn if
                                   // options.ignorePHVOverflow == true.
            new PHV::ValidateAllocation(phv),
            new PHV::ValidateActions(phv, false, true, false)
        }); }

    setName("PHV Analysis");
}

