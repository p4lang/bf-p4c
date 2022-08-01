#ifndef BF_P4C_PHV_V2_PHV_KIT_H_
#define BF_P4C_PHV_V2_PHV_KIT_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/action_source_tracker.h"
#include "bf-p4c/phv/alloc_setting.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/collect_strided_headers.h"
#include "bf-p4c/phv/fieldslice_live_range.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/v2/action_packing_validator.h"
#include "bf-p4c/phv/v2/parser_packing_validator.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/smart_fieldslice_packing.h"

namespace PHV {
namespace v2 {

/// PhvKit is a collection of const references to misc passes that PHV allocation depends on.
/// It also provides some helper methods.
struct PhvKit {
    // PHV fields and clot info.
    const PhvInfo& phv;
    const ClotInfo& clot;

    // clustering results (super clusters) and no_pack constraint found during clustering.
    const Clustering& clustering;

    // defuses and action constraints.
    const PhvUse& uses;
    const FieldDefUse& defuse;

    // action-related constraints
    const ActionPhvConstraints& actions;
    const ActionSourceTracker& source_tracker;

    // packing validator that checks whether a set of packing is valid
    // in terms of action phv constraints.
    const ActionPackingValidator* packing_validator;

    /// parser packing validator checks whether a packing would break parser constraints.
    const ParserPackingValidator* parser_packing_validator;

    // parser-related
    const MapFieldToParserStates& field_to_parser_states;
    const CalcParserCriticalPath& parser_critical_path;
    const CollectParserInfo& parser_info;
    const CollectStridedHeaders& strided_headers;

    // physical live range (available only after table has been allocated)
    const PHV::FieldSliceLiveRangeDB& physical_liverange_db;

    // pragma
    const PHV::Pragmas& pragmas;

    // misc allocation settings.
    const AllocSetting& settings;

    // Collect field packing that table/ixbar would benefit from.
    const TableFieldPackOptimization& table_pack_opt;

    // provide access to information of last round of table placement.
    const MauBacktracker& mau;

    PhvKit(const PhvInfo& phv, const ClotInfo& clot, const Clustering& clustering,
           const PhvUse& uses, const FieldDefUse& defuse, const ActionPhvConstraints& actions,
           const MapFieldToParserStates& field_to_parser_states,
           const CalcParserCriticalPath& parser_critical_path, const CollectParserInfo& parser_info,
           const CollectStridedHeaders& strided_headers,
           const FieldSliceLiveRangeDB& physical_liverange_db,
           const ActionSourceTracker& source_tracker, const Pragmas& pragmas,
           const AllocSetting& settings, const TableFieldPackOptimization& table_pack_opt,
           const MauBacktracker& mau)
        : phv(phv),
          clot(clot),
          clustering(clustering),
          uses(uses),
          defuse(defuse),
          actions(actions),
          source_tracker(source_tracker),
          packing_validator(new ActionPackingValidator(source_tracker, uses)),
          parser_packing_validator(new ParserPackingValidator(
              phv, field_to_parser_states, parser_info, defuse, pragmas.pa_no_init())),
          field_to_parser_states(field_to_parser_states),
          parser_critical_path(parser_critical_path),
          parser_info(parser_info),
          strided_headers(strided_headers),
          physical_liverange_db(physical_liverange_db),
          pragmas(pragmas),
          settings(settings),
          table_pack_opt(table_pack_opt),
          mau(mau) {}

    const SymBitMatrix& mutex() const {
        return phv.field_mutex();
    }

    // has_pack_conflict should be used as the only source of pack conflict checks.
    // It checks mutex + pack conflict from mau + no pack constraint from cluster.
    bool has_pack_conflict(const PHV::FieldSlice &fs1, const PHV::FieldSlice &fs2) const;

    // return true if field is used and not padding.
    bool is_referenced(const PHV::Field* f) const { return !f->padding && uses.is_referenced(f); };

    /// @returns a copy of all SuperClusters from clustering_i.
    std::list<PHV::SuperCluster*> make_superclusters() const {
        return clustering.cluster_groups();
    }

    // @returns a slicing iterator.
    PHV::Slicing::IteratorInterface* make_slicing_ctx(const PHV::SuperCluster* sc) const;

    // @returns true if @p a and @p b can be overlaid,
    // because of their physical live ranges are disjoint and both fieldslices are
    // qualified to be overlaid:
    // (1) not pov, deparsed_to_tm, nor is_invalidate_from_arch.
    // (2) not in pa_no_overlay.
    bool can_physical_liverange_be_overlaid(const PHV::AllocSlice& a,
                                            const PHV::AllocSlice& b) const;

    /// @returns true if super cluster is fully allocated to clot.
    static bool is_clot_allocated(const ClotInfo& clots, const PHV::SuperCluster& sc);

    /// @returns the container groups available on this Device. All fieldslices in
    /// a cluster must be allocated to the same container group.
    static std::list<PHV::ContainerGroup *> make_device_container_groups();

    /// clear alloc_slices allocated in @p phv, if any.
    static void clear_slices(PhvInfo& phv);

    /// Translate each AllocSlice in @p alloc into a PHV::Field::alloc_slice and
    /// attach it to the PHV::Field it slices.
    static void bind_slices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv);

    /// Merge Adjacent AllocSlices of the same field into one AllocSlice.
    /// MUST run this after allocation because later passes assume that
    /// phv alloc info is sorted in field bit order, msb first.
    static void sort_and_merge_alloc_slices(PhvInfo& phv);

    /// remove singleton metadata slice list. This was introduced because some metadata fields are
    /// placed in a slice list, but they do not need to be. Removing them from slice list allows
    /// allocator to try more possible starting positions.
    /// TODO(yumin): we should fix this in make_clusters and remove this function.
    static std::list<PHV::SuperCluster*> remove_singleton_metadata_slicelist(
            const std::list<PHV::SuperCluster*>& cluster_groups);

    /// Remove unreferenced clusters from @p cluster_groups_input. For example, a singleton
    /// super cluster with only one padding field.
    static std::list<PHV::SuperCluster*> remove_unref_clusters(
        const PhvUse& uses, const std::list<PHV::SuperCluster*>& cluster_groups_input);

    /// @returns super clusters with fully-clotted clusters removed from @p clusters.
    static std::list<PHV::SuperCluster*> remove_clot_allocated_clusters(
            const ClotInfo& clot, std::list<PHV::SuperCluster*> clusters);

    /// Check if the supercluster has field slice that requires strided
    /// allocation. Merge all related stride superclusters.
    static std::list<PHV::SuperCluster*> create_strided_clusters(
            const CollectStridedHeaders& strided_headers,
            const std::list<PHV::SuperCluster*>& cluster_groups);
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_PHV_KIT_H_ */
