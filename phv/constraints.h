#ifndef _TOFINO_PHV_EQUALITY_CONSTRAINTS_H_
#define _TOFINO_PHV_EQUALITY_CONSTRAINTS_H_
#include "backends/tofino/phv/phv.h"
#include "solver_interface.h"
#include <map>
#include <set>
class Constraints {
 public:
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

  void SetConstraints(SolverInterface &solver);
  void SetConstraints(const Equal &e, SolverInterface::SetEqual set_equal);
 private:
  void SetEqual_(const PHV::Bit &bit1, const PHV::Bit &bit2, const Equal &eq);
  std::map<PHV::Bit, std::set<PHV::Bit>> equalities_[NUM_EQUALITIES];
  std::set<PHV::Byte> byte_equalities_;
};
template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq);
#endif
