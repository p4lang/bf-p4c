#ifndef _TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#define _TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#include "tofino/parde/parde_visitor.h"
#include "bit_extractor.h"
#include <stack>
class Constraints;
class ParseGraphConstraint : public PardeInspector, public BitExtractor {
 public:
  ParseGraphConstraint(Constraints &c) : extracts_(0), extract_widths_({0}), constraints_(c) {
    visitDagOnce = false;}
 private:
  bool preorder(const IR::Primitive *prim) override;
  // Just create a new item in the stack.
  bool preorder(const IR::Tofino::ParserMatch *) override {
    extract_widths_.push(extract_widths_.top());
    return true; }
  void postorder(const IR::Tofino::ParserMatch *pm) override;
  PHV::Bits extracts_;
  std::stack<int> extract_widths_;
  Constraints &constraints_;
};
#endif
