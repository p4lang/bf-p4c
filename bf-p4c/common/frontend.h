#ifndef TOFINO_COMMON_FRONTEND_H_
#define TOFINO_COMMON_FRONTEND_H_

#include "frontends/p4/fromv1.0/converters.h"

namespace Tofino {

class ExternConverter : public P4V1::ExternConverter {
    bool has_stateful_alu = false;
    struct reg_info {
        const IR::Register *reg = nullptr;
        const IR::Type::Bits *utype = nullptr;  // salu alu type
        const IR::Type *rtype = nullptr;  // layout type
    };
    reg_info getRegInfo(const IR::Declaration_Instance *);
    const IR::Type::Bits *findUType(const IR::Declaration_Instance *, const IR::Type ** = nullptr);
 public:
    const IR::Type_Extern *convertExternType(const IR::Type_Extern *, cstring) override;
    const IR::Declaration_Instance *convertExternInstance(
                const IR::Declaration_Instance *, cstring) override;
    const IR::Statement *convertExternCall(const IR::Declaration_Instance *,
                                           const IR::Primitive *) override;
};

}  // namespace Tofino

#endif /* TOFINO_COMMON_FRONTEND_H_ */
