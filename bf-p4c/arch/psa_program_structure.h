#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/ordered_set.h"
#include "bf-p4c/ir/gress.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "program_structure.h"

namespace BFN {

namespace PSA {

struct ProgramStructure : BFN::ProgramStructure {
    cstring type_ih;
    cstring type_im;
    cstring type_eh;
    cstring type_em;

    ordered_map<cstring, TranslationMap> methodcalls;

    // map the resub_md and recirc_md to the user-provided name and type.
    ordered_map<cstring, cstring> psaPacketPathNames;
    ordered_map<cstring, const IR::Type *> psaPacketPathTypes;

    void createParsers() override;

    void createControls() override;

    void createMain() override;

    const IR::P4Program *create(const IR::P4Program *program) override;
};

}  // namespace PSA

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_PSA_PROGRAM_STRUCTURE_H_ */
