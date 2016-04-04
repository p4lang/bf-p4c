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
  // The bits are being passed by value since we might need to swap them inside
  // the function body.
  void SetDistance(PHV::Bit b1, PHV::Bit b2, const int &d);
  std::pair<int, bool>
  GetDistance(const PHV::Bit &b1, const PHV::Bit &b2) const;
  // This function sets is_t_phv_ for bit to false.
  void SetNoTPhv(const PHV::Bit &bit);

  // These functions are used to specify the bits that are used at match keys
  // in TCAM and exact match tables.
  void SetExactMatchBits(const int &stage, const std::set<PHV::Bit> &bits);
  void SetTcamMatchBits(const int &stage, const std::set<PHV::Bit> &bits);

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
  // Helper function to generate/retrieve a unique ID for a bit.
  BitId unique_bit_id_counter_;
  std::map<PHV::Bit, BitId> uniq_bit_ids_;
  std::vector<PHV::Bit> bits_;
  BitId unique_bit_id(const PHV::Bit &bit);
  BitId unique_bit_id(const PHV::Bit &bit) const;
};
template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq);
#endif
