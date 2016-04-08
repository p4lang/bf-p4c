#ifndef _TOFINO_PHV_SET_WRITE_CONSTRAINTS_H_
#define _TOFINO_PHV_SET_WRITE_CONSTRAINTS_H_
#include "ir/ir.h"
#include "tofino/mau/mau_visitor.h"
#include <set>
namespace operations_research {
  class IntExpr;
  class IntVar;
}
class HeaderBits;
class HeaderBit;
class SetWriteConstraints : public MauInspector {
 public:
  SetWriteConstraints(HeaderBits &header_bits) : header_bits_(header_bits) { }
  bool preorder(const IR::Primitive *primitive) override;
  void postorder(const IR::ActionFunction *action_function) override;
 protected:
  virtual void SetConstraint(HeaderBit *dst1, HeaderBit *src1, HeaderBit *dst2,
                             HeaderBit *src2);
  HeaderBits &header_bits_;
 private:
  typedef std::tuple<operations_research::IntExpr*,
                     operations_research::IntExpr*,
                     operations_research::IntExpr*,
        	     operations_research::IntExpr*> DstSrcPairT;
  std::map<DstSrcPairT, std::pair<HeaderBit*, HeaderBit*>> dst_src_pairs_;
};

class SetEqualDstContainerConstraint : public SetWriteConstraints {
 public:
  SetEqualDstContainerConstraint(HeaderBits &header_bits) :
    SetWriteConstraints(header_bits) { }
  bool is_updated() const { return is_updated_; }
  void reset_updated() { is_updated_ = false; }
  void SetConstraint(HeaderBit *dst1, HeaderBit *src1, HeaderBit *dst2,
                     HeaderBit *src2) override;
 private:
  bool is_updated_;
};
#endif
