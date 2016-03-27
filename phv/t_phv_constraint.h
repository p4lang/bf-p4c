#ifndef _TOFINO_PHV_T_PHV_CONSTRAINT_H_
#define _TOFINO_PHV_T_PHV_CONSTRAINT_H_
#include "ir/ir.h"
#include "phv.h"
#include "constraints.h"
#include "backends/tofino/mau/mau_visitor.h"
// This class inspects every IR::HeaderSliceRef object that appears in IR::MAU
// and and prevents all bits its bits from being allocated to T-PHV.
class TPhvConstraint : public MauInspector {
 public:
  TPhvConstraint(Constraints &c) : constraints_(c) { }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      PHV::Bit bit = PHV::Bit(hsr->header_ref()->toString(), i);
      constraints_.SetNoTPhv(bit);
    }
    return false;
  }
 private:
  Constraints &constraints_;
};
#endif
