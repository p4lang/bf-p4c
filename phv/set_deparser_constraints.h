#ifndef _TOFINO_PHV_SET_DEPARSER_CONSTRAINTS_H_
#define _TOFINO_PHV_SET_DEPARSER_CONSTRAINTS_H_
#include "ir/ir.h"
#include "backends/tofino/parde/parde_visitor.h"
#include "phv.h"
#include <array>
#include <map>
namespace operations_research {
  class IntExpr;
}
class HeaderBits;
class SetDeparserConstraints : public PardeInspector {
 public:
  SetDeparserConstraints(HeaderBits &header_bits) : header_bits_(header_bits) {}
  bool preorder(const IR::HeaderSliceRef *hsr) override;
  bool preorder(const IR::Tofino::Parser *) override { return false; }
 private:
  HeaderBits &header_bits_;
  std::set<operations_research::IntExpr*> containers_;
  gress_t first_gress_;
  typedef std::array<operations_research::IntExpr*, PHV::kNumDeparserGroups>
    DeparserFlags;
  std::map<operations_research::IntExpr*, DeparserFlags>
    first_gress_containers_;
};
#endif
