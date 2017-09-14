#ifndef BF_P4C_PARDE_BRIDGE_METADATA_H_
#define BF_P4C_PARDE_BRIDGE_METADATA_H_

#include "ir/ir.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/parde/field_packing.h"

class AddBridgedMetadata : public PassManager {
    PhvInfo       &phv;
    const FieldDefUse   &defuse;
    BFN::FieldPacking packing;

    class FindFieldsToBridge;
    class AddBridge;
 public:
    AddBridgedMetadata(PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* BF_P4C_PARDE_BRIDGE_METADATA_H_ */
