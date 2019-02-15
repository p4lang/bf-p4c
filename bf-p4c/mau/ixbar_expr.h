#ifndef BF_P4C_MAU_IXBAR_EXPR_H_
#define BF_P4C_MAU_IXBAR_EXPR_H_

#include "ir/ir.h"
#include "input_xbar.h"

class CanBeIXBarExpr : public Inspector {
    bool        rv = true;

    static const IR::Type_Extern *externType(const IR::Type *type) {
        if (auto *spec = type->to<IR::Type_SpecializedCanonical>())
            type = spec->baseType;
        return type->to<IR::Type_Extern>(); }

    profile_t init_apply(const IR::Node *n) {
        rv = true;
        return Inspector::init_apply(n); }
    bool preorder(const IR::Node *) { return false; }  // ignore non-expressions
    bool preorder(const IR::Constant *c) {
        if (c->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::Member *m) {
        if (m->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::TempVar *tv) {
        if (tv->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::Slice *sl) {
        if (sl->type->width_bits() > IXBar::MAX_HASH_BITS) {
            rv = false;
        } else if (sl->e0->is<IR::Member>() || sl->e0->is<IR::TempVar>()) {
            // can do a small slice of a field even when whole field would be too big
            return false; }
        return rv; }
    bool preorder(const IR::Concat *c) {
        if (c->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::Cast *c) {
        if (c->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BFN::SignExtend *e) {
        if (e->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BFN::ReinterpretCast *e) {
        if (e->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BXor *e) {
        if (e->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BAnd *e) {
        if (e->type->width_bits() > IXBar::MAX_HASH_BITS) {
            rv = false;
        } else if (!e->left->is<IR::Constant>() && e->right->is<IR::Constant>()) {
            rv = false; }
        return rv; }
    bool preorder(const IR::BOr *e) {
        if (e->type->width_bits() > IXBar::MAX_HASH_BITS) {
            rv = false;
        } else if (!e->left->is<IR::Constant>() && e->right->is<IR::Constant>()) {
            rv = false; }
        return rv; }
    bool preorder(const IR::MethodCallExpression *mce) {
        if (auto *method = mce->method->to<IR::Member>()) {
            if (auto *ext = externType(method->type)) {
                if (ext->name == "Hash" && method->member == "get") {
                    return false; } } }
        return rv = false; }
    // any other expression cannot be an ixbar expression
    bool preorder(const IR::Expression *) { return rv = false; }

 public:
    explicit CanBeIXBarExpr(const IR::Expression *e) { e->apply(*this); }
    explicit operator bool() const { return rv; }
};

class SetupMeterAluHash : public Inspector {
    const PhvInfo               &phv;
    IXBar::Use::MeterAluHash    &mah;
    int                         offset;

    bool preorder(const IR::Concat *) override;
    bool preorder(const IR::Cast *) override;
    bool preorder(const IR::BFN::SignExtend *) override;
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::Expression *) override;

 public:
    SetupMeterAluHash(const PhvInfo &phv, IXBar::Use::MeterAluHash &mah, int start)
    : phv(phv), mah(mah), offset(start) {}
};

class AdjustIXBarExpression : public MauModifier {
    bool preorder(IR::MAU::IXBarExpression *e) override;
};

#endif /* BF_P4C_MAU_IXBAR_EXPR_H_ */
