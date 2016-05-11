#ifndef _COMMON_PARAM_BINDING_H_
#define _COMMON_PARAM_BINDING_H_

#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

class ParamBinding : public Transform {
    const P4::ReferenceMap* refMap;
    std::map<const IR::Type*, const IR::InstanceRef *>          by_type;
    std::map<const IR::Parameter *, const IR::InstanceRef *>    by_param;
    const IR::Node *preorder(IR::Type_Parser *n) override { prune(); return n; }
    const IR::Node *preorder(IR::Type_Control *n) override { prune(); return n; }
    const IR::Expression *postorder(IR::PathExpression *pe) override;
    const IR::Expression *postorder(IR::Member *mem) override;

 public:
    explicit ParamBinding(const P4::ReferenceMap *refMap) : refMap(refMap) {}
    void bind(const IR::Parameter *param);
    const IR::InstanceRef *get(const IR::Parameter *param) {
        return by_param.count(param) ? by_param.at(param) : nullptr; }
};

class RemoveInstanceRef : public Transform {
 public:
    RemoveInstanceRef() { dontForwardChildrenBeforePreorder = true; }
    const IR::Expression *preorder(IR::InstanceRef *ir) {
        if (!ir->obj->is<IR::HeaderStack>())
            return new IR::ConcreteHeaderRef(ir->obj);
        return ir; }
};

#endif /* _COMMON_PARAM_BINDING_H_ */
