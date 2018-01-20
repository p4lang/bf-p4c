#ifndef BF_P4C_ARCH_REWRITE_PACKET_PATH_H_
#define BF_P4C_ARCH_REWRITE_PACKET_PATH_H_

#include "frontends/common/resolveReferences/referenceMap.h"
#include "ir/ir.h"
#include "program_structure.h"

namespace BFN {

namespace PSA {

struct TranslatePacketPath : public PassManager {
    TranslatePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                        ProgramStructure *structure);
};

}  // namespace PSA

}  // namespace BFN

#endif /* BF_P4C_ARCH_REWRITE_PACKET_PATH_H_ */

