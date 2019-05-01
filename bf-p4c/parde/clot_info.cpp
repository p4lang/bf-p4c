#include <array>
#include <vector>

#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/device.h"
#include "bf-p4c/logging/logging.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "clot_info.h"

/// Holds information relating to a field's extract.
class FieldExtractInfo {
    friend class GreedyClotAllocator;

    /// The parser state in which the field is extracted.
    const IR::BFN::ParserState* state_;

    /// The field's offset, in bits, from the start of the parser state.
    const unsigned state_bit_offset_;

    /// The field itself.
    const PHV::Field* field_;

 public:
    FieldExtractInfo(const IR::BFN::ParserState* state,
                     unsigned state_bit_offset,
                     const PHV::Field* field)
        : state_(state), state_bit_offset_(state_bit_offset), field_(field) { }

    /// @return the parser state in which the field is extracted.
    const IR::BFN::ParserState* state() const { return state_; }

    /// @return the field's offset, in bits, from the start of the parser state.
    unsigned state_bit_offset() const { return state_bit_offset_; }

    /// @return the field itself.
    const PHV::Field* field() const { return field_; }
};

std::string ClotInfo::print(const PhvInfo* phvInfo) const {
    std::stringstream out;

    unsigned total_unused_fields_in_clots = 0;
    unsigned total_unused_bits_in_clots = 0;
    unsigned total_bits = 0;

    out << "CLOT Allocation:" << std::endl;

    TablePrinter tp(out, {"CLOT", "Fields", "Bits", "Property"},
                          TablePrinter::Align::CENTER);

    std::set<int> unaligned_clots;
    for (auto entry : clot_to_parser_state()) {
        auto c = entry.first;
        auto state = entry.second;

        std::vector<std::vector<std::string>> rows;
        unsigned bits_in_clot = 0;

        for (auto f : c->all_fields()) {
            if (is_unused(f)) {
                total_unused_fields_in_clots++;
                total_unused_bits_in_clots += f->size;
            }

            std::stringstream bits;
            bits << f->size
                 << " [" << c->bit_offset(f) << ".." << (c->bit_offset(f) + f->size - 1) << "]";

            bool is_phv = c->is_phv_field(f);
            bool is_csum = c->is_csum_field(f);
            bool is_phv_overwrite = phvInfo && !is_csum && field_overwritten(*phvInfo, c, f);

            std::string attr;
            if (is_phv || is_csum) {
                attr += " (";
                if (is_phv) attr += " phv";
                if (is_phv_overwrite) attr += "*";
                if (is_csum) attr += " csum";
                attr += " ) ";
            }

            rows.push_back({"", std::string(f->name), bits.str(), attr});
            bits_in_clot = std::max(bits_in_clot, c->bit_offset(f) + f->size);
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

    unsigned total_unused_fields = 0;
    unsigned total_unused_bits = 0;

    out << std::endl;
    out << "All fields:" << std::endl;

    TablePrinter field_tp(out, {"Field", "Bits", "CLOT", "Property"},
                               TablePrinter::Align::CENTER);
    for (auto kv : parser_state_to_fields_) {
        for (auto f : kv.second) {
            auto clot = this->clot(f);
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

            field_tp.addRow({std::string(f->name),
                             std::to_string(f->size),
                             clot ? std::to_string(clot->tag) : "",
                             attr});
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

bool ClotInfo::can_start_clot(const FieldExtractInfo* extract_info) const {
    auto field = extract_info->field();

    // Start of field must be byte-aligned.
    if (extract_info->state_bit_offset() % 8 != 0) {
        LOG6("  Can't start CLOT with " << field->name << ": not byte-aligned");
        return false;
    }

    // Field must be unused.
    // XXX(Jed): Remove this when we can allocate slices to CLOTs.
    if (!is_unused(field)) {
        LOG6("  Can't start CLOT with " << field->name << ": is used");
        return false;
    }

    // Field must not be modified.
    if (is_modified(field)) {
        LOG6("  Can't start CLOT with " << field->name << ": is modified");
        return false;
    }

    // Field must not be a checksum.
    if (is_checksum(field)) {
        LOG6("  Can't start CLOT with " << field->name << ": is checksum");
        return false;
    }

    return true;
}

bool ClotInfo::can_end_clot(const FieldExtractInfo* extract_info) const {
    auto field = extract_info->field();

    // End of field must be byte-aligned.
    if ((extract_info->state_bit_offset() + field->size) % 8 != 0) {
        LOG6("  Can't end CLOT with " << field->name << ": not byte-aligned");
        return false;
    }

    // Field must be unused.
    // XXX(Jed): Remove this when we can allocate slices to CLOTs.
    if (!is_unused(field)) {
        LOG6("  Can't end CLOT with " << field->name << ": is used");
        return false;
    }

    // Field must not be modified.
    if (is_modified(field)) {
        LOG6("  Can't end CLOT with " << field->name << ": is modified");
        return false;
    }

    // Field must not be a checksum.
    if (is_checksum(field)) {
        LOG6("  Can't end CLOT with " << field->name << ": is checksum");
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

bool ClotInfo::is_readonly(const PHV::Field* field) const {
    return uses.is_used_mau(field) && !is_modified(field) && !is_checksum(field);
}

bool ClotInfo::is_unused(const PHV::Field* field) const {
    return !uses.is_used_mau(field) && !is_modified(field) && !is_checksum(field);
}

bool ClotInfo::adjust(const PhvInfo& phv, Clot* clot) {
    auto& all_fields = clot->all_fields();
    const int num_fields = all_fields.size();

    // Find the first non-overwritten field.
    int start_idx = 0;
    while (start_idx < num_fields && field_overwritten(phv, clot, all_fields.at(start_idx))) {
        start_idx++;
    }

    // Find the last non-overwritten field.
    int end_idx = num_fields - 1;
    while (start_idx < end_idx && field_overwritten(phv, clot, all_fields.at(end_idx))) {
        end_idx--;
    }

    clot->crop(start_idx, end_idx);
    return start_idx <= end_idx;
}

void ClotInfo::adjust_clots(const PhvInfo& phv) {
    std::vector<Clot*> clots;
    for (auto clot : clots_) {
        if (adjust(phv, clot)) {
            // Adjustment successful, so keep the CLOT.
            clots.push_back(clot);
        } else {
            // Adjustment resulted in an empty CLOT, so remove it.
            auto state_name = clot_to_parser_state_.at(clot);
            clot_to_parser_state_.erase(clot);

            auto& state_clots = parser_state_to_clots_.at(state_name);
            state_clots.erase(clot);
            if (state_clots.empty()) parser_state_to_clots_.erase(state_name);
        }
    }

    clots_ = clots;
}

bool ClotInfo::field_overwritten(const PhvInfo& phv,
                                 const Clot* clot,
                                 const PHV::Field* field) const {
    if (!clot->has_field(field) || is_checksum(field)) return false;

    // The field is overwritten if it shares a PHV container with a modified field, or with a field
    // not in the same CLOT.
    bool result = false;
    field->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
        for (auto field : phv.fields_in_container(alloc.container)) {
            result |= !clot->has_field(field) || is_modified(field);
            if (result) break;
        }
    });

    return result;
}

bool ClotInfo::field_deparsed_from_clot(const PhvInfo& phvInfo,
                                        const Clot* clot,
                                        const PHV::Field* field) const {
    return clot->has_field(field) &&
           !clot->is_csum_field(field) &&
           !field_overwritten(phvInfo, clot, field);
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
        auto largest = find_largest_paths(parser_state_to_clots(), graph, root);
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
    parser_state_to_clots_.clear();
    container_range_.clear();
    field_range_.clear();
    field_aliases_.clear();
    Clot::tagCnt.clear();
}

class ClotCandidate {
    /// Information relating to the extracts of the candidate's fields, ordered by position in the
    /// packet.
    const std::vector<const FieldExtractInfo*> extract_infos;

    /// The indices into @ref extract_infos that correspond to fields that can start a CLOT, in
    /// ascending order.
    std::vector<unsigned> can_start_indices_;

    /// The set of indices into @ref extract_infos that correspond to fields that can end a CLOT,
    /// in descending order.
    std::vector<unsigned> can_end_indices_;

    /// Indicates which bits in the candidate are checksums, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field in the candidate.
    bitvec checksum_bits;

    /// Indicates which bits in the candidate are modified, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field in the candidate.
    bitvec modified_bits;

    /// Indicates which bits in the candidate are unused, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field in the candidate.
    bitvec unused_bits;

    /// Indicates which bits in the candidate are read-only, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field in the candidate.
    bitvec readonly_bits;

    /// The length of the candidate, in bits.
    unsigned size_bits;

    static unsigned nextId;

 public:
    const unsigned id;

    ClotCandidate(const ClotInfo& clotInfo,
                  const std::vector<const FieldExtractInfo*>& extract_infos)
                  : extract_infos(extract_infos), id(nextId++) {
        unsigned offset = 0;
        unsigned idx = 0;
        for (auto extract_info : extract_infos) {
            auto field = extract_info->field();
            if (clotInfo.is_modified(field))
                modified_bits.setrange(offset, field->size);

            if (clotInfo.is_checksum(field))
                checksum_bits.setrange(offset, field->size);

            if (clotInfo.is_readonly(field))
                readonly_bits.setrange(offset, field->size);

            if (clotInfo.is_unused(field))
                unused_bits.setrange(offset, field->size);

            if (clotInfo.can_start_clot(extract_info))
                can_start_indices_.push_back(idx);

            if (clotInfo.can_end_clot(extract_info))
                can_end_indices_.push_back(idx);

            offset += field->size;
            idx++;
        }

        size_bits = offset;
        std::reverse(can_end_indices_.begin(), can_end_indices_.end());
    }

    /// The header associated with this candidate's extracts.
    const cstring header() const {
        return (*(extract_infos.begin()))->field()->header();
    }

    /// The parser state associated with this candidate's extracts.
    const IR::BFN::ParserState* state() const {
        return (*(extract_infos.begin()))->state();
    }

    /// The state-relative offset, in bits, of the first extract in the candidate.
    unsigned state_bit_offset() const {
        return (*(extract_infos.begin()))->state_bit_offset();
    }

    const std::vector<const FieldExtractInfo*>& extracts() const {
        return extract_infos;
    }

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can
    /// start a CLOT, in ascending order.
    const std::vector<unsigned>& can_start_indices() const {
        return can_start_indices_;
    }

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can end
    /// a CLOT, in descending order.
    const std::vector<unsigned>& can_end_indices() const {
        return can_end_indices_;
    }

    /// A FieldExtractInfo conflicts with a candidate if the field can come within the inter-CLOT
    /// gap surrounding the candidate.
    bool conflicts_with(const CollectParserInfo& parserInfo,
                        const FieldExtractInfo* extract) const {
        const int GAP_SIZE = 8 * Device::pardeSpec().byteInterClotGap();

        int candidate_offset = state_bit_offset();
        int candidate_size = size_bits;

        int extract_offset = extract->state_bit_offset();
        int extract_size = extract->field()->size;

        auto shift_amounts = parserInfo.get_all_shift_amounts(state(), extract->state());

        // Using coordinates relative to the start of the candidate's parser state, the candidate's
        // exclusion zone spans the interval
        //
        //   [candidate_offset - GAP_SIZE, candidate_offset + candidate_size + GAP_SIZE - 1].
        //
        // Each path through the parser yields a possibly different shift amount to get from the
        // parser state of the candidate to that of the extract, so the extract can appear in a few
        // different positions. For each shift amount, the extract spans the interval
        //
        //   [shift + extract_offset, shift + extract_offset + extract_size - 1].
        //
        // So, we have a conflict if there is a shift amount in the interval
        //
        //   [candidate_offset - GAP_SIZE - extract_offset - extract_size + 1,
        //    candidate_offset + candidate_size + GAP_SIZE - 1 - extract_offset].

        int lower_bound = candidate_offset - GAP_SIZE - extract_offset - extract_size + 1;
        int upper_bound = candidate_offset + candidate_size + GAP_SIZE - 1 - extract_offset;

        auto first_possible_conflict = shift_amounts->lower_bound(lower_bound);

        if (first_possible_conflict == shift_amounts->end()) return false;
        return *first_possible_conflict <= upper_bound;
    }

    /// Lexicographic order according to (number of unused bits, number of read-only bits,
    /// allocation order).
    bool operator<(const ClotCandidate& other) const {
        if (unused_bits.popcount() != other.unused_bits.popcount())
            return unused_bits.popcount() < other.unused_bits.popcount();

        if (readonly_bits.popcount() != other.readonly_bits.popcount())
            return readonly_bits.popcount() < other.readonly_bits.popcount();

        return this < &other;
    }

    struct Cmp {
        bool operator()(const ClotCandidate* left, const ClotCandidate* right) const {
            BUG_CHECK(left != nullptr, "Comparing against null CLOT candidate");
            BUG_CHECK(right != nullptr, "Comparing against null CLOT candidate");
            return *right < *left;
        }
    };

    std::string print() const {
        std::stringstream out;

        out << "CLOT candidate " << id << " (state " << state()->name << "):" << std::endl;

        TablePrinter tp(out, {"Fields", "Bits", "Property"}, TablePrinter::Align::CENTER);

        int offset = 0;
        for (auto extract_info : extract_infos) {
            auto field = extract_info->field();

            std::stringstream bits;
            bits << field->size << " [" << offset << ".." << (offset + field->size - 1) << "]";

            std::string attr;
            if (checksum_bits.getbit(offset)) attr = "checksum";
            if (modified_bits.getbit(offset)) attr = "modified";
            else if (readonly_bits.getbit(offset)) attr = "read-only";
            else
                attr = "unused";

            tp.addRow({std::string(field->name), bits.str(), attr});

            offset += field->size;
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
};

unsigned ClotCandidate::nextId = 0;

/**
 * This implements a greedy CLOT-allocation algorithm, as described in
 * https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
 */
class GreedyClotAllocator : public Visitor {
    const PhvInfo& phvInfo;
    ClotInfo& clotInfo;
    const CollectParserInfo& parserInfo;

 public:
    explicit GreedyClotAllocator(const PhvInfo& phvInfo,
                             ClotInfo& clotInfo,
                             const CollectParserInfo& parserInfo) :
        phvInfo(phvInfo),
        clotInfo(clotInfo),
        parserInfo(parserInfo) { }

 private:
    typedef std::map<cstring, std::map<const PHV::Field*, FieldExtractInfo*>> FieldExtractInfoMap;
    typedef std::set<const ClotCandidate*, ClotCandidate::Cmp> ClotCandidateSet;

    /// Generates a FieldExtractInfo object for each field that is extracted in the subgraph rooted
    /// at the given state, and can be part of a clot (@see ClotInfo::can_be_in_clot).
    ///
    /// Returns @arg result, a map from headers to fields to their FieldExtractInfo instances.
    /// This method assumes the graph is an unrolled DAG.
    FieldExtractInfoMap* find_extracts(
            const IR::BFN::ParserGraph* graph,
            const IR::BFN::ParserState* state = nullptr,
            FieldExtractInfoMap* result = nullptr,
            unsigned packet_offset = 0) {
        // Initialize parameters if needed.
        if (!state) state = graph->root;
        if (!result) result = new FieldExtractInfoMap();

        LOG6("Finding extracts in state " << state->name << " at packet offset " << packet_offset);

        // Find all extracts in the current state.
        if (clotInfo.field_range_.count(state)) {
            for (auto entry : clotInfo.field_range_.at(state)) {
                auto field = entry.first;
                const auto& bitrange = entry.second;

                if (!clotInfo.can_be_in_clot(field)) continue;

                auto header = field->header();
                if (!result->count(header) || !result->at(header).count(field)) {
                    (*result)[header][field] =
                        new FieldExtractInfo(state, static_cast<unsigned>(bitrange.lo), field);
                }
            }
        }

        // Recurse with the successors of the current state, if any.
        if (graph->successors().count(state)) {
            for (auto succ : graph->successors().at(state)) {
                auto transition = graph->transition(state, succ);
                BUG_CHECK(transition,
                          "Missing parser transition from %s to %s", state->name, succ->name);

                const auto& shift_bytes = transition->shift;
                BUG_CHECK(shift_bytes, "Missing parser shift amount in transition from %s to %s",
                          state->name, succ->name);

                int new_packet_offset = static_cast<int>(packet_offset) + *shift_bytes * 8;
                BUG_CHECK(new_packet_offset >= 0,
                          "Transition from %s to %s results in negative packet offset",
                          state->name, succ->name);

                LOG6("Recursing with transition " << state->name << " -> " << succ->name);
                find_extracts(graph, succ, result, static_cast<unsigned>(new_packet_offset));
            }
        }

        return result;
    }

    /// Creates a CLOT candidate out of the given extracts, if possible, and adds the result to the
    /// given candidate set.
    ///
    /// Precondition: the extracts are a valid CLOT prefix.
    void try_add_clot_candidate(ClotCandidateSet* candidates,
                                std::vector<const FieldExtractInfo*>& extracts) const {
        // Remove extracts until we find one that can end a CLOT.
        while (!extracts.empty() && !clotInfo.can_end_clot(extracts.back()))
            extracts.pop_back();

        // If we still have extracts, create a CLOT candidate out of those.
        if (!extracts.empty()) {
            const ClotCandidate* candidate = new ClotCandidate(clotInfo, extracts);
            candidates->insert(candidate);
            LOG6("  Created candidate");
            LOG6(candidate->print());
        }
    }

    /// A helper. Adds to the given @arg result any CLOT candidates that can be made from a given
    /// set of extracts into fields that all belong to a given header.
    void add_clot_candidates(ClotCandidateSet* result,
                             cstring header,
                             const std::map<const PHV::Field*,
                                            const FieldExtractInfo*>& extract_map) const {
        // Invariant: `extracts` forms a valid prefix for a potential CLOT candidate. When
        // `extracts` is non-empty, `state` is the parser state for the potential CLOT
        // candidate, and `next_offset` is the expected state-relative offset for the next
        // field.
        std::vector<const FieldExtractInfo*> extracts;
        const IR::BFN::ParserState* state = nullptr;
        unsigned next_offset = 0;

        // Obtain information about the header's fields from PhvInfo, and loop through those
        // fields.
        if (!phvInfo.has_struct_info(header)) {
            WARNING("No PhvInfo::StructInfo for header " << header
                    << ". No CLOTs will be allocated for this header.");
            return;
        }

        const auto& struct_info = phvInfo.struct_info(header);
        BUG_CHECK(struct_info.size > 0,
                  "PhvInfo::StructInfo has no fields for extracted header %s",
                  header);
        LOG6("Finding CLOT candidates for header " << header);
        for (int idx = 0; idx < struct_info.size; idx++) {
            auto field = phvInfo.field(struct_info.first_field_id + idx);
            auto extract_info = extract_map.count(field) ? extract_map.at(field) : nullptr;
            LOG6("  Considering field " << field->name);

            if (!extracts.empty()
                    && (!extract_info
                        || extract_info->state() != state
                        || extract_info->state_bit_offset() != next_offset)) {
                // We have a break in contiguity. Create a new CLOT candidate, if possible, and
                // set things up for the next candidate.
                LOG6("  Contiguity break");
                try_add_clot_candidate(result, extracts);
                extracts.clear();
            }

            if (extracts.empty()) {
                // Starting a new candidate.
                if (!extract_info) {
                    LOG6("  Can't start CLOT with " << field->name << ": not extracted");
                    continue;
                }

                if (!clotInfo.can_start_clot(extract_info))
                    continue;

                state = extract_info->state();
                next_offset = extract_info->state_bit_offset();
            }

            // Add to the existing prefix.
            LOG6("  Added field " << field->name << " to CLOT candidate prefix");
            extracts.push_back(extract_info);
            next_offset += field->size;
        }

        // If possible, create a new CLOT candidate from the remaining extracts.
        try_add_clot_candidate(result, extracts);
    }

    // Precondition: all FieldExtractInfo instances in the given map correspond to fields that
    // satisfy @ref ClotInfo::can_be_in_clot.
    //
    // This method's responsibility, then, is to ensure the following for each candidate:
    //   - A set of contiguous bits is extracted from the packet.
    //   - The aggregate set of extracted bits is byte-aligned in the packet.
    //   - All extracted fields reside in a single header and are contiguous.
    //   - Neither the first nor last field in the candidate is modified or is a checksum.
    //   - The extracts all come from the same parser state.
    ClotCandidateSet* find_clot_candidates(FieldExtractInfoMap* extract_info_map) {
        auto result = new ClotCandidateSet();

        for (auto entry : *extract_info_map) {
            // XXX(Jed) convert submap so its values can be const. Ugh.
            std::map<const PHV::Field*, const FieldExtractInfo*> submap;
            for (auto subentry : entry.second) {
                submap[subentry.first] = subentry.second;
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
        std::map<const PHV::Field*, const FieldExtractInfo*> extract_map;
        for (auto extract : to_adjust->extracts()) {
            if (allocated->conflicts_with(parserInfo, extract)) {
                LOG6("  " << extract->field()->name << " conflicts.");
                conflict = true;
            } else {
                extract_map[extract->field()] = extract;
            }
        }

        if (!conflict) result->insert(to_adjust);
        else if (!extract_map.empty())
            add_clot_candidates(result, to_adjust->header(), extract_map);

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
        unsigned best_start = 0;
        unsigned best_end = 0;
        int best_size = 0;

        const auto& extracts = candidate->extracts();
        for (auto start_idx : candidate->can_start_indices()) {
            auto start = extracts.at(start_idx);
            for (auto end_idx : candidate->can_end_indices()) {
                if (start_idx > end_idx) break;

                auto end = extracts.at(end_idx);
                int size =
                    end->state_bit_offset() + end->field()->size - start->state_bit_offset();

                if (size > MAX_SIZE) continue;

                if (size > best_size) {
                    best_start = start_idx;
                    best_end = end_idx;
                    best_size = size;
                }

                break;
            }

            if (best_size == MAX_SIZE) break;
        }

        if (best_size == 0) return nullptr;
        if (best_start == 0 && best_end == extracts.size() - 1) return candidate;

        auto resized = new std::vector<const FieldExtractInfo*>();
        for (auto idx = best_start ; idx <= best_end; idx++)
            resized->push_back(extracts.at(idx));

        auto result = new ClotCandidate(clotInfo, *resized);
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
            clot->start = state_bit_offset / 8;

            // Add fields.
            int offset = 0;
            for (auto extract : candidate->extracts()) {
                auto field = extract->field();

                Clot::FieldKind kind;
                if (clotInfo.is_checksum(field))
                    kind = Clot::FieldKind::CHECKSUM;
                else if (clotInfo.is_modified(field))
                    kind = Clot::FieldKind::MODIFIED;
                else if (clotInfo.is_readonly(field))
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

                    LOG4("  Adding " << kind_str << " " << field->name << " at bit " << offset);
                }
                clot->add_field(kind, field, offset);

                offset += field->size;
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
                    LOG3("No remaining CLOT candidates.");
                } else {
                    LOG3("Remaining CLOT candidates:");
                    for (auto candidate : *candidates)
                        LOG3(candidate->print());
                }
            }
        }
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        // Make sure we clear our state from previous invocations of the visitor.
        auto result = Visitor::init_apply(root);
        clear();
        return result;
    }

    const IR::Node *apply_visitor(const IR::Node *root, const char *) override {
        // Loop over each gress.
        for (auto kv : parserInfo.graphs()) {
            // Build auxiliary data structures.
            auto field_extract_info = find_extracts(kv.second);
            if (LOGGING(4)) {
                LOG4("Extracts found that can be part of a CLOT:");
                for (auto kv2 : *field_extract_info) {
                    LOG4("  In header " << kv2.first << ":");
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
        Logging::FileLog parserLog(pipe->id, "parser.log", true /* append */);

        LOG2(clotInfo.print());

        return root;
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
        new GreedyClotAllocator(phv, clotInfo, parserInfo)
    });
}

const IR::Node *ClotAdjuster::apply_visitor(const IR::Node* root, const char*) {
    clotInfo.adjust_clots(phv);

    const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
    Logging::FileLog parserLog(pipe->id, "parser.log", true /* append */);
    LOG2(clotInfo.print(&phv));

    return root;
}
