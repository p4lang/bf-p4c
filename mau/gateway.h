#ifndef _TOFINO_MAU_GATEWAY_H_
#define _TOFINO_MAU_GATEWAY_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

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
    unsigned            row_limit;
    const PhvInfo::Info *xor_match = nullptr;
    bool preorder(const IR::MAU::Table *tbl) override {
        unsigned row = 0;
        for (auto &gw : tbl->gateway_rows) {
            if (++row > row_limit)
                return false;
            visit(gw.first, "gateway_row"); }
        return false; }
    bool preorder(const IR::Expression *e) override {
        auto finfo = phv.field(e);
        if (!finfo) return true;
        info_t &info = this->info[finfo];
        const Context *ctxt = nullptr;
        info.need_mask = -1;  // FIXME -- should look for mask ops and extract them
        if (auto *rel = findContext<IR::Operation::Relation>(ctxt)) {
            if (!rel->is<IR::Equ>() && !rel->is<IR::Neq>()) {
                info.need_range = true;
            } else if (ctxt->child_index > 0) {
                info.xor_with = xor_match;
            } else {
                xor_match = finfo; } }
        return false; }
    bool preorder(const IR::Primitive *prim) override {
        if (prim->name != "valid") return true;
        if (auto *hdr = prim->operands[0]->to<IR::HeaderRef>())
            valid_offsets[hdr->toString()] = -1;
        else
            Util::CompilationError("valid of non-header: %s", prim);
        return false; }
    void postorder(const IR::Operation::Relation *) override {
        xor_match = nullptr; }

 public:
    struct info_t {
        const PhvInfo::Info     *xor_with = nullptr;
        bool                    need_range = false;
        uint64_t                need_mask = 0;
        int                     offset = -1; };
    map<const PhvInfo::Info *, info_t>        info;
    map<cstring, int>                         valid_offsets;
    int                                       bytes, bits;
    explicit CollectGatewayFields(const PhvInfo &phv, unsigned rl = ~0U)
    : phv(phv), row_limit(rl) {}
    bool compute_offsets();
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
    bool preorder(const IR::Expression *) override;
    bool preorder(const IR::Primitive *) override;
    bool preorder(const IR::LAnd *) override { return true; }
    bool preorder(const IR::LNot *) override { return true; }
    bool preorder(const IR::BAnd *) override { return true; }
    bool preorder(const IR::BOr *) override { return true; }
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::Equ *) override;
    bool preorder(const IR::Geq *) override;
    friend std::ostream &operator<<(std::ostream &, const BuildGatewayMatch &);
    const PhvInfo::Info         *match_field;
    PhvInfo::Info::bitrange     match_field_bits;
    uint64_t                    andmask, ormask;
 public:
    BuildGatewayMatch(const PhvInfo &phv, CollectGatewayFields &f) : phv(phv), fields(f) {
        match.setwidth(fields.bytes*8 + fields.bits); }
};

inline std::ostream &operator<<(std::ostream &out, const BuildGatewayMatch &m) {
    return out << m.match; }

#endif /* _TOFINO_MAU_GATEWAY_H_ */
