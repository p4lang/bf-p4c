#ifndef TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#define TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#include <set>
#include "ir/ir.h"
#include "tofino/mau/mau_visitor.h"
#include "bit_extractor.h"
class Constraints;
class ContainerConstraint : public Inspector, public BitExtractor {
 public:
  explicit ContainerConstraint(Constraints &ec) : constraints_(ec) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_CONTAINER_CONSTRAINT_H_ */
