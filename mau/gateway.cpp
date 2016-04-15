#include "gateway.h"
#include <deque>

class CanonGatewayExpr::NeedNegate : public Inspector {
    bool        rv = false;
    bool preorder(const IR::Neq *) override { rv = true; return false; }

 public:
    explicit NeedNegate(const IR::Expression *e) { e->apply(*this); }
    explicit operator bool() const { return rv; }
};

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
    const IR::Expression *rv = e;
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
    const IR::Expression *rv = e;
    if (auto a = e->expr->to<IR::LAnd>()) {
        rv = new IR::LOr(new IR::LNot(a->left), new IR::LNot(a->right));
    } else if (auto a = e->expr->to<IR::LOr>()) {
        rv = new IR::LAnd(new IR::LNot(a->left), new IR::LNot(a->right));
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
    LOG2("CanonGateway on table " << tbl->name);
    /* split logical-OR operations across rows */
    for (auto it = rows.begin(); it != rows.end(); ++it) {
        LOG3("    " << it->first << " -> " << it->second);
        if (auto *e = dynamic_cast<const IR::LOr *>(it->first)) {
            auto act = it->second;
            it->first = e->right;
            it = rows.emplace(++it, e->left, act); } }
    if (rows.back().first)
        rows.emplace_back(nullptr, cstring());
    std::deque<std::pair<const IR::Expression *, cstring>> need_negate;
    /* move things that need negation to the end and negate them */
    for (auto it = rows.begin(); it != rows.end()-1;) {
        if (NeedNegate(it->first)) {
            need_negate.push_back(*it);
            it = rows.erase(it);
        } else {
            for (auto &n : need_negate) {
                if (n.second != it->second)
                    it->first = new IR::LAnd(it->first, new IR::LNot(n.first)); }
            ++it; } }
    if (need_negate.empty()) return tbl;
    while (!need_negate.empty()) {
        auto &back = rows.back();
        for (auto &n : need_negate) {
            if (n.second == back.second) continue;
            if (back.first)
                back.first = new IR::LAnd(back.first, new IR::LNot(n.first));
            else
                back.first = new IR::LNot(n.first); }
        if (back.first)
            rows.emplace_back(nullptr, need_negate.back().second);
        need_negate.pop_front(); }
    /* reprocess this table in case it has revealed more stuff to be done. */
    for (auto &row : rows)
        visit(row.first);
    return postorder(tbl);
}

bool CollectGatewayFields::compute_offsets() {
    bytes = bits = 0;
    for (auto &field : info)
        field.second.offset = -1;
    for (auto &field : info) {
        if (field.second.xor_with) {
            auto &with = info[field.second.xor_with];
            if (with.offset >= 0 && with.offset != bytes) return false;
            if (with.need_range || field.second.need_range) return false;
            field.second.offset = with.offset = bytes*8;
            bytes += (std::max(field.first->size, field.second.xor_with->size) + 7)/8U; } }
    if (bytes > 4) return false;
    for (auto &field : info) {
        if (field.second.offset >= 0) continue;
        int size = (field.first->size + 7)/8U;
        if (bytes+size > 4 || field.second.need_range) {
            field.second.offset = bits + 32;
            bits += field.first->size;
        } else {
            field.second.offset = bytes*8;
            bytes += size; } }
    for (auto &valid : valid_offsets)
        valid.second = bits++ + bytes*8;
    if (bytes < 4)
        for (auto &field : info)
            if (field.second.offset >= 32)
                field.second.offset -= 8*(4-bytes);
    return bits <= 12;
}

bool BuildGatewayMatch::preorder(const IR::Expression *e) {
    PhvInfo::Info::bitrange bits;
    auto field = phv.field(e, &bits);
    if (!field)
        BUG("Unhandled expression in BuildGatewayMatch: %s", e);
    if (!match_field) {
        match_field = field;
        match_field_bits = bits;
    } else {
        size_t size = std::max(bits.size(), match_field_bits.size());
        uint64_t mask = (1U << size) - 1;
        mask &= andmask & ~ormask;
        int lo = fields.info.at(match_field).offset + match_field_bits.lo;
        if (lo != fields.info.at(field).offset + bits.lo)
            BUG("field equality comparison misaligned in gateway");
        mask <<= lo;
        match.word1 &= ~mask;
        match_field = nullptr; }
    return false;
}

bool BuildGatewayMatch::preorder(const IR::Primitive *prim) {
    if (prim->name != "valid")
        BUG("Unknown primitive in BuildGatewayMatch: %s", prim);
    auto hdr = prim->operands[0]->to<IR::HeaderRef>()->toString();
    if (!fields.valid_offsets.count(hdr))
        BUG("Failed to get valid bit in BuildGatewayMatch");
    if (getContext() && getContext()->node->is<IR::LNot>())
        match.word1 &= ~(1U << fields.valid_offsets[hdr]);
    else
        match.word0 &= ~(1U << fields.valid_offsets[hdr]);
    return false;
}

bool BuildGatewayMatch::preorder(const IR::Constant *c) {
    auto ctxt = getContext();
    if (ctxt->node->is<IR::BAnd>()) {
        andmask = c->asLong();
    } else if (ctxt->node->is<IR::BOr>()) {
        ormask = c->asLong();
    } else if (match_field) {
        uint64_t mask = (1U << match_field_bits.size()) - 1;
        uint64_t val = c->asLong() & mask;
        if ((val & mask & ~andmask) || (~val & mask & ormask))
            BUG("masked comparison in gateway can never match");
        mask &= andmask & ~ormask;
        int lo = fields.info.at(match_field).offset + match_field_bits.lo;
        mask <<= lo;
        val <<= lo;
        match.word0 &= ~val | ~mask;
        match.word1 &= val | ~mask;
        match_field = nullptr;
    } else {
        BUG("Invalid context for constant in BuildGatewayMatch"); }
    return true;
}

bool BuildGatewayMatch::preorder(const IR::Equ *) {
    match_field = nullptr;
    andmask = -1;
    ormask = 0;
    return true;
}
bool BuildGatewayMatch::preorder(const IR::Geq *) {
    WARNING("gateway range matches not implemented");
    match_field = nullptr;
    andmask = -1;
    ormask = 0;
    return true;
}
