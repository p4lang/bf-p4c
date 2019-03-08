#ifndef BF_P4C_MAU_IXBAR_EXPR_H_
#define BF_P4C_MAU_IXBAR_EXPR_H_

#include "ir/ir.h"
#include "input_xbar.h"

class CanBeIXBarExpr : public Inspector {
    bool        rv = true;
    // FIXME -- if we want to run this *before* SimplifyReferences has converted all
    // PathExpressions into the referred to object, we need some way of resolving what the
    // path expressions refer to, or at least whether they refer to something that can be
    // accessed in the ixbar.  So we use this function on a per-use basis.  The default
    // implementation throws a BUG if ever called (as normally we're after SimplifyReferences
    // and all PathExpressions are gone), but in the case where we're before that (calling
    // from CreateSaluInstruction called from AttachTables called from extract_maupipe),
    // we use a functor that can tell a local of the RegisterAction (which can't be in the
    // ixbar) from anything else (which is assumed to be a header or metadata instance.)
    // If we ever clean up the frontend reference handling so we no longer need to resolve
    // names via the refmap, this can go away.  Or if we could do SimplifyRefernces before
    // trying to build StatefulAlu instructions.
    std::function<bool(const IR::PathExpression *)> checkPath;

    static const IR::Type_Extern *externType(const IR::Type *type) {
        if (auto *spec = type->to<IR::Type_SpecializedCanonical>())
            type = spec->baseType;
        return type->to<IR::Type_Extern>(); }

    profile_t init_apply(const IR::Node *n) {
        rv = true;
        return Inspector::init_apply(n); }
    bool preorder(const IR::Node *) { return false; }  // ignore non-expressions
    bool preorder(const IR::PathExpression *pe) {
        if (pe->type->width_bits() > IXBar::MAX_HASH_BITS || !checkPath(pe)) rv = false;
        return false; }
    bool preorder(const IR::Constant *c) {
        if (c->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::Member *m) {
        if (m->type->width_bits() > IXBar::MAX_HASH_BITS) rv = false;
        auto *base = m->expr;
        while ((m = base->to<IR::Member>())) base = m->expr;
        if (auto *pe = base->to<IR::PathExpression>()) {
            if (!checkPath(pe)) rv = false;
        } else if (base->is<IR::HeaderRef>() || base->is<IR::TempVar>()) {
            // ok
        } else {
            rv = false; }
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
    explicit CanBeIXBarExpr(const IR::Expression *e,
                            std::function<bool(const IR::PathExpression *)> checkPath =
        [](const IR::PathExpression *)->bool { BUG("Unexpected path expression"); })
    : checkPath(checkPath) { e->apply(*this); }
    operator bool() const { return rv; }
};

class AdjustIXBarExpression : public MauModifier {
    bool preorder(IR::MAU::IXBarExpression *e) override;
};

#endif /* BF_P4C_MAU_IXBAR_EXPR_H_ */
