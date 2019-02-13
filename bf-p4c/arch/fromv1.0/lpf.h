#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_LPF_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_LPF_H_

#include "frontends/p4/fromv1.0/converters.h"

namespace P4V1 {

class LpfConverter : public ExternConverter {
    LpfConverter();
    static LpfConverter singleton;
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

#endif /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_LPF_H_ */
