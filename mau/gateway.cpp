#include "gateway.h"

const IR::Expression *CanonGatewayExpr::postorder(IR::Operation::Relation *e) {
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Leq *e) {
    if (e->left->is<IR::Constant>())
        return new IR::Geq(e->right, e->left);
    if (auto k = e->right->to<IR::Constant>())
        return new IR::Lss(e->left, new IR::Constant(k->value + 1));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Lss *e) {
    if (auto k = e->left->to<IR::Constant>())
        return new IR::Geq(e->right, new IR::Constant(k->value + 1));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Geq *e) {
    if (auto k = e->left->to<IR::Constant>())
        return new IR::Lss(e->right, new IR::Constant(k->value + 1));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Grt *e) {
    if (e->left->is<IR::Constant>())
        return new IR::Lss(e->right, e->left);
    if (auto k = e->right->to<IR::Constant>())
        return new IR::Geq(e->left, new IR::Constant(k->value + 1));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::LAnd *e) {
    IR::Expression *rv = e;
    if (auto k = e->left->to<IR::Constant>()) {
        return k->value ? e->right : k; }
    if (auto k = e->right->to<IR::Constant>()) {
        return k->value ? e->left : k; }
    while (auto r = e->right->to<IR::LAnd>()) {
        e->left = postorder(new IR::LAnd(e->left, r->left));
        e->right = r->right; }
    if (auto l = e->left->to<IR::LOr>()) {
        if (auto r = e->right->to<IR::LOr>()) {
            auto c1 = postorder(new IR::LAnd(l->left, r->left));
            auto c2 = postorder(new IR::LAnd(l->left, r->right));
            auto c3 = postorder(new IR::LAnd(l->right, r->left));
            auto c4 = postorder(new IR::LAnd(l->right, r->right));
            rv = new IR::LOr(new IR::LOr(new IR::LOr(c1, c2), c3), c4);
        } else {
            auto c1 = postorder(new IR::LAnd(l->left, e->right));
            auto c2 = postorder(new IR::LAnd(l->right, e->right));
            rv = new IR::LOr(c1, c2); }
    } else if (auto r = e->right->to<IR::LOr>()) {
        auto c1 = postorder(new IR::LAnd(e->left, r->left));
        auto c2 = postorder(new IR::LAnd(e->left, r->right));
        rv = new IR::LOr(c1, c2); }
    if (rv != e)
        visit(rv);
    return rv;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::LOr *e) {
    if (auto k = e->left->to<IR::Constant>()) {
        return k->value ? k : e->right; }
    if (auto k = e->right->to<IR::Constant>()) {
        return k->value ? k : e->left; }
    while (auto r = e->right->to<IR::LOr>()) {
        e->left = postorder(new IR::LOr(e->left, r->left));
        e->right = r->right; }
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::LNot *e) {
    IR::Expression *rv = e;
    if (auto a = e->expr->to<IR::LAnd>()) {
        rv = new IR::LOr(new IR::LNot(a), new IR::LNot(a));
    } else if (auto a = e->expr->to<IR::LOr>()) {
        rv = new IR::LAnd(new IR::LNot(a), new IR::LNot(a));
    } else if (auto a = e->expr->to<IR::Equ>()) {
        rv = new IR::Neq(a->left, a->right);
    } else if (auto a = e->expr->to<IR::Neq>()) {
        rv = new IR::Equ(a->left, a->right);
    } else if (auto a = e->expr->to<IR::Leq>()) {
        rv = new IR::Grt(a->left, a->right);
    } else if (auto a = e->expr->to<IR::Lss>()) {
        rv = new IR::Geq(a->left, a->right);
    } else if (auto a = e->expr->to<IR::Geq>()) {
        rv = new IR::Lss(a->left, a->right);
    } else if (auto a = e->expr->to<IR::Grt>()) {
        rv = new IR::Grt(a->left, a->right); }
    if (rv != e)
        visit(rv);
    return rv;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::BAnd *e) {
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e;
}
const IR::Expression *CanonGatewayExpr::postorder(IR::BOr *e) {
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e;
}

const IR::MAU::Table *CanonGatewayExpr::postorder(IR::MAU::Table *tbl) {
    auto &rows = tbl->gateway_rows;
    if (rows.empty() || !rows[0].first)
        return tbl;
    /* split logical-OR operations across rows */
    while (auto *e = rows[0].first->to<IR::LOr>()) {
        auto act = rows[0].second;
        rows[0].first = e->right;
        rows.insert(rows.begin(), std::make_pair(e->left, act)); }
    /* move != to last row and reverse its sense (changing to ==) */
    for (unsigned i = 0; i < rows.size() - 1; i++) {
        if (auto *e = rows[i].first->to<IR::Neq>()) {
            if (!rows[i+1].first) {
                rows[i].first = new IR::Equ(e->left, e->right);
                std::swap(rows[i].second, rows[i+1].second);
            } else if (rows[i+1].second == rows[i].second) {
                std::swap(rows[i].first, rows[i+1].first); } } }
    return tbl;
}
