#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_V1_PROGRAM_STRUCTURE_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_V1_PROGRAM_STRUCTURE_H_

#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/ordered_set.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/ir/gress.h"

namespace BFN {

namespace V1 {

/// Experimental implementation of programStructure to facilitate the
/// translation between P4-16 program of different architecture.
struct ProgramStructure : BFN::ProgramStructure {
    // maintain symbol tables for program transformation
    ChecksumSourceMap                            checksums;

    /// user program specific info
    cstring type_h;
    cstring type_m;
    const IR::Parameter *user_metadata;
    bool backward_compatible;

    void createParsers() override;
    void createControls() override;
    void createMain() override;
    void createPipeline();
    const IR::P4Program *create(const IR::P4Program *program) override;
};

}  // namespace V1

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_V1_PROGRAM_STRUCTURE_H_ */
