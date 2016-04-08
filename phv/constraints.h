#ifndef _TOFINO_PHV_EQUALITY_CONSTRAINTS_H_
#define _TOFINO_PHV_EQUALITY_CONSTRAINTS_H_
#include "backends/tofino/phv/phv.h"
#include "solver_interface.h"
#include "ir/ir.h"
#include <map>
#include <set>
#include <cstdint>
class Constraints {
 public:
  Constraints() : unique_bit_id_counter_(0) { }
  // This functions modifies the internal data structures to express the
  // constraint that byte must be byte-aligned in a PHV container.
  void SetEqualByte(const PHV::Byte &byte);
  template<class T> void
  SetEqualByte(const T &begin, const T &end) {
    for (auto it = begin; it != end; std::advance(it, 1)) {
      SetEqualByte(*it);
    }
  }

  template<class T> void SetDeparsedHeader(const T &begin, const T &end,
                                           const gress_t gress) {
    deparsed_headers_.at(gress).insert(std::vector<PHV::Byte>(begin, end));
  }

  enum Equal {OFFSET, CONTAINER, MAU_GROUP, NUM_EQUALITIES};
  bool
  IsEqual(const PHV::Bit &bit1, const PHV::Bit &bit2, const Equal &e) const {
    return (equalities_[e].count(bit1) != 0) &&
           (equalities_[e].at(bit1).count(bit2) != 0);
  }
  template<class T>
  void SetEqual(const T &begin, const T &end, const Equal &eq) {
    auto it = (begin == end ? end : std::next(begin, 1));
    for (;it != end; std::advance(it, 1)) SetEqual_(*begin, *it, eq);
  }
  void SetOffset(const PHV::Bit &bit, const int &min, const int &max);
  void SetContiguousBits(const PHV::Bits &bits);
  std::pair<int, bool>
  GetDistance(const PHV::Bit &b1, const PHV::Bit &b2) const;
  // This function sets is_t_phv_ for bit to false.
  void SetNoTPhv(const PHV::Bit &bit);

  // These functions are used to specify the bits that are used at match keys
  // in TCAM and exact match tables.
  void SetExactMatchBits(const int &stage, const std::set<PHV::Bit> &bits);
  void SetTcamMatchBits(const int &stage, const std::set<PHV::Bit> &bits);

  // Sets/get conflict between the two bits.
  void SetContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2);
  bool IsContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2) const;
  void SetBitConflict(const PHV::Bit &b1, const PHV::Bit &b2);

  void SetConstraints(SolverInterface &solver);
  template<class T> void
  SetConstraints(const Equal &e, T set_equal, std::set<PHV::Bit> bits);
 private:
  // This type is used to identify a bit in the internal data structures of
  // this class.
  typedef uint16_t BitId;
  void SetEqual_(const PHV::Bit &bit1, const PHV::Bit &bit2, const Equal &eq);
  // This function return the byte containing b.
  PHV::Byte GetByte(const PHV::Bit &b) const;
  void SetMatchBits(const std::set<PHV::Bit> &bits, std::vector<PHV::Bit> *v);
  // Data structures to store constraints.
  // Each map in the array stores an equality constraint (equality of MAU
  // groups, containers or offsets inside a container). For example, if
  // equalities_[Equal::OFFSET] has an entry ipv4[0] : std::set({inner_ipv4[0],
  // ipv6[0]}), then it means that the first bit of ipv4, inner_ipv4 and ipv6
  // needs to be allocated at the same offset inside a container. However, they
  // need not be allocated to the same container.
  std::map<PHV::Bit, std::set<PHV::Bit>> equalities_[NUM_EQUALITIES];
  std::set<PHV::Byte> byte_equalities_;
  // The 2 std::map objects below store constraints on bits. A bit can contain
  // an entry in either of the 2 maps but not both.
  // This is a bit-to-offset range map. The bit must be allocated an offset
  // within the range (inclusive).
  std::map<PHV::Bit, std::pair<int, int>> bit_offset_range_;
  // The domain of possible offset that a bit can be allocated. The values must
  // be stored in sorted order in the vector.
  std::map<PHV::Bit, std::vector<int>> bit_offset_domain_;
  // The bits in every PHV::Bits object must be assigned to contiguous offsets.
  // However, they need not be assigned to the same PHV container.
  std::list<PHV::Bits> contiguous_bits_;
  // Returns true if all the bits in pbits must be allocated to contiguous bits
  // in a PHV container. False otherwise.
  bool IsContiguous(const PHV::Bits &pbits) const;
  // Each element in this list stores a set of destination-source pairs of an
  // action. This list expresses the single-source PHV container constraint.
  std::list<std::set<std::pair<PHV::Bit, PHV::Bit>>> dst_src_pairs_;
  std::array<std::set<std::vector<PHV::Byte>>, 2> deparsed_headers_;
  // A vector of flags to indicate if a bit can be assigned to T-PHV. This
  // vector is indexed by BitId.
  std::vector<bool> is_t_phv_;
  // TODO: Change these to use BitId instead of PHV::Bit.
  std::array<std::vector<PHV::Bit>, StageUse::MAX_STAGES> exact_match_bits_;
  std::array<std::vector<PHV::Bit>, StageUse::MAX_STAGES> tcam_match_bits_;
  // Conflict matrices: A "true" indicates the the corresponding bits cannot be
  // allocated to the same PHV container/bit. The inner and outer vectors in
  // both conflict matrices are indexed by BitId. Example: If
  // container_conflicts_[i][j] is true, bits_[i] and bits_[j] cannot be
  // allocated to the same PHV container.
  // Two bits can have container conflicts if any of the following conditions
  // are true:
  // 1.They appear in different headers which are deparsed and may appear in
  // the same packet.
  // 2. They are written to (using modify_field) in the same action from two
  // bits which have a container conflict. See case 2 in
  // source_container_constraint.cpp.
  // 3. They appear in a header that is deparsed but they are more than 32b
  // apart in the header.
  // 4. They are written from actions in different tables in the same stage and
  // these tables may match on the same packet.
  std::vector<std::vector<bool>> container_conflicts_;
  std::vector<std::vector<bool>> bit_conflicts_;
  // Helper functions to generate/retrieve a unique ID for a bit.
  BitId unique_bit_id(const PHV::Bit &bit);
  BitId unique_bit_id(const PHV::Bit &bit) const;
  BitId unique_bit_id_counter_;
  std::map<PHV::Bit, BitId> uniq_bit_ids_;
  std::vector<PHV::Bit> bits_;
};
template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq);
#endif
