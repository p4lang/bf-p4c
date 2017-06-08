#ifndef TOFINO_COMMON_FRONTEND_H_
#define TOFINO_COMMON_FRONTEND_H_

#include "frontends/p4/fromv1.0/converters.h"

namespace Tofino {

class ExternConverter : public P4V1::ExternConverter {
    bool has_stateful_alu = false;
 public:
    const IR::Type_Extern *convertExternType(const IR::Type_Extern *, cstring) override;
    const IR::Declaration_Instance *convertExternInstance(
                const IR::Declaration_Instance *, cstring) override;
};

}  // namespace Tofino

#endif /* TOFINO_COMMON_FRONTEND_H_ */
