#include "bf-p4c/midend/type_checker.h"

namespace BFN {

// Overrides the setTypeType method in base classes.
const IR::Type* TypeInference::setTypeType(const IR::Type* type, bool learn) {
    if (done()) return type;
    const IR::Type* typeToCanonicalize;
    if (readOnly)
        typeToCanonicalize = getOriginal<IR::Type>();
    else
        typeToCanonicalize = type;
    auto canon = canonicalize(typeToCanonicalize);
    if (canon != nullptr) {
        // Learn the new type
        if (canon != typeToCanonicalize && learn) {
            TypeInference tc(refMap, typeMap, true);
            unsigned e = ::errorCount();
            (void)canon->apply(tc);
            if (::errorCount() > e)
                return nullptr;
        }
        auto tt = new IR::Type_Type(canon);
        setType(getOriginal(), tt);
        setType(type, tt);
    }
    return canon;
}

/**
 * IR class to represent a special struct whose layout can be changed when used as
 * bridged metadata, mirrored metadata, etc.
 */
const IR::Node *TypeInference::postorder(IR::BFN::Type_StructFlexible *type) {
    auto canon = setTypeType(type);
    auto validator = [this] (const IR::Type* t) {
        while (t->is<IR::Type_Newtype>())
            t = getTypeType(t->to<IR::Type_Newtype>()->type);
        return t->is<IR::Type_Struct>() || t->is<IR::Type_Bits>() ||
               t->is<IR::Type_Header>() || t->is<IR::Type_HeaderUnion>() ||
               t->is<IR::Type_Enum>() || t->is<IR::Type_Error>() ||
               t->is<IR::Type_Boolean>() || t->is<IR::Type_Stack>() ||
               t->is<IR::Type_Varbits>() || t->is<IR::Type_ActionEnum>() ||
               t->is<IR::Type_Tuple>() || t->is<IR::Type_SerEnum>() ||
               t->is<IR::BFN::Type_StructFlexible>(); };
    validateFields(canon, validator);
    return type;
}

/**
 * IR class to represent sign conversion from bit<n> to int<n>, or vice versa.
 */
const IR::Node* TypeInference::postorder(IR::BFN::ReinterpretCast *expression) {
    if (done()) return expression;
    const IR::Type* sourceType = getType(expression->expr);
    const IR::Type* castType = getTypeType(expression->destType);
    if (sourceType == nullptr || castType == nullptr)
        return expression;
    if (!castType->is<IR::Type_Bits>()) {
        ::error("%1%: cast not supported", expression->destType);
        return expression;
    }
    setType(expression, castType);
    setType(getOriginal(), castType);
    return expression;
}

/**
 * IR class to represent the sign extension for int<n> type.
 */
const IR::Node* TypeInference::postorder(IR::BFN::SignExtend *expression) {
    if (done()) return expression;
    const IR::Type* sourceType = getType(expression->expr);
    const IR::Type* castType = getTypeType(expression->destType);
    if (sourceType == nullptr || castType == nullptr)
        return expression;
    if (!castType->is<IR::Type_Bits>()) {
        ::error("%1%: cast not supported", expression->destType);
        return expression;
    }
    setType(expression, castType);
    setType(getOriginal(), castType);
    return expression;
}

/**
 * Overrides the default implementation in frontend to add support
 * for IR::BFN::Type_StructFlexible.
 */
const IR::Node* TypeInference::postorder(IR::Type_Header* type) {
    auto canon = setTypeType(type);
    auto validator = [this] (const IR::Type* t) {
        while (t->is<IR::Type_Newtype>())
            t = getTypeType(t->to<IR::Type_Newtype>()->type);
        return t->is<IR::Type_Bits>() || t->is<IR::Type_Varbits>() ||
               t->is<IR::BFN::Type_StructFlexible>() ||
               (t->is<IR::Type_Struct>() && onlyBitsOrBitStructs(t)) ||
               t->is<IR::Type_SerEnum>(); };
    validateFields(canon, validator);

    LOG1("tt " << type);
    const IR::StructField* varbit = nullptr;
    for (auto field : type->fields) {
        auto ftype = getType(field);
        if (ftype == nullptr)
            return type;
        if (ftype->is<IR::Type_Varbits>()) {
            if (varbit == nullptr) {
                varbit = field;
            } else {
                typeError("%1% and %2%: multiple varbit fields in a header",
                          varbit, field);
                return type;
            }
        }
    }
    return type;
}

const IR::Type* TypeInference::canonicalize(const IR::Type* type) {
    if (type == nullptr)
        return nullptr;

    auto exists = typeMap->getType(type);
    if (exists != nullptr) {
        if (exists->is<IR::Type_Type>())
            return exists->to<IR::Type_Type>()->type;
        return exists;
    }
    if (auto tt = type->to<IR::Type_Type>())
        type = tt->type;

    if (type->is<IR::BFN::Type_StructFlexible>()) {
        auto str = type->to<IR::BFN::Type_StructFlexible>();
        auto fields = canonicalizeFields(str);
        if (fields == nullptr)
            return nullptr;
        const IR::Type *canon;
        if (fields != &str->fields)
            canon = new IR::BFN::Type_StructFlexible(str->srcInfo,
                    str->name, str->annotations, *fields);
        else
            canon = str;
        return canon;
    } else {
        return P4::TypeInference::canonicalize(type);
    }
}

TypeInference* TypeInference::clone() const {
    return new TypeInference(refMap, typeMap, true); }

// it might be better to allow frontend TypeChecking class to use
// custom TypeInference pass.
TypeChecking::TypeChecking(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                           bool updateExpressions) {
    addPasses({
        new P4::ResolveReferences(refMap),
        new BFN::TypeInference(refMap, typeMap, true), /* extended P4::TypeInference */
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
