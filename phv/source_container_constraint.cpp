#include <base/logging.h>
#include "source_container_constraint.h"
#include "constraints.h"

bool SourceContainerConstraint::preorder(const IR::Primitive *primitive) {
  if (primitive->name == "set") {
    PhvInfo::Field::bitrange dst_bits, src_bits;
    auto dst = phv.field(primitive->operands[0], &dst_bits);
    auto src = phv.field(primitive->operands[1], &src_bits);
    if (src && dst) {
      // Just print a warning. This should have been handled in an earlier pass.
      if (src_bits.size() != dst_bits.size()) {
        WARNING("Source and destination are different width: " << primitive);
      }
      int width_bits = std::min(src_bits.size(), dst_bits.size());
      LOG2("Setting write constraint for " << primitive);
      for (int i = 0; i < width_bits; ++i) {
        dst_src_pairs_.emplace(dst->bit(i + dst_bits.lo), src->bit(i + src_bits.lo));
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
      // Note that when is_equal() returns false, it means that the two bits
      // may or may not be in the same container.
      auto is_equal = std::bind(&Constraints::IsEqual, &constraints_, _1, _2,
                                Constraints::CONTAINER);
      // For every pair of source-destination pairs, we need to handle 3 cases:
      // Case 1. Both destinations must be allocated to the same PHV container.
      // In this case is_equal(dst1, dst2) is true. Both sources must go into
      // same container.
      if ((true == is_equal(it->first, it2->first)) &&
          (false == is_equal(it->second, it2->second))) {
        LOG2("Setting sources " << it->second << " and " << it2->second <<
               " equal in " << af->name);
        constraints_.SetEqual(it->second, it2->second, Constraints::CONTAINER);
        // The distance between the source bits and destination bits must be
        // equal.
        bool is_valid;
        int dst_dist, src_dist;
        std::tie(dst_dist, is_valid) = constraints_.GetDistance(it->first,
                                                                it2->first);
        CHECK(true == is_valid) << ": Unknown distance between " << it->first <<
          " and " << it2->first;
        std::tie(src_dist, is_valid) = constraints_.GetDistance(it->second,
                                                                it2->second);
        if (true == is_valid) {
          // FIXME: This must be changed into a compiler error message.
          CHECK(src_dist == dst_dist) << ": Conflicting write constraints";
        }
        is_updated_ = true;
      }
      // Case 2. Destinations must be allocated to different containers. This is
      // usually because there is a container conflict between the two sources.
      // IsContainerConflict(src1, src2) is true. Now, both destinations must
      // go into different containers.
      if ((true == constraints_.IsContainerConflict(it->second, it2->second)) &&
          (false == constraints_.IsContainerConflict(it->first, it2->first))) {
        // FIXME: The assertion below fails if the source containers must be
        // unequal and the destination containers must be equal. This violates
        // single write constraint. This must be changed into a compiler error
        // message.
        CHECK(false == is_equal(it->first, it2->first)) <<
          ": Different distination containers for " << it->second << " and " <<
          it2->second << " in " << (*af);
        LOG2("Setting destination container conflict for " << it->first <<
               " and " << it2->first);
        constraints_.SetContainerConflict(it->first, it2->first);
        is_updated_ = true;
      }
      // Case 3. The sources and destinations may or may not be in same PHV
      // container. Under this case, is_equal(dst1, dst2) is false and
      // IsContainerConflict(src1, src2) is false. We need to add a conditional
      // constraint: If dst1 and dst2 got into same container, src1 and src2
      // must be in same container. Also:
      // offset of dst1 - offset of src1 == offset of dst2 - offset of src2.
      // This case must be handled in the solver.
      // For now, just store this source-destination pair in the constraints
      // object.
    }
    constraints_.SetDstSrcPair(af->name, *it);
  }
  dst_src_pairs_.clear();
}
