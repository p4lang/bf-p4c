#ifndef _TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#define _TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
class Constraints;
class MauGroupConstraint : public Inspector, public BitExtractor {
 public:
  MauGroupConstraint(Constraints &ec) : constraints_(ec) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif
