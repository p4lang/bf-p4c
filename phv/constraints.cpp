#include "constraints.h"
#include <base/logging.h>
#include "lib/log.h"
void
Constraints::SetEqual_(const PHV::Bit &bit1, const PHV::Bit &bit2,
                       const Equal &eq) {
  CHECK(eq < NUM_EQUALITIES) << "; Invalid equality type " << eq;
  auto &equality = equalities_[eq];
  if (equality.count(bit1) == 0)
    equality.insert(std::make_pair(bit1, std::set<PHV::Bit>({{bit1}})));
  if (equality.count(bit2) == 0)
    equality.insert(std::make_pair(bit2, std::set<PHV::Bit>({{bit2}})));
  auto &bit1_set = equality.at(bit1);
  if (bit1_set.count(bit2) == 0) {
    LOG2("Setting " << static_cast<int>(eq) << " for " << bit1 << ", " << bit2);
    bit1_set.insert(equality.at(bit2).begin(), equality.at(bit2).end());
    for (auto b : bit1_set) {
      equality.at(b).insert(bit1_set.begin(), bit1_set.end());
    }
  }
}

template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq) {
  SetEqual_(bit1, bit2, eq);
}

void
Constraints::SetConstraints(const Equal &e,
                            SolverInterface::SetEqual set_equal) {
  std::set<PHV::Bit> bits;
  for (auto &p : equalities_[e]) {
    if (bits.count(p.first) == 0) {
      set_equal(p.second);
      bits.insert(p.second.begin(), p.second.end());
    }
  }
}

void Constraints::SetNoTPhv(const PHV::Bit &bit) {
  size_t bit_id = unique_bit_id(bit);
  is_t_phv_[bit_id] = false;
}

void Constraints::SetConstraints(SolverInterface &solver) {
  using namespace std::placeholders;
  SetConstraints(Equal::MAU_GROUP,
                 std::bind(&SolverInterface::SetEqualMauGroup, &solver, _1));
  SetConstraints(Equal::CONTAINER,
                 std::bind(&SolverInterface::SetEqualContainer, &solver, _1));
  for (auto &byte : byte_equalities_) {
    solver.SetByte(byte);
  }
  SetConstraints(Equal::OFFSET,
                 std::bind(&SolverInterface::SetEqualOffset, &solver, _1));
  for (size_t i = 0; i < deparsed_headers_.size(); ++i) {
    for (auto &hdr : deparsed_headers_[i]) {
      CHECK(hdr.size() > 0) << "; Deparsing zero sized header";
      auto it = hdr.begin();
      solver.SetFirstDeparsedHeaderByte(*it);
      for (auto it2 = std::next(it, 1); it2 != hdr.end(); ++it, ++it2) {
        solver.SetDeparsedHeader(*it, *it2);
      }
      CHECK(hdr.end() != it);
      solver.SetLastDeparsedHeaderByte(*it);
    }
  }
  for (auto &i_hdr : deparsed_headers_[0]) {
    for (auto &e_hdr : deparsed_headers_[1]) {
      for (auto &i_hdr_byte : i_hdr) {
        for (auto &e_hdr_byte : e_hdr) {
          solver.SetDeparserGroups(i_hdr_byte, e_hdr_byte);
        }
      }
    }
  }
  // Set T-PHV constraint.
  for (auto &b : unique_bit_ids_) {
    if (false == is_t_phv_.at(b.second)) solver.SetNoTPhv(b.first);
  }
}

int Constraints::unique_bit_id(const PHV::Bit &bit) {
  if (unique_bit_ids_.count(bit) == 0) {
    unique_bit_ids_.insert(std::make_pair(bit, unique_bit_id_counter_));
    CHECK(is_t_phv_.size() == (unique_bit_id_counter_++));
    is_t_phv_.push_back(true);
  }
  return unique_bit_ids_.at(bit);
}
