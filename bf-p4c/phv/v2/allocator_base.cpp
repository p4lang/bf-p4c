#include "bf-p4c/phv/v2/allocator_base.h"

#include <sstream>
#include <tuple>
#include <unordered_map>

#include <boost/optional/optional.hpp>
#include <boost/range/join.hpp>

#include "bf-p4c/device.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/action_source_tracker.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/copacker.h"
#include "bf-p4c/phv/v2/phv_kit.h"
#include "bf-p4c/phv/v2/tx_score.h"
#include "bf-p4c/phv/v2/utils_v2.h"
#include "lib/exceptions.h"

namespace PHV {
namespace v2 {

namespace {

/// @returns true if @p f is mutex with all @p overlapped slices.
bool can_control_flow_overlay(const SymBitMatrix& mutex,
                              const Field* f,
                              const ordered_set<AllocSlice>& overlapped) {
    for (const auto& slice : overlapped)
        if (!mutex(f->id, slice.field()->id)) return false;
    return true;
}

/// @returns true if the live range of @p slice is disjoint with all slices in @p overlapped.
bool can_physical_liverange_overlay(const PhvKit& kit,
                                    const AllocSlice& slice,
                                    const ordered_set<AllocSlice>& overlapped) {
    BUG_CHECK(slice.isPhysicalStageBased(),
              "slice must be physical-stage-based in can_physical_liverange_overlay");
    for (const auto& other : overlapped) {
        BUG_CHECK(other.isPhysicalStageBased(),
                  "slice must be physical-stage-based in can_physical_liverange_overlay");
        if (!kit.can_physical_liverange_be_overlaid(slice, other)) {
            return false;
        }
    }
    return true;
}

/// @returns AllocSlices of @p fs_starts to @p c. Unreferenced fields and is_ignore_alloc will
/// be ignored.
std::vector<AllocSlice> make_alloc_slices(const PhvUse& uses,
                                          const FieldSliceAllocStartMap& fs_starts,
                                          const Container& c) {
    std::vector<AllocSlice> rst;
    for (const auto& kv : fs_starts) {
        const auto& fs = kv.first;
        const int start = kv.second;
        // skip ignore alloc field slice and not referenced field if not ghost field.
        if (fs.field()->is_ignore_alloc() ||
            (!uses.is_referenced(fs.field()) && !fs.field()->isGhostField())) {
            continue;
        }
        auto alloc_slice = AllocSlice(fs.field(), c, fs.range(), StartLen(start, fs.size()));
        rst.emplace_back(alloc_slice);
    }
    return rst;
}

/// @returns updated AllocSlices with physical liveranges. NOTE: When allocating fields that
/// are parsed together and planed to be allocated in one container, they must all show up in
/// @p slices. In another words, when allocating a slice list, pass all AllocSlice to @p slices.
/// This is because physical liverange is tied with clot allocation, see field_slice_liverange
/// for more details.
/// NOTE: for fields that has uninitialized reads, those adjacent reads are merged into one
/// through LiveRangeInfo::merge_invalid_ranges.
std::vector<AllocSlice> update_alloc_slices_with_physical_liverange(
    const ClotInfo& clot,
    const FieldSliceLiveRangeDB& liverange_db,
    const CollectStridedHeaders& strided_headers,
    const std::vector<AllocSlice>& slices) {
    const bool deparsed_cannot_read_clot =
        std::any_of(slices.begin(), slices.end(), [&](const AllocSlice& slice) {
            const auto* f = slice.field();
            return f->deparsed() && (!clot.whole_field_clot(f) || clot.is_modified(f));
        });

    std::vector<AllocSlice> rst;
    for (auto& slice : slices) {
        LOG5("\tupdate_alloc_slices_with_physical_liverange for " << slice);
        const auto* info = liverange_db.get_liverange(FieldSlice(slice.field()));
        if (!info) {
            if (slice.field()->is_ignore_alloc()) {
                continue;  // skip dummy padding slices.
            }
            BUG("missing physical liverange info: %1%", slice);
        }

        const auto* field = slice.field();
        // overwrite live range to whole pipe when there is a deparsed and modified field
        // packed in this slice list.
        if (deparsed_cannot_read_clot && clot.allocated_unmodified_undigested(field)) {
            info = liverange_db.default_liverange();
        } else if (strided_headers.get_strided_group(field)) {
            // XXX(yumin): workaround for @donot_unroll pragma parser loop bug: defuse analysis
            // (control flow visitor) cannot handle parser loop correctly.
            info = liverange_db.default_liverange();
        }
        for (const auto& r : LiveRangeInfo::merge_invalid_ranges(info->disjoint_ranges())) {
            PHV::AllocSlice clone = slice;
            clone.setIsPhysicalStageBased(true);
            clone.setLiveness(r.start, r.end);
            LOG4("\t  creating liverange slice: " << clone);
            rst.emplace_back(clone);
        }
    }
    return rst;
}

/// @returns a map of start of field slices in @p sl, based on @p alignment.
FieldSliceAllocStartMap make_start_map(const SuperCluster* sc,
                                       const ScAllocAlignment& alignment,
                                       const SuperCluster::SliceList* sl) {
    FieldSliceAllocStartMap starts;
    for (const auto& fs : *sl) {
        starts[fs] = alignment.cluster_starts.at(&sc->aligned_cluster(fs));
    }
    return starts;
}

/// @returns true if have overlapped field slices.
bool has_overlapped_slice(const SuperCluster::SliceList* sl,
                          const std::vector<AllocSlice>* allocated) {
    for (const auto& fs : *sl) {
        for (const auto& alloc_sl : *allocated) {
            if (fs.field() == alloc_sl.field() && alloc_sl.field_slice().overlaps(fs.range())) {
                return true;
            }
        }
    }
    return false;
}

}  // namespace

void SomeContScopeAllocResult::collect(const ContScopeAllocResult& rst,
                                       const TxScore* score) {
    // 0: highest score overall.
    // 1: highest score of not packing with any other field slices.
    // 2: highest score of not packing with any other field slices and not introducing
    //    whole_container_set_only constraint. (i.e., not in mocha/dark container).
    const auto sat_level = [](const ContScopeAllocResult& r) {
        size_t level = 0;
        if (!r.is_packing) {
            level = 1;
            if (!r.cont_is_whole_container_set_only()) {
                level = 2;
            }
        }
        return level;
    };
    ContScopeAllocResult curr = rst;
    const TxScore* curr_score = score;
    for (size_t i = 0; i < 3; i++) {
        size_t curr_level = sat_level(curr);
        if (i > curr_level) {
            break;
        }
        if (i >= results.size()) {
            results.push_back(curr);
            scores.push_back(curr_score);
            break;
        } else if (curr_score->better_than(scores[i])) {
            std::swap(curr, results[i]);
            std::swap(curr_score, scores[i]);
        } else if (curr_level <= sat_level(results[i])) {
            // score is not better, and level is not deeper.
            break;
        }
    }

    // erase unnecessary results: more constraints, lower score.
    for (size_t i = 0; i < results.size(); i++) {
        if ((i == 0 && !results[i].cont_is_whole_container_set_only() && !results[i].is_packing) ||
            (i == 1 && !results[i].cont_is_whole_container_set_only())) {
            results.resize(i + 1);
            break;
        }
    }
}

Transaction AllocatorBase::make_speculated_alloc(const ScoreContext& ctx,
                                                 const Allocation& alloc,
                                                 const SuperCluster* sc,
                                                 const std::vector<AllocSlice>& candidates,
                                                 const Container& candidates_cont) const {
    BUG_CHECK(sc, "current allocating super cluster cannot be null");
    if (candidates.empty()) return alloc.makeTransaction();
    const auto gress = candidates.front().field()->gress;
    // returns true when the field slice has been allocated, or allocation is proposed.
    const auto is_allocated = [&](const FieldSlice fs) {
        const auto* f = fs.field();
        for (const auto& alloc_slice : alloc.getStatus(f)) {
            if (alloc_slice.field_slice() == fs.range()) {
                return true;
            }
        }
        for (const auto& alloc_slice : candidates) {
            if (f == alloc_slice.field() && alloc_slice.field_slice() == fs.range()) {
                return true;
            }
        }
        return false;
    };
    ordered_set<Container> empty_containers;
    const auto& phv_spec = Device::phvSpec();
    for (const auto &c : *ctx.cont_group()) {
        const int cid = phv_spec.containerToId(c);
        if (c.type().kind() != Kind::normal) continue;
        if ((gress == INGRESS && phv_spec.egressOnly()[cid]) ||
            (gress == EGRESS && phv_spec.ingressOnly()[cid])) {
            continue;
        }
        if (alloc.parserGroupGress(c) && *alloc.parserGroupGress(c) != gress) continue;
        if (alloc.deparserGroupGress(c) && *alloc.deparserGroupGress(c) != gress) continue;
        const auto EMPTY = Allocation::ContainerAllocStatus::EMPTY;
        const auto* container_status = alloc.getStatus(c);
        if (!container_status || container_status->alloc_status == EMPTY) {
            empty_containers.insert(c);
        }
    }
    empty_containers.erase(candidates_cont);

    bool pseudo_slice_added = false;
    std::stringstream ss;
    auto speculated_tx = alloc.makeTransaction();
    for (const auto* sl : sc->slice_lists()) {
        // skip allocated slice list. NOTE: do not just check the front() because
        // if the front() is ignore_alloc, duplicated allocation might be generated.
        if (std::any_of(sl->begin(), sl->end(),
                        [&](const FieldSlice& fs) { return is_allocated(fs); })) {
            continue;
        }
        // cannot find empty containers to safely generate pseudo allocation.
        if (empty_containers.empty()) return speculated_tx;
        // we can only guess allocation when
        // (1) There is only one possible starting position, because of the size
        //     of slice list and alignment.
        // (2) The slice list cannot be packed with any other fields, because of either the
        //     size or solitary constraint.
        const int total_bits = SuperCluster::slice_list_total_bits(*sl);
        const int alignment = sl->front().alignment() ? sl->front().alignment()->align : 0;
        if (total_bits < int(candidates_cont.size())) {
            // no bit-in-byte alignment constraint
            if (!sl->front().alignment()) continue;
            // with bit-in-byte but has multiple stating positions.
            if (alignment + total_bits + 8 <= int(candidates_cont.size())) continue;
            // one only one starting position is not enough, because this field might be packed
            // with other fields. When packing is necessary, speculated allocation will add
            // incorrect constraints, e.g., when allocating to 16-bit container,
            // slice lists:
            // [a<12> ^0]
            // [b<1>]
            // [c<3>]
            // [x<12>, y<1>, z<3>]
            // action: { x =a, y = b, z = c };
            // Assume that we have allocated {x, y, z} to H1, c to H2[0:2],
            // and we are allocating b<1> to H3[12], then if we guess that a<12>
            // will allocated to H4[0:11], then action solver will failed because there are 3
            // container sources (H2, H3, and H4). But it is false positive because actually
            // we can allocate a<12> to H3[0:11], i.e. packing with b<1> with only 2 sources.
            // That is, unless we explicitly know that there is not other field can be packed
            // with this slice list, we should not speculate its allocation.
            if (!sl->front().field()->is_solitary()) continue;
        }
        Container c = empty_containers.front();
        empty_containers.erase(c);
        // make pseudo allocation.
        std::vector<AllocSlice> speculated_alloc_slices;
        int offset = alignment;
        for (const auto& fs : *sl) {
            AllocSlice alloc_slice =
                AllocSlice(fs.field(), c, fs.range(), StartLen(offset, fs.size()));
            speculated_alloc_slices.emplace_back(alloc_slice);
            offset += fs.size();
        }
        if (kit_i.settings.physical_liverange_overlay) {
            speculated_alloc_slices = update_alloc_slices_with_physical_liverange(
                kit_i.clot, kit_i.physical_liverange_db, kit_i.strided_headers,
                speculated_alloc_slices);
        }
        pseudo_slice_added = true;
        for (const auto& alloc_slice : speculated_alloc_slices) {
            speculated_tx.allocate(alloc_slice);
            ss <<"\n" << ctx.t_tabs() << " pseudo allocate: " << alloc_slice;
        }
    }
    if (pseudo_slice_added) {
        LOG5(ctx.t_tabs() << "CanPack validation pseudo alloc:" << ss.str());
    }
    return speculated_tx;
}

const AllocError* AllocatorBase::verify_can_pack(const ScoreContext& ctx,
                                                 const Allocation& alloc,
                                                 const SuperCluster* sc,
                                                 const std::vector<AllocSlice>& candidates,
                                                 const Container& c,
                                                 ActionSourceCoPackMap& action_copack_hints) const {
    boost::optional<CanPackErrorV2> err;
    if (c.type().kind() == Kind::mocha || c.type().kind() == Kind::dark) {
        // materialize slice lists allocation into alloc when dark/mocha.
        // Materializing unallocated but fixed alignment slices will help
        // solver to check whole-container-set alignment constraints.
        const auto speculated_alloc = make_speculated_alloc(ctx, alloc, sc, candidates, c);
        err = kit_i.actions.can_pack_v2(speculated_alloc, candidates);
    } else {
        err = kit_i.actions.can_pack_v2(alloc, candidates);
    }
    if (!err->ok()) {
        std::stringstream ss;
        ss << err->code << ", " << err->msg;
        auto* alloc_err = new AllocError(ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED, ss.str());
        alloc_err->invalid_packing = err->invalid_dest_packing;
        return alloc_err;
    }

    //// recursivesly check conditional constraints, but do not need to commit them to tx.
    auto tx = alloc.makeTransaction();
    for (const auto& sl : candidates)
        tx.allocate(sl, nullptr, kit_i.settings.single_gress_parser_group);

    auto copack_hints = CoPacker(kit_i.source_tracker, sc, ctx.alloc_alignment())
                            .gen_copack_hints(tx, candidates, c);
    if (!copack_hints.ok()) {
        return copack_hints.err;
    }
    action_copack_hints = std::move(copack_hints.action_hints);
    return nullptr;
}

const AllocError* AllocatorBase::is_container_type_ok(const AllocSlice& sl,
                                                      const Container& c) const {
    auto* err = new AllocError(ErrorCode::CONTAINER_TYPE_MISMATCH);

    // pa_container_type pragma.
    auto required_kind = kit_i.pragmas.pa_container_type().required_kind(sl.field());
    if (required_kind && *required_kind != c.type().kind()) {
        *err << "unsat @pa_container_type: " << sl.field() << " must be " << *required_kind;
        return err;
    }
    // candidacy
    bool type_ok = true;
    switch (c.type().kind()) {
        case Kind::normal: {
            break;
        }
        case Kind::mocha: {
            type_ok = sl.field()->is_mocha_candidate();
            break;
        }
        case Kind::dark: {
            type_ok = sl.field()->is_dark_candidate();
            break;
        }
        case Kind::tagalong: {
            type_ok = sl.field()->is_tphv_candidate(kit_i.uses);
            break;
        }
    }
    if (!type_ok) {
        *err << sl.field()->name << " is not a candidate of " << c.type();
        return err;
    }
    return nullptr;
};

const AllocError* AllocatorBase::is_container_gress_ok(const Allocation& alloc,
                                                       const AllocSlice& sl,
                                                       const Container& c) const {
    auto* err = new AllocError(ErrorCode::CONTAINER_GRESS_MISMATCH);
    const auto gress = alloc.gress(c);
    if (gress && *gress != sl.field()->gress) {
        *err << "container is " << *gress << " but this field is not: " << sl.field()->name;
        return err;
    }
    // all containers within parser group must have same gress assignment
    const auto parser_group_gress = alloc.parserGroupGress(c);
    const bool is_extracted = kit_i.uses.is_extracted(sl.field());
    if (parser_group_gress && (is_extracted || kit_i.settings.single_gress_parser_group) &&
        (*parser_group_gress != sl.field()->gress)) {
        *err << c << " has parser group gress " << *parser_group_gress
             << " but the field is not: " << sl.field();
        return err;
    }
    // all containers within deparser group must have same gress assignment
    auto deparser_group_gress = alloc.deparserGroupGress(c);
    bool is_deparsed = kit_i.uses.is_deparsed(sl.field());
    if (deparser_group_gress && is_deparsed && *deparser_group_gress != sl.field()->gress) {
        *err << c << " has deparser group gress " << *deparser_group_gress << " but slice needs "
             << sl.field()->gress;
        return err;
    }

    // gress ok
    return nullptr;
}

const AllocError* AllocatorBase::is_container_write_mode_ok(const Allocation& alloc,
                                                            const AllocSlice& candidate,
                                                            const Container& c) const {
    auto* err = new AllocError(ErrorCode::CONTAINER_PARSER_WRITE_MODE_MISMATCH);
    const Field* f = candidate.field();
    const auto& field_to_states = kit_i.field_to_parser_states;
    const bool is_extracted = kit_i.uses.is_extracted(f);
    if (!is_extracted) {
        return nullptr;
    }

    // all containers within parser group must have same parser write mode
    boost::optional<IR::BFN::ParserWriteMode> write_mode;
    if (field_to_states.field_to_extracts.count(f)) {
        for (auto e : field_to_states.field_to_extracts.at(f)) {
            write_mode = e->write_mode;
        }
    }

    /// ignore deparser zero candidates if their extracts have been removed.
    if (f->is_deparser_zero_candidate() && !write_mode) {
        return nullptr;
    }

    BUG_CHECK(write_mode, "parser write mode not exist for extracted field %1%", f->name);

    // W0 is not allowed to be used with clear_on_write due to a hardware issue (P4C-4589).
    // W0 is a 32-bit container, and it will be the only container of its parser group,
    // so we do not need to check other containers of its parser group.
    bool w0_bug = Device::currentDevice() == Device::JBAY;
#if HAVE_CLOUDBREAK
    w0_bug |= Device::currentDevice() == Device::CLOUDBREAK;
#endif
    if (w0_bug && c == Container({PHV::Kind::normal, PHV::Size::b32}, 0) &&
        write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
        *err << "W0 must not be used in clear-on-write mode on either Tofino 2 or Tofino 3.";
        return err;
    }

    const PhvSpec& phv_spec = Device::phvSpec();
    for (unsigned other_id : phv_spec.parserGroup(phv_spec.containerToId(c))) {
        auto other = phv_spec.idToContainer(other_id);
        if (c == other) continue;

        const auto* cs = alloc.getStatus(other);
        if (!cs) continue;
        for (auto allocated : (*cs).slices) {
            if (!field_to_states.field_to_extracts.count(allocated.field())) continue;
            boost::optional<IR::BFN::ParserWriteMode> other_write_mode;
            for (auto e : field_to_states.field_to_extracts.at(allocated.field())) {
                other_write_mode = e->write_mode;
                // See P4C-3033 for more details
                // In tofino2, all extractions happen using 16b extracts.
                // So a 16-bit parser extractor extracts over a pair of even and
                // odd phv 8-bit containers to perform 8-bit extraction.
                // If any of 8 -bit containers in the pair are in CLEAR_ON_WRITE mode,
                // then both containers will be cleared everytime an extraction happens.
                // In order to avoid this corruption, if one container in the
                // pair in in CLEAR_ON_WRITE mode, the other is not used in parser.
                // NOTE: on JABY, parser groups of 8-bit containers are two adjacent even-odd
                // containers, while other containers are all in their own group.
                if (*other_write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                    *err << c << " has parser write mode " << int(*write_mode) << " but " << other
                         << " has conflicting parser write mode " << int(*other_write_mode);
                    return err;
                }
            }

            if (other_write_mode && *write_mode != *other_write_mode) {
                *err << c << " has parser write mode " << int(*write_mode) << " but " << other
                     << " has conflicting parser write mode " << int(*other_write_mode);
                return err;
            }
        }
    }
    return nullptr;
}

const AllocError* AllocatorBase::is_container_solitary_ok(const Allocation& alloc,
                                                          const AllocSlice& candidate,
                                                          const Container& c) const {
    // TODO(yumin): this is to allow allocating solitary fields that are NOT in one slice list.
    // This should not be necessary now with the new slicing iterator and also because
    // that we have eliminated the conditional constraints from action data.
    // We should try to remove this check before release.
    // true if @a is the same field allocated right before @b. e.g.
    // B1[0:1] <- f1[0:1], B1[2:7] <- f1[2:7]
    const auto is_aligned_same_field_alloc = [](AllocSlice a, AllocSlice b) {
        if (a.field() != b.field() || a.container() != b.container()) {
            return false;
        }
        if (a.container_slice().hi > b.container_slice().hi) {
            std::swap(a, b);
        }
        return b.field_slice().lo - a.field_slice().hi ==
               b.container_slice().lo - a.container_slice().hi;
    };
    const auto& allocated = alloc.liverange_overlapped_slices(c, {candidate});
    std::vector<FieldSlice> allocated_live;
    for (auto& sl : allocated) {
        // XXX(yumin): aligned fieldslice from the same field can be ignored
        if (is_aligned_same_field_alloc(candidate, sl) ||
            sl.field()->is_padding() || sl.field()->is_ignore_alloc()) {
            continue;
        }
        allocated_live.push_back(FieldSlice(sl.field(), sl.field_slice()));
    }

    auto* err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
    if (candidate.field()->is_solitary() && !allocated_live.empty()) {
        *err << "cannot allocate solitary field to container that "
               "already has other field allocated: "
             << candidate;
        return err;
    }
    for (auto& allocated_sl : allocated_live) {
        if (allocated_sl.field()->is_solitary()) {
            *err << "solitary field allocated already: " << allocated_sl;
            return err;
        }
    }
    return nullptr;
}

const AllocError* AllocatorBase::is_container_bytes_ok(
    const Allocation& alloc, const std::vector<AllocSlice>& candidates, const Container& c) const {
    // Check sum of constraints.
    ordered_set<const Field*> max_byte_limited;
    ordered_map<const Field*, int> bits_allocated_this_tx;
    for (auto& slice : candidates) {
        if (slice.field()->hasMaxContainerBytesConstraint()) max_byte_limited.insert(slice.field());
        bits_allocated_this_tx[slice.field()] += slice.width();
    }

    // If there are no fields that have the max container bytes constraints, then return true.
    if (max_byte_limited.size() == 0) return nullptr;

    for (const auto* f : max_byte_limited) {
        ordered_set<Container> containers{c};
        int allocated_bits = 0;
        for (auto& slice : alloc.slices(f)) {
            containers.insert(slice.container());
            allocated_bits += slice.width();
        }
        // TODO(yumin): not necessary?
        if (allocated_bits != f->size) allocated_bits += bits_allocated_this_tx.at(f);
        int unallocated_bits = f->size - allocated_bits;
        int container_bits = 0;
        for (auto& c : containers) {
            container_bits += static_cast<int>(c.size());
        }
        int containerBytes = (container_bits / 8) + ROUNDUP(unallocated_bits, 8);
        if (containerBytes > f->getMaxContainerBytes()) {
            auto* err = new AllocError(ErrorCode::FIELD_MAX_CONTAINER_BYTES_EXCEEDED);
            *err << "Violating max container bytes allowed for " << f->name
                 << ". max: " << f->getMaxContainerBytes()
                 << ", at least required: " << containerBytes;
            return err;
        }
    }
    return nullptr;
}

const AllocError* AllocatorBase::check_container_scope_constraints(
    const Allocation& alloc, const std::vector<AllocSlice>& candidates, const Container& c) const {
    // check parser packing.
    FieldSliceAllocStartMap fs_starts;
    for (const auto& slice : alloc.slices(c)) {
        if (slice.getEarliestLiveness().first != -1) continue;  // filter our non-parsed slice
        fs_starts[FieldSlice(slice.field(), slice.field_slice())] = slice.container_slice().lo;
    }
    for (const auto& slice : candidates) {
        if (slice.getEarliestLiveness().first != -1) continue;  // filter out non-parsed slice
        fs_starts[FieldSlice(slice.field(), slice.field_slice())] = slice.container_slice().lo;
    }
    if (auto* parser_packing_err = kit_i.parser_packing_validator->can_pack(fs_starts, c)) {
        return parser_packing_err;
    }
    // check every candidate slice against allocated.
    for (const auto& sl : candidates) {
        // Check container type constraint.
        if (auto* err = is_container_type_ok(sl, c)) {
            return err;
        }
        // Check gress related constraints.
        if (auto* err = is_container_gress_ok(alloc, sl, c)) {
            return err;
        }
        // Check solitary constraint for candidates and allocated fields.
        if (auto* err = is_container_solitary_ok(alloc, sl, c)) {
            return err;
        }
        // Check container group write mode constraints.
        if (auto* err = is_container_write_mode_ok(alloc, sl, c)) {
            return err;
        }
    }
    // Check max container bytes constraint.
    if (auto* err = is_container_bytes_ok(alloc, candidates, c)) {
        return err;
    }
    return nullptr;
}

ContScopeAllocResult AllocatorBase::try_slices_to_container(
    const ScoreContext& ctx, const Allocation& alloc, const FieldSliceAllocStartMap& fs_starts,
    const Container& c, const bool skip_mau_checks) const {
    auto candidates = make_alloc_slices(kit_i.uses, fs_starts, c);
    if (kit_i.settings.physical_liverange_overlay) {
        candidates = update_alloc_slices_with_physical_liverange(
            kit_i.clot, kit_i.physical_liverange_db, kit_i.strided_headers, candidates);
    }
    LOG4(ctx.t_tabs() << "@" << c);
    if (LOGGING(5)) {
        LOG5(ctx.t_tabs() << "AllocSlices:");
        for (const auto& slice : candidates) {
            LOG5(ctx.t_tabs() << " " << slice);
        }
    }

    // check overlay
    LOG4(ctx.t_tabs() << "Overlay status:");
    for (const auto& slice : candidates) {
        const auto& overlapped = alloc.slices(slice.container(), slice.container_slice());
        const cstring short_name =
            slice.field()->name + " " + cstring::to_cstring(slice.field_slice());
        if (overlapped.empty()) {
            LOG4(ctx.t_tabs() << " " << short_name << ": "
                              << "no overlapped slices.");
        } else if (can_control_flow_overlay(kit_i.mutex(), slice.field(), overlapped)) {
            LOG4(ctx.t_tabs() << short_name << ": " << "control flow overlaid.");
        } else if (kit_i.settings.physical_liverange_overlay &&
                   can_physical_liverange_overlay(kit_i, slice, overlapped)) {
            LOG4(ctx.t_tabs() << short_name << ": "
                              << "physical liverange overlaid.");
        } else {
            auto err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
            *err << "overlapped with allocated slices";
            // detailed error message only for high log level.
            if (LOGGING(6)) {
                *err << ": " << short_name << " is overlapped with: " << overlapped.front();
            }
            return ContScopeAllocResult(err);
        }
    }

    // check misc container-scope constraints.
    if (const auto* err = check_container_scope_constraints(alloc, candidates, c)) {
        return ContScopeAllocResult(err);
    }

    // check all kinds of action phv constraints.
    ActionSourceCoPackMap action_copack_hints;
    if (!skip_mau_checks) {
        if (const auto* err =
                verify_can_pack(ctx, alloc, ctx.sc(), candidates, c, action_copack_hints)) {
            return ContScopeAllocResult(err);
        }
    }

    // save allocation to result transaction.
    auto tx = alloc.makeTransaction();
    for (auto& slice : candidates) {
        tx.allocate(slice, nullptr, kit_i.settings.single_gress_parser_group);
    }

    const bool packed_with_existing = !alloc.liverange_overlapped_slices(c, candidates).empty();
    return ContScopeAllocResult(tx, action_copack_hints, c, packed_with_existing);
}

SomeContScopeAllocResult AllocatorBase::try_slices_to_container_group(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const FieldSliceAllocStartMap& fs_starts,
    const ContainerGroup& group) const {
    const auto new_ctx = ctx.with_t(ctx.t() + 1);
    /// pretty-print error messages that aggregates the same failures.
    boost::optional<cstring> last_err_str = boost::none;
    std::vector<Container> same_err_conts;
    const auto flush_aggregated_errs = [&]() {
        if (last_err_str) {
            std::stringstream ss;
            ss << "Try container";
            for (const auto& c : same_err_conts) {
                ss << " " << c;
            }
            LOG3(ctx.t_tabs() << ss.str());
            LOG3(new_ctx.t_tabs() << "Failed, " << *last_err_str);
        }
        last_err_str = boost::none;
        same_err_conts.clear();
    };
    const auto pretty_print_errs = [&](const Container& c, const ContScopeAllocResult& r) {
        if (r.ok()) {
            flush_aggregated_errs();
        } else {
            cstring err_str = r.err_str();
            if (last_err_str && *last_err_str != err_str) {
                flush_aggregated_errs();
            }
            last_err_str = err_str;
            same_err_conts.push_back(c);
        }
    };

    // try all containers.
    SomeContScopeAllocResult some(
        new AllocError(ErrorCode::NOT_ENOUGH_SPACE, "no container have enough space"));
    for (const Container& c : group) {
        auto c_rst = try_slices_to_container(new_ctx, alloc, fs_starts, c);
        pretty_print_errs(c, c_rst);
        if (c_rst.ok()) {
            // pick this container if higher score.
            const auto* c_rst_score = ctx.score()->make(*c_rst.tx);
            LOG3(ctx.t_tabs() << "Try container " << c);
            LOG3(new_ctx.t_tabs() << "Succeeded, score: " << c_rst_score->str());
            some.collect(c_rst, c_rst_score);
            // XXX(yumin): we do not use is_packing in c_rst because only strict empty is allowed,
            // for this container-level search optimization parameter.
            if (ctx.search_config()->stop_first_succ_empty_normal_container) {
                const auto container_status = alloc.getStatus(c);
                if (c.type().kind() == PHV::Kind::normal &&
                    (!container_status || container_status->slices.empty())) {
                    LOG3(new_ctx.t_tabs()
                         << "Stop early because first_succ_empty_normal_container.");
                    break;
                }
            }
        } else {
            // prefer to return the most informative error message.
            if (c_rst.err->code == ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED) {
                some.err = c_rst.err;
            } else if (some.err->code != ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED &&
                       c_rst.err->code == ErrorCode::CONTAINER_PARSER_PACKING_INVALID) {
                some.err = c_rst.err;
            }
        }
    }
    flush_aggregated_errs();
    return some;
}

SomeContScopeAllocResult AllocatorBase::try_slices_adapter(const ScoreContext& ctx,
                                                           const Allocation& alloc,
                                                           const FieldSliceAllocStartMap& fs_starts,
                                                           const ContainerGroup& group,
                                                           boost::optional<Container> c) const {
    if (c) {
        auto rst = try_slices_to_container(ctx, alloc, fs_starts, *c);
        if (rst.ok()) {
            auto score = ctx.score()->make(*rst.tx);
            return SomeContScopeAllocResult(rst, score);
        } else {
            return SomeContScopeAllocResult(rst.err);
        }
    } else {
        return try_slices_to_container_group(ctx, alloc, fs_starts, group);
    }
}

boost::optional<Transaction> AllocatorBase::try_hints(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const ContainerGroup& group,
    const ActionSourceCoPackMap& action_hints_map,
    ordered_set<PHV::FieldSlice>& allocated,
    ScAllocAlignment& hint_enforced_alignments) const {
    auto tx = alloc.makeTransaction();
    // try hints for every action.
    for (const auto& action_hints : action_hints_map) {
        const auto* act = action_hints.first;
        const auto& hints = action_hints.second;
        const bool required = hints.size() == 1 && hints.front()->required;
        LOG3(ctx.t_tabs() << "> trying to allocate by hints for " << act->externalName()
                          << (required ? " (required)" : ""));
        // for all mutex hints of this action, try until we find an allocation.
        for (const auto* hint : hints) {
            LOG3(ctx.t_tabs() << "> trying hints: " << hint);
            auto hint_tx = tx.makeTransaction();
            bool hint_ok = true;
            bool hint_empty = true;
            for (const auto& src_pack : hint->pack_sources) {
                LOG3(ctx.t_tabs() << " try SrcPackVec: " << src_pack);
                // remove allocated.
                FieldSliceAllocStartMap fs_starts;
                for (const auto& kv : src_pack->fs_starts) {
                    if (allocated.count(kv.first)) continue;
                    fs_starts[kv.first] = kv.second;
                }
                if (fs_starts.empty()) {
                    LOG3(ctx.t_tabs() << "skip this SrcPackVec because all have been allocated");
                    continue;
                }
                hint_empty = false;
                // XXX(yumin): we trust that copacker will respect ScAllocAlignment.
                auto src_pack_rst = try_slices_adapter(
                        ctx.with_t(ctx.t() + 1), hint_tx, fs_starts,
                        group, src_pack->container);
                if (src_pack_rst.ok()) {
                    hint_tx.commit(*src_pack_rst.front().tx);
                } else {
                    LOG3("Failed to allocate by hints.");
                    hint_ok = false;
                    if (required) {
                        return boost::none;
                    } else {
                        break;
                    }
                }
            }
            if (!hint_ok || hint_empty) continue;
            /// we found one hint allocated, commit and break.
            for (const auto& src_pack : hint->pack_sources) {
                for (const auto& fs_idx : src_pack->fs_starts) {
                    const auto& fs = fs_idx.first;
                    const int idx = fs_idx.second;
                    allocated.insert(fs);
                    const auto& aligned = ctx.sc()->aligned_cluster(fs);
                    BUG_CHECK(
                        !hint_enforced_alignments.cluster_starts.count(&aligned) ||
                            hint_enforced_alignments.cluster_starts.at(&aligned) == idx,
                        "copacker returned an invalid alignment");
                    hint_enforced_alignments.cluster_starts[&aligned] = idx;
                }
            }
            tx.commit(hint_tx);
            break;
        }
    }
    return tx;
}

AllocResult AllocatorBase::try_wide_arith_slices_to_container_group(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const ScAllocAlignment& alignment,
    const SuperCluster::SliceList* lo,
    const SuperCluster::SliceList* hi,
    const ContainerGroup& group) const {
    const TxScore* rst_score = nullptr;
    boost::optional<AllocResult> rst;
    const auto lo_starts = make_start_map(ctx.sc(), alignment, lo);
    const auto hi_starts = make_start_map(ctx.sc(), alignment, hi);
    for (auto itr = group.begin(); itr != group.end(); ++itr) {
        if (std::next(itr) == group.end()) continue;
        const auto lo_cont = *itr;
        const auto hi_cont = *(std::next(itr));
        if (!(lo_cont.index() % 2 == 0)) continue;  // arith lo in even container
        if (!(hi_cont.index() % 2 != 0)) continue;  // arith hi in  odd container

        auto tx = alloc.makeTransaction();
        LOG3(ctx.t_tabs() << "TryAlloc wide_arith lo slice list " << lo << " to " << lo_cont);
        auto lo_alloc = try_slices_to_container(ctx, tx, lo_starts, lo_cont);
        if (!lo_alloc.ok()) {
            LOG3(ctx.t_tabs() << "Failed because " << lo_alloc.err_str() );
            continue;
        }
        tx.commit(*lo_alloc.tx);
        LOG3(ctx.t_tabs() << "TryAlloc wide_arith hi slice list " << hi << " to " << hi_cont);
        auto hi_alloc = try_slices_to_container(ctx, tx, hi_starts, hi_cont);
        if (!hi_alloc.ok()) {
            LOG3(ctx.t_tabs() << "Failed because " << hi_alloc.err_str() );
            continue;
        }
        tx.commit(*hi_alloc.tx);

        // pick this pair of container if higher score.
        // XXX(yumin): we ignore copack hints for wide_arith slices.
        const auto* tx_score = ctx.score()->make(tx);
        if (!rst || tx_score->better_than(rst_score)) {
            LOG3(ctx.t_tabs() << "Container pair " << lo_cont << " and " << hi_cont
                              << " now has the highest score");
            rst = AllocResult(std::move(tx));
            rst_score = tx_score;
        }
    }
    if (!rst) {
        return AllocResult(new AllocError(ErrorCode::WIDE_ARITH_ALLOC_FAILED));
    }
    return *rst;
}
AllocatorBase::DfsState AllocatorBase::DfsState::next_state(
    const ScAllocAlignment& updated_alignment,
    const ordered_set<const SuperCluster::SliceList*>& just_allocated) const {
    auto updated_allocated = allocated;
    std::vector<const SuperCluster::SliceList*> updated_to_allocate;
    for (const auto& sl : to_allocate) {
        if (just_allocated.count(sl)) {
            updated_allocated.push_back(sl);
        } else {
            updated_to_allocate.push_back(sl);
        }
    }
    return DfsState(updated_alignment, updated_allocated, updated_to_allocate);
}

std::string AllocatorBase::DfsListsAllocator::depth_prefix(const int depth) const {
    std::stringstream prefix_ss;
    prefix_ss << ">> @Depth-" << depth << ": ";
    return prefix_ss.str();
}

boost::optional<ScAllocAlignment> AllocatorBase::DfsListsAllocator::new_alignment_with_start(
    const ScoreContext& ctx, const SuperCluster::SliceList* target, const int sl_start,
    const PHV::Size& width, const ScAllocAlignment& alignment) const {
    auto this_start_alignment = alignment;
    int offset = sl_start;
    for (const auto& fs : *target) {
        // if the slice 's cluster cannot be placed at the current offset.
        if (!ctx.sc()->aligned_cluster(fs).validContainerStart(width).getbit(offset)) {
            return boost::none;
        }
        if (this_start_alignment.ok(&ctx.sc()->aligned_cluster(fs), offset)) {
            this_start_alignment.cluster_starts[&ctx.sc()->aligned_cluster(fs)] = offset;
        } else {
            return boost::none;
        }
        offset += fs.size();
    }
    return this_start_alignment;
}

bool AllocatorBase::DfsListsAllocator::allocate(const ScoreContext& ctx,
                                                const Transaction& tx,
                                                const DfsState& state,
                                                const int depth) {
    cstring log_prefix = ctx.t_tabs() + depth_prefix(depth);
    if (state.done()) {
        // all items have been allocated.
        LOG3(log_prefix << "ALL slice lists have been allocated.");
        caller_pruned = !yield(tx);
        return true;  // returns true when we have found a solution on this path.
    }

    n_steps++;
    const auto* sl = state.next_to_allocate();
    LOG3(log_prefix << "Start to allocate target: " << sl);

    // find the the best container start index for this slice list.
    AllocError* no_alignment_err = new AllocError(ErrorCode::NO_VALID_SC_ALLOC_ALIGNMENT);
    *no_alignment_err << "Cannot find any valid alignment, when allocating " << sl;
    const auto* last_err = no_alignment_err;
    bool found_solution = false;
    bool sl_and_required_hints_can_be_allocated = false;
    const PHV::Size width = ctx.cont_group()->width();
    // all slice lists that have ever been marked as part of the invalid packing.
    auto* invalid_action_lists = new ordered_set<const SuperCluster::SliceList*>();
    const auto ordered_valid_starts = base.make_start_positions(ctx, sl, width);
    for (const int sl_start : ordered_valid_starts) {
        if (pruned()) break;
        auto this_start_alignment =
            new_alignment_with_start(ctx, sl, sl_start, width, state.alignment);
        if (!this_start_alignment) continue;
        const auto new_state = state.next_state(*this_start_alignment, {sl});
        // we have found a valid alignment, try to allocate sl by it.
        FieldSliceAllocStartMap to_be_allocated =
            make_start_map(ctx.sc(), *this_start_alignment, sl);
        LOG3(log_prefix << "Try to allocate slice list starts @ " << sl_start
                        << ", layout: " << to_be_allocated);
        const auto this_start_ctx =
            ctx.with_t(ctx.t() + 1).with_alloc_alignment(&(*this_start_alignment));
        auto some_sl_alloc_rst = base.try_slices_to_container_group(
                this_start_ctx, tx, to_be_allocated, *ctx.cont_group());
        if (!some_sl_alloc_rst.ok()) {
            // failed, save important errors and try other alignments.
            LOG3(log_prefix << "slice list starts @ " << sl_start << " failed, because "
                            << some_sl_alloc_rst.err->str());
            auto* err = new AllocError(*some_sl_alloc_rst.err);
            *err << "\nWhen trying to allocate in these field slices in this layout "
                    "(container_index:field_slice): " << to_be_allocated;
            last_err = err;
            if (err->code == ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED && err->invalid_packing) {
                for (const auto* allocated_sl : new_state.allocated) {
                    if (has_overlapped_slice(allocated_sl, err->invalid_packing)) {
                        invalid_action_lists->insert(allocated_sl);
                    }
                }
            }
            continue;
        }
        if (LOGGING(3)) {
            LOG3(log_prefix << "# of some results: " << some_sl_alloc_rst.size());
            for (const auto& r : some_sl_alloc_rst.results) {
                LOG3(log_prefix << r.c);
            }
        }
        LOG3(log_prefix << "slice list starts @ " << sl_start << " succeeded.");
        // try to search deeper with every one of Some result.
        for (const auto& sl_alloc_rst : some_sl_alloc_rst.results) {
            if (pruned()) break;
            LOG3(log_prefix << "try search deeper with: " << sl_alloc_rst.c);
            Transaction this_choice = tx;
            for (const auto& kv : sl_alloc_rst.tx->get_actual_diff()) {
                for (const auto& alloc_slice : kv.second.slices) {
                    this_choice.allocate(alloc_slice);
                }
            }
            if (sl_alloc_rst.action_hints.empty()) {
                sl_and_required_hints_can_be_allocated = true;
                found_solution |= allocate(ctx, this_choice, new_state, depth + 1);
                continue;
            }

            // split by required and optional hints.
            ActionSourceCoPackMap required_hints;
            ActionSourceCoPackMap optional_hints;
            for (const auto& action_hints : sl_alloc_rst.action_hints) {
                const auto* act = action_hints.first;
                const auto& hints = action_hints.second;
                const bool required = hints.size() == 1 && hints.front()->required;
                if (required) {
                    required_hints[act] = hints;
                } else {
                    optional_hints[act] = hints;
                }
            }
            if (!required_hints.empty())
                LOG3(log_prefix << "Required CoPack hint(s):" << required_hints);
            if (!optional_hints.empty())
                LOG3(log_prefix << "Optional CoPack hint(s) found:" << optional_hints);

            /// When a hint is allocated, the alignment is then fixed for all the slice
            /// in the aligned cluster, so we clone a mutable updated_alignment.
            ScAllocAlignment hint_updated_alignment = *this_start_alignment;
            ordered_set<PHV::FieldSlice> allocated_fs;
            for (const auto* sl : new_state.allocated) {
                for (const auto& fs : *sl) {
                    allocated_fs.insert(fs);
                }
            }

            // try required hints, skip this choice if failed.
            auto required_hints_applied_tx = base.try_hints(
                    this_start_ctx, this_choice, *ctx.cont_group(),
                    required_hints, allocated_fs, hint_updated_alignment);
            if (!required_hints_applied_tx) {
                LOG3(log_prefix << "cannot search deeper with: " << sl_alloc_rst.c
                                << " because required copack failed");
                auto* copack_err = new AllocError(ErrorCode::CANNOT_APPLY_REQUIRED_COPACK_HINTS);
                *copack_err << "If we pack " << to_be_allocated << " into " << sl_alloc_rst.c
                            << ", required hints: " << required_hints << " cannot be applied.";
                last_err = copack_err;
                continue;
            }
            this_choice.commit(*required_hints_applied_tx);

            // apply optional hints for higher chance of successful allocation.
            // TODO(yumin): we might consider to provide an option to try without copack hints.
            auto optional_hints_applied_tx = base.try_hints(
                    this_start_ctx, this_choice, *ctx.cont_group(),
                    optional_hints, allocated_fs, hint_updated_alignment);
            BUG_CHECK(optional_hints_applied_tx, "optional hints shall not fail.");
            this_choice.commit(*optional_hints_applied_tx);

            // recursion
            ordered_set<const SuperCluster::SliceList*> just_allocated;
            for (const auto& sl : new_state.to_allocate) {
                if (allocated_fs.count(sl->front())) {
                    just_allocated.insert(sl);
                    continue;
                }
            }
            DfsState hint_updated_state =
                new_state.next_state(hint_updated_alignment, just_allocated);
            sl_and_required_hints_can_be_allocated = true;
            found_solution |= allocate(ctx, this_choice, hint_updated_state, depth + 1);
        }
    }
    if (!sl_and_required_hints_can_be_allocated) {
        LOG3(log_prefix << "Cannot allocate " << sl);
        // prepare error messages.
        auto* err = new AllocError(*last_err);
        if (!invalid_action_lists->empty()) {
            invalid_action_lists->insert(sl);
            err->reslice_required = invalid_action_lists;
        }
        if (depth > deepest_depth) {
            LOG3(log_prefix << "Current Tx status:");
            LOG3(AllocResult::pretty_print_tx(tx, log_prefix));
            *err << ";\nWhen some slices have been allocated:\n";
            *err << AllocResult::pretty_print_tx(tx, "\t");
            deepest_err = err;
            deepest_depth = depth;
        }
    }
    return found_solution;
}

bool AllocatorBase::DfsListsAllocator::search_allocate(
    const ScoreContext& ctx,
    const Transaction& tx,
    const ScAllocAlignment& alignment,
    const std::vector<const SuperCluster::SliceList*>& allocated,
    const std::vector<const SuperCluster::SliceList*>& to_allocate,
    const DfsAllocCb& yield_cb) {
    yield = yield_cb;
    DfsState state(alignment, allocated, to_allocate);
    return allocate(ctx, tx, state, 0);
}

AllocResult AllocatorBase::try_super_cluster_to_container_group(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const SuperCluster* sc,
    const ContainerGroup& group) const {
    // Make a new transaction.
    PHV::Transaction sc_tx = alloc.makeTransaction();
    ScAllocAlignment curr_alignment;
    auto new_ctx = ctx.with_t(ctx.t() + 1);

    // always try to allocate wide_arithmetic slice lists first.
    ordered_set<const SuperCluster::SliceList*> wide_arith_lists;
    for (const auto* lo_sl : *ctx.alloc_order()) {
        const PHV::SuperCluster::SliceList *hi_sl = nullptr;
        for (const auto& slice : *lo_sl) {
            // find lo part of wide_arithmetic slice lists.
            if (!slice.field()->bit_used_in_wide_arith(slice.range().lo)) {
                continue;
            }
            if (!slice.field()->bit_is_wide_arith_lo(slice.range().lo)) {
                continue;
            }
            hi_sl = sc->findLinkedWideArithSliceList(lo_sl);
            break;
        }
        if (!hi_sl) continue;

        // Track alignment of wide arithmetic field slices.
        for (const auto* sl : {lo_sl, hi_sl}) {
            int offset = sl->front().alignment() ? sl->front().alignment()->align : 0;
            for (const auto& fs : *sl) {
                curr_alignment.cluster_starts[&sc->aligned_cluster(fs)] = offset;
                offset += fs.size();
            }
        }
        static const cstring prefix = "> trying to allocate wide_arith slice list:";
        LOG3(ctx.t_tabs() <<  prefix << "START to allocate the pair: " << lo_sl << ", " << hi_sl);
        auto sl_alloc_rst =
            try_wide_arith_slices_to_container_group(
                    new_ctx.with_alloc_alignment(&curr_alignment),
                    sc_tx, curr_alignment, lo_sl, hi_sl, group);
        if (!sl_alloc_rst.ok()) {
            LOG3(ctx.t_tabs() << prefix << "FAILED, because " << sl_alloc_rst.err_str());
            return sl_alloc_rst;
        }
        LOG3(ctx.t_tabs() << prefix << "SUCCEEDED, result:\n"
             << sl_alloc_rst.tx_str(ctx.t_tabs() + " "));
        sc_tx.commit(*sl_alloc_rst.tx);

        // Track allocated slices in order to skip them when allocating their clusters.
        wide_arith_lists.insert(lo_sl);
        wide_arith_lists.insert(hi_sl);
    }

    // allocate non-wide-arithmetic slices.
    std::vector<const SuperCluster::SliceList*> allocated;
    std::vector<const SuperCluster::SliceList*> to_allocate;
    for (const auto* sl : *ctx.alloc_order()) {
        if (wide_arith_lists.count(sl)) {
            allocated.push_back(sl);
            continue;
        }
        to_allocate.push_back(sl);
    }
    boost::optional<Transaction> best_tx;
    const TxScore* best_score = nullptr;
    DfsListsAllocator dfs_alloc(*this, ctx.search_config()->n_dfs_steps_sc_alloc);
    int n_found = 0;
    auto cb = [&](const Transaction& new_tx) {
        auto score = ctx.score()->make(new_tx);
        LOG3(ctx.t_tabs() << "New Allocation for SC-" << sc->uid << " found:\n"
             << AllocResult(new_tx).tx_str(ctx.t_tabs() + " "));
        LOG3(ctx.t_tabs() << "Score: " << score->str());
        if (!best_score || score->better_than(best_score)) {
            LOG3(ctx.t_tabs() << "which is the best of this container group so far.");
            best_score = score;
            best_tx = new_tx;
        }
        ++n_found;
        return n_found < ctx.search_config()->n_best_of_sc_alloc;
    };
    dfs_alloc.search_allocate(
            ctx, sc_tx.makeTransaction(), curr_alignment, allocated, to_allocate, cb);
    if (best_tx) {
        sc_tx.commit(*best_tx);
        return AllocResult(sc_tx);
    } else {
        return AllocResult(dfs_alloc.get_deepest_err());
    }
}

std::vector<int> AllocatorBase::make_start_positions(const ScoreContext& ctx,
                                                     const SuperCluster::SliceList* sl,
                                                     const PHV::Size width) const {
    auto valid_starts_bv = ctx.sc()->aligned_cluster(sl->front()).validContainerStart(width);
    std::vector<int> ordered_valid_starts;
    for (const int i : valid_starts_bv) {
        ordered_valid_starts.push_back(i);
    }
    if (ctx.search_config()->try_byte_aligned_starts_first_for_table_keys) {
        // find the first match key field.
        int offset = 0;
        bitvec ixbar_read;
        for (const auto& fs : *sl) {
            if (!kit_i.uses.ixbar_read(fs.field(), fs.range()).empty()) {
                ixbar_read.setrange(offset, fs.size());
            }
            offset += fs.size();
        }
        if (!ixbar_read.empty()) {
            // for every valid start, check how many bytes it might use.
            std::unordered_map<int, int> start_n_bytes;
            for (const int start : ordered_valid_starts) {
                std::unordered_set<int> bytes;
                for (const int read_bit : ixbar_read) {
                    bytes.insert((start + read_bit) / 8);
                }
                start_n_bytes[start] = bytes.size();
            }
            // sort by less ixbar byte usage and then by index.
            std::sort(ordered_valid_starts.begin(), ordered_valid_starts.end(), [&](int a, int b) {
                if (start_n_bytes[a] != start_n_bytes[b]) {
                    return start_n_bytes[a] < start_n_bytes[b];
                }
                return a < b;
            });
        }
    }
    // rest of starts.
    return ordered_valid_starts;
}

std::set<PHV::Size> AllocatorBase::compute_valid_container_sizes(const SuperCluster* sc) const {
    static const std::map<int, PHV::Size> width_to_size {
        {8, Size::b8},
        {16, Size::b16},
        {32, Size::b32},
    };
    std::set<PHV::Size> ok_sizes{Size::b8, Size::b16, Size::b32};
    const auto remove_smaller_than = [&ok_sizes](int width) {
        for (auto itr = ok_sizes.begin(); itr != ok_sizes.end();) {
            if (int(*itr) < width) {
                itr = ok_sizes.erase(itr);
            } else {
                break;
            }
        }
    };
    const auto remove_if_not = [&ok_sizes](PHV::Size width) {
        if (ok_sizes.count(width)) {
            ok_sizes = {width};
        } else {
            // conflict found.
            ok_sizes.clear();
        }
    };
    // apply pa_container_size constraints
    const auto& pa_sz = kit_i.pragmas.pa_container_sizes();
    sc->forall_fieldslices([&](const FieldSlice& fs) {
        if (auto req = pa_sz.expected_container_size(fs)) {
            remove_if_not(*req);
        }
    });
    if (ok_sizes.empty()) {
        return ok_sizes;
    }

    // apply field slice width constraints.
    int max_fs_width = 0;
    sc->forall_fieldslices(
        [&](const FieldSlice& fs) { max_fs_width = std::max(max_fs_width, fs.size()); });
    remove_smaller_than(max_fs_width);
    if (ok_sizes.empty()) {
        return ok_sizes;
    }

    // apply slice list width constraints.
    int max_sl_width = 0;
    for (const auto* sl : sc->slice_lists()) {
        // compute max slicelist width
        const auto& head = sl->front();
        int offset = head.alignment() ? (*head.alignment()).align : 0;
        for (const auto& fs : *sl) {
            offset += fs.size();
        }
        max_sl_width = std::max(max_sl_width, offset);
        if (sl->front().field()->exact_containers()) {
            BUG_CHECK(width_to_size.count(offset),
                      "non-container-sized slice list should be filtered earlier: %1%, %2%", sl,
                      offset);
            remove_if_not(width_to_size.at(offset));
        }
    }
    remove_smaller_than(max_sl_width);

    return ok_sizes;
}

std::vector<const SuperCluster::SliceList*>* AllocatorBase::make_alloc_order(
    const ScoreContext& ctx, const SuperCluster* sc, const PHV::Size width) const {
    auto* alloc_order = new std::vector<const SuperCluster::SliceList*>();
    ordered_set<FieldSlice> in_list_slices;
    for (const auto* sl : sc->slice_lists()) {
        alloc_order->push_back(sl);
        for (const auto& fs : *sl) {
            in_list_slices.insert(fs);
        }
    }
    for (const auto& fs : sc->slices()) {
        if (!in_list_slices.count(fs)) {
            alloc_order->push_back(new SuperCluster::SliceList{fs});
        }
    }
    kit_i.actions.dest_first_sort(*alloc_order);

    ordered_set<const SuperCluster::SliceList*> is_alignment_fixed;
    for (const auto* sl : *alloc_order) {
        // fixed because of constraints
        const auto& head = sl->front();
        if (head.field()->exact_containers() || head.field()->deparsed_bottom_bits()) {
            is_alignment_fixed.insert(sl);
            continue;
        }

        // fixed because of size.
        const int total_bits = SuperCluster::slice_list_total_bits(*sl);
        const int alignment = sl->front().alignment() ? sl->front().alignment()->align : 0;
        // with bit-in-byte alignment constraint and it limits the choice of starting position.
        if (total_bits == int(width) ||
            (sl->front().alignment() && alignment + total_bits + 8 > int(width))) {
            is_alignment_fixed.insert(sl);
        }
    }

    // sort again
    std::stable_sort(alloc_order->begin(), alloc_order->end(),
                     [&](const SuperCluster::SliceList* a, const SuperCluster::SliceList* b) {
                         if (is_alignment_fixed.count(a) != is_alignment_fixed.count(b)) {
                             return is_alignment_fixed.count(a) > is_alignment_fixed.count(b);
                         }
                         return false;
                     });

    if (LOGGING(4)) {
        LOG4(ctx.t_tabs() << "Sorted slice list allocation order: ");
        for (const auto* sl : *alloc_order) {
            LOG4(ctx.t_tabs() << sl);
        }
    }
    return alloc_order;
}

AllocResult AllocatorBase::try_sliced_super_cluster(const ScoreContext& ctx,
                                                    const Allocation& alloc,
                                                    const SuperCluster* sc,
                                                    const ContainerGroupsBySize& groups) const {
    // defensive check on @p sc. We can remove this for performance if necessary,
    // because all super clusters produced by slicing iterator are well-formed.
    {
        PHV::Error err;
        BUG_CHECK(SuperCluster::is_well_formed(sc, &err),
                  "Only well-formed super cluster can be allocated, but %1% is not, because %2%",
                  sc, err.str());
    }

    LOG3(ctx.t_tabs() << "Trying to allocate super cluster Uid: " << sc->uid);

    const auto ok_sizes = compute_valid_container_sizes(sc);
    if (ok_sizes.empty()) {
        return AllocResult(new AllocError(ErrorCode::NO_VALID_CONTAINER_SIZE));
    }

    const bool not_all_tphv_candidates = sc->any_of_fieldslices(
        [&](const FieldSlice& fs) { return !fs.field()->is_tphv_candidate(kit_i.uses); });
    const TxScore* rst_score = nullptr;
    boost::optional<AllocResult> rst;  // save the last succeed transaction only.
    // slice lists that allocator has returned an error of cannot_pack.
    // stores only critical error message that might help caller to better slice the cluster.
    auto* reslice_required = new ordered_set<const SuperCluster::SliceList*>();
    cstring reslice_required_reason = "";
    boost::optional<const AllocError*> other_err =
        boost::make_optional(false, (const AllocError*)nullptr);
    bool has_any_valid_alignment = false;
    // find the best score, forall (container group) of @p sc.
    for (const PHV::Size& sz : ok_sizes) {
        // Attach the sorted slice list order to context. This is the order of allocation
        // for all field slices in this cluster.
        auto* alloc_order = make_alloc_order(ctx, sc, sz);
        const auto new_ctx = ctx.with_sc(sc).with_alloc_order(alloc_order).with_t(ctx.t() + 1);
        LOG3(new_ctx.t_tabs() << "Trying to allocate SC-" << sc->uid << " to " << sz
                              << " container groups");
        // pre-screening for alignment issue.
        if (make_sc_alloc_alignment(sc, sz, 1).empty()) {
            LOG3(new_ctx.t_tabs() << "No alignment found, skip this size of containers: " << sz);
            continue;
        }
        has_any_valid_alignment = true;
        for (const auto& group : groups.at(sz)) {
            const auto grp_ctx = new_ctx.with_t(new_ctx.t() + 1).with_cont_group(&group);
            // if this is a pure TPHV group but not all fields are TPHV-compatible, skip.
            if (Device::currentDevice() == Device::TOFINO && !group.is(Kind::normal) &&
                not_all_tphv_candidates) {
                LOG3(grp_ctx.t_tabs() << "Skip TPHV group: " << group);
                continue;
            }
            LOG3(grp_ctx.t_tabs() << "Try container group: " << group);
            auto group_rst =
                try_super_cluster_to_container_group(
                        grp_ctx.with_t(grp_ctx.t() + 1), alloc, sc, group);
            LOG3(grp_ctx.t_tabs()
                 << "(End) Try container group: " << group);
            if (!group_rst.ok()) {
                LOG3(grp_ctx.t_tabs()
                     << "Failed to find valid allocation because: " << group_rst.err_str());
                if (group_rst.err->code == ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED &&
                    group_rst.err->reslice_required) {
                    reslice_required_reason = group_rst.err->msg;
                    for (const auto& sl : *group_rst.err->reslice_required) {
                        reslice_required->insert(sl);
                    }
                } else {
                    other_err = group_rst.err;
                }
                continue;
            }
            auto new_score = grp_ctx.score()->make(*group_rst.tx);
            LOG3(grp_ctx.t_tabs() << "Successfully allocated "
                 << "SC-" << sc->uid << " to group " << group << ": ");
            LOG3(group_rst.tx_str(grp_ctx.t_tabs() + " "));
            LOG3(grp_ctx.t_tabs() << "Score: " << new_score->str());
            if (!rst || new_score->better_than(rst_score)) {
                if (!rst) {
                    LOG3(grp_ctx.t_tabs() << "This is the first valid allocation.");
                } else {
                    LOG3(grp_ctx.t_tabs() << "This is a *BETTER* allocation.");
                    LOG3(grp_ctx.t_tabs() << "Previous score: " << rst_score->str());
                }
                rst = group_rst;
                rst_score = new_score;
            } else {
                LOG3(grp_ctx.t_tabs() << "This is *NOT* a better allocation.");
            }
        }
    }
    if (rst) {
        return *rst;
    } else {
        AllocError* err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
        if (!has_any_valid_alignment) {
            err = new AllocError(ErrorCode::NO_VALID_SC_ALLOC_ALIGNMENT);
        } else if (!reslice_required->empty()) {
            err = new AllocError(ErrorCode::ACTION_CANNOT_BE_SYNTHESIZED);
            err->reslice_required = reslice_required;
            *err << reslice_required_reason;
        } else if (other_err) {
            return AllocResult(*other_err);
        }
        return AllocResult(err);
    }
}

PHV::Transaction AllocatorBase::alloc_deparser_zero_cluster(
        const ScoreContext& ctx,
        const PHV::Allocation& alloc,
        const PHV::SuperCluster* sc,
        PhvInfo& phv) const {
    static const std::map<gress_t, PHV::Container> zero_container = {
        {INGRESS, PHV::Container("B0")}, {EGRESS, PHV::Container("B16")}};

    auto tx = alloc.makeTransaction();
    if (kit_i.is_clot_allocated(kit_i.clot, *sc)) {
        return tx;
    }
    LOG3(ctx.t_tabs() << "try alloc deparser-zero optimization clusters: " << sc);
    for (auto* sl : sc->slice_lists()) {
        int offset = 0;
        for (const auto& slice : *sl) {
            std::vector<PHV::AllocSlice> candidate_slices;
            const int slice_width = slice.size();
            // Allocate bytewise chunks of this field to B0 and B16.
            for (int i = 0; i < slice_width; i += 8) {
                int alloc_slice_width = std::min(8, slice_width - i);
                le_bitrange container_slice = StartLen(offset % 8, alloc_slice_width);
                le_bitrange field_slice = StartLen(i + slice.range().lo, alloc_slice_width);
                BUG_CHECK(slice.gress() == INGRESS || slice.gress() == EGRESS,
                          "Found a field slice for %1% that is neither ingress nor egress",
                          slice.field()->name);
                const auto& container = zero_container.at(slice.gress());
                auto alloc_slice = PHV::AllocSlice(
                        kit_i.phv.field(slice.field()->id), container,
                        field_slice, container_slice);
                LOG5(ctx.t_tabs() << "deparser-zero slice: " << alloc_slice);
                candidate_slices.push_back(alloc_slice);
                phv.addZeroContainer(slice.gress(), container);
                offset += alloc_slice_width;
            }
            if (kit_i.settings.physical_liverange_overlay) {
                // candidate_slices = update_alloc_slices_with_physical_liverange(
                //     kit_i.clot, kit_i.physical_liverange_db, candidate_slices);
                // XXX(yumin): do not overlay with deparser-zero optimization slices, because
                // they rely on parser to init the container to zero and use them in deparser
                // for emitting zeros.
                // TODO(yumin): we can overlay them on Tofino2+ if we support the feature:
                // deparser output any one of 8 constant bytes in any slot of a field
                // dictionary (the 8 constants can be programmed to any 8 8bit values).
                const auto default_lr =
                    kit_i.physical_liverange_db.default_liverange()->disjoint_ranges().front();
                for (auto& slice : candidate_slices) {
                    slice.setIsPhysicalStageBased(true);
                    slice.setLiveness(default_lr.start, default_lr.end);
                }
            }
            for (auto& alloc_slice : candidate_slices)
                tx.allocate(alloc_slice, nullptr, kit_i.settings.single_gress_parser_group);
        }
    }
    return tx;
}

AllocResult AllocatorBase::alloc_stride(const ScoreContext& ctx,
                                        const Allocation& alloc,
                                        const std::vector<FieldSlice>& stride,
                                        const ContainerGroupsBySize& groups_by_sizes) const {
    const auto& leader = stride.front();
    BUG_CHECK(leader.field()->exact_containers(),
              "non-header stride not supported: %1%", leader);
    BUG_CHECK(groups_by_sizes.count(PHV::Size(leader.size())),
              "non-container-sized stride not supported: %1%", leader);

    if (LOGGING(3)) {
        LOG3(ctx.t_tabs() << "Trying to allocate stride:");
        for (const auto& fs : stride) {
            LOG3(ctx.t_tabs() << "\t" << fs);
        }
    }

    boost::optional<AllocResult> best_rst;
    const TxScore* best_score = nullptr;
    // find the best container group for this stride.
    for (const auto& group : groups_by_sizes.at(PHV::Size(leader.size()))) {
        LOG3(ctx.t_tabs() << " Trying container group: " << group);
        // XXX(yumin): for each group, we will only try the first okay container stride,
        // (may go across to the next group because stride are not limited by mau groups).
        // pick a leader container, and try to allocate the stride starting from leader.
        auto leader_cond_ctx = ctx.with_t(ctx.t() + 1);
        for (const auto& leader_cond : group) {
            // build allocation schedule based on this leader container.
            bool ok = true;
            PHV::Container curr_cond = leader_cond;
            ordered_map<FieldSlice, Container> container_schedule;
            for (const auto& fs : stride) {
                if (!alloc.getStatus(curr_cond)) {
                    ok = false;
                    break;
                }
                container_schedule[fs] = curr_cond;
                curr_cond = PHV::Container(curr_cond.type(), curr_cond.index() + 1);
            }
            if (!ok) break;
            // allocate them by schedule.
            auto tx = alloc.makeTransaction();
            for (const auto& fs_cond : container_schedule) {
                FieldSliceAllocStartMap fs_start;
                fs_start[fs_cond.first] = 0;
                LOG3(leader_cond_ctx.t_tabs()
                     << "Try to allocate " << fs_cond.first << " ==> " << fs_cond.second);
                auto rst = try_slices_to_container(leader_cond_ctx.with_t(leader_cond_ctx.t() + 1),
                                                   tx, fs_start, fs_cond.second, true);
                if (!rst.ok()) {
                    LOG3(leader_cond_ctx.t_tabs() << "Failed because " << rst.err_str());
                    ok = false;
                    break;
                }
                tx.commit(*rst.tx);
            }
            if (ok) {
                LOG3(leader_cond_ctx.t_tabs()
                     << "stride allocation succeeded for leader container: " << leader_cond);
                auto* score = ctx.score()->make(tx);
                if (!best_score || score->better_than(best_score)) {
                    LOG3(leader_cond_ctx.t_tabs() << "This is by far the best score.");
                    best_rst = AllocResult(tx);
                    best_score = score;
                }
                break;
            }
        }
    }
    if (best_rst) {
        return *best_rst;
    }
    return AllocResult(new AllocError(ErrorCode::NOT_ENOUGH_SPACE));
}

AllocResult AllocatorBase::alloc_strided_super_clusters(const ScoreContext& ctx,
                                                        const Allocation& alloc,
                                                        const SuperCluster* sc,
                                                        const ContainerGroupsBySize& groups,
                                                        const int max_n_slicings) const {
    BUG_CHECK(sc->needsStridedAlloc(), "invalid argument: a non-strided cluster : %1%", sc);
    LOG3(ctx.t_tabs() << "Trying to stride-allocate " << sc);
    const auto* stride_group =
        kit_i.strided_headers.get_strided_group(sc->slices().front().field());
    ordered_map<const PHV::Field*, int> stride_group_index;
    int idx = 0;
    for (const auto* f : *stride_group) {
        stride_group_index[f] = idx++;
    }
    boost::optional<Transaction> best_rst;
    const TxScore* best_score = nullptr;
    int n_tried = 0;
    auto itr_ctx = kit_i.make_slicing_ctx(sc);  // do not need to set config, strided mode.
    const auto* err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
    const auto new_ctx = ctx.with_sc(sc).with_t(ctx.t() + 1);
    itr_ctx->iterate([&](std::list<SuperCluster*> clusters) {
        n_tried++;
        if (LOGGING(3)) {
            LOG3(ctx.t_tabs() << "Clusters of (strided) slicing-attempt-" << n_tried << ":");
            for (auto* sc : clusters) LOG3(ctx.t_tabs() << sc);
        }
        // group stride cluster by their ranges, where each range is a group.
        ordered_map<le_bitrange, std::vector<FieldSlice>> strides;
        for (const auto* sc : clusters) {
            BUG_CHECK(!sc->slices().empty(), "empty cluster: %1%", sc);
            const auto fs = sc->slices().front();
            strides[fs.range()].push_back(fs);
        }
        auto tx = alloc.makeTransaction();
        for (std::vector<FieldSlice> stride : Values(strides)) {
            // sort by their header stack index, because lower index fields needs to be allocated to
            // lower id containers. NOTE: there is no such check in the old PHV allocation,
            // either I missed something, or it is correct when only super clusters order is the
            // same as header stack order, which would be a miracle if it is always true.
            // B
            std::sort(stride.begin(), stride.end(),
                      [&](const PHV::FieldSlice& a, const PHV::FieldSlice& b) {
                          return stride_group_index.at(a.field()) <
                                 stride_group_index.at(b.field());
                      });
            auto rst = alloc_stride(new_ctx, tx, stride, groups);
            if (!rst.ok()) {
                LOG3(ctx.t_tabs() << "slicing-attempt-" << n_tried
                     << " failed, while allocating the stride of " << stride.front());
                err = rst.err;
                return n_tried < max_n_slicings;
            }
            tx.commit(*rst.tx);
        }
        auto score = ctx.score()->make(tx);
        if (!best_score || score->better_than(best_score)) {
            LOG3(ctx.t_tabs() << "slicing-attempt-" << n_tried << " succeeded. ");
            best_rst = tx;
            best_score = score;
        }
        return n_tried < max_n_slicings;
    });
    if (best_rst)
        return AllocResult(*best_rst);
    else
        return AllocResult(err);
}

}  // namespace v2
}  // namespace PHV
