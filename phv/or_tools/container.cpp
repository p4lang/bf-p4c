#include "container.h"
#include "mau_group.h"
#include <base/logging.h>
#include <constraint_solver/constraint_solver.h>
namespace or_tools {
using operations_research::IntVar;
using operations_research::IntExpr;
using operations_research::Solver;
Container::Container(IntVar *cig) :
  container_in_group_(cig), container_(nullptr), deparser_group_(nullptr) { }

IntExpr *Container::deparser_group(const gress_t &thread) {
  if (nullptr == deparser_group_) {
    LOG2("Making deparser group flags for " << container_in_group_);
    Solver *solver = container_in_group_->solver();
    std::vector<IntVar*> flags;
    flags.reserve(PHV::kNumDeparserGroups);
    auto lt_flags = std::array<IntVar*, PHV::kMaxContainer>();
    for (auto boundaries : PHV::kDeparserGroups) {
      if (boundaries.at(0) < PHV::kTPhvContainerOffset ||
          true == mau_group()->is_t_phv()) {
        flags.push_back(
          MakeDeparserGroupFlags(boundaries, &lt_flags));
      }
    }
    deparser_group_ = solver->MakeSum(flags);
    // If the container is allocated to one of the "shared deparser groups", we
    // want to make sure that domain of byte->deparser_group_ does not overlap
    // for ingress and egress.
    if (thread == INGRESS) {
      std::vector<IntVar*> v;
      for (auto i : PHV::kSharedDeparserGroups) {
        v.push_back(solver->MakeIsEqualCstVar(deparser_group_, i));
      }
      deparser_group_ = solver->MakeSum(deparser_group_,
                          solver->MakeProd(solver->MakeSum(v),
                                           PHV::kNumDeparserGroups + 1));
    }
  }
  return deparser_group_;
}

void Container::set_mau_group(MauGroup *mg) {
  CHECK(nullptr != mg) << ": MAU group is null";
  CHECK((nullptr == mau_group_) || mg == mau_group_) <<
    ": Cannot rewrite MAU group" << mau_group_;
  if (nullptr == container_) {
    CHECK(nullptr == mau_group_) << ": Invalid MAU group for " <<
      container_in_group_;
    LOG2("Creating container from " << mg->mau_group() << " and " <<
           container_in_group_);
    Solver *s = container_in_group_->solver();
    container_ = s->MakeSum(s->MakeProd(mg->mau_group(),
                                        PHV::kNumContainersPerMauGroup),
                            container_in_group_);
  }
  mau_group_ = mg;
}

void Container::SetConflict(Container *c) {
  Solver *solver = container_in_group_->solver();
  CHECK(this != c) << ": Cannot set conflict between equal containers" <<
    container_in_group()->name();
  CHECK(container_in_group() != c->container_in_group()) <<
    ": Cannot set non-equality with " << container_in_group()->name();
  if (c->mau_group() == mau_group()) {
    solver->AddConstraint(
      solver->MakeNonEquality(container_in_group(), c->container_in_group()));
  }
  else {
    solver->AddConstraint(
      solver->MakeNonEquality(container(), c->container()));
  }
}

PHV::Container Container::Value() const {
  return PHV::Container(mau_group()->mau_group()->Value(),
                        container_in_group()->Value());
}

IntVar *
Container::MakeDeparserGroupFlags(const std::vector<int> &boundaries,
                                  std::array<IntVar*, PHV::kMaxContainer> *lt) {
  CHECK(1 == boundaries.size() || 3 == boundaries.size() ||
          5 == boundaries.size() || 7 == boundaries.size()) << ": Found " <<
    boundaries.size() << " elements in boundary vector";
  Solver *s = solver();
  bool is_lt = false;
  int expected_sum = 0;
  std::vector<IntVar*> cmp_flags;
  auto it = boundaries.begin();
  while (boundaries.end() != it) {
    if (true == is_lt) {
      if (nullptr == lt->at(*it)) {
        lt->at(*it) = s->MakeIsLessCstVar(container_, *it);
      }
      cmp_flags.push_back(lt->at(*it));
    }
    else {
      ++expected_sum;
      cmp_flags.push_back(s->MakeIsGreaterOrEqualCstVar(container_, *it));
    }
    is_lt = (!is_lt);
    ++it;
  }
  IntExpr *sum = nullptr;
  if (cmp_flags.size() == 1) sum = cmp_flags.front();
  else sum = s->MakeSum(cmp_flags);
  return s->MakeIsEqualCstVar(sum, expected_sum);
}

operations_research::Solver *Container::solver() const {
  return container_in_group_->solver(); }
}
