#include "check_design_pattern.h"
#include "lib/error.h"

bool BFN::CheckExternValidity::preorder(const IR::MethodCallExpression* expr) {
    auto* mi = P4::MethodInstance::resolve(expr, refMap, typeMap, true);

    std::set<cstring> externsToCheck = {"Hash"};
    std::set<cstring> methodToCheck = {"get"};

    // size_t is the number of parameters in emit/pack call that uses field list.
    std::map<cstring, size_t> expectedFieldListPos = {
        {"Mirror", 2}, {"Resubmit", 1},
        {"Digest", 1}, {"Pktgen", 1},
        {"Hash",   1}};

    std::map<cstring, cstring> emitMethod = {
        {"Mirror", "emit"}, {"Resubmit", "emit"},
        {"Digest", "pack"}, {"Pktgen", "emit"},
        {"Hash", "get"}};

    std::set<cstring> structAllowed = { "Digest", "Hash" };

    if (auto *em = mi->to<P4::ExternMethod>()) {
        auto externName = em->actualExternType->name;
        // skip if wrong extern
        if (!externsToCheck.count(externName))
            return false;
        // skip if wrong method
        if (!methodToCheck.count(em->method->name))
            return false;
        // skip if no field list
        if (expectedFieldListPos.at(externName) > em->method->getParameters()->size())
            return false;
        size_t fieldListIdx = expectedFieldListPos.at(externName) - 1;

        // emitted field list cannot be an empty list
        auto args = expr->arguments;
        if (fieldListIdx < args->size()) {
            auto arg = args->at(fieldListIdx);
            if (auto lexp = arg->expression->to<IR::ListExpression>()) {
                if (lexp->size() == 0) {
                    std::string errString = "%1%: field list cannot be empty";
                    if (externName != "Hash")
                        errString += ", use emit()?";
                    error(ErrorType::ERR_UNSUPPORTED, errString.c_str(), expr);
                    return false;
                }
            }
            if (auto sexp = arg->expression->to<IR::StructExpression>()) {
                if (sexp->size() == 0) {
                    std::string errString = "%1%: field list cannot be empty";
                    if (externName != "Hash")
                        errString += ", use emit()?";
                    error(ErrorType::ERR_UNSUPPORTED, errString.c_str(), expr);
                    return false;
                }
            }
        } else {
            error(ErrorType::ERR_UNSUPPORTED, "%1%: field list argument not present", expr);
        }

        const IR::Type* cannoType;
        auto param = em->actualMethodType->parameters->parameters.at(fieldListIdx);
        if (param->type->is<IR::Type_Name>())
            cannoType = typeMap->getTypeType(param->type, true);
        else
            cannoType = param->type;

        // emitted field list must be a header
        if (!structAllowed.count(externName) &&
            !cannoType->is<IR::Type_Header>()) {
            ::error(ErrorType::ERR_TYPE_ERROR, "The parameter %1% in %2% must be a header, "
                    "not a %3%. You may need to specify the type parameter T on %2%", param,
                    expr, cannoType);
            return false; }
    }
    return false;
}

Visitor::profile_t BFN::FindDirectExterns::init_apply(const IR::Node* root) {
    directExterns.clear();
    return Inspector::init_apply(root);
}

typedef BFN::CheckDirectResourceInvocation BFN_CheckDiResIn;
const std::map<cstring, cstring>  BFN_CheckDiResIn::externsToProperties = {
     { "DirectCounter"  , "counters"  },
     { "DirectMeter"    , "meters"    },
     { "DirectRegister" , "registers" },
     { "DirectLpf"      , "filters"   },
     { "DirectWred"     , "filters"   }
};

bool BFN::FindDirectExterns::preorder(const IR::MethodCallExpression* expr) {
    auto* mi = P4::MethodInstance::resolve(expr, refMap, typeMap, true);
    if (auto *em = mi->to<P4::ExternMethod>()) {
        auto externName = em->actualExternType->name;
        // skip if wrong extern
        if (!BFN_CheckDiResIn::externsToProperties.count(externName))
            return false;

        auto act = findContext<IR::P4Action>();
        if (!act) return false;

        directExterns[act].push_back(em);
    }
    return false;
}

bool BFN::CheckDirectExternsOnTables::preorder(IR::P4Table* table) {
    auto actionList = table->getActionList();
    for (auto act : actionList->actionList) {
        auto action = refMap->getDeclaration(act->getPath())->to<IR::P4Action>();
        if (directExterns.count(action)) {
            auto externMethods = directExterns[action];
            for (auto em : externMethods) {
                auto externName = em->actualExternType->name;
                auto externObjName = em->object->getName();
                auto propToCheck = BFN_CheckDiResIn::externsToProperties.at(externName);
                bool missingExtern = false;
                if (auto prop = table->properties->getProperty(propToCheck)) {
                    if (auto propValue = prop->value->to<IR::ExpressionValue>()) {
                        if (auto propPath = propValue->expression->to<IR::PathExpression>())
                            if (externObjName != propPath->path->name)
                                missingExtern = true;
                    }
                } else {
                    // If a property is missing on the table but defined in
                    // the tables actions, we add it here.
                    // However, BF Runtime generation happens before midend and
                    // to ensure this direct resource api is generated in bf-rt
                    // json we have to either run this pass before or flag an
                    // error. For now we error out and ask user to correct P4 to
                    // generate API
                    auto newPath = new IR::PathExpression(externObjName);
                    auto newPropValue = new IR::ExpressionValue(newPath);
                    auto newProp = new IR::Property(propToCheck,
                        IR::Annotations::empty, newPropValue, false);
                    auto properties = table->properties->clone();
                    properties->push_back(newProp);
                    table->properties = properties;
                    missingExtern = true;
                }

                if (missingExtern) {
                    ::error(ErrorType::ERR_TYPE_ERROR,
                        "Direct Extern - '%2%' of type '%1%' is used in action "
                        "'%3%' but not specified as a '%4%' property on the "
                        "actions table '%5%'. Please add it to the table to "
                        "generate the runtime API for this extern",
                        externName, em->object->externalName(), action->externalName(),
                        propToCheck, table->externalName());
                }
            }
        }
    }
    return false;
}

bool BFN::CheckTableConstEntries::preorder(const IR::P4Table *tbl) {
    if (tbl->getEntries() && tbl->getEntries()->size() == 0) {
        ::error(ErrorType::ERR_UNEXPECTED,
            "table %1% should not have empty const entries list.", tbl->name);
    }
    return false;
}
