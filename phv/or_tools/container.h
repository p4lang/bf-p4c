#ifndef _TOFINO_PHV_ORTOOLS_CONTAINER_H_
#define _TOFINO_PHV_ORTOOLS_CONTAINER_H_
#include "tofino/phv/phv.h"
#include "ir/ir.h"
namespace operations_research {
class IntExpr;
class IntVar;
class Solver;
}
namespace or_tools {
class MauGroup;
class Container {
 public:
  Container(operations_research::IntVar *cig);
  operations_research::IntVar *
  container_in_group() const { return container_in_group_; }
  void set_container(operations_research::IntExpr *container);
  operations_research::IntExpr *container() const { return container_; }
  operations_research::IntExpr *deparser_group(const gress_t &thread);
  void set_mau_group(MauGroup *mg);
  MauGroup *mau_group() const { return mau_group_; }
  void SetConflict(Container *c);
  // Returns the value assigned to this container by the solver. Must be called
  // only after a solution has been found.
  PHV::Container Value() const;
 private:
  operations_research::IntVar *
  MakeDeparserGroupFlags(
    const std::vector<int> &boundaries,
    std::array<operations_research::IntVar*, PHV::kMaxContainer> *lt);
  operations_research::Solver *solver() const;
  // Container in PHV group of this byte. For Tofino, this has range [0, 15].
  operations_research::IntVar *container_in_group_;
  operations_research::IntExpr *container_;
  // This variable has different domains depending on whether this byte belongs
  // to an ingress or egress thread. For egress, it can take values in the
  // range [0, PHV::kNumDeparserGroups]. For ingress, it can take values
  // greater than PHV::kNumDeparserGroups but cannot take values in
  // PHV::kSharedDeparserGroups.
  operations_research::IntExpr *deparser_group_;
  // This object store MAU group related constraint variables. Container
  // objects that are constrained to the same MAU group must point to the same
  // or_tools::MauGroup object.
  MauGroup *mau_group_;
};
}
#endif
