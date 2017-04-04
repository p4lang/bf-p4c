#ifndef TOFINO_MAU_PUSH_POP_H_
#define TOFINO_MAU_PUSH_POP_H_

#include "tofino/common/header_stack.h"
#include "mau_visitor.h"
#include "tofino/common/slice.h"

class HeaderPushPop : public MauTransform {
    const HeaderStackInfo &stacks;

    void copy_hdr(IR::Vector<IR::Primitive> *rv, const IR::Type_StructLike *hdr,
                  const IR::HeaderRef *to, const IR::HeaderRef *from) {
        for (auto field : *hdr->fields) {
            auto dst = new IR::Member(field->type, to, field->name);
            auto src = new IR::Member(field->type, from, field->name);
            rv->push_back(new IR::Primitive("modify_field", dst, src)); } }
    IR::Node *do_push(const IR::HeaderRef *stack, int count) {
        auto &info = stacks.at(stack->toString());
        auto *rv = new IR::Vector<IR::Primitive>;
        for (int i = info.size-1; i >= count; --i)
            copy_hdr(rv, stack->baseRef()->type,
                     new IR::HeaderStackItemRef(stack, new IR::Constant(i)),
                     new IR::HeaderStackItemRef(stack, new IR::Constant(i - count)));
        auto *valid = new IR::Member(IR::Type::Bits::get(info.size + info.maxpop + info.maxpush),
                                     stack, "$stkvalid");
        rv->push_back(new IR::Primitive("modify_field",
            MakeSlice(valid, info.maxpop, info.maxpop + info.size - 1),
            MakeSlice(valid, info.maxpop + count, info.maxpop + info.size + count - 1)));
        return rv; }
    IR::Node *do_pop(const IR::HeaderRef *stack, int count) {
        auto & info = stacks.at(stack->toString());
        auto *rv = new IR::Vector<IR::Primitive>;
        for (int i = count; i < info.size; ++i)
            copy_hdr(rv, stack->baseRef()->type,
                     new IR::HeaderStackItemRef(stack, new IR::Constant(i - count)),
                     new IR::HeaderStackItemRef(stack, new IR::Constant(i)));
        auto *valid = new IR::Member(IR::Type::Bits::get(info.size + info.maxpop + info.maxpush),
                                     stack, "$stkvalid");
        rv->push_back(new IR::Primitive("modify_field",
            MakeSlice(valid, info.maxpop, info.maxpop + info.size - 1),
            MakeSlice(valid, info.maxpop - count, info.maxpop + info.size - count - 1)));
        return rv; }

    IR::Node *preorder(IR::Primitive *prim) override {
        if (prim->name == "push")
            return do_push(prim->operands[0]->to<IR::HeaderRef>(),
                           prim->operands[1]->to<IR::Constant>()->asInt());
        else if (prim->name == "pop")
            return do_pop(prim->operands[0]->to<IR::HeaderRef>(),
                          prim->operands[1]->to<IR::Constant>()->asInt());
        return prim; }

 public:
    explicit HeaderPushPop(const HeaderStackInfo &stacks) : stacks(stacks) {}
};

#endif /* TOFINO_MAU_PUSH_POP_H_ */
