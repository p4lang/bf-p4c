#include "container_constraint.h"
#include "constraints.h"
bool
ContainerConstraint::preorder(const IR::Primitive *prim) {
  // FIXME: This should include the extract instruction too. But extract() has
  // to be fixed in the IR.
  if (prim->name == "emit") {
    LOG2("Setting constraints for " << (*prim));
    for (auto &byte : GetBytes(prim->operands[0], nullptr)) {
      equality_constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                     Constraints::CONTAINER);
    }
  }
  if (prim->name == "set_metadata") {
    LOG2("Setting constraints for " << (*prim));
    for (auto &byte : GetBytes(prim->operands[0], prim->operands[1])) {
      equality_constraints_.SetEqual(byte.cfirst(), byte.clast(),
                                     Constraints::CONTAINER);
    }
  }
  // FIXME: We still do not handle the case where an operands can be split
  // across to adjacent PHVs.
  if ("add" == prim->name || "subtract" == prim->name) {
    LOG2("Setting constraints for " << (*prim));
    for (auto &op : prim->operands) {
      std::set<PHV::Bit> bits = GetBits(op);
      equality_constraints_.SetEqual(bits.cbegin(), bits.cend(),
                                     Constraints::CONTAINER);
    }
  }
  return false;
}
