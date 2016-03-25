#ifndef _TOFINO_PHV_OFFSET_CONSTRAINT_H_
#define _TOFINO_PHV_OFFSET_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
class Constraints;
class OffsetConstraint : public Inspector, public BitExtractor {
 public:
  OffsetConstraint(Constraints &ec) : equality_constraints_(ec) { }
  bool preorder(const IR::Primitive *prim) override;
 private:
  Constraints &equality_constraints_;
};
#endif
