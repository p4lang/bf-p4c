#include "byte_constraint.h"
#include "constraints.h"
#include "ir/ir.h"
#include <base/logging.h>

bool ByteConstraint::preorder(const IR::Primitive *prim) {
  if ("emit" == prim->name) {
    LOG2("Adding byte/deparser constraints for " << (*prim));
    const IR::Tofino::Deparser *deparser = findContext<IR::Tofino::Deparser>();
    CHECK(nullptr != deparser) << "; Cannot find context for " << (*prim);
    const gress_t gress = deparser->gress;
    auto bytes(GetBytes(prim->operands[0], nullptr));
    CHECK(false == bytes.empty()) << "; Cannot find bytes in " << (*prim);
    constraints_.SetEqualByte(bytes.begin(), bytes.end());
    constraints_.SetDeparsedHeader(bytes.begin(), bytes.end(), gress);
  }
  else if ("extract" == prim->name) {
    // FIXME: When extract primitive has been changed to
    // extract(IR::HeaderSliceRef*) where the HeaderSliceRef object points to
    // the whole header, uncomment the code below.
    // auto bytes(GetBytes(prim->operands[0], nullptr));
    // constraints_.SetEqualByte(bytes.begin(), bytes.end());
  }
  else if (prim->name == "set_metadata") {
    auto bytes(GetBytes(prim->operands[0], prim->operands[1]));
    constraints_.SetEqualByte(bytes.begin(), bytes.end());
  }
  return false;
}

bool ByteConstraint::preorder(const IR::Tofino::Deparser *dp) {
  std::list<PHV::Bit> bits = GetBits(dp->egress_port);
  constraints_.SetOffset(*bits.begin(), 0, 7);
  constraints_.SetContiguousBits(PHV::Bits(bits.begin(), bits.end()));
  return true;
}
