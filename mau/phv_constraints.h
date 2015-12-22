#ifndef _TOFINO_MAU_PHV_CONSTRAINTS_H_
#define _TOFINO_MAU_PHV_CONSTRAINTS_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

class MauPhvConstraints : public MauInspector {
    PhvInfo     &phv;
    bool preorder(const IR::Primitive *p) override;
    void constraining_op(const IR::Expression *e);
    bool preorder(const IR::Add *e) override { constraining_op(e); return false; }
    bool preorder(const IR::Sub *e) override { constraining_op(e); return false; }
    bool preorder(const IR::Shl *e) override { constraining_op(e); return false; }
    bool preorder(const IR::Shr *e) override { constraining_op(e); return false; }

 public:
    explicit MauPhvConstraints(PhvInfo &p) : phv(p) {}
};

#endif /* _TOFINO_MAU_PHV_CONSTRAINTS_H_ */
