#include "slice.h"

const IR::Expression *MakeSlice(const IR::Expression *e, int lo, int hi) {
    if (auto k = e->to<IR::Constant>()) {
        return ((*k >> lo) & IR::Constant((1U << (hi-lo+1)) - 1)).clone(); }
    if (lo >= e->type->width_bits()) {
        return new IR::Constant(IR::Type::Bits::get(hi-lo+1), 0); }
    if (hi >= e->type->width_bits())
        hi = e->type->width_bits() - 1;
    if (lo == 0 && hi == e->type->width_bits() - 1)
        return e;
    if (auto sl = e->to<IR::Slice>()) {
        lo += sl->getL();
        hi += sl->getL();
        BUG_CHECK(hi <= sl->getH(), "MakeSlice slice on slice type mismatch");
        e = sl->e0; }
    return new IR::Slice(e, hi, lo);
}
