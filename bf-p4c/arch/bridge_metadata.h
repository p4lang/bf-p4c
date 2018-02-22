#ifndef BF_P4C_ARCH_BRIDGE_METADATA_H_
#define BF_P4C_ARCH_BRIDGE_METADATA_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

struct BridgeMetadata : public PassManager {
    BridgeMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_BRIDGE_METADATA_H_ */
