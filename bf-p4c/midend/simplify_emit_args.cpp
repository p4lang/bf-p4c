#include "simplify_emit_args.h"
#include "bf-p4c/common/utils.h"

namespace BFN {

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

DoEliminateEmitHeaders::DoEliminateEmitHeaders(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        refMap(refMap), typeMap(typeMap) { setName("EliminateEmitHeaders"); }

const IR::Node *DoEliminateEmitHeaders::preorder(IR::Argument *arg) {
    const IR::Type *type = nullptr;
    if (auto path = arg->expression->to<IR::PathExpression>()) {
        if (path->type->is<IR::Type_StructLike>())
            type = path->type->to<IR::Type_StructLike>();
        else
            return arg;
    } else if (auto mem = arg->expression->to<IR::Member>()) {
        if (mem->type->is<IR::Type_StructLike>())
            type = mem->type->to<IR::Type_StructLike>();
        else
            return arg; }

    if (!type) return arg;

    auto mc = findContext<IR::MethodCallExpression>();
    if (!mc) return arg;

    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
    if (auto em = mi->to<P4::ExternMethod>()) {
        if (em->actualExternType->name != "Digest" &&
            em->actualExternType->name != "Mirror" &&
            em->actualExternType->name != "Resubmit")
            return arg; }

    auto fieldList = IR::Vector<IR::Expression>();
    if (auto header = type->to<IR::Type_Header>()) {
        for (auto f : header->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(mem);
        }
    } else if (auto st = type->to<IR::Type_Struct>()) {
        for (auto f : st->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(mem); } }

    if (fieldList.size())
        return new IR::Argument(arg->srcInfo, new IR::ListExpression(fieldList));

    return arg;
}

}  // namespace BFN
