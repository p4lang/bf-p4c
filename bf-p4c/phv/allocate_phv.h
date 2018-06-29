#ifndef BF_P4C_PHV_ALLOCATE_PHV_H_
#define BF_P4C_PHV_ALLOCATE_PHV_H_

#include <boost/optional.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/utils.h"
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
    static constexpr int DARK_TO_PHV_DISTANCE = 2;
    struct ScoreByKind {
        int n_set_gress;
        int n_set_parser_group_gress;
        int n_set_deparser_group_gress;
        int n_overlay_bits;
        int n_packing_bits;  // how many wasted bits in partial container get used.
        int n_packing_priority;  // smaller, better.
        int n_inc_containers;
        int n_wasted_bits;  // if no_pack but taking a container larger than it.

        // The number of CLOT-eligible bits that have been allocated to PHV
        // (JBay only).
        int n_clot_bits;

        // The number of containers in a deparser group allocated to
        // non-deparsed fields of a different gress than the deparser group.
        int n_mismatched_deparser_gress;

        // The difference in the number of PHV containers available by size.
        // Lower is better, as it indicates that roughly the same number of 8b,
        // 16b, and 32b containers remain.
        int container_imbalance;
    };

    ordered_map<PHV::Kind, ScoreByKind> score;
    int n_tphv_on_phv_bits;
    int n_mocha_on_phv_bits;
    int n_dark_on_phv_bits;
    int n_dark_on_mocha_bits;
    /// Number of bitmasked-set operations introduced by this transaction.
    int n_num_bitmasked_set;

    AllocScore() : n_tphv_on_phv_bits(0), n_mocha_on_phv_bits(0), n_dark_on_phv_bits(0),
                   n_dark_on_mocha_bits(0), n_num_bitmasked_set(0) { }

    /** Construct a score from a Transaction.
     *
     * @p alloc: new allocation
     * @p group: the container group where allocations were made to.
     */
    AllocScore(
            const PHV::Transaction& alloc,
            const ClotInfo& clot,
            const PhvUse& uses,
            const int bitmasks = 0);

    bool operator>(const AllocScore& other) const;
    static AllocScore make_lowest();

    /* stateful variables for AllocScore. */
    /// Opportunities for packing if allocated in some order.
    static FieldPackingOpportunity* g_packing_opportunities;

 private:
    bitvec calcContainerAllocVec(const ordered_set<PHV::AllocSlice>& slices);

    ContainerAllocStatus
    calcContainerStatus(const PHV::Container& container,
                        const ordered_set<PHV::AllocSlice>& slices);
};

std::ostream& operator<<(std::ostream& s, const AllocScore& score);

/** A set of functions used in PHV allocation.
 */
class CoreAllocation {
    // Input.
    const SymBitMatrix& mutex_i;
    // const Clustering& clustering_i;
    const PhvUse& uses_i;
    const FieldDefUse& defuse_i;
    const ClotInfo& clot_i;

    // Modified in this pass.
    PhvInfo& phv_i;
    ActionPhvConstraints& actions_i;
    PHV::Pragmas& pragmas_i;  // Some might not be satisfied.

 public:
    CoreAllocation(const SymBitMatrix& mutex,
                   const Clustering&,
                   const PhvUse& uses,
                   const FieldDefUse& defuse,
                   const ClotInfo& clot,
                   PHV::Pragmas& pragmas,
                   PhvInfo& phv,
                   ActionPhvConstraints& actions)
        : mutex_i(mutex), /* clustering_i(clustering), */ uses_i(uses), defuse_i(defuse),
          clot_i(clot), phv_i(phv), actions_i(actions), pragmas_i(pragmas) { }

    /// @returns true if @f can overlay all fields in @slices.
    static bool can_overlay(
            SymBitMatrix mutually_exclusive_field_ids,
            const PHV::Field* f,
            const ordered_set<PHV::AllocSlice>& slices);

    /** Checks whether @group can satisfy the group/cluster constraints for
     * @cluster. If so, returns group-specific information for placing
     * @cluster. At present, this is the set of valid starting bit locations
     * for fields of @cluster in containers of @group.
     */
    boost::optional<bitvec> satisfies_constraints(
        const PHV::ContainerGroup& group, const PHV::AlignedCluster& cluster) const;

    /// @returns true if slice list<-->container constraints are satisfied.
    bool satisfies_constraints(std::vector<PHV::AllocSlice> slices) const;

    /// @returns true if field<-->group constraints are satisfied.
    bool satisfies_constraints(const PHV::ContainerGroup& group, const PHV::Field* f) const;

    /// @returns true if field slice<-->group constraints are satisfied.
    bool satisfies_constraints(
        const PHV::ContainerGroup& group,
        const PHV::FieldSlice& slice) const;

    /// @returns true if @slice is a valid allocation move given the allocation
    /// statis in @alloc.
    bool satisfies_constraints(const PHV::Allocation& alloc, PHV::AllocSlice slice) const;

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
        PHV::SuperCluster& cluster) const;

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
     */
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const PHV::Allocation::ConditionalConstraints& start_positions) const;

    /// Convenience method that transforms start_positions map into a map of ConditionalConstraints,
    /// which is passed to `tryAllocSliceList` above.
    boost::optional<PHV::Transaction> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster& super_cluster,
        const ordered_map<PHV::FieldSlice, int>& start_positions) const;

    const PhvUse& uses() const                            { return uses_i; }
    const SymBitMatrix& mutex() const                     { return mutex_i; }
    const FieldDefUse& defuse() const                     { return defuse_i; }
    const ActionPhvConstraints& actionConstraints() const { return actions_i; }
    PHV::Pragmas& pragmas() const                         { return pragmas_i; }
};

// TODO(yumin) extends this to include all possible cases.
enum class AllocResultCode {
    SUCCESS,        // All fields allocated
    FAIL,           // Some fields unallocated
    FAIL_UNSAT      // Some fields CANNOT be allocated due to unsatisfiable
                    // constraints
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
  * TODO(yumin): Introduce a way to control whether we want to use vertex coloring
  * result for overlaying.
 */
class AllocationStrategy {
 protected:
    const CoreAllocation& core_alloc_i;
    std::ostream& report_i;

 public:
    AllocationStrategy(const CoreAllocation& alloc, std::ostream& out)
        : core_alloc_i(alloc), report_i(out) {}

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
                  std::list<PHV::ContainerGroup *>& container_groups) = 0;

    /// Write summary of this strategy to report_i.
    void writeTransactionSummary(
            const PHV::Transaction& transaction,
            const std::list<PHV::SuperCluster *>& allocated);
};

class BruteForceAllocationStrategy : public AllocationStrategy {
 private:
    const CalcCriticalPathClusters& critical_path_clusters_i;
    const FieldInterference& field_interference_i;
    const ClotInfo& clot_i;
    // XXX(yumin): not used right now
    // Update this everytime after slicing.
    // FieldInterference::SliceColorMap slice_to_color_i;

 public:
    BruteForceAllocationStrategy(const CoreAllocation& alloc,
                                 std::ostream& out,
                                 const CalcCriticalPathClusters& cpc,
                                 const FieldInterference& f,
                                 const ClotInfo& clot)
        : AllocationStrategy(alloc, out)
        , critical_path_clusters_i(cpc), field_interference_i(f), clot_i(clot) { }

    AllocResult
    tryAllocation(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  std::list<PHV::ContainerGroup *>& container_groups) override;

 protected:
    std::list<PHV::SuperCluster*>
    remove_unreferenced_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups_input);

    std::list<PHV::SuperCluster*>
    crush_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups);

    std::list<PHV::SuperCluster*>
    slice_clusters(
            const std::list<PHV::SuperCluster*>& cluster_groups,
            std::list<PHV::SuperCluster*>& unsliceable);

    std::list<PHV::SuperCluster*>
    remove_singleton_slicelist_metadata(
            const std::list<PHV::SuperCluster*>& cluster_groups);

    void sortClusters(std::list<PHV::SuperCluster*>& cluster_groups);

    std::list<PHV::SuperCluster*>
    allocLoop(PHV::Transaction& rst,
              std::list<PHV::SuperCluster*>& cluster_groups,
              const std::list<PHV::ContainerGroup *>& container_groups);

    /** Return a vector of slicing schemas for @p sc, that
     *
     *  1. Slicing by the available spots on containers.
     *  2. Slicing by 7, 6, 5...1-bit chunks.
     *
     */
    std::vector<bitvec>
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
class AllocatePHV : public Inspector {
 private:
    CoreAllocation core_alloc_i;
    PhvInfo& phv_i;
    const PhvUse& uses_i;
    const ClotInfo& clot_i;
    const Clustering& clustering_i;
    const SymBitMatrix& mutex_i;
    PHV::Pragmas& pragmas_i;

    // Used to create strategies, if they need
    ActionPhvConstraints& actions_i;
    // Used to create strategies, if needed
    const CalcCriticalPathClusters& critical_path_clusters_i;
    FieldInterference field_interference_i;

    bool preorder(const IR::BFN::ChecksumVerify* verify) override;
    bool preorder(const IR::BFN::ChecksumUpdate* update) override;
    bool preorder(const IR::BFN::ChecksumGet* get) override;

    /** The entry point.  This "pass" doesn't actually traverse the IR, but it
     * marks the place in the back end where PHV allocation does its work,
     * which is triggered by a call to `end_apply`.
     */
    void end_apply();

    /** Translate each AllocSlice in @alloc into a PHV::Field::alloc_slice and
     * attach it to the PHV::Field it slices.
     */
    static void bindSlices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv);

    /// Clear alloc_slices allocated in @phv, if any.
    static void clearSlices(PhvInfo& phv);

    /// @returns a SuperClusters from clustering_i.
    std::list<PHV::SuperCluster*> make_cluster_groups() const {
        return clustering_i.cluster_groups(); }

    /// @returns a concrete allocation.
    PHV::ConcreteAllocation make_concrete_allocation() const {
        return PHV::ConcreteAllocation(mutex_i, uses_i); }

    /** @returns the container groups available on this Device.  All fields in
     * a cluster must be allocated to the same container group.
     */
    static std::list<PHV::ContainerGroup *> makeDeviceContainerGroups();

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

 public:
    AllocatePHV(const Clustering& clustering,
                const PhvUse& uses,
                const FieldDefUse& defuse,
                const ClotInfo& clot,
                PHV::Pragmas& pragmas,
                PhvInfo& phv,
                ActionPhvConstraints& actions,
                const CalcCriticalPathClusters& critical_cluster)
        : core_alloc_i(phv.field_mutex, clustering, uses, defuse, clot, pragmas, phv, actions),
          phv_i(phv), uses_i(uses), clot_i(clot),
          clustering_i(clustering), mutex_i(phv.field_mutex), pragmas_i(pragmas),
          actions_i(actions), critical_path_clusters_i(critical_cluster),
          field_interference_i(phv.field_mutex, uses) { }
};

#endif  /* BF_P4C_PHV_ALLOCATE_PHV_H_ */
