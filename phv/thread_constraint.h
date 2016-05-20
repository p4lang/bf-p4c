#ifndef TOFINO_PHV_THREAD_CONSTRAINT_H_
#define TOFINO_PHV_THREAD_CONSTRAINT_H_

#include "ir/ir.h"
#include "phv_fields.h"

class Constraints;
class ThreadConstraint : public Inspector {
    PhvInfo &phv;
    Constraints &constraints;
    std::set<PHV::Bit>  used[2];
    bool preorder(const IR::Expression *e) override;
    bool preorder(const IR::HeaderRef *hr) override;
    void end_apply(const IR::Node *) override;
 public:
    explicit ThreadConstraint(PhvInfo &phv, Constraints &ec) : phv(phv), constraints(ec) { }
};

#endif /* TOFINO_PHV_THREAD_CONSTRAINT_H_ */
