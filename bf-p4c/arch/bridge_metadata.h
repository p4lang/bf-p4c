#ifndef BF_P4C_ARCH_BRIDGE_METADATA_H_
#define BF_P4C_ARCH_BRIDGE_METADATA_H_

#include "ir/ir.h"
#include "bf-p4c/arch/psa_program_structure.h"

namespace BFN {

struct AddTnaBridgeMetadata : public PassManager {
    AddTnaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

struct AddPsaBridgeMetadata : public PassManager {
    AddPsaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
        PSA::ProgramStructure* structure);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_METADATA_H_ */
