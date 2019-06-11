#include <boost/range/adaptor/reversed.hpp>

#include <array>
#include <vector>

#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/device.h"
#include "bf-p4c/lib/cmp.h"
#include "bf-p4c/logging/logging.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "clot_info.h"

class ClotCandidate : public LiftLess<ClotCandidate> {
 public:
    const Pseudoheader* pseudoheader;


 private:
    /// Information relating to the extracts of the candidate's field slices, ordered by position
    /// in the packet.
    const std::vector<const FieldSliceExtractInfo*> extract_infos;

    /// The indices into @ref extract_infos that correspond to field slices that can start a CLOT,
    /// in ascending order.
    std::vector<unsigned> can_start_indices_;

    /// The set of indices into @ref extract_infos that correspond to field slices that can end a
    /// CLOT, in descending order.
    std::vector<unsigned> can_end_indices_;

    /// Indicates which bits in the candidate are checksums, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec checksum_bits;

    /// Indicates which bits in the candidate are modified, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec modified_bits;

    /// Indicates which bits in the candidate are unused, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec unused_bits;

    /// Indicates which bits in the candidate are read-only, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec readonly_bits;

    static unsigned nextId;

 public:
    const unsigned id;

    /// The length of the candidate, in bits.
    unsigned size_bits;

    ClotCandidate(const ClotInfo& clotInfo,
                  const Pseudoheader* pseudoheader,
                  const std::vector<const FieldSliceExtractInfo*>& extract_infos);

    /// The parser state associated with this candidate's extracts.
    const IR::BFN::ParserState* state() const;

    /// The state-relative offset, in bits, of the first extract in the candidate.
    unsigned state_bit_offset() const;

    const std::vector<const FieldSliceExtractInfo*>& extracts() const;

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can
    /// start a CLOT, in ascending order.
    const std::vector<unsigned>& can_start_indices() const;

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can end
    /// a CLOT, in descending order.
    const std::vector<unsigned>& can_end_indices() const;

    /// Lexicographic order according to (number of unused bits, number of read-only bits, id).
    bool operator<(const ClotCandidate& other) const;

    std::string print() const;
};

/// Holds information relating to a field slice's extract.
class FieldSliceExtractInfo {
    friend class GreedyClotAllocator;

    /// The parser state in which the field slice is extracted.
    const IR::BFN::ParserState* state_;

    /// The field slice's offset, in bits, from the start of the parser state.
    const unsigned state_bit_offset_;

    /// The field slice itself.
    const PHV::FieldSlice* slice_;

 public:
    FieldSliceExtractInfo(const IR::BFN::ParserState* state,
                          unsigned state_bit_offset,
                          const PHV::Field* field)
        : FieldSliceExtractInfo(state, state_bit_offset, new PHV::FieldSlice(field)) { }

    FieldSliceExtractInfo(const IR::BFN::ParserState* state,
                          unsigned state_bit_offset,
                          const PHV::FieldSlice* slice)
        : state_(state), state_bit_offset_(state_bit_offset), slice_(slice) { }

    /// @return the parser state in which the field slice is extracted.
    const IR::BFN::ParserState* state() const { return state_; }

    /// @return the field slice's offset, in bits, from the start of the parser state.
    unsigned state_bit_offset() const { return state_bit_offset_; }

    /// @return the field slice itself.
    const PHV::FieldSlice* slice() const { return slice_; }

    /// Trims the start of the extract so that it is byte-aligned. Returns nullptr if this results
    /// in an empty slice.
    const FieldSliceExtractInfo* trim_head_to_byte() const;

    /// Trims the end of the extract so that it is byte-aligned. Returns nullptr if this results in
    /// an empty slice.
    const FieldSliceExtractInfo* trim_tail_to_byte() const;

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

std::string ClotInfo::print(const PhvInfo* phvInfo) const {
    std::stringstream out;

    unsigned total_unused_fields_in_clots = 0;
    unsigned total_unused_bits_in_clots = 0;
    unsigned total_bits = 0;

    std::set<int> unaligned_clots;
    for (auto gress : (gress_t[2]) {INGRESS, EGRESS}) {
        out << "CLOT Allocation (" << toString(gress) << "):" << std::endl;
        TablePrinter tp(out, {"CLOT", "Fields", "Bits", "Property"},
                              TablePrinter::Align::CENTER);

        for (auto entry : clot_to_parser_state()) {
            auto c = entry.first;
            auto pair = entry.second;
            if (gress != pair.first) continue;
            auto state = pair.second;

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

            tp.addRow({std::to_string(c->tag),
                       "state " + std::string(state),
                       std::to_string(bytes) + " bytes",
                       ""});
            tp.addBlank();

            for (const auto& row : rows)
                tp.addRow(row);

            tp.addSep();
        }

        tp.addRow({"", "Total Bits", std::to_string(total_bits), ""});
        tp.print();
        out << std::endl;
    }

    unsigned total_unused_fields = 0;
    unsigned total_unused_bits = 0;

    out << "All fields:" << std::endl;

    TablePrinter field_tp(out, {"Field", "Bits", "CLOTs", "Property"},
                               TablePrinter::Align::CENTER);
    for (auto kv : parser_state_to_fields_) {
        for (auto f : kv.second) {
            std::string attr;
            if (is_checksum(f)) {
                attr = "checksum";
            } else if (is_modified(f)) {
                attr = "modified";
            } else if (is_readonly(f)) {
                attr = "read-only";
            } else {
                attr = "unused";
                total_unused_fields++;
                total_unused_bits += f->size;
            }

            std::stringstream tags;
            bool first_clot = true;
            for (auto entry : *slice_clots(f)) {
                if (!first_clot) tags << ", ";
                tags << entry.second->tag;
                first_clot = false;
            }

            field_tp.addRow({std::string(f->name), std::to_string(f->size), tags.str(), attr});
        }
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

bool ClotInfo::can_be_in_clot(const PHV::Field* field) const {
    if (is_added_by_mau(field->header())) {
        LOG6("  Field " << field->name << " can't be in a CLOT: its header might be added by MAU");
        return false;
    }

    if (!field->deparsed() && !is_checksum(field)) {
        LOG6("  Field " << field->name << " can't be in a CLOT: not deparsed and not a checksum");
        return false;
    }

    if (is_used_in_multiple_checksum_update_sets(field)) {
        LOG6("  Field " << field->name << " can't be in a CLOT: it's involved in multiple "
             << "checksum-update field lists");
        return false;
    }

    if (is_extracted_in_multiple_states(field)) {
        LOG6("  Field " << field->name << " can't be in a CLOT: it's extracted in multiple parser "
             << "states");
        return false;
    }

    if (!extracts_full_width(field)) {
        LOG6("  Field " << field->name << " can't be in a CLOT: its full width is not extracted "
             << "by the parser");
        return false;
    }

    return true;
}

bool ClotInfo::can_start_clot(const FieldSliceExtractInfo* extract_info) const {
    auto slice = extract_info->slice();

    // Either the start of the slice is byte-aligned, or the slice contains a byte boundary.
    int offset_from_byte = extract_info->state_bit_offset() % 8;
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
    int offset_from_byte = (extract_info->state_bit_offset() + slice->size()) % 8;
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

    return true;
}

bool ClotInfo::extracts_full_width(const PHV::Field* field) const {
    if (!field_to_parser_states_.count(field))
        return false;

    for (auto state : field_to_parser_states_.at(field)) {
        BUG_CHECK(field_range_.count(state),
                  "No field range found for %s extracted in %s",
                  field->name, state->name);

        const auto& submap = field_range_.at(state);
        BUG_CHECK(submap.count(field),
                  "No field range found for %s extracted in %s",
                  field->name, state->name);

        if (field->size != submap.at(field).size()) return false;
    }

    return true;
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
        for (auto state : field_to_parser_states_.at(field)) {
            for (auto idx : field_to_byte_idx.at(state).at(field)) {
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

void ClotInfo::adjust_clots(const PhvInfo& phv) {
    std::vector<Clot*> clots;
    for (auto clot : clots_) {
        if (adjust(phv, clot)) {
            // Adjustment successful, so keep the CLOT.
            clots.push_back(clot);
        } else {
            // Adjustment resulted in an empty CLOT, so remove it.
            auto pair = clot_to_parser_state_.at(clot);
            auto gress = pair.first;
            auto state_name = pair.second;
            clot_to_parser_state_.erase(clot);

            auto& parser_state_to_clots = this->parser_state_to_clots(gress);
            auto& state_clots = parser_state_to_clots.at(state_name);
            state_clots.erase(clot);
            if (state_clots.empty()) parser_state_to_clots.erase(state_name);
        }
    }

    clots_ = clots;
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

    auto field = slice->field();
    auto slice_range = slice->range();
    field->foreach_alloc(slice_range, PHV::AllocContext::DEPARSER, nullptr,
            [&](const PHV::Field::alloc_slice& alloc) {
        // The container overwrites the slice if the container has a modified field or is not
        // completely covered by the CLOT.
        bool container_overwrites = false;
        auto container = alloc.container;
        for (auto alloc_slice : phv.get_slices_in_container(container)) {
            auto field = alloc_slice.field;
            auto slice = new PHV::FieldSlice(field, alloc_slice.field_bits());
            container_overwrites = !clot_covers_slice(clot, slice) || is_modified(field);
            if (container_overwrites) break;
        }

        if (!container_overwrites) return;

        auto overwrite_range = alloc.field_bits().intersectWith(slice_range);
        overwrite_range = overwrite_range.shiftedByBits(-slice_range.lo);
        auto normalized_overwrite_range = overwrite_range.toOrder<Order>(slice_range.size());

        result.setrange(normalized_overwrite_range.lo, normalized_overwrite_range.size());
    });

    return result;
}

bool ClotInfo::is_added_by_mau(cstring h) const {
    return headers_added_by_mau_.count(h);
}

std::map<int, PHV::Container>
ClotInfo::get_overwrite_containers(const Clot* clot, const PhvInfo& phv) const {
    std::map<int, PHV::Container> containers;

    for (auto slice : clot->all_slices()) {
        auto field = slice->field();
        auto range = slice->range();
        if (slice_overwritten_by_phv(phv, clot, slice)) {
            field->foreach_alloc(range, PHV::AllocContext::DEPARSER, nullptr,
                    [&](const PHV::Field::alloc_slice &alloc) {
                auto container = alloc.container;
                auto net_range = range.toOrder<Endian::Network>(field->size);
                int field_in_clot_offset = clot->bit_offset(slice) - net_range.lo;

                auto field_range = alloc.field_bits().toOrder<Endian::Network>(field->size);

                auto container_range =
                    alloc.container_bits().toOrder<Endian::Network>(alloc.container.size());

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

/// Finds the paths with the largest number of CLOTs allocated.
///
/// @arg memo is a memoization table that maps each visited parser state to the corresponding
///     result of the recursive call.
///
/// @return the maximum number of CLOTs allocated on paths starting at the given @arg state, paired
///     with the aggregate set of nodes on those maximal paths.
//
// DANGER: This function assumes the parser graph is a DAG.
std::pair<unsigned, std::set<const IR::BFN::ParserState*>*>* find_largest_paths(
        const std::map<cstring, std::set<const Clot*>>& parser_state_to_clots,
        const IR::BFN::ParserGraph* graph,
        const IR::BFN::ParserState* state,
        std::map<const IR::BFN::ParserState*,
                 std::pair<unsigned,
                           std::set<const IR::BFN::ParserState*>*>*>* memo = nullptr) {
    // Create the memoization table if needed, and make sure we haven't visited the state already.
    if (memo == nullptr) {
        memo = new std::map<const IR::BFN::ParserState*,
                             std::pair<unsigned, std::set<const IR::BFN::ParserState*>*>*>();
    } else if (memo->count(state)) {
        return memo->at(state);
    }

    // Recursively find the largest paths of the children, and aggregate the results.
    unsigned max_clots = 0;
    auto max_path_states = new std::set<const IR::BFN::ParserState*>();
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
        new std::pair<unsigned, std::set<const IR::BFN::ParserState*>*>(
            max_clots, max_path_states);
    return (*memo)[state] = result;
}

// DANGER: This method assumes the parser graph is a DAG.
const std::set<const IR::BFN::ParserState*>* ClotInfo::find_full_states(
        const IR::BFN::ParserGraph* graph) const {
    auto root = graph->root;
    auto gress = root->thread();
    const auto MAX_LIVE_CLOTS = Device::pardeSpec().maxClotsLivePerGress();
    std::set<const IR::BFN::ParserState*>* result;

    // Find states that are part of paths on which the maximum number of live CLOTs are allocated.
    if (num_clots_allocated(gress) < MAX_LIVE_CLOTS) {
        result = new std::set<const IR::BFN::ParserState*>();
    } else {
        auto largest = find_largest_paths(parser_state_to_clots(gress), graph, root);
        BUG_CHECK(largest->first <= MAX_LIVE_CLOTS,
            "Packet has %d live CLOTs, when at most %d are allowed",
            largest->first,
            MAX_LIVE_CLOTS);

        result =
            largest->first < MAX_LIVE_CLOTS
                ? new std::set<const IR::BFN::ParserState*>()
                : largest->second;
    }

    // Enforcement of the CLOTs-per-state constraint is done in a later pass, during state
    // splitting.

    return result;
}

bool ClotInfo::clot_covers_slice(const Clot* clot, const PHV::FieldSlice* slice) const {
    auto fields_to_slices = clot->fields_to_slices();
    auto field = slice->field();
    if (!fields_to_slices.count(field)) return false;

    auto clot_slice = fields_to_slices.at(field);
    return clot_slice->range().contains(slice->range());
}

void ClotInfo::clear() {
    is_modified_.clear();
    parser_state_to_fields_.clear();
    field_to_parser_states_.clear();
    field_to_byte_idx.clear();
    byte_idx_to_field.clear();
    checksum_dests_.clear();
    field_to_checksum_updates_.clear();
    clots_.clear();
    clot_to_parser_state_.clear();
    parser_state_to_clots_[INGRESS].clear();
    parser_state_to_clots_[EGRESS].clear();
    field_range_.clear();
    field_aliases_.clear();
    headers_added_by_mau_.clear();
    pseudoheaders_.clear();
    field_to_pseudoheaders_.clear();
    Clot::tagCnt.clear();
    Pseudoheader::nextId = 0;
}

int Pseudoheader::nextId = 0;

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_head_to_byte() const {
    auto trim_amt = (8 - state_bit_offset_ % 8) % 8;
    auto size = slice_->size() - trim_amt;
    return size > 0 ? trim(0, size) : nullptr;
}

const FieldSliceExtractInfo* FieldSliceExtractInfo::trim_tail_to_byte() const {
    auto trim_amt = (state_bit_offset_ + slice_->size()) % 8;
    auto start_idx = trim_amt;
    auto size = slice_->size() - trim_amt;
    return size > 0 ? trim(start_idx, size) : nullptr;
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

    auto state_bit_offset = state_bit_offset_ + (cur_size - start_idx - size);
    auto range = slice_->range().shiftedByBits(start_idx).resizedToBits(size);
    auto slice = new PHV::FieldSlice(slice_->field(), range);
    return new FieldSliceExtractInfo(state_, state_bit_offset, slice);
}

std::vector<const FieldSliceExtractInfo*>*
FieldSliceExtractInfo::remove_conflicts(const CollectParserInfo& parserInfo,
                                        const ClotCandidate* candidate) const {
    const int GAP_SIZE = 8 * Device::pardeSpec().byteInterClotGap();

    int candidate_offset = candidate->state_bit_offset();
    int candidate_size = candidate->size_bits;

    int extract_offset = state_bit_offset();
    int extract_size = slice()->size();

    auto shift_amounts = parserInfo.get_all_shift_amounts(state(), candidate->state());

    // Each path through the parser yields a possibly different shift amount to get from the parser
    // state of the extract to that of the candidate, so the candidate can appear in a few
    // different positions relative to the extract. Go through the various shift amounts
    // and figure out which bits conflict.
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

    int lower_bound = extract_offset - candidate_offset - candidate_size - GAP_SIZE + 1;
    int upper_bound = extract_offset + extract_size - candidate_offset + GAP_SIZE - 1;

    bool have_conflict = false;

    for (auto it = shift_amounts->lower_bound(lower_bound);
         it != shift_amounts->end() && *it <= upper_bound;
         ++it) {
        auto shift = *it;

        auto conflict_start =
            std::max(0,
                     shift + candidate_offset - extract_offset - GAP_SIZE);
        auto conflict_end =
            std::min(extract_size - 1,
                     shift + candidate_offset - extract_offset + candidate_size + GAP_SIZE - 1);
        auto conflict_size = conflict_end - conflict_start + 1;

        // NB: conflict_start and conflict_end are in packet coordinates, but conflicting_bits uses
        // field coordinates, so we do the conversion here.
        conflicting_bits.setrange(extract_size - conflict_end - 1, conflict_size);
        have_conflict = true;
    }

    if (!have_conflict) return new std::vector<const FieldSliceExtractInfo*>({this});

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

ClotCandidate::ClotCandidate(const ClotInfo& clotInfo,
                             const Pseudoheader* pseudoheader,
                             const std::vector<const FieldSliceExtractInfo*>& extract_infos)
                             : pseudoheader(pseudoheader), extract_infos(extract_infos),
                               id(nextId++) {
    unsigned offset = 0;
    unsigned idx = 0;
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

const IR::BFN::ParserState* ClotCandidate::state() const {
    return (*(extract_infos.begin()))->state();
}

unsigned ClotCandidate::state_bit_offset() const {
    return (*(extract_infos.begin()))->state_bit_offset();
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

bool ClotCandidate::operator<(const ClotCandidate& other) const {
    if (unused_bits.popcount() != other.unused_bits.popcount())
        return unused_bits.popcount() < other.unused_bits.popcount();

    if (readonly_bits.popcount() != other.readonly_bits.popcount())
        return readonly_bits.popcount() < other.readonly_bits.popcount();

    return id < other.id;
}

std::string ClotCandidate::print() const {
    std::stringstream out;

    out << "CLOT candidate " << id << " (state " << state()->name << "):" << std::endl;

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

/**
 * This implements a greedy CLOT-allocation algorithm, as described in
 * https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
 */
class GreedyClotAllocator : public Visitor {
    ClotInfo& clotInfo;
    const CollectParserInfo& parserInfo;
    Logging::FileLog* log = nullptr;

 public:
    explicit GreedyClotAllocator(ClotInfo& clotInfo,
                                 const CollectParserInfo& parserInfo) :
        clotInfo(clotInfo),
        parserInfo(parserInfo) { }

 private:
    typedef std::map<const Pseudoheader*,
                     std::map<const PHV::Field*, FieldSliceExtractInfo*>,
                     Pseudoheader::Less> FieldSliceExtractInfoMap;
    typedef std::set<const ClotCandidate*, ClotCandidate::Greater> ClotCandidateSet;

    /// Generates a FieldSliceExtractInfo object for each field that is extracted in the subgraph
    /// rooted at the given state, and can be part of a clot (@see ClotInfo::can_be_in_clot).
    ///
    /// Returns @arg result, a map from pseudoheaders to fields to their FieldSliceExtractInfo
    /// instances.
    ///
    /// This method assumes the graph is an unrolled DAG.
    //
    // Invariant: `state` is not an element of `visited`.
    FieldSliceExtractInfoMap* group_extracts(
            const IR::BFN::ParserGraph* graph,
            const IR::BFN::ParserState* state = nullptr,
            FieldSliceExtractInfoMap* result = nullptr,
            std::set<const IR::BFN::ParserState*>* visited = nullptr) {
        // Initialize parameters if needed.
        if (!state) state = graph->root;
        if (!result) result = new FieldSliceExtractInfoMap();
        if (!visited) visited = new std::set<const IR::BFN::ParserState*>();

        LOG6("Finding extracts in state " << state->name);
        visited->insert(state);

        // Find all extracts in the current state.
        if (clotInfo.field_range_.count(state)) {
            for (auto entry : clotInfo.field_range_.at(state)) {
                auto field = entry.first;
                const auto& bitrange = entry.second;

                if (!clotInfo.can_be_in_clot(field)) continue;

                BUG_CHECK(clotInfo.field_to_pseudoheaders_.count(field),
                          "Field %s determined to be CLOT-eligible, but is not extracted (no "
                          "pseudoheader information)",
                          field->name);

                auto fei = new FieldSliceExtractInfo(state,
                                                     static_cast<unsigned>(bitrange.lo),
                                                     field);
                for (auto pseudoheader : clotInfo.field_to_pseudoheaders_.at(field)) {
                    BUG_CHECK(!result->count(pseudoheader) ||
                              !result->at(pseudoheader).count(field),
                              "Field %s determined to be CLOT-eligible, but is extracted twice",
                              field->name);

                    (*result)[pseudoheader][field] = fei;
                }
            }
        }

        // Recurse with the unvisited successors of the current state, if any.
        if (graph->successors().count(state)) {
            for (auto succ : graph->successors().at(state)) {
                if (visited->count(succ)) continue;

                LOG6("Recursing with transition " << state->name << " -> " << succ->name);
                group_extracts(graph, succ, result, visited);
            }
        }

        return result;
    }

    /// Creates a CLOT candidate out of the given extracts, if possible, and adds the result to the
    /// given candidate set.
    ///
    /// Precondition: the extracts are a valid CLOT prefix.
    void try_add_clot_candidate(ClotCandidateSet* candidates,
                                const Pseudoheader* pseudoheader,
                                std::vector<const FieldSliceExtractInfo*>& extracts) const {
        // Trim the first extract so that it is byte-aligned.
        extracts[0] = extracts.front()->trim_head_to_byte();

        // Remove extracts until we find one that can end a CLOT.
        while (!extracts.empty() && !clotInfo.can_end_clot(extracts.back()))
            extracts.pop_back();

        // If we still have extracts, create a CLOT candidate out of those.
        if (!extracts.empty()) {
            // Trim the last extract so that it is byte-aligned. If we only have a single extract,
            // and this results in the extract being empty, then don't create a CLOT candidate.
            extracts.back() = extracts.back()->trim_tail_to_byte();
            if (extracts.size() == 1 && extracts[0] == nullptr) return;

            const ClotCandidate* candidate = new ClotCandidate(clotInfo, pseudoheader, extracts);
            candidates->insert(candidate);
            LOG6("  Created candidate");
            LOG6(candidate->print());
        }
    }

    /// A helper. Adds to the given @arg result any CLOT candidates that can be made from a given
    /// set of extracts into field slices that all belong to a given pseudoheader.
    void add_clot_candidates(
            ClotCandidateSet* result,
            const Pseudoheader* pseudoheader,
            const std::map<const PHV::Field*,
                           std::vector<const FieldSliceExtractInfo*>>& extract_map) const {
        // Invariant: `extracts` forms a valid prefix for a potential CLOT candidate. When
        // `extracts` is non-empty, `state` is the parser state for the potential CLOT
        // candidate, and `next_offset` is the expected state-relative offset for the next
        // field slice.
        std::vector<const FieldSliceExtractInfo*> extracts;
        const IR::BFN::ParserState* state = nullptr;
        unsigned next_offset = 0;

        LOG6("Finding CLOT candidates for pseudoheader " << pseudoheader->id);
        for (auto field : pseudoheader->fields) {
            LOG6("  Considering field " << field->name);

            if (!extract_map.count(field)) {
                if (extracts.empty()) {
                    LOG6("  Can't start CLOT with " << field->name << ": not extracted");
                } else {
                    // We have a break in contiguity. Create a new CLOT candidate, if possible, and
                    // set things up for the next candidate.
                    LOG6("  Contiguity break");
                    try_add_clot_candidate(result, pseudoheader, extracts);
                    extracts.clear();
                }

                continue;
            }

            for (auto extract_info : extract_map.at(field)) {
                if (!extracts.empty()
                        && (extract_info->state() != state
                            || extract_info->state_bit_offset() != next_offset)) {
                    // We have a break in contiguity. Create a new CLOT candidate, if possible, and
                    // set things up for the next candidate.
                    LOG6("  Contiguity break");
                    try_add_clot_candidate(result, pseudoheader, extracts);
                    extracts.clear();
                }

                if (extracts.empty()) {
                    // Starting a new candidate.
                    if (!clotInfo.can_start_clot(extract_info)) continue;

                    state = extract_info->state();
                    next_offset = extract_info->state_bit_offset();
                }

                // Add to the existing prefix.
                extracts.push_back(extract_info);
                auto slice = extract_info->slice();
                next_offset += slice->size();

                LOG6("  Added " << slice->shortString() << " to CLOT candidate prefix");
            }
        }

        // If possible, create a new CLOT candidate from the remaining extracts.
        if (!extracts.empty()) try_add_clot_candidate(result, pseudoheader, extracts);
    }

    // Precondition: all FieldSliceExtractInfo instances in the given map correspond to fields that
    // satisfy @ref ClotInfo::can_be_in_clot.
    //
    // This method's responsibility, then, is to ensure the following for each candidate:
    //   - A set of contiguous bits is extracted from the packet.
    //   - The aggregate set of extracted bits is byte-aligned in the packet.
    //   - All extracted field slices are contiguous.
    //   - No pair of extracted field slices have a deparserNoPack constraint.
    //   - Neither the first nor last field in the candidate is modified or is a checksum.
    //   - The extracts all come from the same parser state.
    ClotCandidateSet* find_clot_candidates(FieldSliceExtractInfoMap* extract_info_map) {
        auto result = new ClotCandidateSet();

        for (auto entry : *extract_info_map) {
            std::map<const PHV::Field*, std::vector<const FieldSliceExtractInfo*>> submap;
            for (auto subentry : entry.second) {
                submap[subentry.first].push_back(subentry.second);
            }

            add_clot_candidates(result, entry.first, submap);
        }

        return result;
    }

    /// Adjusts a CLOT candidate to account for the allocation of another (possibly the same)
    /// candidate.
    ClotCandidateSet* adjust_for_allocation(const ClotCandidate* to_adjust,
                                            const ClotCandidate* allocated) const {
        LOG6("Adjusting candidate " << to_adjust->id
             << " (state " << to_adjust->state()->name << ")");

        ClotCandidateSet* result = new ClotCandidateSet();

        // If the states are mutually exclusive, then no need to adjust.
        const auto& graph = parserInfo.graph(parserInfo.parser(allocated->state()));
        if (graph.is_mutex(to_adjust->state(), allocated->state())) {
            LOG6("  No need to adjust: states are mutually exclusive");
            result->insert(to_adjust);
            return result;
        }

        // Slow path: if the candidates conflict, delegate to add_clot_candidates.
        // Fast path: if the candidates do not conflict, then we just return a singleton containing
        //            the candidate that we are adjusting.
        bool conflict = false;
        std::map<const PHV::Field*, std::vector<const FieldSliceExtractInfo*>> extract_map;
        for (auto extract : to_adjust->extracts()) {
            auto non_conflicts = extract->remove_conflicts(parserInfo, allocated);
            conflict |= non_conflicts->empty();

            for (auto adjusted : *non_conflicts) {
                conflict |= extract != adjusted;
                extract_map[extract->slice()->field()].push_back(adjusted);
            }
        }

        if (!conflict) result->insert(to_adjust);
        else if (!extract_map.empty())
            add_clot_candidates(result, to_adjust->pseudoheader, extract_map);

        return result;
    }

    /// Resizes a CLOT candidate so that it fits into the maximum CLOT length.
    ///
    /// @return the resized CLOT candidate, or nullptr if resizing fails.
    //
    // We can be fancier here, but this just greedily picks the first longest subsequence of
    // extracts that fits the CLOT-allocation constraints.
    const ClotCandidate* resize(const ClotCandidate* candidate) const {
        const int MAX_SIZE = Device::pardeSpec().byteMaxClotSize() * 8;
        unsigned best_start_idx = 0;
        unsigned best_end_idx = 0;
        int best_size = 0;
        bool need_resize = false;

        const auto& extracts = candidate->extracts();
        for (auto start_idx : candidate->can_start_indices()) {
            auto start = extracts.at(start_idx)->trim_head_to_byte();

            // Find the rightmost end_idx that fits in the maximum CLOT size.
            //
            // We do this by taking start_bit_offset to be that of the last byte (or fraction of a
            // byte) in `start`, and finding the rightmost index whose offset lands within the
            // minimum CLOT size of start_bit_offset.

            int start_bit_offset =
                (start->state_bit_offset() + start->slice()->size() - 1) / 8 * 8;

            for (auto end_idx : candidate->can_end_indices()) {
                if (start_idx > end_idx) break;

                auto end = extracts.at(end_idx)->trim_tail_to_byte();
                int end_bit_offset = end->state_bit_offset();
                if (end_bit_offset - start_bit_offset >= MAX_SIZE) continue;

                int full_size = end_bit_offset + end->slice()->size() - start->state_bit_offset();

                int cur_size = std::min(MAX_SIZE, full_size);

                if (cur_size > best_size) {
                    best_start_idx = start_idx;
                    best_end_idx = end_idx;
                    best_size = cur_size;
                    need_resize = cur_size != full_size;
                }

                break;
            }

            if (best_size == MAX_SIZE) break;
        }

        if (best_size == 0) return nullptr;
        if (best_start_idx == 0 && best_end_idx == extracts.size() - 1 && !need_resize)
            return candidate;

        // Create the list of extracts for the resized candidate.
        auto resized = new std::vector<const FieldSliceExtractInfo*>();
        for (auto idx = best_start_idx ; idx <= best_end_idx; idx++)
            resized->push_back(extracts.at(idx));

        // Trim first and last extract to byte boundary.
        auto start = resized->front() = resized->front()->trim_head_to_byte();
        auto end = resized->back() = resized->back()->trim_tail_to_byte();

        // Trim last extract if we exceed the maximum CLOT length.
        int size = end->state_bit_offset() + end->slice()->size() - start->state_bit_offset();
        if (size > MAX_SIZE) {
            int trim_amount = size - MAX_SIZE;

            // Make sure we leave at least one bit in the extract, while maintaining byte
            // alignment.
            int end_size = end->slice()->size();
            if (end_size <= trim_amount) trim_amount = (end_size - 1) / 8 * 8;

            int new_end_start = trim_amount;
            int new_end_size = end_size - new_end_start;
            resized->back() = end = end->trim(new_end_start, new_end_size);
            size -= trim_amount;
        }

        // Trim the first extract if we still exceed the maximum CLOT length.
        if (size > MAX_SIZE) {
            int trim_amount = size - MAX_SIZE;
            int start_size = start->slice()->size();
            BUG_CHECK(start_size > trim_amount,
                      "Extract for %s is only %d bits, but need to trim %d bits to fit in CLOT",
                      start->slice()->shortString(), start_size, trim_amount);

            int new_start_size = start_size - trim_amount;
            resized->front() = start->trim(0, new_start_size);
        }

        auto result = new ClotCandidate(clotInfo, candidate->pseudoheader, *resized);
        LOG3("Resized candidate " << candidate->id << ":");
        LOG3(result->print());
        return result;
    }

    /// Uses a greedy algorithm to allocate the given candidates.
    void allocate(ClotCandidateSet* candidates) {
        const auto MAX_CLOTS_PER_GRESS = Device::pardeSpec().numClotsPerGress();

        // Invariant: all members of the candidate set can be allocated. That is, if we were to
        // allocate any single member, it would not violate any CLOT-allocation constraints.
        while (!candidates->empty()) {
            auto candidate = *(candidates->begin());

            // Resize the candidate before allocating.
            auto resized = resize(candidate);
            if (!resized) {
                // Resizing failed.
                LOG3("Couldn't fit candidate " << candidate->id << " into a CLOT");
                candidates->erase(candidate);
                continue;
            }

            candidate = resized;

            // Allocate the candidate.
            auto state = candidate->state();
            auto state_bit_offset = candidate->state_bit_offset();
            BUG_CHECK(state_bit_offset % 8 == 0,
                      "CLOT candidate is not byte-aligned\n%s", candidate->print());
            auto gress = state->thread();

            auto clot = new Clot(gress);
            LOG3("Allocating CLOT " << clot->tag << " to candidate " << candidate->id
                 << " (state " << state->name << ")");
            clotInfo.add_clot(clot, state);

            // Add field slices.
            int offset = 0;
            for (auto extract : candidate->extracts()) {
                auto slice = extract->slice();

                Clot::FieldKind kind;
                if (clotInfo.is_checksum(slice))
                    kind = Clot::FieldKind::CHECKSUM;
                else if (clotInfo.is_modified(slice))
                    kind = Clot::FieldKind::MODIFIED;
                else if (clotInfo.is_readonly(slice))
                    kind = Clot::FieldKind::READONLY;
                else
                    kind = Clot::FieldKind::UNUSED;

                if (LOGGING(4)) {
                    std::string kind_str;
                    switch (kind) {
                    case Clot::FieldKind::CHECKSUM:
                        kind_str = "checksum field"; break;
                    case Clot::FieldKind::MODIFIED:
                        kind_str = "modified phv field"; break;
                    case Clot::FieldKind::READONLY:
                        kind_str = "read-only phv field"; break;
                    case Clot::FieldKind::UNUSED:
                        kind_str = "field"; break;
                    }

                    LOG4("  Adding " << kind_str << " " << slice->shortString() << " at bit "
                         << offset);
                }
                clot->add_slice(kind, slice);

                offset += slice->size();
            }

            // Done allocating the candidate. Remove any candidates that would violate
            // CLOT-allocation limits, and adjust the rest to account for the inter-CLOT gap
            // requirement.
            auto new_candidates = new ClotCandidateSet();
            auto num_clots_allocated = clotInfo.num_clots_allocated(gress);
            BUG_CHECK(num_clots_allocated <= MAX_CLOTS_PER_GRESS,
                "%d CLOTs allocated in %s, when at most %d are allowed",
                num_clots_allocated,
                toString(gress),
                MAX_CLOTS_PER_GRESS);
            if (clotInfo.num_clots_allocated(gress) == MAX_CLOTS_PER_GRESS) {
                // We've allocated the last CLOT available in the gress. Remove all other
                // candidates for the gress.
                for (auto candidate : *candidates) {
                    if (candidate->state()->thread() != gress)
                        new_candidates->insert(candidate);
                }
            } else {
                auto graph = parserInfo.graphs().at(parserInfo.parser(state));
                auto full_states = clotInfo.find_full_states(graph);
                for (auto other_candidate : *candidates) {
                    if (full_states->count(other_candidate->state())) {
                        // Candidate's state is full. Remove from candidacy.
                        continue;
                    }

                    auto adjusted = adjust_for_allocation(other_candidate, candidate);
                    new_candidates->insert(adjusted->begin(), adjusted->end());
                }
            }

            candidates = new_candidates;

            if (LOGGING(3)) {
                if (candidates->empty()) {
                    LOG3("CLOT allocation complete: no remaining CLOT candidates.");
                } else {
                    LOG3("Remaining CLOT candidates:");
                    for (auto candidate : *candidates)
                        LOG3(candidate->print());
                }
            }
        }
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        // Configure logging for this visitor.
        if (BackendOptions().verbose > 0) {
            auto pipe = root->to<IR::BFN::Pipe>();
            log = new Logging::FileLog(pipe->id, "parser.log");
        }

        // Make sure we clear our state from previous invocations of the visitor.
        auto result = Visitor::init_apply(root);
        clear();
        return result;
    }

    const IR::Node *apply_visitor(const IR::Node *root, const char *) override {
        // Loop over each gress.
        for (auto kv : parserInfo.graphs()) {
            // Build auxiliary data structures.
            auto field_extract_info = group_extracts(kv.second);
            if (LOGGING(4)) {
                LOG4("Extracts found that can be part of a CLOT:");
                for (auto kv2 : *field_extract_info) {
                    LOG4("  In pseudoheader " << kv2.first->id << ":");
                    for (auto kv3 : kv2.second)
                        LOG4("    " << kv3.first->name);
                    LOG4("");
                }
                LOG4("");
            }

            // Identify CLOT candidates.
            auto candidates = find_clot_candidates(field_extract_info);
            if (LOGGING(3)) {
                if (candidates->empty()) {
                    LOG3("No CLOT candidates found.");
                } else {
                    LOG3("CLOT candidates:");
                    for (auto candidate : *candidates)
                        LOG3(candidate->print());
                }
            }

            // Perform allocation.
            allocate(candidates);
        }

        const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
        Logging::FileLog parserLog(pipe->id, "parser.log");

        LOG2(clotInfo.print());

        return root;
    }

    void end_apply() override {
        Logging::FileLog::close(log);
        Visitor::end_apply();
    }

    void clear() {
    }
};

AllocateClot::AllocateClot(ClotInfo &clotInfo, const PhvInfo &phv, PhvUse &uses) {
    addPasses({
        &uses,
        &parserInfo,
        LOGGING(3) ? new DumpParser("before_clot_allocation") : nullptr,
        new CollectClotInfo(phv, clotInfo),
        new GreedyClotAllocator(clotInfo, parserInfo)
    });
}

Visitor::profile_t ClotAdjuster::init_apply(const IR::Node* root) {
    auto result = Visitor::init_apply(root);

    // Configure logging for this visitor.
    if (BackendOptions().verbose > 0) {
        auto pipe = root->to<IR::BFN::Pipe>();
        log = new Logging::FileLog(pipe->id, "parser.log");
    }

    return result;
}

const IR::Node *ClotAdjuster::apply_visitor(const IR::Node* root, const char*) {
    clotInfo.adjust_clots(phv);

    const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
    Logging::FileLog parserLog(pipe->id, "parser.log");
    LOG2(clotInfo.print(&phv));

    return root;
}

void ClotAdjuster::end_apply(const IR::Node* root) {
    Logging::FileLog::close(log);
    Visitor::end_apply();
}
