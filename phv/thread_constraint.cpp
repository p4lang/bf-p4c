#include "thread_constraint.h"
#include "constraints.h"
#include "lib/range.h"

bool ThreadConstraint::preorder(const IR::Expression *e) {
    PhvInfo::Field::bitrange bits;
    if (auto *f = phv.field(e, &bits)) {
        auto &use = used[VisitingThread(this)];
        for (int i : Range(bits.lo, bits.hi))
            use.insert(f->bit(i));
        return false; }
    return true;
}

bool ThreadConstraint::preorder(const IR::HeaderRef *hr) {
    cstring name = hr->toString();
    auto &use = used[VisitingThread(this)];
    for (int fid : Range(*phv.header(hr))) {
        auto *f = phv.field(fid);
        if (f->size > 0) {
            for (int i : Range(0, f->size-1))
                use.insert(f->bit(i)); } }
    if (auto *f = phv.field(name + ".$valid"))
        use.insert(f->bit(0));
    return false;
}

void ThreadConstraint::end_apply(const IR::Node *) {
    LOG1(used[INGRESS].size() << " live ingress bits, " <<
         used[EGRESS].size() << " live egress bits");
    for (auto &bit1 : used[INGRESS])
        for (auto &bit2 : used[EGRESS])
            constraints.SetContainerConflict(bit1, bit2);
}
