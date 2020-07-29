#include "field_slice_extract_info.h"

void FieldSliceExtractInfo::update(
    const IR::BFN::ParserState* state,
    unsigned state_bit_offset,
    unsigned max_packet_bit_offset
) {
    BUG_CHECK(!state_bit_offsets_.count(state),
              "Field %s is unexpectedly extracted multiple times in %2%",
              slice_->field()->name, state->name);

    auto& entry = *state_bit_offsets_.begin();
    BUG_CHECK(entry.second % 8 == state_bit_offset % 8,
              "Field %s determined to be CLOT-eligible, but has inconsistent bit-in-byte "
              "offsets in states %s and %s",
              slice_->field()->name,
              entry.first->name,
              state->name);

    BUG_CHECK(entry.first->thread() == state->thread(),
              "A FieldSliceExtractInfo for an %s extract of field %s is being updated with an "
              "extract in parser state %s, which comes from %s",
              toString(entry.first->thread()),
              slice_->field()->name,
              state->name,
              toString(state->thread()));

    state_bit_offsets_[state] = state_bit_offset;
    max_packet_bit_offset_ = std::max(max_packet_bit_offset_, max_packet_bit_offset);
}

ordered_set<const IR::BFN::ParserState*> FieldSliceExtractInfo::states() const {
    ordered_set<const IR::BFN::ParserState*> result;
    for (auto state : Keys(state_bit_offsets_)) result.insert(state);
    return result;
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_head_to_byte() const {
    auto trim_amt = (8 - bit_in_byte_offset()) % 8;
    auto size = slice_->size() - trim_amt;
    BUG_CHECK(size > 0, "Trimmed extract %1% to %2% bits", slice()->shortString(), size);
    return trim(0, size);
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_tail_to_byte() const {
    auto trim_amt = (bit_in_byte_offset() + slice_->size()) % 8;
    return trim_tail_bits(trim_amt);
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_tail_to_max_clot_pos() const {
    auto max_pos = max_packet_bit_offset_ + slice_->size();
    int trim_amt = max_pos - Device::pardeSpec().bitMaxClotPos();
    if (trim_amt <= 0) {
        // No need to trim.
        return this;
    }

    auto result = trim_tail_bits(trim_amt);
    return result;
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_tail_bits(int trim_amt) const {
    auto start_idx = trim_amt;
    auto size = slice_->size() - trim_amt;
    BUG_CHECK(size > 0, "Trimmed extract %1% to %2% bits", slice()->shortString(), size);
    return trim(start_idx, size);
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim(int start_idx, int size) const {
    BUG_CHECK(start_idx >= 0,
              "Attempted to trim an extract of %s to a negative start index: %d",
              slice_->shortString(), start_idx);

    auto cur_size = slice_->size();
    BUG_CHECK(cur_size >= start_idx + size - 1,
              "Attempted to trim an extract of %s to a sub-slice larger than the original "
              "(start_idx = %d, size = %d)",
              slice_->shortString(), start_idx, size);

    if (start_idx == 0 && cur_size == size) return this;

    auto max_packet_bit_offset = max_packet_bit_offset_ + (cur_size - start_idx - size);
    ordered_map<const IR::BFN::ParserState*, unsigned> state_bit_offsets;
    for (auto& entry : state_bit_offsets_) {
        auto& state = entry.first;
        auto state_bit_offset = entry.second;

        state_bit_offsets[state] = state_bit_offset + (cur_size - start_idx - size);
    }

    auto range = slice_->range().shiftedByBits(start_idx).resizedToBits(size);
    auto slice = new PHV::FieldSlice(slice_->field(), range);
    return new FieldSliceExtractInfo(state_bit_offsets, max_packet_bit_offset, slice);
}

std::vector<const FieldSliceExtractInfo*>*
FieldSliceExtractInfo::remove_conflicts(const CollectParserInfo& parserInfo,
                                        const ClotCandidate* candidate) const {
    const int GAP_SIZE = 8 * Device::pardeSpec().byteInterClotGap();

    int candidate_size = candidate->size_bits;
    int extract_size = slice()->size();

    // For each parser state in which this field slice is extracted, and each parser state
    // corresponding to the candidate, each path through the parser yields a possibly different
    // shift amount to get from the parser state of the extract to that of the candidate, so the
    // candidate can appear in a few different positions relative to the extract. Go through the
    // various parser states and shift amounts and figure out which bits conflict.
    //
    // Using coordinates relative to the start of the extract, for each shift amount, the candidate
    // starts at bit (shift + candidate_offset - extract_offset). So, each shift amount results in
    // a conflict with the bits in the interval
    //
    //   [shift + candidate_offset - extract_offset - GAP_SIZE,
    //    shift + candidate_offset - extract_offset + candidate_size + GAP_SIZE - 1].
    //
    // So, we have a conflict for shift amounts in the interval
    //
    //   [extract_offset - candidate_offset - candidate_size - GAP_SIZE + 1,
    //    extract_offset + extract_size - candidate_offset + GAP_SIZE - 1].

    // Tracks which bits in the extract conflict with the candidate. Indices are in field order,
    // which is the opposite of packet order.
    bitvec conflicting_bits;

    for (auto& extract_entry : state_bit_offsets()) {
        auto& extract_state = extract_entry.first;
        int extract_offset = extract_entry.second;

        for (auto& candidate_entry : candidate->state_bit_offsets()) {
            auto& candidate_state = candidate_entry.first;
            int candidate_offset = candidate_entry.second;

            auto shift_amounts = parserInfo.get_all_shift_amounts(extract_state, candidate_state);

            int lower_bound = extract_offset - candidate_offset - candidate_size - GAP_SIZE + 1;
            int upper_bound = extract_offset + extract_size - candidate_offset + GAP_SIZE - 1;

            for (auto it = shift_amounts->lower_bound(lower_bound);
                 it != shift_amounts->end() && *it <= upper_bound;
                 ++it) {
                auto shift = *it;

                auto conflict_start =
                    std::max(0, shift + candidate_offset - extract_offset - GAP_SIZE);
                auto conflict_end =
                    std::min(extract_size - 1,
                             shift + candidate_offset - extract_offset
                                 + candidate_size + GAP_SIZE - 1);
                auto conflict_size = conflict_end - conflict_start + 1;

                // NB: conflict_start and conflict_end are in packet coordinates, but
                // conflicting_bits uses field coordinates, so we do the conversion here.
                conflicting_bits.setrange(extract_size - conflict_end - 1, conflict_size);
            }
        }
    }

    if (!conflicting_bits.popcount()) return new std::vector<const FieldSliceExtractInfo*>({this});

    auto result = new std::vector<const FieldSliceExtractInfo*>();

    // Scan through conflicting_bits and build our results list.
    int start_idx = -1;
    for (int idx = extract_size - 1; idx >= 0; --idx) {
        if (start_idx != -1 && conflicting_bits[idx]) {
            // Finished a chunk of non-conflicts.
            result->push_back(trim(idx + 1, start_idx - idx));
            start_idx = -1;
        }

        if (start_idx == -1 && !conflicting_bits[idx]) {
            // Starting a new chunk of non-conflicts.
            start_idx = idx;
        }
    }

    if (start_idx != -1) {
        // Add a final chunk of non-conflicts.
        result->push_back(trim(0, start_idx + 1));
    }

    return result;
}