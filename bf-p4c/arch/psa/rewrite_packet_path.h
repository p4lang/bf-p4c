#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_

#include "p4/methodInstance.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "ir/ir.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/arch/psa/programStructure.h"

namespace BFN {

namespace PSA {

struct RewritePacketPath : public PassManager {
    explicit RewritePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
        PSA::ProgramStructure* structure);
};

}  // namespace PSA

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_ */

