#include "bf-p4c/phv/v2/allocator_base.h"

#include <sstream>
#include <tuple>

#include <boost/range/join.hpp>

#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/action_source_tracker.h"
#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/copacker.h"
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
bool can_physical_liverange_overlay(const AllocUtils& utils,
                                    const AllocSlice& slice,
                                    const ordered_set<AllocSlice>& overlapped) {
    BUG_CHECK(slice.isPhysicalStageBased(),
              "slice must be physical-stage-based in can_physical_liverange_overlay");
    for (const auto& other : overlapped) {
        BUG_CHECK(other.isPhysicalStageBased(),
                  "slice must be physical-stage-based in can_physical_liverange_overlay");
        if (!utils.can_physical_liverange_be_overlaid(slice, other)) {
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
    const std::vector<AllocSlice>& slices) {
    const bool deparsed_cannot_read_clot =
        std::any_of(slices.begin(), slices.end(), [&](const AllocSlice& slice) {
            const auto* f = slice.field();
            return f->deparsed() && (!clot.whole_field_clot(f) || clot.is_modified(f));
        });

    std::vector<AllocSlice> rst;
    for (auto& slice : slices) {
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
        }
        for (const auto& r : LiveRangeInfo::merge_invalid_ranges(info->disjoint_ranges())) {
            PHV::AllocSlice clone = slice;
            clone.setIsPhysicalStageBased(true);
            clone.setLiveness(r.start, r.end);
            rst.emplace_back(clone);
        }
    }
    return rst;
}

/// @returns a map of start of field slices in @p sl, based on @p alignment.
FieldSliceAllocStartMap make_start_map(const ScAllocAlignment& alignment,
                                       const SuperCluster::SliceList* sl) {
    FieldSliceAllocStartMap starts;
    for (const auto& fs : *sl) {
        starts[fs] = alignment.slice_starts.at(fs);
    }
    return starts;
}

}  // namespace

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
    for (const auto& group : Device::phvSpec().mauGroups(candidates_cont.type().size())) {
        for (const auto cid : group) {
            const Container c = Device::phvSpec().idToContainer(cid);
            if (c.type().kind() != Kind::normal) continue;
            if ((gress == INGRESS && Device::phvSpec().egressOnly()[cid]) ||
                (gress == EGRESS && Device::phvSpec().ingressOnly()[cid])) {
                continue;
            }
            if (alloc.parserGroupGress(c) && *alloc.parserGroupGress(c) != gress) continue;
            if (alloc.deparserGroupGress(c) && *alloc.deparserGroupGress(c) != gress) continue;
            const auto EMPTY = Allocation::ContainerAllocStatus::EMPTY;
            if (!alloc.getStatus(c) || alloc.getStatus(c)->alloc_status == EMPTY) {
                empty_containers.insert(c);
            }
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
        if (utils_i.settings.physical_liverange_overlay) {
            speculated_alloc_slices = update_alloc_slices_with_physical_liverange(
                utils_i.clot, utils_i.physical_liverange_db, speculated_alloc_slices);
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
    // TODO(yumin): speed optimization: we can skip adding speculated alloc if
    // slice lists have all been allocated.
    const auto speculated_alloc = make_speculated_alloc(ctx, alloc, sc, candidates, c);
    const auto err = utils_i.actions.can_pack_v2(speculated_alloc, candidates);
    if (err.first != CanPackErrorCode::NO_ERROR) {
        std::stringstream ss;
        ss << err.first << ", " << err.second;
        const auto is_container_empty = alloc.liverange_overlapped_slices(c, candidates).empty();
        if (is_container_empty && c.type().kind() == PHV::Kind::normal) {
            return new AllocError(ErrorCode::CANNOT_PACK_CANDIDATES, ss.str());
        } else {
            return new AllocError(ErrorCode::CANNOT_PACK_WITH_ALLOCATED, ss.str());
        }
    }

    //// recursivesly check conditional constraints, but do not need to commit them to tx.
    auto tx = speculated_alloc.makeTransaction();
    for (const auto& sl : candidates)
        tx.allocate(sl, nullptr, utils_i.settings.single_gress_parser_group);

    auto copack_hints = CoPacker(utils_i.source_tracker, sc, ctx.alloc_alignment())
                            .gen_copack_hints(tx, candidates, c);
    if (!copack_hints.ok()) {
        return copack_hints.err;
    }

    for (const auto& action_hints : copack_hints.action_hints) {
        const auto* action = action_hints.first;
        const auto& hints = action_hints.second;
        if (!(hints.size() == 1 && hints.front()->required)) continue;
        LOG5(ctx.t_tabs() << "Recursively check action " << cstring::to_cstring(action->name)
                          << " for unallocated sources that must be pack, reason: "
                          << hints.front()->reason);
        for (const auto& pack_vec : hints.front()->pack_sources) {
            auto* min_search_config = new SearchConfig(*ctx.search_config());
            min_search_config->stop_first_succ_empty_normal_container = true;
            auto rst =
                try_slices_adapter(ctx.with_t(ctx.t() + 1)
                                       .with_search_config(min_search_config)
                                       .with_score(new NilTxScoreMaker()),
                                   tx, pack_vec->fs_starts, *ctx.cont_group(), pack_vec->container);
            if (!rst.ok()) {
                std::stringstream ss;
                ss << "recursive can_pack failed for action " << cstring::to_cstring(action->name);
                return new AllocError(ErrorCode::CANNOT_PACK_WITH_ALLOCATED, ss.str());
            }
        }
    }
    action_copack_hints = std::move(copack_hints.action_hints);
    return nullptr;
}

const AllocError* AllocatorBase::is_container_type_ok(const AllocSlice& sl,
                                                      const Container& c) const {
    auto* err = new AllocError(ErrorCode::CONTAINER_TYPE_MISMATCH);

    // pa_container_type pragma.
    auto required_kind = utils_i.pragmas.pa_container_type().required_kind(sl.field());
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
            type_ok = sl.field()->is_tphv_candidate(utils_i.uses);
            break;
        }
    }
    if (!type_ok) {
        *err << "unsat container type: " << sl.field() << " cannot be allocated to " << c;
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
        *err << "container is " << *gress << " but the field is not: " << sl.field();
        return err;
    }
    // all containers within parser group must have same gress assignment
    const auto parser_group_gress = alloc.parserGroupGress(c);
    const bool is_extracted = utils_i.uses.is_extracted(sl.field());
    if (parser_group_gress && (is_extracted || utils_i.settings.single_gress_parser_group) &&
        (*parser_group_gress != sl.field()->gress)) {
        *err << c << " has parser group gress " << *parser_group_gress
             << " but the field is not: " << sl.field();
        return err;
    }
    // all containers within deparser group must have same gress assignment
    auto deparser_group_gress = alloc.deparserGroupGress(c);
    bool is_deparsed = utils_i.uses.is_deparsed(sl.field());
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
    const auto& field_to_states = utils_i.field_to_parser_states;
    const auto parser_group_gress = alloc.parserGroupGress(c);
    const bool is_extracted = utils_i.uses.is_extracted(f);
    if (!is_extracted || !parser_group_gress) {
        return nullptr;
    }
    // all containers within parser group must have same parser write mode
    auto allocated_slices = alloc.liverange_overlapped_slices(c, {candidate});
    if (allocated_slices.empty()) return nullptr;
    boost::optional<IR::BFN::ParserWriteMode> write_mode;
    for (auto allocated : allocated_slices) {
        auto allocated_field = allocated.field();
        if (allocated_field == f) {
            continue;
        }
        if (!field_to_states.field_to_extracts.count(allocated_field)) continue;
        for (auto ef : field_to_states.field_to_extracts.at(f)) {
            auto ef_state = field_to_states.extract_to_state.at(ef);
            for (auto esl : field_to_states.field_to_extracts.at(allocated_field)) {
                auto esl_state = field_to_states.extract_to_state.at(esl);
                // A container cannot have same extract in same state
                if (esl_state == ef_state && ef->source->equiv(*esl->source) &&
                    ef->source->is<IR::BFN::PacketRVal>()) {
                    *err << "Slices of field " << f << " and " << allocated_field
                         << " have same extract source in the same state " << esl_state->name;
                    return err;
                }
            }
        }
    }

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
    const PhvSpec& phv_spec = Device::phvSpec();
    for (unsigned other_id : phv_spec.parserGroup(phv_spec.containerToId(c))) {
        auto other = phv_spec.idToContainer(other_id);
        if (c == other) continue;

        auto cs = alloc.getStatus(other);
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

const AllocError* AllocatorBase::is_container_parser_packing_ok(
    const Allocation& alloc, const AllocSlice& candidate, const Container& c) const {
    const auto is_extracted = [&](const Field* f) {
        // constants will have zeros in irrelevant bits, and when extracter bit-or-write
        // the container, zeros will just be no-op to other fields packed in the container,
        // so extracted from constant are okay to be packed with any other fields.
        return !f->pov && utils_i.uses.is_extracted(f) &&
               !utils_i.uses.is_extracted_from_constant(f);
    };
    const auto is_uninitialized = [&](const Field* f) {
        return (f->pov || (utils_i.defuse.hasUninitializedRead(f->id)));
    };
    bool has_uninitialized_read = false;
    bool has_extracted = false;
    bool all_extracted_togehter = true;
    for (auto& allocated : alloc.liverange_overlapped_slices(c, {candidate})) {
        if (allocated.field()->is_ignore_alloc()) {
            continue;
        }
        has_uninitialized_read |=
            !allocated.field()->is_padding() && is_uninitialized(allocated.field());
        // padding field may overwrite uninitialized field, as long as it was extracted.
        // TODO(yumin): unless we do not generate extract for padding fields?
        has_extracted |= is_extracted(allocated.field());
        // TODO(yumin): WARNING: this is wrong! extracted together slices can be packed into
        // a container in an order that is different from input buffer. The correct check
        // should be are they always extracted in this layout.
        all_extracted_togehter &=
            utils_i.phv.are_bridged_extracted_together(allocated.field(), candidate.field());
    }

    // if all are extracted together, them they can be packed.
    if (all_extracted_togehter) {
        return nullptr;
    }

    const bool candidate_extracted = is_extracted(candidate.field());
    const bool candidate_uninitialized =
        !candidate.field()->is_padding() && is_uninitialized(candidate.field());
    auto* err = new AllocError(ErrorCode::CONTAINER_PARSER_PACKING_INVALID);
    if (has_extracted && (candidate_uninitialized || candidate_extracted)) {
        // TODO(yumin): when both allcoated and candidate are extracted, actually they can be
        // packed together as long as they are *always extracted together*:
        // AllocSlices (allocated + candidates) are in the same layout as they were on the
        // input buffer on any state.
        *err << "extracted slices allocated already, can't be packed because " << candidate
             << " is " << (candidate_extracted ? "extracted" : "uninitialized");
        return err;
    }
    if (has_uninitialized_read && candidate_extracted) {
        *err << "uninitialized slices allocated already, can't be packed with extracted slice: "
             << candidate;
        return err;
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
    const Allocation& alloc, const std::vector<AllocSlice> candidates, const Container& c) const {
    for (const auto& sl : candidates) {
        // Check container type constraint.
        if (auto* err = is_container_type_ok(sl, c)) {
            return err;
        }
        // Check gress related constraints.
        if (auto* err = is_container_gress_ok(alloc, sl, c)) {
            return err;
        }
        // Check container group write mode constraints.
        if (auto* err = is_container_write_mode_ok(alloc, sl, c)) {
            return err;
        }
        // Check solitary constraint for candidates and allocated fields.
        if (auto* err = is_container_solitary_ok(alloc, sl, c)) {
            return err;
        }
        // Check solitary constraint for candidates and allocated fields.
        if (auto* err = is_container_parser_packing_ok(alloc, sl, c)) {
            return err;
        }
    }
    // Check max container bytes constraint.
    if (auto* err = is_container_bytes_ok(alloc, candidates, c)) {
        return err;
    }
    return nullptr;
}

AllocResultWithPackHint AllocatorBase::try_slices_to_container(
    const ScoreContext& ctx, const Allocation& alloc, const FieldSliceAllocStartMap& fs_starts,
    const Container& c) const {
    auto candidates = make_alloc_slices(utils_i.uses, fs_starts, c);
    // check misc container-scope constraints.
    if (const auto* err = check_container_scope_constraints(alloc, candidates, c)) {
        return AllocResultWithPackHint(err);
    }
    if (utils_i.settings.physical_liverange_overlay) {
        candidates = update_alloc_slices_with_physical_liverange(
            utils_i.clot, utils_i.physical_liverange_db, candidates);
    }
    if (LOGGING(3)) {
        LOG3(ctx.t_tabs() << "AllocSlices:");
        for (const auto& slice : candidates) {
            LOG3(ctx.t_tabs() << " " << slice);
        }
    }

    // check overlay
    LOG5(ctx.t_tabs() << "Overlay status:");
    for (const auto& slice : candidates) {
        const auto& overlapped = alloc.slices(slice.container(), slice.container_slice());
        const cstring short_name =
            slice.field()->name + " " + cstring::to_cstring(slice.field_slice());
        if (overlapped.empty()) {
            LOG5(ctx.t_tabs() << " " << short_name << ": "
                              << "no overlapped slices.");
        } else if (can_control_flow_overlay(utils_i.mutex(), slice.field(), overlapped)) {
            LOG5(ctx.t_tabs() << short_name << ": " << "control flow overlaid.");
        } else if (utils_i.settings.physical_liverange_overlay &&
                   can_physical_liverange_overlay(utils_i, slice, overlapped)) {
            LOG5(ctx.t_tabs() << short_name << ": "
                              << "physical liverange overlaid.");
        } else {
            auto err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
            *err << short_name << ": " << "not available, overlapped with: " << overlapped;
            return AllocResultWithPackHint(err);
        }
    }

    // check can_pack
    ActionSourceCoPackMap action_copack_hints;
    if (const auto* err =
            verify_can_pack(ctx, alloc, ctx.sc(), candidates, c, action_copack_hints)) {
        return AllocResultWithPackHint(err);
    }

    // save allocation to result transaction.
    auto tx = alloc.makeTransaction();
    for (auto& slice : candidates) {
        tx.allocate(slice, nullptr, utils_i.settings.single_gress_parser_group);
    }

    return AllocResultWithPackHint(tx, action_copack_hints);
}

AllocResultWithPackHint AllocatorBase::try_slices_to_container_group(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const FieldSliceAllocStartMap& fs_starts,
    const ContainerGroup& group) const {
    const TxScore* rst_score = nullptr;
    boost::optional<AllocResultWithPackHint> rst;
    const auto new_ctx = ctx.with_t(ctx.t() + 1);
    ErrorCode err_code = ErrorCode::NO_CONTAINER_AVAILABLE;
    cstring err_details = "no container have enough space.";
    for (const Container& c : group) {
        LOG3(ctx.t_tabs() << "Try container " << c);
        auto c_rst = try_slices_to_container(new_ctx, alloc, fs_starts, c);
        if (c_rst.ok()) {
            // pick this container if higher score.
            const auto* c_rst_score = ctx.score()->make(*c_rst.tx);
            LOG3(ctx.t_tabs() << "Succeeded, result: ");
            LOG3(c_rst.tx_str(ctx.t_tabs() + " "));
            LOG3(ctx.t_tabs() << "score: " << c_rst_score->str());
            if (!rst || c_rst_score->better_than(rst_score)) {
                rst = c_rst;
                rst_score = c_rst_score;
                LOG3(ctx.t_tabs() << "Container " << c << " now has the highest score");
            } else {
                LOG3(ctx.t_tabs() << "Container " << c << " is not the best choice found");
            }
            // handle container-level search optimization parameter.
            if (ctx.search_config()->stop_first_succ_empty_normal_container) {
                const auto container_status = alloc.getStatus(c);
                if (c.type().kind() == PHV::Kind::normal &&
                    (!container_status || container_status->slices.empty())) {
                    LOG3(ctx.t_tabs() << "Stop early because first_succ_empty_normal_container.");
                    break;
                }
            }
        } else {
            LOG3(ctx.t_tabs() << "Failed @" << c << " because: " << c_rst.err_str());
            // prefer to return this most informative error message.
            if (c_rst.err->code == ErrorCode::CANNOT_PACK_CANDIDATES) {
                err_code = ErrorCode::CANNOT_PACK_CANDIDATES;
                err_details = c_rst.err_str();
            }
        }
    }
    if (rst) {
        return *rst;
    }
    // no valid container found.
    return AllocResultWithPackHint(new AllocError(err_code, err_details));
}

AllocResultWithPackHint AllocatorBase::try_slices_adapter(const ScoreContext& ctx,
                                                          const Allocation& alloc,
                                                          const FieldSliceAllocStartMap& fs_starts,
                                                          const ContainerGroup& group,
                                                          boost::optional<Container> c) const {
    if (c) {
        return try_slices_to_container(ctx, alloc, fs_starts, *c);
    } else {
        return try_slices_to_container_group(ctx, alloc, fs_starts, group);
    }
}

Transaction AllocatorBase::try_hints(const ScoreContext& ctx,
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
        LOG3(ctx.t_tabs() << "> trying to allocate by hints for " << act->externalName());
        // for all mutex hints of this action, try until we find an allocation.
        for (const auto* hint : hints) {
            LOG3(ctx.t_tabs() << "> trying hints: " << hint);
            auto hint_tx = tx.makeTransaction();
            bool hint_ok = true;
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
                // XXX(yumin): we trust that copacker will respect ScAllocAlignment.
                auto src_pack_rst = try_slices_adapter(
                        ctx.with_t(ctx.t() + 1), hint_tx, fs_starts,
                        group, src_pack->container);
                if (src_pack_rst.ok()) {
                    hint_tx.commit(*src_pack_rst.tx);
                } else {
                    LOG3("Failed to allocate by hints.");
                    hint_ok = false;
                    break;
                }
            }
            if (!hint_ok) continue;
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
    const auto lo_starts = make_start_map(alignment, lo);
    const auto hi_starts = make_start_map(alignment, hi);
    for (auto itr = group.begin(); itr != group.end(); ++itr) {
        if (std::next(itr) == group.end()) continue;
        const auto lo_cont = *itr;
        const auto hi_cont = *(std::next(itr));
        if (lo_cont.index() % 2 != 0) continue;

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

// TODO(yumin): use universal dest-to-src field slice allocation order.
// The current allocation process is still a bit weird. It allocates slice lists first,
// and then field slices in rotational clusters. The problem is that, if the slice list
// allocation is invalid (violating action phv constraints by packing some field slices),
// we cannot know it until allocating its sources. Instead, we can just use a universal
// destination fieldslice first order, backtrack immediately if we cannot allocate sources.
AllocResult AllocatorBase::try_super_cluster_with_alignment_to_container_group(
    const ScoreContext& ctx,
    const Allocation& alloc,
    const SuperCluster* sc,
    const ContainerGroup& group) const {
    // Make a new transaction.
    PHV::Transaction sc_tx = alloc.makeTransaction();
    ordered_set<PHV::FieldSlice> allocated;
    auto new_ctx = ctx.with_t(ctx.t() + 1);

    // always try to allocate wide_arithmetic slice lists first.
    for (const auto* lo_sl : *ctx.sl_alloc_order()) {
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

        static const cstring prefix = "> trying to allocate wide_arith slice list:";
        LOG3(ctx.t_tabs() <<  prefix << "START to allocate the pair: " << lo_sl << ", " << hi_sl);
        auto sl_alloc_rst = try_wide_arith_slices_to_container_group(
                new_ctx, sc_tx, *ctx.alloc_alignment(), lo_sl, hi_sl, group);
        if (!sl_alloc_rst.ok()) {
            LOG3(ctx.t_tabs() << prefix << "FAILED, because " << sl_alloc_rst.err_str());
            return sl_alloc_rst;
        }
        LOG3(ctx.t_tabs() << prefix << "SUCCEEDED, result:\n"
             << sl_alloc_rst.tx_str(ctx.t_tabs()));
        sc_tx.commit(*sl_alloc_rst.tx);

        // Track allocated slices in order to skip them when allocating their clusters.
        for (const auto& fs : boost::range::join(*lo_sl, *hi_sl)) {
            allocated.insert(fs);
        }
    }

    // allocate non_wide_arithmetic slice lists.
    // Successfully allocated copack hints can update alignment starts.
    ScAllocAlignment updated_alignment = *ctx.alloc_alignment();
    for (const auto* sl : *ctx.sl_alloc_order()) {
        // skip wide_arithmetic slice lists, they should have been allocated above.
        if (allocated.count(sl->front())) continue;


        static const cstring prefix = "> trying to allocate slice list: ";
        LOG3(ctx.t_tabs() << prefix << "START to allocate " << sl);
        // Try allocating the slice list.
        FieldSliceAllocStartMap to_be_allocated = make_start_map(*ctx.alloc_alignment(), sl);
        new_ctx = new_ctx.with_alloc_alignment(&updated_alignment);
        auto sl_alloc_rst = try_slices_to_container_group(
                new_ctx, sc_tx, to_be_allocated, group);
        if (!sl_alloc_rst.ok()) {
            LOG3(ctx.t_tabs() << prefix << "FAILED, because " << sl_alloc_rst.err->str());
            auto* new_err = new AllocError(*sl_alloc_rst.err);
            new_err->cannot_allocate_sl = sl;
            return AllocResult(new_err);
        }
        LOG3(ctx.t_tabs() << prefix << "SUCCEEDED, result:\n"
             << sl_alloc_rst.tx_str(ctx.t_tabs()));
        sc_tx.commit(*sl_alloc_rst.tx);

        // Track allocated slices in order to skip them when allocating their clusters.
        for (auto& slice : *sl) {
            allocated.insert(slice);
        }

        /// try hints here
        /// When a hint is allocated, the alignment is then fixed for all the slice
        /// in the aligned cluster, so we pass a mutable updated_alignment.
        auto hint_tx = try_hints(new_ctx, sc_tx, group, sl_alloc_rst.action_hints, allocated,
                                 updated_alignment);
        sc_tx.commit(hint_tx);
    }

    LOG3(ctx.t_tabs() << "Slice lists allocation done, start to allocate clusters");
    // always allocate wider clusters first.
    std::vector<const RotationalCluster*> rot_alloc_order;
    for (auto* rot : sc->clusters()) {
        rot_alloc_order.push_back(rot);
    }
    std::stable_sort(rot_alloc_order.begin(), rot_alloc_order.end(),
                     [&](const RotationalCluster* a, const RotationalCluster* b) {
                         if (a->slices().size() != b->slices().size()) {
                             return a->slices().size() > b->slices().size();
                         }
                         return a->aggregate_size() > b->aggregate_size();
                     });

    // After allocating each slice list, use the alignment for each slice in
    // each list to place its cluster.
    for (auto* rotational_cluster : rot_alloc_order) {
        for (auto* aligned_cluster : rotational_cluster->clusters()) {
            // TODO(yumin): move this part to context.
            // Sort all field slices in an aligned cluster by the dest_first_order.
            std::vector<PHV::FieldSlice> aligned_slices;
            for (const PHV::FieldSlice& fs : aligned_cluster->slices()) {
                aligned_slices.push_back(fs);
            }
            utils_i.actions.dest_first_sort(aligned_slices);

            // skip aligned cluster if all allocated. Cannot filter before sorting because
            // allocated field may impact sorting order.
            if (std::all_of(aligned_slices.begin(), aligned_slices.end(),
                            [&](const FieldSlice& fs) { return allocated.count(fs); })) {
                continue;
            }

            // Forall fields in an aligned cluster, they must share a same start position.
            // Compute possible starts.
            bitvec starts;
            if (updated_alignment.cluster_starts.count(aligned_cluster)) {
                // decided by slice list or hints already.
                starts = bitvec(updated_alignment.cluster_starts.at(aligned_cluster), 1);
            }  else {
                auto optStarts = aligned_cluster->validContainerStart(group.width());
                if (optStarts.empty()) {
                    auto* err = new AllocError(ErrorCode::ALIGNED_CLUSTER_NO_VALID_START);
                    // Other constraints satisfied, but alignment constraints
                    // cannot be satisfied.
                    *err << aligned_cluster << " to " << group.width() << " container ";
                    return AllocResult(err);
                }
                // Constraints satisfied so long as aligned_cluster is placed
                // starting at a bit position in `starts`.
                starts = optStarts;
            }

            // try all possible alignments
            const TxScore* rst_score = nullptr;
            boost::optional<AllocResult> rst;  // save the best transaction.
            std::stringstream all_err;
            for (auto start : starts) {
                bool failed = false;
                auto aligned_cluster_tx = sc_tx.makeTransaction();
                // Try allocating all fields at this alignment.
                for (const PHV::FieldSlice& slice : aligned_slices) {
                    // Skip fields that have already been allocated above.
                    if (allocated.find(slice) != allocated.end()) continue;
                    std::stringstream ss;
                    ss << "> trying to allocate field slice " << slice.shortString() << " @"
                       << start << ": ";
                    const cstring prefix = ss.str();
                    LOG3(ctx.t_tabs() << prefix << "START");
                    const FieldSliceAllocStartMap fs_start = {{slice, start}};
                    auto this_slice_rst =
                        try_slices_to_container_group(new_ctx, aligned_cluster_tx, fs_start, group);
                    if (this_slice_rst.ok()) {
                        LOG3(ctx.t_tabs() << prefix << "SUCCEEDED");
                        aligned_cluster_tx.commit(*this_slice_rst.tx);
                    } else {
                        LOG3(ctx.t_tabs()
                             << prefix << "FAILED, because: " << this_slice_rst.err_str());
                        // keep records of all errors if we have not found any solution yet.
                        if (!rst) {
                            all_err << "When trying to allocate " << slice.shortString()
                                    << " at alignment @" << start << ", allocation failed because "
                                    << this_slice_rst.err_str() << "\n";
                        }
                        failed = true;
                        break;
                    }
                }
                if (failed) {
                    LOG3(ctx.t_tabs() << "Aligned cluster allocation FAILED @" << start);
                    continue;
                }
                LOG3(ctx.t_tabs() << "Aligned cluster allocation SUCCEEDED @" << start);

                auto new_score = ctx.score()->make(aligned_cluster_tx);
                if (!rst || new_score->better_than(rst_score)) {
                    LOG3(ctx.t_tabs()
                         << "New best score is of alignment @" << start);
                    rst = AllocResult(std::move(aligned_cluster_tx));
                    rst_score = new_score;
                }
                if (ctx.search_config()->stop_first_succ_fs_alignment) {
                    LOG3(ctx.t_tabs() << "Stop early because stop_first_succ_fs_alignment.");
                    break;
                }
            }

            if (!rst) {
                auto* err = new AllocError(ErrorCode::ALIGNED_CLUSTER_CANNOT_BE_ALLOCATED);
                *err << "Failed to allocate this aligned cluster: " << aligned_cluster << "\n";
                *err << "Error logs:\n" << all_err.str();
                return AllocResult(err);
            }
            sc_tx.commit(*(rst->tx));
        }
    }
    return AllocResult(sc_tx);
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
    const auto& pa_sz = utils_i.pragmas.pa_container_sizes();
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

    // attach the sorted slice list order to context. This is the order of allocation
    // for slice lists. NOTE: because we have finally deprecated the conditional constrain
    // we shall allocate destinations first to be able to detect failures.
    auto* sorted_slice_lists = new std::list<const SuperCluster::SliceList*>(
        sc->slice_lists().begin(), sc->slice_lists().end());
    utils_i.actions.dest_first_sort(*sorted_slice_lists);
    if (LOGGING(5)) {
        LOG5(ctx.t_tabs() << "Sorted slice list allocation order: ");
        for (const auto* sl : *sorted_slice_lists) {
            LOG5(ctx.t_tabs() << sl);
        }
    }

    // find the best score, forall (alignment, container group) of @p sc.
    const auto new_ctx =
        ctx.with_sc(sc).with_sl_alloc_order(sorted_slice_lists).with_t(ctx.t() + 1);
    const TxScore* rst_score = nullptr;
    boost::optional<AllocResult> rst;  // save the last succeed transaction only.
    // slice lists that allocator has returned an error of cannot_pack.
    ordered_set<const SuperCluster::SliceList*> cannot_pack_sl;
    boost::optional<const AllocError*> other_err;
    bool found_alignment = false;
    // stores only critical error message that might help caller to better slice the cluster.
    for (const auto& sz : ok_sizes) {
        LOG3(new_ctx.t_tabs() << "Trying to allocate SC-" << sc->uid << " to " << sz
                          << " container groups");
        auto alignments = make_sc_alloc_alignment(
                sc, sz, new_ctx.search_config()->n_max_sc_alignments, sorted_slice_lists);
        if (alignments.empty()) {
            LOG3(new_ctx.t_tabs() << "No valid ScAllocAlignment found for size " << sz);
            continue;
        } else {
            found_alignment = true;
        }
        LOG3(new_ctx.t_tabs() << "# of alignments found: " << alignments.size());
        for (const auto& group : groups.at(sz)) {
            const auto grp_ctx = new_ctx.with_t(new_ctx.t() + 1).with_cont_group(&group);
            LOG3(grp_ctx.t_tabs() << "Try container group: " << group);
            for (const auto& alignment : alignments) {
                const auto grp_aln_ctx =
                    grp_ctx.with_t(grp_ctx.t() + 1).with_alloc_alignment(&alignment);
                if (!alignment.empty()) {
                    LOG3(grp_aln_ctx.t_tabs() << "Try with this slice list alignment:\n"
                                              << alignment.pretty_print(grp_aln_ctx.t_tabs(), sc));
                }
                auto group_rst = try_super_cluster_with_alignment_to_container_group(
                        grp_aln_ctx, alloc, sc, group);
                if (!group_rst.ok()) {
                    LOG3(grp_aln_ctx.t_tabs()
                         << "Failed to find valid allocation because: " << group_rst.err_str());
                    if (group_rst.err->code == ErrorCode::CANNOT_PACK_CANDIDATES &&
                        group_rst.err->cannot_allocate_sl) {
                        cannot_pack_sl.insert(group_rst.err->cannot_allocate_sl);
                    } else {
                        other_err = group_rst.err;
                    }
                    continue;
                }
                auto new_score = grp_aln_ctx.score()->make(*group_rst.tx);
                LOG3(grp_aln_ctx.t_tabs() << "Successfully allocated " << "SC-" << sc->uid << ":");
                LOG3(group_rst.tx_str(grp_aln_ctx.t_tabs() + " "));
                LOG3(grp_aln_ctx.t_tabs() << "Score: " << new_score->str());
                if (!rst || new_score->better_than(rst_score)) {
                    if (!rst) {
                        LOG3(grp_aln_ctx.t_tabs() << "This is the first valid allocation.");
                    } else {
                        LOG3(grp_aln_ctx.t_tabs() << "This is a better allocation.");
                    }
                    rst = group_rst;
                    rst_score = new_score;
                } else {
                    LOG3(grp_aln_ctx.t_tabs() << "This is a worse allocation.");
                }
                if (grp_aln_ctx.search_config()->stop_first_succ_sc_alignment) {
                    LOG3(grp_aln_ctx.t_tabs()
                         << "Stopped at first alignment of successful allocation.");
                    break;
                }
            }
        }
    }
    if (rst) {
        return *rst;
    } else {
        AllocError* err = new AllocError(ErrorCode::NOT_ENOUGH_SPACE);
        if (!found_alignment) {
            err = new AllocError(ErrorCode::NO_VALID_SC_ALLOC_ALIGNMENT);
        } else if (!cannot_pack_sl.empty()) {
            err = new AllocError(ErrorCode::CANNOT_PACK_CANDIDATES);
            err->cannot_allocate_sl = *cannot_pack_sl.begin();
            *err << "cannot allocate slice list: " << err->cannot_allocate_sl;
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
    if (utils_i.is_clot_allocated(utils_i.clot, *sc)) {
        return tx;
    }
    LOG3(ctx.t_tabs() << " try alloc deparser-zero optimization clusters: " << sc);
    for (auto* sl : sc->slice_lists()) {
        int offset = 0;
        for (const auto& slice : *sl) {
            LOG5(ctx.t_tabs() << "Slice in slice list: " << slice);
            std::vector<PHV::AllocSlice> candidate_slices;
            const int slice_width = slice.size();
            // Allocate bytewise chunks of this field to B0 and B16.
            for (int i = 0; i < slice_width; i += 8) {
                int alloc_slice_width = std::min(8, slice_width - i);
                LOG5(ctx.t_tabs() << "Alloc slice width: " << alloc_slice_width);
                LOG5(ctx.t_tabs() << "Slice list offset: " << offset);
                le_bitrange container_slice = StartLen(offset % 8, alloc_slice_width);
                le_bitrange field_slice = StartLen(i + slice.range().lo, alloc_slice_width);
                LOG5(ctx.t_tabs() << "Container slice: " << container_slice
                                  << ", field slice: " << field_slice);
                BUG_CHECK(slice.gress() == INGRESS || slice.gress() == EGRESS,
                          "Found a field slice for %1% that is neither ingress nor egress",
                          slice.field()->name);
                const auto& container = zero_container.at(slice.gress());
                auto alloc_slice = PHV::AllocSlice(
                        utils_i.phv.field(slice.field()->id), container,
                        field_slice, container_slice);
                candidate_slices.push_back(alloc_slice);
                phv.addZeroContainer(slice.gress(), container);
                offset += alloc_slice_width;
            }
            if (utils_i.settings.physical_liverange_overlay) {
                // candidate_slices = update_alloc_slices_with_physical_liverange(
                //     utils_i.clot, utils_i.physical_liverange_db, candidate_slices);
                // XXX(yumin): do not overlay with deparser-zero optimization slices, because
                // they rely on parser to init the container to zero and use them in deparser
                // for emitting zeros.
                // TODO(yumin): we can overlay them on Tofino2+ if we support the feature:
                // deparser output any one of 8 constant bytes in any slot of a field
                // dictionary (the 8 constants can be programmed to any 8 8bit values).
                const auto default_lr =
                    utils_i.physical_liverange_db.default_liverange()->disjoint_ranges().front();
                for (auto& slice : candidate_slices) {
                    slice.setIsPhysicalStageBased(true);
                    slice.setLiveness(default_lr.start, default_lr.end);
                }
            }
            for (auto& alloc_slice : candidate_slices)
                tx.allocate(alloc_slice, nullptr, utils_i.settings.single_gress_parser_group);
        }
    }
    return tx;
}

}  // namespace v2
}  // namespace PHV
