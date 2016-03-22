#ifndef _TOFINO_PHV_ORTOOLS_MATCH_XBAR_CONSTRAINT_H_
#define _TOFINO_PHV_ORTOOLS_MATCH_XBAR_CONSTRAINT_H_
#include "backends/tofino/phv/match_xbar_constraint.h"
#include <array>
#include <set>
namespace operations_research {
  class IntVar;
}
class HeaderBits;
class HeaderBit;
namespace ORTools {
class MatchXbarConstraint : public ::MatchXbarConstraint {
 public:
  MatchXbarConstraint(HeaderBits &header_bits) : header_bits_(header_bits) { }
 protected:
  void EnforceConstraint(const std::set<PHV::Bit> &match_bits,
                         const std::array<int, 4> &byte_limits);
 private:
  void
  SetUniqueConstraint(
    std::vector<operations_research::IntVar*> &is_unique_flags,
    const std::vector<HeaderBit*> &phv_bytes,
    const std::array<int, 4> &unique_bytes,
    const std::vector<std::size_t> &byte_offsets) const;
  HeaderBits &header_bits_;
};
}
#endif
