#include "parse_graph_constraint.h"
#include "phv.h"
#include "constraints.h"
#include <base/logging.h>
bool ParseGraphConstraint::preorder(const IR::Primitive *prim) {
//if (prim->name == "emit") {
//  std::list<PHV::Bit> bits = GetBits(prim->operands[0]);
//  CHECK(bits.size() != 0) << ": Invalid operand in " << *prim;
//  CHECK(bits.size() % 8 == 0) << ": Invalid header size in " << (*prim);
//  for (auto it1 = bits.cbegin(); it1 != bits.cend();) {
//    for (auto it2 = bits.cbegin(); it2 != it1;) {
//      if (std::distance(it2, it1) >= 32) {
//        constraints_.SetContainerConflict(*it1, *it2);
//      }
//      else constraints_.SetBitConflict(*it1, *it2);
//      std::advance(it2, 8);
//    }
//    std::advance(it1, 8);
//  }
//}
  if (prim->name == "extract") {
    auto bytes = GetBytes(prim->operands[0]);
    for (auto &b : bytes) {
      extracts_.insert(extracts_.end(), b.begin(), b.end());
      extract_widths_.top() += b.size();
    }
    CHECK(extract_widths_.top() % 8 == 0) << ": Bad extraction in " << *prim;
  }
  return false;
}

void ParseGraphConstraint::postorder(const IR::Tofino::ParserMatch *) {
  size_t num_new_bits = extract_widths_.top();
  extract_widths_.pop();
  num_new_bits -= extract_widths_.top();
  PHV::Bits old_bits(extracts_.cbegin(),
                     std::next(extracts_.cbegin(), extract_widths_.top()));
  PHV::Bits new_bits(std::next(extracts_.cbegin(), extract_widths_.top()),
                     extracts_.cend());
  CHECK(num_new_bits == new_bits.size()) << ": Size mismatch " << num_new_bits << " and " << new_bits.size();
  constraints_.SetParseConflict(old_bits, new_bits);
  extracts_.resize(extract_widths_.top());
}
