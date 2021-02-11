#ifndef BF_P4C_PHV_ALLOCATE_PHV_H_
#define BF_P4C_PHV_ALLOCATE_PHV_H_

#include <boost/optional.hpp>

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/dark_live_range.h"
#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/phv/collect_strided_headers.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/utils/tables_to_ids.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"

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

/// AllocContext will will create alloc scores.
class AllocContext {
 private:
    cstring name_i;

    /// Opportunities for packing if allocated in some order.
    FieldPackingOpportunity* packing_opportunities_i = nullptr;

    /// comparison function
    AllocScore::IsBetterFunc is_better_i;

 public:
    AllocContext(cstring name, AllocScore::IsBetterFunc is_better)
        : name_i(name), is_better_i(is_better) { }

    AllocScore make_score(
        const PHV::Transaction& alloc,
        const PhvInfo& phv,
        const ClotInfo& clot,
        const PhvUse& uses,
        const MapFieldToParserStates& field_to_parser_states,
        const CalcParserCriticalPath& parser_critical_path,
        const int bitmasks = 0) const;

    bool is_better(const AllocScore& left, const AllocScore& right) const {
        return is_better_i(left, right);
    }

    AllocContext with(FieldPackingOpportunity* packing) {
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
    // Input.
    const SymBitMatrix& mutex_i;
    const PhvUse& uses_i;
    const FieldDefUse& defuse_i;
    const ClotInfo& clot_i;

    // Modified in this pass.
    PhvInfo& phv_i;
    ActionPhvConstraints& actions_i;
    PHV::Pragmas& pragmas_i;  // Some might not be satisfied.

    // Metadata initialization possibilities.
    LiveRangeShrinking& meta_init_i;
    // Dark overlay possibilities.
    DarkOverlay& dark_init_i;

    // Table allocation information from the previous round.
    bool disableMetadataInit;

    const MapFieldToParserStates& field_to_parser_states_i;
    const CalcParserCriticalPath& parser_critical_path_i;
    const CollectParserInfo& parser_info_i;
    const CollectStridedHeaders& strided_headers_i;

    // Alignment failure fields. Right now, this will only contain bridged metadata fields if PHV
    // allocation fails due to alignment reasons. Used to backtrack to bridged metadata packing.
    ordered_set<const PHV::Field*> fieldsWithAlignmentConflicts;

    boost::optional<PHV::Transaction> alloc_super_cluster_with_alignment(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster,
        const AllocAlignment& alignment,
        const AllocContext& score_ctx) const;

    /// returns @p max_n possible alloc alignments for a super cluster vs a container group
    std::vector<AllocAlignment> build_alignments(
        int max_n,
        const PHV::ContainerGroup& container_group,
        PHV::SuperCluster& super_cluster) const;

    /// Builds a vector of alignments for @p slice_list,
    /// because there are multiple starting point of a slice list
    std::vector<AllocAlignment> build_slicelist_alignment(
      const PHV::ContainerGroup& container_group,
      const PHV::SuperCluster& super_cluster,
      const PHV::SuperCluster::SliceList* slice_list) const;

 public:
    CoreAllocation(const SymBitMatrix& mutex,
                   const PhvUse& uses,
                   const FieldDefUse& defuse,
                   const ClotInfo& clot,
                   PHV::Pragmas& pragmas,
                   PhvInfo& phv,
                   ActionPhvConstraints& actions,
                   LiveRangeShrinking& meta,
                   DarkOverlay& dark,
                   const MapFieldToParserStates& field_to_parser_states,
                   const CalcParserCriticalPath& parser_critical_path,
                   const MauBacktracker& alloc,
                   const CollectParserInfo& parser_info,
                   const CollectStridedHeaders& strided_headers)
        : mutex_i(mutex), /* clustering_i(clustering), */ uses_i(uses), defuse_i(defuse),
          clot_i(clot), phv_i(phv), actions_i(actions), pragmas_i(pragmas), meta_init_i(meta),
          dark_init_i(dark), disableMetadataInit(alloc.disableMetadataInitialization()),
          field_to_parser_states_i(field_to_parser_states),
          parser_critical_path_i(parser_critical_path), parser_info_i(parser_info),
          strided_headers_i(strided_headers) { }

    /// @returns true if @f can overlay all fields in @slices.
    static bool can_overlay(
            const SymBitMatrix& mutually_exclusive_field_ids,
            const PHV::Field* f,
            const ordered_set<PHV::AllocSlice>& slices);

    /// @returns true if slice list<-->container constraints are satisfied.
    bool satisfies_constraints(std::vector<PHV::AllocSlice> slices,
                               const PHV::Allocation& alloc) const;

    /// @returns true if field<-->group constraints are satisfied.
    bool satisfies_constraints(const PHV::ContainerGroup& group, const PHV::Field* f) const;

    /// @returns true if field slice<-->group constraints are satisfied.
    bool satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const;

    /// @returns true if @slice is a valid allocation move given the allocation
    /// status in @alloc. @initFields contains a list of fields in this container that will be
    /// initialized via metadata initialization.
    bool satisfies_constraints(
            const PHV::Allocation& alloc,
            PHV::AllocSlice slice,
            ordered_set<PHV::AllocSlice>& initFields) const;

    /// @returns true if @container_group and @cluster_group satisfy constraints.
    /// XXX(cole): figure out what, if any, constraints should go here.
    static bool satisfies_constraints(const PHV::ContainerGroup& container_group,
                                      const PHV::SuperCluster& cluster_group);

    /** Try to allocate all fields in @cluster to containers in @group, using the
     * following techniques (when permissible by constraints), assuming @alloc is
     * the allocation so far, possibly including allocations to containers in
     * @group:
     *
     *   - splitting fields across different containers
     *   - packing different fields (or field slices) into the same container
     *   - overlaying fields
     *
     * @returns an allocation of @cluster to @group or boost::none if no allocation
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
    boost::optional<PHV::Transaction> tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        PHV::SuperCluster& cluster,
        int max_alignment_tries,
        const AllocContext& score_ctx) const;

    boost::optional<const PHV::SuperCluster::SliceList*> find_first_unallocated_slicelist(
        const PHV::Allocation& alloc, const std::list<PHV::ContainerGroup*>& container_groups,
        PHV::SuperCluster& cluster, const AllocContext& score_ctx) const;

    /** Helper function that tries to allocate all fields in the deparser zero supercluster
      * @cluster to containers B0 (for ingress) and B16 (for egress). The DeparserZero analysis
      * earlier in PHV allocation already ensures that these fields can be safely allocated to the
      * zero-ed containers.
      */
    boost::optional<PHV::Transaction> tryDeparserZeroAlloc(
        const PHV::Allocation& alloc,
        PHV::SuperCluster& cluster) const;

    bool checkDarkOverlay(std::vector<PHV::AllocSlice> candidate_slices,
                          PHV::Transaction alloc) const;


    /** Helper function for tryAlloc that tries to allocate all fields in
     * @start_positions simultaneously. Deparsed fields in particular need to be
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
     * Additionally, @start_positions also includes the conditional constraints generated by
     * ActionPhvConstraints.
     *
     * Uses mutex_i and uses_i.
     *
     * @param alloc the allocation computed so far.
     * @param group the container group to which the slice list is to be allocated.
     * @param super_cluster ???
     * @param start_positions a map. Keys are the field slices to be allocated. Values are the
     *                        corresponding conditional constraint on the field slice.
     */
    /// XXX(yumin): there is an assumption that only fieldslice of the slice list, shows up
    /// in the @start_positions map(as there is no slice list passed as args).
    /// Better to remove this.
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::Allocation::ConditionalConstraint& start_positions,
        const AllocContext& score_ctx) const;

    /// Convenience method that transforms start_positions map into a map of ConditionalConstraint,
    /// which is passed to `tryAllocSliceList` above.
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::SuperCluster::SliceList& slice_list,
        const ordered_map<PHV::FieldSlice, int>& start_positions,
        const AllocContext& score_ctx) const;

    bool generateNewAllocSlices(
        const PHV::AllocSlice& origSlice,
        const ordered_set<PHV::AllocSlice>& alloced_slices,
        PHV::DarkInitMap& slices,
        std::vector<PHV::AllocSlice>& new_candidate_slices,
        PHV::Transaction& alloc_attempt,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const;

    bool hasCrossingLiveranges(std::vector<PHV::AllocSlice> candidate_slices,
                               ordered_set<PHV::AllocSlice> alloc_slices) const;


    PhvInfo& phv() const                                  { return phv_i; }
    const PhvUse& uses() const                            { return uses_i; }
    const SymBitMatrix& mutex() const                     { return mutex_i; }
    const FieldDefUse& defuse() const                     { return defuse_i; }
    const ActionPhvConstraints& actionConstraints() const { return actions_i; }
    PHV::Pragmas& pragmas() const                         { return pragmas_i; }
    const MapFieldToParserStates& field_to_parser_states() const {
        return field_to_parser_states_i; }
    const CalcParserCriticalPath& parser_critical_path() const { return parser_critical_path_i; }
    const ClotInfo& clot() const { return clot_i; }
    // const CollectParserInfo& parser_info_i;
    const CollectStridedHeaders& strided_headers() const { return strided_headers_i; }
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
    std::list<PHV::SuperCluster *> remaining_clusters;
    // To avoid copy on those large objects, constructor only takes rvalue,
    // so use std::move() if needed.
    AllocResult(AllocResultCode r, PHV::Transaction&& t,  // NOLINT
                std::list<PHV::SuperCluster *>&& c)
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
    const CoreAllocation& core_alloc_i;

 public:
    AllocationStrategy(cstring name, const CoreAllocation& alloc)
        : name(name), core_alloc_i(alloc) {}

    /** Run this strategy
     * Returns: a AllocResult that
     * 1. status: the result of this strategy.
     * 2. transaction: allocations had been made.
     * 3. remaining_clusters: the remaining cluster;
     * Strategies should not changed @p container_groups, except for sorting it.
     */
    virtual AllocResult
    tryAllocation(const PHV::Allocation& alloc,
                  const std::list<PHV::SuperCluster *>& cluster_groups_input,
                  const std::list<PHV::ContainerGroup *>& container_groups) = 0;
};

struct BruteForceStrategyConfig {
    cstring name;
    // heristic set of alloc score:
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
    // whether this score is tofino only.
    bool tofino_only;
    // enable validation on pre-sliced super clusters to avoid creating unallocatable
    // clusters at preslicing.
    bool pre_slicing_validation;
    // enable AlwaysRun Action use for dark spills and zero-initialization during dark overlays
    bool enable_ara_in_overlays;
};

class BruteForceAllocationStrategy : public AllocationStrategy {
 private:
    const PHV::Allocation& empty_alloc_i;
    const CalcParserCriticalPath& parser_critical_path_i;
    const CalcCriticalPathClusters& critical_path_clusters_i;
    const ClotInfo& clot_i;
    const CollectStridedHeaders& strided_headers_i;
    const PhvUse& uses_i;
    const Clustering& clustering_i;
    const BruteForceStrategyConfig& config_i;
    PHV::Slicing::PackConflictChecker has_pack_conflict_i;
    PHV::Slicing::IsReferencedChecker is_referenced_i;
    boost::optional<const PHV::SuperCluster::SliceList*> unallocatable_list_i;
    int pipe_id_i;  /// used for logging purposes

 public:
    BruteForceAllocationStrategy(const PHV::Allocation& empty_alloc, const cstring name,
                                 const CoreAllocation& alloc, const CalcParserCriticalPath& ccp,
                                 const CalcCriticalPathClusters& cpc, const ClotInfo& clot,
                                 const CollectStridedHeaders& hs, const PhvUse& uses,
                                 const Clustering& clustering,
                                 const BruteForceStrategyConfig& config, int pipeId);

    AllocResult
    tryAllocation(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  const std::list<PHV::ContainerGroup *>& container_groups) override;

    boost::optional<const PHV::SuperCluster::SliceList*> get_unallocatable_list() const {
        return unallocatable_list_i;
    }

 protected:
    AllocResult
    tryAllocationFailuresFirst(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  const std::list<PHV::ContainerGroup *>& container_groups,
                  const ordered_set<const PHV::Field*>& failures);

    /// remove singleton unreferenced fields.
    std::list<PHV::SuperCluster*> remove_unreferenced_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups_input) const;

    /// remove superclusters with deparser zero fields.
    std::list<PHV::SuperCluster*> remove_deparser_zero_superclusters(
            const std::list<PHV::SuperCluster*>& cluster_groups_input,
            std::list<PHV::SuperCluster*>& deparser_zero_superclusters) const;

    std::list<PHV::SuperCluster*>
    create_strided_clusters(const std::list<PHV::SuperCluster*>& cluster_groups) const;

    std::list<PHV::SuperCluster*> crush_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups);

    /// slice clusters into clusters with container-sized chunks.
    std::list<PHV::SuperCluster*> preslice_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups,
            const std::list<PHV::ContainerGroup *>& container_groups,
            std::list<PHV::SuperCluster*>& unsliceable);

    /// remove singleton metadata slice list. This was introduced because some metadata fields are
    /// placed in a supercluster but they should not be.
    std::list<PHV::SuperCluster*> remove_singleton_slicelist_metadata(
            const std::list<PHV::SuperCluster*>& cluster_groups) const;

    /// Sort list of superclusters into the order in which they should be allocated.
    void sortClusters(std::list<PHV::SuperCluster*>& cluster_groups);

    bool tryAllocSlicing(
        const std::list<PHV::SuperCluster*>& slicing,
        const std::list<PHV::ContainerGroup *>& container_groups,
        PHV::Transaction& slicing_alloc,
        const AllocContext& score_ctx);

    bool tryAllocStride(const std::list<PHV::SuperCluster*>& stride,
                        const std::list<PHV::ContainerGroup *>& container_groups,
                        PHV::Transaction& stride_alloc,
                        const AllocContext& score_ctx);

    bool tryAllocStrideWithLeaderAllocated(
        const std::list<PHV::SuperCluster*>& stride,
        PHV::Transaction& leader_alloc,
        const AllocContext& score_ctx);

    bool tryAllocSlicingStrided(unsigned num_strides,
                                const std::list<PHV::SuperCluster*>& slicing,
                                const std::list<PHV::ContainerGroup *>& container_groups,
                                PHV::Transaction& slicing_alloc,
                                const AllocContext& score_ctx);

    std::list<PHV::SuperCluster*>
    allocLoop(PHV::Transaction& rst,
              std::list<PHV::SuperCluster*>& cluster_groups,
              const std::list<PHV::ContainerGroup *>& container_groups,
              const AllocContext& score_ctx);

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
};

/** Given constraints gathered from compilation thus far, allocate fields to
 * PHV containers.
 *
 * @pre An up-to-date PhvInfo object with fields marked with their constraints;
 * field mutual exclusion information; and clusters.
 *
 * @post PhvInfo::Fields in @phv are annotated with `alloc_slice` information
 * that assigns field slices to containers, or `::error` explains why PHV
 * allocation was unsuccessful.
 */
class AllocatePHV : public Visitor {
 private:
    CoreAllocation core_alloc_i;
    PhvInfo& phv_i;
    const PhvUse& uses_i;
    const ClotInfo& clot_i;
    const Clustering& clustering_i;
    const MauBacktracker& alloc_i;
    const SymBitMatrix& mutex_i;
    PHV::Pragmas& pragmas_i;
    const IR::BFN::Pipe *root;

    // Used to balance container usage for parser states on the critical path
    const CalcParserCriticalPath& parser_critical_path_i;

    // Used to create strategies, if needed
    const CalcCriticalPathClusters& critical_path_clusters_i;
    const MapTablesToIDs table_ids_i;
    const CollectStridedHeaders& strided_headers_i;

    /** The entry point.  This "pass" doesn't actually traverse the IR, but it
     * marks the place in the back end where PHV allocation does its work.
     */
    const IR::Node *apply_visitor(const IR::Node* root, const char *name = 0) override;

    /// @returns a SuperClusters from clustering_i.
    std::list<PHV::SuperCluster*> make_cluster_groups() const {
        return clustering_i.cluster_groups(); }

    /// @returns true if the only unallocated fields are all TempVars (TPHV fields) introduced by
    /// privatization (field->privatized() == true).
    bool onlyPrivatizedFieldsUnallocated(std::list<PHV::SuperCluster*>& unallocated) const;

    /// Throw a pretty-printed ::error when allocation fails due to resource constraints.
    void formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<PHV::SuperCluster *>& unallocated);

    /// Throw a pretty-printed ::error when allocation fails due to
    /// unsatisfiable constraints.
    void formatAndThrowUnsat(const std::list<PHV::SuperCluster *>& unallocated) const;

    /// Throws backtracking exception, if we need to backtrack because of conflicting alignment
    /// constraints induced by bridged metadata packing.
    ordered_set<cstring> throwBacktrackException(
            const size_t numBridgedConflicts,
            const std::list<PHV::SuperCluster*>& unallocated) const;

    /** Diagnose why unallocated clusters remained unallocated, and throw the appropriate error
      * message.
      */
    bool diagnoseFailures(const std::list<PHV::SuperCluster *>& unallocated) const;

    /** Diagnose why unallocated supercluster sc remained unallocated, and throw appropriate error
      * message.
      */
    bool diagnoseSuperCluster(const PHV::SuperCluster* sc) const;

 public:
    // Select if dark overlays (spilling and zero-initialization) will
    // be using AlwaysRunActions (ARA)

    AllocatePHV(const Clustering& clustering,
                const PhvUse& uses,
                const FieldDefUse& defuse,
                const ClotInfo& clot,
                PHV::Pragmas& pragmas,
                PhvInfo& phv,
                ActionPhvConstraints& actions,
                const MapFieldToParserStates& field_to_parser_states,
                const CalcParserCriticalPath& parser_critical_path,
                const CalcCriticalPathClusters& critical_cluster,
                const MauBacktracker& alloc,
                LiveRangeShrinking& meta_init,
                DarkOverlay& dark,
                const MapTablesToIDs& t,
                const CollectStridedHeaders& hs,
                const CollectParserInfo& parser_info)
        : core_alloc_i(phv.field_mutex(), uses, defuse, clot, pragmas, phv, actions,
           meta_init, dark, field_to_parser_states, parser_critical_path, alloc, parser_info, hs),
          phv_i(phv), uses_i(uses), clot_i(clot),
          clustering_i(clustering), alloc_i(alloc),
          mutex_i(phv.field_mutex()), pragmas_i(pragmas),
          parser_critical_path_i(parser_critical_path),
          critical_path_clusters_i(critical_cluster), table_ids_i(t),
          strided_headers_i(hs) { }

    /** @returns the container groups available on this Device.  All fields in
     * a cluster must be allocated to the same container group.
     */
    static std::list<PHV::ContainerGroup *> makeDeviceContainerGroups();

    /// Clear alloc_slices allocated in @phv, if any.
    static void clearSlices(PhvInfo& phv);

    /** Translate each AllocSlice in @alloc into a PHV::Field::alloc_slice and
     * attach it to the PHV::Field it slices.
     */
    static void bindSlices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv);
};

/// IncrementalPHVAllocation incrementally allocates fields.
/// Currently it only supports allocating temp vars created by table alloc.
/// XXX(yumin): we need to check whether mutex and live range info for those fields
/// are correct or not.
class IncrementalPHVAllocation : public Visitor {
    CoreAllocation core_alloc_i;
    PhvInfo& phv_i;
    const PhvUse& uses_i;
    const ClotInfo& clot_i;
    const Clustering& clustering_i;
    const MauBacktracker& alloc_i;
    const SymBitMatrix& mutex_i;
    PHV::Pragmas& pragmas_i;
    const IR::BFN::Pipe *root;
    const CalcParserCriticalPath& parser_critical_path_i;
    const CalcCriticalPathClusters& critical_path_clusters_i;
    const MapTablesToIDs table_ids_i;
    const CollectStridedHeaders& strided_headers_i;

    // fields to be allocated.
    const ordered_set<PHV::Field*>& temp_vars_i;

    // This pass does not traverse IR.
    const IR::Node *apply_visitor(const IR::Node* root, const char* name = 0) override;

 public:
    explicit IncrementalPHVAllocation(
        const ordered_set<PHV::Field*>& temp_vars, const Clustering& clustering, const PhvUse& uses,
        const FieldDefUse& defuse, const ClotInfo& clot, PHV::Pragmas& pragmas, PhvInfo& phv,
        ActionPhvConstraints& actions, const MapFieldToParserStates& field_to_parser_states,
        const CalcParserCriticalPath& parser_critical_path,
        const CalcCriticalPathClusters& critical_cluster, const MauBacktracker& alloc,
        LiveRangeShrinking& meta_init, DarkOverlay& dark, const MapTablesToIDs& t,
        const CollectStridedHeaders& hs, const CollectParserInfo& parser_info)
        : core_alloc_i(phv.field_mutex(), uses, defuse, clot, pragmas, phv, actions,
           meta_init, dark, field_to_parser_states, parser_critical_path, alloc, parser_info, hs),
          phv_i(phv), uses_i(uses), clot_i(clot),
          clustering_i(clustering), alloc_i(alloc),
          mutex_i(phv.field_mutex()), pragmas_i(pragmas),
          parser_critical_path_i(parser_critical_path),
          critical_path_clusters_i(critical_cluster), table_ids_i(t),
          strided_headers_i(hs),
          temp_vars_i(temp_vars) {}
};

#endif  /* BF_P4C_PHV_ALLOCATE_PHV_H_ */
