#include "lib/bitvec.h"
#include "check_extern_invocation.h"
#include "backends/tofino/device.h"

namespace BFN {

void CheckExternInvocationCommon::checkExtern(const P4::ExternMethod *extMethod,
        const IR::MethodCallExpression *expr) {
    cstring externName = extMethod->object->getName().name;
    cstring externType = extMethod->originalExternType->name;
    bitvec pos;

    if (auto p = findContext<IR::BFN::TnaParser>()) {
        pos.setbit(genIndex(p->thread, PARSER));
        checkPipeConstraints(externType, pos, expr, externName, p->name);
    } else if (auto m = findContext<IR::BFN::TnaControl>()) {
        pos.setbit(genIndex(m->thread, MAU));
        checkPipeConstraints(externType, pos, expr, externName, m->name);
    } else if (auto d = findContext<IR::BFN::TnaDeparser>()) {
        pos.setbit(genIndex(d->thread, DEPARSER));
        checkPipeConstraints(externType, pos, expr, externName, d->name);
    }
}

void CheckExternInvocationCommon::initCommonPipeConstraints() {
    bitvec validInMau;
    validInMau.setbit(genIndex(INGRESS, MAU));
    validInMau.setbit(genIndex(EGRESS, MAU));
    setPipeConstraints("ActionProfile", validInMau);
    setPipeConstraints("ActionSelector", validInMau);
    setPipeConstraints("Alpm", validInMau);
    setPipeConstraints("Atcam", validInMau);
    setPipeConstraints("Counter", validInMau);
    setPipeConstraints("DirectCounter", validInMau);
    setPipeConstraints("DirectLpf", validInMau);
    setPipeConstraints("DirectMeter", validInMau);
    setPipeConstraints("DirectRegister", validInMau);
    setPipeConstraints("DirectRegisterAction", validInMau);
    setPipeConstraints("DirectWred", validInMau);
    setPipeConstraints("Hash", validInMau);
    setPipeConstraints("Lpf", validInMau);
    setPipeConstraints("MathUnit", validInMau);
    setPipeConstraints("Meter", validInMau);
    setPipeConstraints("Random", validInMau);
    setPipeConstraints("Register", validInMau);
    setPipeConstraints("RegisterAction", validInMau);
    setPipeConstraints("RegisterParam", validInMau);
    setPipeConstraints("Wred", validInMau);
    setPipeConstraints("invalidate", validInMau);
    setPipeConstraints("is_validated", validInMau);
    setPipeConstraints("max", validInMau);
    setPipeConstraints("min", validInMau);
    setPipeConstraints("SelectorAction", validInMau);

    bitvec validInDeparsers;
    validInDeparsers.setbit(genIndex(INGRESS, DEPARSER));
    validInDeparsers.setbit(genIndex(EGRESS, DEPARSER));
    setPipeConstraints("Checksum", validInDeparsers);
    setPipeConstraints("Digest", validInDeparsers);
    setPipeConstraints("Mirror", validInDeparsers);
    setPipeConstraints("Resubmit", validInDeparsers);
    setPipeConstraints("packet_out", validInDeparsers);
    setPipeConstraints("is_validated", validInDeparsers);

    bitvec validInParsers;
    validInParsers.setbit(genIndex(INGRESS, PARSER));
    validInParsers.setbit(genIndex(EGRESS, PARSER));
    setPipeConstraints("Checksum", validInParsers);
    setPipeConstraints("ParserCounter", validInParsers);
    setPipeConstraints("ParserPriority", validInParsers);
    setPipeConstraints("packet_in", validInParsers);
}

void CheckTNAExternInvocation::initPipeConstraints() {
    initCommonPipeConstraints();
}

void CheckT2NAExternInvocation::initPipeConstraints() {
    initCommonPipeConstraints();

    bitvec validInMau;
    validInMau.setbit(genIndex(INGRESS, MAU));
    validInMau.setbit(genIndex(EGRESS, MAU));
    setPipeConstraints("LearnAction", validInMau);
    setPipeConstraints("LearnAction2", validInMau);
    setPipeConstraints("LearnAction3", validInMau);
    setPipeConstraints("LearnAction4", validInMau);
    setPipeConstraints("MinMaxAction", validInMau);
    setPipeConstraints("MinMaxAction2", validInMau);
    setPipeConstraints("MinMaxAction3", validInMau);
    setPipeConstraints("MinMaxAction4", validInMau);

    bitvec validInGhost;
    validInGhost.setbit(genIndex(GHOST, MAU));
    setPipeConstraints("ActionProfile", validInGhost);
    setPipeConstraints("ActionSelector", validInGhost);
    setPipeConstraints("Counter", validInGhost);
    setPipeConstraints("DirectCounter", validInGhost);
    setPipeConstraints("DirectLpf", validInGhost);
    setPipeConstraints("DirectMeter", validInGhost);
    setPipeConstraints("DirectRegister", validInGhost);
    setPipeConstraints("DirectRegisterAction", validInGhost);
    setPipeConstraints("DirectRegisterAction2", validInMau | validInGhost);
    setPipeConstraints("DirectRegisterAction3", validInMau | validInGhost);
    setPipeConstraints("DirectRegisterAction4", validInMau | validInGhost);
    setPipeConstraints("DirectWred", validInGhost);
    setPipeConstraints("SelectorAction", validInGhost);
    setPipeConstraints("Hash", validInGhost);
    setPipeConstraints("Lpf", validInGhost);
    setPipeConstraints("MathUnit", validInGhost);
    setPipeConstraints("Meter", validInGhost);
    setPipeConstraints("Random", validInGhost);
    setPipeConstraints("Register", validInGhost);
    setPipeConstraints("RegisterAction", validInGhost);
    setPipeConstraints("RegisterAction2", validInMau | validInGhost);
    setPipeConstraints("RegisterAction3", validInMau | validInGhost);
    setPipeConstraints("RegisterAction4", validInMau | validInGhost);
    setPipeConstraints("RegisterParam", validInGhost);
    setPipeConstraints("Wred", validInGhost);
    setPipeConstraints("invalidate", validInGhost);
    setPipeConstraints("max", validInGhost);
    setPipeConstraints("min", validInGhost);

    bitvec validInIngressDeparser;
    validInIngressDeparser.setbit(genIndex(INGRESS, DEPARSER));
    setPipeConstraints("Pktgen", validInIngressDeparser);

#ifdef HAVE_CLOUDBREAK
    if (Device::currentDevice() == Device::CLOUDBREAK) {
        bitvec validInParsers;
        validInParsers.setbit(genIndex(INGRESS, PARSER));
        validInParsers.setbit(genIndex(EGRESS, PARSER));
        setPipeConstraints("extract_greedy", validInParsers);
        setPipeConstraints("lookahead_greedy", validInParsers);
    }
#endif
}

}  // namespace BFN
