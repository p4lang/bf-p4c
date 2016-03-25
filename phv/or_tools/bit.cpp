#include "bit.h"
#include <constraint_solver/constraint_solver.h>

namespace ORTools {
using operations_research::IntVar;
void Bit::set_mau_group(IntVar *const mau_group,
                        const std::array<IntVar*, 3> &size_flags) {
  mau_group_ = mau_group;
  is_8b_ = size_flags[0];
  is_16b_ = size_flags[1];
  is_32b_ = size_flags[2];
}

void Bit::set_offset(IntVar *base_offset, const int &relative_offset) {
  base_offset_ = base_offset;
  relative_offset_ = relative_offset;
  if (0 == relative_offset) offset_ = base_offset_;
}

void Bit::CopyOffset(const Bit &bit) {
  CHECK(nullptr == base_offset_);
  CHECK(nullptr == offset_);
  base_offset_ = bit.base_offset();
  offset_ = bit.offset();
  relative_offset_ = bit.relative_offset();
  CHECK(nullptr != base_offset_);
  CHECK(nullptr != offset_);
}

void Bit::SetContainerWidthConstraints() {
  CHECK(nullptr != base_offset_);
  operations_research::Solver *solver = base_offset_->solver();
  for (int i = 0; i < relative_offset_; ++i) {
    base_offset_->RemoveValue(31 - i);
  }
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(is_8b(),
                      base_offset()->IsGreaterOrEqual(8 - relative_offset_)),
      1));
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(is_16b(),
                      base_offset()->IsGreaterOrEqual(16 - relative_offset_)),
      1));
}
}
