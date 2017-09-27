#include "slice.h"

const IR::Expression *MakeSlice(const IR::Expression *e, int lo, int hi) {
    if (e->is<IR::MAU::MultiOperand>())
        return new IR::Slice(e, hi, lo);
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

safe_vector<const IR::Expression *> convertMaskToSlices(const IR::Mask *mask) {
    BUG_CHECK(mask != nullptr, "Cannot convert nullptr IR::Mask");
    safe_vector<const IR::Expression *> slice_vector;

    auto value = mask->right->to<IR::Constant>()->value;
    auto expr = mask->left;
    mp_bitcnt_t zero_pos = 0;
    mp_bitcnt_t one_pos = mpz_scan1(value.get_mpz_t(), zero_pos);
    while (static_cast<size_t>(one_pos)
           < static_cast<size_t>(expr->type->width_bits())) {
        zero_pos = mpz_scan0(value.get_mpz_t(), one_pos);
        auto slice = MakeSlice(mask->left, static_cast<size_t>(one_pos),
                               static_cast<size_t>(zero_pos - 1));
        slice_vector.push_back(slice);
        one_pos = mpz_scan1(value.get_mpz_t(), zero_pos);
    }
    return slice_vector;
}
