#include "set_deparser_constraints.h"
#include "header_bits.h"
#include "header_bit.h"
#include "phv.h"
#include "constraint_solver/constraint_solver.h"
namespace operations_research {
  class Solver;
}

bool SetDeparserConstraints::preorder(const IR::HeaderSliceRef *hsr) {
  // If this HeaderSliceRef is not in an emit primitive, ignore it.
  // TODO: Currently, this does not handle intrinsic metadata that appears in
  // the deparsers.
  if (nullptr == findContext<IR::Primitive>() ||
      "emit" != findContext<IR::Primitive>()->name) return false;
  operations_research::Solver *solver = header_bits_.solver();
  const gress_t gress = findContext<IR::Tofino::Deparser>()->gress;
  HeaderBit *prev_bit = nullptr;
  LOG1("Setting deparser constraints on " << hsr);
  for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
    const cstring &header_name = hsr->header_ref()->toString();
    HeaderBit *bit = header_bits_.get(header_name, i);
    CHECK(bit->group() != nullptr) << "; Invalid group for " << header_name;
    CHECK(bit->container() != nullptr) << "; Invalid container for " <<
      header_name;
    if (nullptr != prev_bit && bit->container() == prev_bit->container()) {
      // This is executed when we know that prev_bit and this will be allocated
      // to consecutive bits in the same byte in the same container.
      LOG2("Copying constraints from " << prev_bit->name() << " to " <<
             bit->name());
      bit->set_is_last_byte(prev_bit->is_last_byte());
    }
    else {
      LOG2("Setting deparser constraints for " << bit->name());
      bit->SetDeparserConstraints(prev_bit, gress, *solver);
    }
    prev_bit = bit;
  }
  CHECK(nullptr != prev_bit);
  // prev_bit must always be allocated to the last byte of the container.
  prev_bit->SetLastDeparsedHeaderByteConstraint(*solver);

  // Set deparser group constraints.
  auto invalid_mau_group = &(gress == INGRESS ? PHV::kEgressMauGroups :
                                                PHV::kIngressMauGroups);
  for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
    HeaderBit *bit = header_bits_.get(hsr->header_ref()->toString(), i);
    for (auto mau_group : *invalid_mau_group) {
      // Remove MAU groups which are tied to the opposite gress.
      bit->group()->RemoveValue(mau_group);
    }
  }
  for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
    HeaderBit *bit = header_bits_.get(hsr->header_ref()->toString(), i);
    if (containers_.count(bit->container()) == 0) {
      DeparserFlags deparser_flags;
      for (DeparserFlags::size_type f = 0; f < deparser_flags.size(); ++f) {
        deparser_flags[f] = solver->MakeBoolVar(bit->name() + "-dep-flag" +
                                                std::to_string(f));
      }
      for (auto &c : PHV::kContainerToDeparserGroup) {
        solver->AddConstraint(
          solver->MakeGreater(
            solver->MakeSum(
              solver->MakeIsDifferentCstVar(bit->container(), c.first),
              deparser_flags[c.second]), 0));
      }
      if (first_gress_containers_.size() == 0) {
        first_gress_containers_.insert(std::make_pair(bit->container(),
                                                      deparser_flags));
        first_gress_ = gress;
      }
      if (gress != first_gress_) {
        for (auto &c : first_gress_containers_) {
          CHECK(c.first != bit->container());
          for (DeparserFlags::size_type f = 0; f < c.second.size(); --f) {
            solver->AddConstraint(
              solver->MakeNonEquality(
                solver->MakeSum(c.second.at(f), deparser_flags.at(f)), 2));
          }
        }
      }
      else {
        first_gress_containers_.insert(std::make_pair(bit->container(),
                                                      deparser_flags));
      }
      containers_.insert(bit->container());
    }
  }
  return false;
}
