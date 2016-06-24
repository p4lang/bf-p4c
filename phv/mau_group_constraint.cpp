#include "mau_group_constraint.h"
#include "constraints.h"

bool MauGroupConstraint::preorder(const IR::Primitive *prim) {
    // FIXME: This should include the extract instruction too. But extract() has
    // to be fixed in the IR.
    if (prim->name == "emit" || prim->name == "extract") {
        for (auto &byte : GetBytes(prim->operands[0])) {
            constraints_.SetEqual(byte.cfirst(), byte.clast(), Constraints::MAU_GROUP); }
    } else if (prim->name == "set_metadata") {
        for (auto &byte : GetBytes(prim->operands[0], prim->operands[1])) {
            constraints_.SetEqual(byte.cfirst(), byte.clast(), Constraints::MAU_GROUP); }
    } else if ("set" == prim->name || "bit_xor" == prim->name ||
             "bit_or" == prim->name || "bit_and" == prim->name) {
        LOG2("Setting constraint for " << (*prim));
        for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[1])) {
            constraints_.SetEqual(bit_pair.first, bit_pair.second, Constraints::MAU_GROUP); }
        if ("bit_xor" == prim->name || "bit_or" == prim->name || "bit_and" == prim->name) {
            for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[2])) {
                constraints_.SetEqual(bit_pair.first, bit_pair.second, Constraints::MAU_GROUP); } }
    } else if ("add" == prim->name || "add_to_field" == prim->name ||
             "subtract" == prim->name || "subtract_from_field" == prim->name) {
        LOG2("Setting constraint for " << (*prim));
        std::list<PHV::Bit> bits = GetBits(prim->operands.begin(), prim->operands.end());
        constraints_.SetEqual(bits.begin(), bits.end(), Constraints::MAU_GROUP);
    } else {
        WARNING("Unhandled primitive " << (*prim));
        return true; }
    return false;
}

bool MauGroupConstraint::preorder(const IR::Tofino::Deparser *dp) {
    std::list<PHV::Bit> bits = GetBits(dp->egress_port);
    constraints_.SetEqual(bits.begin(), bits.end(), Constraints::MAU_GROUP);
    return true;
}
