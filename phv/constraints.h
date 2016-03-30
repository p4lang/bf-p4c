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
  void SetEqualByte(const PHV::Bit &bit, const int &offset, const int &width) {
    PHV::Byte byte;
    for (int i = 0; i < width; ++i) {
      byte[offset + i] = PHV::Bit(bit.first, bit.second + i);
    }
    byte_equalities_.insert(byte);
  }
  template<class T> void
  SetEqualByte(const T &begin, const T &end) {
    byte_equalities_.insert(begin, end);
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
  // This function sets is_t_phv_ for bit to false.
  void SetNoTPhv(const PHV::Bit &bit);

  // These functions are used to specify the bits that are used at match keys
  // in TCAM and exact match tables.
  void SetExactMatchBits(const int &stage, const std::set<PHV::Bit> &bits);
  void SetTcamMatchBits(const int &stage, const std::set<PHV::Bit> &bits);

  void SetConstraints(SolverInterface &solver);
  void SetConstraints(const Equal &e, SolverInterface::SetEqual set_equal);
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
  std::map<PHV::Bit, std::pair<int, int>> bit_offset_range_;
  std::map<PHV::Bit, std::vector<int>> bit_offset_domain_;
  // The bits in every PHV::Bits object must be assigned to contiguous offsets.
  // However, they need not be assigned to the same PHV container.
  std::list<PHV::Bits> contiguous_bits_;
  std::array<std::set<std::vector<PHV::Byte>>, 2> deparsed_headers_;
  std::vector<bool> is_t_phv_;
  // TODO: Change these to use BitId instead of PHV::Bit.
  std::array<std::vector<PHV::Bit>, StageUse::MAX_STAGES> exact_match_bits_;
  std::array<std::vector<PHV::Bit>, StageUse::MAX_STAGES> tcam_match_bits_;
  // Helper function to generate/retrieve a unique ID for a bit.
  BitId unique_bit_id_counter_;
  std::map<PHV::Bit, BitId> uniq_bit_ids_;
  std::vector<PHV::Bit> bits_;
  BitId unique_bit_id(const PHV::Bit &bit);
};
template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq);
#endif
