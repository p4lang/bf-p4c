#include <boost/range/adaptors.hpp>

#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/parde_utils.h"
#include "device.h"

/// A mapping from a computed r-value to the r-values we evaluated it to.
/// For one computedRVal, it can have multiple definition parserRVal.
using ParserValueResolution =
    std::map<const IR::BFN::ComputedRVal*, std::vector<ParserRValDef>>;

class ComputeSaveAndSelect: public ParserInspector {
    using State = IR::BFN::ParserState;
    using StateTransition = IR::BFN::Transition;
    using StateSelect = IR::BFN::Select;

    struct UnresolvedSelect {
        UnresolvedSelect(const StateSelect* s, unsigned shifts,
                         const std::set<MatchRegister>& used,
                         boost::optional<ParserRValDef> prefer = boost::none)
            : select(s), byte_shifted(shifts),
              used_by_others(used), preferred_source(prefer) { }

        const StateSelect* select;
        unsigned byte_shifted;
        // MatchRegisters that has been used on the path by other selects.
        // Any save before that state need to update this.
        std::set<MatchRegister> used_by_others;
        // Used when select has unresolved source, i.e. IR::BFN::ComputedRVal.
        // In that case, it means that the source has multiple defs so we have to
        // trace it back to the state of each def and insert save at that state.
        boost::optional<ParserRValDef> preferred_source;

        bool operator<(const UnresolvedSelect& other) const {
            return source() < other.source();
        }

        std::string to_string() const {
            std::stringstream ss;
            ss << "[";
            ss << select << " ... ";
            for (const auto& r : used_by_others) {
                ss << r << " "; }
            ss << "]";
            return ss.str();
        }

        // The absolute offset that this select match on for current state's
        // input buffer.
        nw_bitrange source() const {
            const IR::BFN::InputBufferRVal* buf = nullptr;
            if (preferred_source) {
                buf = (*preferred_source).rval->to<IR::BFN::InputBufferRVal>();
            } else {
                buf = select->source->to<IR::BFN::InputBufferRVal>();
            }

            if (buf) {
                return buf->range().shiftedByBytes(byte_shifted);
            } else {
                ::error("select on a field that is impossible to implement for hardware, "
                        "likely selecting on a field that is written by constants: %1%",
                        select);
                return nw_bitrange();
            }
        }

        bool
        isExtractedEarlier(const State* state) const {
            // For multipledef selects, only when state maches, source is meaningful.
            if (preferred_source) {
                return (*preferred_source).state->name != state->name;
            } else {
                return source().lo < 0; }
        }
    };

    // group of UnresolvedSelect's that can be packed together (adjacent in input buffer)
    class UnresolvedSelectGroup {
        std::vector<UnresolvedSelect> _members;

     public:
        std::vector<std::pair<MatchRegister, nw_bitrange>>
        calc_reg_slices_for_select(const UnresolvedSelect& unresolved,
                const std::vector<MatchRegister>& all_regs_for_this_group) const {
            std::vector<std::pair<MatchRegister, nw_bitrange>> reg_slices;

            nw_bitrange group_range = source();
            nw_bitrange select_range = unresolved.source();

            int group_start_bit_in_regs = group_range.lo % 8;
            int select_start_bit_in_regs = group_start_bit_in_regs +
                                           (select_range.lo - group_range.lo);

            nw_bitrange select_range_in_reg(StartLen(select_start_bit_in_regs,
                                                     select_range.size()));

            int curr_reg_start = 0;
            for (auto& reg : all_regs_for_this_group) {
                int reg_size_in_bit = reg.size * 8;

                nw_bitrange curr_reg_range(StartLen(curr_reg_start, reg_size_in_bit));
                auto intersect = toClosedRange(select_range_in_reg.intersectWith(curr_reg_range));

                if (intersect) {
                    nw_bitrange range_in_reg = (*intersect).shiftedByBits(-curr_reg_start);
                    auto slice = std::make_pair(reg, range_in_reg);
                    reg_slices.push_back(slice);
                }

                curr_reg_start += reg_size_in_bit;
            }

            return reg_slices;
        }

        const std::vector<UnresolvedSelect>& members() const { return _members; }

        nw_bitrange source() const {
            nw_bitrange rv(INT_MAX, INT_MIN);

            for (auto& unresolved : members()) {
                auto source = unresolved.source();
                rv = rv.unionWith(source);
            }
            return rv;
        }

        static bool can_join(const UnresolvedSelect& a, const UnresolvedSelect& b) {
            nw_bitrange srca = a.source();
            nw_bitrange srcb = b.source();
            return (srca.hi + 1) == srcb.lo;
        }

        bool contains(const UnresolvedSelect& a) const {
            for (auto& unresolved : members()) {
                if (a.select == unresolved.select)
                    return true;
            }
            return false;
        }

        bool join(const UnresolvedSelect& unresolved) {
            if (members().empty() || contains(unresolved) ||
                can_join(last(), unresolved)) {
                _members.push_back(unresolved);
                return true;
            }

            return false;
        }

        UnresolvedSelect& last() {
            return _members.back();
        }

        void debug_print() const {
            if (LOGGING(4))
                for (auto& s : members())
                    LOG4(s.to_string());
        }
    };

    profile_t init_apply(const IR::Node* root) override {
        state_unresolved_selects.clear();
        unprocessed_states.clear();
        transition_saves.clear();
        select_groups.clear();
        select_reg_slices.clear();
        additional_states.clear();
        return Inspector::init_apply(root);
    }

    void postorder(const State* state) override {
        LOG4(">> Inserting Saves on " << state->name);
        // Mark state_unresolved_selects for this state
        for (const auto* select : state->selects) {
            if (auto* computed = select->source->to<IR::BFN::ComputedRVal>()) {
                LOG3("Select on multi-defined rvalue: " << select);
                for (auto& def : multiDefValues.at(computed)) {
                    LOG3("  ..Defined at : " << def.state->name << ", " << def.rval);
                    state_unresolved_selects[state].push_back(
                            UnresolvedSelect(select, 0, { }, def));
                }
            } else {
                state_unresolved_selects[state].push_back(
                        UnresolvedSelect(select, 0, { }));
            }
        }

        unprocessed_states.insert(state);
        calcSaves(state);
    }

    /// For all unresolved selects that reach this point, separate out selects
    /// that should be processed in this state and those should be processed in an earlier state.
    /// Unresolved selects are sorted by whether has decided register, then the size of select.
    void calcUnresolvedSelects(
            std::vector<UnresolvedSelect>& unresolved_selects,
            std::vector<UnresolvedSelect>& early_state_extracted,
            const std::map<const StateSelect*, nw_bitrange>& corrected_source,
            const State* state,
            const State* next_state,
            unsigned shift_bytes) {
        for (const auto& unresolved : calcUnresolvedSelects(next_state, shift_bytes)) {
            // Wrongly trace-backd select, ignored.
            if (corrected_source.count(unresolved.select)
                && unresolved.source() != corrected_source.at(unresolved.select)) {
                continue; }
            if (unresolved.isExtractedEarlier(state)) {
                early_state_extracted.push_back(unresolved);
            } else {
                unresolved_selects.push_back(unresolved);
            }
        }
        // Sorted by whether has decided register, the size of select.
        std::sort(unresolved_selects.begin(), unresolved_selects.end(),
             [&] (const UnresolvedSelect& l, const UnresolvedSelect& r) {
                 if (select_groups.count(l.select) && select_groups.count(r.select)) {
                     auto count_l = select_reg_slices.count(l.select);
                     auto count_r = select_reg_slices.count(r.select);

                     if (count_l != count_r)
                         return count_l > count_r;
                 }

                 return l.source().size() < r.source().size();
             });
    }

    /// @returns a vector of all match resigers sorted by size, increasing.
    std::vector<MatchRegister> getMatchRegistersSortedBySize() {
        auto registers = Device::pardeSpec().matchRegisters();
        std::sort(registers.begin(), registers.end(),
                  [] (const MatchRegister& a, const MatchRegister& b) {
                      return a.size < b.size; });
        return registers;
    }

    /// For byte @p i on the input buffer, find a match register that already saved
    /// byte i in, and valid for @p unresolved.
    boost::optional<MatchRegister>
    findSavedRegForByte(
            int i,
            const UnresolvedSelectGroup* unresolved_group,
            const std::map<nw_byterange, MatchRegister>& saved_range,
            const std::map<const StateSelect*, std::set<MatchRegister>>& used_by_other_path) {
        for (int reg_size : {1, 2}) {
            nw_byterange reg_range = nw_byterange(StartLen(i, reg_size));
            if (saved_range.count(reg_range)) {
                auto& reg = saved_range.at(reg_range);
                // If this reg is used by others, we can not reuse it's result.
                bool used_by_others = false;
                for (auto& unresolved : unresolved_group->members()) {
                    if (used_by_other_path.count(unresolved.select)
                        && used_by_other_path.at(unresolved.select).count(reg)) {
                        used_by_others = true;
                        break;
                    }
                }
                if (used_by_others)
                    continue;

                return reg;
            }
        }
        return boost::none;
    }

    /// Return a vector of match registers that address the @p unresolved.
    boost::optional<std::vector<MatchRegister>>
    allocMatchRegisterForSelectGroup(
            const UnresolvedSelectGroup* unresolved_group,
            const std::map<nw_byterange, MatchRegister>& saved_range,
            const std::set<MatchRegister>& used_registers,
            const std::map<const StateSelect*, std::set<MatchRegister>>& used_by_other_path) {
        for (auto& unresolved : unresolved_group->members()) {
            auto select = unresolved.select;
            auto select_group = select_groups.at(select);

            if (select_group_registers.count(select_group)) {
                // If the select has already be set by other branch,
                // this branch need to follow it's decision.
                // already saved in this state.
                auto& regs = select_group_registers.at(select_group);

                bool has_conflict =
                    std::any_of(regs.begin(), regs.end(), [&] (const MatchRegister& r) -> bool {
                        return unresolved.used_by_others.count(r); });
                if (!has_conflict) {
                    return regs;
                } else {
                    ::error("Cannot allocate parser match register for %1%.\n"
                            "Consider shrinking the live range of select fields or reducing the"
                            " number of select fields that are being matched in the same state"
                            , select);
                }
                return boost::none;
            }
        }

        // TODO(yumin):
        // We should have an algorithm that minimizes the use the
        // register, e.g. use half to cover two small field,
        // instead of this naive one.
        std::vector<MatchRegister> accumulated_regs;
        std::set<MatchRegister> in_candidates;

        // calculate which regs to use for each byte.
        nw_byterange source = unresolved_group->source().toUnit<RangeUnit::Byte>();

        for (int i = source.loByte(); i <= source.hiByte();) {
            auto already_save_in =
                findSavedRegForByte(i, unresolved_group, saved_range, used_by_other_path);

            if (already_save_in) {
                LOG4("re-used " << *already_save_in << " because byte " << i << " are shared");
                accumulated_regs.push_back(*already_save_in);
                i += (*already_save_in).size;
                continue;
            }

            bool found_reg_for_this_byte = false;
            for (auto& reg : getMatchRegistersSortedBySize()) {
                if (in_candidates.count(reg))
                    continue;

                if (used_registers.count(reg))
                    continue;

                bool reg_already_used = false;
                for (auto& unresolved : unresolved_group->members()) {
                    if (unresolved.used_by_others.count(reg)) {
                        reg_already_used = true;
                        break;
                    }
                    if (used_by_other_path.count(unresolved.select)
                        && used_by_other_path.at(unresolved.select).count(reg)) {
                        reg_already_used = true;
                        break;
                    }
                }
                if (reg_already_used)
                    continue;

                accumulated_regs.push_back(reg);
                i += reg.size;
                found_reg_for_this_byte = true;
                in_candidates.insert(reg);
                break;
            }

            if (!found_reg_for_this_byte) {
                LOG3("Can not find match register for byte " << i << " for:");
                unresolved_group->debug_print();
                return boost::none;
            }
        }
        return accumulated_regs;
    }

    std::vector<UnresolvedSelectGroup*>
    packUnresolvedSelects(const std::vector<UnresolvedSelect>& unresolved_selects) {
        std::vector<UnresolvedSelectGroup*> packed_groups;

        for (auto& unresolved : unresolved_selects) {
            bool foundUnion = false;

            for (auto& group : packed_groups) {
                foundUnion = group->join(unresolved);

                if (foundUnion) {
                    select_groups[unresolved.select] = group;
                    break;
                }
            }

            if (!foundUnion) {
                auto* new_group = new UnresolvedSelectGroup;
                new_group->join(unresolved);
                select_groups[unresolved.select] = new_group;
                packed_groups.push_back(new_group);
            }
        }

        auto sort_by_group_size = [&](UnresolvedSelectGroup* l, UnresolvedSelectGroup* r) {
            return l->source().size() < r->source().size();
        };

        std::sort(packed_groups.begin(), packed_groups.end(), sort_by_group_size);

        if (LOGGING(4)) {
            LOG4("Created " << packed_groups.size() << " unresolved select groups");
            for (auto group : packed_groups)
                group->debug_print();
        }

        return packed_groups;
    }

    void calcSaves(const State* state) {
        // For multi-def sources, we need to calculate the corrected_source and used_regs
        // across different branches.
        std::map<const StateSelect*, nw_bitrange> corrected_source;
        std::map<const StateSelect*, std::set<MatchRegister>> used_by_other_path;

        calcCorrectSourceAndUsedReg(state, corrected_source, used_by_other_path);

        // For each transition branch, calculate the saves and corresponding select.
        for (const auto* transition : state->transitions) {
            BUG_CHECK(transition->shift, "State %1% has unset shift?", state->name);
            BUG_CHECK(*transition->shift >= 0, "State %1% has negative shift %2%?",
                      state->name, *transition->shift);
            if (!transition->next) {
                continue; }

            auto next_state = transition->next;
            unprocessed_states.erase(next_state);
            LOG4("For transition to: " << next_state->name);

            // Get unresolved selects by merge all child state's unresolved selects.
            std::vector<UnresolvedSelect> unresolved_selects;
            std::vector<UnresolvedSelect> early_state_extracted;

            calcUnresolvedSelects(unresolved_selects,
                                  early_state_extracted,
                                  corrected_source,
                                  state,
                                  next_state,
                                  *(transition->shift));

            auto packed_unresolved_selects = packUnresolvedSelects(unresolved_selects);

            // Mapping input buffer to a register that save it.
            std::map<nw_byterange, MatchRegister> saved_range;
            std::set<MatchRegister> used_registers;
            std::set<const StateSelect*> resolved_in_this_transition;

            for (auto unresolved_group : packed_unresolved_selects) {
                auto reg_choice = allocMatchRegisterForSelectGroup(
                        unresolved_group, saved_range, used_registers, used_by_other_path);
                // Cannot find a register or the found one has been used
                // by downstream states because of brother's decision.
                if (!reg_choice) {
                    // throw error message saying that it's impossible.
                    ::error("Ran out of parser match registers for %1%", state->name);
                    for (auto& unresolved : unresolved_group->members())
                        ::error("%1%", unresolved.select->p4Source);

                    return;
                }

                if (LOGGING(4)) {
                    for (const auto& reg : *reg_choice) {
                        LOG4("Assign: " << reg << " to");
                        for (auto& unresolved : unresolved_group->members())
                            LOG4("  " << unresolved.select->p4Source);

                        LOG4("From: " << state->name << " to " << next_state->name);
                    }
                }

                // Assign registers and update match_saves
                nw_byterange source = unresolved_group->source().toUnit<RangeUnit::Byte>();
                nw_byterange save_range_itr = source;

                for (const auto& r : *reg_choice) {
                    nw_byterange range_of_this_register = save_range_itr.resizedToBytes(r.size);
                    if (!saved_range.count(range_of_this_register)) {
                        transition_saves[transition].push_back(
                                new IR::BFN::SaveToRegister(r, range_of_this_register));
                        saved_range[range_of_this_register] = r;
                    }
                    save_range_itr = save_range_itr.shiftedByBytes(r.size);
                }

                for (auto& unresolved : unresolved_group->members())
                    resolved_in_this_transition.insert(unresolved.select);

                unsigned total_bits_in_regs = 0;

                for (auto& unresolved : unresolved_group->members()) {
                    auto reg_slices = unresolved_group->calc_reg_slices_for_select(unresolved,
                                                                           *reg_choice);
                    for (auto rs : reg_slices)
                        total_bits_in_regs += rs.second.size();

                    select_reg_slices[unresolved.select] = reg_slices;
                }

                select_group_registers[unresolved_group] = *reg_choice;
                used_registers.insert((*reg_choice).begin(), (*reg_choice).end());
            }

            // If there are remaining selects that need to be extracted in an earlier state,
            // update the used registers on this transition.
            // Note that, though registers used in this state will 'start to live' in the next
            // state, it should be added because those remaining_unresolved selects 'start to live'
            // in next state as well.
            for (const auto& remaining_unresolved : early_state_extracted) {
                // If the select is resolved in this state, parent defs go over this state
                // does not need to be saved, like the W => W => R situation.
                if (resolved_in_this_transition.count(remaining_unresolved.select))
                    continue;

                auto unresolved = remaining_unresolved;

                for (auto r : used_registers)
                    unresolved.used_by_others.insert(r);

                state_unresolved_selects[state].push_back(unresolved);
                LOG5("Add Unresolved in `" << state->name << "` " << unresolved.select);
            }
        }  // for transition
    }

    void end_apply() override {
        // Add all unresolved select to a dummy state.
        auto unprocessed_copy = unprocessed_states;
        for (const auto* state : unprocessed_copy) {
            auto gress = state->thread();
            BUG_CHECK(additional_states.count(gress) == 0,
                      "More than one start state for init parser match word on %1%", gress);
            auto* transition = new IR::BFN::Transition(match_t(), 0, state);
            auto* init_state = new IR::BFN::ParserState(
                    createThreadName(gress, "$_save_init_state"), gress, { }, { }, { transition });
            calcSaves(init_state);
            if (transition_saves.count(transition)
                && transition_saves[transition].size() > 0) {
                additional_states[gress] = init_state; }
        }
        BUG_CHECK(unprocessed_states.size() == 0,
                  "Unprocessed states remaining");
    }

    /// @returns all unresolved select from @p next_state.
    std::vector<UnresolvedSelect>
    calcUnresolvedSelects(const State* next_state, unsigned shift_bytes) {
        // For the state_unresolved_selects from children state,
        // The range in this state used to save should be range + shift.
        std::vector<UnresolvedSelect> rst;
        for (const auto& s : state_unresolved_selects[next_state]) {
            UnresolvedSelect for_this_state(s);
            for_this_state.byte_shifted += shift_bytes;
            rst.push_back(for_this_state);
        }

        // sort selects based on position in input buffer
        std::sort(rst.begin(), rst.end());

        return rst;
    }

    /// For this @p state, what is the correct source for those computed value
    /// and for those source, what are match registers that have beeen used.
    void
    calcCorrectSourceAndUsedReg(
            const State* state,
            std::map<const StateSelect*, nw_bitrange>& corrected_source,
            std::map<const StateSelect*, std::set<MatchRegister>>& used_regs) {
        // Count all selects.
        std::map<std::pair<const StateSelect*, nw_bitrange>, int> select_count;
        ordered_set<const StateSelect*> selects;
        for (const auto* transition : state->transitions) {
            BUG_CHECK(transition->shift, "State %1% has unset shift?", state->name);
            BUG_CHECK(*transition->shift >= 0, "State %1% has negative shift %2%?",
                      state->name, *transition->shift);

            auto next_state = transition->next;
            unsigned shift_bytes = *transition->shift;
            if (!next_state) continue;

            // Get unresolved selects by merge all child state's unresolved selects.
            auto unresolved_selects = calcUnresolvedSelects(next_state, shift_bytes);
            for (const auto& select : unresolved_selects) {
                if (select.isExtractedEarlier(state)) continue;
                selects.insert(select.select);
                select_count[{select.select, select.source()}]++; }
        }

        // Find out selects that show up more than once, calculate right source.
        ordered_map<const StateSelect*, nw_bitrange> temp_corrected_source;
        for (const auto* select : selects) {
            int max_count = -1;
            for (const auto& kv : select_count) {
            LOG5("Select-Count: " << kv.first.first << " on "
                 << kv.first.second << " c: " << kv.second);
                if (kv.second <= 1) continue;
                if (select != kv.first.first) continue;
                if (kv.second > max_count) {
                    temp_corrected_source[select] = kv.first.second;
                    max_count = kv.second;
                    LOG5("Corrected Souce of `" << select << "` ..is.. " << kv.first.second);
                }
            }
        }

        for (const auto& kv : temp_corrected_source) {
            const auto* select_use = kv.first;
            auto& source = kv.second;

            BUG_CHECK(corrected_source.count(select_use)
                      ? corrected_source.at(select_use) == source : true,
                      "Parser bug in calculating source for: %1%", select_use->p4Source);
            corrected_source[select_use] = source;

            // Merge all used register set.
            for (const auto* transition : state->transitions) {
                if (!transition->next)
                    continue;
                auto* next_state = transition->next;
                unsigned shift_bytes = *(transition->shift);
                auto unresolved_selects = calcUnresolvedSelects(next_state, shift_bytes);

                for (const auto& select : unresolved_selects) {
                    if (select.select == select_use && source == select.source()) {
                        used_regs[select_use].insert(select.used_by_others.begin(),
                                                     select.used_by_others.end()); } }
            }
        }
    }

    // For unresolved computed values.
    const ParserValueResolution& multiDefValues;
    std::map<const State*, std::vector<UnresolvedSelect>> state_unresolved_selects;
    ordered_set<const State*> unprocessed_states;

 public:
    explicit ComputeSaveAndSelect(const ParserValueResolution& m)
        : multiDefValues(m) { }

 public:
    // The saves need to be executed on this transition.
    std::map<const StateTransition*, std::vector<const IR::BFN::SaveToRegister*>> transition_saves;

    // select to group it belongs to
    std::map<const StateSelect*, const UnresolvedSelectGroup*> select_groups;

    // The register slices that this select should match against.
    std::map<const IR::BFN::Select*,
             std::vector<std::pair<MatchRegister, nw_bitrange>>> select_reg_slices;

    // The registers that this select group should match against.
    std::map<const UnresolvedSelectGroup*, std::vector<MatchRegister>> select_group_registers;

    // The additional state that should be prepended to the start state
    // to generate save for the select on the first state.
    std::map<gress_t, IR::BFN::ParserState*> additional_states;
};

struct WriteBackSaveAndSelect : public ParserModifier {
    explicit WriteBackSaveAndSelect(const ComputeSaveAndSelect& saves)
        : rst(saves) { }

    bool preorder(IR::BFN::Parser* parser) override {
        auto gress = parser->gress;
        if (rst.additional_states.count(gress) > 0) {
            parser->start = rst.additional_states.at(gress); }
        return true;
    }

    void postorder(IR::BFN::Transition* transition) override {
        auto* original_transition = getOriginal<IR::BFN::Transition>();
        if (rst.transition_saves.count(original_transition)) {
            for (const auto* save : rst.transition_saves.at(original_transition)) {
                transition->saves.push_back(save); }
        }
    }

    void postorder(IR::BFN::Select* select) override {
        auto* original_select = getOriginal<IR::BFN::Select>();
        if (rst.select_reg_slices.count(original_select)) {
            select->reg_slices = rst.select_reg_slices.at(original_select);
        }
    }

    const ComputeSaveAndSelect& rst;
};

/** A helper class for adjusting match value.
 */
class MatchRegisterLayout {
 private:
    std::vector<MatchRegister> all_regs;
    std::map<MatchRegister, match_t> values;
    size_t total_size;

    match_t shiftRight(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 >>= n;
        word1 >>= n;
        return match_t(word0, word1);
    }

    match_t shiftLeft(match_t val, int n) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        word0 <<= n;
        word1 <<= n;
        return match_t(word0, word1);
    }

    match_t orTwo(match_t a, match_t b) {
        auto word0 = (a.word0 | b.word0);
        auto word1 = (a.word1 | b.word1);
        return match_t(word0, word1);
    }

    match_t setWild(match_t a) {
        auto word0 = a.word0;
        auto word1 = a.word1;
        auto wilds = (~(word0 ^ word1)) & (~((~uintmax_t(0)) << total_size));
        return match_t(word0 | wilds, word1 | wilds);
    }

    // start is the from the left
    match_t getSubValue(match_t val, int sz, int start, int len) {
        auto word0 = val.word0;
        auto word1 = val.word1;
        uintmax_t mask = (~((~uintmax_t(0)) << (sz - start)));
        auto trim_left_word0 = (word0 & mask);
        auto trim_left_word1 = (word1 & mask);
        return shiftRight(match_t(trim_left_word0, trim_left_word1), sz - start - len);
    }

 public:
    explicit MatchRegisterLayout(ordered_set<MatchRegister> used_regs)
        : total_size(0) {
        for (const auto& r : used_regs) {
            total_size += r.size * 8;
            all_regs.push_back(r);
            values[r] = match_t(0, 0); }
    }

    void writeValue(const IR::BFN::Select* select, match_t val) {
        auto& reg_slices = select->reg_slices;

        int val_size = 0;
        int val_shifted = 0;

        for (auto rs : reg_slices)
            val_size += rs.second.size();

        for (auto& slice : reg_slices) {
            auto& reg = slice.first;
            auto& reg_sub_range = slice.second;

            nw_bitrange reg_range(0, reg.size * 8 - 1);
            BUG_CHECK(reg_range.contains(reg_sub_range),
                      "range not part of parser match register?");

            match_t slice_val = getSubValue(val, val_size, val_shifted, reg_sub_range.size());
            match_t val_to_or = shiftLeft(slice_val, reg.size * 8 - reg_sub_range.hi - 1);

            values[reg] = orTwo(values[reg], val_to_or);
            val_shifted += reg_sub_range.size();
        }

        BUG_CHECK(val_shifted == val_size, "value not entirely shifted?");
    }

    match_t getMatchValue() {
        int shift = 0;
        match_t rtn(0, 0);
        for (const auto& r : boost::adaptors::reverse(all_regs)) {
            rtn = orTwo(rtn, shiftLeft(values[r], shift));
            shift += r.size * 8;
        }
        return setWild(rtn);
    }
};

struct AdjustMatchValue : public ParserModifier {
    void postorder(IR::BFN::Transition* transition) override {
        if (transition->value->is<IR::BFN::ParserConstMatchValue>()) {
            adjustConstValue(transition);
        } else if (transition->value->is<IR::BFN::ParserPvsMatchValue>()) {
            adjustPvsValue(transition);
        } else {
            BUG("Unknown match value: %1%", transition->value);
        }
    }

    /// Adjust the transition value to a match_t that:
    ///   1. match_t value's size = sum of size of all used registers.
    ///   2. values are placed into their `slot` in match_t value.
    void adjustConstValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        ordered_set<MatchRegister> used_registers;
        for (const auto* select : state->selects) {
            for (const auto& rs : select->reg_slices) {
                used_registers.insert(rs.first); } }

        // Pop out value for each select.
        auto const_val = transition->value->to<IR::BFN::ParserConstMatchValue>()->value;
        uintmax_t word0 = const_val.word0;
        uintmax_t word1 = const_val.word1;
        auto shiftOut = [&word0, &word1] (int sz) {
            uintmax_t mask = ~(~uintmax_t(0) << sz);
            uintmax_t sub0 = (word0 & mask);
            uintmax_t sub1 = (word1 & mask);
            word0 >>= sz;
            word1 >>= sz;
            return match_t(sub0, sub1); };

        std::map<const IR::BFN::Select*, match_t> select_values;
        for (const auto* select : boost::adaptors::reverse(state->selects)) {
            int value_size = 0;
            for (auto rs : select->reg_slices) {
                auto mask = rs.second;
                value_size += mask.size();
            }
            select_values[select] = shiftOut(value_size);
        }

        MatchRegisterLayout layout(used_registers);
        for (const auto* select : state->selects) {
            layout.writeValue(select, select_values[select]);
        }
        transition->value = new IR::BFN::ParserConstMatchValue(layout.getMatchValue());
    }

    /// Build a mapping from fieldslice to matcher slice by checking the field
    /// where the select originally matched on and the masking of the registers.
    void adjustPvsValue(IR::BFN::Transition* transition) {
        auto* state = findContext<IR::BFN::ParserState>();
        auto* old_value = transition->value->to<IR::BFN::ParserPvsMatchValue>();
        auto* adjusted = new IR::BFN::ParserPvsMatchValue(old_value->name, old_value->size);

        for (const auto* select : state->selects) {
            cstring field_name = select->p4Source->toString();

            int field_start = 0;
            for (const auto& rs : boost::adaptors::reverse(select->reg_slices)) {
                auto reg = rs.first;
                auto reg_slice = rs.second.toOrder<Endian::Little>(reg.size * 8);

                nw_bitrange field_slice(StartLen(field_start, reg_slice.size()));
                adjusted->mapping[{field_name, field_slice}] =  {reg, reg_slice};

                LOG3("PVS add mapping: " << field_name << field_slice << " -> "
                     << reg << reg_slice);

                field_start += field_slice.size();
            }
        }

        transition->value = adjusted;
    }
};

struct CheckAllocation : public Inspector {
    bool preorder(const IR::BFN::Select* select) override {
        BUG_CHECK(select->reg_slices.size() > 0,
            "Parser match register not allocated for %1%", select);
        return false;
    }
};

AllocateParserMatchRegisters::AllocateParserMatchRegisters(
    const ParserValueResolution& multiDefValues) {
    auto* computeSaveAndSelect = new ComputeSaveAndSelect(multiDefValues);
    addPasses({
        LOGGING(3) ? new DumpParser("before_parser_match_alloc") : nullptr,
        computeSaveAndSelect,
        new WriteBackSaveAndSelect(*computeSaveAndSelect),
        new AdjustMatchValue,
        new CheckAllocation,
        LOGGING(3) ? new DumpParser("after_parser_match_alloc") : nullptr,
    });
}
