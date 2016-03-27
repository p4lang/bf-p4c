#include "bit.h"
#include "lib/log.h"
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

void Bit::set_container(operations_research::IntVar *const container_in_group,
                        operations_research::IntExpr *const container) {
  LOG2("Setting container for " << name() << " to " << container_in_group);
  CHECK(nullptr == container_in_group_) <<
    "; Cannot reassign container in group for " << name();
  CHECK(nullptr == container_) <<
    "; Cannot reassign container for " << name();
  CHECK(nullptr != container_in_group) <<
    "; Invalid container in group for " << name();
  CHECK(nullptr != container) <<
    "; Invalid container in group for " << name();
  container_in_group_ = container_in_group;
  container_ = container;
}

void Bit::set_offset(IntVar *base_offset, const int &relative_offset) {
  LOG2("Setting offset for " << name());
  base_offset_ = base_offset;
  relative_offset_ = relative_offset;
  if (0 == relative_offset) offset_ = base_offset_;
  else {
    offset_ = base_offset->solver()->MakeSum(base_offset,
                                             (int64)relative_offset);
  }
}

void Bit::CopyOffset(const Bit &bit) {
  LOG2("Copying offset from " << bit.name() << " to " << name());
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

void Bit::SetFirstDeparsedHeaderByte(const std::array<Bit *, 8> &byte) {
  LOG2("Setting first deparsed byte for " << name());
  auto solver = base_offset_->solver();
  solver->AddConstraint(solver->MakeEquality(base_offset(), 0));
  is_last_byte_ = is_8b_;
  CHECK(nullptr != is_last_byte_);
  for (auto &b : byte) b->is_last_byte_ = is_last_byte_;
}

void Bit::SetDeparsedHeader(const Bit &prev_bit,
                            const std::array<Bit *, 8> &byte) {
  auto solver = base_offset_->solver();
  operations_research::IntExpr *is_next_byte =
    solver->MakeIsDifferentVar(
      solver->MakeSum(
        solver->MakeIsEqualVar(container(), prev_bit.container()),
        solver->MakeIsEqualVar(base_offset(),
                               solver->MakeSum(prev_bit.base_offset(), 8))),
      solver->MakeIntConst(2));
  // is_next_byte and prev_bit.is_last_byte() must be equal.
  solver->AddConstraint(
    solver->MakeEquality(is_next_byte, prev_bit.is_last_byte()));
  // Either prev_bit_->is_last_byte_ or base_offset_ must be non 0.
  solver->AddConstraint(
    solver->MakeEquality(
      solver->MakeSum(prev_bit.is_last_byte(),
                      solver->MakeIsDifferentCstVar(base_offset(), 0)), 1));
  // This block of code sets the constraints for is_last_byte_.
  auto last_byte_16b = solver->MakeIsEqualVar(
                         is_16b_, solver->MakeDifference(
                                    solver->MakeIntConst(9), base_offset()));
  auto last_byte_32b = solver->MakeIsEqualVar(
                         is_32b_, solver->MakeDifference(
                                    solver->MakeIntConst(25), base_offset()));
  std::vector<IntVar*> last_bytes({is_8b_, last_byte_16b, last_byte_32b});
  is_last_byte_ = solver->MakeIsEqualVar(solver->MakeSum(last_bytes),
                                         solver->MakeIntConst(1));
  for (auto &b : byte) b->is_last_byte_ = is_last_byte_;
}
}
