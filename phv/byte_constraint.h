#ifndef TOFINO_PHV_BYTE_CONSTRAINT_H_
#define TOFINO_PHV_BYTE_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
#include "phv_fields.h"

class Constraints;
class ByteConstraint : public Inspector, public BitExtractor {
  PhvInfo &phv;
 public:
  ByteConstraint(PhvInfo &phv, Constraints &eq_c) : phv(phv), constraints_(eq_c) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_BYTE_CONSTRAINT_H_ */
