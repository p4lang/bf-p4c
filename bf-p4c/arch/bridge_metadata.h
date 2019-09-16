#ifndef BF_P4C_ARCH_BRIDGE_METADATA_H_
#define BF_P4C_ARCH_BRIDGE_METADATA_H_

#include "ir/ir.h"
#include "bf-p4c/arch/psa_program_structure.h"

namespace BFN {

static const cstring COMPILER_META = "__bfp4c_compiler_generated_meta";
static const cstring BRIDGED_MD = "__bfp4c_bridged_metadata";
static const cstring BRIDGED_MD_HEADER = "__bfp4c_bridged_metadata_header";
static const cstring BRIDGED_MD_FIELD = "__bfp4c_fields";
static const cstring BRIDGED_MD_INDICATOR = "__bfp4c_bridged_metadata_indicator";

struct AddTnaBridgeMetadata : public PassManager {
    AddTnaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

struct AddPsaBridgeMetadata : public PassManager {
    AddPsaBridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
        PSA::ProgramStructure* structure);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_METADATA_H_ */
