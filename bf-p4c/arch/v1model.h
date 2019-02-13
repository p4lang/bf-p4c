#ifndef BF_P4C_ARCH_V1MODEL_H_
#define BF_P4C_ARCH_V1MODEL_H_

#include <boost/algorithm/string.hpp>
#include "ir/ir.h"
#include "ir/namemap.h"
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
#include "bf-p4c/arch/fromv1.0/v1_program_structure.h"
#include "bf-p4c/arch/fromv1.0/v1_converters.h"
#include "bf-p4c/arch/arch.h"

namespace BFN {

class SimpleSwitchTranslation : public PassManager {
 public:
    V1::ProgramStructure structure;
    const IR::ToplevelBlock   *toplevel = nullptr;

    SimpleSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);

    const IR::ToplevelBlock* getToplevelBlock() { CHECK_NULL(toplevel); return toplevel; }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_V1MODEL_H_ */
