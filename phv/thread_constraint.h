#ifndef TOFINO_PHV_THREAD_CONSTRAINT_H_
#define TOFINO_PHV_THREAD_CONSTRAINT_H_

#include "ir/ir.h"
#include "tofino/ir/thread_visitor.h"
#include "bit_extractor.h"
#include "lib/range.h"

class Constraints;
class ThreadConstraint : public Inspector {
    PhvInfo &phv;
    Constraints &constraints;
    std::set<PHV::Bit>  used[2];
    bool preorder(const IR::Expression *e) override {
        PhvInfo::Info::bitrange bits;
        if (auto *i = phv.field(e, &bits)) {
            auto &use = used[VisitingThread(this)];
            for (int bit : Range(bits.lo + i->offset, bits.hi + i->offset))
                use.emplace(i->bitgroup(), bit);
            return false; }
        return true; }
    bool preorder(const IR::HeaderRef *hr) override {
        cstring name = hr->toString();
        auto &use = used[VisitingThread(this)];
        for (int bit : Range(0, hr->type->width_bits() - 1))
            use.emplace(name, bit);
        if (auto *i = phv.field(name + ".$valid"))
            use.emplace(i->bitgroup(), i->offset);
        return false; }
    void end_apply(const IR::Node *) override {
        for (auto &bit1 : used[INGRESS])
            for (auto &bit2 : used[EGRESS])
                constraints.SetContainerConflict(bit1, bit2); }
 public:
    explicit ThreadConstraint(PhvInfo &phv, Constraints &ec) : phv(phv), constraints(ec) { }
};

#endif /* TOFINO_PHV_THREAD_CONSTRAINT_H_ */
