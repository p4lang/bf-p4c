#include "offset_constraint.h"
#include "constraints.h"
bool
OffsetConstraint::preorder(const IR::Primitive *prim) {
  if ("bit_xor" == prim->name || "bit_or" == prim->name ||
      "bit_and" == prim->name || "add" == prim->name ||
      "subtract" == prim->name || "add_to_field" == prim->name ||
      "subtract_from_field" == prim->name) {
    for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[1])) {
      equality_constraints_.SetEqual(bit_pair.first, bit_pair.second,
                                     Constraints::OFFSET);
    }
    if (prim->operands.size() == 3) {
      for (auto &bit_pair : GetBitPairs(prim->operands[0], prim->operands[2])) {
        equality_constraints_.SetEqual(bit_pair.first, bit_pair.second,
                                       Constraints::OFFSET);
      }
    }
  }
  return false;
}
