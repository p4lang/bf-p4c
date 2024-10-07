#include "bf-p4c/midend/type_checker.h"

namespace BFN {

// Overrides the setTypeType method in base classes.
const P4::IR::Type* TypeInference::setTypeType(const P4::IR::Type* type, bool learn) {
    if (done()) return type;
    const P4::IR::Type* typeToCanonicalize;
    if (readOnly)
        typeToCanonicalize = getOriginal<P4::IR::Type>();
    else
        typeToCanonicalize = type;
    auto canon = canonicalize(typeToCanonicalize);
    if (canon != nullptr) {
        // Learn the new type
        if (canon != typeToCanonicalize && learn) {
            TypeInference tc(typeMap, true);
            unsigned e = errorCount();
            (void)canon->apply(tc);
            if (errorCount() > e)
                return nullptr;
        }
        auto tt = new P4::IR::Type_Type(canon);
        setType(getOriginal(), tt);
        setType(type, tt);
    }
    return canon;
}

/**
 * IR class to represent sign conversion from bit<n> to int<n>, or vice versa.
 */
 /*
const P4::IR::Node* TypeInference::postorder(P4::IR::BFN::ReinterpretCast *expression) {
    if (done()) return expression;
    const P4::IR::Type* sourceType = getType(expression->expr);
    const P4::IR::Type* castType = getTypeType(expression->destType);
    if (sourceType == nullptr || castType == nullptr)
        return expression;

    if (!castType->is<P4::IR::Type_Bits>() &&
        !castType->is<P4::IR::Type_Boolean>() &&
        !castType->is<P4::IR::Type_Newtype>() &&
        !castType->is<P4::IR::Type_SerEnum>()) {
        error("%1%: cast not supported", expression->destType);
        return expression;
    }
    setType(expression, castType);
    setType(getOriginal(), castType);
    return expression;
}*/

/**
 * IR class to represent the sign extension for int<n> type.
 */
 /*
const P4::IR::Node* TypeInference::postorder(P4::IR::BFN::SignExtend *expression) {
    if (done()) return expression;
    const P4::IR::Type* sourceType = getType(expression->expr);
    const P4::IR::Type* castType = getTypeType(expression->destType);
    if (sourceType == nullptr || castType == nullptr)
        return expression;
    if (!castType->is<P4::IR::Type_Bits>()) {
        error("%1%: cast not supported", expression->destType);
        return expression;
    }
    setType(expression, castType);
    setType(getOriginal(), castType);
    return expression;
}*/

const P4::IR::Node* TypeInference::postorder(P4::IR::Member* expression) {
    if (done()) return expression;
    auto type = getType(expression->expr);
    if (type == nullptr)
        return expression;
    cstring member = expression->member.name;
    if (type->is<P4::IR::Type_StructLike>()) {
        if (type->is<P4::IR::Type_Header>() || type->is<P4::IR::Type_HeaderUnion>()) {
            if (member == "$valid") {
                // Built-in method
                auto type = P4::IR::Type::Bits::get(1);
                auto ctype = canonicalize(type);
                if (ctype == nullptr)
                    return expression;
                setType(getOriginal(), ctype);
                setType(expression, ctype);
                setLeftValue(expression);
                setLeftValue(getOriginal<P4::IR::Expression>());
                return expression;
            }
        }
    }
    return P4::TypeInference::postorder(expression);
}

TypeInference* TypeInference::clone() const {
    return new TypeInference(typeMap, true); }

// it might be better to allow frontend TypeChecking class to use
// custom TypeInference pass.
TypeChecking::TypeChecking(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                           bool updateExpressions) :
                           P4::TypeChecking(refMap, typeMap, updateExpressions) {
    passes.clear();
    addPasses({
        new P4::ResolveReferences(refMap),
        new BFN::TypeInference(typeMap, true), /* extended P4::TypeInference */
        updateExpressions ? new P4::ApplyTypesToExpressions(typeMap) : nullptr,
        updateExpressions ? new P4::ResolveReferences(refMap) : nullptr });
    setStopOnError(true);
}

// similarly, it might be better to avoid code duplication here.
EvaluatorPass::EvaluatorPass(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    evaluator = new P4::Evaluator(refMap, typeMap);
    passes.emplace_back(new BFN::TypeChecking(refMap, typeMap));
    passes.emplace_back(evaluator);
}



}  // namespace BFN
