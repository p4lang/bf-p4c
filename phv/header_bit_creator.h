#ifndef TOFINO_PHV_HEADER_BIT_CREATOR_H_
#define TOFINO_PHV_HEADER_BIT_CREATOR_H_
#include "header_bits.h"
#include "ir/ir.h"
class HeaderBitCreator : public Inspector {
 public:
  explicit HeaderBitCreator(HeaderBits &hdr_bits) :
    header_bits_(hdr_bits) {
  }

  bool preorder(const IR::HeaderSliceRef *hsr) override {
    auto header_ref = hsr->header_ref();
    header_bits_.CreateHeader(header_ref->toString(),
                              header_ref->type->width_bits());
    return false;
  }
 private:
  HeaderBits &header_bits_;
};
#endif /* TOFINO_PHV_HEADER_BIT_CREATOR_H_ */
