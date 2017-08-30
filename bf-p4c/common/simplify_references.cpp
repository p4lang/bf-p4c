/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/common/simplify_references.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeMap.h"
#include "tofino/common/param_binding.h"
#include "tofino/common/rewrite.h"

namespace {

class ApplyParamBindings : public Transform {
    ParamBinding* bindings;
    const P4::ReferenceMap *refMap;
    const IR::Node *preorder(IR::Type_Parser *n) override { prune(); return n; }
    const IR::Node *preorder(IR::Type_Control *n) override { prune(); return n; }
    const IR::Expression *postorder(IR::PathExpression *pe) override;
    const IR::Expression *postorder(IR::Member *mem) override;

 public:
    ApplyParamBindings(ParamBinding* bindings, const P4::ReferenceMap* refMap)
        : bindings(bindings), refMap(refMap) { }
};

const IR::Expression *ApplyParamBindings::postorder(IR::PathExpression *pe) {
    if (auto decl = refMap->getDeclaration(pe->path)) {
        if (auto param = decl->to<IR::Parameter>()) {
            if (auto ref = bindings->get(param)) {
                LOG2("binding " << pe << " to " << ref);
                return ref;
            } else {
                LOG3("no binding for " << param); }
        } else if (auto var = decl->to<IR::Declaration_Variable>()) {
            if (auto ref = bindings->get(var)) {
                LOG3("return existing instance for var " << var->name);
                return ref;
            } else {
                LOG2("creating instance for var " << var->name);
                bindings->bind(var);
                return bindings->get(var);
            }
        } else {
            LOG3(decl << " is not a parameter"); }
    } else {
        LOG3("nothing in blockMap for " << pe); }
    return pe;
}

const IR::Expression *ApplyParamBindings::postorder(IR::Member *mem) {
    if (auto iref = mem->expr->to<IR::InstanceRef>()) {
        if ((iref = iref->nested.get<IR::InstanceRef>(mem->member))) {
            LOG2("collapsing " << mem << " to " << iref);
            return iref; }
        LOG3("not collapsing " << mem << " (no nested iref)");
    } else {
        LOG3("not collapsing " << mem << " (not an iref)"); }
    return mem;
}

class SplitComplexInstanceRef : public Transform {
    profile_t init_apply(const IR::Node *root) override {
        return Transform::init_apply(root); }
    const IR::Node *preorder(IR::MethodCallStatement *prim) override;
};

/**
 * Split extern method calls that refer to a complex objects (non-header structs or stacks)
 * such calls need to be split to refer to each field or element of the stack.
 * These are (currently) just 'extract' and 'emit' methods.  They need to be split to
 * only extract a single header at a time.
 * We do this as a perorder function so after splitting, we'll recursively visit the split
 * children, splitting further as needed.
 */
const IR::Node *SplitComplexInstanceRef::preorder(IR::MethodCallStatement *mc) {
    if (mc->methodCall->arguments->size() == 0) return mc;
    auto dest = mc->methodCall->arguments->at(0)->to<IR::InstanceRef>();
    if (!dest) return mc;
    if (auto hs = dest->obj->to<IR::HeaderStack>()) {
        auto *rv = new IR::Vector<IR::StatOrDecl>;
        for (int idx = 0; idx < hs->size; ++idx) {
            auto *split = mc->methodCall->clone();
            auto *args = split->arguments->clone();
            split->arguments = args;
            for (auto &op : *args)
                if (auto ir = op->to<IR::InstanceRef>())
                    if (ir->obj == hs)
                        op = new IR::HeaderStackItemRef(ir, new IR::Constant(idx));
            rv->push_back(new IR::MethodCallStatement(mc->srcInfo, split)); }
        return rv;
    } else if (!dest->nested.empty()) {
        auto *rv = new IR::Vector<IR::StatOrDecl>;
        for (auto nest : dest->nested) {
            auto *split = mc->methodCall->clone();
            auto *args = split->arguments->clone();
            split->arguments = args;
            for (auto &op : *args)
                if (auto ir = op->to<IR::InstanceRef>())
                    op = ir->nested.at(nest.first);
            rv->push_back(new IR::MethodCallStatement(mc->srcInfo, split)); }
        return rv; }
    return mc;
}

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

class ConvertIndexToHeaderStackItemRef : public Transform {
    const IR::Expression *preorder(IR::ArrayIndex *idx) override {
        auto type = idx->type->to<IR::Type_Header>();
        if (!type) BUG("%1% is not a header stack ref", idx->type);
        return new IR::HeaderStackItemRef(idx->srcInfo, type, idx->left, idx->right);
    }
    const IR::Expression* preorder(IR::Member* member) override {
        auto type = member->type->to<IR::Type_Header>();
        if (!type) return member;
        if (member->member == "next")
            return new IR::HeaderStackItemRef(member->srcInfo, type, member->expr,
                                              new IR::Tofino::UnresolvedStackNext);
        if (member->member == "last")
            return new IR::HeaderStackItemRef(member->srcInfo, type, member->expr,
                                              new IR::Tofino::UnresolvedStackLast);
        return member;
    }
};

}  // namespace

SimplifyReferences::SimplifyReferences(ParamBinding* bindings,
                                       P4::ReferenceMap* refMap,
                                       P4::TypeMap* typeMap) {
    addPasses({
        new ApplyParamBindings(bindings, refMap),
        new SplitComplexInstanceRef,
        new RemoveInstanceRef,
        new RemoveIsValid,
        new ConvertIndexToHeaderStackItemRef,
        new RewriteForTofino(refMap, typeMap),
    });
}
