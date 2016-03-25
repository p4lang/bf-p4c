#include "byte_constraint.h"
#include "constraints.h"
#include "ir/ir.h"
#include <base/logging.h>

bool ByteConstraint::preorder(const IR::Primitive *prim) {
  if ("emit" == prim->name) {
    auto bytes(GetBytes(prim->operands[0], nullptr));
    equality_constraints_.SetEqualByte(bytes.begin(), bytes.end());
  }
  if (prim->name == "set_metadata") {
    auto bytes(GetBytes(prim->operands[0], prim->operands[1]));
    equality_constraints_.SetEqualByte(bytes.begin(), bytes.end());
  }
  return false;
}
//  const IR::HeaderSliceRef *hsr = nullptr;
//  int offset = 0;
//  if (prim->name == "extract" || prim->name == "emit") {
//    CHECK(prim->operands.size() == 1) << "; Illegal parameters in " <<
//      prim->toString();
//    hsr = prim->operands[0]->to<const IR::HeaderSliceRef>();
//    CHECK(nullptr != hsr) << "; Invalid operand for " << prim->toString();
//    CHECK(0 == (hsr->type->width_bits() % 8)) <<
//      "; Cannot emit header of width " << hsr->type->width_bits();
//  }
//  else if (prim->name == "set_metadata") {
//    CHECK(prim->operands.size() == 2 || prim->operands.size() == 1) <<
//      "; Invalid operands for " << prim->toString();
//    hsr = prim->operands[0]->to<const IR::HeaderSliceRef>();
//    auto src_hsr = prim->operands[1]->to<const IR::HeaderSliceRef>();
//    if (nullptr != src_hsr) offset = (src_hsr->offset_bits() % 8);
//    // FIXME: This just handles the case where the destination of
//    // set_metadata needs the same byte-alignment as the source packet
//    // field. However, if a constant is written to a metadata, there is no
//    // constraint on alignment. That is not handled here.
//    else LOG1("Skipping " << prim);
//  }
//  if (nullptr != hsr) {
//    for (int i = hsr->lsb(); i <= hsr->msb(); offset = 0) {
//      int width = std::min(1 + hsr->msb() - i, 8 - offset);
//      PHV::Bit bit(hsr->header_ref()->toString(), i);
//      if (StoreOffsets(bit, width, offset)) {
//        LOG1("Enforcing byte constraint on " << bit);
//        CHECK(offset < 8) << "; Invalid offset " << offset <<
//          " for byte starting at " << bit;
//        CHECK(offset + width <= 8) << "; Invalid width " << width <<
//          " at offset " << offset << " for byte starting at " << bit;
//        EnforceConstraint(bit, width, offset);
//      }
//      eq_constraints_.SetEqualByte(bit, width);
//      i += (8 - offset);
//    }
//  }
//  return false;
//}
