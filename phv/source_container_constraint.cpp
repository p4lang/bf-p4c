#include "source_container_constraint.h"
#include "constraints.h"
#include <base/logging.h>
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
        // The distance between the source bits and destination bits must be
        // equal.
        bool is_valid;
        int distance;
        std::tie(distance, is_valid) = constraints_.GetDistance(it->first,
                                                                it2->first);
        CHECK(true == is_valid) << ": Unknown distance between " << it->first <<
          " and " << it2->first;
        constraints_.SetDistance(it->second, it2->second, distance);
        is_updated_ = true;
      }
    }
  }
  dst_src_pairs_.clear();
}
