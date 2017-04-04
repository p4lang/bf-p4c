#include "split_phv_use.h"
#include "tofino/common/slice.h"

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
                operand = MakeSlice(operand, lo, hi);
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
            auto *sl = MakeSlice(e, lo, hi);
            LOG3("   " << *sl);
            rv->push_back(sl);
            assert(rv->back()); }
        if (rv) return rv; }
    return e;
}
