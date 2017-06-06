#ifndef TOFINO_COMMON_REWRITE_H_
#define TOFINO_COMMON_REWRITE_H_

#include "ir/ir.h"

class RewriteForTofino : public Transform {
    const IR::Expression *preorder(IR::MethodCallExpression *mc) override {
        if (auto *mem = mc->method->to<IR::Member>()) {
            if (mem->member == "isValid") {
                auto *v = new IR::Primitive(mc->srcInfo, "isValid", mem->expr);
                v->type = IR::Type::Boolean::get();
                return v; } }
        return mc; }
};

#endif /* TOFINO_COMMON_REWRITE_H_ */
