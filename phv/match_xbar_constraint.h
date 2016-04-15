#ifndef TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#define TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#include <set>
#include "tofino/mau/mau_visitor.h"
#include "ir/ir.h"
#include "phv.h"
class Constraints;
class MatchXbarConstraint : public MauInspector {
 public:
  explicit MatchXbarConstraint(Constraints &c) : constraints_(c) { }
  bool preorder(const IR::MAU::Table *mau_table) override;
  void postorder(const IR::Tofino::Pipe *) override;
 private:
  std::array<std::set<PHV::Bit>, StageUse::MAX_STAGES> exact_match_bits_;
  std::array<std::set<PHV::Bit>, StageUse::MAX_STAGES> tcam_match_bits_;
  Constraints &constraints_;
};
#endif /* TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_ */
