#include "solver.h"
#include "lib/log.h"
namespace ORTools {
int Solver::unique_id_ = 0;

using operations_research::IntVar;
using operations_research::IntExpr;
void Solver::SetEqualMauGroup(const std::set<PHV::Bit> &bits) {
  CHECK(bits.size() > 0) << "; Received empty set";
  std::array<IntVar*, 3> size_flags;
  IntVar *group = MakeMauGroup(bits.begin()->name(), &size_flags);
  for (auto &b : bits) {
    if (bits_.count(b) == 0) bits_.insert(std::make_pair(b, Bit(b.name())));
    Bit &bit = bits_.find(b)->second;
    CHECK(bit.mau_group() == nullptr);
    LOG2("Setting group for " << bit.name() << " to " << group->name());
    bit.set_mau_group(group, size_flags);
  }
}

void Solver::SetEqualContainer(const std::set<PHV::Bit> &bits) {
  IntVar *mau_group = bits_.at(*bits.begin()).mau_group();
  IntVar *container_in_group = MakeContainerInGroup(bits.begin()->name());
  IntExpr *container = MakeContainer(mau_group, container_in_group);
  for (auto &b : bits) {
    Bit &bit = bits_.at(b);
    CHECK(bit.mau_group() == mau_group);
    LOG2("Setting container in group for " << bit.name() << " to " <<
         container_in_group->name());
    bit.set_container(container_in_group, container);
  }
}

void Solver::SetByte(const PHV::Byte &byte) {
  IntVar *base_offset = MakeByteAlignedOffset(byte.cfirst()->name());
  for (auto it = byte.cfirst(); it != byte.clast(); ++it) {
    Bit &bit = bits_.at(*it);
    CHECK(nullptr != bit.container());
    const int relative_offset = std::distance(byte.cbegin(), it);
    bit.set_offset(base_offset, relative_offset);
  }
}

void Solver::SetEqualOffset(const std::set<PHV::Bit> &bits) {
  Bit base_bit("");
  for (auto &b : bits) {
    Bit &bit = bits_.at(b);
    if (nullptr != bit.offset()) {
      base_bit.CopyOffset(bit);
      break;
    }
  }
  if (nullptr == base_bit.offset()) {
    base_bit.set_offset(MakeOffset(bits.begin()->name()), 0);
  }
  CHECK(nullptr != base_bit.offset());
  for (auto &b : bits) {
    Bit &bit = bits_.at(b);
    if (nullptr == bit.offset()) {
      CHECK(nullptr == bit.base_offset());
      bit.CopyOffset(base_bit);
    }
    else {
      solver_.AddConstraint(
        solver_.MakeEquality(base_bit.offset(), bit.offset()));
    }
  }
}

void Solver::SetContainerWidthConstraints() {
  std::map<std::pair<IntVar*, IntVar*>, Bit*> mau_group_offsets;
  for (auto &b : bits_) {
    Bit &bit = b.second;
    auto p = std::make_pair(bit.mau_group(), bit.base_offset());
    if (mau_group_offsets.count(p) == 0) {
      mau_group_offsets.insert(std::make_pair(p, &bit));
    }
    if (mau_group_offsets.at(p)->relative_offset() < bit.relative_offset()) {
      mau_group_offsets.at(p) = &bit;
    }
  }
  for (auto &p : mau_group_offsets) {
    p.second->SetContainerWidthConstraints();
  }
}

void Solver::allocation(const PHV::Bit &bit, PHV::Container *container,
                        int *container_bit) {
  (*container) = PHV::Container(0, 0);
  (*container_bit) = 0;
  if (0 != bits_.count(bit)) {
    const Bit &b(bits_.at(bit));
    if ((nullptr != b.mau_group()) && (nullptr != b.container_in_group()))
      (*container) = PHV::Container(b.mau_group()->Value(),
                                    b.container_in_group()->Value());
    if (nullptr != b.base_offset())
      (*container_bit) = b.base_offset()->Value() + b.relative_offset();
  }
}

bool Solver::Solve1(operations_research::Solver::IntValueStrategy int_val) {
  auto int_vars = GetIntVars();
  auto db = solver_.MakePhase(int_vars,
                              operations_research::Solver::CHOOSE_FIRST_UNBOUND,
                              int_val);
  solver_.NewSearch(db, solver_.MakeLubyRestart(1000),
                    solver_.MakeTimeLimit(120000));
  return solver_.NextSolution();
}

std::vector<IntVar*> Solver::GetIntVars() const {
  std::vector<IntVar*> rv;
  // Collect constraint variables.
  std::vector<IntVar*> group_vars(mau_groups());
  std::random_shuffle(group_vars.begin(), group_vars.end());
  while (group_vars.size() != 0) {
    rv.push_back(*group_vars.begin());
    auto vars2 = containers_and_offsets(*group_vars.begin());
    rv.insert(rv.end(), vars2.begin(), vars2.end());
    group_vars.erase(group_vars.begin());
  }
  for (auto &v : rv) {
    CHECK(nullptr != v) << "; Found nullptr in variable vector";
    LOG2("intvar vec: " << v->name());
  }
  return rv;
}

std::vector<IntVar*> Solver::mau_groups() const {
  std::set<IntVar*> rv;
  for (auto &b : bits_) {
    rv.insert(b.second.mau_group());
  }
  return std::vector<IntVar*>(rv.begin(), rv.end());
}

std::vector<IntVar*>
Solver::containers_and_offsets(IntVar *mau_group) const {
  std::set<IntVar*> container_in_groups;
  for (auto &b : bits_) {
    if (b.second.mau_group() == mau_group) {
      container_in_groups.insert(b.second.container_in_group());
    }
  }
  container_in_groups.erase(nullptr);
  std::vector<IntVar*> rv;
  while (false == container_in_groups.empty()) {
    auto c = container_in_groups.begin();
    rv.push_back(*c);
    for (auto &b : bits_) {
      if (b.second.container_in_group() == *c &&
          b.second.base_offset() != nullptr) {
        rv.push_back(b.second.base_offset());
      }
    }
    container_in_groups.erase(c);
  }
  return rv;
}

IntVar *
Solver::MakeMauGroup(const cstring &name, std::array<IntVar*, 3> *flags) {
  auto v = solver_.MakeIntVar(0, PHV::kNumMauGroups - 1,
                              name + "-group-" + std::to_string(unique_id()));
  v->RemoveValues(std::vector<int64>(PHV::kInvalidMauGroups.begin(),
                                     PHV::kInvalidMauGroups.begin()));
  std::array<const std::vector<int>, 3> mau_groups =
    {{PHV::k8bMauGroups, PHV::k16bMauGroups, PHV::k32bMauGroups}};
  for (decltype(flags->size()) i = 0; i < flags->size(); ++i) {
    (*flags)[i] = GetWidthFlag(v, mau_groups[i]);
  }
  return v;
}

IntVar *
Solver::GetWidthFlag(IntVar *mau_group, const std::vector<int> &groups) {
  // This function sets constraints between is_8b or is_16b or is_32b and the
  // mau_group_ variable.
  std::vector<IntVar *> is_equal_vars;
  for (auto it = groups.begin(); it != groups.end(); ++it) {
    is_equal_vars.push_back(mau_group->IsEqual(*it));
  }
  return solver_.MakeSum(is_equal_vars)->Var();
}

IntVar *Solver::MakeContainerInGroup(const cstring &name) {
  auto uid = std::to_string(unique_id());
  return solver_.MakeIntVar(0, PHV::kNumContainersPerMauGroup - 1,
                            name + "-containeringroup-" + uid);
}

IntExpr *Solver::MakeContainer(IntVar *group, IntVar *container_in_group) {
  return solver_.MakeSum(solver_.MakeProd(group,
                                          PHV::kNumContainersPerMauGroup),
                         container_in_group);
}

IntVar *Solver::MakeByteAlignedOffset(const cstring &name) {
  // FIXME: For some reason, no name is being assigned to IntVar objects
  // created below.
  return solver_.MakeIntVar(std::vector<int>({0, 8, 16, 24}),
                            name + "-ba-offset-" + std::to_string(unique_id()));
}

IntVar *Solver::MakeOffset(const cstring &name) {
  return solver_.MakeIntVar(0, 31,
                            name + "-offset-" + std::to_string(unique_id()));
}
}
