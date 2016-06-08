#include "match_xbar_constraint.h"
#include "constraints.h"
class HeaderSliceRefInspector : public Inspector {
 public:
  explicit HeaderSliceRefInspector(const IR::Node *node) { node->apply(*this); }
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
  auto match_table = mau_table->match_table;
  if ((nullptr != match_table) &&
      (nullptr != match_table->reads)) {
    match_bits = HeaderSliceRefInspector(match_table->reads).match_bits();
  }
  if (true == mau_table->layout.ternary) {
    if (tcam_match_bits_.size() <= size_t(stage))
      tcam_match_bits_.resize(stage+1);
    tcam_match_bits_.at(stage).insert(match_bits.begin(), match_bits.end());
    match_bits.clear();
  }
  for (auto &gw_row : mau_table->gateway_rows) {
    auto new_match_bits = HeaderSliceRefInspector(gw_row.first).match_bits();
    match_bits.insert(new_match_bits.begin(), new_match_bits.end());
  }
  if (exact_match_bits_.size() <= size_t(stage))
    exact_match_bits_.resize(stage+1);
  exact_match_bits_.at(stage).insert(match_bits.begin(), match_bits.end());
  return true;
}

void MatchXbarConstraint::postorder(const IR::Tofino::Pipe *) {
  unsigned i = 0;
  for (auto &mb : tcam_match_bits_)
    constraints_.SetTcamMatchBits(i++, mb);
  i = 0;
  for (auto &mb : exact_match_bits_)
    constraints_.SetExactMatchBits(i++, mb);
}
