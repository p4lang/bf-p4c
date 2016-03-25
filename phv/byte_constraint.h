#ifndef _TOFINO_PHV_BYTE_CONSTRAINT_H_
#define _TOFINO_PHV_BYTE_CONSTRAINT_H_
#include "backends/tofino/parde/parde_visitor.h"
#include "bit_extractor.h"
class Constraints;
class ByteConstraint : public PardeInspector, public BitExtractor {
 public:
  ByteConstraint(Constraints &eq_c) : equality_constraints_(eq_c) { }
  bool preorder(const IR::Primitive *prim) override;
 private:
  Constraints &equality_constraints_;
};
#endif
