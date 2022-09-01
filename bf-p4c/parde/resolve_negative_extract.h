#ifndef EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_
#define EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_

#include <map>
#include <sstream>

#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/device.h"

/// For extracts with negative source, i.e. source is in an earlier state, adjust
/// the state's shift amount so that the source is within current state's input buffer.
struct ResolveNegativeExtract : public PassManager {
    /// Colect all negative extract states and compute corresponding shift values
    /// for transitions and states
    struct CollectNegativeExtractStates : public ParserInspector {
        const CollectParserInfo& parserInfo;

        /**
         * @brief In-buffer offsets of states
         */
        std::map<cstring, unsigned> state_to_shift;

        /**
         * @brief Output shift values for given transitions - key is the
         * source node and value is a map transition -> value
         */
        std::map<cstring,
            std::map<const IR::BFN::ParserMatchValue*,
                     unsigned>> transition_shift;

        /**
         * @brief Transitions exiting parser with unconsumed bytes in the packet buffer.
         */
        std::map<const IR::BFN::Transition*, unsigned> remainder_before_exit;

        explicit CollectNegativeExtractStates(const CollectParserInfo& pi) : parserInfo(pi) { }

        bool preorder(const IR::BFN::PacketRVal* rval) override {
            auto extract = findContext<IR::BFN::Extract>();
            if (extract && rval->range.lo < 0) {
                auto state = findContext<IR::BFN::ParserState>();
                unsigned shift = (-rval->range.lo + 7) / 8;
                // state_to_shift[state->name] = std::max(state_to_shift[state->name], shift);
                historic_states[state] = std::max(historic_states[state], shift);
                parsers[state] = findContext<IR::BFN::Parser>();
            }

            return false;
        }

        profile_t init_apply(const IR::Node *node) override {
            auto rv = ParserInspector::init_apply(node);
            // Initialize all structures
            transition_shift.clear();
            state_to_shift.clear();
            historic_states.clear();
            parsers.clear();
            return rv;
        }

        void end_apply() override {
            // Required data capture update all node states
            const unsigned max_buff_size = Device::pardeSpec().byteInputBufferSize();
            for (auto kv : historic_states) {
                // 1] Distribute the required history value and adjust transitions
                auto state = kv.first;
                auto max_idx_value = kv.second;
                BUG_CHECK(max_idx_value <= max_buff_size,
                    "In parse state %s: a value that is %d B backwards from the current "
                    "parsing position is being accessed/used. It is only possible to "
                    "access %d B backwards from the current parsing position. As a "
                    "possible workaround try moving around the extracts (possibly "
                    "by using methods advance and lookahead or splitting some headers).",
                    state->name, max_idx_value, max_buff_size);

                distribute_shift_to_node(state, nullptr, parsers[state], max_idx_value);
                // 2] Add the fix amount of shift data (it should be the same value from nodes)
                //
                // It is not a problem if the SHIFT value will not cover the whole state because
                // the future pass will split the state to get more data to parse data.
                for (auto trans : state->transitions) {
                    unsigned shift_value = trans->shift + max_idx_value;
                    transition_shift[state->name][trans->value] = shift_value;
                }
            }

            for (auto kv : state_to_shift)
                LOG3(kv.first << " needs " << kv.second << " bytes of shift");

            for (auto kv : transition_shift) {
                for (auto tr_config : kv.second) {
                    std::stringstream ss;
                    ss << "Transition with match { " << tr_config.first << " } from state " <<
                    kv.first << " needs will be set with the shift value " << tr_config.second;
                    LOG3(ss.str());
                }
            }

            LOG3("ResolveNegativeExtract has been finished.");
        }

     private:
        /**
         * @brief Set of nodes which were identified as nodes where historic
         * data need to be accessed. The value stored together with the state
         * is the maximal historic data index
         *
         */
        std::map<const IR::BFN::ParserState*, unsigned> historic_states;

        /**
         * @brief Mapping of Parser state to given Parser instance
         *
         */
        std::map<const IR::BFN::ParserState*, const IR::BFN::Parser*> parsers;

        /**
         * @brief Get the current value of the transition (assigned by the algorithm)
         *
         * @param tr Transition to process
         * @param src Transition source node
         * @return Transition shift value
         */
        unsigned get_transition_shift(const IR::BFN::ParserState *src,
                                      const IR::BFN::Transition* tr) {
            BUG_CHECK(tr != nullptr, "Transition node cannot be null!");
            if (transition_shift.count(src->name) &&
                transition_shift.at(src->name).count(tr->value)) {
                return transition_shift[src->name][tr->value];
            }

            return tr->shift;
        }

        /**
         * @brief Adjust all transitions/state shifts for the given state
         *
         * Do the following for each state:
         * 1] Set the computed transition shift which is affected byt he historic data path
         *   (value needs to be same for all transitions due to the state spliting)
         * 2] Set the corresponding state shift value for the successor node
         * 3] Correct all transitions from the successors by the state shift value
         *   (we can skip the node on the historic path because it is already analyzed)
         *
         * @param state Parser state used for the analysis
         * @param state_child Child of the @p state
         * @param tr_shift Transition shift to set
         * @param state_shift State shift to set
         */
        void adjust_shift_buffer(const IR::BFN::ParserState *state,
            const IR::BFN::ParserState *state_child,
            unsigned tr_shift, unsigned state_shift) {
            for (auto state_trans : state->transitions) {
                auto state_succ = state_trans->next;
                transition_shift[state->name][state_trans->value] = tr_shift;
                LOG4("Adding transition { " << state_trans->value << " } shift value " <<
                    tr_shift << " B from state " << state->name);

                if (!state_succ) {
                    // This transition exits parser, but we need to shift `state_shift` bytes
                    // from the packet. Remember this transition, AdjustShift will add
                    // auxiliary state which is used to extract the remaining bytes.
                    remainder_before_exit[state_trans] = state_shift;
                    continue;
                };
                state_to_shift[state_succ->name] = state_shift;
                LOG4("Setting shift value " << state_shift << " B for state " << state_succ->name);

                // Don't process the subtree if we reached from that part of the tree
                // because it will be analyzed later
                if (state_succ == state_child) {
                    LOG4("Skipping transition adjustment for " << state_succ->name <<
                        " (will be set later).");
                    continue;
                }

                for (auto succ_tr : state_succ->transitions) {
                    if (transition_shift[state_succ->name].count(succ_tr->value) > 0) continue;

                    unsigned new_shift = get_transition_shift(state_succ, succ_tr) + state_shift;
                    transition_shift[state_succ->name][succ_tr->value] = new_shift;
                    LOG4("Adding transition { " << succ_tr->value << " } shift value " <<
                        new_shift << " B from state " << state_succ->name);
                }
            }
        }

        /**
         * @brief Distribute the shift value (recursive) to parse graph predecessors
         *
         * @param state Analyzed parser state
         * @param succ Successors of the state from which we are calling (can be null)
         * @param parser Analyzed parser state
         * @param required_history Required backward history in bytes
         */
        void distribute_shift_to_node(const IR::BFN::ParserState *state,
            const IR::BFN::ParserState *succ, const IR::BFN::Parser *parser,
            int required_history) {
            // 1] Identify the deficit absorbed by the recursion or if we already analyzed
            // a path through the graph
            BUG_CHECK(state, "Parser state cannot be null!");
            if (state_to_shift.count(state->name) > 0) {
                error("Current path with historic data usage has an intersection with"
                    " a previously analyzed historic data path at node %1%!", state->name);
            }

            int deficit = required_history;
            auto graph = parserInfo.graph(parser);
            auto transitions = graph.transitions(state, succ);
            if (transitions.size() > 0 && required_history > 0) {
                // All transitions should have the same shift value - we will take the first
                // one
                unsigned shift_value = get_transition_shift(state, *transitions.begin());
                deficit = required_history - shift_value;
            }

            LOG4("Shift distribution for node " << state->name <<", to distribute = "
                << required_history << " (deficit = " << deficit << " B)");

            // 2] Call recursively to all predecessors to distribute the remaining history
            // shift - we need to make a call iff we can distribute the value to successors.
            //
            // In this stage, there should be one path only to the state with historic data
            if (deficit > 0) {
                auto preds = graph.predecessors().at(state);
                if (preds.size() > 1) {
                    error("Cannot resolve negative extract because of multiple paths to "
                        "the node %1%", state->name);
                }
                distribute_shift_to_node(*preds.begin(), state, parser, deficit);
            }

            // Check if we reached the starting node - stop if true
            if (transitions.size() == 0 && !succ) {
                LOG4("Initial node " << state->name << " has been reached.");
                return;
            }

            // 3] The following code assumes that all transition from this state requires the
            // same transition shift value
            //
            // Initial values assumes that we need to borrow the whole transition AND
            // new transition shift is 0
            const int old_tr_shift = get_transition_shift(state, *transitions.begin());
            // Required history can be negative --> difference is the successors's shift value
            // Required history is positive is the curent historic value plus the shift value
            int new_state_shift = old_tr_shift + deficit;
            int new_tr_shift = 0;
            if (deficit <= 0) {
                // Deficit is negative --> historic data which are not needed inside the buffer
                // (we can shift them out)
                new_tr_shift = -deficit;
            }
            adjust_shift_buffer(state, succ, new_tr_shift, new_state_shift);
        }
    };

    struct AdjustShift : public ParserModifier {
        const CollectNegativeExtractStates& collectNegative;

        explicit AdjustShift(const CollectNegativeExtractStates& cg) : collectNegative(cg) { }

        bool preorder(IR::BFN::Transition* transition) override {
            auto state = findContext<IR::BFN::ParserState>();
            auto orig_transition = getOriginal()->to<IR::BFN::Transition>();
            BUG_CHECK(state, "State cannot be null!");
            BUG_CHECK(orig_transition, "Original IR::BFN::Transition cannot be null!");

            if (collectNegative.transition_shift.count(state->name) &&
                collectNegative.transition_shift.at(state->name).count(orig_transition->value)) {
                const auto& tr_map = collectNegative.transition_shift.at(state->name);
                transition->shift = tr_map.at(orig_transition->value);
                LOG3("Adjusting transition from " << state->name << ", match { " <<
                    orig_transition->value << " } to shift value = " << transition->shift);
            }

            if (collectNegative.remainder_before_exit.count(orig_transition)) {
                // The transition exits parser but needs to push a shift to the target
                // state (which is empty in this case). We generate new auxiliary state
                // for this purpose.
                unsigned state_shift = collectNegative.remainder_before_exit.at(orig_transition);

                auto remainder_state = new IR::BFN::ParserState(state->p4State,
                                                          state->name + "$final_shift",
                                                          state->gress);
                transition->next = remainder_state;
                auto end_transition = new IR::BFN::Transition(match_t(), state_shift);
                remainder_state->transitions.push_back(end_transition);
                LOG5("Transition from state " << state->name << " with match value "
                     << orig_transition->value << " leads to exit, adding new state "
                     << remainder_state->name << " to consume " << state_shift << " bytes.");
            }

            return true;
        }

        bool preorder(IR::BFN::PacketRVal* rval) override {
            auto state   = findContext<IR::BFN::ParserState>();
            auto extract = findContext<IR::BFN::Extract>();

            if (collectNegative.state_to_shift.count(state->name)) {
                unsigned shift = collectNegative.state_to_shift.at(state->name) * 8;
                rval->range.lo += shift;
                rval->range.hi += shift;
                if (extract) {
                    LOG3("Adjusting field " << extract->dest->field->toString() << " to " <<
                        shift/8 << " byte offset (lo = " << rval->range.lo << ", hi  = " <<
                        rval->range.hi << ")");
                }
            }

            return false;
        }
    };

    ResolveNegativeExtract() {
        auto* parserInfo = new CollectParserInfo;
        auto* collectNegative = new CollectNegativeExtractStates(*parserInfo);

        addPasses({
            LOGGING(4) ? new DumpParser("before_resolve_negative_extract") : nullptr,
            parserInfo,
            collectNegative,
            new AdjustShift(*collectNegative),
            LOGGING(4) ? new DumpParser("after_resolve_negative_extract") : nullptr
        });
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_RESOLVE_NEGATIVE_EXTRACT_H_ */
