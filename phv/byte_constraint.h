#ifndef _TOFINO_PHV_BYTE_CONSTRAINT_H_
#define _TOFINO_PHV_BYTE_CONSTRAINT_H_
#include "backends/tofino/parde/parde_visitor.h"
#include "bit_extractor.h"
class Constraints;
class ByteConstraint : public PardeInspector, public BitExtractor {
 public:
  ByteConstraint(Constraints &eq_c) : constraints_(eq_c) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  bool preorder(const IR::Tofino::Deparser *dp) override;
  Constraints &constraints_;
};
#endif
