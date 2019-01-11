#ifndef BF_P4C_MIDEND_UNROLL_PARSER_COUNTER_H_
#define BF_P4C_MIDEND_UNROLL_PARSER_COUNTER_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "frontends/common/resolveReferences/referenceMap.h"

/** Unroll states that loop on parser counter value.
 * This pass tries to remove the common use of parser counter in the mid-end
 * by replacing the looping states with a state that select on the value
 * that was loaded in to parser counter, then goto different
 * state that does n times of extractions, depending on the value.
 *
 * Currently this pass only support use of parser counter in the following
 * case:
 *     State_A : load value to parser counter, then transition(or select) to State_B.
 *     State_B : self-loop to itself by selecting on the counter value, decrement
 *               counter value by delta in each turn, and extract headerstack only.
 *               Except for the self-loop, it goes to the state_exit.
 * will be converted into:
 *     State_A : transition to State_Counter_Select.
 *     State_Counter_Select : Select on the value that was supposed to be loaded into counter,
 *                            then goes to one of the following states,
 *     State_B_0 : one copy of state_B.
 *     State_B_1 : two copy of state_B chained together.
 *     ....
 *     State_B_N : N + 1 copy of state_B, chained together
 * where N equals to the largest index of the header stack extracted in the looping state.
 *
 * TODO(yumin): rotate in counter.set() is not supported now, because in the extract_parser,
 * we do not support IR::Range expression now. Once it's supported, we can support it by simply
 * apply a IR::Range expression on the select value. MAYBE WE CAN??
 */
class UnrollParserCounter : public Modifier {
    static constexpr const char* parser_counter_type_name = "ParserCounter";
    static constexpr int MAX_UNROLL = 10;  // Upper bound of unrolled chain.
    static constexpr int COUNTER_SIZE = 8;  // Size of counter.

 public:
    struct CounterSetState {
        const IR::ParserState* state;
        const IR::MethodCallExpression* set_expr;
        cstring counter_name;
        const IR::Declaration_Instance* counter_decl;

        const IR::Expression* getSource() const {
            BUG_CHECK(set_expr->arguments->size() >= 1,
                      "counter set should have at least 1 argument.");
            return (*(set_expr->arguments))[0]->expression;
        }

        int getAddValue() const {
            if (set_expr->arguments->size() > 1) {
                BUG_CHECK(set_expr->arguments->size() == 5,
                          "Parser Counter set expression does not have 5 parameters: %1%",
                          set_expr);
                auto* c = (*(set_expr->arguments))[4]->expression->to<IR::Constant>();
                if (c && c->fitsInt()) {
                    return c->asInt();
                } else {
                    BUG("Wrong type of `add` parameter or too large: %1%", set_expr);
                }
            } else {
                return 0;
            }
        }

        CounterSetState() = default;
        CounterSetState(const IR::ParserState* state,
                        const IR::MethodCallExpression* set_expr,
                        cstring counter_name,
                        const IR::Declaration_Instance* counter_decl)
            : state(state), set_expr(set_expr),
              counter_name(counter_name), counter_decl(counter_decl) { }
    };

    struct CounterLoopState {
        const IR::ParserState* state;
        const IR::ParserState* exit_state;
        int exit_value;  // parser counter can only tell you whether it's 0 or negative.
        int delta;
        int stack_length;

        CounterLoopState() = default;
        CounterLoopState(const IR::ParserState* state,
                         const IR::ParserState* exit_state,
                         int exit_value,
                         int delta,
                         int stack_length)
            : state(state), exit_state(exit_state), exit_value(exit_value),
              delta(delta), stack_length(stack_length) { }
    };

    struct StateChain {
        std::vector<const IR::ParserState*> states;
        const IR::ParserState* head() const {
            return states.back(); }
        explicit StateChain(std::vector<const IR::ParserState*> states)
            : states(states) { }
    };

 private:
    P4::ReferenceMap *refMap;
    std::set<cstring> stateNames;

 private:
    bool isCounter(const IR::Declaration_Instance* inst) const;

    int expr2Int(const IR::Expression* expr) const;

    int calcDelta(const IR::ParserState* loop_state, cstring counter_name);

    int extractHeaderStackSize(const IR::ParserState* loop_state);

    boost::optional<int> getMaxLoopDepthPragma(const IR::ParserState* state);

    IR::IndexedVector<IR::StatOrDecl>
    filterOutCounter(const IR::IndexedVector<IR::StatOrDecl>& primitives) const;

    const IR::ParserState*
    selectCase2State(const IR::SelectCase* select_case) const;

    std::pair<int, const IR::ParserState*>
    calcExitValues(const IR::ParserState* state) const;

    /// A loop state must end with a select that select on the counter and
    /// one case goes to itself, onse case goes to other state.
    bool hasLoop(const IR::ParserState* state) const;

    /// Try to find a state that has self loop.
    const IR::ParserState*
    findLoopStateAfter(const IR::ParserState* state) const;

    /// @returns the loop state after @p state, if exist.
    boost::optional<CounterLoopState>
    collectLoopState(const IR::ParserState* state, cstring counter_name);

    std::vector<CounterSetState>
    collectCounterSets(const IR::P4Parser* parser);

    IR::ParserState* createOneUnrolledState(const IR::ParserState* state,
                                            const IR::ParserState* next);

    StateChain createUnrolledStates(const IR::ParserState* state,
                                    const IR::ParserState* dest,
                                    int length);

    /// @return the selecting state and a vector of unrolled loop states.
    std::pair<IR::ParserState*, std::vector<StateChain>>
    unroll(const CounterSetState& set, const CounterLoopState& loop);

    IR::Expression* replaceTransition(const IR::Expression* old,
                                      const IR::ParserState* loop,
                                      const IR::ParserState* unrolled);

    /// replace all states that has parser counter set by replacing the transition to the loop
    /// state with the unrolled states.
    /// XXX(yumin): note that old loop state won't be removed, just no state will transition to
    /// it.
    bool preorder(IR::P4Parser* parser) override;

 public:
    explicit UnrollParserCounter(P4::ReferenceMap *refMap) : refMap(refMap) { }
};

#endif /* BF_P4C_MIDEND_UNROLL_PARSER_COUNTER_H_ */
