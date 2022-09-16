#include "clot_candidate.h"

#include "bf-p4c/common/table_printer.h"
#include "field_slice_extract_info.h"

ClotCandidate::ClotCandidate(const ClotInfo& clotInfo,
                             const Pseudoheader* pseudoheader,
                             const std::vector<const FieldSliceExtractInfo*>& extract_infos,
                             bool afterAllocatedClot,
                             bool beforeAllocatedClot)
                             : pseudoheader(pseudoheader), extract_infos(extract_infos),
                               id(nextId++), afterAllocatedClot(afterAllocatedClot),
                               beforeAllocatedClot(beforeAllocatedClot) {
    unsigned offset = 0;
    unsigned idx = 0;

    if (pseudoheader != nullptr) {
        pov_bits = pseudoheader->pov_bits;
    } else {
        auto first_field = extract_infos.front()->slice()->field();
        pov_bits = clotInfo.fields_to_pov_bits_.at(first_field);
    }

    for (auto extract_info : extract_infos) {
        auto slice = extract_info->slice();

        if (clotInfo.is_modified(slice))
            modified_bits.setrange(offset, slice->size());

        if (clotInfo.is_checksum(slice))
            checksum_bits.setrange(offset, slice->size());

        if (clotInfo.is_readonly(slice))
            readonly_bits.setrange(offset, slice->size());

        if (clotInfo.is_unused(slice))
            unused_bits.setrange(offset, slice->size());

        if (clotInfo.can_start_clot(extract_info))
            can_start_indices_.push_back(idx);

        if (clotInfo.can_end_clot(extract_info))
            can_end_indices_.push_back(idx);

        offset += slice->size();
        idx++;
    }

    size_bits = offset;
    std::reverse(can_end_indices_.begin(), can_end_indices_.end());
}

ordered_set<const IR::BFN::ParserState*> ClotCandidate::states() const {
    return (*(extract_infos.begin()))->states();
}

gress_t ClotCandidate::thread() const {
    return (*Keys(state_bit_offsets()).begin())->thread();
}

const ordered_map<const IR::BFN::ParserState*, unsigned>&
ClotCandidate::state_bit_offsets() const {
    return (*(extract_infos.begin()))->state_bit_offsets();
}

unsigned ClotCandidate::bit_in_byte_offset() const {
    return (*(extract_infos.begin()))->bit_in_byte_offset();
}

const std::vector<const FieldSliceExtractInfo*>& ClotCandidate::extracts() const {
    return extract_infos;
}

const std::vector<unsigned>& ClotCandidate::can_start_indices() const {
    return can_start_indices_;
}

const std::vector<unsigned>& ClotCandidate::can_end_indices() const {
    return can_end_indices_;
}

const std::map<unsigned, StatePairSet>
ClotCandidate::byte_gaps(const CollectParserInfo& parserInfo, const ClotCandidate* other) const {
    return extract_infos.back()->byte_gaps(parserInfo, other->extract_infos.front());
}

const ClotCandidate* ClotCandidate::mark_adjacencies(bool afterAllocatedClot,
                                                     bool beforeAllocatedClot) const {
    afterAllocatedClot |= this->afterAllocatedClot;
    beforeAllocatedClot |= this->beforeAllocatedClot;

    if (afterAllocatedClot == this->afterAllocatedClot
            && beforeAllocatedClot == this->beforeAllocatedClot)
        return this;

    auto* result = new ClotCandidate(*this);
    result->afterAllocatedClot = afterAllocatedClot;
    result->beforeAllocatedClot = beforeAllocatedClot;
    return result;
}

bool ClotCandidate::operator<(const ClotCandidate& other) const {
    if (unused_bits.popcount() != other.unused_bits.popcount())
        return unused_bits.popcount() < other.unused_bits.popcount();

    if (readonly_bits.popcount() != other.readonly_bits.popcount())
        return readonly_bits.popcount() < other.readonly_bits.popcount();

    return id < other.id;
}

std::string ClotCandidate::print() const {
    std::stringstream out;

    out << "CLOT candidate " << id << ":" << std::endl;

    bool first_state = true;
    for (auto* state : states()) {
        if (first_state)
            out << "  states: ";
        else
            out << "          ";

        first_state = false;
        out << state->name << std::endl;
    }

    if (afterAllocatedClot)
        out << "  appears after  an allocated CLOT with 0-byte gap" << std::endl;
    if (beforeAllocatedClot)
        out << "  appears before an allocated CLOT with 0-byte gap" << std::endl;

    TablePrinter tp(out, {"Fields", "Bits", "Property"}, TablePrinter::Align::CENTER);

    int offset = 0;
    for (auto extract_info : extract_infos) {
        auto slice = extract_info->slice();

        std::stringstream bits;
        bits << slice->size() << " [" << offset << ".." << (offset + slice->size() - 1) << "]";

        std::string attr;
        if (checksum_bits.getbit(offset)) attr = "checksum";
        if (modified_bits.getbit(offset)) attr = "modified";
        else if (readonly_bits.getbit(offset)) attr = "read-only";
        else
            attr = "unused";

        tp.addRow({std::string(slice->shortString()), bits.str(), attr});

        offset += slice->size();
    }

    tp.addSep();
    tp.addRow({"Unused bits", std::to_string(unused_bits.popcount()), ""});
    tp.addRow({"Read-only bits", std::to_string(readonly_bits.popcount()), ""});
    tp.addRow({"Modified bits", std::to_string(modified_bits.popcount()), ""});
    tp.addRow({"Checksum bits", std::to_string(checksum_bits.popcount()), ""});
    tp.addRow({"Total bits", std::to_string(offset), ""});

    tp.print();

    return out.str();
}

unsigned ClotCandidate::nextId = 0;
