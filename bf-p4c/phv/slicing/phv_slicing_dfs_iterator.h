#ifndef BF_P4C_PHV_SLICING_PHV_SLICING_DFS_ITERATOR_H_
#define BF_P4C_PHV_SLICING_PHV_SLICING_DFS_ITERATOR_H_

#include <utility>

#include "bf-p4c/phv/slicing/phv_slicing_split.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/ordered_set.h"

namespace PHV {
namespace Slicing {

/// locate a slice list.
using SliceListLoc = std::pair<SuperCluster*, SuperCluster::SliceList*>;

/// constraints introduced on fieldslices of container sizes after splitting a slice list.
struct AfterSplitConstraint {
    enum class ConstraintType {
        EXACT = 0,  // must be placed in container of the size.
        MIN = 1,    // must be placed in container at least the size.
        NONE = 2,   // no new constraint.
    };
    ConstraintType t;
    int size;

    // returns the intersection of two AfterSplitConstraint.
    // e.g. MIN(8)   ^ EXACT(32) = EXACT(32)
    //      MIN(8)   ^ MIN(16)   = MIN(16)
    //      EXACT(8) ^ EXACT(16) = boost::none
    boost::optional<AfterSplitConstraint> intersect(const AfterSplitConstraint& other) const;
};

std::ostream& operator<<(std::ostream& out, const AfterSplitConstraint& c);

/// map FieldSlices to AfterSplit constraints introduced by the slicing decisions.
using SplitDecision = ordered_map<FieldSlice, AfterSplitConstraint>;

/// SplitChoice for a slice list.
enum class SplitChoice {
    B = 8,
    H = 16,
    W = 32,
};

/// DfsItrContext implements the Slicing Iterator using DFS.
/// Because caller won't be using DfsItrContext directly(protected by pImpl),
/// to make white-box testing possible, all functions are public.
class DfsItrContext : public IteratorInterface {
 public:
    // input
    const PhvInfo& phv_i;
    const SuperCluster* sc_i;
    const PHVContainerSizeLayout pa_i;
    const PackConflictChecker has_pack_conflict_i;
    const IsReferencedChecker is_used_i;
    bool minimal_packing_mode_i = false;

    // if a pa_container_size asks a field to be allocated to containers larger than it's
    // size, it's recorded here and will be used during pruning. Note that for one field,
    // there can only one upcasting piece, which is the tailing part.
    ordered_map<const PHV::Field*, std::pair<le_bitrange, int>> pa_container_size_upcastings_i;

    //// DFS states
    // split_decisions collects slicing decisions already made and
    // map fieldslice -> the after split constraints of the fieldslice.
    // The trick here is what we use a value, FieldSlice, representing that,
    // if a slicelist contains any fieldslice in this set, then the split decision
    // for that slicelist has already been made.
    SplitDecision split_decisions_i;

    // slicelist_head_on_stack stores all first fieldslices of slice_lists
    // already split on the DFS stack.
    std::vector<PHV::FieldSlice> slicelist_head_on_stack_i;

    // done_i is a set of super clusters that
    // (1) all slice slices are already split, or cannot be split further.
    // (2) the super cluster is well-formed, i.e. SuperCluster::is_well_formed() = true.
    ordered_set<SuperCluster*> done_i;

    // super clusters left to be sliced.
    ordered_set<SuperCluster*> to_be_split_i;

    // true if has itr generated before. one context can only generate one iterator.
    bool has_itr_i = false;

    // tracking dfs depth.
    int dfs_depth_i = 0;

    // a step counter records how many steps the search has tried.
    int n_steps_i = 0;
    // maximum search steps.
    const int n_step_limit_i;

    // last solution was found at n_steps_since_last_solution before.
    int n_steps_since_last_solution = 0;
    // max steps per one valid solution.
    const int n_step_limit_per_solution;

    // if not nullptr, backtrack to the stack that to_invalidate is not on stack,
    // i.e. not a part of the DFS path.
    const SuperCluster::SliceList* to_invalidate = nullptr;

 public:
    DfsItrContext(const PhvInfo& phv, const SuperCluster* sc, const PHVContainerSizeLayout& pa,
                  const PackConflictChecker& pack_conflict,
                  const IsReferencedChecker is_used,
                  int max_search_steps = (1 << 25),
                  int max_search_steps_per_solution = (1 << 19))
        : phv_i(phv),
          sc_i(sc),
          pa_i(pa),
          has_pack_conflict_i(pack_conflict),
          is_used_i(is_used),
          n_step_limit_i(max_search_steps),
          n_step_limit_per_solution(max_search_steps_per_solution) {}

    /// iterate will pass valid slicing results to cb. Stop when cb returns false.
    void iterate(const IterateCb& cb) override;

    /// invalidate is the feedback mechanism for allocation algorithm to
    /// ask iterator not to produce slicing result contains @p sl.
    void invalidate(const SuperCluster::SliceList* sl) override;

    /// set minimal packing mode to true so that iterator will get slicing results
    /// that prefers minimal packing first.
    void set_minimal_packing_mode(bool enable) override { minimal_packing_mode_i = enable; }

    /// dfs search valid slicing. @p unchecked are superclusters that needs to be checked
    /// for pruning.
    bool dfs(const IterateCb& yield, const ordered_set<SuperCluster*>& unchecked);

    /// split_by_pa_container_size will split @p sc by @p pa container size.
    boost::optional<std::list<SuperCluster*>> split_by_pa_container_size(
        const SuperCluster* sc, const PHVContainerSizeLayout& pa);

    /// split_by_adjacent_no_pack will split @p sc at byte boundary if two adjacent fields
    /// cannot be packed into one container.
    boost::optional<std::list<SuperCluster*>> split_by_adjacent_no_pack(SuperCluster* sc) const;

    /// split_by_deparsed_bottom_bits will split at the beginning of deparsed_bottom_bits field.
    boost::optional<std::list<SuperCluster*>> split_by_deparsed_bottom_bits(
        SuperCluster* sc) const;

    /// split_by_adjacent_deparsed_and_non_deparsed will split @p sc between deparsed and
    /// non-deparsed field.
    boost::optional<std::list<SuperCluster*>> split_by_adjacent_deparsed_and_non_deparsed(
        SuperCluster* sc) const;

    /// split_by_valid_container_range will split based on valid container range constraint
    /// that a field cannot be packed fields after it, when its valid container range
    /// is equal to the size of the field.
    boost::optional<std::list<SuperCluster*>> split_by_valid_container_range(
        SuperCluster* sc) const;

    /// split_by_long_fieldslices will split fieldslices that its length is greater or equal to
    /// 64 bits, using 32-bit container if possible.
    boost::optional<std::list<SuperCluster*>> split_by_long_fieldslices(SuperCluster* sc) const;

    /// return possible SplitChoice on @p target.
    /// When minimal_packing_mode is false, results are sorted with a set of heuristics
    /// that choices with more packing opportunities (generally larger container-sized chunks),
    /// ,split at field boundaries, and better chances to split between ref/unref fields,
    /// are placed at lower indexes. See implementation for more details on heuristics.
    /// If minimal_packing_mode is true, then we will prefer to split with less packing
    /// of fieldslices.
    std::vector<SplitChoice> make_choices(const SliceListLoc& target) const;

    /// pruning strategies
    /// return true if found any unsatisfactory case. This function will return true
    /// if any of the following pruning strategies returns true.
    bool dfs_prune(const ordered_set<SuperCluster*>& unchecked) const;

    /// dfs_prune_unwell_formed: return true if
    /// (1) @p sc cannot be split further and is not well_formed.
    /// (2) a slicelist in @p sc that cannot be split further has pack conflicts.
    bool dfs_prune_unwell_formed(const SuperCluster* sc) const;

    /// return true if exists constraint unsat due to the limit of slice list size.
    bool dfs_prune_unsat_slicelist_max_size(
        const ordered_map<FieldSlice, AfterSplitConstraint>& constraints,
        const SuperCluster* sc) const;

    /// return true if constraints for a slice list cannot be *all* satisfied.
    /// Check for cases like:
    ///    32      xxx      16
    /// [fs1<8>, fs2<8>, fs3<16>]
    /// it's unsat because fs1 was decided to be allocated into 32-bit container
    /// while for fs3 it's 16-bit container. However, in the above layout
    /// it's impossible. We run a greedy algorithm looking for cases but may have
    /// false negatives.
    bool dfs_prune_unsat_slicelist_constraints(
        const ordered_map<FieldSlice, AfterSplitConstraint>& constraints,
        const SuperCluster* sc) const;

    /// return true if exists a medatada list that will join two
    /// exact_containers lists of different sizes. For example:;
    /// sl_1: [f1<16>, f2<8>, f3<8>[0:1], f3<8>[2:7]], total 32, exact.
    /// sl_2: [f2'<8>, f4<8>[0:3], f4<8>[4:7]], total 16, exact.
    /// sl_3: [md1<2>, pad<2>, md2<4>]
    /// rotational clusters:
    /// {f3[0:1], md1}, {f4<8>[0:3], md2}
    /// sl_3 will join sl_1 and sl_2 into one super cluster, and we can infer that
    /// this cluster is invalid because exact slice list sizes are not the same.
    bool dfs_prune_unsat_exact_list_size_mismatch(
        const ordered_map<FieldSlice, AfterSplitConstraint>& decided_sz,
        const SuperCluster* sc) const;

    /// collect_aftersplit_constraints returns AfterSplitConstraints on the fieldslice
    /// of @p sc based on split_decisions_i and pa_container_size_upcastings_i.
    boost::optional<ordered_map<FieldSlice, AfterSplitConstraint>> collect_aftersplit_constraints(
        const SuperCluster* sc) const;

    /// dfs_pick_next return the next slice list to be split.
    /// There are some heuristics for returning the slicelist that has most constraints.
    boost::optional<SliceListLoc> dfs_pick_next() const;

    /// make_split_meta will generate schema and decision to split out first @p first_n_bits
    /// of @p sl under @p sc.
    std::pair<SplitSchema, SplitDecision> make_split_meta(SuperCluster* sc,
                                                          SuperCluster::SliceList* sl,
                                                          int first_n_bits) const;

    /// return true if the slicelist needs to be further split.
    bool need_further_split(const SuperCluster::SliceList* sl) const;

    /// return true if there are pack_conflicts in @p sl.
    bool check_pack_conflict(const SuperCluster::SliceList* sl) const;

    /// get_well_formed_no_more_split returns super clusters that all the slice lists
    /// does not need_further_split, and the cluster is well_formed.
    std::vector<SuperCluster*> get_well_formed_no_more_split() const;
};

}  // namespace Slicing
}  // namespace PHV

#endif /* BF_P4C_PHV_SLICING_PHV_SLICING_DFS_ITERATOR_H_ */
