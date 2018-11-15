#ifndef BF_P4C_PHV_UTILS_SLICING_ITERATOR_H_
#define BF_P4C_PHV_UTILS_SLICING_ITERATOR_H_

#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
/** Increment @bv as if it were an unsigned integer of unbounded size. */
void inc(bitvec& bv);

/** Consider a bitvec where each bit indicates whether a field list should be
 * sliced at a corresponding 8b boundary.  Eg.
 *
 *          bv[0]    bv[1]    bv[2]
 *   |--------|--------|--------|--------|
 *
 * The following bit patterns correspond to slicing stragegies:
 *  - 000:  32b
 *  - 001:  24b /  8b               <-- invalid
 *  - 010:  16b / 16b
 *  - 011:  16b /  8b / 8b
 *  - 100:   8b / 24b               <-- invalid
 *  - 110:   8b /  8b / 16b
 *  - 111:   8b /  8b /  8b /  8b
 *
 * Adjacent 0s indicate how wide a slice will be; container-sized slices
 * correspond to no 0s, one 0, or three 0s.
 *
 * To limit the search space, this method checks the number of contiguous
 * trailing zeroes when it sets a bit; if there are two 0s, or more than three,
 * then the least signicant zeroes will be replaced with 1s, effectively
 * skipping the intervening slicings, which are destined to fail.
 *
 * For example, suppose we're incrementing 1111111:
 *
 *   after inc:                       10000000
 *   after enforce_container_sizes:   10001000
 *
 * This is the smallest number with groups of zero, one, or three zeroes.
 *
 * Slice lists that do not have the 'exact_containers' constraint can be sliced
 * into 24b sizes, i.e. can container sequences of two zeroes, but not more
 * than three.
 *
 * @param bv the bitvec of slice positions.
 *
 * @param sentinel is the size of the entire bitvec, including leading zeroes.
 * It corresponds to the bit position of a "sentinel" bit that is set to 1 when
 * all permutations of previous bit positions have been explored.
 *
 * @param boundaries marks the boundaries between slice lists.  Sequences of
 * zeroes need to be counted within (not across) boundaries.
 *
 * @param required marks required slices, i.e. bits that cannot be zero.
 *
 * @param exact_containers marks which bits in @bv correspond to slice lists
 * which require exact containers, i.e. cannot contain sequences of two zeroes.
 *
 * @warning this mutates @bv by reference.
 */
void enforce_container_sizes(
    bitvec& bv,
    int sentinel,
    const bitvec& boundaries,
    const bitvec& required,
    const bitvec& exact_containers);

/** A custom forward iterator that walks through all possible slicings of a
 * SuperCluster.
 */
class SlicingIterator {
    // Threshold for the number of different slicings tried by the slicing iterator. If more
    // slicings than this are tried, then error out with a message about being unable to slice
    // superclusters.
    static constexpr uint64_t SLICING_THRESHOLD = (1 << 20);

    /// Supercluster associated with this slicing iterator.
    const SuperCluster* sc_i;

    /// pa_container_size pragmas associated with this supercluster.
    std::map<const PHV::Field*, std::vector<PHV::Size>> pa_container_sizes_i;

    /// true when the pa_container_size pragmas have to be enforced for this SlicingIterator.
    bool enforcePragmas;

    /// true when all possible slicings have been exhausted. Two iterators
    /// with `done_i` set are always equal.
    bool done_i;

    /// true if the associated supercluster has slice lists.
    bool has_slice_lists_i;

    bitvec compressed_schemas_i;
    bitvec boundaries_i;
    bitvec required_slices_i;
    ordered_map<PHV::SuperCluster::SliceList*, le_bitrange> ranges_i;
    bitvec exact_containers_i;
    int sentinel_idx_i;
    std::list<PHV::SuperCluster*> cached_i;

    /// Number of different slicings tried by the slicing iterator.
    uint64_t num_slicings;

    void enforce_MAU_constraints_for_meta_slice_lists(
            ordered_map<PHV::SuperCluster::SliceList*, bitvec>& split_schema) const;

    /// @return a slicing based on the current value of compressed_schemas_i.
    boost::optional<std::list<PHV::SuperCluster*>> get_slices() const;

    /// @returns a representation of limits for slicing in a format suitable for pretty printing.
    cstring get_slice_coordinates(
            const int slice_list_size,
            const std::pair<int, int>& slice_location) const;

    /// Changes compressed_schemas_i to account for pa_container_size pragmas.
    void enforce_container_size_pragmas(
            const ordered_map<PHV::SuperCluster::SliceList*, std::pair<int, int>>&);

 public:
    explicit SlicingIterator(
            const SuperCluster* sc,
            const std::map<const PHV::Field*, std::vector<PHV::Size>>& pa,
            bool enforce_pragmas = true);

    /// @returns a list of possible slices of @sc.
    std::list<PHV::SuperCluster*> operator*() const;

    /// Increments this iterator to point to the next possible slicing of @sc.
    SlicingIterator operator++();

    /// @returns true if both iterators are over the same SuperCluster, both
    /// are done, or both have the same compressed schema value.
    bool operator==(const SlicingIterator& other) const;

    bool done() const { return done_i; }

    /// Split a SuperCluster with slice lists according to @split_schema.
    static boost::optional<std::list<PHV::SuperCluster*>> split_super_cluster(
        const PHV::SuperCluster* sc,
        ordered_map<PHV::SuperCluster::SliceList*, bitvec> split_schemas);

    /// Split the RotationalCluster in a SuperCluster without a slice list
    /// according to @split_schema.
    static boost::optional<std::list<PHV::SuperCluster*>> split_super_cluster(
        const PHV::SuperCluster* sc,
        bitvec split_schema);
};

}  // namespace PHV

#endif  /*  BF_P4C_PHV_UTILS_SLICING_ITERATOR_H_  */
