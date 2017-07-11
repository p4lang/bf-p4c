#ifndef TOFINO_PARDE_BRIDGE_METADATA_H_
#define TOFINO_PARDE_BRIDGE_METADATA_H_

#include "ir/ir.h"
#include "tofino/common/field_defuse.h"
#include "tofino/parde/field_packing.h"

class AddBridgedMetadata : public PassManager {
    PhvInfo       &phv;
    const FieldDefUse   &defuse;
    Tofino::FieldPacking packing;

    class FindFieldsToBridge;
    class AddBridge;
 public:
    AddBridgedMetadata(PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* TOFINO_PARDE_BRIDGE_METADATA_H_ */
