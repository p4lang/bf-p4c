#ifndef TOFINO_PHV_BIT_EXTRACTOR_H_
#define TOFINO_PHV_BIT_EXTRACTOR_H_
#include <list>
#include <set>
#include "phv.h"
#include "phv_fields.h"

namespace IR {
class Expression;
class HeaderRef;
}

class BitExtractor {
 protected:
  const PhvInfo &phv;
  std::set<std::pair<PHV::Bit, PHV::Bit>>
  GetBitPairs(const IR::Expression *e1, const IR::Expression *e2);
  std::list<PHV::Bit> GetBits(const IR::Expression *e1) const;
  template<class T>
  std::list<PHV::Bit> GetBits(const T &begin, const T &end) {
    std::list<PHV::Bit> rv;
    for (auto it = begin; it != end; ++it) {
      auto new_bits = GetBits(*it);
      rv.insert(rv.end(), new_bits.begin(), new_bits.end()); }
    return rv; }
  std::list<PHV::Byte> GetBytes(const IR::Expression *e1, const IR::Expression *e2 = nullptr);
 public:
  explicit BitExtractor(const PhvInfo &phv) : phv(phv) {}
};
#endif /* TOFINO_PHV_BIT_EXTRACTOR_H_ */
