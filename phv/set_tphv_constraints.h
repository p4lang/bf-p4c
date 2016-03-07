#ifndef _TOFINO_PHV_SET_TPHV_CONSTRAINTS_H_
#define _TOFINO_PHV_SET_TPHV_CONSTRAINTS_H_
#include "ir/ir.h"
#include "header_bits.h"
#include "phv.h"
#include "backends/tofino/mau/mau_visitor.h"
class SetTPhvConstraints : public MauInspector {
 public:
  SetTPhvConstraints(HeaderBits &header_bits) : header_bits_(header_bits) { }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      auto bit = header_bits_.get(hsr->header_ref()->toString(), i);
      for (int64 j = 0; (nullptr != bit->group()) && j < PHV::kNumMauTPhvGroups;
           ++j) {
        bit->group()->RemoveValue(j + PHV::kMauTPhvGroupOffset);
      }
    }
    return false;
  }
 private:
  HeaderBits &header_bits_;
};
#endif
