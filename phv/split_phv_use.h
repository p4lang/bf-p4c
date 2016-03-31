#ifndef _TOFINO_PHV_SPLIT_PHV_USE_H_
#define _TOFINO_PHV_SPLIT_PHV_USE_H_

#include "ir/ir.h"
#include "phv_fields.h"

class SplitPhvUse : public Transform {
    const PhvInfo &phv;
    gress_t     gress;
    IR::Node *preorder(IR::Tofino::Parser *p) { gress = p->gress; return p; }
    IR::Node *preorder(IR::Tofino::Deparser *d) { gress = d->gress; return d; }
    IR::Node *preorder(IR::Primitive *p) override;
    IR::Node *preorder(IR::HeaderSliceRef *p) override;
    IR::Expression *preorder(IR::Slice *p) override;
 public:
    explicit SplitPhvUse(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_PHV_SPLIT_PHV_USE_H_ */
