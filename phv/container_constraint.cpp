#include "container_constraint.h"
#include "constraints.h"
bool ContainerConstraint::preorder(const IR::Primitive *prim) {
  // FIXME: This should include the extract instruction too. But extract() has
  // to be fixed in the IR.
  if (prim->name == "emit") {
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

bool SourceContainerConstraint::preorder(const IR::Primitive *primitive) {
  if (primitive->name == "set") {
    auto dst = primitive->operands[0]->to<IR::HeaderSliceRef>();
    auto src = primitive->operands[1]->to<IR::HeaderSliceRef>();
    if (nullptr != src && nullptr != dst) {
      // Just print a warning. This should have been handled in an earlier pass.
      if (src->type->width_bits() != dst->type->width_bits()) {
        WARNING("Source and destination are different width: " << primitive);
      }
      int width_bits = std::min(src->type->width_bits(),
                                dst->type->width_bits());
      LOG2("Setting write constraint for " << primitive);
      for (int i = 0; i < width_bits; ++i) {
        PHV::Bit src_bit(src->header_ref()->toString(), src->offset_bits() + i);
        PHV::Bit dst_bit(dst->header_ref()->toString(), dst->offset_bits() + i);
        dst_src_pairs_.insert(std::make_pair(dst_bit, src_bit));
      }
    }
  }
  return false;
}

void SourceContainerConstraint::postorder(const IR::ActionFunction *af) {
  using namespace std::placeholders;
  // These 2 for-loops will iterate over every dst-src pair of bits used in
  // set() primitives in an action.
  for (auto it = dst_src_pairs_.begin(); it != dst_src_pairs_.end(); ++it) {
    for (auto it2 = dst_src_pairs_.begin(); it2 != it; ++it2) {
      auto is_equal = std::bind(&Constraints::IsEqual, &constraints_, _1, _2,
                                Constraints::CONTAINER);
      if ((true == is_equal(it->first, it2->first)) &&
          (false == is_equal(it->second, it2->second))) {
        LOG2("Setting sources " << it->second << " and " << it2->second <<
               " equal in " << af->name);
        constraints_.SetEqual(it->second, it2->second, Constraints::CONTAINER);
        is_updated_ = true;
      }
    }
  }
  dst_src_pairs_.clear();
}
