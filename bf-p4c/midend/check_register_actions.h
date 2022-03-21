#ifndef EXTENSIONS_BF_P4C_MIDEND_CHECK_REGISTER_ACTIONS_H_
#define EXTENSIONS_BF_P4C_MIDEND_CHECK_REGISTER_ACTIONS_H_

#include "frontends/p4/typeMap.h"
#include "ir/ir.h"

namespace BFN {

/**
 * \class CheckRegisterActions
 * \ingroup midend
 * \brief PassManager that checks if the RegisterActions work on proper Registers.
 *
 * Registers and their RegisterActions use don't care types that are unified. This
 * pass just checks if the RegisterAction works with register that has the same width.
 * If not we can still allow it, but only if the index width is appropriately increased/decreased.
 */
class CheckRegisterActions : public Inspector {
    P4::TypeMap* typeMap;

    bool preorder(const IR::Declaration_Instance* di) override;

 public:
    explicit CheckRegisterActions(P4::TypeMap* typeMap) : typeMap(typeMap) {}
};

}  // namespace BFN

#endif  // EXTENSIONS_BF_P4C_MIDEND_CHECK_REGISTER_ACTIONS_H_
