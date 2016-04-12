#ifndef _TOFINO_PHV_SOURCE_CONTAINER_CONSTRAINT_H_
#define _TOFINO_PHV_SOURCE_CONTAINER_CONSTRAINT_H_
#include "phv.h"
#include "ir/ir.h"
#include "tofino/mau/mau_visitor.h"
#include <set>
class Constraints;
// Suppose with have an action A1 with 2 primitives: set(a, b); set(c, d); F1,
// F2, F3, F4 1-bit metadata fields. If F1 and F3 must be assigned to the same
// PHV container due to any other constraints (eg: they are consecutive bits in
// a packet header), then F2 and F4 must also be assigned to the same PHV
// container. This is because of constraints on a PHV's ALU. In addition, if
// another action A2 has the following primitives: set(F2, F5); set (F4, F6); If
// this class visits the IR just once, it will detect that F2 and F4 must go the
// same PHV container. In the second pass of the same IR, it will detect that F5
// and F6 must go to the same PHV container.
class SourceContainerConstraint : public MauInspector {
 public:
  SourceContainerConstraint(Constraints &ec) :
    constraints_(ec), is_updated_(true) { }
  bool is_updated() const { return is_updated_; }
  void reset_updated() { is_updated_ = false; }
 protected:
  std::set<std::pair<PHV::Bit, PHV::Bit>> dst_src_pairs_;
  Constraints &constraints_;
 private:
  bool preorder(const IR::Primitive *primitive) override;
  virtual void postorder(const IR::ActionFunction *af) override;
  bool is_updated_;
};
#endif
