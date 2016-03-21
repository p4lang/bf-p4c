#ifndef _TOFINO_PHV_T_PHV_CONSTRAINT_H_
#define _TOFINO_PHV_T_PHV_CONSTRAINT_H_
#include "ir/ir.h"
#include "phv.h"
#include "backends/tofino/mau/mau_visitor.h"
class TPhvConstraint : public MauInspector {
 public:
  bool preorder(const IR::HeaderSliceRef *hsr) {
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      PHV::Bit bit = PHV::Bit(hsr->header_ref()->toString(), i);
      if (tphv_forbidden_bits_.count(bit) == 0) {
        EnforceConstraint(bit);
        tphv_forbidden_bits_.insert(bit);
      }
    }
    return false;
  }
 protected:
  // This function is called for every bit that must NOT be allocated to T-PHV.
  virtual void EnforceConstraint(const PHV::Bit &bit) = 0;
 private:
  std::set<PHV::Bit> tphv_forbidden_bits_;
};
#endif
