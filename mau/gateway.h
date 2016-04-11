#ifndef _TOFINO_MAU_GATEWAY_H_
#define _TOFINO_MAU_GATEWAY_H_

#include "mau_visitor.h"

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
};

#endif /* _TOFINO_MAU_GATEWAY_H_ */
