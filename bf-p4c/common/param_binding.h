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
    profile_t init_apply(const IR::Node *root) override {
        return Transform::init_apply(root); }
    const IR::Node *preorder(IR::MethodCallStatement *prim) override;
};

class RemoveInstanceRef : public Transform {
    std::map<cstring, const IR::Expression *>   created_tempvars;
 public:
    RemoveInstanceRef() { dontForwardChildrenBeforePreorder = true; }
    const IR::Expression *preorder(IR::InstanceRef *ir) override {
        if (!ir->obj) {
            const IR::Expression *rv = nullptr;
            if (created_tempvars.count(ir->name.name)) {
                rv = created_tempvars.at(ir->name.name);
                LOG2("RemoveInstanceRef existing TempVar " << ir->name.name);
            } else {
                created_tempvars[ir->name.name] = rv = new IR::TempVar(ir->type, ir->name.name);
                LOG2("RemoveInstanceRef new TempVar " << ir->name.name); }
            return rv;
        } else if (!ir->obj->is<IR::HeaderStack>()) {
            LOG2("RemoveInstanceRef new ConcreteheaderRef " << ir->obj);
            return new IR::ConcreteHeaderRef(ir->obj);
        } else {
            LOG2("RemoveInstanceRef not removing " << ir->name.name);
            return ir; } }
};

/**
 * Remove calls to the `isValid()` method on headers and replace them with
 * references to the header's `$valid` POV bit field.
 *
 * XXX(seth): It would be nicer to deal with this in terms of the
 * frontend/midend IR, because then we could rerun type checking and resolve
 * references to make sure everything is still correct. Doing it here feels a
 * bit hacky by comparison. This is considerably simpler, though, so it makes
 * sense as a first step.
 */
class RemoveIsValid : public Transform {
 private:
    const IR::Expression* preorder(IR::MethodCallExpression* call) override {
        std::cerr << "[RemoveIsValid] considering call: " << call << std::endl;
        auto* method = call->method->to<IR::Member>();
        if (!method) return call;

        if (method->member != "isValid") return call;
        BUG_CHECK(call->arguments->size() == 0,
                  "Wrong number of arguments for method call: %1%", call);
        auto* target = method->expr;
        BUG_CHECK(target != nullptr, "Method has no target: %1%", call);
        BUG_CHECK(target->type->is<IR::Type_Header>(),
                  "Invoking isValid() on unexpected type %1%", target->type);

        // On Tofino, calling a header's `isValid()` method is implemented by
        // reading the header's POV bit, which is a simple bit<1> value.
        const cstring validField = "$valid";
        auto* member = new IR::Member(call->srcInfo, target, validField);
        member->type = IR::Type::Bits::get(1);

        // If isValid() is being used as a table key element, it already behaves
        // like a bit<1> value; just replace it with a reference to the valid bit.
        if (getParent<IR::KeyElement>() != nullptr) return member;

        // In other contexts, rewrite isValid() into a comparison with a constant.
        // This maintains a boolean type for the overall expression.
        auto* constant = new IR::Constant(IR::Type::Bits::get(1), 1);
        auto* result = new IR::Equ(call->srcInfo, member, constant);
        result->type = IR::Type::Boolean::get();
        return result;
    }
};

#endif /* _COMMON_PARAM_BINDING_H_ */
