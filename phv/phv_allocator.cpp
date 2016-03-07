#include "phv_allocator.h"
#include "phv_fields.h"
#include "constraint_solver/constraint_solver.h"
#include "header_bit.h"
#include "header_bit_creator.h"
#include "set_tphv_constraints.h"
#include "set_deparser_constraints.h"
#include "set_match_xbar_constraints.h"
#include "set_write_constraints.h"

using namespace std::placeholders;
using operations_research::IntVar;
using operations_research::Solver;
using operations_research::SearchMonitor;

class PopulatePhvInfo : public Inspector {
 public:
  PopulatePhvInfo(HeaderBits &header_bits, PhvInfo *phv_info) :
    header_bits_(header_bits), phv_info_(phv_info) { }
  bool
  preorder(const IR::HeaderSliceRef *hsr) {
    for (auto field : hsr->fields()) {
      vector<PhvInfo::Info::alloc_slice> *alloc = phv_info_->alloc(field);
      for (int i = field->lsb(); i <= field->msb(); ++i) {
        int field_bit = i - field->lsb();
        // Check if this bit has already been added to phv_info_.
        HeaderBit *bit = header_bits_.get(hsr->header_ref()->toString(), i);
        if (bit->group() == nullptr) continue;
        int container_offset_bits = bit->base_offset()->Value() +
                                    bit->relative_offset();
        unsigned container = bit->container<int>();
        auto iter = alloc->begin();
        for (; iter != alloc->end(); ++iter) {
          if (iter->field_bit <= field_bit &&
              field_bit < iter->field_bit + iter->width) {
            break;
          }
          // Append the bit to an existing alloc structure.
          if (iter->container.index() == container &&
              iter->width + iter->container_bit == container_offset_bits &&
              iter->width + iter->field_bit == field_bit) {
              iter->width += 1;
              break;
          }
          // Prepend the bit to an existing alloc structure.
          if (iter->container.index() == container &&
              iter->container_bit == container_offset_bits + 1 &&
              iter->field_bit == (field_bit + 1)) {
              --(iter->field_bit);
              --(iter->container_bit);
              iter->width += 1;
              break;
          }
        }
        if (iter == alloc->end()) {
          alloc->emplace_back(PHV::Container(bit->group()->Value(),
                                             bit->container_in_group()->Value()),
                              field_bit, container_offset_bits, 1);
        }
      }
    }
    return false;
  }
 private:
  HeaderBits &header_bits_;
  PhvInfo *phv_info_;
};

PhvAllocator::PhvAllocator(const IR::Tofino::Pipe *maupipe) :
  maupipe_(maupipe), solver_("Allocator"), header_bit_creator_(header_bits_) {
}

std::vector<IntVar*>
PhvAllocator::SetConstraints() {
  // Create HeaderBit* objects.
  maupipe_->apply(header_bit_creator_);

  header_bits_.set_solver(solver_);
  ContainerVarCreator cvc(header_bits_);
  cvc.CreateContainerVars(maupipe_);

  header_bits_.SetContainerWidthConstraints();

  // Set TPHV constraints. Fields used in MAU cannot go into T-PHV.
  SetTPhvConstraints stphvc(header_bits_);
  maupipe_->apply(stphvc);
  // Set deparser constraints including deparser groups.
  SetDeparserConstraints sdc(header_bits_);
  maupipe_->apply(sdc);

  SetEqualDstContainerConstraint sedcc(header_bits_);
  // This loop should keep iterating until SetEqualityConstraint has been set
  // between all pairs of sources that have a common destination container.
  do {
    sedcc.reset_updated();
    maupipe_->apply(sedcc);
  } while (true == sedcc.is_updated());
  // Set single write constraint on primitives in an action.
  SetWriteConstraints sswc(header_bits_);
  maupipe_->apply(sswc);

  // Set MAU match xbar constraints.
  SetMatchXbarConstraints smxc(header_bits_);
  maupipe_->apply(smxc);

  // Collect constraint variables.
  auto group_vars(header_bits_.GetGroupVars());
  std::random_shuffle(group_vars.begin(), group_vars.end());
  std::vector<IntVar*> vars;
  while (group_vars.size() != 0) {
    // Insert all group variables equal to first group.
    const std::set<IntVar*> equal_groups =
      header_bits_.Equals(*group_vars.begin());
    vars.insert(vars.end(), equal_groups.begin(), equal_groups.end());
    auto vars2 = header_bits_.containers_and_offsets(equal_groups);
    vars.insert(vars.end(), vars2.begin(), vars2.end());
    for (auto v : equal_groups) {
      auto it = std::find(group_vars.begin(), group_vars.end(), v);
      CHECK(it != group_vars.end());
      group_vars.erase(it);
    }
  }
  for (auto &v : vars) {
    LOG1("Inserting " << v->name() << std::endl);
  }
  return vars;
}

class PrintFailure : public SearchMonitor {
 public:
  explicit PrintFailure(Solver* const s, const std::vector<IntVar*> &vars) :
    SearchMonitor(s), vars_(vars) {}
  void BeginFail() {
    LOG1("Inspecting failure");
    for (auto v : vars_) {
      if (v->Size() == 1)
        LOG1("Found " << v->name() << " value is " << v->Value());
    }
  }
 private:
  const std::vector<IntVar*> vars_;
};

bool PhvAllocator::Solve() {
  LOG1("Trying MIN_VALUE");
  auto vars = SetConstraints();
  auto db = solver_.MakePhase(
              vars, Solver::CHOOSE_FIRST_UNBOUND, Solver::ASSIGN_MIN_VALUE);
  solver_.NewSearch(db, solver_.MakeFailuresLimit(10000U),
                    new PrintFailure(&solver_, vars));
  return solver_.NextSolution();
}

bool PhvAllocator::SolveRandomValueStrategy() {
  LOG1("Trying RANDOM_VALUE");
  auto vars = SetConstraints();
  auto db = solver_.MakePhase(
              vars, Solver::CHOOSE_FIRST_UNBOUND, Solver::ASSIGN_RANDOM_VALUE);
  solver_.NewSearch(db, solver_.MakeLubyRestart(1000),
                    solver_.MakeTimeLimit(120000));
  return solver_.NextSolution();
}

void
PhvAllocator::GetAllocation(PhvInfo *phv_info) {
  PopulatePhvInfo ppi(header_bits_, phv_info);
  maupipe_->apply(ppi);
  for (auto &item : header_bits_) {
    if (item.second->container() == nullptr) continue;
    std::cout << item.second->name() << ":" << item.second->is_8b()->Value() << item.second->is_16b()->Value() << item.second->is_32b()->Value() << " " << item.second->group()->Value() << " " << item.second->base_offset()->Value() << std::endl;
  }
}
