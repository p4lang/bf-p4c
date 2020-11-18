#ifndef BF_P4C_MIDEND_SIMPLIFY_KEY_POLICY_H_
#define BF_P4C_MIDEND_SIMPLIFY_KEY_POLICY_H_

#include "midend/simplifyKey.h"

namespace BFN {

class IsPhase0 : public P4::KeyIsSimple {
 public:
    IsPhase0() { }

    bool isSimple(const IR::Expression *, const Visitor::Context *ctxt) override {
        while (true) {
            if (ctxt == nullptr)
                return false;
            auto *n = ctxt->node;
            if (n->is<IR::P4Program>())
                return false;
            if (auto table = n->to<IR::P4Table>()) {
                auto annot = table->getAnnotations();
                if (annot->getSingle("phase0")) {
                    return true;
                }
                return false;
            }
            ctxt = ctxt->parent;
        }
        return false;
    }
};

class IsSlice : public P4::KeyIsSimple {
 public:
    IsSlice() { }

    bool isSimple(const IR::Expression *expr, const Visitor::Context *) override {
        auto slice = expr->to<IR::Slice>();
        if (!slice)
            return false;
        auto *e = slice->e0;
        while (e->is<IR::Member>())
            e = e->to<IR::Member>()->expr;
        return e->to<IR::PathExpression>() != nullptr;
    }
};

class KeyIsSimple {
 public:
    static P4::KeyIsSimple *getPolicy(P4::ReferenceMap &refMap, P4::TypeMap &typeMap) {
        return
            new P4::OrPolicy(
                new P4::OrPolicy(
                    new P4::OrPolicy(new P4::IsValid(&refMap, &typeMap), new P4::IsMask()),
                    new BFN::IsPhase0()),
                new BFN::IsSlice());
    }
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_SIMPLIFY_KEY_POLICY_H_ */
