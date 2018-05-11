#ifndef BF_P4C_MAU_GATEWAY_H_
#define BF_P4C_MAU_GATEWAY_H_

#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/safe_vector.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

class CanonGatewayExpr : public MauTransform {
    IR::MAU::Action *preorder(IR::MAU::Action *af) override { prune(); return af; }
    IR::P4Table *preorder(IR::P4Table *t) override { prune(); return t; }
    IR::Attached *preorder(IR::Attached *a) override { prune(); return a; }
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
    const IR::Node *postorder(IR::MAU::Table *) override;
    class NeedNegate;
};

class CollectGatewayFields : public Inspector {
    const PhvInfo       &phv;
    const IXBar::Use    *ixbar = nullptr;
    unsigned            row_limit = ~0U;   // FIXME -- needed?  only use by SplitComplexGateways
    const PHV::Field   *xor_match = nullptr;    // field on lhs of ==/!= when visiting rhs
    bool preorder(const IR::MAU::Table *tbl) override {
        unsigned row = 0;
        for (auto &gw : tbl->gateway_rows) {
            if (++row > row_limit)
                return false;
            visit(gw.first, "gateway_row"); }
        return false; }
    bool preorder(const IR::Expression *) override;
    void postorder(const IR::Literal *) override;
    void postorder(const IR::Operation::Relation *) override {
        xor_match = nullptr; }

 public:
    struct info_t {
        ordered_set<const PHV::Field *> xor_with;       // {x: x ==/!= this field in gateway } 
        le_bitrange             bits = { -1, -1 };
        bool                    const_eq = false;       // ==/!= with constant
        bool                    need_range = false;     // </>= with constant
        uint64_t                need_mask = 0;
        safe_vector<std::pair<int, le_bitrange>> offsets;
        safe_vector<std::pair<int, le_bitrange>> xor_offsets; };
    ordered_map<const PHV::Field *, info_t>       info;
    ordered_map<const info_t*, cstring>           info_to_uses;
    bool                                          need_range = false;
    int                                           bytes, bits;
    explicit CollectGatewayFields(const PhvInfo &phv, const IXBar::Use *ix = nullptr)
    : phv(phv), ixbar(ix) {}
    CollectGatewayFields(const PhvInfo &phv, unsigned rl) : phv(phv), row_limit(rl) {}
    bool compute_offsets();
    friend std::ostream &operator<<(std::ostream &, const info_t &);
    friend std::ostream &operator<<(std::ostream &, const CollectGatewayFields &);
};

class GatewayRangeMatch : public MauModifier {
    const PhvInfo       &phv;
    void postorder(IR::MAU::Table *) override;
    // optimization -- prune parts of the tree we know can't contain MAU::Tables
    bool preorder(IR::MAU::Action *) override { return false; }
    bool preorder(IR::P4Table *) override { return false; }
    bool preorder(IR::Attached *) override { return false; }
    class SetupRanges;

 public:
    explicit GatewayRangeMatch(const PhvInfo &phv) : phv(phv) {}
};

class CheckGatewayExpr : public Inspector {
    const PhvInfo       &phv;
    bool preorder(const IR::MAU::Table *tbl) override;
    bool preorder(const IR::MAU::Action *) override { return false; }
    bool preorder(const IR::MAU::InputXBarRead *) override { return false; }
    bool preorder(const IR::P4Table *) override { return false; }
    bool preorder(const IR::Attached *) override { return false; }
    bool preorder(const IR::MAU::BackendAttached *) override { return false; }
    bool preorder(const IR::Equ *) override { return true; }
    bool preorder(const IR::Neq *) override { return true; }
    bool preorder(const IR::BAnd *) override { return true; }
    bool preorder(const IR::BOr *) override { return true; }
    bool preorder(const IR::LAnd *) override { return true; }
    bool preorder(const IR::LOr *) override { return true; }
    bool preorder(const IR::LNot *) override { return true; }
    bool preorder(const IR::Literal *) override { return true; }
    bool preorder(const IR::RangeMatch *) override { return true; }
    bool preorder(const IR::Expression *e) override;
    bool preorder(const IR::Operation::Relation *rel) override;

 public:
    explicit CheckGatewayExpr(const PhvInfo &phv) : phv(phv) {}
};

class BuildGatewayMatch : public Inspector {
    const PhvInfo               &phv;
    CollectGatewayFields        &fields;
    match_t                     match;
    safe_vector<int>            range_match;
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
    const PHV::Field           *match_field;
    le_bitrange                 match_field_bits;
    uint64_t                    andmask, ormask;
    int                         shift;
 public:
    BuildGatewayMatch(const PhvInfo &phv, CollectGatewayFields &f);
};

class GatewayOpt : public PassManager {
 public:
    explicit GatewayOpt(const PhvInfo &);
};

#endif /* BF_P4C_MAU_GATEWAY_H_ */
