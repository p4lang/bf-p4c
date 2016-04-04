#include "container_constraint.h"
#include "constraints.h"
bool ContainerConstraint::preorder(const IR::Primitive *prim) {
  // FIXME: This should include the extract instruction too. But extract() has
  // to be fixed in the IR.
  if (prim->name == "emit" || prim->name == "extract") {
    LOG2("Setting constraints for " << (*prim));
    for (auto &byte : GetBytes(prim->operands[0], nullptr)) {
      constraints_.SetEqual(byte.cfirst(), byte.clast(),
                            Constraints::CONTAINER);
    }
  }
  if (prim->name == "set_metadata") {
    LOG2("Setting constraints for " << (*prim));
    for (auto &byte : GetBytes(prim->operands[0], prim->operands[1])) {
      constraints_.SetEqual(byte.cfirst(), byte.clast(),
                            Constraints::CONTAINER);
    }
  }
  // FIXME: We still do not handle the case where an operands can be split
  // across to adjacent PHVs.
  if ("add" == prim->name || "subtract" == prim->name ||
      "add_to_field" == prim->name || "subtract_from_field" == prim->name) {
    LOG2("Setting constraint for " << (*prim));
    for (auto &op : prim->operands) {
      std::list<PHV::Bit> bits = GetBits(op);
      constraints_.SetEqual(bits.cbegin(), bits.cend(), Constraints::CONTAINER);
    }
  }
  return false;
}

bool ContainerConstraint::preorder(const IR::Tofino::Deparser *dp) {
  std::list<PHV::Bit> bits = GetBits(dp->egress_port);
  constraints_.SetEqual(bits.cbegin(), bits.cend(), Constraints::CONTAINER);
  return true;
}
