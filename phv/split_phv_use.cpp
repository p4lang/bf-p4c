#include "split_phv_use.h"

IR::Node *SplitPhvUse::preorder(IR::Primitive *p) {
    if (p->operands.empty()) return p;
    IR::Vector<IR::Primitive> *rv = nullptr;
    PhvInfo::Info::bitrange bits;
    if (auto field = phv.field(p->operands[0], &bits)) {
        if (field->alloc[gress].size() <= 1) return p;
        LOG3("split " << *p << "into");
        for (auto &alloc : field->alloc[gress]) {
            if (alloc.field_bit > bits.hi || alloc.field_hi() < bits.lo)
                continue;
            int lo = alloc.field_bit - bits.lo;
            if (lo < 0) lo = 0;
            int hi = alloc.field_hi() - bits.lo;
            if (hi > bits.hi - bits.lo)
                hi = bits.hi - bits.lo;
            if (lo == 0 && hi == bits.hi - bits.lo) {
                LOG3("-- already split");
                return p; }
            if (!rv) rv = new IR::Vector<IR::Primitive>;
            IR::Primitive *cl = p->clone();
            for (auto &operand : cl->operands)
                operand = preorder(new IR::Slice(operand, hi, lo));
            LOG3("   " << *cl);
            rv->push_back(cl); }
        if (rv) return rv; }
    return p;
}

IR::Node *SplitPhvUse::preorder(IR::HeaderSliceRef *hsr) {
    PhvInfo::Info::bitrange bits;
    IR::Vector<IR::Expression> *rv = nullptr;
    if (auto field = phv.field(hsr, &bits)) {
        if (field->alloc[gress].size() <= 1) return hsr;
        LOG3("split " << *hsr << " into");
        for (auto &alloc : field->alloc[gress]) {
            if (alloc.field_bit > bits.hi || alloc.field_hi() < bits.lo)
                continue;
            int lo = alloc.field_bit - bits.lo;
            if (lo < 0) lo = 0;
            int hi = alloc.field_hi() - bits.lo;
            if (hi > bits.hi - bits.lo)
                hi = bits.hi - bits.lo;
            if (lo == 0 && hi == bits.hi - bits.lo) {
                LOG3("-- already split");
                return hsr; }
            if (getContext()->node->is<IR::Expression>()) {
                /* FIXME -- trying to split a child of an expression -- need to be splitting
                 * that expression, or issuing an error about that expression earlier */
                WARNING("want to split " << *hsr << " but can't");
                return hsr; }
            if (!rv) rv = new IR::Vector<IR::Expression>;
            auto *sl = new IR::Slice(hsr, hi, lo);
            LOG3("   " << *sl);
            rv->push_back(preorder(sl)); }
        if (rv) return rv; }
    return hsr;
}

IR::Expression *SplitPhvUse::preorder(IR::Slice *sl) {
    if (auto *hsr = sl->e0->to<IR::HeaderSliceRef>()) {
        int lo = sl->getL() + hsr->getL();
        int hi = sl->getH() + hsr->getL();
        if (lo > hsr->getH())
            return new IR::Constant(0);
        if (hi > hsr->getH())
            hi = hsr->getH();
        return new IR::HeaderSliceRef(hsr->srcInfo, hsr->header_ref(), hi, lo);
    } else if (auto *of = sl->e0->to<IR::Slice>()) {
        int lo = sl->getL() + of->getL();
        int hi = sl->getH() + of->getL();
        if (lo > of->getH())
            return new IR::Constant(0);
        if (hi > of->getH())
            hi = of->getH();
        return preorder(new IR::Slice(of->srcInfo, of->e0, hi, lo));
    } else if (auto *k = sl->e0->to<IR::Constant>()) {
        int lo = sl->getL();
        int hi = sl->getH();
        return ((*k >> lo) & IR::Constant((1U << (hi-lo+1)) - 1)).clone();
    } else {
        return sl; }
}
