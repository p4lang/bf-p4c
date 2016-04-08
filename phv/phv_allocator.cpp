#include "phv_allocator.h"
#include "constraints.h"
#include "phv_fields.h"
#include "byte_constraint.h"
#include "container_constraint.h"
#include "match_xbar_constraint.h"
#include "mau_group_constraint.h"
#include "offset_constraint.h"
#include "parse_graph_constraint.h"
#include "source_container_constraint.h"
#include "t_phv_constraint.h"
#include "or_tools/min_value_solver.h"
#include "or_tools/random_value_solver.h"

using namespace std::placeholders;

class PopulatePhvInfo : public Inspector {
 public:
  PopulatePhvInfo(SolverInterface &solver, PhvInfo *phv_info) :
    solver_(solver), phv_info_(phv_info) { }
  bool preorder(const IR::Primitive *prim) override {
    bool rv = true;
    if (prim->name == "extract") {
      const IR::HeaderRef *hr = prim->operands[0]->to<IR::HeaderRef>();
      if (nullptr != hr) {
        GetAllocation(IR::HeaderSliceRef(hr->srcInfo, hr,
                                         hr->type->width_bits() - 1, 0));
        rv = false;
      }
    }
    return rv;
  }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    GetAllocation(*hsr);
    return false;
  }
 private:
  void GetAllocation(const IR::HeaderSliceRef hsr) {
    for (auto field : hsr.fields()) {
      vector<PhvInfo::Info::alloc_slice> *alloc = phv_info_->alloc(field);
      for (int i = field->lsb(); i <= field->msb(); ++i) {
        int field_bit = i - field->lsb();
        // Check if this bit has already been added to phv_info_.
        PHV::Container container;
        int container_bit;
        solver_.allocation(PHV::Bit(hsr.header_ref()->toString(), i),
                           &container, &container_bit);
        auto iter = alloc->begin();
        for (; iter != alloc->end(); ++iter) {
          if (iter->field_bit <= field_bit &&
              field_bit < iter->field_bit + iter->width) {
            break;
          }
          // Append the bit to an existing alloc structure.
          if (iter->container.index() == container.index() &&
              iter->width + iter->container_bit == container_bit &&
              iter->width + iter->field_bit == field_bit) {
            iter->width += 1;
            break;
          }
          // Prepend the bit to an existing alloc structure.
          if (iter->container.index() == container.index() &&
              iter->container_bit == container_bit + 1 &&
              iter->field_bit == (field_bit + 1)) {
            --(iter->field_bit);
            --(iter->container_bit);
            iter->width += 1;
            break;
          }
        }
        if (iter == alloc->end()) {
          alloc->emplace_back(container, field_bit, container_bit, 1);
        }
      }
    }
  }
  SolverInterface &solver_;
  PhvInfo *phv_info_;
};

void PhvAllocator::SetConstraints(const IR::Tofino::Pipe *pipe) {
  // TODO: The code below can be written more elegantly.
  MauGroupConstraint mgc(constraints_);
  pipe->apply(mgc);
  ContainerConstraint cc(constraints_);
  pipe->apply(cc);
  ByteConstraint bc(constraints_);
  pipe->apply(bc);
  OffsetConstraint oc(constraints_);
  pipe->apply(oc);
  SourceContainerConstraint scc(constraints_);
  // This loop should keep iterating until Constraints::SetEqual() has been
  // invoked on all pairs of source containers that have a common destination
  // container.
  do {
    scc.reset_updated();
    pipe->apply(scc);
  } while (true == scc.is_updated());
  // Set bits which cannot be allocated to T-PHV.
  TPhvConstraint tphvc(constraints_);
  pipe->apply(tphvc);
  // Set MAU match xbar constraints.
  MatchXbarConstraint smxc(constraints_);
  pipe->apply(smxc);
  ParseGraphConstraint pgc(constraints_);
  pipe->apply(pgc);
//BitOffsetConstraint boc(constraints_);
//pipe->apply(boc);


//// Set TPHV constraints. Fields used in MAU cannot go into T-PHV.
//or_tools::TPhvConstraint stphvc(header_bits_);
//maupipe_->apply(stphvc);
//// Set deparser constraints including deparser groups.
//SetDeparserConstraints sdc(header_bits_);
//maupipe_->apply(sdc);

//// Set single write constraint on primitives in an action.
//SetWriteConstraints sswc(header_bits_);
//maupipe_->apply(sswc);

//  // Collect constraint variables.
//  auto group_vars(header_bits_.GetGroupVars());
//  std::random_shuffle(group_vars.begin(), group_vars.end());
//  std::vector<IntVar*> vars;
//  while (group_vars.size() != 0) {
//    // Insert all group variables equal to first group.
//    const std::set<IntVar*> equal_groups =
//      header_bits_.Equals(*group_vars.begin());
//    vars.insert(vars.end(), equal_groups.begin(), equal_groups.end());
//    auto vars2 = header_bits_.containers_and_offsets(equal_groups);
//    vars.insert(vars.end(), vars2.begin(), vars2.end());
//    for (auto v : equal_groups) {
//      auto it = std::find(group_vars.begin(), group_vars.end(), v);
//      CHECK(it != group_vars.end());
//      group_vars.erase(it);
//    }
//  }
//  for (auto &v : vars) {
//    LOG1("Inserting " << v->name() << std::endl);
//  }
//  return vars;
}

bool PhvAllocator::Solve(const IR::Tofino::Pipe *pipe, PhvInfo *phv_info) {
  LOG1("Trying MIN_VALUE");
  or_tools::MinValueSolver solver;
  constraints_.SetConstraints(solver);
  int count = 0;
  while (count < 10) {
    if (true == solver.Solve()) {
      PopulatePhvInfo ppi(solver, phv_info);
      pipe->apply(ppi);
      return true;
    }
    else {
      ++count;
    }
  }
  return false;
}
