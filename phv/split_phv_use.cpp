#include "split_phv_use.h"

const IR::Node *SplitPhvUse::preorder(IR::Primitive *p) {
    if (p->operands.empty()) return p;
    IR::Vector<IR::Primitive> *rv = nullptr;
    PhvInfo::Field::bitrange bits;
    if (auto field = phv.field(p->operands[0], &bits)) {
        if (field->alloc.size() <= 1) return p;
        LOG3("split " << *p << "into");
        for (auto &alloc : field->alloc) {
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
                operand = new IR::Slice(operand, hi, lo);
            LOG3("   " << *cl);
            rv->push_back(cl); }
        if (rv) return rv; }
    return p;
}

const IR::Node *SplitPhvUse::preorder(IR::Expression *e) {
    PhvInfo::Field::bitrange bits;
    IR::Vector<IR::Expression> *rv = nullptr;
    if (auto field = phv.field(e, &bits)) {
        prune();
        if (field->alloc.size() <= 1) return e;
        LOG3("split " << *e << " into");
        for (auto &alloc : field->alloc) {
            if (alloc.field_bit > bits.hi || alloc.field_hi() < bits.lo)
                continue;
            int lo = alloc.field_bit - bits.lo;
            if (lo < 0) lo = 0;
            int hi = alloc.field_hi() - bits.lo;
            if (hi > bits.hi - bits.lo)
                hi = bits.hi - bits.lo;
            if (lo == 0 && hi == bits.hi - bits.lo) {
                LOG3("-- already split");
                return e; }
            if (getContext()->node->is<IR::Expression>()) {
                /* FIXME -- trying to split a child of an expression -- need to be splitting
                 * that expression, or issuing an error about that expression earlier */
                WARNING("want to split " << *e << " but can't");
                return e; }
            if (!rv) rv = new IR::Vector<IR::Expression>;
            auto *sl = new IR::Slice(e, hi, lo);
            LOG3("   " << *sl);
            rv->push_back(preorder(sl)->to<IR::Expression>());
            assert(rv->back()); }
        if (rv) return rv; }
    return e;
}

const IR::Node *SplitPhvUse::preorder(IR::Slice *sl) {
    if (auto *of = sl->e0->to<IR::Slice>()) {
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
        return preorder(static_cast<IR::Expression *>(sl)); }
}
