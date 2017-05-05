#include "split_big_states.h"

bool SplitBigStates::preorder(IR::Tofino::ParserMatch *state) {
    int use[3] = { 0, 0, 0 };
    int size = 0;
    PHV::Container last;
    auto it = state->stmts.begin();
    for (; it != state->stmts.end(); ++it) {
        auto *prim = (*it)->to<IR::Primitive>();
        if (!prim) BUG("Non primitive %s in parser state", *it);
        if (prim->operands[0]->type->is<IR::Type::Varbits>()) {
            /* FIXME -- ignoring varbits for now (not properly dealt with in general) */
            continue; }
        PhvInfo::Field::bitrange bits;
        auto dest = phv.field(prim->operands[0], &bits);
        if (!dest) BUG("%s not in phv?", prim->operands[0]);
        auto &alloc = dest->for_bit(bits.lo);
        if (alloc.container == last) continue;
        if (!(last = alloc.container)) {
            std::cout << dest;
            BUG("not a valid PHV container");
        }
        if (use[last.log2sz()] >= 4) break;
        use[last.log2sz()]++;
        size += last.size() / 8U; }
    if (it == state->stmts.end())
        return true;  // No splitting needed.
    auto *rest = new IR::Tofino::ParserMatch(match_t(), state->shift - size, {},
                                             state->next, state->except);
    rest->stmts.insert(rest->stmts.begin(), it, state->stmts.end());
    state->stmts.erase(it, state->stmts.end());
    auto name = names.newname(findContext<IR::Tofino::ParserState>()->name);
    state->next = new IR::Tofino::ParserState(name, VisitingThread(this), {}, { rest });
    state->except = nullptr;
    state->shift = size;
    return true;
}
