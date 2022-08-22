#include "bf-p4c/phv/v2/parser_packing_validator.h"

#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"

namespace PHV {
namespace v2 {

namespace {

/// @returns network-order bitrange of extract to @p fs;
nw_bitrange slice_extract_range(const FieldSlice& fs, const IR::BFN::Extract* e) {
    BUG_CHECK(e->source->is<IR::BFN::PacketRVal>(), "not a packet extract: %1%", e);
    const auto& buf_range = e->source->to<IR::BFN::PacketRVal>()->range;
    return nw_bitrange(
        StartLen(buf_range.hi - fs.range().lo - fs.range().size() + 1, fs.range().size()));
}

}  // namespace

ParserPackingValidator::StateExtractMap ParserPackingValidator::get_extracts(
    const Field* f) const {
    StateExtractMap rst;
    if (!parser_i.field_to_extracts.count(f)) return rst;
    for (const auto& extract : parser_i.field_to_extracts.at(f)) {
        rst[parser_i.extract_to_state.at(extract)].push_back(extract);
    }
    return rst;
}

bool ParserPackingValidator::allow_clobber(const Field* f) const {
    if (f->is_ignore_alloc() || f->is_padding()) return true;
    const bool parser_def = parser_i.field_to_extracts.count(f) || f->pov || f->isGhostField();
    // TODO(yumin): parser_error?
    return !parser_def && !parser_zero_init(f) && !f->is_invalidate_from_arch();
}

// XXX(yumin): strided header fields are handled in the same way as normal fields,
// but in the old allocator, strided header fields are skipped in these checks.
// TODO(yumin): enable strict mode.
// TODO(yumin): w container half-word write, future optimization.
// TODO(yumin): a is clear-on-write and b is okay to be 0 after the state.
const AllocError* ParserPackingValidator::will_buf_extract_clobber_the_other(
    const FieldSlice& fs, const StateExtract& state_extract, const int cont_idx,
    const FieldSlice& other_fs, const StateExtractMap& other_extracts,
    const int other_cont_idx, const boost::optional<Container>& c) const {
    // TODO(yumin): support W-sized container fancy 2 half-word packing.
    const bool half_word_extract = (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
)
        && c && c->type().size() == PHV::Size::b32;
    if (half_word_extract) {
        LOG5("half_word_extract is possible but not implemented.");
    }
    auto* err = new AllocError(ErrorCode::CONTAINER_PARSER_PACKING_INVALID);
    const auto* state = state_extract.first;
    const auto* extract = state_extract.second;
    const auto* parser = parser_i.state_to_parser.at(state);
    const auto& buf_range = slice_extract_range(fs, extract);
    LOG5("check if " << extract << " in " << state->name
         << " will clobber the other: " << other_fs);

    // For extracts in the same state, other input buffer offsets need to be the same as their
    // PHV container offset: must be extracted together in the same state.
    if (other_extracts.count(state)) {
        for (const auto& other_extract : other_extracts.at(state)) {
            if (other_extract->source->is<IR::BFN::PacketRVal>()) {
                const auto& other_buf_range = slice_extract_range(other_fs, other_extract);
                if (!(other_buf_range.hi - buf_range.hi == cont_idx - other_cont_idx)) {
                    *err << "cannot pack " << fs << " with " << other_fs << " because in state "
                         << state->name << " the former " << "slice is extracted from "
                         << ": " << buf_range << ", but " << "the latter is "
                         << other_buf_range << ", which is not consistent with "
                         << "their allocation: former@" << cont_idx
                         << ", other@" << other_cont_idx;
                    return err;
                }
            } else {
                // XXX(yumin): This if check is not required! Remove to always return an error
                // when we transition to strict mode.
                if (!phv_i.must_alloc_same_container(fs, other_fs)) {
                    *err << "cannot pack " << fs << " with " << other_fs << " because in state "
                         << state->name << " the former "
                         << "slice is extracted from "
                         << ": " << buf_range << ", but "
                         << "the latter has " << other_extract;
                    return err;
                }
            }
        }
    }

    // XXX(yumin): THIS is not required! BUT there are some P4 tests in our CI
    // that are incorrect: the manual extraction they wrote will corrupt other
    // fields! Example:
    // (1) compile_only/p4c-2035-name.p4
    // cannot pack
    //     ingress::Bufalo.Quinhagak.Bowden<6>
    //     ingress::Bufalo.Quinhagak.Madawaska<2>
    // because the former slice is extracted in state ingress::Lugert
    // but the latter is not extracted in that state.
    // TODO(yumin): we should disallow these behaviors^, and remove this check,
    // unless there is some fancy way to bypass it?
    if (phv_i.must_alloc_same_container(fs, other_fs)) {
        LOG5("Packing is unavoidable.");
        return (AllocError*)nullptr;
    }

    // This extract will not clobber bits of others only when
    // 1. if the other field is extracted in the same way in this state, then
    //    a. all other extracts are mutex.
    // 2. if the other field is not extracted in this state
    //    a. the other field cannot be parser zero initialized.
    //    b. all other extracts are mutex.
    if (!other_extracts.count(state) && parser_zero_init(other_fs.field())) {
        *err << "cannot pack " << fs << " with " << other_fs << " because the former "
             << "slice is extracted in " << state->name << ": " << extract << ", but "
             << "the latter field requires parser zero initialization.";
        return err;
    }
    for (const auto& other_state_extract : other_extracts) {
        const auto* other_state = other_state_extract.first;
        if (other_state == state) continue;
        const auto* other_parser = parser_i.state_to_parser.at(other_state);
        LOG5("Check extract: " << other_state->name << ": " << other_state_extract.second);
        if (other_parser != parser) {
            continue;
        }
        if (!parser_info_i.graph(parser).is_mutex(state, other_state)) {
            *err << "cannot pack " << fs << " with " << other_fs << " because the former "
                 << "slice is extracted in " << state->name << ": " << extract << ", but "
                 << "the latter is extracted in this non-mutex state: " << other_state->name;
            return err;
        }
    }
    return (AllocError*)nullptr;
};

const AllocError* ParserPackingValidator::will_a_extracts_clobber_b(
    const FieldSliceStart& a, const FieldSliceStart& b, const boost::optional<Container>& c) const {
    const auto& a_fs = a.first;
    const auto& b_fs = b.first;
    const int a_idx = a.second;
    const int b_idx = b.second;
    const auto a_extracts = get_extracts(a_fs.field());
    const auto b_extracts = get_extracts(b_fs.field());
    // because a is fine-sliced, each parser state will have at most 1 extract to the slice,
    // we do not need to check extract withinthe a_extracts,
    for (const auto& state_extracts : a_extracts) {
        // extractions will set container validity bit to 1 (including const), so we cannot
        // pack is_invalidate_from_arch with any extracted field.
        if (b.first.field()->is_invalidate_from_arch()) {
            auto* err = new AllocError(ErrorCode::CONTAINER_PARSER_PACKING_INVALID);
            *err << "cannot pack with invalidate from arch field: " << b.first;
            return err;
        }
        if (allow_clobber(b_fs.field())) break;
        for (const auto& extract : state_extracts.second) {
            StateExtract state_extract{state_extracts.first, extract};
            // only extract from input buffer will clobber bits.
            if (!state_extract.second->source->is<IR::BFN::PacketRVal>()) {
                continue;
            }
            auto* err =
                will_buf_extract_clobber_the_other(
                        a_fs, state_extract, a_idx, b_fs, b_extracts, b_idx, c);
            if (err) {
                return err;
            }
        }
    }
    return nullptr;
}

const AllocError* ParserPackingValidator::can_pack(const FieldSliceStart& a,
                                                   const FieldSliceStart& b,
                                                   const boost::optional<Container>& c) const {
    if (phv_i.field_mutex()(a.first.field()->id, b.first.field()->id)) {
        LOG5("field_mutex is true: " << a.first << " and " << b.first);
        return nullptr;
    }
    if (auto* err = will_a_extracts_clobber_b(a, b, c)) {
        return err;
    } else if (auto* err = will_a_extracts_clobber_b(b, a, c)) {
        return err;
    } else {
        return nullptr;
    }
}

const AllocError* ParserPackingValidator::can_pack(const FieldSliceAllocStartMap& alloc,
                                                   const boost::optional<Container>& c) const {
    /// make sure that every pair of field slices can be packed.
    for (auto i = alloc.begin(); i != alloc.end(); ++i) {
        for (auto j = std::next(i); j != alloc.end(); ++j) {
            if (auto* err = can_pack(*i, *j, c)) {
                return err;
            }
        }
    }
    return nullptr;
}

}  // namespace v2
}  // namespace PHV
