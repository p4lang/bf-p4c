#ifndef EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_
#define EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_

#include "ir/ir.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/arch/psa/programStructure.h"
#include "bf-p4c/arch/psa/psa.h"

namespace BFN {

namespace PSA {

struct RewritePacketPath : public PassManager {
    explicit RewritePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
        PSA::ProgramStructure* structure);
};

}  // namespace PSA

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_PSA_REWRITE_PACKET_PATH_H_ */

