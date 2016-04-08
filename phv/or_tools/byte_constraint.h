#ifndef _TOFINO_PHV_ORTOOLS_BYTE_CONSTRAINT_H_
#define _TOFINO_PHV_ORTOOLS_BYTE_CONSTRAINT_H_
#include "backends/tofino/phv/byte_constraint.h"
class HeaderBits;
class EqualityConstraints;
namespace or_tools {
class ByteConstraint : public ::ByteConstraint {
 public:
  explicit ByteConstraint(HeaderBits &header_bits, EqualityConstraints &eq_c) :
    ::ByteConstraint(eq_c), header_bits_(header_bits) { }
  void EnforceConstraint(const PHV::Bit &bit, const int &width,
                         const int &offset);
 private:
  HeaderBits &header_bits_;
};
}
#endif
