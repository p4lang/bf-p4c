#include "match_xbar_constraint.h"
#include "backends/tofino/phv/header_bits.h"
#include "backends/tofino/phv/header_bit.h"
#include <constraint_solver/constraint_solver.h>

void
or_tools::MatchXbarConstraint::SetUniqueConstraint(
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

void
or_tools::MatchXbarConstraint::EnforceConstraint(
  const std::set<PHV::Bit> &match_bits, const std::array<int, 4> &byte_limits) {
  std::vector<HeaderBit*> phv_bytes;
  for (auto bit : match_bits) {
    phv_bytes.push_back(header_bits_.get(bit.first, bit.second));
    LOG2("Adding " << phv_bytes.back()->name() << " to match xbar constraint");
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
  int total_uniques = std::accumulate(byte_limits.begin(), byte_limits.end(),
                                      0, std::plus<int>());
  LOG2("Fitting " << is_unique_flags.size() << " flags into " <<
         total_uniques << "B");
  CHECK(phv_bytes.size() == is_unique_flags.size());
  solver->AddConstraint(
    solver->MakeLessOrEqual(
      solver->MakeSum(is_unique_flags), total_uniques));
  // Express constraints on match fields extracted from 32b containers.
  for (std::size_t i = 0; i < byte_limits.size() &&
                          (int)is_unique_flags.size() > byte_limits[i]; ++i) {
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
           byte_limits[i] << "B in match xbar");
    solver->AddConstraint(
      solver->MakeLessOrEqual(
        solver->MakeSum(is_unique_and_nth_byte), byte_limits[i]));
  }
  SetUniqueConstraint(is_unique_flags, phv_bytes, byte_limits, {{0, 2}});
  SetUniqueConstraint(is_unique_flags, phv_bytes, byte_limits, {{1, 3}});
}
