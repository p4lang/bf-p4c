#include "header_bits.h"
#include "header_bit.h"
#include "phv.h"
#include "constraint_solver/constraint_solver.h"
#include <list>
#include <set>
int HeaderBits::unique_id_ = 0;

HeaderBits::~HeaderBits() {
  for (auto &item : bits_) {
    delete item.second;
  }
  bits_.clear();
}

void
HeaderBits::CreateHeader(const cstring &header_name, const int &width_bits) {
  LOG2("Creating " << width_bits << "b header named " << header_name);
  for (int i = 0; i < width_bits; ++i) {
    BitIdentifier id = std::make_pair(header_name, i);
    if (bits_.count(id) == 0) {
      bits_[id] = new HeaderBit(header_name + "[" + std::to_string(i) + "]");
    }
  }
}

HeaderBit *
HeaderBits::get(const cstring &header_name, const size_t &offset) const {
  BitIdentifier id = std::make_pair(header_name, offset);
  CHECK(bits_.count(id) != 0) << std::endl << "Cannot find " << header_name <<
    ":" << offset << " in bits_";
  CHECK(bits_.at(id) != nullptr);
  return bits_.at(id);
}

operations_research::IntVar *
HeaderBits::MakeGroupVar(const cstring &name,
                         std::array<operations_research::IntVar*, 3> *is_xb) {
  auto v = solver_->MakeIntVar(0, PHV::kNumMauGroups - 1,
                               name + "-group-" + std::to_string(unique_id()));
  v->RemoveValues(std::vector<int64>(PHV::kInvalidMauGroups.begin(),
                                     PHV::kInvalidMauGroups.begin()));
  for (decltype(is_xb->size()) i = 0; i < is_xb->size(); ++i) {
    (*is_xb)[i] = solver_->MakeBoolVar(name + "-" + std::to_string(8 << i) + "b");
  }
  return v;
}

operations_research::IntVar *
HeaderBits::MakeContainerInGroupVar(const cstring &name) {
  auto uid = std::to_string(unique_id());
  return solver_->MakeIntVar(0, PHV::kNumContainersPerMauGroup - 1,
                             name + "-containeringroup-" + uid);
}

operations_research::IntExpr *
HeaderBits::MakeContainerExpr(operations_research::IntVar *group,
                              operations_research::IntVar *container_in_group) {
  return solver_->MakeSum(solver_->MakeProd(group,
                                            PHV::kNumContainersPerMauGroup),
                          container_in_group);
}

operations_research::IntVar *
HeaderBits::MakeByteAlignedOffsetVar(const cstring &n) {
  // FIXME: For some reason, no name is being assigned to IntVar objects
  // created below.
  return solver_->MakeIntVar(std::vector<int>({0, 8, 16, 24}),
                             n + "-ba-offset-" + std::to_string(unique_id()));
}

operations_research::IntVar *HeaderBits::MakeOffsetVar(const cstring &n) {
  return solver_->MakeIntVar(0, 31,
                             n + "-offset-" + std::to_string(unique_id()));
}

operations_research::IntVar *
HeaderBits::MakeSum(operations_research::IntExpr *e, const int &i) {
  return solver_->MakeSum(e, i)->Var();
}

template<class T>
void
HeaderBits::SetEqualityConstraint(T v1, T v2) {
  CHECK(v1 != nullptr) << "; Received nullptr for setting constraint";
  CHECK(v2 != nullptr) << "; Received nullptr for setting constraint";
  // No need to set constraint if both expression are the same.
  if (false == IsEqual(v1, v2)) {
    LOG3("Setting equality constraint between " << v1->name() << " and " <<
         v2->name());
    if (equals_.count(v1) == 0) {
      equals_.insert(
        std::make_pair(v1, std::set<operations_research::IntExpr*>()));
      equals_.at(v1).insert(v1);
    }
    if (equals_.count(v2) == 0) {
      equals_.insert(
        std::make_pair(v2, std::set<operations_research::IntExpr*>()));
      equals_.at(v2).insert(v2);
    }
    solver_->AddConstraint(solver_->MakeEquality(v1, v2));
    std::set<operations_research::IntExpr*> &v1_set = equals_.at(v1);
    CHECK(v1_set.count(v1) == 1);
    std::set<operations_research::IntExpr*> &v2_set = equals_.at(v2);
    CHECK(v2_set.count(v2) == 1);
    v1_set.insert(v2_set.begin(), v2_set.end());
    for (auto v : v1_set) {
      equals_.at(v).insert(v1_set.begin(), v1_set.end());
    }
  }
}
template void
HeaderBits::SetEqualityConstraint<operations_research::IntVar *>(
  operations_research::IntVar *v1, operations_research::IntVar *v2);
template void
HeaderBits::SetEqualityConstraint<operations_research::IntExpr *>(
  operations_research::IntExpr *v1, operations_research::IntExpr *v2);

void
HeaderBits::SetNonEqualityConstraint(operations_research::IntExpr *v1,
                                     operations_research::IntExpr *v2) {
  // TODO: Change these to throw compiler error messages.
  CHECK(false == IsEqual(v1, v2));
  if (false == IsNonEqual(v1, v2)) {
    solver_->AddConstraint(solver_->MakeNonEquality(v1, v2));
    non_equals_.insert(std::make_pair(v1, v2));
    non_equals_.insert(std::make_pair(v2, v1));
  }
}

bool
HeaderBits::IsEqual(operations_research::IntExpr *v1,
                    operations_research::IntExpr *v2) const {
  return (v1 == v2) ||
         ((equals_.count(v1) != 0) && (equals_.at(v1).count(v2) != 0));
}

bool
HeaderBits::IsNonEqual(operations_research::IntExpr *v1,
                       operations_research::IntExpr *v2) const {
  return (non_equals_.count(std::make_pair(v1, v2)) != 0);
}

template<> std::set<operations_research::IntVar*>
HeaderBits::Equals(operations_research::IntVar *v) const {
  std::set<operations_research::IntVar*> rv;
  if (equals_.count(v) != 0) {
    for (auto v2 : equals_.at(v)) {
      rv.insert(dynamic_cast<operations_research::IntVar*>(v2));
    }
  }
  else rv.insert(v);
  return rv;
}

template<> std::set<operations_research::IntExpr*>
HeaderBits::Equals(operations_research::IntExpr *v) const {
  std::set<operations_research::IntExpr*> rv;
  if (equals_.count(v) != 0) {
    const set<operations_research::IntExpr*> &v2 = equals_.at(v);
    rv.insert(v2.begin(), v2.end());
  }
  else rv.insert(v);
  return rv;
}

void
HeaderBits::SetContainerWidthConstraints() const {
  typedef std::pair<operations_research::IntExpr*,
                     operations_research::IntVar*> key_type;
  std::map<key_type, HeaderBit*> max_const_offset;
  for (auto &item : bits_) {
    key_type key(std::make_pair(item.second->container(),
                                item.second->base_offset()));
    if (item.second->base_offset() == nullptr) continue;
    if (max_const_offset.count(key) == 0) {
      max_const_offset.insert(std::make_pair(key, item.second));
    }
    if ((max_const_offset[key]->relative_offset() <
         item.second->relative_offset()) &&
        item.second->group() != nullptr) max_const_offset[key] = item.second;
  }
  for (auto &item : max_const_offset) {
    item.second->SetContainerWidthConstraints(*solver_);
  }
}

std::vector<operations_research::IntVar*> HeaderBits::GetGroupVars() const {
  std::set<operations_research::IntVar*> group_vars;
  for (auto &item : bits_) {
    if (nullptr != item.second->group())
      group_vars.insert(item.second->group());
  }
  return std::vector<operations_research::IntVar*>(group_vars.begin(),
                                                   group_vars.end());
}

std::vector<operations_research::IntVar*>
HeaderBits::containers_and_offsets(
  const std::set<operations_research::IntVar*> &groups) const {
  std::vector<operations_research::IntVar*> vars;
  for (auto &item : bits_) {
    if (groups.count(item.second->group()) != 0) {
      auto it = std::find_if(vars.begin(), vars.end(),
                             [&item](operations_research::IntVar *v) -> bool {
                               return v == item.second->container_in_group(); });
      if (it == vars.end() && nullptr != item.second->container_in_group()) {
        vars.push_back(item.second->container_in_group()); }
      it = std::find_if(vars.begin(), vars.end(),
                        [&item](operations_research::IntVar *v) -> bool {
                          return v == item.second->base_offset(); });
      if (it == vars.end() && nullptr != item.second->offset()) {
        vars.push_back(item.second->base_offset()); }
    }
  }
  return vars;
}
