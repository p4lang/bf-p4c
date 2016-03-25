#ifndef _TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#define _TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
class Constraints;
class MauGroupConstraint : public Inspector, public BitExtractor {
 public:
  MauGroupConstraint(Constraints &ec) : equality_constraints_(ec) { }
  bool preorder(const IR::Primitive *prim) override;
 private:
  Constraints &equality_constraints_;
};
#endif
