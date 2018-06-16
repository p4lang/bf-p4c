#include "bf-p4c/parde/merge_parser_state.h"

#include <vector>
#include <map>
#include "lib/ordered_map.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace {

struct CollectStateUses : public ParserInspector {
    using State = IR::BFN::ParserState;
    bool preorder(const IR::BFN::ParserState* state) {
        match_reg_def[state] = {};
        match_reg_use[state] = {};
        if (!n_transition_to.count(state))
            n_transition_to[state] = 0;

        for (const auto* transition : state->transitions) {
            auto* next_state = transition->next;
            if (!next_state) continue;

            n_transition_to[next_state]++;
            // for saves => match_reg def
            for (const auto* save : transition->saves) {
                match_reg_def[state].insert(save->dest); }
        }

        // for select => match_reg use
        for (const auto* select : state->selects)
            for (const auto& r : select->reg)
                match_reg_use[state].insert(r);

        return true;
    }

    Visitor::profile_t init_apply(const IR::Node* root) {
        match_reg_def.clear();
        match_reg_use.clear();
        n_transition_to.clear();
        return ParserInspector::init_apply(root);
    }

    std::map<const State*, std::set<MatchRegister>> match_reg_def;
    std::map<const State*, std::set<MatchRegister>> match_reg_use;
    std::map<const State*, int> n_transition_to;
};

class ComputeMergeableState : public ParserInspector {
    using State = IR::BFN::ParserState;

 public:
    explicit ComputeMergeableState(const CollectStateUses& uses)
        : match_reg_def(uses.match_reg_def),
          match_reg_use(uses.match_reg_use),
          n_transition_to(uses.n_transition_to) { }

 private:
    void postorder(const IR::BFN::ParserState* state) {
        // If branching, can not fold in any children node.
        if (state->transitions.size() > 1)
            return;

        // Termination State
        if (state->transitions.size() == 0)
            return;

        auto* transition = *state->transitions.begin();
        auto* next_state = transition->next;

        if (!next_state)
            return;

        // Not a wild match
        if (!is_wild(transition->value))
            return;

        // if the next is merge_point, nothing
        if (is_merge_point(next_state))
            return;

        // find the singleton match but has select reg dependency
        if (intersect(match_reg_def.at(state), match_reg_use.at(next_state)))
            return;

        // mark merge-able (B, A) or if there is any(**, B), make it (**, B, A);
        // as long as there is not any select reg conflict.
        std::vector<const State*> state_chain = getStateChain(next_state);
        for (const auto* other : state_chain)
            if (intersect(match_reg_def.at(state), match_reg_use.at(other)))
                return;

        state_chain.push_back(state);
        state_chains[state] = state_chain;
        state_chains.erase(next_state);
    }

    void end_apply() {
        // forall merging vector, create the new state, save it to result
        for (const auto& kv : state_chains) {
            if (kv.second.size() < 2) {
                continue; }
            auto* merged_state = createMergedState(kv.second);
            results[kv.first] = merged_state;
        }
    }

    State* createMergedState(const std::vector<const State*> states) {
        int shifted = 0;
        const State* tail = states.front();
        std::stringstream name;

        IR::Vector<IR::BFN::ParserPrimitive>    extractions;
        IR::Vector<IR::BFN::SaveToRegister>     saves;

        // For all states expect for the tail, crush them.
        for (auto itr = states.rbegin(); itr < states.rend() - 1; ++itr) {
            auto& st = *itr;
            BUG_CHECK(st->transitions.size() == 1,
                      "branching state can not be merged, unless the last");
            auto* transition = *st->transitions.begin();
            for (const auto* stmt : st->statements) {
                if (auto* extract = stmt->to<IR::BFN::Extract>()) {
                    extractions.push_back(rightShiftSource(extract, shifted));
                } else if (auto* add_checksum = stmt->to<IR::BFN::ChecksumAdd>()) {
                    extractions.push_back(rightShiftSource(add_checksum, shifted));
                } else {
                    extractions.push_back(stmt);
                }
            }
            for (const auto* save : transition->saves) {
                saves.push_back(rightShiftSource(save, shifted)); }
            name << strip_common_prefix(name.str(), strip_gress(st->name).c_str()) << ".";
            shifted += *transition->shift;
        }

        // Include extractions of the last state.
        for (const auto* stmt : tail->statements) {
            if (auto* extract = stmt->to<IR::BFN::Extract>()) {
                extractions.push_back(rightShiftSource(extract, shifted));
            } else if (auto* add_checksum = stmt->to<IR::BFN::ChecksumAdd>()) {
                extractions.push_back(rightShiftSource(add_checksum, shifted));
            } else {
                extractions.push_back(stmt); }
        }

        name << strip_common_prefix(name.str(), strip_gress(tail->name).c_str());

        auto* merged_state = new IR::BFN::ParserState(nullptr, cstring(name), tail->gress);
        merged_state->selects = tail->selects;
        merged_state->statements = extractions;
        for (const auto* transition : tail->transitions) {
            auto* new_transition = createMergedTransition(shifted, transition, saves);
            merged_state->transitions.push_back(new_transition);
        }

        return merged_state;
    }

    IR::BFN::Transition* createMergedTransition(
            int shifted,
            const IR::BFN::Transition* prev_transition,
            const IR::Vector<IR::BFN::SaveToRegister>& prev_saves) {
        IR::Vector<IR::BFN::SaveToRegister> saves = prev_saves;
        for (const auto* save : prev_transition->saves) {
            saves.push_back(rightShiftSource(save, shifted)); }
        auto* rst = new IR::BFN::Transition(
                prev_transition->value,
                *prev_transition->shift + shifted,
                prev_transition->next);
        rst->saves = saves;
        return rst;
    }

    std::vector<const State*> getStateChain(const State* state) {
        if (!state_chains.count(state))
            state_chains[state] = { state };
        return state_chains.at(state);
    }

    /// Shift all input packet extracts to the right by the given
    /// amount. Works for SaveToRegister and Extract.
    /// The coordinate system:
    /// [0............31]
    /// left..........right
    template<class T>
    T*
    rightShiftSource(T* primitive, int byteDelta) {
        const IR::BFN::PacketRVal* source =
            primitive->source->template to<typename IR::BFN::PacketRVal>();

        // Do not need to shift it's not packetRval
        if (!source) return primitive;

        const auto shiftedRange = source->range().shiftedByBytes(byteDelta);
        BUG_CHECK(shiftedRange.lo >= 0, "Shifting extract to negative position.");
        auto* clone = primitive->clone();
        clone->source = new IR::BFN::PacketRVal(shiftedRange);
        return clone;
    }

    bool intersect(const std::set<MatchRegister>& a,
                   const std::set<MatchRegister>& b) {
        for (const auto& reg : a)
            if (b.count(reg) > 0)
                return true;
        return false;
    }

    bool is_merge_point(const State* state) {
        return n_transition_to.at(state) > 1;
    }

    bool is_wild(const IR::BFN::ParserMatchValue* value) {
        if (auto* const_value = value->to<IR::BFN::ParserConstMatchValue>()) {
            return (const_value->value.word0 ^ const_value->value.word1) == 0; }
        return false;
    }

    cstring strip_gress(cstring name) {
        auto p = name.findlast(':');
        if (p)
            return cstring(p + 1);
        else
            return name;
    }

    cstring strip_common_prefix(std::string current, std::string to_append) {
        int sz = std::min(current.size(), to_append.size());
        int i = 0;
        while (i < sz && current[i] == to_append[i]) {
            i++; }
        if (i >= 5) {  // "parse" has 5 chars.
            return to_append.substr(i);
        } else {
            return to_append;
        }
    }

    Visitor::profile_t init_apply(const IR::Node* root) {
        state_chains.clear();
        results.clear();
        return ParserInspector::init_apply(root);
    }

    const std::map<const State*, std::set<MatchRegister>>& match_reg_def;
    const std::map<const State*, std::set<MatchRegister>>& match_reg_use;
    const std::map<const State*, int>& n_transition_to;
    ordered_map<const State*, std::vector<const State*>> state_chains;

 public:
    // A serie of states starting from `key` can be merged into one `value`.
    std::map<const State*, State*> results;
};

struct WriteBackMergedState : public ParserModifier {
    explicit WriteBackMergedState(const ComputeMergeableState& cms)
        : replace_map(cms.results) { }

    bool preorder(IR::BFN::Parser* parser) override {
        auto* original_parser = getOriginal<IR::BFN::Parser>();
        if (replace_map.count(original_parser->start)) {
            LOG4("Replacing " << parser->gress << " parser start " << parser->start->name
                 << " with " << replace_map.at(original_parser->start)->name);
            parser->start = replace_map.at(original_parser->start);
        }
        return true;
    }

    bool preorder(IR::BFN::Transition* transition) override {
        auto* original_transition = getOriginal<IR::BFN::Transition>();
        auto* next = original_transition->next;
        if (replace_map.count(next)) {
            LOG4("Replacing " << transition->next->name << " with "
                 << replace_map.at(next)->name);
            transition->next = replace_map.at(next);
        }
        return true;
    }

    const std::map<const IR::BFN::ParserState*, IR::BFN::ParserState*>& replace_map;
};

}  // namespace

MergeParserStates::MergeParserStates() {
    auto* collectStateUses = new CollectStateUses();
    auto* computeMergeableState = new ComputeMergeableState(*collectStateUses);
    addPasses({
        collectStateUses,
        computeMergeableState,
        new WriteBackMergedState(*computeMergeableState),
        LOGGING(3) ? new DumpParser("merge_parser_states.dot") : nullptr
    });
}
