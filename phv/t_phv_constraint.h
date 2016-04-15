#ifndef TOFINO_PHV_T_PHV_CONSTRAINT_H_
#define TOFINO_PHV_T_PHV_CONSTRAINT_H_
#include "ir/ir.h"
#include "phv.h"
#include "constraints.h"
#include "tofino/mau/mau_visitor.h"
// This class inspects every IR::HeaderSliceRef object that appears in IR::MAU
// and and prevents all bits its bits from being allocated to T-PHV.
class TPhvConstraint : public MauInspector {
 public:
  explicit TPhvConstraint(Constraints &c) : constraints_(c) { }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    if (auto prim = findContext<IR::Primitive>())
      LOG2("Setting no T-PHV for " << *prim);
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      PHV::Bit bit = PHV::Bit(hsr->header_ref()->toString(), i);
      constraints_.SetNoTPhv(bit);
    }
    return false;
  }
 private:
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_T_PHV_CONSTRAINT_H_ */
