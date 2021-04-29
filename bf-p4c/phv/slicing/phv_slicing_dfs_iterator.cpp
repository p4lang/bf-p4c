#include "bf-p4c/phv/slicing/phv_slicing_dfs_iterator.h"

#include <algorithm>
#include <numeric>
#include <sstream>

#include <boost/range/adaptor/reversed.hpp>

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/error.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/error.h"
#include "lib/exceptions.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"

namespace {

/// DeferHelper will call @p defer on leaving scope.
struct DeferHelper {
 public:
    std::function<void()> defer;
    explicit DeferHelper(std::function<void()> defer) : defer(defer) {}
    virtual ~DeferHelper() { defer(); }
};

}  // namespace

// SuperCluster with no slicelist has a different but much simpler iterator.
// Since there is no slice list, that means, there is only one rotational
// cluster in the super cluster. We only need to iterate all possible slicing
// by increasing the a bitvec representation of the cluster, where the n-th
// bit is one indicates "split at 8*(n+1)-th bit on the rotation cluster".
namespace PHV {
namespace Slicing {
namespace NoSliceListItr {

// inc @p bv by 1.
void inc(bitvec& bv) {
    int i = 0;
    for (; i <= (1 << 30); ++i) {
        if (bv.getbit(i)) {
            bv.clrbit(i);
        } else {
            break;
        }
    }
    bv.setbit(i);
}

// all_is_well_formed return true if all clusters are well-formed.
bool all_is_well_formed(const std::list<SuperCluster*>& clusters) {
    return std::all_of(clusters.begin(), clusters.end(),
                       [](const SuperCluster* s) { return SuperCluster::is_well_formed(s); });
}

// Returns a bitvec that there are no more than 3 consecutive 0s, by
// setting 1 on any "0000" to "0001" from higher to lower bits.
// It enforce less or equal to 32b constraints on the bitvec.
bitvec enforce_le_32b(const bitvec& bv, int sentinel) {
    bitvec rst = bv;
    int zeroes = 0;
    for (int i = sentinel - 1; i >= 0; --i) {
        if (rst[i]) {
            zeroes = 0;
        } else {
            zeroes++;
            if (zeroes > 3) {
                rst.setbit(i);
                zeroes = 0;
            }
        }
    }
    return rst;
}

// a simple iterator that can only be used if @p sc does not have any slicelist.
// it iterate all possible slicing by increasing the a bitvec representation of
// slicing the cluster, where the n-th bit is one indicates
// "split at 8*(n+1)-th bit on the rotation cluster".
void no_slicelist_itr(const IterateCb& yield, const SuperCluster* sc) {
    int sentinel_idx = sc->max_width() / 8 - (1 - bool(sc->max_width() % 8));
    if (sentinel_idx < 0) {
        return;
    }
    bitvec compressed_schema;
    while (!compressed_schema[sentinel_idx]) {
        // Expand the compressed schema.
        bitvec split_schema;
        for (int i : enforce_le_32b(compressed_schema, sentinel_idx)) {
            split_schema.setbit((i + 1) * 8);
        }
        // Split the supercluster.
        auto res = split_rotational_cluster(sc, split_schema);
        // If successful, return it.
        if (res && all_is_well_formed(*res)) {
            if (!yield(*res)) {
                return;
            }
        }
        inc(compressed_schema);
    }
}

}  // namespace NoSliceListItr
}  // namespace Slicing
}  // namespace PHV


namespace PHV {
namespace Slicing {

// return a std::map<int, FieldSlice> that maps i to the fieldslice on the i-th bit of @p sl.
const std::map<int, FieldSlice> make_fs_bitmap(const SuperCluster::SliceList* sl) {
    std::map<int, FieldSlice> rst;
    int offset = 0;
    for (const auto& fs : *sl) {
        for (int i = 0; i < fs.size(); i++) {
            rst[offset + i] = fs;
        }
        offset += fs.size();
    }
    return rst;
}


boost::optional<AfterSplitConstraint> AfterSplitConstraint::intersect(
    const AfterSplitConstraint& other) const {
    const AfterSplitConstraint* left = this;
    const AfterSplitConstraint* right = &other;
    if (left->t == ConstraintType::NONE) {
        return *right;
    }
    if (right->t == ConstraintType::NONE) {
        return *left;
    }
    if (left->t == ConstraintType::EXACT && right->t == ConstraintType::EXACT) {
        return left->size == right->size ? boost::make_optional(*left) : boost::none;
    } else if (left->t == ConstraintType::MIN && right->t == ConstraintType::MIN) {
        return AfterSplitConstraint {
            .t = AfterSplitConstraint::ConstraintType::MIN,
            .size = std::max(left->size, right->size),
        };
    } else {
        // unify (exact, min) or (min, exact) to (exact, min).
        if (left->t == ConstraintType::MIN) {
            std::swap(left, right);
        }
        return left->size >= right->size ? boost::make_optional(*left) : boost::none;
    }
}

// NextSplitChoiceMetrics is used during DFS to sort best slicing choice
// from [8, 16, 32]. Generally, we prefer to sort them by
// 1.  try to split at field boundaries. This one implicitly work with to_invalidate
//     because if we are trying not to split the field in the middle, and we
//     still meet some packing conflicts, then we should backtrack to avoid
//     the packing.
// 2.0 try split between referenced and non-referenced field.
// 2.1 (TODO) container sizes that are more abundant. It allows allocation
//     algorithm to balance between containers. More importantly, at the end
//     of allocation, we can prune a lot of invalid slicing. We need to add this
//     if pre-slicing is removed in allocation algorithm.
// 2.2 (TODO) except the above, for metadata slicelist, an important case is
//     that metadata fieldslices may be better to be sliced in the same way
//     as the header fields in the its rotational cluster.
// 3.  larger container to encourage more packings.
struct NextSplitChoiceMetrics {
    bool will_create_new_spilt = false;
    bool will_split_unreferenced = false;
    SplitChoice size;

    NextSplitChoiceMetrics(bool will_create_new_spilt, bool split_unreferenced, SplitChoice size)
        : will_create_new_spilt(will_create_new_spilt),
          will_split_unreferenced(split_unreferenced),
          size(size) {}

    // pick slice list with exact container, more constraints and
    // has smaller size as next target to form a smaller search tree.
    bool operator<(const NextSplitChoiceMetrics& other) {
        if (will_create_new_spilt != other.will_create_new_spilt) {
            return will_create_new_spilt > other.will_create_new_spilt;
        } else if (will_split_unreferenced != other.will_split_unreferenced) {
            return will_split_unreferenced < other.will_split_unreferenced;
        } else {
            return size < other.size;
        }
    }
};

std::vector<SplitChoice> DfsItrContext::make_choices(const SliceListLoc& target) const {
    // marks 1 if that bit is in the middle of a fieldslice.
    bitvec middle_of_fieldslices;
    int offset = 0;
    for (const auto& fs : *target.second) {
        if (!fs.field()->is_padding()) {
            for (int i = offset + 1; i < offset + fs.size(); i++) {
                middle_of_fieldslices.setbit(i);
            }
        }
        offset += fs.size();
        if (offset > 32) break;
    }

    // marks 1 if that bit is at a boundary of reference and unreferenced field,
    // that split [head...][rest...] into referenced list and unreferenced list.
    bitvec unreferenced_boundary;
    offset = 0;
    const bool is_head_referenced = is_used_i(target.second->front().field());
    for (const auto& fs : *target.second) {
        if (is_used_i(fs.field()) != is_head_referenced) {
            unreferenced_boundary.setbit(offset);
            break;
        }
        offset += fs.size();
        if (offset > 32) break;
    }

    int sl_sz = SuperCluster::slice_list_total_bits(*target.second);
    bool has_exact_containers = SuperCluster::slice_list_has_exact_containers(*target.second);
    if (!has_exact_containers) {
        // for metadata field slicelist, we must add the alignment to the slicelist.
        const auto& head = target.second->front();
        sl_sz += head.alignment() ? (*head.alignment()).align : 0;
    }
    bool has_tried_larger_sz = false;

    std::vector<NextSplitChoiceMetrics> choices;
    for (const auto& c : {
             SplitChoice::B,
             SplitChoice::H,
             SplitChoice::W,
         }) {
        // exact container slice list cannot be allocated to larger containters.
        if (int(c) > sl_sz && has_exact_containers) {
            continue;
        }
        // do not add duplicated choices for non_exact_container slice lists.
        // e.g. if the sl is 16-bit-long, then split at 16 is the same as at 32.
        if (int(c) >= sl_sz && !has_exact_containers) {
            if (has_tried_larger_sz) {
                continue;
            } else {
                has_tried_larger_sz = true;
            }
        }
        choices.push_back({
            bool(middle_of_fieldslices[int(c)]),
            bool(unreferenced_boundary[int(c)]),
            c,
        });
    }
    std::sort(choices.begin(), choices.end());

    std::vector<SplitChoice> rst;
    for (const auto& v : boost::adaptors::reverse(choices)) {
        rst.push_back(v.size);
    }
    return rst;
}

// NextSplitTargetMetrics is used during DFS for picking the next. It's
// extremely important to pick the one with most constraints to form a
// smaller search tree, in a same spirit of algorithm X,
// https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X
struct NextSplitTargetMetrics {
    int size = 0;
    bool has_exact_container = false;
    int n_after_split_constraints = 0;

    // pick slice list with exact container, more constraints and
    // has smaller size as next target to form a smaller search tree.
    bool operator>(const NextSplitTargetMetrics& other) {
        if (has_exact_container != other.has_exact_container) {
            return has_exact_container > other.has_exact_container;
        } else if (size != other.size) {
            return size < other.size;
        } else {
            return n_after_split_constraints > other.n_after_split_constraints;
        }
    }
};

boost::optional<SliceListLoc> DfsItrContext::dfs_pick_next() const {
    boost::optional<SliceListLoc> rst = boost::none;
    NextSplitTargetMetrics best;

    for (auto* sc : to_be_split_i) {
        // Unfortunately using after_split_constraints here implies that
        // fixes and improvement of after_split constraints will
        // change the order of searching, which may have a butterfly effect
        // on slicing and allocation in some cases.
        auto after_split_constraints = collect_aftersplit_constraints(sc);
        if (!after_split_constraints) {
            return boost::none;
        }

        for (auto* sl : sc->slice_lists()) {
            if (!need_further_split(sl)) {
                continue;
            }
            NextSplitTargetMetrics curr;
            curr.size = SuperCluster::slice_list_total_bits(*sl);
            curr.has_exact_container = sl->front().field()->exact_containers();
            for (const auto& fs : *sl) {
                if ((*after_split_constraints).count(fs) &&
                    (*after_split_constraints).at(fs).t !=
                        AfterSplitConstraint::ConstraintType::NONE) {
                    curr.n_after_split_constraints++;
                }
            }
            if (!rst || curr > best) {
                rst = make_pair(sc, sl);
                best = curr;
            }
        }
    }
    return rst;
}

std::pair<SplitSchema, SplitDecision> DfsItrContext::make_split_meta(
    SuperCluster* sc, SuperCluster::SliceList* target, int first_n_bits) const {
    SplitSchema schema;
    SplitDecision decisions;
    for (auto* sl : sc->slice_lists()) {
        schema[sl] = bitvec();
        if (sl != target) {
            continue;
        }
        const int sz = SuperCluster::slice_list_total_bits(*sl);
        const auto& head = sl->front();
        // For metadata fields with alignment, we should treat pre_aligment as virtual padding
        // before the field by setting the initial offset to the aligment, e.g.
        // meta<8> with alignment 3 cannot be allocated to 8-bit container, and the initial
        // offset will be 3.
        const int pre_alignment = head.field()->exact_containers()
                                      ? 0
                                      : (head.alignment() ? (*head.alignment()).align : 0);
        if (pre_alignment + sz > first_n_bits) {
            schema[sl].setbit(first_n_bits - pre_alignment);
        }

        AfterSplitConstraint container_size_constraint = {
            .t = AfterSplitConstraint::ConstraintType::EXACT,
            .size = first_n_bits,
        };
        // If slice list does not have exact containers, then split this slicelist
        // introduce only the minimum container size constraint,
        // because they can be flexibly allocate to any larger or equal container.
        if (!SuperCluster::slice_list_has_exact_containers(*sl)) {
            container_size_constraint.t = AfterSplitConstraint::ConstraintType::MIN;
        }

        int offset = pre_alignment;
        for (const auto& fs : *sl) {
            if (offset >= first_n_bits) {
                break;
            }
            if (offset + fs.size() <= first_n_bits) {
                decisions[fs] = container_size_constraint;
            } else {
                const int length = first_n_bits - offset;
                auto partial_fs = FieldSlice(fs, StartLen(fs.range().lo, length));
                decisions[partial_fs] = container_size_constraint;

                // Needs to update slices that has already been split.
                for (const auto& other : sc->cluster(fs).slices()) {
                    if (split_decisions_i.count(other)) {
                        const auto head = FieldSlice(other, StartLen(other.range().lo, length));
                        const auto tail = FieldSlice(
                            other, StartLen(other.range().lo + length, other.size() - length));
                        decisions[head] = split_decisions_i.at(other);
                        decisions[tail] = split_decisions_i.at(other);
                        LOG6("fs update " << other << " into " << head << " and " << tail
                                          << " because " << fs << " is split into " << partial_fs);
                    }
                }
            }
            offset += fs.size();
        }
    }
    return {schema, decisions};
}

std::list<SuperCluster*> DfsItrContext::split_by_adjacent_no_pack(SuperCluster* sc) const {
    // group fieldslices by the byte it locates, and then check no_pack constraint
    // between adjacent byte groups. If there are no_pack constraints, mark split
    // at the byte boundary.
    SplitSchema schema;
    for (auto* sl : sc->slice_lists()) {
        schema[sl] = bitvec();
        const std::map<int, FieldSlice> fs_bitmap = make_fs_bitmap(sl);
        const int n_bits = SuperCluster::slice_list_total_bits(*sl);
        const int n_bytes = n_bits / 8 + int(n_bits % 8 != 0);
        std::vector<ordered_set<const Field*>> group_by_byte(n_bytes);
        for (int i = 0; i < n_bytes; i++) {
            // group fieldslices by the byte they are in.
            for (int bit = i * 8; bit < (i + 1) * 8; bit++) {
                if (fs_bitmap.count(bit)) {
                    group_by_byte[i].insert(fs_bitmap.at(bit).field());
                }
            }
            if (i > 0) {
                for (const auto* fi : group_by_byte[i - 1]) {
                    for (const auto* fj : group_by_byte[i]) {
                        if (fi != fj && has_pack_conflict_i(fi, fj)) {
                            schema[sl].setbit(i * 8);
                            break;
                        }
                    }
                    if (schema[sl].getbit(i * 8)) {
                        break;
                    }
                }
            }
        }
    }
    LOG5("split_by_adjacent_no_pack schema: " << schema);
    auto rst = PHV::Slicing::split(sc, schema);
    if (rst) {
        return *rst;
    } else {
        ::warning("supercluster cannot be split at no_pack byte boundary: %1%",
                  cstring::to_cstring(sc));
        return { sc };
    }
}

// split by pa_container_size for those pragmas that are not up-casting,
// i.e. ignore cases like pa_container_sz(f1<8>, 32); Those will be left
// to be iterated by the allocation algorithm to figure out the best way.
bool DfsItrContext::split_by_pa_container_size(const SuperCluster* sc,
                                               const PHVContainerSizeLayout& pa_sz_layout) {
    // add wide_arith fields to pa_container_size requirements.
    PHVContainerSizeLayout pa = pa_sz_layout;
    sc->forall_fieldslices([&](const FieldSlice& fs) {
        const auto* field = fs.field();
        if (field->used_in_wide_arith()) {
            if (!pa.count(field)) {
                pa[field] = {32, 32};
            }
        }
    });
    // filter out exact_size pragmas;
    pa_container_size_upcastings_i.clear();
    // map (field, range) to AfterSplitConstraint::size when
    // pa_container_size pragma is applied.
    ordered_map<const Field*, ordered_map<le_bitrange, int>> expected_size;
    ordered_set<const Field*> exact_size_pragmas;
    for (const auto& kv : pa) {
        const auto* field = kv.first;
        const auto& sizes = kv.second;
        int total_sz =
            std::accumulate(sizes.begin(), sizes.end(), 0, [](int a, int s) { return a + int(s); });
        // invalid pragma, ignore, the earlier passes may not catch and error it,
        // because some pragma may be added by other passes, like meter_color,
        // and those passes do not check the validity.
        if (total_sz < field->size) {
            LOG6("Invalid pragma found on: " << field <<
                 ", with total @pa_container_size pragma sizes: " << total_sz);
            return false;
        } else if (total_sz == field->size) {
            LOG6("Found pa_container_size with same-size: " << field);
            exact_size_pragmas.insert(field);
            int offset = 0;
            for (const int sz : sizes) {
                expected_size[field][StartLen(offset, sz)] = sz;
                offset += sz;
            }
        } else {
            LOG6("Found upcasting pa_container_size pragma: " << field);
            // upcasting pragma, recorded for pruning.
            if (sizes.size() == 1) {
                pa_container_size_upcastings_i[field] = {StartLen(0, field->size), sizes.front()};
            } else {
                // multiple-sized upcasting pragma, only the tail needs to be upcasted.
                const int prefix_size = total_sz - sizes.back();
                pa_container_size_upcastings_i[field] = {StartLen(prefix_size, sizes.back()),
                                                         sizes.back()};
                // other than the tail, others will be split as specified, so we record them here.
                int offset = 0;
                for (const int sz : sizes) {
                    if (offset == prefix_size) {
                        break;
                    }
                    expected_size[field][StartLen(offset, sz)] = sz;
                    offset += sz;
                }
            }
        }
    }

    // split
    SplitSchema schema;
    for (auto* sl : sc->slice_lists()) {
        schema[sl] = bitvec();
        int offset = 0;
        const int sl_sz = SuperCluster::slice_list_total_bits(*sl);
        for (const auto& fs : *sl) {
            if (!pa.count(fs.field())) {
                offset += fs.size();
                continue;
            }
            const Field* field = fs.field();
            // exact pa_container_sizes should mark boundaries to split.
            // split at the beginning or the end of the field.
            if (exact_size_pragmas.count(field)) {
                if (fs.range().lo == 0) {
                    schema[sl].setbit(offset);
                }
                if (fs.range().hi == field->size - 1) {
                    schema[sl].setbit(offset + fs.size());
                }
            } else if (pa.at(field).size() > 1) {
                // expect for exact sizes pragma,
                // multiple-container-sized fields, if not exact_size_pragmas,
                // should mark the beginning boundary to split as well.
                if (fs.range().lo == 0) {
                    schema[sl].setbit(offset);
                }
            }

            // split in the middle of the field.
            int split_offset = 0;
            for (const auto& sz : pa.at(field)) {
                split_offset += int(sz);
                if (split_offset < fs.range().lo) {
                    continue;
                } else if (split_offset >= fs.range().lo && split_offset <= fs.range().hi + 1) {
                    schema[sl].setbit(offset + split_offset - fs.range().lo);
                } else {
                    break;
                }
            }
            offset += fs.size();
        }
        // do not mark the first or last bit.
        schema[sl].clrbit(0);
        schema[sl].clrbit(sl_sz);
    }

    LOG5("pa_container_sz slicing schema: " << schema);
    auto rst = PHV::Slicing::split(sc, schema);
    if (rst) {
        LOG5("split by pa_container_size result: ");
        for (const auto& sc : *rst) {
            LOG5(sc);
            sc->forall_fieldslices([&](const FieldSlice& fs) {
                if (!expected_size.count(fs.field())) {
                    return;
                }
                for (const auto& kv : expected_size.at(fs.field())) {
                    if (fs.range().intersectWith(kv.first).size() > 0) {
                        split_decisions_i[fs] = AfterSplitConstraint{
                            .t = AfterSplitConstraint::ConstraintType::EXACT,
                            .size = kv.second,
                        };
                        LOG1("pa_container_size enforced AfterSplitConstraint: "
                             << fs << " must be " << split_decisions_i[fs]);
                    }
                }
            });
        }
        to_be_split_i.insert(rst->begin(), rst->end());
        return true;
    } else {
        return false;
    }
}

void DfsItrContext::iterate(const IterateCb& cb) {
    BUG_CHECK(!has_itr_i, "One ItrContext can only generate one iterator.");
    has_itr_i = true;

    LOG3("Making Itr for " << sc_i);

    // no slice list supercluster, a simpler case.
    if (sc_i->slice_lists().size() == 0) {
        LOG3("empty slicelist SuperCluster");
        NoSliceListItr::no_slicelist_itr(cb, sc_i);
        return;
    }

    // slice_list validation
    for (const auto& sl : sc_i->slice_lists()) {
        if (SuperCluster::slice_list_has_exact_containers(*sl)) {
            int total_bits = SuperCluster::slice_list_total_bits(*sl);
            if (total_bits % 8 != 0) {
                LOG1("invalid supercluster, non_byte_aligned exact_containers slicelist: " << sl);
                return;
            }
        }
    }

    // apply pa_container_sizes-driven preslicing on clusters with
    // slicelists only.
    bool ok = split_by_pa_container_size(sc_i, pa_i);
    if (!ok) {
        LOG1("split by pa_container_sizes failed, iteration stopped.");
        return;
    }
    // preslicing by adjacent no_pack fields at byte boundary.
    ordered_set<SuperCluster*> split_by_no_pack;
    for (auto* sc : to_be_split_i) {
        auto after = split_by_adjacent_no_pack(sc);
        split_by_no_pack.insert(after.begin(), after.end());
    }
    to_be_split_i = split_by_no_pack;
    LOG1("after split by adjacent no_pack:");
    for (const auto& sc : to_be_split_i) {
        LOG1(sc);
    }
    dfs(cb);
}

bool DfsItrContext::need_further_split(const SuperCluster::SliceList* sl) const {
    for (const auto& fs : *sl) {
        if (split_decisions_i.count(fs) > 0) {
            return false;
        }
    }

    const int sl_sz = SuperCluster::slice_list_total_bits(*sl);
    const auto& head_alignment = sl->front().alignment();
    const int head_offset = (head_alignment ? (*head_alignment).align : 0);
    if (SuperCluster::slice_list_has_exact_containers(*sl)) {
        if (sl_sz <= 8) {
            return false;
        }
    } else {
        const int span = head_offset + sl_sz;
        if (span <= 8) {
            return false;
        }
    }

    // It marks bits of no_split point to 1 on the no_split bitvec.
    bitvec no_split;
    int offset = sl->front().field()->exact_containers() ? 0 : head_offset;
    boost::optional<FieldSlice> prev = boost::none;
    for (const auto& fs : *sl) {
        if (fs.field()->no_split()) {
            if (prev && fs.field() == (*prev).field()) {
                no_split.setbit(offset);
            }
            for (int i = 1; i < fs.size(); i++) {
                no_split.setbit(offset + i);
            }
        }
        prev = fs;
        offset += fs.size();
    }
    bool all_no_split = true;
    for (const int i : {8, 16, 32}) {
        if (i >= offset) {
            // XXX(yumin): use offset here because metadata may have aligment at head.
            break;
        }
        if (!no_split[i]) {
            all_no_split = false;
            break;
        }
    }
    if (all_no_split) {
        return false;
    }
    return true;
}

// check_pack_conflict checks whether there is any pack_conflict in the
// slice list that can be avoided.
// Note that there can be unavoidable pack_conflicts, for example, in this case
// even if f1 and f2 has pack conflict, because they are adjacent in byte,
// it's considered as unavoidable, function will return false.
// ingress::f1<20> ^0 meta no_split [0:10]
// ingress::f1<20> ^3 meta no_split [11:18]
// ingress::f1<20> ^3 meta no_split [19:19]
// ingress::f2<12> ^0 meta [0:11]
bool DfsItrContext::check_pack_conflict(const SuperCluster::SliceList* sl) const {
    int offset = 0;
    for (auto itr = sl->begin(); itr != sl->end(); offset += itr->size(), itr++) {
        auto next = std::next(itr);
        if (next != sl->end() && next->field() == itr->field()) {
            continue;
        }
        // If the end of fs reaches a byte boundary, skip.
        if ((offset + itr->size()) % 8 != 0) {
            const int tail_byte_num = (offset + itr->size()) / 8;
            // skip fields in the same byte, because no_pack is a soft constraints, when
            // fields are in a same byte, then it's impossible to allocate them without
            // violating this constraint.
            int next_offset = offset + itr->size();
            while (next != sl->end() && next_offset / 8 == tail_byte_num) {
                next_offset += next->size();
                next++;
            }
        }

        for (; next != sl->end(); next++) {
            if (itr->field() != next->field() && has_pack_conflict_i(itr->field(), next->field())) {
                LOG6("pack conflict: " << *itr << " and " << *next);
                return true;
            }
        }
    }
    return false;
}

bool DfsItrContext::dfs_prune_unwell_formed(const SuperCluster* sc) const {
    // cannot be split and is not well-formed.
    bool can_split_further = false;
    for (auto* sl : sc->slice_lists()) {
        if (need_further_split(sl)) {
            can_split_further = true;
        } else {
            // won't be split and contains packing conflicts.
            if (check_pack_conflict(sl)) {
                LOG5("DFS pruned: found pack conflict in: " << sl);
                return true;
            }
        }
    }
    auto err = new PHV::Error();
    if (!can_split_further && !SuperCluster::is_well_formed(sc, err)) {
        LOG5("DFS pruned: cannot split further and is not well formed: " << sc << ", because "
                                                                         << err->str());
        return true;
    }
    return false;
}

boost::optional<ordered_map<FieldSlice, AfterSplitConstraint>>
DfsItrContext::collect_aftersplit_constraints(const SuperCluster* sc) const {
    // sz decided by other fieldslice in the super cluster.
    ordered_map<FieldSlice, AfterSplitConstraint> decided_sz;
    bool has_conflicting_decisions = false;

    // record AfterSplitConstraint from pa_container_size upcasting pragma.
    sc->forall_fieldslices([&](const FieldSlice& fs) {
        if (pa_container_size_upcastings_i.count(fs.field())) {
            le_bitrange range;
            int size;
            std::tie(range, size) = pa_container_size_upcastings_i.at(fs.field());
            if (range.intersectWith(fs.range()).size() > 0) {
                decided_sz[fs] = AfterSplitConstraint{
                    .t = AfterSplitConstraint::ConstraintType::EXACT,
                    .size = size,
                };
            }
        }
    });

    // record AfterSplitConstraint from slice list that does not need any further
    // split but the decision was not made by DFS, i.e., split_decisions_i
    // does not count any fs of the field.
    for (const auto* sl : sc->slice_lists()) {
        if (!split_decisions_i.count(sl->front()) && !need_further_split(sl)) {
            const int sl_sz = SuperCluster::slice_list_total_bits(*sl);
            AfterSplitConstraint constraint = AfterSplitConstraint{
                .t = AfterSplitConstraint::ConstraintType::MIN,
                .size = ROUNDUP(sl_sz, 8) * 8,
            };
            // minor optimization: we don't have 24-bit container.
            if (constraint.size == 24) {
                constraint.size = 32;
            }
            if (SuperCluster::slice_list_has_exact_containers(*sl)) {
                constraint.t = AfterSplitConstraint::ConstraintType::EXACT;
            }
            for (const auto& fs : *sl) {
                if (decided_sz.count(fs)) {
                    auto intersection = constraint.intersect(decided_sz.at(fs));
                    if (!intersection) {
                        LOG5("DFS pruned(conflicted decisions with pragma): "
                             << "pragma constraint must " << decided_sz.at(fs) << ", but " << fs
                             << " must " << constraint);
                        return boost::none;
                    } else {
                        decided_sz[fs] = *intersection;
                    }
                } else {
                    decided_sz[fs] = constraint;
                }
            }
        }
    }

    // build mapping for same_container_group fields.
    ordered_map<const Field*, ordered_set<FieldSlice>> same_container_group_slices;
    sc->forall_fieldslices([&](const FieldSlice& fs) {
        if (fs.field()->same_container_group()) {
            same_container_group_slices[fs.field()].insert(fs);
        }
    });

    // collect constraints on all fieldslices.
    sc->forall_fieldslices([&](const FieldSlice& fs) {
        if (has_conflicting_decisions) {
            return;
        }
        AfterSplitConstraint constraint{.t = AfterSplitConstraint::ConstraintType::NONE, .size = 0};
        // propagate decision collected above, that was not made by DFS, to other fs in cluster.
        if (decided_sz.count(fs)) {
            constraint = decided_sz.at(fs);
        }
        if (split_decisions_i.count(fs)) {
            auto intersection = constraint.intersect(split_decisions_i.at(fs));
            if (!intersection) {
                LOG5("DFS pruned(conflicted decisions on same field): " << fs
                     << " must be both " << constraint << " and " << split_decisions_i.at(fs));
                has_conflicting_decisions = true;
                return;
            }
            constraint = *intersection;
        }
        if (constraint.t == AfterSplitConstraint::ConstraintType::NONE) {
            return;
        }

        ordered_set<FieldSlice> others;
        for (const auto& other : sc->cluster(fs).slices()) {
            others.insert(other);
        }
        // For slices of a field with same_container_group constraint, all those slices
        // will end up in a same supercluster, so they share same aftersplit constraints
        // just slices in a rotation cluster.
        if (fs.field()->same_container_group()) {
            for (const auto& other : same_container_group_slices.at(fs.field())) {
                others.insert(other);
            }
        }
        // propagate constraint.
        for (const auto& other : others) {
            if (!decided_sz.count(other)) {
                decided_sz[other] = constraint;
                continue;
            }

            auto intersection = decided_sz.at(other).intersect(constraint);
            if (!intersection) {
                LOG5("DFS pruned(conflicted decisions): " << other << " must "
                                                          << decided_sz.at(other) << ", but " << fs
                                                          << " must " << constraint);
                has_conflicting_decisions = true;
                return;
            } else {
                decided_sz[other] = *intersection;
            }
        }
    });
    if (has_conflicting_decisions) {
        return boost::none;
    }
    return decided_sz;
}

bool DfsItrContext::dfs_prune_unsat_slicelist_max_size(
    const ordered_map<FieldSlice, AfterSplitConstraint>& constraints,
    const SuperCluster* sc) const {
    // the maximum bits of slices that a fieldslice can reside in.
    ordered_map<FieldSlice, int> max_slicelist_bits;
    for (auto* sl : sc->slice_lists()) {
        int sz = SuperCluster::slice_list_total_bits(*sl);
        for (const auto& fs : *sl) {
            if (fs.field()->exact_containers()) {
                max_slicelist_bits[fs] = sz;
            }
        }
    }

    // (2) if max_slicelist_bits of other fields
    // in the same rot cluster is smaller than decided
    // sz, then it's impossible to split more.
    return sc->any_of_fieldslices([&](const FieldSlice& fs) {
        if (constraints.count(fs) && max_slicelist_bits.count(fs)) {
            const auto& constraint = constraints.at(fs);
            if (constraint.t != AfterSplitConstraint::ConstraintType::NONE &&
                constraint.size > max_slicelist_bits.at(fs)) {
                LOG5("DFS pruned(unsat_decision_sl_sz): "
                     << fs << " must be allocated to " << constraint
                     << ", but the slicelist it resides is only " << max_slicelist_bits.at(fs));
                return true;
            }
        }
        return false;
    });
}

// return true if constraints for a slice list cannot be *all* satisfied.
bool DfsItrContext::dfs_prune_unsat_slicelist_constraints(
    const ordered_map<FieldSlice, AfterSplitConstraint>& decided_sz, const SuperCluster* sc) const {
    // XXX(yumin): can be further improved by constraints that exact_container
    // slice lists starts with byte-boundry. But it maybe too complicated.
    for (auto* sl : sc->slice_lists()) {
        // apply on exact container slicelists only.
        if (!sl->front().field()->exact_containers()) {
            continue;
        }
        // bit to fieldlist mapping.
        const std::map<int, FieldSlice> fs_bitmap = make_fs_bitmap(sl);
        int sl_sz = SuperCluster::slice_list_total_bits(*sl);
        std::vector<AfterSplitConstraint> constraint_vec(
            sl_sz,
            AfterSplitConstraint{.t = AfterSplitConstraint::ConstraintType::NONE, .size = 0});
        int offset = 0;
        for (const auto& fs : *sl) {
            if (!decided_sz.count(fs) ||
                decided_sz.at(fs).t == AfterSplitConstraint::ConstraintType::NONE) {
                offset += fs.size();
                continue;
            }
            const auto sz_req = decided_sz.at(fs);

            // check constraint conflict.
            if (!sz_req.intersect(constraint_vec[offset])) {
                LOG5("DFS pruned(unsat_constraint_1): " << fs << ", decided sz: " << sz_req
                                                        << ", but the starting bit requires "
                                                        << constraint_vec[offset]);
                return true;
            }

            // collect all fields that is in the same byte with current fs.
            ordered_set<const Field*> same_byte_fields;
            for (int i = offset; i >= offset - (offset % 8); i--) {
                same_byte_fields.insert(fs_bitmap.at(i).field());
            }
            for (int i = offset + fs.size(); i % 8 != 0; i++) {
                same_byte_fields.insert(fs_bitmap.at(i).field());
            }

            // seek back to the left-most possible starting bit.
            int leftmost_start = offset;
            for (; leftmost_start >= 0; leftmost_start--) {
                const auto* prev_field = fs_bitmap.at(leftmost_start).field();
                if (!same_byte_fields.count(prev_field) && prev_field != fs.field() &&
                    has_pack_conflict_i(prev_field, fs.field())) {
                    break;
                }
                auto intersection = constraint_vec[leftmost_start].intersect(sz_req);
                if (!intersection) {
                    break;
                }
            }
            leftmost_start++;
            // leftmost_start plus the container size must cover the whole fieldslice.
            if (sz_req.t == AfterSplitConstraint::ConstraintType::MIN) {
                leftmost_start = std::max(leftmost_start, offset + fs.size() - 32);
            } else {
                leftmost_start = std::max(leftmost_start, offset + fs.size() - sz_req.size);
            }

            // check if there is enough room to satisfy se_req.
            if (leftmost_start + sz_req.size > sl_sz) {
                if (LOGGING(5)) {
                    LOG5("DFS pruned(unsat_constraint_2): not enough room at tail. "
                         << "slice list: " << sl << "\n, fieldslice " << fs
                         << " must be allocated to " << sz_req << ", offset: " << offset);
                    std::stringstream ss;
                    ss << "constraint map: \n";
                    for (size_t i = 0; i < constraint_vec.size(); i++) {
                        ss << i << ": " << constraint_vec[i] << "\n";
                    }
                    LOG5(ss.str());
                }
                return true;
            }

            // check forwarding pack_conflict.
            for (int i = leftmost_start; i < leftmost_start + sz_req.size; i++) {
                const auto* field = fs_bitmap.at(i).field();
                if (!same_byte_fields.count(field) && field != fs.field() &&
                    has_pack_conflict_i(field, fs.field())) {
                    LOG5("DFS pruned(unsat_constraint_3): not enough room after "
                         << i << ", slice list: " << sl << "\n, fieldslice " << fs
                         << " must be allocated to " << sz_req << ", offset: " << offset
                         << "\n, plus no_pack with " << fs_bitmap.at(i));
                    return true;
                }
            }

            // mark size constraints on the vector.
            for (int i = leftmost_start; i < leftmost_start + sz_req.size; i++) {
                constraint_vec[i] = *constraint_vec[i].intersect(sz_req);
            }
            offset += fs.size();
        }
    }
    return false;
}

// split_by_bytes split @p by each byte.
std::vector<SuperCluster::SliceList*> split_sl_at_byte_boundary(const SuperCluster::SliceList* sl) {
    int offset = 0;
    auto curr = new SuperCluster::SliceList();
    std::vector<SuperCluster::SliceList*> rst;
    for (auto itr = sl->begin(); itr != sl->end(); itr++) {
        const auto& fs = *itr;
        if (offset + fs.size() >= 8) {
            const int head_length = 8 - offset;
            auto head = FieldSlice(fs, StartLen(fs.range().lo, head_length));
            curr->push_back(head);
            auto remainder = new SuperCluster::SliceList();
            remainder->assign(std::next(itr), sl->end());
            if (fs.size() - head_length > 0) {
                auto tail =
                    FieldSlice(fs, StartLen(fs.range().lo + head_length, fs.size() - head_length));
                remainder->push_front(tail);
            }
            if (remainder->size() > 0) {
                rst = split_sl_at_byte_boundary(remainder);
            }
            rst.push_back(curr);
            return rst;
        } else {
            offset += fs.size();
            curr->push_back(fs);
        }
    }
    if (curr->size() > 0) {
        rst.push_back(curr);
    }
    return rst;
}

// RangeLookupableConstraints supports range lookup on field slices.
struct RangeLookupableConstraints {
    ordered_map<const Field*, std::map<le_bitrange, AfterSplitConstraint>> constraints;

    explicit RangeLookupableConstraints(
        const ordered_map<FieldSlice, AfterSplitConstraint>& original) {
        for (const auto& c : original) {
            constraints[c.first.field()][c.first.range()] = c.second;
        }
    }

    boost::optional<AfterSplitConstraint> lookup(const FieldSlice& fs) const {
        if (!constraints.count(fs.field())) {
            return boost::none;
        }
        for (const auto& c : constraints.at(fs.field())) {
            if (c.first.contains(fs.range())) {
                return c.second;
            }
        }
        return boost::none;
    }
};

bool DfsItrContext::dfs_prune_unsat_exact_list_size_mismatch(
    const ordered_map<FieldSlice, AfterSplitConstraint>& decided_sz, const SuperCluster* sc) const {
    const auto constraints = RangeLookupableConstraints(decided_sz);
    for (auto* sl : sc->slice_lists()) {
        // Note that exact_list_size mismatch can only be created by metadata lists that
        // merge two exact lists with different sizes into one supercluster. Also,
        // exact_containers list has been checked by collect_after_split_constraint already.
        if (sl->front().field()->exact_containers()) {
            continue;
        }
        std::vector<SuperCluster::SliceList*> targets;
        if (!need_further_split(sl)) {
            targets.push_back(sl);
        } else {
            targets = split_sl_at_byte_boundary(sl);
        }
        for (auto* target : targets) {
            AfterSplitConstraint exact_size_req{
                .t = AfterSplitConstraint::ConstraintType::NONE,
                .size = 0,
            };
            for (const auto& fs : *target) {
                auto fs_constraint = constraints.lookup(fs);
                if (fs_constraint) {
                    auto intersect = exact_size_req.intersect(*fs_constraint);
                    if (!intersect) {
                        LOG5("DFS pruned(unsat_exact_size_mismatch): at "
                             << fs << ", it must be " << *fs_constraint << " but there are "
                             << exact_size_req << " before this fieldslice");
                        return true;
                    } else {
                        exact_size_req = *intersect;
                    }
                }
            }
        }
    }
    return false;
}

bool DfsItrContext::dfs_prune() const {
    for (const auto* sc : to_be_split_i) {
        // unwell_formed
        if (dfs_prune_unwell_formed(sc)) {
            return true;
        }

        // conflicting constraints
        auto after_split_constraints = collect_aftersplit_constraints(sc);
        if (!after_split_constraints) {
            return true;
        }

        // unsat constraints due to slice list sz limit.
        if (dfs_prune_unsat_slicelist_max_size(*after_split_constraints, sc)) {
            return true;
        }

        // constraints for a slice list cannot be *all* satisfied.
        if (dfs_prune_unsat_slicelist_constraints(*after_split_constraints, sc)) {
            return true;
        }

        // prune when metadata list joins two size-mismatched exact lists.
        if (dfs_prune_unsat_exact_list_size_mismatch(*after_split_constraints, sc)) {
            return true;
        }
    }
    return false;
}

std::vector<SuperCluster*> DfsItrContext::get_well_formed_no_more_split() const {
    std::vector<SuperCluster*> rst;
    for (const auto& sc : to_be_split_i) {
        bool no_more_split = true;
        for (auto* sl : sc->slice_lists()) {
            if (need_further_split(sl)) {
                no_more_split = false;
                break;
            }
        }
        if (no_more_split && SuperCluster::is_well_formed(sc)) {
            rst.push_back(sc);
        }
    }
    return rst;
}

// return false if iteration should be terminated.
bool DfsItrContext::dfs(const IterateCb& yield) {
    n_steps_i++;
    if (n_steps_i > n_step_limit_i) {
        return false;
    }

    // track dfs search depth for debug.
    dfs_depth_i++;
    LOG5("ENTER DFS: " << dfs_depth_i);
    DeferHelper log_dfs_stack([this]() {
        LOG5("LEAVE DFS: " << dfs_depth_i);
        dfs_depth_i--;
    });

    // pruning
    if (dfs_prune()) {
        return true;
    }

    // move super clusters that cannot be split and well-formed to done.
    auto well_formed_cannot_split = get_well_formed_no_more_split();
    for (auto* sc : well_formed_cannot_split) {
        to_be_split_i.erase(sc);
        done_i.insert(sc);
    }
    DeferHelper revert_well_formed_cannot_split([&]() {
        for (auto* sc : well_formed_cannot_split) {
            to_be_split_i.insert(sc);
            done_i.erase(sc);
        }
    });

    // found one solution.
    if (to_be_split_i.empty()) {
        LOG4("found a solution after " << n_steps_i << " steps");
        return yield(std::list<SuperCluster*>(done_i.begin(), done_i.end()));
    }

    // search
    auto target = dfs_pick_next();
    if (!target) {
        return true;
    }
    auto* sc = (*target).first;
    auto* sl = (*target).second;
    LOG5("dfs_depth-" << dfs_depth_i << ": will split " << sl);

    // remove this sc from to_be_split.
    to_be_split_i.erase(sc);
    DeferHelper resotre_target([&]() { to_be_split_i.insert(sc); });

    // try all possible way to split out the first N bits of the slicelist
    // then recursion.
    auto choices = make_choices(*target);
    if (LOGGING(5)) {
        for (const auto& c : choices) {
            LOG5("dfs_depth-" << dfs_depth_i << ": possible choice " << int(c));
        }
    }
    for (const auto& choice : choices) {
        // create metadata for making a split.
        std::pair<SplitSchema, SplitDecision> split_meta = make_split_meta(sc, sl, int(choice));
        auto rst = PHV::Slicing::split(sc, split_meta.first);
        if (rst) {
            LOG5("dfs_depth-" << dfs_depth_i << ": decide to split out first " << int(choice)
                              << " bits of " << sl);
            to_be_split_i.insert(rst->begin(), rst->end());
            split_decisions_i.insert(split_meta.second.begin(), split_meta.second.end());
            slicelist_head_on_stack_i.push_back(sl->front());
            DeferHelper restore_results([&]() {
                for (const auto& sc : *rst) {
                    to_be_split_i.erase(sc);
                }
                for (auto& v : split_meta.second) {
                    split_decisions_i.erase(v.first);
                }
                slicelist_head_on_stack_i.pop_back();
            });
            if (!dfs(yield)) {
                return false;
            }
            if (to_invalidate != nullptr) {
                // checking the front fieldslice is enough because our way of searching is to
                // cut first N bits of sl. If found that the current sl is the invalidation
                // target, then we reset to_invalid. Otherwise, we backtrack to the layer that
                // its sl equals to invalidation.
                if (to_invalidate->front().field() == sl->front().field() &&
                    to_invalidate->front().range().lo == sl->front().range().lo) {
                    LOG1("to_invalidate stop at dfs-depth-"
                         << dfs_depth_i << ", last choice: " << int(choice) << " on " << sl);
                    to_invalidate = nullptr;
                } else {
                    LOG1("found to_invalidate, backtrack: " << to_invalidate);
                    return true;
                }
            }
        } else {
            LOG5("cannot split by " << int(choice));
        }
    }
    return true;
}

void DfsItrContext::invalidate(const SuperCluster::SliceList* sl) {
    for (const auto& on_stack : slicelist_head_on_stack_i) {
        if (on_stack.field() == sl->front().field() &&
            on_stack.range().lo == sl->front().range().lo) {
            // set to_invalidate only when we are sure that sl is on the stack.
            to_invalidate = sl;
            return;
        }
    }
}

std::ostream& operator<<(std::ostream& out, const PHV::Slicing::AfterSplitConstraint& c) {
    switch (c.t) {
        case AfterSplitConstraint::ConstraintType::EXACT: {
            out << "=";
            break;
        }
        case AfterSplitConstraint::ConstraintType::MIN: {
            out << ">=";
            break;
        }
        default:
            return out;
    }
    out << c.size;
    return out;
}

}  // namespace Slicing
}  // namespace PHV
