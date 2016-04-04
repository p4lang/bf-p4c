#ifndef _TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#define _TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#include "ir/ir.h"
#include "backends/tofino/mau/mau_visitor.h"
#include "bit_extractor.h"
#include <set>
class Constraints;
class ContainerConstraint : public Inspector, public BitExtractor {
 public:
  ContainerConstraint(Constraints &ec) : constraints_(ec) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif
