#include "ir/ir.h"

IR::Tofino::ParserState::ParserState(const IR::ParserState *p4state, gress_t gr) : gress(gr) {
    this->p4state = p4state;
    srcInfo = p4state->srcInfo;
    name = p4state->name;
    if (auto *sel = dynamic_cast<const IR::SelectExpression *>(p4state->selectExpression))
        select = *sel->select->components;
    if (name == "start" || name == "end")
        name += "$";
}
