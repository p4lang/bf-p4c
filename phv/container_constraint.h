#ifndef TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#define TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#include <set>
#include "ir/ir.h"
#include "bit_extractor.h"
#include "phv_fields.h"

class Constraints;
class ContainerConstraint : public Inspector, public BitExtractor {
 public:
  ContainerConstraint(const PhvInfo &phv, Constraints &ec) : phv(phv), constraints_(ec) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  const PhvInfo &phv;
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_CONTAINER_CONSTRAINT_H_ */
