#include "frontends/p4/fromv1.0/converters.h"

namespace P4V1 {

CONVERT_PRIMITIVE(bypass_egress) {
    if (primitive->operands.size() != 0) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    return new IR::MethodCallStatement(primitive->srcInfo,
            IR::ID(primitive->srcInfo, "bypass_egress"), {});
}

static cstring makeHashCall(ProgramStructure *structure, IR::BlockStatement *block,
                            const IR::Expression *field_list) {
    ExpressionConverter conv(structure);
    auto flc = structure->getFieldListCalculation(field_list);
    if (flc == nullptr) {
        ::error("%1%: Expected a field_list_calculation", field_list);
        return cstring(); }
    auto ttype = IR::Type_Bits::get(flc->output_width);
    cstring temp = structure->makeUniqueName("temp");
    block->push_back(new IR::Declaration_Variable(temp, ttype));
    block->push_back(new IR::MethodCallStatement(
        new IR::MethodCallExpression(flc->srcInfo, structure->v1model.hash.Id(), {
            new IR::Argument(new IR::PathExpression(new IR::Path(temp))),
            new IR::Argument(structure->convertHashAlgorithms(flc->algorithm)),
            new IR::Argument(new IR::Constant(ttype, 0)),
            new IR::Argument(conv.convert(flc->input_fields)),
            new IR::Argument(new IR::Constant(IR::Type_Bits::get(flc->output_width + 1),
                             1 << flc->output_width)) })));
    return temp;
}

CONVERT_PRIMITIVE(count_from_hash) {
    if (primitive->operands.size() != 2) return nullptr;
    ExpressionConverter conv(structure);
    auto ref = primitive->operands.at(0);
    const IR::Counter *counter = nullptr;
    if (auto gr = ref->to<IR::GlobalRef>())
        counter = gr->obj->to<IR::Counter>();
    else if (auto nr = ref->to<IR::PathExpression>())
        counter = structure->counters.get(nr->path->name);
    if (counter == nullptr) {
        ::error("Expected a counter reference %1%", ref);
        return nullptr; }
    auto block = new IR::BlockStatement;
    cstring temp = makeHashCall(structure, block, primitive->operands.at(1));
    if (!temp) return nullptr;
    auto counterref = new IR::PathExpression(structure->counters.get(counter));
    auto method = new IR::Member(counterref, structure->v1model.counter.increment.Id());
    auto arg = new IR::Cast(structure->v1model.counter.index_type,
                            new IR::PathExpression(new IR::Path(temp)));
    block->push_back(new IR::MethodCallStatement(primitive->srcInfo, method,
                                                 { new IR::Argument(arg) }));
    return block;
}

static bool makeMeterExecCall(const Util::SourceInfo &srcInfo, ProgramStructure *structure,
                              IR::BlockStatement *block, const IR::Expression *mref,
                              const IR::Expression *index, const IR::Expression *dest) {
    const IR::Meter *meter = nullptr;
    if (auto gr = mref->to<IR::GlobalRef>())
        meter = gr->obj->to<IR::Meter>();
    else if (auto nr = mref->to<IR::PathExpression>())
        meter = structure->meters.get(nr->path->name);
    if (meter == nullptr) {
        ::error("Expected a meter reference %1%", mref);
        return false; }
    auto meterref = new IR::PathExpression(structure->meters.get(meter));
    auto method = new IR::Member(meterref, structure->v1model.meter.executeMeter.Id());
    auto arg = new IR::Cast(structure->v1model.meter.index_type, index);
    block->push_back(new IR::MethodCallStatement(srcInfo, method,
                                                 { new IR::Argument(arg),
                                                   new IR::Argument(dest) }));
    return true;
}

CONVERT_PRIMITIVE(execute_meter, 5) {
    if (primitive->operands.size() != 4) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    ExpressionConverter conv(structure);
    // FIXME -- convert this to a custom primitive so TNA translation can convert
    // FIXME -- it to an execute call on a TNA meter
    return new IR::MethodCallStatement(primitive->srcInfo,
            IR::ID(primitive->srcInfo, "execute_meter_with_color"), {
                new IR::Argument(conv.convert(primitive->operands.at(0))),
                new IR::Argument(conv.convert(primitive->operands.at(1))),
                new IR::Argument(conv.convert(primitive->operands.at(2))),
                new IR::Argument(conv.convert(primitive->operands.at(3))) });
}

CONVERT_PRIMITIVE(execute_meter_from_hash) {
    if (primitive->operands.size() != 3 && primitive->operands.size() != 4) return nullptr;
    ExpressionConverter conv(structure);
    auto block = new IR::BlockStatement;
    cstring temp = makeHashCall(structure, block, primitive->operands.at(1));
    if (primitive->operands.size() == 3) {
        if (!makeMeterExecCall(primitive->srcInfo, structure, block,
                               conv.convert(primitive->operands.at(0)),
                               new IR::PathExpression(new IR::Path(temp)),
                               conv.convert(primitive->operands.at(2))))
            return nullptr;
    } else {
        // has pre-color, so need TNA specific call
        structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
        block->push_back(
            new IR::MethodCallStatement(primitive->srcInfo,
                IR::ID(primitive->srcInfo, "execute_meter_with_color"), {
                    new IR::Argument(conv.convert(primitive->operands.at(0))),
                    new IR::Argument(new IR::PathExpression(new IR::Path(temp))),
                    new IR::Argument(conv.convert(primitive->operands.at(2))),
                    new IR::Argument(conv.convert(primitive->operands.at(3))) })); }
    return block;
}

CONVERT_PRIMITIVE(execute_meter_from_hash_with_or) {
    if (primitive->operands.size() != 3 && primitive->operands.size() != 4) return nullptr;
    ExpressionConverter conv(structure);
    auto block = new IR::BlockStatement;
    cstring temp = makeHashCall(structure, block, primitive->operands.at(1));
    auto dest = conv.convert(primitive->operands.at(2));
    cstring temp2 = structure->makeUniqueName("temp");
    block->push_back(new IR::Declaration_Variable(temp2, dest->type));
    if (primitive->operands.size() == 3) {
        if (!makeMeterExecCall(primitive->srcInfo, structure, block,
                               conv.convert(primitive->operands.at(0)),
                               new IR::PathExpression(new IR::Path(temp)),
                               new IR::PathExpression(new IR::Path(temp2))))
            return nullptr;
    } else {
        // has pre-color, so need TNA specific call
        structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
        block->push_back(
            new IR::MethodCallStatement(primitive->srcInfo,
                IR::ID(primitive->srcInfo, "execute_meter_with_color"), {
                    new IR::Argument(conv.convert(primitive->operands.at(0))),
                    new IR::Argument(new IR::PathExpression(new IR::Path(temp))),
                    new IR::Argument(new IR::PathExpression(new IR::Path(temp2))),
                    new IR::Argument(conv.convert(primitive->operands.at(3))) })); }
    block->push_back(
        new IR::AssignmentStatement(dest,
            new IR::BOr(dest, new IR::PathExpression(new IR::Path(temp2)))));
    return block;
}

CONVERT_PRIMITIVE(execute_meter_with_or) {
    if (primitive->operands.size() != 3 && primitive->operands.size() != 4) return nullptr;
    ExpressionConverter conv(structure);
    auto block = new IR::BlockStatement;
    auto dest = conv.convert(primitive->operands.at(2));
    cstring temp2 = structure->makeUniqueName("temp");
    block->push_back(new IR::Declaration_Variable(temp2, dest->type));
    if (primitive->operands.size() == 3) {
        if (!makeMeterExecCall(primitive->srcInfo, structure, block,
                               conv.convert(primitive->operands.at(0)),
                               conv.convert(primitive->operands.at(1)),
                               new IR::PathExpression(new IR::Path(temp2))))
            return nullptr;
    } else {
        // has pre-color, so need TNA specific call
        structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
        block->push_back(
            new IR::MethodCallStatement(primitive->srcInfo,
                IR::ID(primitive->srcInfo, "execute_meter_with_color"), {
                    new IR::Argument(conv.convert(primitive->operands.at(0))),
                    new IR::Argument(conv.convert(primitive->operands.at(1))),
                    new IR::Argument(new IR::PathExpression(new IR::Path(temp2))),
                    new IR::Argument(conv.convert(primitive->operands.at(3))) })); }
    block->push_back(
        new IR::AssignmentStatement(dest,
            new IR::BOr(dest, new IR::PathExpression(new IR::Path(temp2)))));
    return block;
}

CONVERT_PRIMITIVE(invalidate) {
    if (primitive->operands.size() != 1) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    ExpressionConverter conv(structure);
    auto arg = conv.convert(primitive->operands.at(0));
    return new IR::MethodCallStatement(primitive->srcInfo, IR::ID(primitive->srcInfo,
                    arg->is<IR::Constant>() ? "invalidate_raw" : "invalidate"),
                                       { new IR::Argument(arg) });
}

CONVERT_PRIMITIVE(invalidate_digest) {
    if (primitive->operands.size() != 0) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    ExpressionConverter conv(structure);
    // Since V1model does not understand the Tofino metadata, this is a simple pass through
    // and will be translated to `invalidate(ig_intr_md_for_dprsr.digest_type)` in
    // arch/simple_switch.cpp during Tofino mapping.
    return new IR::MethodCallStatement(primitive->srcInfo, IR::ID(primitive->srcInfo,
                                                                  "invalidate_digest"),
                                       {});
}

CONVERT_PRIMITIVE(recirculate, 5) {
    if (primitive->operands.size() != 1) return nullptr;
    ExpressionConverter conv(structure);
    auto port = primitive->operands.at(0);
    if (!port->is<IR::Constant>() && !port->is<IR::ActionArg>()) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    port = conv.convert(port);
    port = new IR::Cast(IR::Type::Bits::get(9), port);
    return new IR::MethodCallStatement(primitive->srcInfo, "recirculate_raw",
                                       { new IR::Argument(port) });
}

CONVERT_PRIMITIVE(sample_e2e) {
    if (primitive->operands.size() < 2 || primitive->operands.size() > 3) return nullptr;
    structure->include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    ExpressionConverter conv(structure);
    auto session = conv.convert(primitive->operands.at(0));
    auto length = conv.convert(primitive->operands.at(1));

    auto args = new IR::Vector<IR::Argument>();
    auto enumref = new IR::TypeNameExpression(
        new IR::Type_Name(new IR::Path(structure->v1model.clone.cloneType.Id())));
    auto kindarg = new IR::Member(enumref, structure->v1model.clone.cloneType.e2e.Id());
    args->push_back(new IR::Argument(kindarg));
    args->push_back(new IR::Argument(new IR::Cast(primitive->operands.at(0)->srcInfo,
                                                  structure->v1model.clone.sessionType, session)));
    args->push_back(new IR::Argument(length));
    if (primitive->operands.size() == 3) {
        auto list = structure->convertFieldList(primitive->operands.at(2));
        if (list != nullptr)
            args->push_back(new IR::Argument(list)); }

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


// This function is identical to the one in frontend in all aspects except that
// the field list used as argument after conversion is a modified class of
// ListExpression. This class saves the field list calculation and field list
// names which are then used in context json to generate PD
CONVERT_PRIMITIVE(modify_field_with_hash_based_offset, 1) {
    ExpressionConverter conv(structure);
    if (primitive->operands.size() != 4) return nullptr;

    auto dest = conv.convert(primitive->operands.at(0));
    auto base = conv.convert(primitive->operands.at(1));
    auto max = conv.convert(primitive->operands.at(3));
    auto args = new IR::Vector<IR::Argument>();

    auto flc = structure->getFieldListCalculation(primitive->operands.at(2));
    if (flc == nullptr) {
        ::error("%1%: Expected a field_list_calculation", primitive->operands.at(2));
        return nullptr;
    }
    auto ttype = IR::Type_Bits::get(flc->output_width);
    auto fl = structure->getFieldLists(flc);
    if (fl == nullptr)
        return nullptr;
    const IR::ListExpression *listExp = conv.convert(fl)->to<IR::ListExpression>();
    auto list = new IR::HashListExpression(flc->srcInfo, listExp->components, flc->name);
    list->fieldListNames = flc->input;

    auto algorithm = structure->convertHashAlgorithms(flc->algorithm);
    args->push_back(new IR::Argument(dest));
    args->push_back(new IR::Argument(algorithm));
    args->push_back(new IR::Argument(new IR::Cast(ttype, base)));
    args->push_back(new IR::Argument(list));
    args->push_back(new IR::Argument(
        new IR::Cast(max->srcInfo, IR::Type_Bits::get(2 * flc->output_width), max)));
    auto hash = new IR::PathExpression(structure->v1model.hash.Id());
    auto mc = new IR::MethodCallExpression(primitive->srcInfo, hash, args);
    auto result = new IR::MethodCallStatement(primitive->srcInfo, mc);
    return result;
}

}  // end namespace P4V1
