#ifndef _TOFINO_PHV_SPLIT_PHV_USE_H_
#define _TOFINO_PHV_SPLIT_PHV_USE_H_

#include "ir/ir.h"
#include "phv_fields.h"

class SplitPhvUse : public Transform {
    const PhvInfo &phv;
    gress_t     gress;
    IR::Node *preorder(IR::Tofino::Parser *p) override { gress = p->gress; return p; }
    IR::Node *preorder(IR::Tofino::Deparser *d) override { gress = d->gress; return d; }
    IR::Node *preorder(IR::Primitive *p) override;
    IR::Node *preorder(IR::Expression *p) override;
    IR::Node *preorder(IR::Slice *p) override;
 public:
    explicit SplitPhvUse(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_PHV_SPLIT_PHV_USE_H_ */
