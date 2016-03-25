#include "mau_group_constraint.h"
#include "constraints.h"

bool
MauGroupConstraint::preorder(const IR::Primitive *prim) {
  // FIXME: This should include the extract instruction too. But extract() has
  // to be fixed in the IR.
  if (prim->name == "emit") {
    for (auto &byte : GetBytes(prim->operands[0])) {
      equality_constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                     Constraints::MAU_GROUP);
    }
  }
  if (prim->name == "set_metadata") {
    for (auto &byte : GetBytes(prim->operands[0], prim->operands[1])) {
      equality_constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                     Constraints::MAU_GROUP);
    }
  }
  if ("set" == prim->name || "bit_xor" == prim->name ||
      "bit_or" == prim->name || "bit_and" == prim->name) {
    for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[1])) {
      equality_constraints_.SetEqual(bit_pair.first, bit_pair.second,
                                     Constraints::MAU_GROUP);
    }
  }
  if ("bit_xor" == prim->name || "bit_or" == prim->name ||
      "bit_and" == prim->name) {
    for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[2])) {
      equality_constraints_.SetEqual(bit_pair.first, bit_pair.second,
                                     Constraints::MAU_GROUP);
    }
  }
  if ("add" == prim->name || "subtract" == prim->name) {
    std::set<PHV::Bit> bits = GetBits(prim->operands.begin(),
                                      prim->operands.end());
    equality_constraints_.SetEqual(bits.begin(), bits.end(),
                                   Constraints::MAU_GROUP);
  }
  return false;
}
