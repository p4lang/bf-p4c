#ifndef _TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#define _TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#include "ir/ir.h"
#include "bit_extractor.h"
class Constraints;
class ContainerConstraint : public Inspector, public BitExtractor {
 public:
  ContainerConstraint(Constraints &ec) : equality_constraints_(ec) { }
  bool preorder(const IR::Primitive *prim) override;
 private:
  Constraints &equality_constraints_;
};
#endif
