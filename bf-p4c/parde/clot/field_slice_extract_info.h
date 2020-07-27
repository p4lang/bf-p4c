#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_FIELD_SLICE_EXTRACT_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_FIELD_SLICE_EXTRACT_INFO_H_

#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/ordered_map.h"
#include "clot_candidate.h"

/// Holds information relating to a field slice's extract.
class FieldSliceExtractInfo {
    friend class GreedyClotAllocator;

    /// The parser states in which the field slice is extracted, mapped to the field slice's offset
    /// (in bits) from the start of the packet.
    // Invariant: all offsets here are congruent, modulo 8.
    ordered_map<const IR::BFN::ParserState*, unsigned> state_bit_offsets_;

    /// The field slice's maximum offset, in bits, from the start of the packet.
    unsigned max_packet_bit_offset_;

    /// The field slice itself.
    const PHV::FieldSlice* slice_;

 public:
    FieldSliceExtractInfo(
        ordered_map<const IR::BFN::ParserState*, unsigned> state_bit_offsets,
        unsigned max_packet_bit_offset,
        const PHV::Field* field) :
    FieldSliceExtractInfo(state_bit_offsets,
                          max_packet_bit_offset,
                          new PHV::FieldSlice(field)) {
    }

    FieldSliceExtractInfo(
        ordered_map<const IR::BFN::ParserState*, unsigned> state_bit_offsets,
        unsigned max_packet_bit_offset,
        const PHV::FieldSlice* slice) :
    state_bit_offsets_(state_bit_offsets),
    max_packet_bit_offset_(max_packet_bit_offset),
    slice_(slice) {
    }

    /// Updates this object for this field being extracted in a newly discovered parser state.
    ///
    /// @param state
    ///             the new parser state
    /// @param state_bit_offset
    ///             the field's bit offset from the beginning of @state
    /// @param max_packet_bit_offset
    ///             the maximum bit offset from the beginning of the packet of the field in the
    ///             given state
    void update(const IR::BFN::ParserState* state,
                unsigned state_bit_offset,
                unsigned max_packet_bit_offset);

    /// @return the parser states in which the field slice is extracted.
    ordered_set<const IR::BFN::ParserState*> states() const;

    /// @return the field slice's maximum offset, in bits, from the start of the packet.
    unsigned max_packet_bit_offset() const { return max_packet_bit_offset_; }

    /// @return the field slice's offset, in bits, from the start of each parser state in which the
    /// field is extracted.
    const ordered_map<const IR::BFN::ParserState*, unsigned>& state_bit_offsets() const {
        return state_bit_offsets_;
    }

    /// @return the bit offset of the field slice, relative to the given parser @state.
    unsigned state_bit_offset(const IR::BFN::ParserState* state) const {
        return state_bit_offsets_.at(state);
    }

    /// @return the field slice's bit-in-byte offset in the packet.
    unsigned bit_in_byte_offset() const {
        auto offset = *Values(state_bit_offsets_).begin();
        return offset % 8;
    }

    /// @return the field slice itself.
    const PHV::FieldSlice* slice() const { return slice_; }

    /// Trims the start of the extract so that it is byte-aligned.
    const FieldSliceExtractInfo* trim_head_to_byte() const;

    /// Trims the end of the extract so that it is byte-aligned.
    const FieldSliceExtractInfo* trim_tail_to_byte() const;

    /// Trims the end of the extract so that it does not extend past the maximum CLOT position.
    const FieldSliceExtractInfo* trim_tail_to_max_clot_pos() const;

 private:
    /// Trims the given number of bits off the end of the extract.
    const FieldSliceExtractInfo* trim_tail_bits(int size) const;

 public:
    /// Trims the extract to a sub-slice.
    ///
    /// @param start_idx The start of the new slice, relative to the start of the old slice.
    const FieldSliceExtractInfo* trim(int start_idx, int bits) const;

    /// Removes any bytes that conflict with the given @arg candidate, returning the resulting list
    /// of FieldSliceExtractInfo instances, in the order in which they appear in the packet. More
    /// than one instance can result if conflicting bytes occur in the middle of the extract.
    std::vector<const FieldSliceExtractInfo*>*
    remove_conflicts(const CollectParserInfo& parserInfo, const ClotCandidate* candidate) const;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_FIELD_SLICE_EXTRACT_INFO_H_ */
