#ifndef _TOFINO_MAU_SPLIT_GATEWAYS_H_
#define _TOFINO_MAU_SPLIT_GATEWAYS_H_

#include "mau_visitor.h"
#include "field_use.h"
#include "gateway.h"

class SpreadGatewayAcrossSeq : public MauTransform, public Backtrack {
    FieldUse    uses;
    bool do_splitting = false;
    struct enable : public Backtrack::trigger { };
    bool backtrack(trigger &trig) override {
        if (!do_splitting && trig.is<enable>()) {
            do_splitting = true;
            return true; }
        return false; }
    Visitor::profile_t init_apply(const IR::Node *) override;
    const IR::Node *postorder(IR::MAU::Table *) override;

};

class SplitComplexGateways : public Transform {
    const PhvInfo       &phv;
    const IR::MAU::Table  *preorder(IR::MAU::Table *tbl) override;
 public:
    explicit SplitComplexGateways(const PhvInfo &phv) : phv(phv) {}
};



#endif /* _TOFINO_MAU_SPLIT_GATEWAYS_H_ */
