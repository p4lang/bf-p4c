#include <constraint_solver/constraint_solver.h>
#include "mau_group.h"
#include "tofino/phv/phv.h"
#include "lib/log.h"

namespace or_tools {
using operations_research::IntVar;
using operations_research::Solver;

MauGroup::MauGroup(IntVar *mg, cstring name) : mau_group_(mg), is_t_phv_(true), name_(name) {
    std::array<const std::vector<int>, 3> groups =
        {{PHV::k8bMauGroups, PHV::k16bMauGroups, PHV::k32bMauGroups}};
    for (decltype(width_flags_.size()) i = 0; i < width_flags_.size(); ++i) {
        std::vector<IntVar *> is_equal_vars;
        const std::vector<int> &width_groups = groups.at(i);
        for (auto it = width_groups.begin(); it != width_groups.end(); ++it) {
            is_equal_vars.push_back(mau_group_->IsEqual(*it)); }
        width_flags_.at(i) = mau_group_->solver()->MakeSum(is_equal_vars)->Var(); }
}

void MauGroup::SetIngressDeparser() {
    CHECK(PHV::kEgressOnlyMauGroups.size() == 3) << ": Wrong egress group size";
    for (auto i : PHV::kEgressOnlyMauGroups) {
        if (true == mau_group_->Contains(i)) {
            LOG2("Removing egress-only group " << i << " for " << mau_group_);
            mau_group_->RemoveValue(i); } }
}

void MauGroup::SetEgressDeparser() {
    for (auto i : PHV::kIngressOnlyMauGroups) {
        if (true == mau_group_->Contains(i)) {
            LOG2("Removing ingress-only group " << i << " for " << mau_group_);
            mau_group_->RemoveValue(i); } }
}

void MauGroup::SetNoTPhv() {
    for (int i = 0; i < PHV::kNumTPhvMauGroups; ++i) {
        if (mau_group_->Contains(i + PHV::kTPhvMauGroupOffset)) {
            mau_group_->RemoveValue(i + PHV::kTPhvMauGroupOffset); } }
    is_t_phv_ = false;
}

}  // namespace or_tools
