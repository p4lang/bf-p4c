#ifndef TOFINO_PARDE_BRIDGE_METADATA_H_
#define TOFINO_PARDE_BRIDGE_METADATA_H_

#include "ir/ir.h"
#include "tofino/common/field_defuse.h"

class AddBridgedMetadata : public PassManager {
    const PhvInfo       &phv;
    const FieldDefUse   &defuse;
    std::map<int, const IR::Expression *> need_bridge;

    class FindFieldsToBridge;
    class AddBridge;
 public:
    AddBridgedMetadata(const PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* TOFINO_PARDE_BRIDGE_METADATA_H_ */
