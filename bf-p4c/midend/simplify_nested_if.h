#include <stack>
#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/midend/path_linearizer.h"
#include "bf-p4c/midend/type_categories.h"

#ifndef _EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_NESTED_IF_H_
#define _EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_NESTED_IF_H_

namespace P4 {

class SkipControlPolicy {
 public:
    virtual ~SkipControlPolicy() {}
    /**
       If the policy returns true the control block is processed,
       otherwise it is left unchanged.
    */
    virtual bool convert(const IR::P4Control* control) const = 0;
};

class ProcessDeparser : public SkipControlPolicy {
 public:
    ProcessDeparser() {}
    bool convert(const IR::P4Control* control) const override {
        return control->is<IR::BFN::TranslatedP4Deparser>();
    }
};

class DoSimplifyNestedIf : public Transform {
    SkipControlPolicy *policy;
    ordered_map<const IR::Statement*, std::vector<const IR::Expression*>> predicates;
    std::vector<const IR::Expression*> stack_;

 public:
    explicit DoSimplifyNestedIf(SkipControlPolicy *policy) : policy(policy) {
        CHECK_NULL(policy); }

    const IR::Node* preorder(IR::IfStatement *statement) override;
    const IR::Node* preorder(IR::P4Control *control) override;
};

class SimplifyComplexConditionPolicy {
 public:
    virtual ~SimplifyComplexConditionPolicy() {}
    virtual void reset() = 0;
    virtual bool check(const IR::Expression*) = 0;
};

class UniqueAndValidDest : public SimplifyComplexConditionPolicy {
    ReferenceMap *refMap;
    TypeMap *typeMap;
    const std::set<cstring>* valid_fields;
    std::set<cstring> unique_fields;

 public:
    UniqueAndValidDest(ReferenceMap *refMap, TypeMap *typeMap,
            const std::set<cstring> *valid_fields) :
            refMap(refMap), typeMap(typeMap), valid_fields(valid_fields) {
        CHECK_NULL(refMap);
        CHECK_NULL(typeMap);
        CHECK_NULL(valid_fields); }

    void reset() override {
        unique_fields.clear();
    }
    bool check(const IR::Expression* dest) override {
        BFN::PathLinearizer path;
        dest->apply(path);
        if (!path.linearPath) {
            ::error("Destination %1% is too complex ", dest);
            return false; }

        auto* param = BFN::getContainingParameter(*path.linearPath, refMap);
        auto* paramType = typeMap->getType(param);
        if (!BFN::isIntrinsicMetadataType(paramType)) {
            ::error("Destination %1% must be intrinsic metadata ", dest);
            return false; }

        if (auto mem = path.linearPath->components[0]->to<IR::Member>()) {
            if (!valid_fields->count(mem->member.name)) {
                ::error("Invalid field name %1%, the valid fields to use are "
                        "digest_type, resubmit_type and mirror_type"); } }

        unique_fields.insert(path.linearPath->to_cstring());

        if (unique_fields.size() != 1)
            return false;

        return true;
    }
};

/**
 * Tofino does not support complex condition on if statements in
 * deparser. This pass tries to simplify the conditions to a
 * simple comparison to constant, e.g.:
 * if (intrinsic_md.mirror_type == 1) {}
 */
class DoSimplifyComplexCondition : public Transform {
    SimplifyComplexConditionPolicy* policy;
    SkipControlPolicy* skip;

    bitvec constants;
    std::stack<const IR::Expression*> stack_;
    const IR::Expression* unique_dest;

 public:
    DoSimplifyComplexCondition(SimplifyComplexConditionPolicy* policy,
                               SkipControlPolicy *skip) :
            policy(policy), skip(skip) {
        CHECK_NULL(policy); CHECK_NULL(skip); }

    void do_equ(bitvec& val, const IR::Equ* eq);
    void do_neq(bitvec& val, const IR::Neq* neq);
    const IR::Node* preorder(IR::LAnd* expr) override;
    const IR::Node* preorder(IR::P4Control *control) override;
};

/**
 * Only simplify nested if statements in the deparser control block
 */
class SimplifyNestedIf : public PassManager {
 public:
    SimplifyNestedIf(ReferenceMap* refMap, TypeMap* typeMap,
                     TypeChecking* typeChecking = nullptr) {
        std::set<cstring> valid_fields;
        valid_fields = {"digest_type", "resubmit_type", "mirror_type"};
        auto policy = new UniqueAndValidDest(refMap, typeMap, &valid_fields);
        auto skip = new ProcessDeparser();
        if (!typeChecking)
            typeChecking = new TypeChecking(refMap, typeMap);
        passes.push_back(typeChecking);
        passes.push_back(new DoSimplifyNestedIf(skip));
        passes.push_back(new StrengthReduction(refMap, typeMap, typeChecking));
        passes.push_back(new SimplifyControlFlow(refMap, typeMap, typeChecking));
        passes.push_back(new DoSimplifyComplexCondition(policy, skip));
        setName("SimplifyNestedIf");
    }
};

}  // namespace P4

#endif /* _EXTENSIONS_BF_P4C_MIDEND_SIMPLIFY_NESTED_IF_H_ */
