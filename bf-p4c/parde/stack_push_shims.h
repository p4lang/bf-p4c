#ifndef TOFINO_PARDE_STACK_PUSH_SHIMS_H_
#define TOFINO_PARDE_STACK_PUSH_SHIMS_H_

#include "parde_visitor.h"
#include "tofino/common/header_stack.h"

class StackPushShims : public PardeModifier {
    const HeaderStackInfo &stacks;
    bool preorder(IR::Tofino::Parser *p) override {
        for (auto &stack : stacks) {
            if (stack.maxpush == 0 || stack.gress != p->gress) continue;
            p->start = new IR::Tofino::ParserState(stack.name + "$shim", stack.gress, {},
                { new IR::Tofino::ParserMatch(match_t(), 0, {
                    new IR::Tofino::ExtractConstant(
                        new IR::Member(IR::Type::Bits::get(stack.maxpush),
                                       new IR::PathExpression(stack.name), "$push"),
                        new IR::Constant((1U << stack.maxpush) - 1)) }, p->start) } ); }
        return false; }

 public:
    explicit StackPushShims(const HeaderStackInfo &stacks) : stacks(stacks) {}
};

#endif /* TOFINO_PARDE_STACK_PUSH_SHIMS_H_ */
