#include "constraints.h"
#include <base/logging.h>
#include "lib/log.h"
#include <set>
void Constraints::SetEqualByte(const PHV::Byte &byte) {
  LOG2("Setting byte constraint " << byte.name());
  // All the valid bits of byte must be contiguous.
  // TODO: This does not handle the case where byte can have "holes" of invalid
  // bits.
  SetContiguousBits(byte.valid_bits());
  const int d = std::distance(byte.cbegin(), byte.cfirst());
  std::vector<int> v({{0, 8, 16, 24}});
  for (auto &i : v) i += d;
  const PHV::Bit &bit = *(byte.cfirst());
  if (bit_offset_domain_.count(bit) != 0) {
    const std::vector<int> &v2 = bit_offset_domain_.at(bit);
    for (int i = 0; i < 32; ++i) {
      auto e = std::find(v.begin(), v.end(), i);
      if (e != v.end() && std::find(v2.begin(), v2.end(), i) == v2.end()) {
        v.erase(e);
      }
    }
    bit_offset_domain_.erase(bit);
  }
  if (bit_offset_range_.count(bit) != 0) {
    while (v.front() < bit_offset_range_.at(bit).first) v.erase(v.begin());
    while (v.back() > bit_offset_range_.at(bit).second) v.pop_back();
    bit_offset_range_.erase(bit);
  }
  CHECK(bit_offset_domain_.count(bit) == 0);
  // TODO: Change this to compiler error message.
  CHECK(v.size() > 0) << ": No valid offset found for " << bit;
  bit_offset_domain_.insert(std::make_pair(bit, v));
  // TODO: byte_equalities_ is currently used to determine if 2 bits must be
  // allocated to the same byte of a PHV container. This is redundant. We could
  // use the offset constraints and contiguous bits constraints to figure this
  // out.
  byte_equalities_.insert(byte);
}

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

PHV::Byte Constraints::GetByte(const PHV::Bit &b) const {
  for (auto &byte : byte_equalities_) {
    if (true == byte.Contains(b)) return byte;
  }
  return PHV::Byte();
}

inline void Constraints::SetMatchBits(const std::set<PHV::Bit> &bits,
                                      std::vector<PHV::Bit> *v) {
  // bits might contain 2 bits that must appear in the same byte of a PHV
  // container. We need to apply the match xbar width constraint on only one of
  // those bits since the other can be extracted for the PHV for no extra cost.
  // So, we create a new set (called uniq_bytes) which will contain only 1 of
  // the bits appearing in the same byte of a PHV container. The
  // byte_equalities_ object must be used to identify bits that appear in the
  // same PHV container byte. Note that std::set will consider two elements
  // identical if both comp(b1, b2) and comp(b2, b1) return false.
  auto comp = [this](const PHV::Bit &b1, const PHV::Bit &b2) -> bool {
                 if (true == this->GetByte(b1).Contains(b2)) return false;
                 return (b1 < b2); };
  std::set<PHV::Bit, decltype(comp)> uniq_bytes(bits.begin(), bits.end(), comp);
  v->insert(v->end(), uniq_bytes.begin(), uniq_bytes.end());
  CHECK(v->size() == uniq_bytes.size());
}

bool Constraints::IsContiguous(const PHV::Bits &pbits) const {
  for (auto &c : contiguous_bits_) {
    if (std::search(c.cbegin(), c.cend(),
                    pbits.cbegin(), pbits.cend()) != c.cend()) {
      return true;
    }
  }
  return false;
}

template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq) {
  SetEqual_(bit1, bit2, eq);
}

template<class T> void
Constraints::SetConstraints(const Equal &e, T set_equal,
                            std::set<PHV::Bit> bits) {
  for (auto &p : equalities_[e]) {
    if (bits.count(p.first) == 0) {
      bool is_t_phv = std::accumulate(p.second.begin(), p.second.end(), true,
                                      [this](const bool &f, PHV::Bit b) {
                                        BitId bit_id = unique_bit_id(b);
                                        return f && is_t_phv_.at(bit_id); });
      set_equal(p.second, is_t_phv);
      bits.insert(p.second.begin(), p.second.end());
    }
  }
}

void
Constraints::SetOffset(const PHV::Bit &bit, const int &min, const int &max) {
  if (bit_offset_domain_.count(bit) != 0) {
    // This bit already has an entry in bit_offset_domain_. Just prune values
    // outside the [min, max] range.
    std::vector<int> &domain = bit_offset_domain_.at(bit);
    while (domain.front() < min) domain.erase(domain.begin());
    while (domain.back() > max) domain.pop_back();
  }
  else {
    int new_min = min;
    int new_max = max;
    if (bit_offset_range_.count(bit) != 0) {
      new_min = std::max(min, bit_offset_range_.at(bit).first);
      new_max = std::min(max, bit_offset_range_.at(bit).second);
    }
    bit_offset_range_[bit] = std::make_pair(min, max);
  }
}
void Constraints::SetContiguousBits(const PHV::Bits &bits) {
  if (false == bits.empty()) {
    LOG2("Setting contiguous bits " << bits << " of size " << bits.size());
    contiguous_bits_.push_back(bits);
  }
}

void Constraints::SetNoTPhv(const PHV::Bit &bit) {
  BitId bit_id = unique_bit_id(bit);
  is_t_phv_[bit_id] = false;
}

void Constraints::SetExactMatchBits(const int &stage,
                                    const std::set<PHV::Bit> &bits) {
  SetMatchBits(bits, &exact_match_bits_.at(stage));
  LOG2("Found " << exact_match_bits_.at(stage).size() <<
         " exact match bits in stage " << stage);
}

void Constraints::SetTcamMatchBits(const int &stage,
                                   const std::set<PHV::Bit> &bits) {
  SetMatchBits(bits, &tcam_match_bits_.at(stage));
  LOG2("Found " << tcam_match_bits_.at(stage).size() <<
         " TCAM match bits in stage " << stage);
}

void Constraints::SetConstraints(SolverInterface &solver) {
  struct {
    void SetEqualOffset(const PHV::Bit &b,
                        const std::map<PHV::Bit, std::set<PHV::Bit>> &offset_eq,
                        SolverInterface &solver) {
      if (prev_bits.count(b) == 0 && offset_eq.count(b) != 0) {
        solver.SetEqualOffset(offset_eq.at(b));
      }
      prev_bits.insert(b);
    }
   std::set<PHV::Bit> prev_bits;
  } eq_offsets;
  using namespace std::placeholders;
  SetConstraints(Equal::MAU_GROUP, std::bind(&SolverInterface::SetEqualMauGroup,
                                             &solver, _1, _2),
                 std::set<PHV::Bit>());
  SetConstraints(Equal::CONTAINER,
                 std::bind(&SolverInterface::SetEqualContainer, &solver, _1),
                 std::set<PHV::Bit>());
//for (auto &byte : byte_equalities_) {
//  solver.SetByte(byte);
//}
  for (auto &b : bit_offset_domain_) {
    solver.SetOffset(b.first, b.second);
    eq_offsets.SetEqualOffset(b.first, equalities_[Equal::OFFSET], solver);
  }
  for (auto &b : bit_offset_range_) {
    solver.SetOffset(b.first, b.second.first, b.second.second);
    eq_offsets.SetEqualOffset(b.first, equalities_[Equal::OFFSET], solver);
  }
  for (auto &bits : contiguous_bits_) {
    CHECK(false == bits.empty()) << ": PHV::Bits is empty";
    const PHV::Bit b1 = bits.front();
    PHV::Bits::const_iterator b2 = std::next(bits.cbegin());
    eq_offsets.SetEqualOffset(b1, equalities_[Equal::OFFSET], solver);
    while (b2 != bits.cend()) {
      solver.SetBitDistance(b1, *b2, std::distance(bits.cbegin(), b2));
      eq_offsets.SetEqualOffset(*b2, equalities_[Equal::OFFSET], solver);
      ++b2;
    }
  }
  SetConstraints(Equal::OFFSET,
                 std::bind(&SolverInterface::SetEqualOffset, &solver, _1),
                 eq_offsets.prev_bits);
  for (size_t i = 0; i < deparsed_headers_.size(); ++i) {
    for (auto &hdr : deparsed_headers_[i]) {
      CHECK(hdr.size() > 0) << "; Deparsing zero sized header";
      auto it = hdr.begin();
      solver.SetFirstDeparsedHeaderByte(*it);
      for (auto it2 = std::next(it, 1); it2 != hdr.end(); ++it, ++it2) {
        // Sanity check: All eight bits must be valid since the deparser can
        // only deparse whole containers.
        const PHV::Bits bits = it2->valid_bits();
        CHECK(8 == bits.size()) << ": Invalid byte size " << it2->name();
        // This is just a sanity check. There must be an entry in
        // contiguous_bits_ for every deparsed byte.
        CHECK(IsContiguous(bits)) << ": Non-contiguous bits in " << it2->name();
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
  for (auto &v : exact_match_bits_) {
    solver.SetMatchXbarWidth(v, {{32, 32, 32, 32}});
  }
  for (auto &v : tcam_match_bits_) {
    solver.SetMatchXbarWidth(v, {{17, 17, 16, 16}});
  }
  // Set T-PHV constraint.
  for (auto &b : uniq_bit_ids_) {
    if (false == is_t_phv_.at(b.second)) solver.SetNoTPhv(b.first);
  }
}

Constraints::BitId Constraints::unique_bit_id(const PHV::Bit &bit) {
  if (uniq_bit_ids_.count(bit) == 0) {
    uniq_bit_ids_.insert(std::make_pair(bit, unique_bit_id_counter_));
    CHECK(bits_.size() == unique_bit_id_counter_);
    bits_.push_back(bit);
    CHECK(is_t_phv_.size() == (unique_bit_id_counter_++));
    is_t_phv_.push_back(true);
  }
  return const_cast<const Constraints*>(this)->uniq_bit_ids_.at(bit);
}

Constraints::BitId Constraints::unique_bit_id(const PHV::Bit &bit) const {
  CHECK(uniq_bit_ids_.count(bit) != 0) << ": Cannot find BitId for " << bit;
  return uniq_bit_ids_.at(bit);
}
