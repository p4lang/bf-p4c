#include "flatten_emit_args.h"
#include "bf-p4c/common/utils.h"

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
    //   mirror.emit(); - mirror without parameters
    //   resubmit.emit(field_list);
    //   resubmit.emit(); - resubmit without parameters
    //   digest.emit(field_list);
    //   digest.emit(); - digest without parameters
    int field_list_index = (type->name == "Mirror") ? 1 : 0;
    if (mc->arguments->size() == 0) return;

    if (type->name == "Mirror" && mc->arguments->size() != 2) {
        // Fatal error because invalid state later
        fatal_error("%1%: requires two arguments: mirror_id and field_list", mc);
    }

    auto* arg = mc->arguments->at(field_list_index);
    auto* aexpr = arg->expression;
    if (auto* liste = aexpr->to<IR::ListExpression>()) {
        auto* flattened_args = new IR::Vector<IR::Argument>();
        if (type->name == "Mirror")
            flattened_args->push_back(mc->arguments->at(0));
        flattened_args->push_back(new IR::Argument(flatten_args(liste)));
        mc->arguments = flattened_args;
        LOG4("Flattened arguments: " << mc);
    } else if (aexpr->type->to<IR::Type_Header>()) {
        auto result = new IR::ListExpression(arg->srcInfo, {});
        explode(aexpr, &result->components);
        auto newargs = mc->arguments->clone();
        newargs->at(1) = new IR::Argument(arg->name, result);
        mc->arguments = newargs;
        LOG4("Flattened arguments: " << mc);
    }
}

void FlattenEmitArgs::explode(const IR::Expression* expression,
    IR::Vector<IR::Expression>* output) {
    if (auto st = expression->type->to<IR::Type_Header>()) {
        for (auto f : st->fields) {
            auto e = new IR::Member(expression, f->name);
            explode(e, output);
        }
    } else {
        BUG_CHECK(!expression->type->is<IR::Type_StructLike>() &&
            !expression->type->is<IR::Type_Stack>(),
                  "%1%: unexpected type", expression->type);
        output->push_back(expression);
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
