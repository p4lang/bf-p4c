#include "frontends/p4/fromv1.0/converters.h"

namespace P4V1 {

CONVERT_PRIMITIVE(bypass_egress) {
    if (primitive->operands.size() != 0) return nullptr;
#if 0
    // FIXME -- need to include (via structure->include?) PSA or Tofino Native Arch definitions
    // FIXME -- of this metadata, or we'll get errors about ig_intr_md_for_tm being undefined
    auto meta = new IR::PathExpression("ig_intr_md_for_tm");
    auto flag = new IR::Member(meta, "bypass_egress");
    auto ftype = IR::Type::Bits::get(1);
    return structure->assign(primitive->srcInfo, flag, new IR::Constant(ftype, 1), ftype);
#else
    // FIXME -- defer converting this to an assignment until converting to TNA works
    structure->include("tofino/p4_14_prim.p4");
    return new IR::MethodCallStatement(primitive->srcInfo,
            IR::ID(primitive->srcInfo, "bypass_egress"), {});
#endif
}

CONVERT_PRIMITIVE(invalidate) {
    if (primitive->operands.size() != 1) return nullptr;
    structure->include("tofino/p4_14_prim.p4");
    ExpressionConverter conv(structure);
    auto arg = conv.convert(primitive->operands.at(0));
    return new IR::MethodCallStatement(primitive->srcInfo, IR::ID(primitive->srcInfo,
                    arg->is<IR::Constant>() ? "invalidate_raw" : "invalidate"), { arg });
}

CONVERT_PRIMITIVE(recirculate, 5) {
    if (primitive->operands.size() != 1) return nullptr;
    ExpressionConverter conv(structure);
    auto port = primitive->operands.at(0);
    if (!port->is<IR::Constant>() && !port->is<IR::ActionArg>()) return nullptr;
    structure->include("tofino/p4_14_prim.p4");
    port = conv.convert(port);
    port = new IR::Cast(IR::Type::Bits::get(9), port);
    return new IR::MethodCallStatement(primitive->srcInfo, "recirculate_raw", { port });
}

CONVERT_PRIMITIVE(sample_e2e) {
    if (primitive->operands.size() < 2 || primitive->operands.size() > 3) return nullptr;
    structure->include("tofino/p4_14_prim.p4");
    ExpressionConverter conv(structure);
    auto session = conv.convert(primitive->operands.at(0));
    auto length = conv.convert(primitive->operands.at(1));

    auto args = new IR::Vector<IR::Expression>();
    auto enumref = new IR::TypeNameExpression(
        new IR::Type_Name(new IR::Path(structure->v1model.clone.cloneType.Id())));
    auto kindarg = new IR::Member(enumref, structure->v1model.clone.cloneType.e2e.Id());
    args->push_back(kindarg);
    args->push_back(new IR::Cast(primitive->operands.at(0)->srcInfo,
                                 structure->v1model.clone.sessionType, session));
    args->push_back(length);
    if (primitive->operands.size() == 3) {
        auto list = structure->convertFieldList(primitive->operands.at(2));
        if (list != nullptr)
            args->push_back(list); }

    auto fn = IR::ID(primitive->srcInfo, args->size() == 4 ? "sample4" : "sample3");
    return new IR::MethodCallStatement(new IR::MethodCallExpression(fn.srcInfo,
                        new IR::PathExpression(fn), args));
}

CONVERT_PRIMITIVE(swap) {
    if (primitive->operands.size() != 2) return nullptr;
    ExpressionConverter conv(structure);
    auto temp = IR::ID(structure->makeUniqueName("temp"));
    auto v1 = primitive->operands.at(0);
    auto v2 = primitive->operands.at(1);
    auto type = v1->type;
    return new IR::BlockStatement({
        new IR::Declaration_Variable(temp, type, conv.convert(v1)),
        structure->assign(primitive->srcInfo, conv.convert(v1), conv.convert(v2), type),
        structure->assign(primitive->srcInfo, conv.convert(v2), new IR::PathExpression(temp), type)
    });
}

}  // end namespace P4V1
