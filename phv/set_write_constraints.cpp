#include "set_write_constraints.h"
#include "header_bits.h"
#include "header_bit.h"
#include "constraint_solver/constraint_solver.h"

bool
SetWriteConstraints::preorder(const IR::Primitive *primitive) {
  if (primitive->name == "set") {
    LOG2("Setting write constraint for " << primitive);
    auto dst = primitive->operands[0]->to<IR::HeaderSliceRef>();
    auto src = primitive->operands[1]->to<IR::HeaderSliceRef>();
    if (nullptr != src && nullptr != dst) {
      // Just print a warning. This should have been handled in an earlier pass.
      if (src->type->width_bits() != dst->type->width_bits()) {
        WARNING("Source and destination are different width: " << primitive);
      }
      int width_bits = std::min(src->type->width_bits(),
                                dst->type->width_bits());
      for (int i = 0; i < width_bits; ++i) {
        HeaderBit *dst_bit = header_bits_.get(dst->header_ref()->toString(),
                                              i + dst->lsb());
        HeaderBit *src_bit = header_bits_.get(src->header_ref()->toString(),
                                              i + src->lsb());
        CHECK(nullptr != dst_bit) << "Cannot find HeaderBit for " <<
          dst->header_ref() << "[" << i + dst->lsb() << "]";
        CHECK(nullptr != src_bit) << "Cannot find HeaderBit for " <<
          src->header_ref() << "[" << i + src->lsb() << "]";
        LOG2("Inserting dst-src pair " << dst_bit->container()->name() <<
               " and " << src_bit->container()->name());
        dst_src_pairs_.insert(std::make_pair(
                                std::make_tuple(dst_bit->container(),
                                                dst_bit->offset(),
                                                src_bit->container(),
                                                src_bit->offset()),
                                std::make_pair(dst_bit, src_bit)));
      }
    }
  }
  return false;
}

void
SetWriteConstraints::postorder(const IR::ActionFunction *) {
  // These 2 for-loops will iterate over every dst-src pair of bits used in
  // set() primitives in an action.
  for (auto it = dst_src_pairs_.begin(); it != dst_src_pairs_.end(); ++it) {
    for (auto it2 = std::next(it, 1); it2 != dst_src_pairs_.end(); ++it2) {
      SetConstraint(it->second.first, it->second.second, it2->second.first,
                    it2->second.second);
    }
  }
  dst_src_pairs_.clear();
}

void
SetWriteConstraints::SetConstraint(HeaderBit *dst1, HeaderBit *src1,
                                   HeaderBit *dst2, HeaderBit *src2) {
  operations_research::Solver *solver = header_bits_.solver();
  // This if-elseif-else block handles 4 cases:
  // 1. We know that the two destination bits are in the same container.
  // 2. We know that the two destination bits are in different containers.
  // 3. We know that the two source bits are in different containers.
  // 4. The destination containers may be same or different.
  if (header_bits_.IsEqual(dst1->container(), dst2->container())) {
    // Just a sanity check. This should have been done by the
    // SetEqualDstContainerConstraint class.
    CHECK(header_bits_.IsEqual(src1->container(), src2->container()));
    // Make the difference in offsets equal.
    if (header_bits_.IsEqual(dst1->base_offset(), dst2->base_offset())) {
      if (header_bits_.IsEqual(src1->base_offset(), src2->base_offset())) {
        CHECK((dst1->relative_offset() - dst2->relative_offset()) ==
                (src1->relative_offset() - src2->relative_offset()));
      }
      else {
        int dst_relative_offset_diff = (dst1->relative_offset() -
                                        dst2->relative_offset());
        solver->AddConstraint(
          solver->MakeEquality(
            solver->MakeDifference(src1->offset(), src2->offset()),
            dst_relative_offset_diff));
      }
    }
    else {
      if (header_bits_.IsEqual(src1->base_offset(), src2->base_offset())) {
        int src_relative_offset_diff = (src1->relative_offset() -
                                        src2->relative_offset());
        solver->AddConstraint(
          solver->MakeEquality(
            solver->MakeDifference(dst1->offset(), dst2->offset()),
            src_relative_offset_diff));
      }
      else {
        solver->AddConstraint(
              solver->MakeEquality(
                solver->MakeDifference(dst1->offset(), dst2->offset()),
                solver->MakeDifference(src1->offset(), src2->offset())));
      }
    }

  }
  else if (header_bits_.IsNonEqual(dst1->container(), dst2->container())) {
    LOG1("Destination containers " << dst1->container()->name() << " and " <<
           dst2->container()->name() << " are non-equal");
  }
  else if (header_bits_.IsNonEqual(src1->container(), src2->container())) {
    LOG1("Source containers " << src1->container()->name() << " and " <<
           src2->container()->name() << " are non-equal");
    // Case 3: Make the destination containers non-equal.
    header_bits_.SetNonEqualityConstraint(dst1->container(), dst2->container());
  }
  else {
    LOG1("Setting conditional inequality for write between " <<
           dst1->container()->name() << " and " << dst2->container()->name());
    auto is_diff_dst_container = solver->MakeIsDifferentVar(dst1->container(),
                                                            dst2->container());
    // If dst containers are equal, make source containers the equal.
    solver->AddConstraint(
      solver->MakeNonEquality(
        solver->MakeSum(is_diff_dst_container,
                        solver->MakeIsEqualVar(src1->container(),
                                               src2->container())),
        0));
    // FIXME: Offsets need to match when destination containers are equal.
  }
}

void
SetEqualDstContainerConstraint::SetConstraint(
  HeaderBit *dst1, HeaderBit *src1, HeaderBit *dst2, HeaderBit *src2) {
  if (header_bits_.IsEqual(dst1->container(), dst2->container())) {
    if (false == header_bits_.IsEqual(src1->container(), src2->container())) {
      LOG1("Setting equality for write constraint between " <<
             dst1->container()->name() << " and " << dst2->container()->name());
      header_bits_.SetEqualityConstraint(src1->container(), src2->container());
      header_bits_.SetEqualityConstraint(src1->group(), src2->group());
      header_bits_.SetEqualityConstraint(src1->container_in_group(),
                                         src2->container_in_group());
      is_updated_ = true;
    }
  }
}
