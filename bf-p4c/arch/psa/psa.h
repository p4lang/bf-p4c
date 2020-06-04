#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "ir/pattern.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/arch/arch.h"

namespace BFN {

class PortableSwitchTranslation : public PassManager {
 public:
    const IR::ToplevelBlock   *toplevel = nullptr;
    PortableSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                              BFN_Options& options);
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_ */
