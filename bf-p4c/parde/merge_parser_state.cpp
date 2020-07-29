#include "bf-p4c/parde/merge_parser_state.h"

#include <vector>
#include <map>
#include "lib/ordered_map.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace {

struct CollectStateUses : public ParserInspector {
    using State = IR::BFN::ParserState;
    bool preorder(const IR::BFN::ParserState* state) {
        if (!n_transition_to.count(state))
            n_transition_to[state] = 0;

        for (const auto* transition : state->transitions) {
            auto* next_state = transition->next;
            if (!next_state) continue;

            n_transition_to[next_state]++;
        }

        return true;
    }

    Visitor::profile_t init_apply(const IR::Node* root) {
        n_transition_to.clear();
        return ParserInspector::init_apply(root);
    }

    std::map<const State*, int> n_transition_to;
};

/// Shift all input packet extracts to the right by the given
    /// amount. Works for SaveToRegister and Extract.
    /// The coordinate system:
    /// [0............31]
    /// left..........right
struct RightShiftPacketRVal : public Modifier {
    int byteDelta = 0;
    explicit RightShiftPacketRVal(int byteDelta) : byteDelta(byteDelta) { }
    bool preorder(IR::BFN::PacketRVal* rval) override {
        rval->range  = rval->range.shiftedByBytes(byteDelta);
        BUG_CHECK(rval->range.lo >= 0, "Shifting extract to negative position.");
        return true;
    }
};

class ComputeMergeableState : public ParserInspector {
    using State = IR::BFN::ParserState;

 public:
    explicit ComputeMergeableState(const CollectStateUses& uses)
        : n_transition_to(uses.n_transition_to) { }

 private:
    void postorder(const IR::BFN::ParserState* state) {
        // If branching, cannot fold in any children node.
        if (state->transitions.size() > 1)
            return;

        // Termination State
        if (state->transitions.size() == 0)
            return;

        auto* transition = *state->transitions.begin();
        auto* next_state = transition->next;

        if (!next_state)
            return;

        if (!is_dont_care(transition->value))
            return;

        if (is_merge_point(next_state))
            return;

        // TODO(zma) this could use more thoughts
        if (!next_state->selects.empty())
            return;

        // TODO(zma) more thoughts can be given to this
        for (auto stmt : next_state->statements) {
            if (stmt->is<IR::BFN::ParserCounterLoadPkt>())
                return;
        }

        std::vector<const State*> state_chain = getStateChain(next_state);

        LOG4("Add " << state->name << " to merge chain");

        state_chain.push_back(state);
        state_chains[state] = state_chain;
        state_chains.erase(next_state);
    }

    void end_apply() {
        // forall merging vector, create the new state, save it to result
        for (const auto& kv : state_chains) {
            if (kv.second.size() >= 2) {
                auto* merged_state = createMergedState(kv.second);
                results[kv.first] = merged_state;
            }
        }
    }

    bool is_compiler_generated(cstring name) {
        return name.startsWith("$");
    }

    State* createMergedState(const std::vector<const State*> states) {
        if (LOGGING(3)) {
            std::clog << "Creating merged state for:" << std::endl;
            for (auto s : states)
                std::clog << s->name << std::endl;
        }

        int shifted = 0;
        const State* tail = states.front();
        cstring name = "";

        IR::Vector<IR::BFN::ParserPrimitive>    extractions;
        IR::Vector<IR::BFN::SaveToRegister>     saves;

        // Merge all except the tail state.
        bool is_first = true;
        for (auto itr = states.rbegin(); itr != states.rend(); ++itr) {
            auto& st = *itr;
            BUG_CHECK(st->transitions.size() == 1,
                      "branching state can not be merged, unless the last");
            auto* transition = *st->transitions.begin();


            for (const auto* stmt : st->statements) {
                auto s = stmt->apply(RightShiftPacketRVal(shifted));
                extractions.push_back(s->to<IR::BFN::ParserPrimitive>());
            }
            for (const auto* save : transition->saves) {
                saves.push_back((save->apply(RightShiftPacketRVal
                            (shifted)))->to<IR::BFN::SaveToRegister>()); }

            cstring state_name = stripThreadPrefix(st->name);

            if (!is_compiler_generated(name) || !is_compiler_generated(state_name)) {
                if (!is_first) name += ".";
                name += state_name;
                is_first = false;
            }
            if (itr != states.rend() - 1) {
                for (const auto* save : transition->saves) {
                    saves.push_back((save->apply(RightShiftPacketRVal
                                (shifted)))->to<IR::BFN::SaveToRegister>()); }
                shifted += transition->shift;
            }
        }

        auto* merged_state = new IR::BFN::ParserState(nullptr, name, tail->gress);
        merged_state->selects = tail->selects;
        merged_state->statements = extractions;
        for (const auto* transition : tail->transitions) {
            auto* new_transition = createMergedTransition(shifted, transition, saves);
            merged_state->transitions.push_back(new_transition);
        }

        LOG3("Created " << merged_state->name);

        return merged_state;
    }

    IR::BFN::Transition* createMergedTransition(
            int shifted,
            const IR::BFN::Transition* prev_transition,
            const IR::Vector<IR::BFN::SaveToRegister>& prev_saves) {
        IR::Vector<IR::BFN::SaveToRegister> saves = prev_saves;
        for (const auto* save : prev_transition->saves) {
            saves.push_back((save->apply(RightShiftPacketRVal
                            (shifted)))->to<IR::BFN::SaveToRegister>()); }
        auto* rst = new IR::BFN::Transition(
                prev_transition->value,
                prev_transition->shift + shifted,
                prev_transition->next);
        rst->saves = saves;
        return rst;
    }

    std::vector<const State*> getStateChain(const State* state) {
        if (!state_chains.count(state)) {
            state_chains[state] = { state };
            LOG4("Add " << state->name << " to merge chain");
        }
        return state_chains.at(state);
    }

    bool is_merge_point(const State* state) {
        return n_transition_to.at(state) > 1;
    }

    bool is_dont_care(const IR::BFN::ParserMatchValue* value) {
        if (auto* const_value = value->to<IR::BFN::ParserConstMatchValue>()) {
            return (const_value->value.word0 ^ const_value->value.word1) == 0; }
        return false;
    }

    Visitor::profile_t init_apply(const IR::Node* root) {
        state_chains.clear();
        results.clear();
        return ParserInspector::init_apply(root);
    }

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
        LOGGING(4) ? new DumpParser("before_merge_parser_states") : nullptr,
        collectStateUses,
        computeMergeableState,
        new WriteBackMergedState(*computeMergeableState),
        LOGGING(4) ? new DumpParser("after_merge_parser_states") : nullptr
    });
}