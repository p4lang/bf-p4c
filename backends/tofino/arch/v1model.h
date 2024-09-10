/**
 * \defgroup SimpleSwitchTranslation BFN::SimpleSwitchTranslation
 * \ingroup ArchTranslation
 * \brief Set of passes that translate v1model architecture.
 */
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
#include "backends/tofino/bf-p4c-options.h"
#include "backends/tofino/ir/gress.h"
#include "backends/tofino/arch/fromv1.0/v1_program_structure.h"
#include "backends/tofino/arch/fromv1.0/v1_converters.h"
#include "backends/tofino/arch/arch.h"
#include "backends/tofino/common/pragma/all_pragmas.h"
#include "backends/tofino/common/pragma/collect_global_pragma.h"

namespace BFN {

/** \ingroup SimpleSwitchTranslation */
class AddAdjustByteCount : public Modifier {
    V1::ProgramStructure *structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    bool preorder(IR::Declaration_Instance* decl) override;
 public:
     AddAdjustByteCount(V1::ProgramStructure *structure,
             P4::ReferenceMap* refMap, P4::TypeMap *typeMap)
         : structure(structure), refMap(refMap), typeMap(typeMap) {}
};

/**
 * \ingroup SimpleSwitchTranslation
 * \brief PassManager that governs normalization of v1model architecture.
 */
class SimpleSwitchTranslation : public PassManager {
 public:
    V1::ProgramStructure structure;
    const IR::ToplevelBlock   *toplevel = nullptr;

    SimpleSwitchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);

    const IR::ToplevelBlock* getToplevelBlock() { CHECK_NULL(toplevel); return toplevel; }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_V1MODEL_H_ */
