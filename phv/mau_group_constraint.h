#ifndef TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#define TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
class Constraints;
class MauGroupConstraint : public Inspector, public BitExtractor {
 public:
  explicit MauGroupConstraint(Constraints &ec) : constraints_(ec) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_MAU_GROUP_CONSTRAINT_H_ */
