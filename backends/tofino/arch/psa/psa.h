/**
 * \defgroup PortableSwitchTranslation BFN::PortableSwitchTranslation
 * \ingroup ArchTranslation
 * \brief Set of passes that translate PSA architecture.
 */
#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_

#include <optional>
#include <boost/algorithm/string.hpp>
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
#include "backends/tofino/bf-p4c-options.h"
#include "backends/tofino/ir/gress.h"
#include "backends/tofino/arch/arch.h"

namespace BFN {

/**
 * \ingroup PortableSwitchTranslation
 * \brief PassManager that governs normalization of PSA architecture.
 */
class PortableSwitchTranslation : public PassManager {
 public:
    const IR::ToplevelBlock   *toplevel = nullptr;
    PortableSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                              BFN_Options& options);
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_PSA_PSA_H_ */
