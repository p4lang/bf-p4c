#include "bf-p4c/common/flatten_emit_args.h"

void FlattenEmitArgs::postorder(IR::MethodCallExpression* mc) {
    auto method = mc->method->to<IR::Member>();
    if (!method || method->member != "emit") return;

    auto dname = method->expr->to<IR::PathExpression>();
    if (!dname) return;

    auto type = dname->type->to<IR::Type_Extern>();
    if (!type) return;

    if (type->name != "Mirror" && type->name != "Resubmit"
        && type->name != "Digest") return;

    // HACK(Han): after the P4-14 to TNA refactor, we should
    // derive these indices from the TNA model.
    // Assume the following syntax
    //   mirror.emit(session_id, field_list);
    //   resubmit.emit(field_list);
    //   resubmit.emit(); - resubmit without parameters
    //   digest.emit(field_list);
    int field_list_index = (type->name == "Mirror") ? 1 : 0;
    if (mc->arguments->size() == 0) {
        ERROR_CHECK(type->name == "Resubmit",
            "Invalid mirror or digest call without any arguments");
        return;
    }
    auto* arg = mc->arguments->at(field_list_index)->expression;
    if (auto* args = arg->to<IR::ListExpression>()) {
        auto* flattened_args = new IR::Vector<IR::Argument>();
        if (type->name == "Mirror")
            flattened_args->push_back(mc->arguments->at(0));
        flattened_args->push_back(new IR::Argument(flatten_args(args)));
        mc->arguments = flattened_args;
        LOG4("Flattened arguments: " << mc);
    }
}

IR::ListExpression* FlattenEmitArgs::flatten_args(const IR::ListExpression* args) {
    IR::Vector<IR::Expression> components;
    for (const auto* expr : args->components) {
        if (const auto* list_arg = expr->to<IR::ListExpression>()) {
            auto* flattened = flatten_args(list_arg);
            for (const auto* comp : flattened->components)
                components.push_back(comp);
        } else {
            components.push_back(expr);
        }
    }
    return new IR::ListExpression(components);
}
