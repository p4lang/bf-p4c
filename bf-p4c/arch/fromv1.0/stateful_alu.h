#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_STATEFUL_ALU_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_STATEFUL_ALU_H_

#include "frontends/p4-14/fromv1.0/converters.h"

namespace P4 {
namespace P4V1 {

class StatefulAluConverter : public ExternConverter {
    bool has_stateful_alu = false;
    struct reg_info {
        const IR::Register *reg = nullptr;
        const IR::Type::Bits *utype = nullptr;  // salu alu type
        const IR::Type *rtype = nullptr;  // layout type
    };
    std::map<const IR::Register *, reg_info>        cache;
    const IR::ActionProfile *getSelectorProfile(P4V1::ProgramStructure *,
                                                const IR::Declaration_Instance *);
    reg_info getRegInfo(P4V1::ProgramStructure *, const IR::Declaration_Instance *,
                        IR::Vector<IR::Node> *);
    const IR::Type::Bits *findUType(const IR::Declaration_Instance *, const IR::Type ** = nullptr);
    StatefulAluConverter();
    static StatefulAluConverter singleton;
 public:
    const IR::Type_Extern *convertExternType(P4V1::ProgramStructure *,
                const IR::Type_Extern *, cstring) override;
    const IR::Declaration_Instance *convertExternInstance(P4V1::ProgramStructure *,
                const IR::Declaration_Instance *, cstring,
                IR::IndexedVector<IR::Declaration> *) override;
    const IR::Statement *convertExternCall(P4V1::ProgramStructure *,
                const IR::Declaration_Instance *, const IR::Primitive *) override;
};

}  // namespace P4V1
}  // namespace P4

#endif /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_STATEFUL_ALU_H_ */
