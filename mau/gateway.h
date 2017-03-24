#ifndef _TOFINO_MAU_GATEWAY_H_
#define _TOFINO_MAU_GATEWAY_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"
#include "input_xbar.h"

class CanonGatewayExpr : public MauTransform {
    IR::ActionFunction *preorder(IR::ActionFunction *af) override { prune(); return af; }
    IR::V1Table *preorder(IR::V1Table *t) override { prune(); return t; }
    const IR::Expression *postorder(IR::Operation::Relation *) override;
    const IR::Expression *postorder(IR::Leq *) override;
    const IR::Expression *postorder(IR::Lss *) override;
    const IR::Expression *postorder(IR::Geq *) override;
    const IR::Expression *postorder(IR::Grt *) override;
    const IR::Expression *postorder(IR::LAnd *) override;
    const IR::Expression *postorder(IR::LOr *) override;
    const IR::Expression *postorder(IR::LNot *) override;
    const IR::Expression *postorder(IR::BAnd *) override;
    const IR::Expression *postorder(IR::BOr *) override;
    const IR::MAU::Table *postorder(IR::MAU::Table *) override;
    class NeedNegate;
};

class CollectGatewayFields : public Inspector {
    const PhvInfo       &phv;
    const IXBar::Use    *ixbar = nullptr;
    unsigned            row_limit = ~0U;   // FIXME -- needed?  only use by SplitComplexGateways
    const PhvInfo::Field *xor_match = nullptr;
    bool preorder(const IR::MAU::Table *tbl) override {
        unsigned row = 0;
        for (auto &gw : tbl->gateway_rows) {
            if (++row > row_limit)
                return false;
            visit(gw.first, "gateway_row"); }
        return false; }
    bool preorder(const IR::Expression *e) override;
    bool preorder(const IR::Primitive *prim) override;
    void postorder(const IR::Operation::Relation *) override {
        xor_match = nullptr; }

 public:
    typedef PhvInfo::Field::bitrange    bitrange;
    struct info_t {
        const PhvInfo::Field    *xor_with = nullptr;
        bitrange                bits = { -1, -1 };
        bool                    need_range = false;
        uint64_t                need_mask = 0;
        vector<std::pair<int, bitrange>>        offsets; };
    ordered_map<const PhvInfo::Field *, info_t>       info;
    map<cstring, int>                                 valid_offsets;
    bool                                              need_range = false;
    int                                               bytes, bits;
    explicit CollectGatewayFields(const PhvInfo &phv, const IXBar::Use *ix = nullptr)
    : phv(phv), ixbar(ix) {}
    CollectGatewayFields(const PhvInfo &phv, unsigned rl) : phv(phv), row_limit(rl) {}
    bool compute_offsets();
    friend std::ostream &operator<<(std::ostream &, const info_t &);
    friend std::ostream &operator<<(std::ostream &, const CollectGatewayFields &);
};

class GatewayRangeMatch : public MauModifier {
    const PhvInfo       &phv;
    bool preorder(IR::ActionFunction *) override { return false; }
    bool preorder(IR::V1Table *) override { return false; }
    void postorder(IR::MAU::Table *) override;
    class SetupRanges;

 public:
    explicit GatewayRangeMatch(const PhvInfo &phv) : phv(phv) {}
};

class CheckGatewayExpr : public Inspector {
    const PhvInfo       &phv;
    bool preorder(const IR::MAU::Table *tbl) override {
        CollectGatewayFields collect(phv);
        tbl->apply(collect);
        if (!collect.compute_offsets())
            error("%s: condition too complex", tbl->srcInfo);
        return true; }
 public:
    explicit CheckGatewayExpr(const PhvInfo &phv) : phv(phv) {}
};

class BuildGatewayMatch : public Inspector {
    const PhvInfo               &phv;
    CollectGatewayFields        &fields;
    match_t                     match;
    vector<int>                 range_match;
    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::Expression *) override;
    bool preorder(const IR::Primitive *) override;
    bool preorder(const IR::LAnd *) override { return true; }
    bool preorder(const IR::LNot *) override { return true; }
    bool preorder(const IR::BAnd *) override { return true; }
    bool preorder(const IR::BOr *) override { return true; }
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::Equ *) override;
    bool preorder(const IR::RangeMatch *) override;
    friend std::ostream &operator<<(std::ostream &, const BuildGatewayMatch &);
    const PhvInfo::Field        *match_field;
    PhvInfo::Field::bitrange    match_field_bits;
    uint64_t                    andmask, ormask;
    int                         shift;
 public:
    BuildGatewayMatch(const PhvInfo &phv, CollectGatewayFields &f);
};

class GatewayOpt : public PassManager {
 public:
    explicit GatewayOpt(const PhvInfo &);
};

#endif /* _TOFINO_MAU_GATEWAY_H_ */
