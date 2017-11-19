#include "wred.h"

P4V1::WREDConverter::WREDConverter() {
    addConverter("wred", this);
}

const IR::Type_Extern *P4V1::WREDConverter::convertExternType(P4V1::ProgramStructure *structure,
                                                             const IR::Type_Extern *, cstring) {
    structure->include("tofino/wred.p4");
    return nullptr;
}

const IR::Declaration_Instance *P4V1::WREDConverter::convertExternInstance(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext, cstring name,
        IR::IndexedVector<IR::Declaration> *) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "wred", "Extern %s is not wred type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Type *input_type;
    const IR::Expression *instance_count = nullptr;
    const IR::Expression *drop_value = nullptr;
    const IR::Expression *no_drop_value = nullptr;
    const IR::Expression *table = nullptr;
    bool direct = false;
    for (auto prop : Values(ext->properties)) {
        const IR::Expression *val = nullptr;
        if (auto ev = prop->value->to<IR::ExpressionValue>())
            val = conv.convert(ev->expression);
        if (prop->name == "wred_input") {
            input_type = val ? val->type : nullptr;
        } else if (prop->name == "direct" || prop->name == "static") {
            if (table) error("wred %s specifies both 'direct' and 'static'", ext);
            direct = prop->name == "direct";
            table = val;
        } else if (prop->name == "instance_count") {
            instance_count = val;
        } else if (prop->name == "drop_value") {
            drop_value = val;
        } else if (prop->name == "no_drop_value") {
            no_drop_value = val;
        } else {
            error("Unknown property %s on wred", prop);
            continue; }
        if (!val)
            error("%s: %s property is not an expression", prop->name, prop->value->srcInfo); }
    if (direct && instance_count)
        error("wred %s specifies both 'direct' and 'instance_count'", ext);
    if (!drop_value)
        drop_value = new IR::Constant(input_type, (1U << input_type->width_bits()) - 1);
    if (!no_drop_value) no_drop_value = new IR::Constant(input_type, 0);
    auto ctor_args = new IR::Vector<IR::Expression>({ no_drop_value, drop_value });
    if (instance_count) ctor_args->push_back(instance_count);
    auto wred_type = new IR::Type_Specialized(new IR::Type_Name("wred"),
                                new IR::Vector<IR::Type>({ input_type }));
    return new IR::Declaration_Instance(ext->srcInfo, name, wred_type, ctor_args);
}

const IR::Statement *P4V1::WREDConverter::convertExternCall(P4V1::ProgramStructure *structure,
        const IR::Declaration_Instance *ext, const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "wred", "Extern %s is not wred type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Statement *rv = nullptr;
    if (prim->name != "execute") {
        BUG("Unknown method %s in wred", prim->name); }
    BUG_CHECK(prim->operands.size() >= 2 && prim->operands.size() <= 3,
              "Expected 2 or 3 operands for %s", prim->name);
    const IR::Type *input_type = nullptr;
    auto dest = conv.convert(prim->operands.at(1));
    auto args = new IR::Vector<IR::Expression>();
    if (auto prop = ext->properties.get<IR::Property>("wred_input")) {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            input_type = ev->expression->type;
            args->push_back(conv.convert(ev->expression));
        } else {
            error("%s: wred_input property is not an expression", prop->value->srcInfo);
            return nullptr; }
    } else {
        error("No wred_input in %s", ext); }
    if (prim->operands.size() == 3)
        args->push_back(conv.convert(prim->operands.at(2)));
    auto extref = new IR::PathExpression(structure->externs.get(ext));
    auto method = new IR::Member(prim->srcInfo, extref, "execute");
    auto mc = new IR::MethodCallExpression(prim->srcInfo, input_type, method, args);
    rv = structure->assign(prim->srcInfo, dest, mc, input_type);
    return rv;
}

P4V1::WREDConverter P4V1::WREDConverter::singleton;
