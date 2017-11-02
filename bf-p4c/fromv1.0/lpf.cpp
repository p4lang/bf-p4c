#include "lpf.h"

P4V1::LpfConverter::LpfConverter() {
    addConverter("lpf", this);
}

const IR::Type_Extern *P4V1::LpfConverter::convertExternType(P4V1::ProgramStructure *structure,
                                                             const IR::Type_Extern *, cstring) {
    structure->include("tofino/lpf.p4");
    return nullptr;
}

const IR::Declaration_Instance *P4V1::LpfConverter::convertExternInstance(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext, cstring name) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "lpf", "Extern %s is not lpf type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Type *filt_type;
    const IR::Expression *instance_count = nullptr;
    const IR::Expression *table = nullptr;
    bool direct = false;
    for (auto prop : Values(ext->properties)) {
        const IR::Expression *val = nullptr;
        if (auto ev = prop->value->to<IR::ExpressionValue>())
            val = conv.convert(ev->expression);
        if (prop->name == "filter_input") {
            filt_type = val ? val->type : nullptr;
        } else if (prop->name == "direct" || prop->name == "static") {
            if (table) error("lpf %s specifies both 'direct' and 'static'", ext);
            direct = prop->name == "direct";
            table = val;
        } else if (prop->name == "instance_count") {
            instance_count = val;
        } else {
            error("Unknown property %s on lpf", prop);
            continue; }
        if (!val)
            error("%s: %s property is not an expression", prop->name, prop->value->srcInfo); }
    if (direct && instance_count)
        error("lpf %s specifies both 'direct' and 'instance_count'", ext);
    auto ctor_args = new IR::Vector<IR::Expression>();
    if (instance_count) ctor_args->push_back(instance_count);
    auto lpf_type = new IR::Type_Specialized(new IR::Type_Name("lpf"),
                                new IR::Vector<IR::Type>({ filt_type }));
    return new IR::Declaration_Instance(ext->srcInfo, name, lpf_type, ctor_args);
}

const IR::Statement *P4V1::LpfConverter::convertExternCall(P4V1::ProgramStructure *structure,
        const IR::Declaration_Instance *ext, const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "lpf", "Extern %s is not lpf type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Statement *rv = nullptr;
    if (prim->name != "execute") {
        BUG("Unknown method %s in lpf", prim->name); }
    BUG_CHECK(prim->operands.size() >= 2 && prim->operands.size() <= 3,
              "Expected 2 or 3 operands for %s", prim->name);
    const IR::Type *filt_type = nullptr;
    auto dest = conv.convert(prim->operands.at(1));
    auto args = new IR::Vector<IR::Expression>();
    if (auto prop = ext->properties.get<IR::Property>("filter_input")) {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            filt_type = ev->expression->type;
            args->push_back(conv.convert(ev->expression));
        } else {
            error("%s: filter_input property is not an expression", prop->value->srcInfo);
            return nullptr; }
    } else {
        error("No filter_input in %s", ext); }
    if (prim->operands.size() == 3)
        args->push_back(conv.convert(prim->operands.at(2)));
    auto extref = new IR::PathExpression(structure->externs.get(ext));
    auto method = new IR::Member(prim->srcInfo, extref, "execute");
    auto mc = new IR::MethodCallExpression(prim->srcInfo, filt_type, method, args);
    rv = structure->assign(prim->srcInfo, dest, mc, filt_type);
    return rv;
}

P4V1::LpfConverter P4V1::LpfConverter::singleton;
