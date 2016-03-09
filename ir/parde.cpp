#include "ir/ir.h"

IR::Tofino::ParserState::ParserState(const IR::Node *p4state) {
    this->p4state = p4state;
    if (auto *v1_0 = p4state->to<IR::Parser>()) {
        name = v1_0->name;
        if (v1_0->select)
            select = *v1_0->select;
    } else if (auto *v1_2 = p4state->to<IR::ParserState>()) {
        name = v1_2->name;
        if (auto *sel = dynamic_cast<const IR::SelectExpression *>(v1_2->selectExpression))
            select = *sel->select->components;
    } else {
        BUG("Invalid p4state type for Tofino::ParserState"); }
    if (name == "start" || name == "end")
        name += "$";
}
