#ifndef TOFINO_PHV_T_PHV_CONSTRAINT_H_
#define TOFINO_PHV_T_PHV_CONSTRAINT_H_
#include "ir/ir.h"
#include "phv.h"
#include "constraints.h"
#include "tofino/mau/mau_visitor.h"
// This class inspects every IR::HeaderSliceRef object that appears in IR::MAU
// and and prevents all bits its bits from being allocated to T-PHV.
class TPhvConstraint : public MauInspector {
 public:
    TPhvConstraint(const PhvInfo &phv, Constraints &c) : phv(phv), constraints_(c) { }
    bool preorder(const IR::Expression *e) {
        PhvInfo::Field::bitrange    bits;
        if (auto f = phv.field(e, &bits)) {
            if (auto prim = findContext<IR::Primitive>())
                LOG2("Setting no T-PHV for " << *prim);
            for (int i = bits.lo; i <= bits.hi; ++i)
                constraints_.SetNoTPhv(f->bit(i));
            return false; }
        return true; }

 private:
    const PhvInfo &phv;
    Constraints &constraints_;
};
#endif /* TOFINO_PHV_T_PHV_CONSTRAINT_H_ */
