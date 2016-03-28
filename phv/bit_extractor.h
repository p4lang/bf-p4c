#ifndef _TOFINO_PHV_BIT_EXTRACTOR_H_
#define _TOFINO_PHV_BIT_EXTRACTOR_H_
#include "phv.h"
#include <list>
#include <set>
namespace IR {
class Expression;
class HeaderSliceRef;
}
class BitExtractor {
 protected:
  std::set<std::pair<PHV::Bit, PHV::Bit>>
  GetBitPairs(const IR::Expression *e1, const IR::Expression *e2);
  std::set<PHV::Bit> GetBits(const IR::Expression *e1) const;
  template<class T>
  std::set<PHV::Bit> GetBits(const T &begin, const T &end) {
    std::set<PHV::Bit> rv;
    for (auto it = begin; it != end; ++it) {
      auto new_bits = GetBits(*it);
      rv.insert(new_bits.begin(), new_bits.end()); }
    return rv; }
  std::list<PHV::Byte>
  GetBytes(const IR::Expression *e1, const IR::Expression *e2 = nullptr);
 private:
  const IR::HeaderSliceRef *header_slice_ref(const IR::Expression *e) const;
};
#endif
