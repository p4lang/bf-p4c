#include <boost/range/adaptor/reversed.hpp>

#include <array>
#include <vector>
#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/device.h"
#include "bf-p4c/logging/logging.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "clot_info.h"
#include "clot_candidate.h"
#include "field_slice_extract_info.h"

boost::optional<nw_bitrange> ClotInfo::field_range(const IR::BFN::ParserState* state,
                                                   const PHV::Field* field) const {
    BUG_CHECK(field_to_parser_states_.count(field),
              "Field %1% is never extracted from the packet",
              field->name);
    BUG_CHECK(field_to_parser_states_.at(field).count(state),
              "Parser state %1% does not extract %2%",
              state->name, field->name);

    if (field_range_.count(state) && field_range_.at(state).count(field))
        return field_range_.at(state).at(field);

    return boost::optional<nw_bitrange>{};
}

boost::optional<unsigned> ClotInfo::offset(const IR::BFN::ParserState* state,
                                           const PHV::Field* field) const {
    if (auto range = field_range(state, field))
        return range->lo;

    return boost::optional<unsigned>{};
}

cstring ClotInfo::sanitize_state_name(cstring state_name, gress_t gress) const {
    // To have a stable lookup, we require state_name to be always prepended
    // by a gress

    std::stringstream ss;
    ss << gress;

    // It is likely the state name is that of a split state,
    // e.g. Original state = ingress::stateA
    //      Split state = ingress::stateA.$common.0
    // The parser_state_to_clots_ map is created before splitting and
    // carries the original state name. We regenerate the original state
    // name by stripping out the split name addition ".$common.0"

    std::string st(state_name.c_str());
    auto pos = st.find(".$");

    return (!state_name.startsWith(ss.str())  // if not prefixed with gress
        ? (ss.str() + "::") : "") + st.substr(0, pos);  // add the prefix, cut generated appendix
}

const Clot* ClotInfo::parser_state_to_clot(const IR::BFN::LoweredParserState *state,
                                           unsigned tag) const {
    auto state_name = sanitize_state_name(state->name, state->thread());
    auto& parser_state_to_clots = this->parser_state_to_clots(state->thread());

    if (parser_state_to_clots.count(state_name)) {
        auto& clots = parser_state_to_clots.at(state_name);
        auto it = std::find_if(clots.begin(), clots.end(), [&](const Clot* sclot) {
            return (sclot->tag == tag); });
        if (it != clots.end()) return *it;
    }

    return nullptr;
}

std::map<int, PHV::Container>
ClotInfo::get_overwrite_containers(const Clot* clot, const PhvInfo& phv) const {
    std::map<int, PHV::Container> containers;

    for (auto slice : clot->all_slices()) {
        auto field = slice->field();
        auto range = slice->range();
        if (slice_overwritten_by_phv(phv, clot, slice)) {
            field->foreach_alloc(range, PHV::AllocContext::DEPARSER, nullptr,
                    [&](const PHV::AllocSlice &alloc) {
                auto container = alloc.container();
                auto net_range = range.toOrder<Endian::Network>(field->size);
                int field_in_clot_offset = clot->bit_offset(slice) - net_range.lo;

                auto field_range = alloc.field_slice().toOrder<Endian::Network>(field->size);

                auto container_range =
                    alloc.container_slice().toOrder<Endian::Network>(alloc.container().size());

                auto container_offset = field_in_clot_offset - container_range.lo +
                                        field_range.lo;

                BUG_CHECK(container_offset % 8 == 0,
                          "CLOT %d container overwrite offset for %s is not byte-aligned",
                          clot->tag,
                          slice->shortString());

                auto container_offset_in_byte = container_offset / 8;

                if (containers.count(container_offset_in_byte)) {
                    auto other_container = containers.at(container_offset_in_byte);
                    BUG_CHECK(container == other_container,
                        "CLOT %d has more than one container at overwrite offset %d: "
                        "%s and %s",
                        clot->tag,
                        container_offset_in_byte,
                        container,
                        other_container);
                } else {
                    containers[container_offset_in_byte] = container;
                }
            });
        }
    }

    return containers;
}

std::map<int, const PHV::Field*> ClotInfo::get_csum_fields(const Clot* clot) const {
    std::map<int, const PHV::Field*> csum_fields;

    for (auto f : clot->csum_fields()) {
        auto offset = clot->byte_offset(new PHV::FieldSlice(f));
        if (csum_fields.count(offset)) {
            auto other_field = csum_fields.at(offset);
            BUG_CHECK(false,
                "CLOT %d has more than one checksum field at overwrite offset %d: %s and %s",
                f->name, other_field->name);
        }

        csum_fields[offset] = f;
    }

    return csum_fields;
}

void ClotInfo::merge_parser_states(gress_t gress, cstring dst_state_name, cstring src_state_name) {
    auto src_name = sanitize_state_name(src_state_name, gress);
    auto dst_name = sanitize_state_name(dst_state_name, gress);

    auto& state_to_clot = parser_state_to_clots(gress);
    if (!state_to_clot.count(src_name)) return;  // No clot extracts here

    // Bind clots from src to dst
    // dst might not even exist, but this will create appropriate record
    auto& src_clots = state_to_clot.at(src_name);
    for (auto *c : src_clots) {
        parser_state_to_clots(gress)[dst_name].insert(c);
        clot_to_parser_states_[c].first = gress;
        clot_to_parser_states_[c].second.insert(dst_name);
    }
}

void ClotInfo::add_field(const PHV::Field* f, const IR::BFN::ParserRVal* source,
                         const IR::BFN::ParserState* state) {
    LOG4("adding " << f->name << " to " << state->name << " (source " << source << ")");
    parser_state_to_fields_[state].push_back(f);
    field_to_parser_states_[f][state] = source;

    if (auto rval = source->to<IR::BFN::PacketRVal>())
        field_range_[state][f] = rval->range;
}

void ClotInfo::compute_byte_maps() {
    for (auto kv : parser_state_to_fields_) {
        auto state = kv.first;
        auto& fields_in_state = kv.second;

        for (auto f : fields_in_state) {
            if (auto f_offset_opt = offset(state, f)) {
                unsigned f_offset = *f_offset_opt;

                unsigned start_byte =  f_offset / 8;
                unsigned end_byte = (f_offset + f->size - 1) / 8;

                for (unsigned i = start_byte; i <= end_byte; i++) {
                    field_to_byte_idx[state][f].insert(i);
                    byte_idx_to_field[state][i].insert(f);
                }
            }
        }
    }

    if (LOGGING(4)) {
        std::clog << "=====================================================" << std::endl;

        for (auto kv : field_to_byte_idx) {
            std::clog << "state: " << kv.first->name << std::endl;
            for (auto fb : kv.second) {
                std::clog << "  " << fb.first->name << " in byte";
                for (auto id : fb.second)
                    std::clog << " " << id;
                std::clog << std::endl;
            }
        }

        std::clog << "-----------------------------------------------------" << std::endl;

        for (auto kv : byte_idx_to_field) {
            std::clog << "state: " << kv.first->name << std::endl;
            for (auto bf : kv.second) {
                std::clog << "  Byte " << bf.first << " has:";
                for (auto f : bf.second)
                    std::clog << " " << f->name;
                std::clog << std::endl;
            }
        }

        std::clog << "=====================================================" << std::endl;
    }
}

void ClotInfo::add_clot(Clot* clot, ordered_set<const IR::BFN::ParserState*> states) {
    clots_.push_back(clot);

    std::set<cstring> state_names;
    for (auto* state : states) {
        auto state_name = sanitize_state_name(state->name, state->thread());
        state_names.insert(state_name);
        parser_state_to_clots_[clot->gress][state_name].insert(clot);
    }

    clot_to_parser_states_[clot] = {clot->gress, state_names};
}

// DANGER: This method assumes the parser graph is a DAG.
const ordered_set<const IR::BFN::ParserState*>* ClotInfo::find_full_states(
        const IR::BFN::ParserGraph* graph) const {
    auto root = graph->root;
    auto gress = root->thread();
    const auto MAX_LIVE_CLOTS = Device::pardeSpec().maxClotsLivePerGress();
    ordered_set<const IR::BFN::ParserState*>* result;

    // Find states that are part of paths on which the maximum number of live CLOTs are allocated.
    if (num_clots_allocated(gress) < MAX_LIVE_CLOTS) {
        result = new ordered_set<const IR::BFN::ParserState*>();
    } else {
        auto largest = find_largest_paths(parser_state_to_clots(gress), graph, root);
        BUG_CHECK(largest->first <= MAX_LIVE_CLOTS,
            "Packet has %d live CLOTs, when at most %d are allowed",
            largest->first,
            MAX_LIVE_CLOTS);

        result =
            largest->first < MAX_LIVE_CLOTS
                ? new ordered_set<const IR::BFN::ParserState*>()
                : largest->second;
    }

    // Enforcement of the CLOTs-per-state constraint is done in a later pass, during state
    // splitting.

    return result;
}

bool ClotInfo::is_used_in_multiple_checksum_update_sets(const PHV::Field* field) const {
     if (!field_to_checksum_updates_.count(field))
         return false;

      return field_to_checksum_updates_.at(field).size() > 1;

     // TODO it's probably still ok to allocate field to CLOT
     // if the checksum updates it involves in are such that
     // one's source list is a subset of the update?
}

bool ClotInfo::is_extracted_in_multiple_non_mutex_states(const PHV::Field* f) const {
    // If we have no extracts for the field (or no states that extract the field), then it's
    // vacuously true that all extracts are in mutually exclusive states.
    if (!field_to_parser_states_.count(f)) return false;

    auto& states_to_sources = field_to_parser_states_.at(f);
    if (states_to_sources.size() == 0) return false;

    // Collect the states in a set and check that they all come from the same parser.
    const IR::BFN::Parser* parser = nullptr;
    std::set<const IR::BFN::ParserState*> states;
    for (auto state : Keys(states_to_sources)) {
        states.insert(state);

        auto* cur_parser = parserInfo.parser(state);
        if (parser == nullptr) {
            parser = cur_parser;
            BUG_CHECK(parser, "An extract of %1% was associated with a null parser", f);
        }

        BUG_CHECK(parser == cur_parser,
                  "Extracts of %1% don't all come from the same parser",
                  f);
    }

    // See if these states are mutually exclusive.
    return !parserInfo.graph(parser).is_mutex(states);
}

bool ClotInfo::has_consistent_bit_in_byte_offset(const PHV::Field* field) const {
    if (!field_to_parser_states_.count(field))
        // Field not extracted, so vacuously true.
        return true;

    unsigned bit_in_byte_offset = 0;
    bool have_offset = false;
    for (auto& state : Keys(field_to_parser_states_.at(field))) {
        auto cur_bit_in_byte_offset = *offset(state, field) % 8;
        if (!have_offset) {
            bit_in_byte_offset = cur_bit_in_byte_offset;
            have_offset = true;
        }

        if (cur_bit_in_byte_offset != bit_in_byte_offset) return false;
    }

    return true;
}
bool ClotInfo::extracted_with_pov(const PHV::Field* field) const {
    if (!fields_to_pov_bits_.count(field))
        return true;
    for (auto pov : fields_to_pov_bits_.at(field)) {
        if (pov_extracted_without_fields.count(pov->field())) {
            return false;
        }
    }
    return true;
}

bool ClotInfo::can_be_in_clot(const PHV::Field* field) const {
    if (is_added_by_mau(field->header())) {
        LOG5("  Field " << field->name << " can't be in a CLOT: its header might be added by MAU");
        return false;
    }

    if (!field->emitted() && !is_checksum(field)) {
        LOG5("  Field " << field->name << " can't be in a CLOT: not emitted and not a checksum");
        return false;
    }

    if (is_used_in_multiple_checksum_update_sets(field)) {
        LOG5("  Field " << field->name << " can't be in a CLOT: it's involved in multiple "
             "checksum-update field lists");
        return false;
    }

    if (is_extracted_in_multiple_non_mutex_states(field)) {
        LOG5("  Field " << field->name << " can't be in a CLOT: it's extracted in multiple parser "
             "states");
        return false;
    }

    if (!extracts_full_width(field)) {
        LOG5("  Field " << field->name << " can't be in a CLOT: its full width is not extracted "
             "from the packet by the parser");
        return false;
    }

    if (!has_consistent_bit_in_byte_offset(field)) {
        LOG5("  Field " << field->name << " can't be in a CLOT: it has different bit-in-byte "
             "offsets in different parser states");
        return false;
    }

    if (!extracted_with_pov(field)) {
        LOG5(" Field " << field->name << " can't be in a CLOT: there is exists a path through "
             "the parser where POV bit of this field is set, but the field is not extracted");
        return false;
    }

    return true;
}

bool ClotInfo::can_start_clot(const FieldSliceExtractInfo* extract_info) const {
    auto slice = extract_info->slice();

    // Either the start of the slice is byte-aligned, or the slice contains a byte boundary.
    int offset_from_byte = extract_info->bit_in_byte_offset();
    if (offset_from_byte != 0 && slice->size() < 9 - offset_from_byte) {
        LOG6("  Can't start CLOT with " << slice->shortString() << ": not byte-aligned, and "
             "doesn't contain byte boundary");
        return false;
    }

    // Slice must not be modified.
    if (is_modified(slice)) {
        LOG6("  Can't start CLOT with " << slice->field()->name << ": is modified");
        return false;
    }

    // Slice must not be a checksum.
    if (is_checksum(slice)) {
        LOG6("  Can't start CLOT with " << slice->field()->name << ": is checksum");
        return false;
    }

    return true;
}

bool ClotInfo::can_end_clot(const FieldSliceExtractInfo* extract_info) const {
    auto slice = extract_info->slice();

    // Either the end of the slice is byte-aligned, or the slice contains a byte boundary.
    int offset_from_byte = (extract_info->bit_in_byte_offset() + slice->size()) % 8;
    if (offset_from_byte != 0 && slice->size() < offset_from_byte + 1) {
        LOG6("  Can't end CLOT with " << slice->shortString() << ": not byte-aligned, and "
             "doesn't contain byte boundary");
        return false;
    }

    // Slice must not be modified.
    if (is_modified(slice)) {
        LOG6("  Can't end CLOT with " << slice->field()->name << ": is modified");
        return false;
    }

    // Slice must not be a checksum.
    if (is_checksum(slice)) {
        LOG6("  Can't end CLOT with " << slice->field()->name << ": is checksum");
        return false;
    }

    // Slice must start before the maximum CLOT position.
    if (extract_info->max_packet_bit_offset() >= Device::pardeSpec().bitMaxClotPos()) {
        LOG6("  Can't end CLOT with " << slice->field()->name << ": start offset "
            << extract_info->max_packet_bit_offset() << " not less than "
            << Device::pardeSpec().bitMaxClotPos());
        return false;
    }

    return true;
}

bool ClotInfo::extracts_full_width(const PHV::Field* field) const {
    if (!field_to_parser_states_.count(field))
        return false;

    bool have_packet_extract = false;
    for (auto& entry : field_to_parser_states_.at(field)) {
        auto& state = entry.first;
        auto& source = entry.second;

        if (!source->to<IR::BFN::PacketRVal>()) return false;

        if (auto range = field_range(state, field)) {
            have_packet_extract = true;
            if (field->size != range->size()) return false;
        }
    }

    return have_packet_extract;
}

bool ClotInfo::is_checksum(const PHV::Field* field) const {
    return checksum_dests_.count(field);
}

bool ClotInfo::is_checksum(const PHV::FieldSlice* slice) const {
    return is_checksum(slice->field());
}

bool ClotInfo::is_modified(const PHV::Field* field) const {
    if (is_modified_.count(field)) return is_modified_.at(field);

    if (uses.is_written_mau(field)) return is_modified_[field] = true;

    // Tie off infinite recursion by first assuming that the field is not modified.
    is_modified_[field] = false;

    // Recursively check if the field is packed with a modified field in the same header.
    if (field_to_parser_states_.count(field)) {
        for (auto& entry : field_to_parser_states_.at(field)) {
            auto& state = entry.first;

            if (!field_to_byte_idx.count(state)) continue;
            auto byte_indices = field_to_byte_idx.at(state);

            if (!byte_indices.count(field)) continue;
            for (auto idx : byte_indices.at(field)) {
                for (auto other_field : byte_idx_to_field.at(state).at(idx)) {
                    if (field->header() == other_field->header() && is_modified(other_field)) {
                        return is_modified_[field] = true;
                    }
                }
            }
        }
    }

    // Recursively check if the field is aliased with a modified field.
    if (field_aliases_.count(field)) {
        // XXX(Jed): Treat all aliases as modified for now. For some reason, uses.is_written_mau()
        // is returning false for aliases that are written by MAU.
#ifdef __XXX_JED_ALIASES_NOT_WORKING
        for (auto alias : *(field_aliases_.at(field))) {
            if (is_modified(alias)) {
                return is_modified_[field] = true;
            }
        }
#else
        return is_modified_[field] = true;
#endif
    }

    return false;
}

bool ClotInfo::is_modified(const PHV::FieldSlice* slice) const {
    return is_modified(slice->field());
}

bool ClotInfo::is_readonly(const PHV::Field* field) const {
    return uses.is_used_mau(field) && !is_modified(field) && !is_checksum(field);
}

bool ClotInfo::is_readonly(const PHV::FieldSlice* slice) const {
    return is_readonly(slice->field());
}

bool ClotInfo::is_unused(const PHV::Field* field) const {
    return !uses.is_used_mau(field) && !is_modified(field) && !is_checksum(field);
}

bool ClotInfo::is_unused(const PHV::FieldSlice* slice) const {
    return is_unused(slice->field());
}

const std::set<const PHV::Field*>* ClotInfo::clot_eligible_fields() const {
    auto result = new std::set<const PHV::Field*>();
    for (auto entry : field_to_parser_states_) {
        auto field = entry.first;
        if (can_be_in_clot(field)) result->insert(field);
    }
    return result;
}

std::set<const Clot*, Clot::Less>* ClotInfo::fully_allocated(const PHV::FieldSlice* slice) const {
    auto allocated = allocated_slices(slice);
    if (!allocated) return nullptr;

    // Go through the CLOT allocation for the given slice and collect up the set of CLOTs. As
    // we do this, figure out which bits in the slice are CLOT-allocated.
    auto result = new std::set<const Clot*, Clot::Less>();
    bitvec clotted_bits;

    for (const auto& entry : *allocated) {
        const auto& cur_slice = entry.first;
        const auto& cur_clot = entry.second;

        auto clotted_range = cur_slice->range().intersectWith(slice->range());
        clotted_bits.setrange(clotted_range.lo, clotted_range.size());

        result->insert(cur_clot);
    }

    bitvec expected(slice->range().lo, slice->range().size());
    if (clotted_bits != expected) {
        // Whole slice not CLOT-allocated.
        return nullptr;
    }

    return result;
}

void ClotInfo::adjust_clots(const PhvInfo& phv) {
    std::vector<Clot*> clots;
    for (auto clot : clots_) {
        if (adjust(phv, clot)) {
            // Adjustment successful, so keep the CLOT.
            clots.push_back(clot);
        } else {
            // Adjustment resulted in an empty CLOT, so remove it.
            auto& pair = clot_to_parser_states_.at(clot);
            auto gress = pair.first;
            auto state_names = pair.second;
            clot_to_parser_states_.erase(clot);

            auto& parser_state_to_clots = this->parser_state_to_clots(gress);
            for (auto state_name : state_names) {
                auto& state_clots = parser_state_to_clots.at(state_name);
                state_clots.erase(clot);
                if (state_clots.empty()) parser_state_to_clots.erase(state_name);
            }
        }
    }

    clots_ = clots;
}

bool ClotInfo::adjust(const PhvInfo& phv, Clot* clot) {
    auto& all_slices = clot->all_slices();

    // Figure out how many bits are overwritten at the start of the CLOT.
    unsigned num_start_bits_overwritten = 0;
    for (auto slice : all_slices) {
        auto overwrite_mask = bits_overwritten(phv, clot, slice);
        int first_zero_idx = overwrite_mask.ffz(0);
        num_start_bits_overwritten += first_zero_idx;
        if (first_zero_idx < slice->size()) break;
    }

    BUG_CHECK(num_start_bits_overwritten % 8 == 0,
              "CLOT %d starts with %d overwritten bits, which is not byte-aligned",
              clot->tag, num_start_bits_overwritten);

    // Figure out how many bits are overwritten at the end of the CLOT.
    unsigned num_end_bits_overwritten = 0;
    if (num_start_bits_overwritten < clot->length_in_byte() * 8) {
        for (auto slice : boost::adaptors::reverse(all_slices)) {
            auto overwrite_mask = bits_overwritten<Endian::Little>(phv, clot, slice);
            int last_zero_idx = overwrite_mask.ffz(0);
            num_end_bits_overwritten += last_zero_idx;
            if (last_zero_idx < slice->size()) break;
        }
    }

    BUG_CHECK(num_end_bits_overwritten % 8 == 0,
              "CLOT %d ends with %d overwritten bits, which is not byte-aligned",
              clot->tag, num_end_bits_overwritten);

    crop(clot, num_start_bits_overwritten, num_end_bits_overwritten);

    return clot->length_in_byte() > 0;
}

void ClotInfo::crop(Clot* clot, unsigned num_bits, bool from_start) {
    if (num_bits == 0) return;

    unsigned num_bits_skipped = 0;
    std::vector<const PHV::FieldSlice*> cur_slices = clot->all_slices();
    if (!from_start) std::reverse(cur_slices.begin(), cur_slices.end());
    std::vector<const PHV::FieldSlice*> new_slices;
    for (auto slice : cur_slices) {
        if (num_bits_skipped == num_bits) {
            new_slices.push_back(slice);
            continue;
        }

        auto field = slice->field();
        num_bits_skipped += slice->size();

        if (num_bits_skipped <= num_bits) {
            // Remove current slice.
            continue;
        }

        // Replace with a sub-slice of the current slice. We better not have a checksum field,
        // since we can only overwrite whole checksum fields.
        BUG_CHECK(!clot->is_csum_field(field),
                  "Attempted to remove a slice of checksum field %s from CLOT %d",
                  field->name, clot->tag);

        auto new_size = num_bits_skipped - num_bits;

        auto cur_range = slice->range();
        auto shift_amt = from_start ? 0 : cur_range.size() - new_size;

        auto new_range = cur_range.shiftedByBits(shift_amt).resizedToBits(new_size);
        auto subslice = new PHV::FieldSlice(field, new_range);
        new_slices.push_back(subslice);

        num_bits_skipped = num_bits;
    }

    if (!from_start) std::reverse(new_slices.begin(), new_slices.end());
    clot->set_slices(new_slices);
}

void ClotInfo::crop(Clot* clot, unsigned start_bits, unsigned end_bits) {
    BUG_CHECK(start_bits + end_bits <= clot->length_in_byte() * 8,
              "Cropping %d bits from CLOT %d, which is only %d bits long",
              start_bits + end_bits, clot->tag, clot->length_in_byte() * 8);

    crop(clot, start_bits, true);
    crop(clot, end_bits, false);
}

bool ClotInfo::slice_overwritten(const PhvInfo& phv,
                                 const Clot* clot,
                                 const PHV::FieldSlice* slice) const {
    return clot_covers_slice(clot, slice) && !bits_overwritten(phv, clot, slice).empty();
}

bool ClotInfo::slice_overwritten_by_phv(const PhvInfo& phv,
                                        const Clot* clot,
                                        const PHV::FieldSlice* slice) const {
    return clot_covers_slice(clot, slice) && !bits_overwritten_by_phv(phv, clot, slice).empty();
}

template <Endian Order>
bitvec ClotInfo::bits_overwritten(const PhvInfo& phv,
                                  const Clot* clot,
                                  const PHV::FieldSlice* slice) const {
    if (is_checksum(slice->field())) {
        bitvec result;
        result.setrange(0, slice->size());
        return result;
    }

    return bits_overwritten_by_phv<Order>(phv, clot, slice);
}

template <Endian Order>
bitvec ClotInfo::bits_overwritten_by_phv(const PhvInfo& phv,
                                         const Clot* clot,
                                         const PHV::FieldSlice* slice) const {
    bitvec result;
    if (is_checksum(slice->field())) return result;

    const auto* field = slice->field();
    const auto& slice_range = slice->range();
    field->foreach_alloc(slice_range, PHV::AllocContext::DEPARSER, nullptr,
            [&](const PHV::AllocSlice& alloc) {
        // The container overwrites the CLOT if we were given a slice of a modified field.
        bool container_overwrites = is_modified(field);

        // Handle other cases in which the container overwrites the CLOT.
        //
        // We can ignore any slice allocated to the container if that allocated slice satisfies any
        // of the following conditions:
        //
        //   - The given slice and the allocated slice are from mutually exclusive fields.
        //   - The given slice and the allocated slice from different fields, and those fields are
        //     allocated to overlapping ranges in the container.
        //
        // Otherwise, we know one of the following is true, in which case, the container overwrites
        // the CLOT if the CLOT does not completely cover the allocated slice.
        //
        //   - The given slice and the allocated slice are from the same field.
        //   - The given slice and the allocated slice are from different non-mutually-exclusive
        //     fields, and those fields are allocated to non-overlapping ranges in the container.
        if (!container_overwrites) {
            // Get the current container and figure out which bits of the container are occupied by
            // the field of the slice we were given.
            auto container = alloc.container();
            auto occupied_bits =
                phv.bits_allocated(container, field, PHV::AllocContext::DEPARSER);

            // Go through the analysis described above.
            for (const auto& alloc_slice : phv.get_slices_in_container(container)) {
                const auto* other_field = alloc_slice.field();

                // Ignore if field and other_field are mutually exclusive.
                if (phv.isFieldMutex(field, other_field)) continue;

                // Ignore if field and other_field are different, and alloc_slice overlaps with
                // occupied_bits in the container.
                auto other_occupied =
                    phv.bits_allocated(container, other_field, PHV::AllocContext::DEPARSER);
                if (field != other_field && !(occupied_bits & other_occupied).empty()) continue;

                // Container overwrites the CLOT if the CLOT doesn't completely cover the allocated
                // slice.
                const auto* other_slice = new PHV::FieldSlice(other_field,
                                                              alloc_slice.field_slice());
                container_overwrites = !clot_covers_slice(clot, other_slice);
                if (container_overwrites) break;
            }
        }

        if (!container_overwrites) return;

        auto overwrite_range = alloc.field_slice().intersectWith(slice_range);
        overwrite_range = overwrite_range.shiftedByBits(-slice_range.lo);
        auto normalized_overwrite_range = overwrite_range.toOrder<Order>(slice_range.size());

        result.setrange(normalized_overwrite_range.lo, normalized_overwrite_range.size());
    });

    return result;
}

bool ClotInfo::is_added_by_mau(cstring h) const {
    return headers_added_by_mau_.count(h);
}

std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>*
ClotInfo::slice_clots(const PHV::FieldSlice* slice) const {
    auto result = new std::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>();
    auto field = slice->field();
    for (auto c : clots_) {
        auto fields_to_slices = c->fields_to_slices();
        if (!fields_to_slices.count(field)) continue;

        auto clot_slice = fields_to_slices.at(field);
        if (clot_slice->range().overlaps(slice->range()))
            (*result)[clot_slice] = c;
    }

    return result;
}

Clot* ClotInfo::whole_field_clot(const PHV::Field* field) const {
    for (auto c : clots_)
        if (c->has_slice(new PHV::FieldSlice(field)))
            return c;
    return nullptr;
}

bool ClotInfo::clot_covers_slice(const Clot* clot, const PHV::FieldSlice* slice) const {
    auto fields_to_slices = clot->fields_to_slices();
    auto field = slice->field();
    if (!fields_to_slices.count(field)) return false;

    auto clot_slice = fields_to_slices.at(field);
    return clot_slice->range().contains(slice->range());
}

std::string ClotInfo::print(const PhvInfo* phvInfo) const {
    std::stringstream out;

    unsigned total_unused_fields_in_clots = 0;
    unsigned total_unused_bits_in_clots = 0;
    unsigned total_bits = 0;

    std::set<int> unaligned_clots;

    out << std::endl;
    for (auto gress : (gress_t[2]) {INGRESS, EGRESS}) {
        out << "CLOT Allocation (" << toString(gress) << "):" << std::endl;
        TablePrinter tp(out, {"CLOT", "Fields", "Bits", "Property"},
                              TablePrinter::Align::CENTER);

        for (auto entry : clot_to_parser_states()) {
            auto* c = entry.first;
            auto& pair = entry.second;
            if (gress != pair.first) continue;
            auto& states = pair.second;

            std::vector<std::vector<std::string>> rows;
            unsigned bits_in_clot = 0;

            for (auto f : c->all_slices()) {
                if (is_unused(f)) {
                    total_unused_fields_in_clots++;
                    total_unused_bits_in_clots += f->size();
                }

                std::stringstream bits;
                bits << f->size()
                     << " [" << c->bit_offset(f) << ".." << (c->bit_offset(f) + f->size() - 1)
                     << "]";

                bool is_phv = c->is_phv_field(f->field());
                bool is_csum = c->is_csum_field(f->field());
                bool is_phv_overwrite = phvInfo && slice_overwritten_by_phv(*phvInfo, c, f);

                std::string attr;
                if (is_phv || is_csum) {
                    attr += " (";
                    if (is_phv) attr += " phv";
                    if (is_phv_overwrite) attr += "*";
                    if (is_csum) attr += " csum";
                    attr += " ) ";
                }

                rows.push_back({"", std::string(f->shortString()), bits.str(), attr});
                bits_in_clot = std::max(bits_in_clot, c->bit_offset(f) + f->size());
            }

            total_bits += bits_in_clot;

            if (bits_in_clot % 8 != 0) unaligned_clots.insert(c->tag);
            unsigned bytes = bits_in_clot / 8;

            bool first_state = true;
            for (auto& state : states) {
                tp.addRow({first_state ? std::to_string(c->tag) : "",
                           "state " + std::string(state),
                           first_state ? (std::to_string(bytes) + " bytes") : "",
                           ""});
                first_state = false;
            }
            tp.addBlank();

            for (const auto& row : rows)
                tp.addRow(row);

            tp.addSep();
        }

        tp.addRow({"", "Total Bits", std::to_string(total_bits), ""});
        tp.print();
        out << std::endl;

        // Also report the maximum number of CLOTs a packet will use.
        for (auto& kv : parserInfo.graphs()) {
            auto& graph = kv.second;
            if (graph->root->gress != gress) continue;

            auto state_to_clots = parser_state_to_clots(gress);
            auto largest = find_largest_paths(state_to_clots, graph, graph->root);
            out << "  Packets will use up to " << largest->first << " CLOTs." << std::endl;
            out << "  The parser path(s) that will use the most CLOTs contain the following "
                << "states:" << std::endl;
            for (auto state : *largest->second) {
                int num_clots_in_state = 0;
                if (state_to_clots.count(state->name))
                    num_clots_in_state = state_to_clots.at(state->name).size();
                out << "    " << state->name << " (" << num_clots_in_state << " CLOTs)"
                    << std::endl;
            }
            out << std::endl;
        }
    }

    unsigned total_unused_fields = 0;
    unsigned total_unused_bits = 0;

    out << "All fields:" << std::endl;

    TablePrinter field_tp(out, {"Field", "Bits", "CLOTs", "Property"},
                               TablePrinter::Align::CENTER);
    for (auto kv : field_to_parser_states_) {
        auto& field = kv.first;
        auto& states_to_extracts = kv.second;

        // Ignore extracts that aren't always sourced from the packet.
        bool pkt_src = true;
        for (auto& kv2 : states_to_extracts) {
            auto& state = kv2.first;
            pkt_src = field_range(state, field) != boost::none;
            if (!pkt_src) break;
        }
        if (!pkt_src) continue;

        std::string attr;
        if (is_checksum(field)) {
            attr = "checksum";
        } else if (is_modified(field)) {
            attr = "modified";
        } else if (is_readonly(field)) {
            attr = "read-only";
        } else {
            attr = "unused";
            total_unused_fields++;
            total_unused_bits += field->size;
        }

        std::stringstream tags;
        bool first_clot = true;
        for (auto entry : *slice_clots(field)) {
            if (!first_clot) tags << ", ";
            tags << entry.second->tag;
            first_clot = false;
        }

        field_tp.addRow({std::string(field->name), std::to_string(field->size), tags.str(), attr});
    }

    field_tp.addSep();
    field_tp.addRow({"Unused fields", std::to_string(total_unused_fields), "", ""});
    field_tp.addRow({"Unused bits", std::to_string(total_unused_bits), "", ""});
    field_tp.addRow({"Unused CLOT-allocated fields",
                     std::to_string(total_unused_fields_in_clots), "", ""});
    field_tp.addRow({"Unused CLOT-allocated bits",
                     std::to_string(total_unused_bits_in_clots), "", ""});

    field_tp.print();

    // Bug-check.
    if (!unaligned_clots.empty()) {
        std::clog << out.str();
        std::stringstream out;
        bool first_tag = true;
        int count = 0;
        for (auto tag : unaligned_clots) {
            out << (first_tag ? "" : ", ") << tag;
            first_tag = false;
            count++;
        }
        BUG("CLOT%s %s not byte-aligned", count > 1 ? "s" : "", out.str());
    }

    return out.str();
}

void ClotInfo::add_alias(const PHV::Field* f1, const PHV::Field* f2) {
    std::set<const PHV::Field*>* f1_aliases =
        field_aliases_.count(f1) ? field_aliases_.at(f1) : nullptr;
    std::set<const PHV::Field*>* f2_aliases =
        field_aliases_.count(f2) ? field_aliases_.at(f2) : nullptr;

    if (f1_aliases == nullptr && f2_aliases == nullptr) {
        auto aliases = new std::set<const PHV::Field*>();
        aliases->insert(f1);
        aliases->insert(f2);
        field_aliases_[f1] = field_aliases_[f2] = aliases;
    } else if (f1_aliases != nullptr && f2_aliases != nullptr) {
        // Merge the two equivalence classes.
        for (auto field : *f2_aliases) {
            f1_aliases->insert(field);
            field_aliases_[field] = f1_aliases;
        }
    } else if (f1_aliases != nullptr) {
        f1_aliases->insert(f2);
        field_aliases_[f2] = f1_aliases;
    } else {
        f2_aliases->insert(f1);
        field_aliases_[f1] = f2_aliases;
    }
}

void ClotInfo::clear() {
    is_modified_.clear();
    parser_state_to_fields_.clear();
    field_to_parser_states_.clear();
    fields_to_pov_bits_.clear();
    field_to_byte_idx.clear();
    byte_idx_to_field.clear();
    checksum_dests_.clear();
    field_to_checksum_updates_.clear();
    clots_.clear();
    clot_to_parser_states_.clear();
    parser_state_to_clots_[INGRESS].clear();
    parser_state_to_clots_[EGRESS].clear();
    field_range_.clear();
    field_aliases_.clear();
    headers_added_by_mau_.clear();
    field_to_pseudoheaders_.clear();
    deparse_graph_.clear();
    Clot::tagCnt.clear();
    Pseudoheader::nextId = 0;
}

std::pair<unsigned, ordered_set<const IR::BFN::ParserState*>*>* ClotInfo::find_largest_paths(
        const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots,
        const IR::BFN::ParserGraph* graph,
        const IR::BFN::ParserState* state,
        std::map<const IR::BFN::ParserState*,
                 std::pair<unsigned,
                           ordered_set<const IR::BFN::ParserState*>*>*>* memo /*= nullptr*/) const {
    // Create the memoization table if needed, and make sure we haven't visited the state already.
    if (memo == nullptr) {
        memo = new std::map<const IR::BFN::ParserState*,
                             std::pair<unsigned, ordered_set<const IR::BFN::ParserState*>*>*>();
    } else if (memo->count(state)) {
        return memo->at(state);
    }

    // Recursively find the largest paths of the children, and aggregate the results.
    unsigned max_clots = 0;
    auto max_path_states = new ordered_set<const IR::BFN::ParserState*>();
    if (graph->successors().count(state)) {
        for (auto child : graph->successors().at(state)) {
            const auto result = find_largest_paths(parser_state_to_clots, graph, child, memo);
            if (result->first > max_clots) {
                max_clots = result->first;
                max_path_states->clear();
            }

            if (result->first == max_clots) {
                max_path_states->insert(result->second->begin(), result->second->end());
            }
        }
    }

    // Add the current state's result to the table and return.
    if (parser_state_to_clots.count(state->name))
        max_clots += parser_state_to_clots.at(state->name).size();
    max_path_states->insert(state);
    auto result =
        new std::pair<unsigned, ordered_set<const IR::BFN::ParserState*>*>(
            max_clots, max_path_states);
    return (*memo)[state] = result;
}

Visitor::profile_t CollectClotInfo::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    clotInfo.clear();

    // Configure logging for this visitor.
    if (BackendOptions().verbose > 0) {
        if (auto pipe = root->to<IR::BFN::Pipe>())
            log = new Logging::FileLog(pipe->id, "clot_allocation.log");
    }

    return rv;
}

bool CollectClotInfo::preorder(const IR::BFN::Extract* extract) {
    auto state = findContext<IR::BFN::ParserState>();

    if (auto field_lval = extract->dest->to<IR::BFN::FieldLVal>()) {
        if (auto f = phv.field(field_lval->field)) {
            clotInfo.add_field(f, extract->source, state);
        }
    }

    return true;
}

bool CollectClotInfo::preorder(const IR::BFN::EmitField* emit) {
    auto field = phv.field(emit->source->field);
    auto irPov = emit->povBit->field;

    le_bitrange slice;
    auto pov = phv.field(irPov, &slice);

    clotInfo.fields_to_pov_bits_[field].insert(new PHV::FieldSlice(pov, slice));
    return true;
}

bool CollectClotInfo::preorder(const IR::BFN::EmitChecksum* emit) {
    auto f = phv.field(emit->dest->field);
    clotInfo.checksum_dests_.insert(f);

    for (auto s : emit->sources) {
        auto src = phv.field(s->field->field);
        clotInfo.field_to_checksum_updates_[src].push_back(emit);
    }

    le_bitrange slice;
    auto pov = phv.field(emit->povBit->field, &slice);

    clotInfo.fields_to_pov_bits_[f].insert(new PHV::FieldSlice(pov, slice));

    return true;
}

void CollectClotInfo::postorder(const IR::BFN::Deparser* deparser) {
    // Used for deduplicating pseudoheaders. Contains the POV bits and fields of pseudoheaders
    // that have already been allocated, mapped to the allocated pseudoheader.
    std::map<std::pair<const PovBitSet,
                       const std::vector<const PHV::Field*>>,
             const Pseudoheader*> allocated;

    // The POV bits and field list for the current pseudoheader we are building.
    PovBitSet cur_pov_bits;
    std::vector<const PHV::Field*> cur_fields;

    // Tracks the graph node corresponding to the field or constant that was previously emitted by
    // the deparser.
    boost::optional<DeparseGraph::Node> prev_node =  // boost::none;  Compiler incorrectly warns.
                        boost::make_optional(false, DeparseGraph::Node{});  // Compiler is happy!

    // The deparse graph for the current gress.
    auto& deparse_graph = clotInfo.deparse_graph_[deparser->gress];

    for (auto emit : deparser->emits) {
        const PHV::Field* cur_field = nullptr;
        DeparseGraph::Node cur_node;

        if (auto emit_field = emit->to<IR::BFN::EmitField>()) {
            cur_field = phv.field(emit_field->source->field);
            cur_node = deparse_graph.addField(cur_field);
        } else if (auto emit_checksum = emit->to<IR::BFN::EmitChecksum>()) {
            cur_field = phv.field(emit_checksum->dest->field);
            cur_node = deparse_graph.addField(cur_field);
        } else if (auto emit_constant = emit->to<IR::BFN::EmitConstant>()) {
            // exclude from pseudoheader (below)
            // can potentially combine constants and fields with same
            // pov bit sets to create bigger pseudoheader? TODO
            cur_node = deparse_graph.addConst(emit_constant->constant);
        } else {
            BUG("Unexpected deparser emit: %1%", emit);
        }

        if (!cur_field) {
            // Current emit is a constant. Create a pseudoheader with current set of fields.
            add_pseudoheader(cur_pov_bits, cur_fields, allocated);
            cur_pov_bits.clear();
            cur_fields.clear();
        } else {
            // Current emit is a field. Create a pseudoheader if its pov set is different from
            // previous field.
            auto pov_bits = clotInfo.fields_to_pov_bits_.at(cur_field);

            if (cur_pov_bits != pov_bits) {
                add_pseudoheader(cur_pov_bits, cur_fields, allocated);
                cur_pov_bits = pov_bits;
                cur_fields.clear();
            }

            cur_fields.push_back(cur_field);
        }

        // Update the deparse graph with the current field and set things up for the next
        // iteration.
        if (prev_node) {
            deparse_graph.addEdge(*prev_node, cur_node);
        }
        prev_node = cur_node;
    }

    add_pseudoheader(cur_pov_bits, cur_fields, allocated);
}

void CollectClotInfo::add_pseudoheader(
    const PovBitSet pov_bits,
    const std::vector<const PHV::Field*> fields,
    std::map<std::pair<const PovBitSet,
                       const std::vector<const PHV::Field*>>,
             const Pseudoheader*>& allocated
) {
    if (fields.empty()) return;

    auto key = std::make_pair(pov_bits, fields);
    if (allocated.count(key)) return;

    // Have a new pseudoheader.
    auto pseudoheader = new Pseudoheader(pov_bits, fields);
    for (auto field : fields) {
        clotInfo.field_to_pseudoheaders_[field].insert(pseudoheader);
    }

    allocated[key] = pseudoheader;

    if (LOGGING(6)) {
        LOG6("Pseudoheader " << pseudoheader->id);
        std::stringstream out;
        out << "  POV bits: ";
        bool first = true;
        for (auto pov : pov_bits) {
            if (!first) out << ", ";
            first = false;
            out << pov->shortString();
        }
        LOG6(out.str());
        LOG6("  Fields:");
        for (auto field : fields)
            LOG6("    " << field->name);
    }
}

void CollectClotInfo::add_alias_field(const IR::Expression* alias) {
    const PHV::Field* aliasSource = nullptr;
    const PHV::Field* aliasDestination = nullptr;
    if (auto aliasMem = alias->to<IR::BFN::AliasMember>()) {
        aliasSource = phv.field(aliasMem->source);
        aliasDestination = phv.field(aliasMem);
    } else if (auto aliasSlice = alias->to<IR::BFN::AliasSlice>()) {
        aliasSource = phv.field(aliasSlice->source);
        aliasDestination = phv.field(aliasSlice);
    }
    BUG_CHECK(aliasSource, "Alias source for field %1% not found", alias);
    BUG_CHECK(aliasDestination, "Reference to alias field %1% not found", alias);
    clotInfo.add_alias(aliasSource, aliasDestination);
}

bool CollectClotInfo::preorder(const IR::MAU::Instruction* instruction) {
    // Make sure we have a call to "set".
    if (instruction->name != "set") return true;

    auto dst = instruction->operands.at(0);
    auto src = instruction->operands.at(1);

    // Make sure we are setting a header's validity bit.
    le_bitrange bitrange;
    auto dst_field = phv.field(dst, &bitrange);
    if (!dst_field || !dst_field->pov) return true;

    // Handle case where we are assigning a zero constant to the validity bit. Conservatively, we
    // assume that assigning a non-constant value to the POV bit can change its value arbitrarily.
    if (auto constant = src->to<IR::Constant>()) {
        if (constant->value == 0) return true;
    }

    clotInfo.headers_added_by_mau_.insert(dst_field->header());
    return true;
}

void CollectClotInfo::end_apply(const IR::Node* root) {
    clotInfo.compute_byte_maps();
    Logging::FileLog::close(log);
    Inspector::end_apply(root);
}

#if BAREFOOT_INTERNAL
void dump(std::ostream &out, const Clot &c) {
    for (auto &fs : c.fields_to_slices())
        out << fs.first->name << ": " << *fs.second << std::endl;
}
void dump(const Clot &c) { dump(std::cout, c); }
void dump(const Clot *c) { dump(std::cout, *c); }

void dump(const ClotInfo &ci) { std::cout << ci.print(); }
void dump(const ClotInfo *ci) { std::cout << ci->print(); }
#endif
