#ifndef BF_P4C_PHV_V2_ALLOCATOR_BASE_H_
#define BF_P4C_PHV_V2_ALLOCATOR_BASE_H_

#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

/// AllocatorBase contains all reusable functions for PHV allocation, mostly 3 categories:
/// (1) constraint checking functions that their names usually start with is_.
/// (2) helper functions starts with make_* or compute_*.
/// (3) allocation functions: const-qualified functions that returns an AllocResult.
class AllocatorBase {
 protected:
    const AllocUtils& utils_i;

 protected:
    /// @returns error when @p sl cannot fit the container type constraint of @p c.
    const AllocError* is_container_type_ok(const AllocSlice& sl, const Container& c) const;

    /// @returns error when @p sl does not have the same gress assignment as @p c.
    const AllocError* is_container_gress_ok(const Allocation& alloc,
                                            const AllocSlice& sl,
                                            const Container& c) const;

    /// @returns error when there is the parser write mode of @p sl is different from other
    /// slices allocated in containers of the same parser group.
    const AllocError* is_container_write_mode_ok(const Allocation& alloc,
                                                 const AllocSlice& sl,
                                                 const Container& c) const;

    /// @returns error when trying to pack a field with solitary constraint with other fields.
    const AllocError* is_container_solitary_ok(const Allocation& alloc,
                                               const AllocSlice& candidate,
                                               const Container& c) const;

    /// @returns error if packing
    /// (1) uninitialized field with extracted field.
    /// (2) extracted field with other extracted field while not extracted together.
    const AllocError* is_container_parser_packing_ok(const Allocation& alloc,
                                                     const AllocSlice& candidate,
                                                     const Container& c) const;

    /// @returns error if violating max container bytes constraints on some field.
    const AllocError* is_container_bytes_ok(const Allocation& alloc,
                                            const std::vector<AllocSlice>& candidates,
                                            const Container& c) const;

    /// @returns error if violating any of the above is_container_* constraint.
    const AllocError* check_container_scope_constraints(
        const Allocation& alloc,
        const std::vector<AllocSlice> candidates,
        const Container& c) const;

    /// @returns AllocError if can_pack verification failed.
    /// NOTE: when @p c is an empty normal container, a special error with
    /// code CANNOT_PACK_CANDIDATES will be returned.
    /// It indicates that even if we are allocating candidates to an empty container
    /// (assume all other container-scope constraint checks have passed), we still cannot pack
    /// or allocate candidates, which usually means that we need to slice the original super
    /// cluster, which has the slice list of @p candidates, differently, to avoid some packings.
    const AllocError* verify_can_pack(const ScoreContext& ctx,
                                      const Allocation& alloc,
                                      const SuperCluster* sc,
                                      const std::vector<AllocSlice>& candidates,
                                      const Container& c) const;

    /// Generate pseudo AllocSlices for field slices that have not been allocated, but their
    /// allocation can be speculated upfront: when there is only one valid starting position.
    /// @returns a transaction that contains the pseudo AllocSlices.
    /// we can infer that field slices will be allocated to a container with corresponding
    /// starting positions. This will allow can_pack function to check constraints from
    /// action reading(writing) side, even if destination(source) has not been allocated yet.
    Transaction make_speculated_alloc(const ScoreContext& ctx,
                                      const Allocation& alloc,
                                      const SuperCluster* sc,
                                      const std::vector<AllocSlice>& candidates,
                                      const Container& candidates_cont) const;


    /// @returns a set of container sizes that are okay for @p sc.
    std::set<PHV::Size> compute_valid_container_sizes(const SuperCluster* sc) const;

    /// Try to allocate fieldslices with starting positions defined in @p fs_starts to container @p
    /// c. Various container-level constraints will be checked.
    /// Premises without BUG_CHECK:
    ///   (1) @p fs_starts contains all field slices that needs to be allocated to @p c. They
    ///       should never exceed the width of the container,
    ///       i.e., max_i(start_i + size_i) < c.width().
    ///   (2) allocating to @p c will not violate pa_container_size pragma specified on
    ///       field slices in @p fs_starts:
    ///   (3) if there were wide_arithmetic slices, if lo(hi), @p c must have even(odd) index. Also
    ///       caller needs to allocate them to adjacent even-odd pair containers.
    ///   (4) if deparsed/exact_container, total number of bits must be equal to the width of @p c.
    /// @returns error in AllocResult if
    ///   (1) not enough space:
    ///      <1> non-mutex bits occupied or has non-mutex solitary field.
    ///      <2> uninitialized read + extracted.
    ///   (2) cannot pack into container.
    ///   (3) when container is mocha/dark/tphv, not all field slices are be valid
    ///       to be allocated to the container type of @p c.
    ///   (4) violate pa_container_type.
    ///   (5) container gress match
    ///   (6) parserGroupGress match, all containers must have same write mode.
    ///   (7) deparser group must be the same.
    ///   (8) solitary fields are not packed with other fields except for paddings fields.
    ///   (9) fields in @p fs_starts will not violate parser extraction constraints.
    ///   (5) field max container bytes constraints.
    /// NOTE: alloc slices of ignore_alloc field slices will not be generated.
    AllocResult try_slices_to_container(
        const ScoreContext& ctx,
        const Allocation& alloc,
        const FieldSliceAllocStartMap& fs_starts,
        const Container& c) const;

    /// try to find a valid container in @p group for @p fs_starts by calling
    /// try_slices_to_container on every container of @p group. The returned result
    /// will be the container that has the highest score based on ctx.score()->make().
    /// Premises without BUG_CHECK:
    ///   (1) AllocSlices that will be generated based on @p fs_starts will not exceed
    ///       the size of width of @p group.
    ///   (2) @p ctx score has been initialized.
    AllocResult try_slices_to_container_group(
        const ScoreContext& ctx,
        const Allocation& alloc,
        const FieldSliceAllocStartMap& fs_starts,
        const ContainerGroup& group) const;

    /// try to allocate a pair of wide_arith slice lists (@p lo, @p hi) to an even-odd
    /// pair of containers in @p group.
    AllocResult try_wide_arith_slices_to_container_group(
        const ScoreContext& ctx,
        const Allocation& alloc,
        const ScAllocAlignment& alignment,
        const SuperCluster::SliceList* lo,
        const SuperCluster::SliceList* hi,
        const ContainerGroup& group) const;

    /// try to allocate @p sc with @p alignment to @p group.
    AllocResult try_super_cluster_with_alignment_to_container_group(
        const ScoreContext& ctx,
        const Allocation& alloc,
        const SuperCluster* sc,
        const ScAllocAlignment& alignment,
        const ContainerGroup& group) const;

    // TODO(yumin): add this function that tries to split and allocate the super cluster to
    // the set of container groups.
    // AllocResult try_split_and_alloc_super_cluster(const ScoreContext& ctx,
    //                                               const Allocation& alloc,
    //                                               const SuperCluster* sc,
    //                                               const ContainerGroupsBySize& groups) const;

 public:
    explicit AllocatorBase(const AllocUtils& utils): utils_i(utils) {};
    virtual ~AllocatorBase() {};

    /// Try to allocate @p sc, without further slicing, to @p groups.
    /// Premise:
    /// (1) DO NOT pass fully clot-allocated clusters to this function. If does, fields will
    ///     be double-allocated.
    /// (2) DO NOT pass deparser-zero-candidate cluster to this function, because they will not be
    ///     allocated to zero containers, Unless the correctness of their allocation does not
    ///     matter, e.g., in trivial allocator, as they are not referenced in MAU.
    AllocResult try_sliced_super_cluster(const ScoreContext& ctx,
                                         const Allocation& alloc,
                                         const SuperCluster* sc,
                                         const ContainerGroupsBySize& groups) const;

    /// This function will always successfully allocate fieldslices of @p sc to deparser zero
    /// optimization containers, which are B0 for ingress, B16 for egress. phv.addZeroContainer()
    /// will be called to add used deparser-zero containers.
    /// NOTE: if @p sc is fully-clot allocated, it will be ignored.
    /// premise:
    /// (1) @p sc must be deparser-zero optimization candidate.
    PHV::Transaction alloc_deparser_zero_cluster(const ScoreContext& ctx,
                                                 const PHV::Allocation& alloc,
                                                 const PHV::SuperCluster* sc,
                                                 PhvInfo& phv) const;
};

}  // namespace v2
}  // namespace PHV


#endif /* BF_P4C_PHV_V2_ALLOCATOR_BASE_H_ */
