#ifndef _TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#define _TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#include "backends/tofino/mau/mau_visitor.h"
#include "backends/tofino/phv/phv.h"
#include <array>
#include <set>
class MatchXbarConstraint : public MauInspector {
 public:
  bool preorder(const IR::MAU::Table *mau_table) override;
  void postorder(const IR::Tofino::Pipe *) override;
 protected:
  virtual void EnforceConstraint(const std::set<PHV::Bit> &exact_match_bits,
                                 const std::array<int, 4> &byte_limits) = 0;
 private:
  std::array<std::set<PHV::Bit>, StageUse::MAX_STAGES> tcam_bits_;
  std::array<std::set<PHV::Bit>, StageUse::MAX_STAGES> exm_bits_;
};
#endif
