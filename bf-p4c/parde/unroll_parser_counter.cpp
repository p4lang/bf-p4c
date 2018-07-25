#include "bf-p4c/parde/unroll_parser_counter.h"

bool UnrollParserCounter::isCounter(const IR::Declaration_Instance* inst) const {
    if (!inst) return false;
    auto* type = inst->getType();
    if (auto* specialized_type = type->to<IR::Type_Specialized>()) {
        if (specialized_type->baseType->path->name == parser_counter_type_name) {
            return true;
        }
    }
    return false;
}

std::vector<UnrollParserCounter::CounterSetState>
UnrollParserCounter::collectCounterSets(const IR::P4Parser* parser) {
    std::vector<UnrollParserCounter::CounterSetState> rst;
    for (const auto* state : parser->states) {
        for (const auto* prim : state->components) {
            if (!prim->is<IR::MethodCallStatement>()) continue;
            auto* call_stmt = prim->to<IR::MethodCallStatement>();
            auto* call_expr = call_stmt->methodCall;

            auto* method = call_expr->method->to<IR::Member>();
            if (!method || method->member != "set") {
                continue; }

            auto* path = method->expr->to<IR::PathExpression>();
            if (!path) {
                continue; }
            auto* decl = refMap->getDeclaration(path->path)->to<IR::Declaration_Instance>();
            if (method->member == "set" && isCounter(decl)) {
                if (call_expr->arguments->size() != 1) {
                    BUG_CHECK(call_expr->arguments->size() == 5,
                              "Parser Counter set expression does not "
                              "have 5 parameters: %1%", call_expr);
                    int max = expr2Int((*(call_expr->arguments))[1]->expression);
                    int rotate = expr2Int((*(call_expr->arguments))[2]->expression);
                    int mask = expr2Int((*(call_expr->arguments))[3]->expression);
                    // Fancy use of counter, do not unroll.
                    if (rotate != 0
                        || max != ((1 << UnrollParserCounter::COUNTER_SIZE) - 1)
                        || mask != ((1 << UnrollParserCounter::COUNTER_SIZE) - 1)) {
                        continue; }
                }
                rst.push_back(UnrollParserCounter::CounterSetState(
                                      state, call_expr, path->path->name, decl));
                LOG4("Found set counter: " << call_expr
                     << ", Sourcing from " << rst.back().getSource());
            }
        }
    }
    return rst;
}

int UnrollParserCounter::expr2Int(const IR::Expression* expr) const {
    if (auto* c = expr->to<IR::Constant>()) {
        BUG_CHECK(c->fitsInt(), "parser counter parameter too large: %1%", expr);
        return c->asInt();
    } else {
        BUG("Unsupported expression in parser counter: %1%", expr);
        return 0;
    }
}

int UnrollParserCounter::calcDelta(const IR::ParserState* loop_state, cstring counter_name) {
    int delta = 0;
    forAllMatching<IR::MethodCallExpression>(
        &loop_state->components, [&] (const IR::MethodCallExpression* call_expr) {
            auto* method = call_expr->method->to<IR::Member>();
            auto* obj = method->expr->to<IR::PathExpression>();
            auto function_called = method->member;
            if (obj->path->name == counter_name) {
                if (function_called == "increment") {
                    delta += expr2Int((*(call_expr->arguments))[0]->expression);
                } else if (function_called == "decrement") {
                    delta -= expr2Int((*(call_expr->arguments))[0]->expression);
                }
            }
        });
    return delta;
}

int UnrollParserCounter::extractHeaderStackSize(const IR::ParserState* loop_state) {
    int min_header_size = MAX_UNROLL;
    forAllMatching<IR::MethodCallExpression>(
        &loop_state->components, [&] (const IR::MethodCallExpression* call_expr) {
            auto* method = call_expr->method->to<IR::Member>();
            auto function_called = method->member;
            if (function_called == "extract") {
                auto* dest = (*(call_expr->arguments))[0]->expression;
                auto* dest_member = dest->to<IR::Member>();
                const IR::Type_Stack* dest_type =
                    dest_member ? dest_member->expr->type->to<IR::Type_Stack>() : nullptr;
                BUG_CHECK(dest_type && dest_member && dest_member->member == "next",
                          "In parser counter loop state, extract to anything other than "
                          "headerstack is not supported: %1%", call_expr);
                min_header_size = std::min(min_header_size,
                                           dest_type->size->to<IR::Constant>()->asInt());
            }
        });
    return min_header_size;
}

const IR::ParserState*
UnrollParserCounter::selectCase2State(const IR::SelectCase* select_case) const {
    return refMap->getDeclaration(select_case->state->path)->to<IR::ParserState>();
}

std::pair<int, const IR::ParserState*>
UnrollParserCounter::calcExitValues(const IR::ParserState* state) const {
    auto* select = state->selectExpression->to<IR::SelectExpression>();
    for (const auto* select_case : select->selectCases) {
        auto* transition_to = selectCase2State(select_case);
        if (transition_to != state) {
            int exit_value = select_case->keyset->to<IR::Constant>()->asInt();
            return std::make_pair(exit_value, transition_to);
        }
    }
    BUG("Can't find exit select case in %1%", state);
    return {0, nullptr};
}

/// A loop state must end with a select that select on the counter and
/// one case goes to itself, onse case goes to other state.
bool UnrollParserCounter::hasLoop(const IR::ParserState* state) const {
    if (!state || !state->selectExpression)
        return false;

    auto* select = state->selectExpression->to<IR::SelectExpression>();
    if (!select)
        return false;
    if (select->selectCases.size() != 2) {
        return false; }

    bool found_transition_loop = false;
    bool found_exit = false;
    for (const auto* select_case : select->selectCases) {
        auto* transition_to = selectCase2State(select_case);
        if (transition_to == state) {
            found_transition_loop = true;
        } else {
            found_exit = true;
        }
    }

    if (found_transition_loop && found_exit) {
        return true;
    } else {
        return false;
    }
}

/// Try to find a state that has self loop.
const IR::ParserState*
UnrollParserCounter::findLoopStateAfter(const IR::ParserState* state) const {
    if (!state)
        return nullptr;
    if (auto* next = state->selectExpression->to<IR::PathExpression>()) {
        auto* next_state = refMap->getDeclaration(next->path)->to<IR::ParserState>();
        if (hasLoop(next_state)) {
            return next_state;
        } else {
            return nullptr;
        }
    } else if (auto* select = state->selectExpression->to<IR::SelectExpression>()) {
        for (const auto* select_case : select->selectCases) {
            auto* transition_to = selectCase2State(select_case);
            if (hasLoop(transition_to)) {
                return transition_to;
            }
        }
    }
    return nullptr;
}

boost::optional<int>
UnrollParserCounter::getMaxLoopDepthPragma(const IR::ParserState* state) {
    auto* anno = state->getAnnotation("max_loop_depth");
    if (!anno) {
        return boost::none; }
    if (anno->expr.size() != 1) {
        ::warning("@pragma max_loop_depth must have 1 argument, skipping: %1%", anno);
        return boost::none; }
    auto max_loop = anno->expr[0]->to<IR::Constant>();
    if (!max_loop || max_loop->asInt() < 1) {
        ::warning("@pragma max_loop_depth must >= 1, skipping: %1%", anno);
        return boost::none;
    }
    ::warning("apply on %1%", state);
    return max_loop->asInt();
}

/// @returns the loop state after @p state, if exist.
boost::optional<UnrollParserCounter::CounterLoopState>
UnrollParserCounter::collectLoopState(const IR::ParserState* state, cstring counter_name) {
    auto* loop_state = findLoopStateAfter(state);
    if (!loop_state)
        return boost::none;

    // process loop
    int delta = calcDelta(loop_state, counter_name);
    auto exit_values = calcExitValues(loop_state);
    int n_header_stack = extractHeaderStackSize(loop_state);
    auto max_loop_depth_pragma = getMaxLoopDepthPragma(loop_state);
    if (max_loop_depth_pragma) {
        n_header_stack = std::min(n_header_stack, *max_loop_depth_pragma); }

    // only unroll when the use of counter is simple.
    if (exit_values.first != 0 || delta >= 0) {
        return boost::none;
    } else {
        return UnrollParserCounter::CounterLoopState(
                loop_state, exit_values.second, exit_values.first, delta, n_header_stack);
    }
}

IR::IndexedVector<IR::StatOrDecl>
UnrollParserCounter::filterOutCounter(const IR::IndexedVector<IR::StatOrDecl>& primitives) const {
    IR::IndexedVector<IR::StatOrDecl> rst;
    for (const auto* prim : primitives) {
        if (!prim->is<IR::MethodCallStatement>()) {
            rst.push_back(prim->clone());
            continue;
        }
        auto* call_expr = prim->to<IR::MethodCallStatement>()->methodCall;
        auto* method = call_expr->method->to<IR::Member>();
        auto* path = method->expr->to<IR::PathExpression>();
        auto* decl = refMap->getDeclaration(path->path)->to<IR::Declaration_Instance>();
        if (!isCounter(decl)) {
            rst.push_back(prim->clone());
        }
    }
    return rst;
}

IR::ParserState* UnrollParserCounter::createOneUnrolledState(const IR::ParserState* state,
                                                             const IR::ParserState* next) {
    cstring name = cstring::make_unique(stateNames, state->name);
    stateNames.insert(name);
    auto* rst = new IR::ParserState(IR::ID(name),
                                    filterOutCounter(state->components),
                                    new IR::PathExpression(next->name));
    return rst;
}

UnrollParserCounter::StateChain
UnrollParserCounter::createUnrolledStates(const IR::ParserState* state,
                                          const IR::ParserState* dest,
                                          int length) {
    std::vector<const IR::ParserState*> rst = { createOneUnrolledState(state, dest) };
    for (int i = 1; i < length; i++) {
        auto* s = createOneUnrolledState(state, rst.back());
        rst.push_back(s);
    }
    return UnrollParserCounter::StateChain(rst);
}

/// @return the selecting state and a vector of unrolled loop states.
std::pair<IR::ParserState*, std::vector<UnrollParserCounter::StateChain>>
UnrollParserCounter::unroll(const UnrollParserCounter::CounterSetState& set,
                            const UnrollParserCounter::CounterLoopState& loop) {
    // Create unrolled states.
    std::vector<UnrollParserCounter::StateChain> unrolled_states;
    for (int i = 1; i <= loop.stack_length; ++i) {
        unrolled_states.push_back(
                createUnrolledStates(loop.state, loop.exit_state, i));
    }

    // Create select state.
    cstring name = cstring::make_unique(stateNames, loop.state->name + ".$select");
    stateNames.insert(name);

    // Create selectCases that corresponds to counter value (x):
    // X + AddValue + Delta = exit_value ---> last state.
    // X + AddValue + Delta = exit_value + Delta --> 2n last.
    // X + AddValue + Delta = exit_value + Delta * 2 --> 3rd last.
    // ....
    auto* select_on = new IR::ListExpression(
            IR::Vector<IR::Expression>{set.getSource()->clone()});
    IR::Vector<IR::SelectCase> select_cases;
    int key_value = loop.exit_value - set.getAddValue() - loop.delta;
    for (int i = 0; i < loop.stack_length; ++i) {
        // Select on counter value on the state that loads the value is not supported.
        // It means that, somehow, we think there is always one header to extract?
        // This is not correct, we should be able to allow no extraction.
        auto* go_to = unrolled_states[i].head();
        auto* select_val =
            new IR::Constant(IR::Type::Bits::get(set.getSource()->type->width_bits()),
                             mpz_class(key_value));
        auto* select_case = new IR::SelectCase(
                select_val,
                new IR::PathExpression(new IR::Path(IR::ID(go_to->name))));
        select_cases.push_back(select_case);
        key_value -= loop.delta;
    }
    auto* select_expr = new IR::SelectExpression(select_on, select_cases);
    auto* select_state = new IR::ParserState(
            IR::ID(name), IR::IndexedVector<IR::StatOrDecl>(), select_expr);

    return { select_state, unrolled_states };
}

IR::Expression* UnrollParserCounter::replaceTransition(const IR::Expression* old,
                                                       const IR::ParserState* loop,
                                                       const IR::ParserState* unrolled) {
    if (auto* next = old->to<IR::PathExpression>()) {
        auto* next_state = refMap->getDeclaration(next->path)->to<IR::ParserState>();
        BUG_CHECK(next_state == loop, "After set counter, the next state must be a loop "
                  "state, but %1% does not.", old);
        return new IR::PathExpression(new IR::Path(unrolled->name));
    } else if (auto* select = old->to<IR::SelectExpression>()) {
        auto* new_select = select->clone();
        new_select->selectCases.clear();
        for (const auto* select_case : select->selectCases) {
            auto* transition_to = selectCase2State(select_case);
            if (transition_to == loop) {
                new_select->selectCases.push_back(
                        new IR::SelectCase(
                                select_case->keyset,
                                new IR::PathExpression(new IR::Path(unrolled->name))));
            } else {
                new_select->selectCases.push_back(select_case);
            }
        }
        return new_select;
    } else {
        BUG("wrong type of transition expression passed: %1%", old);
        return nullptr;
    }
}

/// replace all states that has parser counter set by replacing the transition to the loop
/// state with the unrolled states.
/// XXX(yumin): note that old loop state won't be removed, just no state will transition to
/// it.
bool UnrollParserCounter::preorder(IR::P4Parser* parser) {
    // To generate unique names.
    for (const auto* state : parser->states) {
        stateNames.insert(state->name); }

    // Foreach counter set, find the loop state after it.
    std::map<const IR::ParserState*, UnrollParserCounter::CounterSetState> counter_sets;
    std::map<const IR::ParserState*, UnrollParserCounter::CounterLoopState> counter_loops;
    for (auto counter_set : collectCounterSets(parser)) {
        counter_sets[counter_set.state] = counter_set;
        auto loop = collectLoopState(counter_set.state, counter_set.counter_name);
        if (loop) {
            counter_loops[counter_set.state] = *loop;
        }
    }

    // unroll all loop states, and replace all transition to loop state to
    // the counter select state.
    IR::IndexedVector<IR::ParserState> unrolled;
    for (const auto* state : parser->states) {
        if (counter_sets.count(state) && counter_loops.count(state)) {
            auto& counter_set = counter_sets[state];
            auto& counter_loop = counter_loops[state];
            // unroll
            auto unrolled_states = unroll(counter_set, counter_loop);
            auto* select_state = unrolled_states.first;
            auto* new_state = new IR::ParserState(
                    IR::ID(state->name),
                    filterOutCounter(state->components),
                    replaceTransition(
                            state->selectExpression, counter_loop.state, select_state));

            // add to result.
            unrolled.push_back(new_state);
            unrolled.push_back(select_state);
            LOG5("Insert unrolled state: " << new_state);
            LOG5("Insert unrolled state: " << select_state);
            for (const auto& r : unrolled_states.second) {
                for (const auto* s : r.states) {
                    unrolled.push_back(s);
                    LOG5("Insert unrolled state: " << s);
                }
            }
        } else {
            unrolled.push_back(state);
        }
    }

    parser->states = unrolled;
    return true;
}
