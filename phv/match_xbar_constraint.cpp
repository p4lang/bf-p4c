#include "match_xbar_constraint.h"
#include "constraints.h"

namespace {
class GetBits : public Inspector {
 public:
    GetBits(const PhvInfo &phv, std::set<PHV::Bit> &out, const IR::Node *node)
    : phv(phv), out(out) { node->apply(*this); }
    bool preorder(const IR::Expression *e) {
        PhvInfo::Field::bitrange bits;
        if (auto info = phv.field(e, &bits)) {
            for (int i : Range(bits.lo, bits.hi))
                out.insert(info->bit(i));
            return false; }
        return true; }
 private:
    const PhvInfo &phv;
    std::set<PHV::Bit> &out;
};
}  // anonymous namespace

bool MatchXbarConstraint::preorder(const IR::MAU::Table *mau_table) {
    const int stage = mau_table->stage();
    LOG1("Found table " << mau_table->name << " in stage " << stage <<
         " match width " << mau_table->layout.match_width_bits <<
         " and logical ID " << mau_table->logical_id);
    std::set<PHV::Bit> match_bits;
    auto match_table = mau_table->match_table;
    if (match_table && match_table->reads)
        GetBits(phv, match_bits, match_table->reads);
    if (true == mau_table->layout.ternary) {
        if (tcam_match_bits_.size() <= size_t(stage))
            tcam_match_bits_.resize(stage+1);
        tcam_match_bits_.at(stage).insert(match_bits.begin(), match_bits.end());
        match_bits.clear(); }
    for (auto &gw_row : mau_table->gateway_rows)
        GetBits(phv, match_bits, gw_row.first);
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
