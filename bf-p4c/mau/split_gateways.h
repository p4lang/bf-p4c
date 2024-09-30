#ifndef BF_P4C_MAU_SPLIT_GATEWAYS_H_
#define BF_P4C_MAU_SPLIT_GATEWAYS_H_

#include "mau_visitor.h"
#include "field_use.h"
#include "gateway.h"

class SpreadGatewayAcrossSeq : public MauTransform, public Backtrack {
    FieldUse    uses;
    bool do_splitting = false;
    struct enable : public Backtrack::trigger {
        DECLARE_TYPEINFO(enable);
    };
    bool backtrack(trigger &trig) override {
        if (!do_splitting && trig.is<enable>()) {
            do_splitting = true;
            return true; }
        return false; }
    Visitor::profile_t init_apply(const P4::IR::Node *) override;
    const P4::IR::Node *postorder(P4::IR::MAU::Table *) override;

 public:
    explicit SpreadGatewayAcrossSeq(const PhvInfo& p) : uses(p) { }
};

class SplitComplexGateways : public Transform {
    const PhvInfo       &phv;
    const P4::IR::MAU::Table  *preorder(P4::IR::MAU::Table *tbl) override;
 public:
    explicit SplitComplexGateways(const PhvInfo &phv) : phv(phv) {}
};


#endif /* BF_P4C_MAU_SPLIT_GATEWAYS_H_ */
