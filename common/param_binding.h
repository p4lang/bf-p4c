#ifndef _COMMON_PARAM_BINDING_H_
#define _COMMON_PARAM_BINDING_H_

#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

class ParamBinding : public Transform {
    const P4::ReferenceMap *refMap;
    const P4::TypeMap *typeMap;
    std::map<const IR::Type*, const IR::InstanceRef *>          by_type;
    std::map<const IR::Parameter *, const IR::InstanceRef *>    by_param;
    std::map<const IR::Declaration_Variable *, const IR::InstanceRef *>    by_declvar;
    const IR::Node *preorder(IR::Type_Parser *n) override { prune(); return n; }
    const IR::Node *preorder(IR::Type_Control *n) override { prune(); return n; }
    const IR::Expression *postorder(IR::PathExpression *pe) override;
    const IR::Expression *postorder(IR::Member *mem) override;

 public:
    ParamBinding(const P4::ReferenceMap *refMap, const P4::TypeMap *typeMap)
    : refMap(refMap), typeMap(typeMap) {}
    void bind(const IR::Parameter *param);
    const IR::InstanceRef *get(const IR::Parameter *param) {
        return by_param.count(param) ? by_param.at(param) : nullptr; }
};

class SplitComplexInstanceRef : public Transform {
    const IR::Node *preorder(IR::Primitive *prim) override {
        if (prim->operands.size() == 0) return prim;
        auto dest = prim->operands[0]->to<IR::InstanceRef>();
        if (!dest || dest->nested.empty()) return prim;
        auto *rv = new IR::Vector<IR::Expression>;
        for (auto nest : dest->nested) {
            auto *split = prim->clone();
            for (auto &op : split->operands)
                if (auto ir = op->to<IR::InstanceRef>())
                    op = ir->nested.at(nest.first);
            rv->push_back(split); }
        return rv; }
};

class RemoveInstanceRef : public Transform {
 public:
    RemoveInstanceRef() { dontForwardChildrenBeforePreorder = true; }
    const IR::Expression *preorder(IR::InstanceRef *ir) override {
        if (!ir->obj) {
            return new IR::TempVar(ir->type, ir->name.name);
        } else if (!ir->obj->is<IR::HeaderStack>())
            return new IR::ConcreteHeaderRef(ir->obj);
        return ir; }
};

#endif /* _COMMON_PARAM_BINDING_H_ */
