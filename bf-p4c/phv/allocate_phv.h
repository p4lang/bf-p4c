#ifndef BF_P4C_PHV_ALLOCATE_PHV_H_
#define BF_P4C_PHV_ALLOCATE_PHV_H_

#include <boost/optional.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/utils.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "lib/symbitmatrix.h"

/** A set of functions used in PHV allocation.
 */
class CoreAllocation {
    // Input.
    const SymBitMatrix& mutex_i;
    const Clustering& clustering_i;
    const PhvUse& uses_i;
    const ClotInfo& clot_i;

    // Modified in this pass.
    PhvInfo& phv_i;
    ActionPhvConstraints& actions_i;

    /** The score of a match.
     * + n_overlays, the number of overlaying bits.
     * + n_packings, the number of packings
     *
     * This score is used in two places,
     * 1. Inside tryAllocSliceList, we use this score to find
     *    a best container for a slice list.
     * 2. Inside tryAlloc, to find the best starting position
     *    for slices from a aligned_cluster.
     */
    struct MatchScore {
        int n_overlays;
        int n_packings;
        bool operator<(const MatchScore &other) {
            if (n_packings != other.n_packings) {
                return n_packings < other.n_packings; }
            return n_overlays < other.n_overlays;
        }
        MatchScore& operator+=(const MatchScore &other) {
            n_overlays += other.n_overlays;
            n_packings += other.n_packings;
            return *this; }
        MatchScore(int o, int p)
            : n_overlays(o), n_packings(p) { }
    };

 public:
    CoreAllocation(const SymBitMatrix& mutex,
                   const Clustering& clustering,
                   const PhvUse& uses,
                   const ClotInfo& clot,
                   PhvInfo& phv,
                   ActionPhvConstraints& actions)
        : mutex_i(mutex), clustering_i(clustering), uses_i(uses), clot_i(clot), phv_i(phv),
        actions_i(actions) { }

    /// Split @sc into container-sized chunks, prefering the largest container
    /// sizes possible.
    /// @returns a list of sliced SuperClusters, or @sc if no slicing occurred.
    static std::list<PHV::SuperCluster*> split_super_cluster(PHV::SuperCluster* sc);

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
    bitvec satisfies_constraints(
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

    /// @returns true if @c satisfies CCGF constraints on CCGF field @f given
    /// allocation @alloc.
    static bool satisfies_CCGF_constraints(
        const PHV::Allocation& alloc,
        const PHV::Field *f,
        PHV::Container c);

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
     * @field_list simultaneously.  Deparsed fields in particular need to be
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
     * Uses mutex_i and uses_i.
     */
    boost::optional<std::pair<PHV::Transaction, MatchScore>> tryAllocSliceList(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const PHV::SuperCluster::SliceList& slices,
        const ordered_map<const PHV::FieldSlice, int>& start_positions) const;

    /** Helper function for tryAlloc that tries to allocate all the fields of a single CCGF.
     *
     * XXX(cole): It would be great not to have to special-case this.
     */
    boost::optional<PHV::Transaction> tryAllocCCGF(
            const PHV::Allocation& alloc,
            const PHV::ContainerGroup& group,
            PHV::Field* f,
            int start) const;

    const PhvUse& uses() const { return uses_i; }
};

// TODO(yumin) extends this to include all possible cases.
enum class AllocResultCode {
    SUCCESS, FAIL
    // partial_success?
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

/** The greedy sorting strategy
 */
class GreedySortingAllocationStrategy : public AllocationStrategy {
 public:
    GreedySortingAllocationStrategy(const CoreAllocation& alloc, std::ostream& out)
        : AllocationStrategy(alloc, out) {}

    AllocResult
    tryAllocation(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  std::list<PHV::ContainerGroup *>& container_groups) override;

 protected:
    /** Waterfall allocation ordering:
     *
     *  - PHV clusters > 4 bits  --> PHV                (smallest to largest)
     *  - TPHV fields  > 4 bits  --> TPHV               (smallest to largest)
     *  - TPHV fields  > 4 bits  --> PHV                (smallest to largest)
     *  - POV fields             --> PHV
     *  - PHV fields  <= 4 bits  --> PHV
     *  - TPHV fields <= 4 bits  --> TPHV
     *  - TPHV fields <= 4 bits  --> PHV
     */
    void greedySort(
        const PHV::Allocation& alloc,
        std::list<PHV::SuperCluster*>& cluster_groups,
        std::list<PHV::ContainerGroup*>& container_groups);
};

/** Pick the container group that has the largest number of possible container for a cluster.
 * This strategy sort the container_groups, when allocating a SuperCluster,
 * by how many containers that may hold the this SuperCluster left.
 */
class BalancedPickAllocationStrategy : public AllocationStrategy {
 protected:
    const CalcCriticalPathClusters& critical_path_clusters_i;
    const FieldInterference& field_interference_i;

 public:
    BalancedPickAllocationStrategy(const CoreAllocation& alloc, std::ostream& out,
                                    const CalcCriticalPathClusters& cpc,
                                    const FieldInterference& f)
        : AllocationStrategy(alloc, out)
        , critical_path_clusters_i(cpc), field_interference_i(f) { }

    AllocResult
    tryAllocation(const PHV::Allocation &alloc,
                  const std::list<PHV::SuperCluster*>& cluster_groups_input,
                  std::list<PHV::ContainerGroup *>& container_groups) override;

 protected:
    /** Sorting SuperClusters
     * This order will guide the allocation.
     */
    virtual void greedySortClusters(std::list<PHV::SuperCluster*>& cluster_groups);

    /** Sort @p container_groups by how many containers that could
     * possibly hold @p cluster exists, decreasingly.
     */
    virtual void sortContainerBy(
        const PHV::Allocation& alloc,
        std::list<PHV::ContainerGroup *>& container_groups,
        const PHV::SuperCluster* cluster);

    /** The main O(n^2) loop.
     */
    std::list<PHV::SuperCluster*>
    allocLoop(PHV::Transaction& rst,
              std::list<PHV::SuperCluster*>& cluster_groups,
              std::list<PHV::ContainerGroup *>& container_groups);
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
    const Clustering& clustering_i;
    const SymBitMatrix& mutex_i;

    // Used to create strategies, if they need
    ActionPhvConstraints& actions_i;
    // Used to create strategies, if needed
    const CalcCriticalPathClusters& critical_path_clusters_i;
    FieldInterference field_interference_i;

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
        return PHV::ConcreteAllocation(mutex_i); }

    /** @returns the container groups available on this Device.  All fields in
     * a cluster must be allocated to the same container group.
     */
    static std::list<PHV::ContainerGroup *> makeDeviceContainerGroups();

    /// Throw a pretty-printed ::error when allocation fails.
    void formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<PHV::SuperCluster *>& unallocated);

 public:
    AllocatePHV(const SymBitMatrix& mutex,
                const Clustering& clustering,
                const PhvUse& uses,
                const ClotInfo& clot,
                PhvInfo& phv,
                ActionPhvConstraints& actions,
                const CalcCriticalPathClusters& critical_cluster)
        : core_alloc_i(mutex, clustering, uses, clot, phv, actions), phv_i(phv), uses_i(uses),
        clustering_i(clustering), mutex_i(mutex), actions_i(actions),
        critical_path_clusters_i(critical_cluster) , field_interference_i(mutex) { }
};

#endif  /* BF_P4C_PHV_ALLOCATE_PHV_H_ */
