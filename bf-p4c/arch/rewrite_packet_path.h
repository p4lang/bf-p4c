#ifndef BF_P4C_ARCH_REWRITE_PACKET_PATH_H_
#define BF_P4C_ARCH_REWRITE_PACKET_PATH_H_

#include "p4/methodInstance.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "ir/ir.h"
#include "program_structure.h"
#include "psa_program_structure.h"

namespace BFN {

namespace PSA {

struct RewritePacketPath : public PassManager {
    explicit RewritePacketPath(ProgramStructure *structure);
};

}  // namespace PSA

}  // namespace BFN

#endif /* BF_P4C_ARCH_REWRITE_PACKET_PATH_H_ */

