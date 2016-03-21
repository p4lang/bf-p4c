#ifndef _TOFINO_PHV_ORTOOLS_TPHV_CONSTRAINTS_H_
#define _TOFINO_PHV_ORTOOLS_TPHV_CONSTRAINTS_H_
#include "backends/tofino/phv/t_phv_constraint.h"
#include "backends/tofino/phv/header_bits.h"
namespace ORTools {
class TPhvConstraint : public ::TPhvConstraint {
 public:
  TPhvConstraint(HeaderBits &header_bits) : header_bits_(header_bits) { }
  void EnforceConstraint(const PHV::Bit &bit) override {
    for (int64 j = 0; j < PHV::kNumMauTPhvGroups; ++j) {
      HeaderBit *header_bit = header_bits_.get(bit.first, bit.second);
      // FIXME: The call to RemoveValue should not be inside an if-statement.
      // Right now, some standard metadata is not handled properly while
      // creating HeaderBit objects. So, the if-statements needs to be here.
      // Should be changed to assert eventually.
      if (nullptr != header_bit->group()) {
        header_bit->group()->RemoveValue(j + PHV::kMauTPhvGroupOffset);
      }
    }
  }
 private:
  HeaderBits &header_bits_;
};
}
#endif
