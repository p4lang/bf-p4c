#include "match_xbar_constraint.h"
class HeaderSliceRefInspector : public Inspector {
 public:
  HeaderSliceRefInspector(const IR::Node *node) { node->apply(*this); }
  bool preorder(const IR::HeaderSliceRef *hsr) {
    for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
      match_bits_.insert(PHV::Bit(hsr->header_ref()->toString(), i));
    }
    return false;
  }
  std::set<PHV::Bit> match_bits() const { return match_bits_; }
 private:
  std::set<PHV::Bit> match_bits_;
};

bool MatchXbarConstraint::preorder(const IR::MAU::Table *mau_table) {
  const int stage = mau_table->stage();
  LOG1("Found table " << mau_table->name << " in stage " << stage <<
         " match width " << mau_table->layout.match_width_bits <<
         " and logical ID " << mau_table->logical_id);
  std::set<PHV::Bit> match_bits;
  if ((nullptr != mau_table->match_table) &&
      (nullptr != mau_table->match_table->reads)) {
    HeaderSliceRefInspector hsri(mau_table->match_table->reads);
    auto new_match_bits = hsri.match_bits();
    match_bits.insert(new_match_bits.begin(), new_match_bits.end());
  }
  if (true == mau_table->layout.ternary) {
    tcam_bits_[stage].insert(match_bits.begin(), match_bits.end());
  }
  else {
    exm_bits_[stage].insert(match_bits.begin(), match_bits.end());
  }
  for (auto &gw_row : mau_table->gateway_rows) {
    HeaderSliceRefInspector hsri(gw_row.first);
    auto new_match_bits = hsri.match_bits();
    exm_bits_[stage].insert(new_match_bits.begin(), new_match_bits.end());
  }
  return true;
}

void MatchXbarConstraint::postorder(const IR::Tofino::Pipe *) {
  for (unsigned stage = 0; stage < StageUse::MAX_STAGES; ++stage) {
    LOG2("Found " << exm_bits_[stage].size() <<
           " exact match bits in stage " << stage);
    LOG2("Found " << tcam_bits_[stage].size() <<
           " ternary match bits in stage " << stage);
    EnforceConstraint(exm_bits_[stage], {{32, 32, 32, 32}});
    EnforceConstraint(tcam_bits_[stage], {{17, 17, 16, 16}});
    exm_bits_[stage].clear();
    tcam_bits_[stage].clear();
  }
}
