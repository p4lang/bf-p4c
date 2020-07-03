
#include "check_extern_invocation.h"

#include "bf-p4c/arch/arch.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

namespace {

int genIndex(gress_t gress, ArchBlock_t block) {
    return gress * ArchBlock_t::BLOCK_TYPE + block;
}

cstring extractBlock(bitvec vec) {
    int bit = vec.ffs(0);
    BUG_CHECK(vec.ffs(bit), "Trying to extract multiple gress/block encodings");
    static const char* lookup[] = {"parser", "control (MAU)", "deparser"};
    BUG_CHECK(sizeof(lookup)/sizeof(lookup[0]) == ArchBlock_t::BLOCK_TYPE, "Bad lookup table");
    return lookup[bit % ArchBlock_t::BLOCK_TYPE];
}

}  // namespace


bool CheckExternInvocationCommon::check_pipe_constraints(cstring extType, bitvec bv,
            const IR::MethodCallExpression *expr, cstring extName, cstring pipe) {
    BUG_CHECK(pipe_constraints.count(extType), "pipe constraints not defined for %1%", extType);
    auto constraint = pipe_constraints.at(extType) & bv;
    if (!bv.empty() && constraint.empty()) {
        ::error("%s %s %s cannot be used in the %s %s", expr->srcInfo,
                extType, extName, pipe, extractBlock(bv)); }
    return false;
}


bool CheckExternInvocationCommon::preorder(const IR::MethodCallExpression *expr) {
    auto mi = P4::MethodInstance::resolve(expr, refMap, typeMap);
    if (auto extMethod = mi->to<P4::ExternMethod>()) {
        cstring obj_name = extMethod->object->getName().name;
        auto name = extMethod->originalExternType->name;

        bitvec pos;
        int index = 0;
        auto p = findContext<IR::BFN::TnaParser>();
        if (p) {
            index = genIndex(p->thread, PARSER);
            pos.setbit(index);
            check_pipe_constraints(name, pos, expr, obj_name, p->name);
            return false; }

        auto m = findContext<IR::BFN::TnaControl>();
        if (m) {
            index = genIndex(m->thread, MAU);
            pos.setbit(index);
            check_pipe_constraints(name, pos, expr, obj_name, m->name);
            return false; }

        auto d = findContext<IR::BFN::TnaDeparser>();
        if (d) {
            index = genIndex(d->thread, DEPARSER);
            pos.setbit(index);
            check_pipe_constraints(name, pos, expr, obj_name, d->name);
            return false; }
    }
    return false;
}

void CheckExternInvocationCommon::init_common_pipe_constraints() {
    bitvec valid_in_mau;
    valid_in_mau.setbit(genIndex(INGRESS, MAU));
    valid_in_mau.setbit(genIndex(EGRESS, MAU));
    set_pipe_constraints("ActionProfile", valid_in_mau);
    set_pipe_constraints("ActionSelector", valid_in_mau);
    set_pipe_constraints("Alpm", valid_in_mau);
    set_pipe_constraints("Atcam", valid_in_mau);
    set_pipe_constraints("Counter", valid_in_mau);
    set_pipe_constraints("DirectCounter", valid_in_mau);
    set_pipe_constraints("DirectLpf", valid_in_mau);
    set_pipe_constraints("DirectMeter", valid_in_mau);
    set_pipe_constraints("DirectRegister", valid_in_mau);
    set_pipe_constraints("DirectRegisterAction", valid_in_mau);
    set_pipe_constraints("DirectWred", valid_in_mau);
    set_pipe_constraints("Hash", valid_in_mau);
    set_pipe_constraints("Lpf", valid_in_mau);
    set_pipe_constraints("MathUnit", valid_in_mau);
    set_pipe_constraints("Meter", valid_in_mau);
    set_pipe_constraints("Random", valid_in_mau);
    set_pipe_constraints("Register", valid_in_mau);
    set_pipe_constraints("RegisterAction", valid_in_mau);
    set_pipe_constraints("RegisterParam", valid_in_mau);
    set_pipe_constraints("Wred", valid_in_mau);
    set_pipe_constraints("invalidate", valid_in_mau);
    set_pipe_constraints("max", valid_in_mau);
    set_pipe_constraints("min", valid_in_mau);
    set_pipe_constraints("SelectorAction", valid_in_mau);

    bitvec valid_in_deparsers;
    valid_in_deparsers.setbit(genIndex(INGRESS, DEPARSER));
    valid_in_deparsers.setbit(genIndex(EGRESS, DEPARSER));
    set_pipe_constraints("Checksum", valid_in_deparsers);
    set_pipe_constraints("Digest", valid_in_deparsers);
    set_pipe_constraints("Mirror", valid_in_deparsers);
    set_pipe_constraints("Resubmit", valid_in_deparsers);
    set_pipe_constraints("packet_out", valid_in_deparsers);

    bitvec valid_in_parsers;
    valid_in_parsers.setbit(genIndex(INGRESS, PARSER));
    valid_in_parsers.setbit(genIndex(EGRESS, PARSER));
    set_pipe_constraints("Checksum", valid_in_parsers);
    set_pipe_constraints("ParserCounter", valid_in_parsers);
    set_pipe_constraints("ParserPriority", valid_in_parsers);
    set_pipe_constraints("packet_in", valid_in_parsers);
}

void CheckTNAExternInvocation::init_pipe_constraints() {
    init_common_pipe_constraints();
}

void CheckT2NAExternInvocation::init_pipe_constraints() {
    init_common_pipe_constraints();

    bitvec valid_in_mau;
    valid_in_mau.setbit(genIndex(INGRESS, MAU));
    valid_in_mau.setbit(genIndex(EGRESS, MAU));
    set_pipe_constraints("LearnAction", valid_in_mau);
    set_pipe_constraints("LearnAction2", valid_in_mau);
    set_pipe_constraints("LearnAction3", valid_in_mau);
    set_pipe_constraints("LearnAction4", valid_in_mau);
    set_pipe_constraints("MinMaxAction", valid_in_mau);
    set_pipe_constraints("MinMaxAction2", valid_in_mau);
    set_pipe_constraints("MinMaxAction3", valid_in_mau);
    set_pipe_constraints("MinMaxAction4", valid_in_mau);

    bitvec valid_in_ghost;
    valid_in_ghost.setbit(genIndex(GHOST, MAU));
    set_pipe_constraints("ActionProfile", valid_in_ghost);
    set_pipe_constraints("ActionSelector", valid_in_ghost);
    set_pipe_constraints("Counter", valid_in_ghost);
    set_pipe_constraints("DirectCounter", valid_in_ghost);
    set_pipe_constraints("DirectLpf", valid_in_ghost);
    set_pipe_constraints("DirectMeter", valid_in_ghost);
    set_pipe_constraints("DirectRegister", valid_in_ghost);
    set_pipe_constraints("DirectRegisterAction", valid_in_ghost);
    set_pipe_constraints("DirectRegisterAction2", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("DirectRegisterAction3", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("DirectRegisterAction4", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("DirectWred", valid_in_ghost);
    set_pipe_constraints("SelectorAction", valid_in_ghost);
    set_pipe_constraints("Hash", valid_in_ghost);
    set_pipe_constraints("Lpf", valid_in_ghost);
    set_pipe_constraints("MathUnit", valid_in_ghost);
    set_pipe_constraints("Meter", valid_in_ghost);
    set_pipe_constraints("Random", valid_in_ghost);
    set_pipe_constraints("Register", valid_in_ghost);
    set_pipe_constraints("RegisterAction", valid_in_ghost);
    set_pipe_constraints("RegisterAction2", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("RegisterAction3", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("RegisterAction4", valid_in_mau | valid_in_ghost);
    set_pipe_constraints("RegisterParam", valid_in_ghost);
    set_pipe_constraints("Wred", valid_in_ghost);
    set_pipe_constraints("invalidate", valid_in_ghost);
    set_pipe_constraints("max", valid_in_ghost);
    set_pipe_constraints("min", valid_in_ghost);

    bitvec valid_in_ingress_deparser;
    valid_in_ingress_deparser.setbit(genIndex(INGRESS, DEPARSER));
    set_pipe_constraints("Pktgen", valid_in_ingress_deparser);
}

}  // namespace BFN
