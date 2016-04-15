#include <constraint_solver/constraint_solver.h>
#include "bit.h"
#include "byte.h"
#include "container.h"
#include "mau_group.h"
#include "lib/log.h"

namespace or_tools {
using operations_research::IntVar;
using operations_research::IntExpr;

void Bit::set_container(Container *container) {
  LOG2("Setting container object for " << name());
  CHECK(nullptr == container_) <<
    ": Cannot reassign container for " << name();
  CHECK(nullptr != container) <<
    ": Invalid container in group for " << name();
  container_ = container;
}

MauGroup *Bit::mau_group() const { return container()->mau_group(); }

void Bit::set_offset(IntVar *base_offset, const int &relative_offset) {
  LOG2("Setting offset for " << name() << " to " << base_offset <<
         " with relative offset " << relative_offset);
  base_offset_ = base_offset;
  relative_offset_ = relative_offset;
  if (0 == relative_offset) {
    offset_ = base_offset_;
  } else {
    offset_ = base_offset->solver()->MakeSum(base_offset, static_cast<int64>(relative_offset));
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

IntExpr *Bit::offset_bytes() const {
  CHECK(nullptr != byte_);
  if (nullptr == byte_->offset()) {
    auto solver = base_offset_->solver();
    auto offset_bytes = solver->MakeSum(
                          std::vector<IntVar*>(
                            {{solver->MakeIsGreaterCstVar(offset_, 7),
                              solver->MakeIsGreaterCstVar(offset_, 15),
                              solver->MakeIsGreaterCstVar(offset_, 23)}}));
    byte_->set_offset(offset_bytes);
  }
  return byte_->offset();
}

std::array<IntVar *, 4> Bit::byte_flags() const {
  auto rv = byte()->flags();
  if (std::find(rv.cbegin(), rv.cend(), nullptr) != rv.end()) {
    auto solver = base_offset_->solver();
    rv[0] = solver->MakeIsLessCstVar(base_offset_, 8);
    rv[1] = solver->MakeIsEqualCstVar(
              solver->MakeSum(
                solver->MakeIsLessCstVar(base_offset_, 8),
                solver->MakeIsLessCstVar(base_offset_, 16)), 1);
    rv[2] = solver->MakeIsEqualCstVar(
              solver->MakeSum(
                solver->MakeIsLessCstVar(base_offset_, 16),
                solver->MakeIsLessCstVar(base_offset_, 24)), 1);
    rv[3] = solver->MakeIsGreaterOrEqualCstVar(base_offset_, 24);
    byte()->set_flags(rv);
  }
  return rv;
}

void Bit::SetContainerWidthConstraints() {
  CHECK(nullptr != base_offset_);
  operations_research::Solver *solver = base_offset_->solver();
  for (int i = 0; i < relative_offset_; ++i) {
    base_offset_->RemoveValue(31 - i);
  }
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(mau_group()->is_8b(),
                      base_offset()->IsGreaterOrEqual(8 - relative_offset_)),
      1));
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(mau_group()->is_16b(),
                      base_offset()->IsGreaterOrEqual(16 - relative_offset_)),
      1));
}

IntVar *Bit::SetFirstDeparsedHeaderByte() {
  LOG2("Setting first deparsed byte for " << name());
  auto solver = base_offset_->solver();
  solver->AddConstraint(solver->MakeEquality(base_offset(), 0));
  return mau_group()->is_8b();
}

IntVar *Bit::SetDeparsedHeader(const Bit &prev_bit, const Byte &prev_byte) {
  CHECK(nullptr != base_offset_) << ": No base offset for " << name();
  auto solver = base_offset_->solver();
  CHECK(nullptr != solver) << ": No solver for " << name();
  CHECK(nullptr != prev_bit.container()) << ": No previous container for " <<
    name();
  CHECK(nullptr != prev_bit.base_offset()) << ": No previous offset for " <<
    name();
  CHECK(nullptr != container()) << ": No container for " << name();
  CHECK(nullptr != container()->container()) << ": No container expr for " <<
    name();
  // is_next_byte is a misnomer. It should really be is_not_next_byte.
  operations_research::IntExpr *is_next_byte = nullptr;
  if (prev_bit.container() == container()) {
    is_next_byte = solver->MakeIntConst(0);
  } else {
    is_next_byte =
      solver->MakeIsDifferentVar(
        solver->MakeSum(
          solver->MakeIsEqualVar(container()->container(),
                                 prev_bit.container()->container()),
          solver->MakeIsEqualVar(base_offset_,
                                 solver->MakeSum(prev_bit.base_offset(), 8))),
        solver->MakeIntConst(2));
  }
  // is_next_byte and prev_byte.is_last_byte() must be equal.
  solver->AddConstraint(
    solver->MakeEquality(is_next_byte, prev_byte.is_last_byte()));
  // Either prev_bit->is_last_byte_ or base_offset_ must be non 0.
  solver->AddConstraint(
    solver->MakeEquality(
      solver->MakeSum(prev_byte.is_last_byte(),
                      solver->MakeIsDifferentCstVar(base_offset(), 0)), 1));
  // This block of code sets the constraints for byte->is_last_byte_.
  auto last_byte_16b = solver->MakeIsEqualVar(
                         mau_group()->is_16b(),
                         solver->MakeDifference(
                           solver->MakeIntConst(9), base_offset()));
  auto last_byte_32b = solver->MakeIsEqualVar(
                         mau_group()->is_32b(),
                         solver->MakeDifference(
                           solver->MakeIntConst(25), base_offset()));
  std::vector<IntVar*> last_bytes({mau_group()->is_8b(), last_byte_16b,
                                   last_byte_32b});

  return solver->MakeIsEqualVar(solver->MakeSum(last_bytes),
                                solver->MakeIntConst(1));
}

void Bit::SetConflict(Bit &bit) {
  operations_research::Solver *s = base_offset()->solver();
  CHECK(nullptr != s) << ": No solver for " << name();
  if (bit.container() != container()) {
    s->AddConstraint(s->MakeNonEquality(MakeBit(), bit.MakeBit()));
  } else if (bit.base_offset() == base_offset_) {
    CHECK(bit.relative_offset() != relative_offset()) <<
      ": Cannot add conflict between " << bit.name() << " and " << name();
  } else {
    s->AddConstraint(s->MakeNonEquality(offset(), bit.offset())); }
}

IntExpr *Bit::MakeBit() {
  if (nullptr == bit_) {
    operations_research::Solver *s = base_offset()->solver();
    bit_ = s->MakeSum(
             s->MakeProd(container_->container(), PHV::kMaxContainer), offset_);
  }
  return bit_;
}
}  // namespace or_tools
