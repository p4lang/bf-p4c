#ifndef BF_P4C_PHV_ALLOCATE_PHV_H_
#define BF_P4C_PHV_ALLOCATE_PHV_H_

#include <sstream>
#include <boost/optional.hpp>

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/action_source_tracker.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/dark_live_range.h"
#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/phv/collect_strided_headers.h"
#include "bf-p4c/phv/fieldslice_live_range.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/packing_validator.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/table_phv_constraints.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "bf-p4c/phv/utils/tables_to_ids.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"
#include "smart_fieldslice_packing.h"

namespace PHV {

// AllocSetting holds const references to various alloc settings.
struct AllocSetting {
    /// trivial allocation mode that
    /// (1) do minimal packing, i.e., pack fieldslices only when unavoidable.
    /// (2) assume that there were infinite number of containers.
    /// (3) no metadata or dark initialization, as if no_code_change mode is enabled.
    bool trivial_alloc = false;
    bool no_code_change = false;              // true if disable metadata and dark init.
    bool physical_liverange_overlay = false;  // true if allow physical liverange overlay.
    bool limit_tmp_creation = false;          // true if intermediate tmp value are limited.
};

/// AllocUtils is a collection of const references to misc passes that PHV allocation depends on.
/// It also provides some helper methods that are used by different allocation strategies.
struct AllocUtils {
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
    PackingValidator* packing_validator;

    // Metadata initialization possibilities.
    const LiveRangeShrinking& meta_init;
    // Dark overlay possibilities.
    const DarkOverlay& dark_init;

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
    const TableFieldPackOptimization& tablePackOpt;

    AllocUtils(const PhvInfo& phv, const ClotInfo& clot, const Clustering& clustering,
               const PhvUse& uses, const FieldDefUse& defuse, const ActionPhvConstraints& actions,
               const LiveRangeShrinking& meta_init,
               const DarkOverlay& dark_init,
               const MapFieldToParserStates& field_to_parser_states,
               const CalcParserCriticalPath& parser_critical_path,
               const CollectParserInfo& parser_info, const CollectStridedHeaders& strided_headers,
               const PHV::FieldSliceLiveRangeDB& physical_liverange_db,
               const ActionSourceTracker& source_tracker,
               const PHV::Pragmas& pragmas,
               const AllocSetting& settings,
               const TableFieldPackOptimization& tablePackOpt)
        : phv(phv),
          clot(clot),
          clustering(clustering),
          uses(uses),
          defuse(defuse),
          actions(actions),
          source_tracker(source_tracker),
          packing_validator(new ActionPackingValidator(source_tracker)),
          meta_init(meta_init),
          dark_init(dark_init),
          field_to_parser_states(field_to_parser_states),
          parser_critical_path(parser_critical_path),
          parser_info(parser_info),
          strided_headers(strided_headers),
          physical_liverange_db(physical_liverange_db),
          pragmas(pragmas),
          settings(settings),
          tablePackOpt(tablePackOpt){}

    const SymBitMatrix& mutex() const {
        return phv.field_mutex();
    }

    // has_pack_conflict should be used as the only source of pack conflict checks.
    // It checks mutex + pack conflict from mau + no pack constraint from cluster.
    bool has_pack_conflict(const PHV::Field* f1, const PHV::Field* f2) const {
        if (f1 == f2 || mutex()(f1->id, f2->id)) return false;
        return clustering.no_pack(f1, f2) || actions.hasPackConflict(f1, f2);
    }

    // return true if field is used and not padding.
    bool is_referenced(const PHV::Field* f) const { return !f->padding && uses.is_referenced(f); };

    /// @returns a copy of all SuperClusters from clustering_i.
    std::list<PHV::SuperCluster*> make_superclusters() const {
        return clustering.cluster_groups();
    }

    // @returns a slicing iterator.
    PHV::Slicing::IteratorInterface* make_slicing_ctx(PHV::SuperCluster* sc) const;

    // @returns true if @p a and @p b can be overlaid,
    // because of their physical live ranges are disjoint and both fieldslices are
    // qualified to be overlaid:
    // (1) not pov, deparsed_to_tm, nor is_invalidate_from_arch.
    // (2) not in pa_no_overlay.
    bool can_physical_liverange_be_overlaid(const PHV::AllocSlice& a,
                                            const PHV::AllocSlice& b) const;

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

    /// Update table references of AllocSlices by using the FieldDefUse data
    /// Table references will be used to replace the static min_stage_i/max_stage_i
    /// for determining the AllocSlice liverange in both min-stage and placed-table domain
    static bool update_refs(AllocSlice& slc, const PhvInfo& p, const FieldDefUse::LocPairSet& refs,
                            FieldUse fuse);
    static void update_slice_refs(PhvInfo& phv, const FieldDefUse& defuse);
};

}  // namespace PHV

/// For each field, calculate the possible packing opportunities, if they are allocated
/// in the given order, with fields that are allocated later than it.
/// This object must be created after sorting superclusters, because
/// it takes the sorted clusters to construct.
class FieldPackingOpportunity {
    const ActionPhvConstraints& actions;
    const PhvUse& uses;
    const FieldDefUse& defuse;
    const SymBitMatrix& mutex;
    using FieldPair = std::pair<const PHV::Field*, const PHV::Field*>;
    std::map<const PHV::Field*, int> opportunities;
    std::map<FieldPair, int> opportunities_after;

    /// @returns a vector fields sorted by the show-up order in the sorted clusters.
    std::vector<const PHV::Field*>
    fieldsInOrder(const std::list<PHV::SuperCluster*>& sorted_clusters) const;

    bool isExtractedOrUninitialized(const PHV::Field* f) const;
    bool canPack(const PHV::Field* f1, const PHV::Field* f2) const;

 public:
    /// @p sorted_clusters is a list of clusters that we will allocated, in this order.
    FieldPackingOpportunity(
            const std::list<PHV::SuperCluster*>& sorted_clusters,
            const ActionPhvConstraints& actions,
            const PhvUse& uses,
            const FieldDefUse& defuse,
            const SymBitMatrix& mutex);

    /// How many fields, after @p f is allocated, can be packed with @p f.
    int nOpportunities(const PHV::Field* f) const {
        return opportunities.at(f); }

    /// How many fields, after @p f1 is allocated and @p f2 is not packed with it,
    /// can be packed with @p f1. This is used to decide the priority of this packing,
    /// less opportunities, more priority. For example, if @p f2 can be packed with f1
    /// and f1', but if not packed with f1, there is no opportunities for f1 to be packed with,
    /// while there is a lot of opportunities for f1', then packing f1 and f2 may be a better
    /// choice.
    int nOpportunitiesAfter(const PHV::Field* f1, const PHV::Field* f2) const;
};

/** The score of an Allocation .
 *
 * This score is used in 3 places where decisions have to be made.
 * From bottom to top, they are:
 * 1. Inside tryAllocSliceList, we use this score to find
 *    a best container for a slice list.
 * 2. Inside tryAlloc, to find the best starting position
 *    for slices from a aligned_cluster.
 * 3. Inside BestScoreStrategy, to find the best container_group
 *    for a SuperCluster.
 */
struct AllocScore {
    using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;

    /// IsBetterFunc returns true if left is better than right.
    using IsBetterFunc =
        std::function<bool(const AllocScore& left, const AllocScore& right)>;

    /// type of the name of a metric.
    typedef cstring MetricName;

    /// general metrics
    static const std::vector<MetricName> g_general_metrics;
    ordered_map<MetricName, int> general;

    /// container-kind-specific scores.
    static const std::vector<MetricName> g_by_kind_metrics;
    ordered_map<PHV::Kind, ordered_map<MetricName, int>> by_kind;

    AllocScore() { }

    /** Construct a score from a Transaction.
     *
     * @p alloc: new allocation
     * @p group: the container group where allocations were made to.
     */
    AllocScore(
            const PHV::Transaction& alloc,
            const PhvInfo& phv,
            const ClotInfo& clot,
            const PhvUse& uses,
            const MapFieldToParserStates& field_to_parser_states,
            const CalcParserCriticalPath& parser_critical_path,
            const TableFieldPackOptimization& tablePackOpt,
            FieldPackingOpportunity* packing,
            const int bitmasks);

    AllocScore& operator=(const AllocScore& other) = default;
    AllocScore operator-(const AllocScore& other) const;
    static AllocScore make_lowest() { return AllocScore(); }

 private:
    bitvec calcContainerAllocVec(const ordered_set<PHV::AllocSlice>& slices);

    ContainerAllocStatus
    calcContainerStatus(const PHV::Container& container,
                        const ordered_set<PHV::AllocSlice>& slices);

    void calcParserExtractorBalanceScore(const PHV::Transaction& alloc, const PhvInfo& phv,
                                         const MapFieldToParserStates& field_to_parser_states,
                                         const CalcParserCriticalPath& parser_critical_path);
};

std::ostream& operator<<(std::ostream& s, const AllocScore& score);

/// ScoreContext can compute a alloc score for an PHV::Transaction.
class ScoreContext {
 private:
    cstring name_i;

    /// Opportunities for packing if allocated in some order.
    FieldPackingOpportunity* packing_opportunities_i = nullptr;

    /// stop at first valid allocation instead of comparing socres.
    bool stop_at_first_i = false;

    /// comparison function
    AllocScore::IsBetterFunc is_better_i;

 public:
    ScoreContext(cstring name, bool stop_at_first, AllocScore::IsBetterFunc is_better)
        : name_i(name), stop_at_first_i(stop_at_first), is_better_i(is_better) { }

    AllocScore make_score(
        const PHV::Transaction& alloc,
        const PhvInfo& phv,
        const ClotInfo& clot,
        const PhvUse& uses,
        const MapFieldToParserStates& field_to_parser_states,
        const CalcParserCriticalPath& parser_critical_path,
        const TableFieldPackOptimization& tablePackOpt,
        const int bitmasks = 0) const;

    bool is_better(const AllocScore& left, const AllocScore& right) const {
        return is_better_i(left, right);
    }

    bool stop_at_first() const { return stop_at_first_i; }

    ScoreContext with(FieldPackingOpportunity* packing) {
        auto cloned = *this;
        cloned.packing_opportunities_i = packing;
        return cloned;
    }
};

/// AllocAlignment has two maps used by tryAllocSliceList
struct AllocAlignment {
    /// a slice_alignment maps field slice to start bit location in a container.
    ordered_map<PHV::FieldSlice, int> slice_alignment;
    /// a cluster_alignment maps aligned cluster to start bit location in a container.
    ordered_map<const PHV::AlignedCluster*, int> cluster_alignment;
};

/** A set of functions used in PHV allocation.
 */
class CoreAllocation {
    struct OverlayInfo {
        bool control_flow_overlay;
        bool physical_liverange_overlay;
        bool metadata_overlay;
        bool dark_overlay;
    };
    const PHV::AllocUtils& utils_i;

    // Table allocation information from the previous round.
    // XXX(yumin): legacy, this might actually never be used at all because it is
    // initialized in value instead of references.
    const bool disableMetadataInit;
    // Enforce single gress parser groups
    bool singleGressParserGroups;

    boost::optional<PHV::Transaction> alloc_super_cluster_with_alignment(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster,
        const AllocAlignment& alignment,
        const std::list<const PHV::SuperCluster::SliceList*>& sorted_slice_lists,
        const ScoreContext& score_ctx) const;

    /// returns @p max_n possible alloc alignments for a super cluster vs a container group
    std::vector<AllocAlignment> build_alignments(
        int max_n,
        const PHV::ContainerGroup& container_group,
        const PHV::SuperCluster& super_cluster) const;

    /// Builds a vector of alignments for @p slice_list,
    /// because there are multiple starting point of a slice list
    std::vector<AllocAlignment> build_slicelist_alignment(
      const PHV::ContainerGroup& container_group,
      const PHV::SuperCluster& super_cluster,
      const PHV::SuperCluster::SliceList* slice_list) const;

    bool check_metadata_and_dark_overlay(
        const PHV::Container& c,
        std::vector<PHV::AllocSlice> &complex_overlay_slices,
        std::vector<PHV::AllocSlice> &candidate_slices,
        ordered_set<PHV::AllocSlice> &new_candidate_slices,
        PHV::Transaction &perContainerAlloc,
        ordered_map<const PHV::AllocSlice, OverlayInfo> &overlay_info,
        boost::optional<PHV::Allocation::LiveRangeShrinkingMap> &initNodes,
        boost::optional<ordered_set<PHV::AllocSlice>> &allocedSlices,
        ordered_set<PHV::AllocSlice> &metaInitSlices,
        PHV::Allocation::LiveRangeShrinkingMap &initActions,
        bool &new_overlay_container,
        const PHV::ContainerGroup& group,
        const bool &canDarkInitUseARA) const;

    bool update_new_prim(const PHV::AllocSlice &existingSl, PHV::AllocSlice &newSl) const;

    boost::optional<std::vector<PHV::AllocSlice>> prepare_candidate_slices(
            PHV::SuperCluster::SliceList & slices,
            const PHV::Container& c,
            const PHV::Allocation::ConditionalConstraint& start_positions) const;

    bool try_metadata_overlay(
        const PHV::Container& c,
        boost::optional<ordered_set<PHV::AllocSlice>> &allocedSlices,
        const PHV::AllocSlice &slice,
        boost::optional<PHV::Allocation::LiveRangeShrinkingMap> &initNodes,
        ordered_set<PHV::AllocSlice> &new_candidate_slices,
        ordered_set<PHV::AllocSlice> &metaInitSlices,
        PHV::Allocation::LiveRangeShrinkingMap &initActions,
        PHV::Transaction &perContainerAlloc,
        const PHV::Allocation::MutuallyLiveSlices &alloced_slices,
        PHV::Allocation::MutuallyLiveSlices &actual_cntr_state) const;

    bool try_dark_overlay(
        std::vector<PHV::AllocSlice> &dark_slices,
        PHV::Transaction &perContainerAlloc,
        const PHV::Container& c,
        std::vector<PHV::AllocSlice> &candidate_slices,
        ordered_set<PHV::AllocSlice> &new_candidate_slices,
        bool &new_overlay_container,
        ordered_set<PHV::AllocSlice> &metaInitSlices,
        const PHV::ContainerGroup& group,
        const bool &canDarkInitUseARA) const;

    bool try_pack_slice_list(
        std::vector<PHV::AllocSlice> &candidate_slices,
        PHV::Transaction &perContainerAlloc,
        PHV::Allocation::LiveRangeShrinkingMap &initActions,
        boost::optional<PHV::Allocation::LiveRangeShrinkingMap> &initNodes,
        const PHV::Container& c,
        const PHV::SuperCluster& super_cluster,
        boost::optional<PHV::Allocation::ConditionalConstraints> &action_constraints,
        int &num_bitmasks) const;

    bool try_place_wide_arith_hi(
        const PHV::ContainerGroup& group,
        const PHV::Container& c,
        PHV::SuperCluster::SliceList *hi_slice,
        const PHV::SuperCluster& super_cluster,
        PHV::Transaction &this_alloc,
        const ScoreContext& score_ctx) const;

    bool find_previous_allocation(
        PHV::Container &previous_container,
        ordered_map<PHV::FieldSlice, PHV::AllocSlice> &previous_allocations,
        const PHV::Allocation::ConditionalConstraint& start_positions,
        PHV::SuperCluster::SliceList &slices,
        const PHV::ContainerGroup& group,
        const PHV::Allocation& alloc) const;

 public:
    CoreAllocation(const PHV::AllocUtils& utils, bool disable_metainit)
        : utils_i(utils), disableMetadataInit(disable_metainit) { }

    /// @returns true if @p f can overlay all fields in @p slices.
    static bool can_overlay(
            const SymBitMatrix& mutually_exclusive_field_ids,
            const PHV::Field* f,
            const ordered_set<PHV::AllocSlice>& slices);

    /// @returns true if @p slice can overlay all fields in @p allocated in terms
    /// of physical liveranges.
    bool can_physical_liverange_overlay(const PHV::AllocSlice& slice,
                                        const ordered_set<PHV::AllocSlice>& allocated) const;

    /// @returns true if slice list<-->container constraints are satisfied.
    bool satisfies_constraints(std::vector<PHV::AllocSlice> slices,
                               const PHV::Allocation& alloc) const;

    /// @returns true if field<-->group constraints are satisfied.
    bool satisfies_constraints(const PHV::ContainerGroup& group, const PHV::Field* f) const;

    /// @returns true if field slice<-->group constraints are satisfied.
    bool satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const;

    /// @returns true if @p slice is a valid allocation move given the allocation
    /// status in @p alloc. @p initFields contains a list of fields in this container
    /// that will be initialized via metadata initialization.
    bool satisfies_constraints(
            const PHV::Allocation& alloc,
            const PHV::AllocSlice& slice,
            ordered_set<PHV::AllocSlice>& initFields) const;

    /// @returns true if @p container_group and @p cluster_group satisfy constraints.
    /// XXX(cole): figure out what, if any, constraints should go here.
    static bool satisfies_constraints(const PHV::ContainerGroup& container_group,
                                      const PHV::SuperCluster& cluster_group);

    // Set/Get single-gress Parser groups
    void set_single_gress_parser_group() { singleGressParserGroups = true; }
    bool get_single_gress_parser_group() { return singleGressParserGroups; }


    /** Try to allocate all fields in @p cluster to containers in @p group, using the
     * following techniques (when permissible by constraints), assuming @p alloc is
     * the allocation so far, possibly including allocations to containers in
     * @p group:
     *
     *   - splitting fields across different containers
     *   - packing different fields (or field slices) into the same container
     *   - overlaying fields
     *
     * @returns an allocation of @p cluster to @p group or boost::none if no allocation
     * could be found.
     *
     * Caveats and TODOs:
     *
     *   - Only does container_no_pack + overlay so far.
     *   - Does not handle partially-allocated clusters, eg. from pragmas.
     *   - Does not slice clusters.
     *   - Does not slice fields into non-container sized slices.
     *
     * Uses mutex_i and uses_i.
     */
    boost::optional<PHV::Transaction> try_alloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        PHV::SuperCluster& cluster,
        int max_alignment_tries,
        const ScoreContext& score_ctx) const;

    boost::optional<const PHV::SuperCluster::SliceList*> find_first_unallocated_slicelist(
        const PHV::Allocation& alloc, const std::list<PHV::ContainerGroup*>& container_groups,
        const PHV::SuperCluster& cluster) const;

    /** Helper function that tries to allocate all fields in the deparser zero supercluster
      * @p cluster to containers B0 (for ingress) and B16 (for egress). The DeparserZero analysis
      * earlier in PHV allocation already ensures that these fields can be safely allocated to the
      * zero-ed containers.
      */
    boost::optional<PHV::Transaction> try_deparser_zero_alloc(
        const PHV::Allocation& alloc, PHV::SuperCluster& cluster, PhvInfo& phv) const;

    bool checkDarkOverlay(const std::vector<PHV::AllocSlice>& candidate_slices,
                          const PHV::Transaction& alloc) const;


    /** Helper function for tryAlloc that tries to allocate all fields in
     * @p start_positions simultaneously. Deparsed fields in particular need to be
     * placed simultaneously with their neighbors; otherwise, the `deparsed`
     * constraint cannot be satisfied.
     *
     * For example, consider a header with two 8-bit fields:
     *
     *     header h { bit<4> f1; bit<4> f2; }
     *
     * Fields f1 and f2 are deparsed, meaning that each must be placed in a
     * container alone or with other deparsed fields (in order) such that no
     * container bits are unallocated.  However, if we check this constraint
     * one field at a time, then neither field can be placed---one must be
     * placed first, but it only occupies half the container, violating the
     * constraint.
     *
     * Additionally, @p start_positions also includes the conditional constraints generated by
     * ActionPhvConstraints.
     *
     * Uses mutex_i and uses_i.
     *
     * @param alloc the allocation computed so far.
     * @param group the container group to which the slice list is to be allocated.
     * @param super_cluster ???
     * @param start_positions a map. Keys are the field slices to be allocated. Values are the
     *                        corresponding conditional constraint on the field slice.
     * @param score_ctx TODO
     */
    /// XXX(yumin): there is an assumption that only fieldslice of the slice list, shows up
    /// in the @p start_positions map (as there is no slice list passed as args).
    /// Better to remove this.
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::Allocation::ConditionalConstraint& start_positions,
        const ScoreContext& score_ctx) const;

    /// Convenience method that transforms @p start_positions map into a map
    /// of ConditionalConstraint, which is passed to `tryAllocSliceList` above.
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::SuperCluster::SliceList& slice_list,
        const ordered_map<PHV::FieldSlice, int>& start_positions,
        const ScoreContext& score_ctx) const;

    bool generateNewAllocSlices(
        const PHV::AllocSlice& origSlice,
        const ordered_set<PHV::AllocSlice>& alloced_slices,
        PHV::DarkInitMap& slices,
        ordered_set<PHV::AllocSlice>& new_candidate_slices,
        PHV::Transaction& alloc_attempt,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const;

    bool hasCrossingLiveranges(std::vector<PHV::AllocSlice> candidate_slices,
                               ordered_set<PHV::AllocSlice> alloc_slices) const;

    /// Generate pseudo AllocSlices for field slices that have not been allocated, but their
    /// allocation can be speculated upfront: when there is only one valid starting position.
    /// @returns a transaction that contains the pseudo AllocSlices.
    /// we can infer that field slices will be allocated to a container with corresponding
    /// starting positions. This will allow can_pack function to
    /// check constraints from action reading side, even if destination has not been allocated yet.
    /// This is enabled only when utils_i.settings_.trivial_alloc is true, otherwise, it simply
    /// returns @p alloc.
    PHV::Transaction make_speculated_alloc(const PHV::Transaction& alloc,
                                           const PHV::SuperCluster& sc,
                                           const std::vector<PHV::AllocSlice>& candidates,
                                           const PHV::Container& c) const;
};

enum class AllocResultCode {
    UNKNOWN,            // default value
    SUCCESS,            // All fields allocated
    FAIL,               // Some fields unallocated
    FAIL_UNSAT_SLICING   // Some fields CANNOT be allocated due to slicing
};

struct AllocResult {
    AllocResultCode status;
    PHV::Transaction transaction;
    std::list<const PHV::SuperCluster *> remaining_clusters;
    // To avoid copy on those large objects, constructor only takes rvalue,
    // so use std::move() if needed.
    AllocResult(AllocResultCode r, PHV::Transaction&& t,  // NOLINT
                std::list<const PHV::SuperCluster *>&& c)
        : status(r), transaction(t), remaining_clusters(c) {}
};

/** The abstract class of Phv allocation strategy.
  * The AllocationStrategy controls the core of PHV allocation: matching
  * SuperClusters to ContainerGroup by tryAllocation function.
  * Strategies can:
  * 1. make a complete or a partial allocation.
  * 2. be chained with other strategies.
  *
  * The result of core function tryAllocation:
  * 1. status: the result of this strategy.
  * 2. transaction: allocations had been made.
  * 3. remaining_clusters: the remaining cluster;
  *
 */
class AllocationStrategy {
 protected:
    const cstring name;
    const PHV::AllocUtils& utils_i;
    const CoreAllocation& core_alloc_i;

 public:
    AllocationStrategy(cstring name, const PHV::AllocUtils& utils, const CoreAllocation& core)
        : name(name), utils_i(utils), core_alloc_i(core) {}

    /** Run this strategy
     * Returns: a AllocResult that
     * 1. status: the result of this strategy.
     * 2. transaction: allocations had been made.
     * 3. remaining_clusters: the remaining cluster;
     * Strategies should not changed @p container_groups, except for sorting it.
     */
    virtual AllocResult
    tryAllocation(const PHV::Allocation& alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  const std::list<PHV::ContainerGroup*>& container_groups) = 0;
};

struct BruteForceStrategyConfig {
    cstring name;
    // heuristics of alloc score:
    AllocScore::IsBetterFunc is_better;
    // if max_failure_retry > 1, will retry (n-1) times by allocating
    // previsouly failed fields at the beginning of the allocation.
    int max_failure_retry;
    // try to split a supercluster for max_slicing_try times then allocate
    // for best score.
    int max_slicing;
    // the number of alignments of slicelists generated.
    // XXX(yumin): currently stopped at the first alloc-able alignment.
    int max_sl_alignment;
    // unsupported devices for this config.
    boost::optional<std::unordered_set<Device::Device_t>> unsupported_devices;
    // enable validation on pre-sliced super clusters to avoid creating unallocatable
    // clusters at preslicing.
    bool pre_slicing_validation;
    // enable AlwaysRun Action use for dark spills and zero-initialization during dark overlays
    bool enable_ara_in_overlays;
};

class BruteForceAllocationStrategy : public AllocationStrategy {
 private:
    const PHV::Allocation& empty_alloc_i;
    const BruteForceStrategyConfig& config_i;
    boost::optional<const PHV::SuperCluster::SliceList*> unallocatable_list_i;
    int pipe_id_i;  /// used for logging purposes
    PhvInfo& phv_i;  // mutable because of deparsed zero allocation.

 public:
    BruteForceAllocationStrategy(
        const cstring name, const PHV::AllocUtils& utils, const CoreAllocation& core,
        const PHV::Allocation& empty_alloc,
        const BruteForceStrategyConfig& config, int pipeId, PhvInfo& phv);

    AllocResult
    tryAllocation(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  const std::list<PHV::ContainerGroup *>& container_groups) override;

    boost::optional<const PHV::SuperCluster::SliceList*> get_unallocatable_list() const {
        return unallocatable_list_i;
    }

    int getPipeId() const {return pipe_id_i;}

 protected:
    AllocResult tryAllocationFailuresFirst(
        const PHV::Allocation& alloc, const std::list<PHV::SuperCluster*>& cluster_groups_input,
        const std::list<PHV::ContainerGroup*>& container_groups,
        const ordered_set<const PHV::Field*>& failures);

    std::list<PHV::SuperCluster*> crush_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups);

    /// slice clusters into clusters with container-sized chunks.
    std::list<PHV::SuperCluster*> preslice_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups,
            const std::list<PHV::ContainerGroup *>& container_groups,
            std::list<const PHV::SuperCluster*>& unsliceable);

    /// Sort list of superclusters into the order in which they should be allocated.
    void sortClusters(std::list<PHV::SuperCluster*>& cluster_groups);

    bool tryAllocSlicing(
        const std::list<PHV::SuperCluster*>& slicing,
        const std::list<PHV::ContainerGroup *>& container_groups,
        PHV::Transaction& slicing_alloc,
        const ScoreContext& score_ctx);

    bool tryAllocStride(const std::list<PHV::SuperCluster*>& stride,
                        const std::list<PHV::ContainerGroup *>& container_groups,
                        PHV::Transaction& stride_alloc,
                        const ScoreContext& score_ctx);

    bool tryAllocStrideWithLeaderAllocated(
        const std::list<PHV::SuperCluster*>& stride,
        PHV::Transaction& leader_alloc,
        const ScoreContext& score_ctx);

    bool tryAllocSlicingStrided(unsigned num_strides,
                                const std::list<PHV::SuperCluster*>& slicing,
                                const std::list<PHV::ContainerGroup *>& container_groups,
                                PHV::Transaction& slicing_alloc,
                                const ScoreContext& score_ctx);

    boost::optional<PHV::Transaction>
    tryVariousSlicing(PHV::Transaction& rst,
                      PHV::SuperCluster* cluster_group,
                      const std::list<PHV::ContainerGroup *>& container_groups,
                      const ScoreContext& score_ctx,
                      std::stringstream& alloc_history);

    std::list<PHV::SuperCluster*>
    allocLoop(PHV::Transaction& rst,
              std::list<PHV::SuperCluster*>& cluster_groups,
              const std::list<PHV::ContainerGroup *>& container_groups,
              const ScoreContext& score_ctx);

    /// Allocate deparser zero fields to zero-initialized containers. B0 for ingress and B16 for
    /// egress.
    std::list<PHV::SuperCluster*> allocDeparserZeroSuperclusters(
            PHV::Transaction& rst,
            std::list<PHV::SuperCluster*>& cluster_groups);

    /** Return a vector of slicing schemas for @p sc, that
     *
     *  1. Slicing by the available spots on containers.
     *  2. Slicing by 7, 6, 5...1-bit chunks.
     *
     */
    ordered_set<bitvec>
    calc_slicing_schemas(const PHV::SuperCluster* sc,
                         const std::set<PHV::Allocation::AvailableSpot>& spots);

    /** Slice cluster_groups to small chunks and try allocate them.
     *
     *  After execution, @p rst will be updated with allocated clusters.
     *  Unallocated superclusters will be stored in @p cluster_groups, without being sliced.
     *  @returns allocated clusters.
     *
     *  Try to slice and allocate each cluster by trying the slicing schemas returned from
     *  calc_slicing_schema, in order.
     */
    std::list<PHV::SuperCluster*>
    pounderRoundAllocLoop(
            PHV::Transaction& rst,
            std::list<PHV::SuperCluster*>& cluster_groups,
            const std::list<PHV::ContainerGroup *>& container_groups);

    // return unallocatable slice list by allocating superclusters to an empty PHV.
    boost::optional<const PHV::SuperCluster::SliceList*> diagnose_slicing(
        const std::list<PHV::SuperCluster*>& slicing,
        const std::list<PHV::ContainerGroup*>& container_groups) const;

    // return unallocatable slice list.
    // It will try to slice @p sliced further and allocate to an empty PHV.
    // The reason why this function will try to split further is because that
    // there can be valid presliced cluster that is too large for a single container group.
    boost::optional<const PHV::SuperCluster::SliceList*> preslice_validation(
        const std::list<PHV::SuperCluster*>& sliced,
        const std::list<PHV::ContainerGroup*>& container_groups) const;

    friend class BruteForceOptimizationStrategy;
};

/// TrivialAllocStrategy will try to allocate every minimally packed clusters to
/// a emtpy PHV and fields in a container to a new container while ignoring container
/// ingress constraint.
class TrivialAllocStrategy {
    /// PhvStatus bookkeeper for containers.
    class PhvStatus {
        std::unordered_map<PHV::Size, int> next_container_idx;
     public:
        PhvStatus();
        PHV::Container next_container(PHV::Size) const;
        void inc_next_container(PHV::Size);
    };
    const PHV::AllocUtils& utils_i;
    const CoreAllocation& core_i;
    PhvInfo& phv_i;
    const int pipe_id_i;  /// used for logging purposes

    struct PartialAllocResult {
        bool ok = false;
        std::vector<PHV::AllocSlice> alloc_slices;
        PhvStatus phv_status;
        const PHV::SuperCluster::SliceList* cannot_allocate = nullptr;
        ordered_set<const PHV::SuperCluster*> unallocated;
        PartialAllocResult(bool ok, std::vector<PHV::AllocSlice> alloc_slices,
                           PhvStatus phv_status,
                           const PHV::SuperCluster::SliceList* cannot_allocate,
                           ordered_set<const PHV::SuperCluster*> unallocated)
            : ok(ok),
              alloc_slices(alloc_slices),
              phv_status(phv_status),
              cannot_allocate(cannot_allocate),
              unallocated(unallocated) {}
    };

    // return a list of container groups that same-size groups are merged into one group.
    std::list<PHV::ContainerGroup*> make_container_groups_merged_by_size() const;

    // gen_alloc_slices_from_tx extract allocation results from tx and generate allocation of
    // fieldslices to *new* phv containers. New phv containers are requested from @p phv_status
    // and phv_status will be updated.
    std::vector<PHV::AllocSlice> gen_alloc_slices_from_tx(const PHV::Transaction& tx,
                                                          PhvStatus& phv_status) const;

    // gen_alloc_slices_from_tx extract allocation results from tx and generate allocation of
    // fieldslices to *new* phv containers. New phv containers are requested from @p phv_status
    // and phv_status will be updated.
    void bind_alloc_slices(const std::vector<PHV::AllocSlice>& slices);

    PartialAllocResult alloc_clusters(PHV::Transaction& rst,
                                      PhvStatus phv_status,
                                      const std::list<PHV::ContainerGroup*>& container_groups,
                                      const std::list<PHV::SuperCluster*>& clusters) const;

 public:
    TrivialAllocStrategy(const PHV::AllocUtils& utils, const CoreAllocation& core, PhvInfo& phv,
                         int pipe_id);

    // @returns spliced SuperClusters that cannot be allocated.
    ordered_set<const PHV::SuperCluster*> allocate(const PHV::Allocation& alloc,
                                                   const std::list<PHV::SuperCluster*>& clusters,
                                                   bool dry_run = false);
};

/** Given constraints gathered from compilation thus far, allocate fields to
 * PHV containers.
 *
 * @pre An up-to-date PhvInfo object with fields marked with their constraints;
 * field mutual exclusion information; and clusters.
 *
 * @post PhvInfo::Fields in \a phv are annotated with `alloc_slice` information
 * that assigns field slices to containers, or error explains why PHV
 * allocation was unsuccessful.
 */
class AllocatePHV : public Visitor {
 private:
    const PHV::AllocUtils& utils_i;
    const MauBacktracker& mau_i;
    CoreAllocation core_alloc_i;
    PhvInfo& phv_i;
    const IR::BFN::Pipe *root;
    /** The entry point.  This "pass" doesn't actually traverse the IR, but it
     * marks the place in the back end where PHV allocation does its work.
     */
    const IR::Node *apply_visitor(const IR::Node* root, const char *name = 0) override;

    /// Throw a pretty-printed error when allocation fails due to resource constraints.
    void formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<const PHV::SuperCluster *>& unallocated);

    /// Throw a pretty-printed error when allocation fails due to
    /// unsatisfiable constraints.
    void formatAndThrowUnsat(const std::list<const PHV::SuperCluster *>& unallocated) const;

    /** Diagnose why unallocated clusters remained unallocated, and throw the appropriate error
      * message.
      */
    bool diagnoseFailures(const std::list<const PHV::SuperCluster *>& unallocated) const;

    /** Diagnose why unallocated supercluster sc remained unallocated, and throw appropriate error
      * message.
      */
    bool diagnoseSuperCluster(const PHV::SuperCluster* sc) const;

    /// use brute force strategy to allocate.
    AllocResult brute_force_alloc(
        PHV::ConcreteAllocation& alloc, PHV::ConcreteAllocation& empty_alloc,
        std::vector<const PHV::SuperCluster::SliceList*>& unallocatable_lists,
        std::list<PHV::SuperCluster*>& cluster_groups,
        const std::list<PHV::ContainerGroup*>& container_groups, const int pipe_id) const;

 public:
    AllocatePHV(const PHV::AllocUtils& utils, const MauBacktracker& mau, PhvInfo& phv)
        : utils_i(utils),
          mau_i(mau),
          core_alloc_i(utils, mau.disableMetadataInitialization()),
          phv_i(phv) {}
};

/// IncrementalPHVAllocation incrementally allocates fields.
/// Currently it only supports allocating temp vars created by table alloc.
/// XXX(yumin): we need to check whether mutex and live range info for those fields
/// are correct or not.
class IncrementalPHVAllocation : public Visitor {
    const PHV::AllocUtils& utils_i;
    CoreAllocation core_alloc_i;
    PhvInfo& phv_i;
    PHV::AllocSetting &settings_i;

    // fields to be allocated.
    const ordered_set<PHV::Field*>& temp_vars_i;

    // This pass does not traverse IR.
    const IR::Node *apply_visitor(const IR::Node* root, const char* name = 0) override;

 public:
    explicit IncrementalPHVAllocation(const ordered_set<PHV::Field*>& temp_vars,
                                      const PHV::AllocUtils& utils, PhvInfo& phv,
                                      PHV::AllocSetting &settings)
        : utils_i(utils), core_alloc_i(utils, true), phv_i(phv), settings_i(settings),
          temp_vars_i(temp_vars) {}
};

#endif  /* BF_P4C_PHV_ALLOCATE_PHV_H_ */
