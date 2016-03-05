#ifndef _COMMON_PARAM_BINDING_H_
#define _COMMON_PARAM_BINDING_H_

#include "ir/ir.h"
#include "frontends/p4v1.2/evaluator/evaluator.h"

class ParamBinding : public Transform {
    const P4V12::BlockMap *blockMap;
    std::map<const IR::Type*, const IR::InstanceRef *>          by_type;
    std::map<const IR::Parameter *, const IR::InstanceRef *>    by_param;
    const IR::Node *preorder(IR::Type_Parser *n) { prune(); return n; }
    const IR::Node *preorder(IR::Type_Control *n) { prune(); return n; }
    const IR::Expression *postorder(IR::PathExpression *pe);
    const IR::Expression *postorder(IR::Member *mem);

 public:
    explicit ParamBinding(const P4V12::BlockMap *bm) : blockMap(bm) {}
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
