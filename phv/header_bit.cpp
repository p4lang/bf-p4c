#include "header_bit.h"
#include "phv.h"
#include "lib/log.h"
#include "constraint_solver/constraint_solver.h"
using namespace operations_research;

template<class T> T HeaderBit::container() const {
  return container_;
}
template<> int HeaderBit::container<int>() const {
  return (mau_group_->Value() * PHV::kNumContainersPerMauGroup +
          container_in_group_->Value());
}
template operations_research::IntExpr *HeaderBit::container() const;
template int HeaderBit::container() const;

void
HeaderBit::set_container(operations_research::IntVar *const container_in_group,
                         operations_research::IntExpr *const container) {
  LOG2("Setting container " << container_in_group->name() << " for " << name());
  CHECK(nullptr == container_in_group_) <<
    "; Reassigning container in group for " << name();
  container_in_group_ = container_in_group;
  CHECK(nullptr == container_) << "; Reassigning container for " << name();
  container_ = container;
}

void
HeaderBit::set_offset(operations_research::IntVar *const base_offset,
                      const int &relative_offset,
                      operations_research::Solver *solver) {
  CHECK(relative_offset < 8);
  LOG1("Setting base offset to " << base_offset->name() << " for " << name());
  base_offset_ = base_offset;
  relative_offset_ = relative_offset;
  if (0 == relative_offset) {
    offset_ = base_offset_;
  }
  else {
    offset_ = solver->MakeSum(base_offset_, relative_offset);
  }
  byte_offset_flags_[0] = solver->MakeIsLessCstVar(offset_, 8);
  byte_offset_flags_[3] = solver->MakeIsGreaterOrEqualCstVar(offset_, 24);
  byte_offset_flags_[1] = solver->MakeIsEqualCstVar(
                            solver->MakeSum(
                              solver->MakeIsLessCstVar(offset_, 16),
                              solver->MakeIsLessCstVar(offset_, 8)),
                            1);
  byte_offset_flags_[2] = solver->MakeIsEqualCstVar(
                            solver->MakeSum(
                              solver->MakeIsLessCstVar(offset_, 24),
                              solver->MakeIsLessCstVar(offset_, 16)),
                            1);
  byte_ = solver->MakeSum(
            solver->MakeProd(container_, 4),
            solver->MakeScalProd(std::vector<operations_research::IntVar*>(
                                   byte_offset_flags_.begin(),
                                   byte_offset_flags_.end()),
                                 std::vector<int>({{ 0, 1, 2, 3 }})));
}

void
HeaderBit::set_offset(const HeaderBit &prev_bit,
                      const int &relative_offset,
                      operations_research::Solver &solver) {
  CHECK(nullptr == base_offset_) << "; Reassigning base offset for " << name();
  base_offset_ = prev_bit.base_offset();
  byte_ = prev_bit.byte();
  byte_offset_flags_ = prev_bit.byte_offset_flags();
  relative_offset_ = prev_bit.relative_offset() + relative_offset;
  offset_ = solver.MakeSum(base_offset_, relative_offset_);
  CHECK(nullptr != container_);
}

void HeaderBit::CopyMauGroup(const HeaderBit *header_bit) {
  mau_group_ = header_bit->mau_group_;
  is_8b_ = header_bit->is_8b_;
  is_16b_ = header_bit->is_16b_;
  is_32b_ = header_bit->is_32b_;
}

void HeaderBit::CopyContainer(const HeaderBit *header_bit) {
  LOG2("Copying " << header_bit->name() << " to " << name());
  CopyMauGroup(header_bit);
  set_container(header_bit->container_in_group(), header_bit->container());
//offset_ = header_bit->offset_;
//base_offset_ = header_bit->base_offset_;
//relative_offset_ = header_bit->relative_offset_;
//is_last_byte_ = header_bit->is_last_byte_;
//is_first_byte_ = header_bit->is_first_byte_;
}

void HeaderBit::SetGroupFlag(Solver &s, const std::vector<int> &groups,
                             operations_research::IntVar *v) const {
  // This function sets constraints between is_8b or is_16b or is_32b and the
  // mau_group_ variable.
  std::vector<IntVar *> is_equal_vars;
  for (auto it = groups.begin(); it != groups.end(); ++it) {
    is_equal_vars.push_back(mau_group_->IsEqual(*it));
  }
  s.AddConstraint(s.MakeEquality(s.MakeSum(is_equal_vars), v));
}

void
HeaderBit::SetContainerWidthConstraints(Solver &solver) const {
  SetGroupFlag(solver, PHV::k8bMauGroups, is_8b());
  SetGroupFlag(solver, PHV::k16bMauGroups, is_16b());
  SetGroupFlag(solver, PHV::k32bMauGroups, is_32b());
  for (int i = 0; i < relative_offset_; ++i) {
    base_offset_->RemoveValue(31 - i);
  }
  solver.AddConstraint(
    solver.MakeLessOrEqual(
      solver.MakeSum(is_8b(),
                     base_offset()->IsGreaterOrEqual(8 - relative_offset_)),
      1));
  solver.AddConstraint(
    solver.MakeLessOrEqual(
      solver.MakeSum(is_16b(),
                     base_offset()->IsGreaterOrEqual(16 - relative_offset_)),
      1));
  solver.AddConstraint(
    solver.MakeLessOrEqual(base_offset(), 31 - relative_offset_));
  std::vector<operations_research::IntVar*> is_xb_vars({is_8b(), is_16b(),
                                                        is_32b()});
  solver.AddConstraint(solver.MakeSumEquality(is_xb_vars, 1));
}

void
HeaderBit::SetLastDeparsedHeaderByteConstraint(operations_research::Solver &solver) {
  // For the last bit of a header, is_last_byte_ must be true.
  solver.AddConstraint(solver.MakeEquality(is_last_byte(), 1));
}

void
HeaderBit::SetDeparserConstraints(const HeaderBit *prev_bit,
                                  const gress_t &gress,
                                  Solver &solver) {
  LOG2("Setting deparser constraints for " << name());
  // The first PHV 32 containers of each width are tied to a particular thread.
  if (gress == INGRESS) {
    mau_group_->RemoveValues({{ 1, 5, 9}});
  }
  else if (gress == EGRESS) {
    mau_group_->RemoveValues({{ 0, 4, 8}});
  }
  else {
    CHECK(false) << "; Invalid thread " << cstring::to_cstring(gress);
  }
  // This block of code sets the constraints for is_last_byte_.
  auto last_byte_16b = solver.MakeIsEqualVar(
                         is_16b_, solver.MakeDifference(
                                    solver.MakeIntConst(9), base_offset()));
  auto last_byte_32b = solver.MakeIsEqualVar(
                         is_32b_, solver.MakeDifference(
                                    solver.MakeIntConst(25), base_offset()));
  std::vector<IntVar*> last_bytes({is_8b_, last_byte_16b, last_byte_32b});
  auto last_byte_expr = solver.MakeSum(last_bytes);
  is_last_byte_ = solver.MakeIsEqualVar(last_byte_expr, solver.MakeIntConst(1));
  if (nullptr != prev_bit) {
    CHECK(nullptr != prev_bit->offset());
    CHECK((prev_bit->base_offset() != base_offset() &&
           relative_offset() == 0) ||
          (prev_bit->relative_offset() + 1 == relative_offset())) <<
      "; Incompatible offsets for " << prev_bit->name() << " and " << name();
    // FIXME: The below code is run for every bit in the header slice. However,
    // it can probably be executed for every 8th bit since the 8 bits will
    // share the same byte in a container.
    // For a deparsed bit, either is_first_byte_ is true or this bit must be
    // allocated to the byte following the previous bit's byte.
    is_first_byte_ = solver.MakeIsDifferentVar(
                       solver.MakeSum(
                         solver.MakeIsEqualVar(
                           container(), prev_bit->container()),
                         solver.MakeIsEqualVar(
                           base_offset(),
                           solver.MakeSum(prev_bit->base_offset(), 8))),
                       solver.MakeIntConst(2));
    // Either is_first_byte_ or previous_byte_->is_last_byte() must be 1.
    solver.AddConstraint(
      solver.MakeEquality(is_first_byte_, prev_bit->is_last_byte()));
    // Either previous_byte_->is_last_byte_ or base_offset_ must be non 0.
    solver.AddConstraint(
      solver.MakeEquality(
        solver.MakeSum(prev_bit->is_last_byte(),
                       solver.MakeIsDifferentCstVar(base_offset(), 0)), 1));
    // This constraint makes the assumption that the base_offset_ for bits in
    // the header slice is allocated in groups of 8.
    solver.AddConstraint(
      solver.MakeEquality(is_first_byte_,
                          base_offset()->IsEqual(0)));
  }
  else {
    // This is the first bit of the header slice in the emit primitive. It must
    // be at the first byte in the container.
    base_offset_->RemoveValues({8, 16, 24});
    is_first_byte_ = solver.MakeIntConst(1);
  }
}
