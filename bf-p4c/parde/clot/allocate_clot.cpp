#include "allocate_clot.h"
#include "clot_candidate.h"
#include "field_slice_extract_info.h"
#include "field_pov_analysis.h"
#include "header_removal_analysis.h"
/**
 * This implements a greedy CLOT-allocation algorithm, as described in
 * https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU.
 */
class GreedyClotAllocator : public Visitor {
    ClotInfo& clotInfo;
    const PhvInfo& phvInfo;
    const CollectParserInfo& parserInfo;
    Logging::FileLog* log = nullptr;
    const bool logAllocation;

 public:
    explicit GreedyClotAllocator(const PhvInfo& phvInfo, ClotInfo& clotInfo, bool logAllocation) :
        clotInfo(clotInfo),
        phvInfo(phvInfo),
        parserInfo(clotInfo.parserInfo),
        logAllocation(logAllocation) { }

 private:
    typedef std::map<const Pseudoheader*,
                     ordered_map<const PHV::Field*, FieldSliceExtractInfo*>,
                     Pseudoheader::Less> FieldSliceExtractInfoMap;
    typedef std::set<const ClotCandidate*, ClotCandidate::Greater> ClotCandidateSet;

    /// Generates a FieldSliceExtractInfo object for each field that is (1) extracted in the
    /// subgraph rooted at the given state and (2) can be part of a clot (@see
    /// ClotInfo::can_be_in_clot).
    ///
    /// Returns @arg result.
    ///
    /// This method assumes the graph is an unrolled DAG.
    //
    // Invariant: `state` is not an element of `visited`.
    FieldExtractInfo* group_extracts(
            const IR::BFN::ParserGraph* graph,
            const IR::BFN::ParserState* state = nullptr,
            FieldExtractInfo* result = nullptr,
            ordered_set<const IR::BFN::ParserState*>* visited = nullptr) {
        // Initialize parameters if needed.
        if (!state) state = graph->root;
        if (!result) result = new FieldExtractInfo();
        if (!visited) visited = new ordered_set<const IR::BFN::ParserState*>();

        LOG6("Finding extracts in state " << state->name);
        visited->insert(state);

        // Find all packet-sourced extracts in the current state.
        if (clotInfo.field_range_.count(state)) {
            for (auto entry : clotInfo.field_range_.at(state)) {
                auto field = entry.first;
                const auto& bitrange = entry.second;
                auto max_packet_offset = parserInfo.get_max_shift_amount(state) + bitrange.lo;

                // Add to result->fieldMap.
                result->updateFieldMap(field,
                                       state,
                                       static_cast<unsigned>(bitrange.lo),
                                       static_cast<unsigned>(max_packet_offset));

                if (!clotInfo.can_be_in_clot(field)) continue;

                BUG_CHECK(clotInfo.field_to_pseudoheaders_.count(field),
                          "Field %s determined to be CLOT-eligible, but is not extracted (no "
                          "pseudoheader information)",
                          field->name);

                // Add to result->pseudoheaderMap.
                for (auto pseudoheader : clotInfo.field_to_pseudoheaders_.at(field)) {
                    result->updatePseudoheaderMap(pseudoheader,
                                                  field,
                                                  state,
                                                  static_cast<unsigned>(bitrange.lo),
                                                  static_cast<unsigned>(max_packet_offset));
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
            // Trim the last extract so that it is byte-aligned.
            extracts.back() = extracts.back()->trim_tail_to_byte();

            // Further trim the last extract so that it does not extend past the maximum CLOT
            // position.
            extracts.back()->trim_tail_to_max_clot_pos();

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
        // `extracts` is non-empty, `next_offset_by_state` maps each parser state for the potential
        // CLOT candidate to the expected state-relative offset for the next field slice. When
        // `extracts` is empty, then so is `next_offset_by_state`.
        std::vector<const FieldSliceExtractInfo*> extracts;
        ordered_map<const IR::BFN::ParserState*, unsigned> next_offset_by_state;

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
                    next_offset_by_state.clear();
                }

                continue;
            }

            for (auto extract_info : extract_map.at(field)) {
                if (!extracts.empty()) {
                    // We have a break in contiguity if the current extract_info is extracted in a
                    // different set of states than the current candidate or if the current
                    // extract_info has any state-relative bit offsets that are different from what
                    // we are expecting.
                    auto& extract_state_bit_offsets = extract_info->state_bit_offsets();

                    bool have_contiguity_break =
                        extract_state_bit_offsets.size() != next_offset_by_state.size();
                    if (have_contiguity_break) {
                        LOG6("  Contiguity break: extracted in a different set of states");
                    } else {
                        for (auto& entry : next_offset_by_state) {
                            auto& state = entry.first;
                            auto next_offset = entry.second;

                            have_contiguity_break = !extract_state_bit_offsets.count(state);
                            if (have_contiguity_break) {
                                LOG6("  Contiguity break: extracted in a different set of states");
                                break;
                            }

                            have_contiguity_break =
                                extract_state_bit_offsets.at(state) != next_offset;
                            if (have_contiguity_break) {
                                LOG6("  Contiguity break in state " << state->name);
                                break;
                            }
                        }
                    }

                    if (have_contiguity_break) {
                        // We have a break in contiguity. Create a new CLOT candidate, if possible,
                        // and set things up for the next candidate.
                        try_add_clot_candidate(result, pseudoheader, extracts);
                        extracts.clear();
                        next_offset_by_state.clear();
                    }
                }

                if (extracts.empty()) {
                    // Starting a new candidate.
                    if (!clotInfo.can_start_clot(extract_info)) continue;

                    auto& state_bit_offsets = extract_info->state_bit_offsets();
                    next_offset_by_state.insert(state_bit_offsets.begin(),
                                                state_bit_offsets.end());
                }

                // Add to the existing prefix.
                extracts.push_back(extract_info);
                auto slice = extract_info->slice();
                for (auto& next_offset : Values(next_offset_by_state)) {
                    next_offset += slice->size();
                }

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
    //   - The fields in the candidate are all extracted in the same set of parser states.
    ClotCandidateSet*
    find_clot_candidates(const FieldExtractInfo::PseudoheaderMap& extract_info_map) {
        auto result = new ClotCandidateSet();

        for (const auto& entry : extract_info_map) {
            std::map<const PHV::Field*, std::vector<const FieldSliceExtractInfo*>> submap;
            for (const auto& subentry : entry.second) {
                submap[subentry.first].push_back(subentry.second);
            }

            add_clot_candidates(result, entry.first, submap);
        }

        return result;
    }

    /// Helper to determine whether an adjustment is needed to create an inter-CLOT gap between two
    /// CLOT candidates, when @p c1 is parsed before @p c2. If @p c1 is never parsed before @p c2,
    /// or if @p c1 and @p c2 are always separated by at least the inter-CLOT gap requirement,
    /// then this conservatively returns true.
    bool needInterClotGap(const ClotCandidate* c1,
                          const ClotCandidate* c2,
                          const FieldExtractInfo* fei,
                          const HeaderRemovalAnalysis::ResultMap header_removals) const {
        BUG_CHECK(c1->thread() == c2->thread(),
                  "Candidate %1% comes from %2%, but candidate %3% comes from %4%",
                  c1->id, c1->thread(), c2->id, c2->thread());

        auto gress = c1->thread();
        const auto& deparse_graph = clotInfo.deparse_graph_[gress];

        auto gaps = c1->byte_gaps(parserInfo, c2);
        if (gaps.empty()) {
            LOG5("    Candidate " << c1->id << " is never parsed before candidate " << c2->id);
            return true;
        }

        LOG5("    Candidate " << c1->id << " might be parsed before candidate " << c2->id);

        // Need gap if CLOTs are never zero-separated.
        if (!gaps.count(0)) {
            LOG5("      Candidate " << c1->id << " never appears immediately before candidate "
                << c2->id << " in parsed packet");
            return true;
        }

        // Need gap if separation between CLOTs can be non-zero and smaller than the required
        // inter-CLOT gap.
        for (unsigned i = 1; i < Device::pardeSpec().byteInterClotGap(); i++) {
            if (gaps.count(i)) {
                LOG5("      Candidates might be separated by " << i << " bytes in parsed packet");
                return true;
            }
        }

        // Need gap if c1 can become invalid in MAU when c2 is still valid.
        auto c1_pov_bits = c1->pseudoheader->pov_bits;
        auto c2_pov_bits = c2->pseudoheader->pov_bits;
        auto check = [&](const PHV::FieldSlice* f1) {
            auto check = [&](const PHV::FieldSlice* f2) {
                return f1 != f2 && header_removals.at({f1, f2}).count({f1});
            };
            return std::any_of(c2_pov_bits.begin(), c2_pov_bits.end(), check);
        };
        if (std::any_of(c1_pov_bits.begin(), c1_pov_bits.end(), check)) {
            LOG5("      Candidate " << c1->id << " might be invalidated by MAU while candidate "
                 << c2->id << " remains valid");
            return true;
        }

        // Need gap if c2 can be deparsed before c1.
        const auto* c2_last_field = c2->extracts().back()->slice()->field();
        const auto* c1_first_field = c1->extracts().front()->slice()->field();
        if (deparse_graph.canReach(c2_last_field, c1_first_field)) {
            LOG5("      Candidate " << c2->id << " might be deparsed before candidate " << c1->id);
            return true;
        }

        // Need gap if c1 can become separated from c2 during deparsing.
        {
            const auto* c1_last_slice = c1->extracts().back()->slice();
            const auto* c2_first_slice = c2->extracts().front()->slice();
            const auto* c1_last_field = c1_last_slice->field();
            const auto* c2_first_field = c2_first_slice->field();

            if (c1_last_field == c2_first_field) {
                // c1's last slice and c2's first slice come from the same field. This means that
                // the "gaps" set should be a singleton containing the exact separation between the
                // two slices. We already know that 0 ∈ gaps, so expect that |gaps| = 1.
                if (gaps.size() != 1) {
                    std::stringstream msg;
                    msg << "Unexpectedly got more than one gap size between two slices of the "
                        << "same field. Slices " << c1_last_slice->shortString() << " and "
                        << c2_first_slice->shortString() << " have gaps {";

                    bool first = true;
                    for (auto gap : Keys(gaps)) {
                        if (!first) msg << ", ";
                        msg << gap;
                        first = false;
                    }

                    msg << "}";

                    BUG("%s", msg.str());
                }
            } else {
                // c1's last slice and c2's first slice come from different fields. Because we know
                // 0 ∈ gaps, c1's last slice must cover the last bit of its field, and c2's first
                // slice must cover the first bit of its field. It suffices, then, to check
                // entities that might be deparsed between those two fields.
                for (const auto nodeInfo : deparse_graph.nodesBetween(c1_last_field,
                                                                      c2_first_field)) {
                    if (nodeInfo.isConstant()) {
                        LOG5("      Constant " << nodeInfo.constant << " might be deparsed "
                             "between CLOT candidates");
                        return true;
                    }

                    const auto* f = nodeInfo.field;

                    // The field f might be deparsed between c1 and c2, so the two CLOT candidates
                    // might be separated if f's header might be added by the MAU pipeline.
                    if (clotInfo.is_added_by_mau(f->header())) {
                        LOG5("      Field " << f->name << " might be deparsed between candidates, "
                             "and its header might be added by MAU");
                        return true;
                    }

                    // The two CLOT candidates might be separated if there is a path through the
                    // parser in which c1 is parsed immediately before c2, and f is also parsed.
                    //
                    // fei->fieldMap will contain an entry for f if f is parsed.
                    if (fei->fieldMap.count(f)) {
                        BUG_CHECK(fei->fieldMap.count(c1_first_field),
                                  "Field %1% is part of a CLOT candidate, but has no fieldMap "
                                  "entry",
                                  c1_first_field);
                        BUG_CHECK(fei->fieldMap.count(c2_last_field),
                                  "Field %1% is part of a CLOT candidate, but has no fieldMap "
                                  "entry",
                                  c2_last_field);

                        const auto* fExtractInfo = fei->fieldMap.at(f);
                        const auto* c1ExtractInfo = fei->fieldMap.at(c1_first_field);
                        const auto* c2ExtractInfo = fei->fieldMap.at(c2_last_field);

                        // Get the set of states in which the first field of c1 is extracted, and
                        // that field comes after f in the packet.
                        const auto fC1Gaps = fExtractInfo->bit_gaps(parserInfo, c1ExtractInfo);
                        ordered_set<const IR::BFN::ParserState*> c1States;
                        for (const auto& statePairSet : Values(fC1Gaps)) {
                            for (const auto& statePair : statePairSet) {
                                c1States.insert(statePair.second);
                            }
                        }

                        // Get the set of states in which the last field of c2 is extracted, and
                        // that field comes before f in the packet.
                        const auto c2FGaps = c2ExtractInfo->bit_gaps(parserInfo, fExtractInfo);
                        ordered_set<const IR::BFN::ParserState*> c2States;
                        for (const auto& statePairSet : Values(c2FGaps)) {
                            for (const auto& statePair : statePairSet) {
                                c2States.insert(statePair.first);
                            }
                        }

                        // Look at the states in which c1 is extracted immediately before c2. If
                        // any of those states are contained in c1States or c2States, then c1 might
                        // be separated from c2.
                        for (auto statePair : gaps.at(0)) {
                            const auto* c1State = statePair.first;
                            const auto* c2State = statePair.second;

                            if (c1States.count(c1State) || c2States.count(c2State)) {
                                LOG5("      Field " << f->name << " might be inserted between "
                                     "candidates");
                                return true;
                            }
                        }
                    }
                }
            }
        }

        return false;
    }

    /// Adjusts a CLOT candidate to account for the allocation of another (possibly the same)
    /// candidate.
    ClotCandidateSet* adjust_for_allocation(const ClotCandidate* to_adjust,
            const ClotCandidate* allocated,
            const FieldExtractInfo* fei,
            const HeaderRemovalAnalysis::ResultMap header_removals) const {
        const auto GAP_BYTES = Device::pardeSpec().byteInterClotGap();
        const auto GAP_BITS = 8 * GAP_BYTES;

        LOG5("");
        LOG5("  Adjusting candidate " << to_adjust->id << " for allocated CLOT");

        ClotCandidateSet* result = new ClotCandidateSet();

        // If the states from one candidate are mutually exclusive with the states from another,
        // then no need to adjust.
        const auto to_adjust_states = to_adjust->states();
        const auto allocated_states = allocated->states();
        const auto& graph = parserInfo.graph(parserInfo.parser(*allocated_states.begin()));
        bool mutually_exclusive = true;
        for (auto& to_adjust_state : to_adjust_states) {
            for (auto& allocated_state : allocated_states) {
                mutually_exclusive = graph.is_mutex(to_adjust_state, allocated_state);
                if (!mutually_exclusive) break;
            }
            if (!mutually_exclusive) break;
        }

        if (mutually_exclusive) {
            LOG5("    No need to adjust: states are mutually exclusive");
            result->insert(to_adjust);
            return result;
        }

        // Determine the inter-CLOT gap sizes needed before and after the allocated candidate.
        bool allocatedNeedsPreGap = needInterClotGap(to_adjust, allocated, fei, header_removals);
        int preGapBits = allocatedNeedsPreGap ? GAP_BITS : 0;

        bool allocatedNeedsPostGap = needInterClotGap(allocated, to_adjust, fei, header_removals);
        int postGapBits = allocatedNeedsPostGap ? GAP_BITS : 0;

        // If the candidate occurs immediately after a CLOT that has already been allocated, and
        // the just-allocated CLOT conflicts with the first byte of the candidate, then we need to
        // remove the first few bytes to create a sufficient inter-CLOT gap with the previously
        // allocated CLOT.
        //
        // Given this constraint, this le_bitinterval tracks which bits in the candidate can be
        // included in the adjusted CLOT candidate. This is kept in low-endian format to make
        // manipulations with field slices easier later on.
        le_bitinterval candidate_interval = StartLen(0, to_adjust->size_bits);
        if (to_adjust->afterAllocatedClot) {
            // Get the first extract and figure out what parts of it don't conflict.
            const auto* first_extract = to_adjust->extracts().front();
            const auto* non_conflicts = first_extract->remove_conflicts(parserInfo,
                                                                        preGapBits,
                                                                        allocated,
                                                                        postGapBits);

            // Figure out if first byte conflicts.
            bool first_byte_conflicts;
            if (non_conflicts->empty()) {
                first_byte_conflicts = true;
            } else {
                const auto* first_adjusted = non_conflicts->front();
                first_byte_conflicts =
                    first_extract->slice()->range().hi != first_adjusted->slice()->range().hi;
            }

            // Adjust candidate_interval as needed.
            if (first_byte_conflicts) {
                LOG5("    First byte of candidate " << to_adjust->id << " conflicts");
                int new_size = std::max(0L, candidate_interval.size() - GAP_BITS);
                candidate_interval = candidate_interval.resizedToBits(new_size);
            }
        }

        // Similarly, we may need to remove the last few bytes of the candidate.
        if (to_adjust->beforeAllocatedClot) {
            // Get the last extract and figure out what parts of it don't conflict.
            const auto* last_extract = to_adjust->extracts().back();
            const auto* non_conflicts = last_extract->remove_conflicts(parserInfo,
                                                                       preGapBits,
                                                                       allocated,
                                                                       postGapBits);

            // Figure out if last byte conflicts.
            bool last_byte_conflicts;
            if (non_conflicts->empty()) {
                last_byte_conflicts = true;
            } else {
                const auto* last_adjusted = non_conflicts->back();
                last_byte_conflicts =
                    last_extract->slice()->range().lo != last_adjusted->slice()->range().lo;
            }

            // Adjust candidate_interval as needed.
            if (last_byte_conflicts) {
                LOG5("    Last byte of candidate " << to_adjust->id << " conflicts");
                int new_size = std::max(0L, candidate_interval.size() - GAP_BITS);
                candidate_interval = candidate_interval.resizedToBits(new_size)
                                                       .shiftedByBits(GAP_BITS);
            }
        }

        // Figure out whether the candidates conflict. Build an extract_map for the set of
        // non-conflicting extracts. This map will be used for the slow path below.
        bool have_conflict = false;
        std::map<const PHV::Field*, std::vector<const FieldSliceExtractInfo*>> extract_map;
        unsigned extract_bit_pos = to_adjust->size_bits;
        for (auto extract : to_adjust->extracts()) {
            const auto* slice = extract->slice();
            extract_bit_pos -= slice->size();

            // Adjust the extract so it lands within candidate_bitinterval. If the extract is
            // disjoint from the interval, then use nullptr to represent the empty extract.
            const FieldSliceExtractInfo* adjusted_extract = nullptr;
            auto trim_range =
                toHalfOpenRange(slice->range())
                    .shiftedByBits(extract_bit_pos)
                    .intersectWith(candidate_interval)
                    .shiftedByBits(-extract_bit_pos)
                    .shiftedByBits(-slice->range().lo);
            if (!trim_range.empty()) {
                adjusted_extract = extract->trim(trim_range.lo, trim_range.size());
            }

            const auto* non_conflicts =
                adjusted_extract
                    ? adjusted_extract->remove_conflicts(parserInfo,
                                                         preGapBits,
                                                         allocated,
                                                         postGapBits)
                    : new std::vector<const FieldSliceExtractInfo*>();

            // Figure out whether this extract conflicts with the allocated candidate, and add the
            // non-conflicting extracts to extract_map.
            bool extract_conflicts = false;
            if (non_conflicts->empty()) {
                extract_conflicts = true;
                LOG5("    Removed " << slice->shortString());
            }
            for (auto adjusted : *non_conflicts) {
                extract_conflicts |= extract != adjusted;
                extract_map[slice->field()].push_back(adjusted);
            }

            have_conflict |= extract_conflicts;
            if (LOGGING(5) && extract_conflicts && !non_conflicts->empty()) {
                LOG5("    Replaced " << slice->shortString());

                bool first_replacement = true;
                for (auto adjusted : *non_conflicts) {
                    LOG5("       "
                        << (first_replacement ? "with: " : "      ")
                        << adjusted->slice()->shortString());
                    first_replacement = false;
                }
            }
        }

        // Fast path, taken when the candidates don't conflict:
        //   Return a singleton containing the candidate that we are adjusting, after updating the
        //   candidate with information about whether it appears immediately before or after an
        //   allocated CLOT.
        //
        // Slow path, taken when the candidates conflict:
        //   Delegate to add_clot_candidates.
        if (!have_conflict) {
            if (LOGGING(5)) {
                LOG5("    Candidate does not conflict with allocated CLOT");

                if (!allocatedNeedsPostGap) {
                    if (to_adjust->afterAllocatedClot) {
                        LOG5("    Candidate already appears after an allocated CLOT with 0-byte "
                             "gap");
                    } else {
                        LOG5("    Marking candidate as appearing after allocated CLOT with 0-byte "
                             "gap");
                    }
                }

                if (!allocatedNeedsPreGap) {
                    if (to_adjust->beforeAllocatedClot) {
                        LOG5("    Candidate already appears before an allocated CLOT with 0-byte "
                             "gap");
                    } else {
                        LOG5("    Marking candidate as appearing before allocated CLOT with "
                             "0-byte gap");
                    }
                }
            }

            result->insert(to_adjust->mark_adjacencies(!allocatedNeedsPostGap,
                                                       !allocatedNeedsPreGap));
        } else if (!extract_map.empty()) {
            add_clot_candidates(result, to_adjust->pseudoheader, extract_map);
        }

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

        // Since the CLOT candidate looks the same (has the same contiguous sequence of field
        // slices) in all parser states that it appears in, we can just work within a single such
        // parser state.
        const auto* state = *Keys(candidate->state_bit_offsets()).begin();

        const auto& extracts = candidate->extracts();
        for (auto start_idx : candidate->can_start_indices()) {
            auto start = extracts.at(start_idx)->trim_head_to_byte();
            if (start->slice()->field()->gress == INGRESS &&
                start->max_packet_bit_offset() <
                           Device::pardeSpec().byteTotalIngressMetadataSize()*8) {
                if (start->slice()->size() >
                    static_cast<int>(Device::pardeSpec().byteTotalIngressMetadataSize()*8 -
                    start->max_packet_bit_offset())) {
                    start->trim(0, Device::pardeSpec().byteTotalIngressMetadataSize()*8 -
                                                      start->max_packet_bit_offset());
                }
            } else if (start->slice()->field()->gress == EGRESS &&
                       start->max_packet_bit_offset() < 28 * 8) {
                if (start->slice()->size() >
                    static_cast<int>(28 * 8 - start->max_packet_bit_offset())) {
                    start->trim(0, 28*8 - start->max_packet_bit_offset());
                }
            }

            // Find the rightmost end_idx that fits in the maximum CLOT size.
            //
            // We do this by taking start_bit_offset to be that of the last byte (or fraction of a
            // byte) in `start`, and finding the rightmost index whose offset lands within the
            // minimum CLOT size of start_bit_offset.

            int start_bit_offset =
                (start->state_bit_offset(state) + start->slice()->size() - 1) / 8 * 8;

            for (auto end_idx : candidate->can_end_indices()) {
                if (start_idx > end_idx) break;

                auto end = extracts.at(end_idx)->trim_tail_to_byte();
                int end_bit_offset = end->state_bit_offset(state);
                if (end_bit_offset - start_bit_offset >= MAX_SIZE) continue;

                int full_size =
                    end_bit_offset + end->slice()->size() - start->state_bit_offset(state);

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
        int size =
            end->state_bit_offset(state) + end->slice()->size() - start->state_bit_offset(state);
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
    void allocate(ClotCandidateSet* candidates,
                  const FieldExtractInfo* fei,
                  const HeaderRemovalAnalysis::ResultMap header_removals) {
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
            BUG_CHECK(candidate->bit_in_byte_offset() == 0,
                      "CLOT candidate is not byte-aligned\n%s", candidate->print());
            auto states = candidate->states();
            auto gress = candidate->thread();

            auto clot = new Clot(gress);
            if (LOGGING(3)) {
                LOG3("Allocating CLOT " << clot->tag << " to candidate " << candidate->id);

                bool first_state = true;
                for (auto* state : states) {
                    LOG3("  " << (first_state ? "states: " : "        ") << state->name);
                    first_state = false;
                }
            }
            clotInfo.add_clot(clot, states);

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
                    if (candidate->thread() != gress)
                        new_candidates->insert(candidate);
                }
            } else {
                auto graph = parserInfo.graphs().at(parserInfo.parser(*states.begin()));
                auto full_states = clotInfo.find_full_states(graph);
                if (!full_states->empty()) {
                    if (LOGGING(6)) {
                      LOG6("The following states are now full.");
                      LOG6("Allocating more CLOTs would violate the max-CLOTs-per-packet "
                           "constraint.");

                      for (auto state : *full_states)
                          LOG6("  " << state->name);

                      LOG6("");
                    }
                }

                // Set of removed candidates; used for logging.
                ClotCandidateSet removed_candidates;

                for (auto other_candidate : *candidates) {
                    if (intersects(*full_states, other_candidate->states())) {
                        // Candidate has a full state. Remove from candidacy.
                        if (LOGGING(3)) removed_candidates.insert(other_candidate);
                        continue;
                    }

                    if (candidate == other_candidate) continue;

                    auto adjusted =
                        adjust_for_allocation(other_candidate, candidate, fei, header_removals);
                    new_candidates->insert(adjusted->begin(), adjusted->end());
                }

                if (LOGGING(3) && !removed_candidates.empty()) {
                    LOG3("Removed the following from candidacy to satisfy the "
                         "max-CLOTs-per-packet constraint:");
                    for (auto candidate : removed_candidates) {
                        LOG3("  Candidate " << candidate->id);

                        bool first_state = true;
                        for (auto* state : candidate->states()) {
                             LOG3("  " << (first_state ? "states: " : "        ") << state->name);
                             first_state = false;
                        }
                    }
                    LOG3("");
                }
            }

            candidates = new_candidates;

            if (LOGGING(3)) {
                LOG3("");
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

    HeaderRemovalAnalysis::ResultMap analyze_header_removals(const ClotCandidateSet* candidates,
                                                             const IR::MAU::TableSeq* mau) {
        // Build the set of correlations that we're interested in.
        std::set<FieldSliceSet> correlations = {};
        for (const auto* c1 : *candidates) {
            for (const auto* c2 : *candidates) {
                if (c1 == c2) continue;

                // Only interesting if c1 and c2 can appear back-to-back in the packet.
                if (!c1->byte_gaps(parserInfo, c2).count(0)
                        && !c2->byte_gaps(parserInfo, c1).count(0))
                    continue;

                for (const auto* pov1 : c1->pseudoheader->pov_bits) {
                    for (const auto* pov2 : c2->pseudoheader->pov_bits) {
                        FieldSliceSet set = {pov1, pov2};
                        correlations.emplace(set);
                    }
                }
            }
        }

        HeaderRemovalAnalysis hra(phvInfo, correlations);
        mau->apply(hra);
        return hra.resultMap;
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        // Configure logging for this visitor.
        if (BackendOptions().verbose > 0) {
            if (auto pipe = root->to<IR::BFN::Pipe>())
                log = new Logging::FileLog(pipe->id, "clot_allocation.log");
        }

        // Make sure we clear our state from previous invocations of the visitor.
        auto result = Visitor::init_apply(root);
        clear();
        return result;
    }

    const IR::Node *apply_visitor(const IR::Node *root, const char *) override {
        const auto* pipe = root->to<IR::BFN::Pipe>();
        BUG_CHECK(pipe, "GreedyClotAllocator must be applied to pipe");

        // Loop over each gress.
        for (const auto& entry : parserInfo.graphs()) {
            const auto* parser = entry.first;
            const auto* graph = entry.second;

            // Build auxiliary data structures.
            auto field_extract_info = group_extracts(graph);
            if (LOGGING(4)) {
                LOG4("Extracts found that can be part of a CLOT:");
                for (const auto& entry2 : field_extract_info->pseudoheaderMap) {
                    const auto* pseudoheader = entry2.first;
                    const auto& extracts = entry2.second;

                    LOG4("  In pseudoheader " << pseudoheader->id << ":");
                    for (const auto* field : Keys(extracts))
                        LOG4("    " << field->name);
                    LOG4("");
                }
                LOG4("");
            }

            // Identify CLOT candidates.
            auto candidates = find_clot_candidates(field_extract_info->pseudoheaderMap);
            if (LOGGING(3)) {
                if (candidates->empty()) {
                    LOG3("No CLOT candidates found.");
                } else {
                    LOG3("CLOT candidates:");
                    for (auto candidate : *candidates)
                        LOG3(candidate->print());
                }
            }

            // Do header-removal analysis.
            const auto* mau = pipe->thread[parser->gress].mau;
            auto header_removals = analyze_header_removals(candidates, mau);

            // Perform allocation.
            allocate(candidates, field_extract_info, header_removals);
        }

        if (logAllocation)
            if (auto *pipe = root->to<IR::BFN::Pipe>())
                Logging::FileLog parserLog(pipe->id, "clot_allocation.log");

        LOG2(clotInfo.print());

        return root;
    }

    void end_apply() override {
        if (log)
            Logging::FileLog::close(log);
        Visitor::end_apply();
    }

    void clear() {
    }
};

AllocateClot::AllocateClot(ClotInfo &clotInfo, const PhvInfo &phv, PhvUse &uses, bool log) :
clotInfo(clotInfo) {
    addPasses({
        &uses,
        &clotInfo.parserInfo,
        LOGGING(3) ? new DumpParser("before_clot_allocation") : nullptr,
        /// FieldPovAnalysis runs a data flow analysis on parser and fills result in
        /// clotInfo.pov_extracted_without_fields
        new FieldPovAnalysis(clotInfo, phv),
        new CollectClotInfo(phv, clotInfo),
        new GreedyClotAllocator(phv, clotInfo, log)
    });
}

Visitor::profile_t ClotAdjuster::init_apply(const IR::Node* root) {
    auto result = Visitor::init_apply(root);

    // Configure logging for this visitor.
    if (BackendOptions().verbose > 0) {
        if (auto pipe = root->to<IR::BFN::Pipe>())
            log = new Logging::FileLog(pipe->id, "clot_allocation.log");
    }

    return result;
}

const IR::Node *ClotAdjuster::apply_visitor(const IR::Node* root, const char*) {
    clotInfo.adjust_clots(phv);

    const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
    if (pipe)
        Logging::FileLog parserLog(pipe->id, "clot_allocation.log");
    LOG1(clotInfo.print(&phv));

    return root;
}

void ClotAdjuster::end_apply(const IR::Node*) {
    if (log)
        Logging::FileLog::close(log);
    Visitor::end_apply();
}
