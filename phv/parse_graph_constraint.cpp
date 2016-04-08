#include "parse_graph_constraint.h"
#include "phv.h"
#include "constraints.h"
#include <base/logging.h>
bool ParseGraphConstraint::preorder(const IR::Primitive *prim) {
  if (prim->name == "emit") {
    std::list<PHV::Bit> bits = GetBits(prim->operands[0]);
    CHECK(bits.size() != 0) << ": Invalid operand in " << *prim;
    CHECK(bits.size() % 8 == 0) << ": Invalid header size in " << (*prim);
    for (auto it1 = bits.cbegin(); it1 != bits.cend();) {
      for (auto it2 = bits.cbegin(); it2 != it1;) {
        if (std::distance(it2, it1) >= 32) {
          constraints_.SetContainerConflict(*it1, *it2);
        }
        else constraints_.SetBitConflict(*it1, *it2);
        std::advance(it2, 8);
      }
      std::advance(it1, 8);
    }
  }
  return true;
}
