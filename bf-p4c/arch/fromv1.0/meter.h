#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_METER_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_METER_H_

#include "frontends/p4-14/fromv1.0/converters.h"

namespace P4 {
namespace P4V1 {

class MeterConverter : public ExternConverter {
    MeterConverter();
    static MeterConverter singleton;
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

#endif /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_METER_H_ */
