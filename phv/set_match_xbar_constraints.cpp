#include "set_match_xbar_constraints.h"
#include "header_bits.h"
#include "header_bit.h"
#include <constraint_solver/constraint_solver.h>
class HeaderSliceRefInspector : public Inspector {
 public:
  HeaderSliceRefInspector(const IR::Node *node, HeaderBits &header_bits) :
    header_bits_(header_bits) { node->apply(*this); }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      HeaderBit *bit = header_bits_.get(hsr->header_ref()->toString(), i);
      if (nullptr != bit->byte()) match_bits_.insert(bit);
    }
    return false;
  }
  std::set<HeaderBit*> match_bits() const { return match_bits_; }
 private:
  std::set<HeaderBit*> match_bits_;
  const HeaderBits &header_bits_;
};

bool SetMatchXbarConstraints::preorder(const IR::MAU::Table *mau_table) {
  const int stage = mau_table->stage();
  LOG1("Found table " << mau_table->name << " in stage " << stage <<
         " match width " << mau_table->layout.match_width_bits <<
         " and logical ID " << mau_table->logical_id);
  std::set<HeaderBit*> match_bits;
  if ((nullptr != mau_table->match_table) &&
      (nullptr != mau_table->match_table->reads)) {
    HeaderSliceRefInspector hsri(mau_table->match_table->reads, header_bits_);
    auto new_match_bits = hsri.match_bits();
    match_bits.insert(new_match_bits.begin(), new_match_bits.end());
  }
  for (auto &gw_row : mau_table->gateway_rows) {
    HeaderSliceRefInspector hsri(gw_row.first, header_bits_);
    auto new_match_bits = hsri.match_bits();
    match_bits.insert(new_match_bits.begin(), new_match_bits.end());
  }
  if (true == mau_table->layout.ternary) {
    ternary_match_bits_[stage].insert(match_bits.begin(), match_bits.end());
  }
  else if (false == mau_table->layout.gateway) {
    exact_match_bits_[stage].insert(match_bits.begin(), match_bits.end());
  }
  return true;
}

void
SetMatchXbarConstraints::SetUniqueConstraint(
  const std::set<HeaderBit*> &bits,
  const std::array<int, 4> &unique_bytes) const {
  std::vector<HeaderBit*> phv_bytes;
  for (auto bit : bits) {
    auto it =std::find_if(
               phv_bytes.begin(), phv_bytes.end(),
               [&bit, this](HeaderBit *b) -> bool {
                 return (bit->byte() == b->byte()) ||
                        (header_bits_.IsEqual(bit->container(), b->container()) &&
                         bit->byte_offset_flags() == b->byte_offset_flags()); });
    if (phv_bytes.end() == it) {
      phv_bytes.push_back(bit);
    }
    else if ((*it)->relative_offset() > bit->relative_offset()) {
      (*it) = bit;
    }
  }
  for (auto &item : phv_bytes) {
    LOG2("Adding " << item->name() << " to match xbar constraint");
  }
  operations_research::Solver *solver = header_bits_.solver();
  std::vector<operations_research::IntVar*> is_unique_flags;
  for (auto byte = phv_bytes.begin(); byte != phv_bytes.end(); ++byte) {
    std::vector<operations_research::IntVar*> is_equal_vars;
    for (auto later_byte = std::next(byte, 1); later_byte != phv_bytes.end();
         ++later_byte) {
      is_equal_vars.push_back(solver->MakeIsDifferentVar((*later_byte)->byte(),
                                                         (*byte)->byte()));
    }
    auto sum = solver->MakeSum(is_equal_vars);
    is_unique_flags.push_back(
      solver->MakeIsEqualCstVar(sum, std::distance(byte, phv_bytes.end()) - 1));
  }
  // This constraint enforces the limit on the total width of the match xbar.
  int total_uniques = std::accumulate(unique_bytes.begin(), unique_bytes.end(),
                                      0, std::plus<int>());
  LOG2("Fitting " << is_unique_flags.size() << " flags into " <<
         total_uniques << "B");
  CHECK(phv_bytes.size() == is_unique_flags.size());
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(is_unique_flags), total_uniques));
  // Express constraints on match fields extracted from 32b containers.
  for (std::size_t i = 0; i < unique_bytes.size() &&
                          (int)is_unique_flags.size() > unique_bytes[i]; ++i) {
    std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
    for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
      operations_research::IntVar *v = is_unique_flags[b];
      HeaderBit *bit = phv_bytes[b];
      is_unique_and_nth_byte.push_back(
        solver->MakeIsEqualCstVar(
          solver->MakeSum(
            solver->MakeSum(bit->is_32b(), bit->byte_offset_flags()[i]), v),
          3));
    }
    LOG2("Constraining " << is_unique_and_nth_byte.size() << " to " <<
           unique_bytes[i] << "B in match xbar");
    solver->AddConstraint(
      solver->MakeLessOrEqual(
        solver->MakeSum(is_unique_and_nth_byte), unique_bytes[i]));
  }
  SetUniqueConstraint(is_unique_flags, phv_bytes, unique_bytes, {{0, 2}});
  SetUniqueConstraint(is_unique_flags, phv_bytes, unique_bytes, {{1, 3}});
}

void
SetMatchXbarConstraints::SetUniqueConstraint(
  std::vector<operations_research::IntVar*> &is_unique_flags,
  const std::vector<HeaderBit*> &phv_bytes,
  const std::array<int, 4> &unique_bytes,
  const std::vector<std::size_t> &byte_offsets) const {
  operations_research::Solver *solver = header_bits_.solver();
  int max_unique_bytes = 0;
  for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
    max_unique_bytes += unique_bytes[byte_offsets[i]];
  }
  std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
  for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
    for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
      operations_research::IntVar *v = is_unique_flags[b];
      HeaderBit *bit = phv_bytes[b];
      CHECK(bit->byte_offset_flags().size() > byte_offsets[i]);
      if (byte_offsets[i] == 0) {
        is_unique_and_nth_byte.push_back(
          solver->MakeIsEqualCstVar(
            solver->MakeSum(
              solver->MakeSum(bit->is_32b(), bit->is_16b()),
              solver->MakeSum(v, bit->byte_offset_flags()[byte_offsets[i]])),
            3));
      }
      else {
        is_unique_and_nth_byte.push_back(
          solver->MakeIsEqualCstVar(
            solver->MakeSum(v, bit->byte_offset_flags()[byte_offsets[i]]), 2));
      }
    }
  }
  LOG2("Constraining " << is_unique_and_nth_byte.size() << " to " <<
         max_unique_bytes << "B in match xbar");
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(is_unique_and_nth_byte), max_unique_bytes));
}

void SetMatchXbarConstraints::postorder(const IR::Tofino::Pipe *) {
  for (unsigned stage = 0; stage < StageUse::MAX_STAGES; ++stage) {
    LOG2("Found " << exact_match_bits_[stage].size() <<
           " exact match bits in stage " << stage);
    SetUniqueConstraint(exact_match_bits_[stage], {{32, 32, 32, 32}});
    exact_match_bits_[stage].clear();
    LOG2("Found " << ternary_match_bits_[stage].size() <<
           " ternary match bits in stage " << stage);
    SetUniqueConstraint(ternary_match_bits_[stage], {{17, 17, 16, 16}});
    ternary_match_bits_[stage].clear();
  }
}
