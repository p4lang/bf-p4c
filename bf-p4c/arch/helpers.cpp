#include "bf-p4c/arch/helpers.h"

namespace BFN {

boost::optional<cstring> getExternTypeName(const P4::ExternMethod* extMethod) {
    boost::optional<cstring> name = boost::none;
    if (auto inst = extMethod->object->to<IR::Declaration_Instance>()) {
        if (auto tn = inst->type->to<IR::Type_Name>()) {
            name = tn->path->name;
        } else if (auto ts = inst->type->to<IR::Type_Specialized>()) {
            if (auto bt = ts->baseType->to<IR::Type_Name>()) {
                name = bt->path->name; } }
    } else if (auto param = extMethod->object->to<IR::Parameter>()) {
        if (auto tn = param->type->to<IR::Type_Name>()) {
            name = tn->path->name;
        } else if (auto te = param->type->to<IR::Type_Extern>()) {
            name = te->name;
        }
    }
    return name;
}

/**
 * Helper functions to handle list of extern instances from table properties.
 */
boost::optional<P4::ExternInstance>
getExternInstanceFromPropertyByTypeName(const IR::P4Table* table,
                                        cstring propertyName,
                                        cstring externTypeName,
                                        P4::ReferenceMap* refMap,
                                        P4::TypeMap* typeMap,
                                        bool *isConstructedInPlace) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error(ErrorType::ERR_EXPECTED,
                "Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }
    auto expr = property->value->to<IR::ExpressionValue>()->expression;

    std::vector<P4::ExternInstance> rv;
    auto process_extern_instance = [&] (const IR::Expression* expr) {
        if (isConstructedInPlace) *isConstructedInPlace = expr->is<IR::ConstructorCallExpression>();
        if (expr->is<IR::ConstructorCallExpression>()
                && property->getAnnotation(IR::Annotation::nameAnnotation) == nullptr) {
            ::error(ErrorType::ERR_UNSUPPORTED,
                    "Table '%1%' has an anonymous table property '%2%' with no name annotation, "
                    "which is not supported by P4Runtime", table->controlPlaneName(), propertyName);
        }
        auto name = property->controlPlaneName();
        auto externInstance = P4::ExternInstance::resolve(expr, refMap, typeMap, name);
        if (!externInstance) {
            ::error(ErrorType::ERR_INVALID,
                    "Expected %1% property value for table %2% to resolve to an "
                    "extern instance: %3%", propertyName, table->controlPlaneName(),
                    property);
        }
        if (externInstance->type->name == externTypeName) {
            rv.push_back(*externInstance);
        }
    };
    if (expr->is<IR::ListExpression>()) {
        for (auto inst : expr->to<IR::ListExpression>()->components) {
            process_extern_instance(inst); }
    } else {
        process_extern_instance(expr); }

    if (rv.empty())
        return boost::none;

    if (rv.size() > 1) {
        ::error(ErrorType::ERR_UNSUPPORTED,
                "Table '%1%' has more than one extern with type '%2%' attached to"
                "property '%3%', which is not supported by Tofino", table->controlPlaneName(),
                externTypeName, propertyName);
    }
    return rv[0];
}

/**
 * Helper functions to extract extern instance from table properties.
 * Originally implemented in as part of the control-plane repo.
 */
boost::optional<P4::ExternInstance>
getExternInstanceFromProperty(const IR::P4Table* table,
                              cstring propertyName,
                              P4::ReferenceMap* refMap,
                              P4::TypeMap* typeMap) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error("Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }

    auto expr = property->value->to<IR::ExpressionValue>()->expression;
    auto name = property->controlPlaneName();
    auto externInstance = P4::ExternInstance::resolve(expr, refMap, typeMap, name);
    if (!externInstance) {
        ::error("Expected %1% property value for table %2% to resolve to an "
                "extern instance: %3%", propertyName, table->controlPlaneName(),
                property);
        return boost::none; }

    return externInstance;
}

boost::optional<const IR::ExpressionValue*>
getExpressionFromProperty(const IR::P4Table* table,
                          const cstring& propertyName) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error("Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }

    auto expr = property->value->to<IR::ExpressionValue>();
    return expr;
}

}  // namespace BFN
