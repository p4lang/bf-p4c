#ifndef TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#define TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_
#include <set>
#include "tofino/mau/mau_visitor.h"
#include "ir/ir.h"
#include "phv.h"
#include "phv_fields.h"

class Constraints;
class MatchXbarConstraint : public MauInspector {
 public:
    MatchXbarConstraint(const PhvInfo &phv, Constraints &c) : phv(phv), constraints_(c) { }
    bool preorder(const IR::MAU::Table *mau_table) override;
    void postorder(const IR::Tofino::Pipe *) override;
 private:
    const PhvInfo &phv;
    std::vector<std::set<PHV::Bit>> exact_match_bits_;
    std::vector<std::set<PHV::Bit>> tcam_match_bits_;
    Constraints &constraints_;
};
#endif /* TOFINO_PHV_MATCH_XBAR_CONSTRAINT_H_ */
