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

class SourceContainerConstraint : public MauInspector {
 public:
  SourceContainerConstraint(Constraints &ec) :
    constraints_(ec), is_updated_(true) { }
  bool is_updated() const { return is_updated_; }
  void reset_updated() { is_updated_ = false; }
 private:
  bool preorder(const IR::Primitive *primitive) override;
  void postorder(const IR::ActionFunction *af) override;
  Constraints &constraints_;
  bool is_updated_;
  std::set<std::pair<PHV::Bit, PHV::Bit>> dst_src_pairs_;
};
#endif
