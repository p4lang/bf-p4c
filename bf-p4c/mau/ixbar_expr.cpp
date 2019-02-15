#include "ixbar_expr.h"

bool SetupMeterAluHash::preorder(const IR::Concat *c) {
    visit(c->right, "right");
    offset += c->right->type->width_bits();
    visit(c->left, "left");
    return false;
}

bool SetupMeterAluHash::preorder(const IR::Cast *c) {
    auto *from = c->expr->type->to<IR::Type::Bits>();
    auto *to = c->type->to<IR::Type::Bits>();
    visit(c->expr, "expr");
    if (from->isSigned && to->isSigned && to->size > from->size) {
        le_bitrange bits;
        auto *field = phv.field(c->expr, &bits);
        BUG_CHECK(field, "Not a phv ref expression: %s", c);
        // copy the sign bit to sign extend
        for (int bit = from->size; bit < to->size; ++bit) {
            mah.identity_positions[field].emplace_back(offset+bit, field,
                                                       le_bitrange(bits.hi, bits.hi));
            mah.bit_mask.setbit(offset + bit); } }
    return false;
}

bool SetupMeterAluHash::preorder(const IR::BFN::SignExtend *c) {
    auto *from = c->expr->type->to<IR::Type::Bits>();
    auto *to = c->type->to<IR::Type::Bits>();
    visit(c->expr, "expr");
    BUG_CHECK(from->isSigned && to->isSigned && to->size > from->size, "invalid SignExtend %s", c);
    le_bitrange bits;
    auto *field = phv.field(c->expr, &bits);
    BUG_CHECK(field, "Not a phv ref expression: %s", c);
    // copy the sign bit to sign extend
    for (int bit = from->size; bit < to->size; ++bit) {
        mah.identity_positions[field].emplace_back(offset+bit, field,
                                                   le_bitrange(bits.hi, bits.hi));
        mah.bit_mask.setbit(offset + bit); }
    return false;
}

bool SetupMeterAluHash::preorder(const IR::Constant *c) {
    if (c->value != 0) {
        P4C_UNIMPLEMENTED("Can't handle nonzero constant in ixbar identity");
    }
    mah.bit_mask.setrange(offset, c->type->width_bits());
    return false;
}

bool SetupMeterAluHash::preorder(const IR::Expression *e) {
    le_bitrange bits;
    if (auto *field = phv.field(e, &bits)) {
        mah.identity_positions[field].emplace_back(offset, field, bits);
        mah.bit_mask.setrange(offset, bits.size());
    } else {
        BUG("Not a phv ref expression: %s", e);
    }
    return false;
}

bool AdjustIXBarExpression::preorder(IR::MAU::IXBarExpression *e) {
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto &ce : tbl->resources->salu_ixbar.meter_alu_hash.computed_expressions) {
        if (e->expr->equiv(*ce.second)) {
            e->bit = ce.first;
            return false; } }
    for (auto &hdu : tbl->resources->hash_dists) {
        if (e->equiv(*hdu.original_hd->field_list)) {
            // FIXME -- if we do this, the asm generation for the HashDist parent of this node
            // fails, as it uses pointer comparison on the IR::MAU::HashDist nodes, so will fail
            // if any pass after ixbar allocation changes them.  This IXBar expression is the
            // child of such a node, so updating it will violate that.  But since asm generation
            // only cares about the hash dist result (not the actual location in the ixbar hash),
            // we don't need to actually update the IXBarExpression.
#if 0
            e->bit = hdu.use.hash_dist_hash.bit_mask.ffs(0);
#endif
            return false; } }
    BUG("Can't find %s in the ixbar allocation for %s", e->expr, tbl);
    return false;
}

