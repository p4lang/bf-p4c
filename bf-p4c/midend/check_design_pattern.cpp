#include "check_design_pattern.h"
#include "frontends/p4/methodInstance.h"
#include "lib/error.h"

bool BFN::CheckExternValidity::preorder(const IR::MethodCallExpression* expr) {
    auto* mi = P4::MethodInstance::resolve(expr, refMap, typeMap, true);

    std::set<cstring> externsToCheck = {"Mirror", "Resubmit", "Digest", "Pktgen", "Hash"};
    std::set<cstring> methodToCheck = {"emit", "pack", "get"};

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
                    std::string errString = " field list cannot be empty";
                    if (externName != "Hash")
                        errString += ", use emit()?";
                    error(ErrorType::ERR_UNSUPPORTED, errString.c_str(), expr);
                    return false;
                }
            }
        } else {
            error(ErrorType::ERR_UNSUPPORTED, " field list argument not present", expr);
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
