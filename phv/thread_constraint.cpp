#include "thread_constraint.h"
#include "constraints.h"
#include "lib/range.h"

bool ThreadConstraint::preorder(const IR::Expression *e) {
    PhvInfo::Info::bitrange bits;
    if (auto *i = phv.field(e, &bits)) {
        auto &use = used[VisitingThread(this)];
        for (int bit : Range(bits.lo + i->offset, bits.hi + i->offset))
            use.emplace(i->bitgroup(), bit);
        return false; }
    return true;
}

bool ThreadConstraint::preorder(const IR::HeaderRef *hr) {
    cstring name = hr->toString();
    auto &use = used[VisitingThread(this)];
    for (int bit : Range(0, hr->type->width_bits() - 1))
        use.emplace(name, bit);
    if (auto *i = phv.field(name + ".$valid"))
        use.emplace(i->bitgroup(), i->offset);
    return false;
}

void ThreadConstraint::end_apply(const IR::Node *) {
    LOG1(used[INGRESS].size() << " live ingress bits, " <<
         used[EGRESS].size() << " live egress bits");
    for (auto &bit1 : used[INGRESS])
        for (auto &bit2 : used[EGRESS])
            constraints.SetContainerConflict(bit1, bit2);
}
