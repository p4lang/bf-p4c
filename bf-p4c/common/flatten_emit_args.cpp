#include "bf-p4c/common/flatten_emit_args.h"

void FlattenEmitArgs::postorder(IR::MethodCallExpression* mc) {
    auto method = mc->method->to<IR::Member>();
    if (!method || method->member != "emit") return;

    auto dname = method->expr->to<IR::PathExpression>();
    if (!dname) return;

    auto type = dname->type->to<IR::Type_Extern>();
    if (!type) return;

    if (type->name != "mirror_packet" && type->name != "resubmit_packet"
        && type->name != "learning_packet") return;

    auto* arg = mc->arguments->at(0);
    if (auto* args = arg->to<IR::ListExpression>()) {
        auto* flattened_args = new IR::Vector<IR::Expression>();
        flattened_args->push_back(flatten_args(args));
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
