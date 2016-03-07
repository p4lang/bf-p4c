#ifndef _TOFINO_PHV_SET_MATCH_XBAR_CONSTRAINTS_H_
#define _TOFINO_PHV_SET_MATCH_XBAR_CONSTRAINTS_H_
#include "backends/tofino/mau/mau_visitor.h"
#include "backends/tofino/mau/resource.h"
#include <array>
#include <set>
namespace operations_research {
  class IntVar;
}
class HeaderBits;
class HeaderBit;
class SetMatchXbarConstraints : public MauInspector {
 public:
  SetMatchXbarConstraints(HeaderBits &header_bits) : header_bits_(header_bits) {
  }
  bool preorder(const IR::MAU::Table *mau_table) override;
  void postorder(const IR::Tofino::Pipe *);
 private:
  void SetUniqueConstraint(const std::set<HeaderBit*> &bits,
                           const std::array<int, 4> &unique_bytes) const;
  void
  SetUniqueConstraint(
    std::vector<operations_research::IntVar*> &is_unique_flags,
    const std::vector<HeaderBit*> &phv_bytes,
    const std::array<int, 4> &unique_bytes,
    const std::vector<std::size_t> &byte_offsets) const;
  std::array<std::set<HeaderBit*>, StageUse::MAX_STAGES> ternary_match_bits_;
  std::array<std::set<HeaderBit*>, StageUse::MAX_STAGES> exact_match_bits_;
  HeaderBits &header_bits_;
};
#endif
