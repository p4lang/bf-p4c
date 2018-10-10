#include "meter.h"

P4V1::MeterConverter::MeterConverter() {
    addConverter("meter", this);
}

const IR::Type_Extern *P4V1::MeterConverter::convertExternType(P4V1::ProgramStructure *structure,
                                                               const IR::Type_Extern *, cstring) {
    structure->include("tofino/meter.p4");
    return nullptr;
}

const IR::Declaration_Instance *P4V1::MeterConverter::convertExternInstance(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext, cstring name,
        IR::IndexedVector<IR::Declaration> *) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "meter", "Extern %s is not meter type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Member *meter_type = nullptr;
    const IR::Expression *instance_count = nullptr;
    const IR::Expression *table = nullptr;
    auto* externalName = new IR::StringLiteral(IR::ID("." + name));
    auto* annotations = new IR::Annotations({
        new IR::Annotation(IR::ID("name"), { externalName })});
    bool direct = false;
    LOG1("ext : " << ext);
    for (auto prop : Values(ext->properties)) {
        LOG1("prop : " << prop->name);
        const IR::Expression *val = nullptr;
        if (auto ev = prop->value->to<IR::ExpressionValue>())
            val = conv.convert(ev->expression);
        cstring valstr;
        if (auto sl = val->to<IR::StringLiteral>()) valstr = sl->value;
        if (auto pe = val->to<IR::PathExpression>()) valstr = pe->path->name;
        if (prop->name == "type") {
            if (valstr != "bytes" && valstr != "packets")
                error("%s property must be 'bytes' or 'packets'", prop);
            meter_type = new IR::Member(val->srcInfo,
                new IR::TypeNameExpression(new IR::Type_Name("MeterType_t")),
                valstr == "bytes" ? "BYTES" : "PACKETS");
        } else if (prop->name == "direct" || prop->name == "static") {
            if (table) error("meter %s specifies both 'direct' and 'static'", ext);
            direct = prop->name == "direct";
            table = val;
        } else if (prop->name == "instance_count") {
            instance_count = val;
        } else if (prop->name == "green_value") {
            annotations->addAnnotation("green", val);
        } else if (prop->name == "yellow_value") {
            annotations->addAnnotation("yellow", val);
        } else if (prop->name == "red_value") {
            annotations->addAnnotation("red", val);
        } else if (prop->name == "meter_sweep_interval") {
            auto ival = val->to<IR::Constant>()->asInt();
            BUG_CHECK(ival >= 0 || ival <= 4,
                "Meter sweep interval value is %d must be in the range [0:4] - %s", ival, ext);
            annotations->addAnnotation("meter_sweep_interval", val);
        } else if (prop->name == "meter_profile") {
            auto pval = val->to<IR::Constant>()->asInt();
            BUG_CHECK(pval >= 0 || pval <= 15,
                "Meter profile value is %d must be in the range [0:15] - %s", pval, ext);
            annotations->addAnnotation("meter_profile", val);
        } else {
            error("Unknown property %s on meter", prop);
            continue; }
        if (!val)
            error("%s: %s property is not an expression", prop->name, prop->value->srcInfo); }
    if (direct && instance_count)
        error("meter %s specifies both 'direct' and 'instance_count'", ext);

    auto args = new IR::Vector<IR::Argument>();
    if (instance_count) {
        args->push_back(new IR::Argument(instance_count));
        args->push_back(new IR::Argument(meter_type));
        auto type = new IR::Type_Specialized(
            new IR::Type_Name("Meter"),
            new IR::Vector<IR::Type>({ IR::Type::Bits::get(32) }));
        return new IR::Declaration_Instance(ext->srcInfo, name, annotations, type, args);
    } else {
        args->push_back(new IR::Argument(meter_type));
        auto type = new IR::Type_Name("DirectMeter");
        return new IR::Declaration_Instance(ext->srcInfo, name, annotations, type, args);
    }
}

const IR::Statement *P4V1::MeterConverter::convertExternCall(P4V1::ProgramStructure *structure,
        const IR::Declaration_Instance *ext, const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "meter", "Extern %s is not meter type, but %s", ext, ext->type);
    ExpressionConverter conv(structure);
    const IR::Statement *rv = nullptr;
    if (prim->name != "execute" && prim->name != "execute_with_or" &&
        prim->name != "execute_with_pre_color" && prim->name != "execute_with_pre_color_with_or") {
        BUG("Unknown method %s in meter",  prim->name); }
    bool direct = ext->properties.get<IR::Property>("instance_count") == nullptr;
    bool pre_color = strstr(prim->name, "pre_color");
    bool with_or = strstr(prim->name, "with_or");
    if (prim->operands.size() != 2U + pre_color + !direct)
        error("Expected %d operands for %s", 1 + pre_color + !direct, prim);
    auto dest = conv.convert(prim->operands.at(1));
    auto args = new IR::Vector<IR::Argument>();
    if (prim->operands.size() > 2)
        args->push_back(new IR::Argument(conv.convert(prim->operands.at(2))));
    if (prim->operands.size() > 3)
        args->push_back(new IR::Argument(conv.convert(prim->operands.at(3))));
    auto extref = new IR::PathExpression(structure->externs.get(ext));
    auto method = new IR::Member(prim->srcInfo, extref, "execute");
    IR::Expression *expr = new IR::MethodCallExpression(prim->srcInfo, method, args);
    if (with_or)
        expr = new IR::BOr(conv.convert(prim->operands.at(1)), expr);
    rv = structure->assign(prim->srcInfo, dest, expr, IR::Type::Bits::get(8));
    return rv;
}

P4V1::MeterConverter P4V1::MeterConverter::singleton;
