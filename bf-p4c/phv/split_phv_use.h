#ifndef _TOFINO_PHV_SPLIT_PHV_USE_H_
#define _TOFINO_PHV_SPLIT_PHV_USE_H_

#include "ir/ir.h"

class PhvInfo;

class SplitPhvUse : public Transform {
    const PhvInfo &phv;
    gress_t     gress;
    const IR::Node *preorder(IR::Tofino::Parser *p) override { gress = p->gress; return p; }
    const IR::Node *preorder(IR::Tofino::Deparser *d) override { gress = d->gress; return d; }
    const IR::Node *preorder(IR::Tofino::Extract *e) override;
    const IR::Node *preorder(IR::Tofino::Emit *e) override;
    const IR::Node *preorder(IR::Expression *p) override;
    const IR::Node *preorder(IR::KeyElement *ke) override { return ke->transform_visit(*this); }
    const IR::Property *preorder(IR::Property *prop) override { prune(); return prop; }
 public:
    explicit SplitPhvUse(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_PHV_SPLIT_PHV_USE_H_ */
