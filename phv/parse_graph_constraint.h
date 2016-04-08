#ifndef _TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#define _TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#include "tofino/parde/parde_visitor.h"
#include "bit_extractor.h"
class Constraints;
class ParseGraphConstraint : public PardeInspector, public BitExtractor {
 public:
  ParseGraphConstraint(Constraints &c) : constraints_(c) { }
 private:
  bool preorder(const IR::Primitive *prim) override;
  Constraints &constraints_;
};
#endif
