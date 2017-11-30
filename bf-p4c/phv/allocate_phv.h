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
#include "lib/symbitmatrix.h"


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
    // Input.
    const SymBitMatrix& mutex_i;
    const Clustering& clustering_i;
    const PhvUse& uses_i;
    const ClotInfo& clot_i;

    // Modified in this pass.
    PhvInfo& phv_i;
    ActionPhvConstraints& actions_i;

    /** The entry point.  This "pass" doesn't actually traverse the IR, but it
     * marks the place in the back end where PHV allocation does its work,
     * which is triggered by a call to `end_apply`.
     */
    void end_apply();

 public:
    AllocatePHV(const SymBitMatrix& mutex,
                const Clustering& clustering,
                const PhvUse& uses,
                const ClotInfo& clot,
                PhvInfo& phv,
                ActionPhvConstraints& actions)
    : mutex_i(mutex), clustering_i(clustering), uses_i(uses), clot_i(clot), phv_i(phv),
      actions_i(actions) { }

    /// Throw a pretty-printed ::error when allocation fails.
    static void formatAndThrowError(
        const PHV::Allocation& alloc,
        const std::list<PHV::SuperCluster *>& unallocated);

    /// Sorts @clusters and @groups according to the waterfall allocation strategy.
    static void makeAllocationStrategy(
        const PHV::Allocation& alloc,
        std::list<PHV::SuperCluster *>& clusters,
        std::list<PHV::ContainerGroup *>& groups);

    /** @returns the container groups available on this Device.  All fields in
     * a cluster must be allocated to the same container group.
     */
    static std::list<PHV::ContainerGroup *> makeDeviceContainerGroups();

    /** Return a vector of consecutive bit ranges of size @slice_size starting
     * at 0 (zero) and adding up to @aggregate_size.  The first and last slices
     * may be smaller than @size if the starting bit in the container (@start)
     * is non-zero.  For example:
     *
     *                            3                             <-- start ==  3
     * container slices:       [---][---][---][---][---]       slice size ==  5
     * whole field:               |------------------|     aggregate size == 20
     * field slices:              [][---][---][---][-]         
     *                            0 2    7    12   17
     *
     * @aggregate_size and @slice_size must be positive, and @start must be
     * greater than or equal to zero.
     */
    static
    std::vector<le_bitrange> make_field_slices(int aggregate_size, int slice_size, int start);

    /** Produces bit ranges with coordinates relative to the container rather
     * than the field.  The first slice is positioned at @start, the
     * others at 0.
     *
     * @see make_field_slices.
     */
    static
    std::vector<le_bitrange> make_container_slices(int aggregate_size, int slice_size, int start);

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

    /// @returns true if field list<-->container constraints are satisfied.
    bool satisfies_constraints(std::vector<PHV::AllocSlice> slices) const;

    /// @returns true if field<-->group constraints are satisfied.
    bool satisfies_constraints(const PHV::ContainerGroup& group, const PHV::Field* f) const;

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
        PHV::SuperCluster& cluster);

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
    boost::optional<PHV::Transaction> tryAlloc(
        const PHV::Allocation& alloc,
        const PHV::ContainerGroup& group,
        const std::vector<PHV::Field*>& fields,
        const ordered_map<const PHV::Field*, int>& start_positions);

    /** Helper function for tryAlloc that tries to allocate all the fields of a single CCGF.
     *
     * XXX(cole): It would be great not to have to special-case this.
     */
    boost::optional<PHV::Transaction> tryAllocCCGF(
            const PHV::Allocation& alloc,
            const PHV::ContainerGroup& group,
            PHV::Field* f,
            int start);

    /** Translate each AllocSlice in @alloc into a PHV::Field::alloc_slice and
     * attach it to the PHV::Field it slices.
     */
    static void bindSlices(const PHV::ConcreteAllocation& alloc, PhvInfo& phv);

    /// Clear alloc_slices allocated in @phv, if any.
    static void clearSlices(PhvInfo& phv);
};

#endif  /* BF_P4C_PHV_ALLOCATE_PHV_H_ */
