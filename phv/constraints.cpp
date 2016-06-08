#include "constraints.h"
#include <base/logging.h>
#include <set>
#include <cmath>
#include <climits>
#include "lib/log.h"
void Constraints::SetEqualByte(const PHV::Byte &byte) {
  LOG2("Setting byte constraint " << byte.name());
  // All the valid bits of byte must be contiguous.
  // TODO: This does not handle the case where byte can have "holes" of invalid
  // bits.
  SetContiguousBits(byte.valid_bits());
  // The rest of the function essentially sets possible offset values for the
  // first valid bit in byte. It has to handle 2 complexities:
  // 1. The domain of possible values is for the first valid bit is {0+i, 8+i,
  // 16+i, 24+i} when i is the distance of the first valid bit from the
  // beginning of the byte.
  // 2. The first valid bit might already have an entry in bit_offset_domain_
  // or bit_offset_range_. In that case, we must remove the origin entry insert
  // an entry in bit_offset_domain_ which is the intersection of step 1 and the
  // original entry.
  const int d = std::distance(byte.cbegin(), byte.cfirst());
  std::vector<int> domain({{0, 8, 16, 24}});
  for (auto &i : domain) i += d;
  const PHV::Bit &bit = *(byte.cfirst());
  if (bit_offset_domain_.count(bit) != 0) {
    const std::vector<int> &v2 = bit_offset_domain_.at(bit);
    for (int i = 0; i < 32; ++i) {
      auto e = std::find(domain.begin(), domain.end(), i);
      if (e != domain.end() && std::find(v2.begin(), v2.end(), i) == v2.end()) {
        domain.erase(e);
      }
    }
    bit_offset_domain_.erase(bit);
  }
  if (bit_offset_range_.count(bit) != 0) {
    while (domain.front() < bit_offset_range_.at(bit).first) {
      domain.erase(domain.begin());
    }
    while (domain.back() > bit_offset_range_.at(bit).second) domain.pop_back();
    bit_offset_range_.erase(bit);
  }
  CHECK(!bit_offset_domain_.count(bit));
  // TODO: Change this to compiler error message.
  CHECK(domain.size() > 0) << ": No valid offset found for " << bit;
  LOG2("Setting bit-offset domain for " << bit.name());
  bit_offset_domain_.insert(std::make_pair(bit, domain));
  // TODO: byte_equalities_ is currently used to determine if 2 bits must be
  // allocated to the same byte of a PHV container. This is redundant. We could
  // use the offset constraints and contiguous bits constraints to figure this
  // out.
  byte_equalities_.insert(byte);
}

bool Constraints::IsDeparsed(const PHV::Byte &byte) const {
  for (auto hdrs : deparsed_headers_) {
    for (auto hdr : hdrs) {
      if (hdr.end() != std::find(hdr.begin(), hdr.end(), byte)) return true;
    }
  }
  return false;
}

std::set<PHV::Bit>
Constraints::GetEqual(const PHV::Bit &b, const Equal &e) const {
  if (0 == equalities_[e].count(b))
      return std::set<PHV::Bit>({b});
  return equalities_[e].at(b);
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
  LOG2("Setting range for " << bit);
  if (bit_offset_domain_.count(bit) != 0) {
    // This bit already has an entry in bit_offset_domain_. Just prune values
    // outside the [min, max] range.
    std::vector<int> &domain = bit_offset_domain_.at(bit);
    while (domain.front() < min) domain.erase(domain.begin());
    while (domain.back() > max) domain.pop_back();
  } else {
    int new_min = min;
    int new_max = max;
    if (bit_offset_range_.count(bit) != 0) {
      new_min = std::max(min, bit_offset_range_.at(bit).first);
      new_max = std::min(max, bit_offset_range_.at(bit).second);
    }
    bit_offset_range_[bit] = std::make_pair(new_min, new_max);
  }
}
void Constraints::SetContiguousBits(const PHV::Bits &bits) {
  if (false == bits.empty()) {
    LOG2("Setting contiguous bits " << bits << " of size " << bits.size());
    contiguous_bits_.push_back(bits);
  }
}

std::pair<int, bool>
Constraints::GetDistance(const PHV::Bit &b1, const PHV::Bit &b2) const {
  for (auto bits : contiguous_bits_) {
    auto it1 = std::find(bits.begin(), bits.end(), b1);
    auto it2 = std::find(bits.begin(), bits.end(), b2);
    if (bits.end() != it1 && bits.end() != it2) {
      return std::make_pair(std::distance(it1, it2), true);
    }
  }
  return std::make_pair(INT_MAX, false);
}

void Constraints::SetNoTPhv(const PHV::Bit &bit) {
  BitId bit_id = unique_bit_id(bit);
  is_t_phv_[bit_id] = false;
}

void Constraints::SetExactMatchBits(const int &stage,
                                    const std::set<PHV::Bit> &bits) {
  if (exact_match_bits_.size() <= size_t(stage))
    exact_match_bits_.resize(stage+1);
  SetMatchBits(bits, &exact_match_bits_.at(stage));
  LOG2("Found " << exact_match_bits_.at(stage).size() <<
         " exact match bits in stage " << stage);
}

void Constraints::SetTcamMatchBits(const int &stage,
                                   const std::set<PHV::Bit> &bits) {
  if (tcam_match_bits_.size() <= size_t(stage))
    tcam_match_bits_.resize(stage+1);
  SetMatchBits(bits, &tcam_match_bits_.at(stage));
  LOG2("Found " << tcam_match_bits_.at(stage).size() <<
         " TCAM match bits in stage " << stage);
}

void
Constraints::SetContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2) {
  CHECK(true == b1.IsValid()) << ": First bit is invalid";
  CHECK(true == b2.IsValid()) << ": Second bit is invalid";
  // Just return if there is already a container conflict between the two bits.
  // The two for-loops below are time consuming.
  if (true == IsContainerConflict(b1, b2)) return;
  LOG2("Setting container conflict between " << b1 << " and " << b2);
  // Set container conflicts between all bits that must share containers with
  // b1 and b2.
  for (auto x : GetEqual(b1, Equal::CONTAINER)) {
    for (auto y : GetEqual(b2, Equal::CONTAINER)) {
      BitId bit_min = std::min(unique_bit_id(x), unique_bit_id(y));
      BitId bit_max = std::max(unique_bit_id(x), unique_bit_id(y));
      container_conflicts_.at(bit_max).at(bit_min) = true;
    }
  }
}

bool
Constraints::IsContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2) const {
  // Assume there is no container conflict between a bit and itself.
  if (b1 == b2) return false;
  // If either bit does not have an entry in the conflict matrix, just return
  // false. It probably does not have any conflicting constraints.
  if (uniq_bit_ids_.count(b1) == 0) return false;
  if (uniq_bit_ids_.count(b2) == 0) return false;
  BitId bit_min = std::min(unique_bit_id(b1), unique_bit_id(b2));
  BitId bit_max = std::max(unique_bit_id(b1), unique_bit_id(b2));
  return container_conflicts_.at(bit_max).at(bit_min);
}

void Constraints::SetBitConflict(const PHV::Bit &b1, const PHV::Bit &b2) {
  CHECK(b1 != b2) << ": " << b1 << " conflicting with self";
  BitId bit_min = std::min(unique_bit_id(b1), unique_bit_id(b2));
  BitId bit_max = std::max(unique_bit_id(b1), unique_bit_id(b2));
  if (false == bit_conflicts_.at(bit_max).at(bit_min)) {
    LOG2("Setting bit conflict between " << b1 << " and " << b2);
    bit_conflicts_.at(bit_max).at(bit_min) = true;
  }
}

void Constraints::SetDstSrcPair(const cstring &af_name,
                                const std::pair<PHV::Bit, PHV::Bit> &p) {
  auto &s = dst_src_pairs_[af_name];
  s.insert(p);
}

// FIXME: This function does not handle set_metadata extractions. For
// set_metadata, the first few and last few bits of a byte might be invalid. In
// that case, we must set conflicts between the first pair of valid bits of
// every bytes. For, just adding a spurious CHECK(true==it->IsValid()) so that
// compiler crashes if this is not fixed.
void Constraints::SetParseConflict(const PHV::Bits &old_bits,
                                   const PHV::Bits &new_bits) {
  CHECK(new_bits.size() % 8 == 0) << ": Bad size " << new_bits.size();
  CHECK(old_bits.size() % 8 == 0) << ": Bad size " << old_bits.size();
  // We are setting bit-conflicts between every 8th bit. We do not need to set
  // a conflict between every pair of bits because the following statements are
  // true:
  // 1. Every 8th bit will be allocated at offset 0 or 8 or 16 or 24 in a PHV
  //    container.
  // 2. Since the parser extracts bytes, the bits in old_bits and new_bits are
  //    allocated in sets of 8.
  // Because of this, when we set a bit-conflict between every 8th bit, we are
  // guaranteed that no bits in old_bits will be overlayed with any bits in
  // new_bits.
  for (auto it = new_bits.cbegin(); it != new_bits.cend(); std::advance(it, 8)) {
    // We want to set a container-conflict if both bits are being deparsed and:
    // 1. distance > 31 OR
    // 2. Bits are being emitted with different POV bits. The assumption here
    // is that if bits are being emitted in different emit primitives, use
    // different POV bits. is_valid is false if the bits are being emitted in
    // different primitives.
    int distance;
    bool is_valid;
    // FIXME: Remove after inserting code for set_metadata.
    CHECK(true == it->IsValid());
    for (auto it2 = new_bits.cbegin(); it2 != it;) {
      // FIXME: Remove after inserting code for set_metadata.
      CHECK(true == it2->IsValid());
      // TODO: If *it and *it2 are being deparsed in the same emit() and they
      // are atleast 32b apart, then we must set a container-conflict between
      // them. This might speed up the solver.
      SetBitConflict(*it, *it2);
      std::advance(it2, 8);
    }
    for (auto it2 = old_bits.cbegin(); it2 != old_bits.cend();) {
      // FIXME: Remove after inserting code for set_metadata.
      CHECK(true == it2->IsValid());
      std::tie(distance, is_valid) = GetDistance(*it, *it2);
      if (((is_valid == false) || distance >= 32) &&
          true == IsDeparsed(PHV::Byte(it, std::next(it, 8))) &&
          true == IsDeparsed(PHV::Byte(it2, std::next(it2, 8)))) {
        SetContainerConflict(*it, *it2);
      } else {
        SetBitConflict(*it, *it2);
      }
      std::advance(it2, 8);
    }
  }
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
    // Stores the PHV::Bit objects for which the equal offset constraint has
    // been added in the solver.
    std::set<PHV::Bit> prev_bits;
  } eq_offsets;
  using namespace std::placeholders;
  SetConstraints(Equal::CONTAINER,
                 std::bind(&SolverInterface::SetEqualContainer, &solver, _1),
                 std::set<PHV::Bit>());
  SetConstraints(Equal::MAU_GROUP, std::bind(&SolverInterface::SetEqualMauGroup,
                                             &solver, _1, _2),
                 std::set<PHV::Bit>());
  LOG1("Setting bit-offset domains");
  for (auto &b : bit_offset_domain_) {
    solver.SetOffset(b.first, b.second);
    eq_offsets.SetEqualOffset(b.first, equalities_[Equal::OFFSET], solver);
  }
  LOG1("Setting bit-offset ranges");
  for (auto &b : bit_offset_range_) {
    solver.SetOffset(b.first, b.second.first, b.second.second);
    eq_offsets.SetEqualOffset(b.first, equalities_[Equal::OFFSET], solver);
  }
  LOG1("Setting contiguous bits constraints");
  for (auto &bits : contiguous_bits_) {
    CHECK(false == bits.empty()) << ": PHV::Bits is empty";
    const PHV::Bit b1 = bits.front();
    CHECK(bits.size() > 1) << ": Found 1-bit sequence " << b1;
    CHECK(true == b1.IsValid()) << ": First bit in sequence is invalid";
    CHECK(b1 == *(bits.cbegin())) << ": Unexpected first bit " << b1;
    eq_offsets.SetEqualOffset(b1, equalities_[Equal::OFFSET], solver);
    PHV::Bits::const_iterator first = bits.cbegin();
    while (std::next(first, 1) != bits.cend()) {
      PHV::Bits::const_iterator second = std::next(first, 1);
      if (true == second->IsValid()) {
        solver.SetBitDistance(*first, *second, 1);
        eq_offsets.SetEqualOffset(*second, equalities_[Equal::OFFSET], solver);
      }
      std::advance(first, 1);
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
    for (auto &i_hdr_byte : i_hdr) {
      for (auto &e_hdr : deparsed_headers_[1]) {
        for (auto &e_hdr_byte : e_hdr) {
          solver.SetDeparserGroups(i_hdr_byte, e_hdr_byte);
          for (auto &i_pov : deparsed_pov_[0]) {
            solver.SetDeparserGroups(i_pov, e_hdr_byte[0]);
          }
        }
      }
      for (auto &e_pov : deparsed_pov_[1]) {
        solver.SetDeparserGroups(i_hdr_byte[0], e_pov);
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
  // Set container conflicts.
  std::set<std::pair<PHV::Bit, PHV::Bit>> conflicts;
  for (BitId bid = 0; bid < bits_.size(); ++bid) {
    for (BitId bid2 = 0; bid2 < bid; ++bid2) {
      PHV::Bit b1 = bits_.at(bid);
      PHV::Bit b2 = bits_.at(bid2);
      if (true == container_conflicts_.at(bid).at(bid2) &&
          conflicts.count(std::make_pair(b1, b2)) == 0 &&
          conflicts.count(std::make_pair(b2, b1)) == 0) {
        // FIXME: This has to be changed to a compiler error message. The user
        // has probably written a program which imposes conflicting constraints
        // on b1 and b2.
        CHECK(IsEqual(b1, b2, Equal::CONTAINER) == false) <<
          ": Cannot add conflict between " << b1.name() << " and " << b2.name();
        solver.SetContainerConflict(b1, b2);
        // The following code is needed to prevent reporting redundant
        // conflicts. After setting a conflict between b1 and b2, we do not
        // need to set a container conflict between any bits that share a
        // container with b1 and any bits that share a container with b2. So,
        // we add combinations of b1's and b2's container-mates to the reported
        // conflicts set.
        for (auto e1 : GetEqual(b1, Equal::CONTAINER)) {
          for (auto e2 : GetEqual(b2, Equal::CONTAINER)) {
            conflicts.insert(std::make_pair(e1, e2));
          }
        }
      } else if (true == container_conflicts_.at(bid).at(bid2)) {
        LOG3("Ignoring redundant conflict between " << bits_.at(bid) <<
               " and " << bits_.at(bid2));
      }
    }
  }
  for (BitId bid = 0; bid < bits_.size(); ++bid) {
    for (BitId bid2 = 0; bid2 < bid; ++bid2) {
      PHV::Bit b1 = bits_.at(bid);
      PHV::Bit b2 = bits_.at(bid2);
      // A bit-conflict is set in the solver if there wasn't already a
      // container-conflict between the two bits.
      if (true == bit_conflicts_.at(bid).at(bid2) &&
          conflicts.count(std::make_pair(b1, b2)) == 0 &&
          conflicts.count(std::make_pair(b2, b1)) == 0) {
        solver.SetBitConflict(b1, b2);
      }
    }
  }
}

Constraints::BitId Constraints::unique_bit_id(const PHV::Bit &bit) {
  if (uniq_bit_ids_.count(bit) == 0) {
    uniq_bit_ids_.insert(std::make_pair(bit, unique_bit_id_counter_));
    // Check that the initial sizes of all vectors were OK.
    CHECK(bits_.size() == unique_bit_id_counter_);
    CHECK(is_t_phv_.size() == (unique_bit_id_counter_));
    bits_.push_back(bit);
    is_t_phv_.push_back(true);
    // Set the container-conflict vector for the new bit.
    CHECK(container_conflicts_.size() == (unique_bit_id_counter_));
    container_conflicts_.push_back(std::vector<bool>());
    auto &v = container_conflicts_.at(unique_bit_id_counter_);
    v.resize(unique_bit_id_counter_);
    std::fill(v.begin(), v.end(), false);
    // Set the bit-conflict vector for the new bit.
    CHECK(bit_conflicts_.size() == (unique_bit_id_counter_));
    bit_conflicts_.push_back(std::vector<bool>());
    auto &v2 = bit_conflicts_.at(unique_bit_id_counter_);
    v2.resize(unique_bit_id_counter_);
    std::fill(v2.begin(), v2.end(), false);
    CHECK(v.size() == unique_bit_id_counter_) << ": Wrong size " << v.size();
    ++unique_bit_id_counter_;
  }
  return const_cast<const Constraints*>(this)->uniq_bit_ids_.at(bit);
}

Constraints::BitId Constraints::unique_bit_id(const PHV::Bit &bit) const {
  CHECK(uniq_bit_ids_.count(bit) != 0) << ": Cannot find BitId for " << bit;
  return uniq_bit_ids_.at(bit);
}
