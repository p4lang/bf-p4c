#ifndef TOFINO_FROMV1_0_STATEFUL_ALU_H_
#define TOFINO_FROMV1_0_STATEFUL_ALU_H_

#include "frontends/p4/fromv1.0/converters.h"

namespace P4V1 {

class StatefulAluConverter : public ExternConverter {
    bool has_stateful_alu = false;
    struct reg_info {
        const IR::Register *reg = nullptr;
        const IR::Type::Bits *utype = nullptr;  // salu alu type
        const IR::Type *rtype = nullptr;  // layout type
    };
    reg_info getRegInfo(P4V1::ProgramStructure *, const IR::Declaration_Instance *);
    const IR::Type::Bits *findUType(const IR::Declaration_Instance *, const IR::Type ** = nullptr);
    StatefulAluConverter();
    static StatefulAluConverter singleton;
 public:
    const IR::Type_Extern *convertExternType(P4V1::ProgramStructure *,
                const IR::Type_Extern *, cstring) override;
    const IR::Declaration_Instance *convertExternInstance(P4V1::ProgramStructure *,
                const IR::Declaration_Instance *, cstring) override;
    const IR::Statement *convertExternCall(P4V1::ProgramStructure *,
                const IR::Declaration_Instance *, const IR::Primitive *) override;
};

}  // namespace P4V1

#endif /* TOFINO_FROMV1_0_STATEFUL_ALU_H_ */
