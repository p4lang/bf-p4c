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


bool CollectGatewayFields::preorder(const IR::Expression *e) {
    bitrange bits;
    auto finfo = phv.field(e, &bits);
    if (!finfo) return true;
    info_t &info = this->info[finfo];
    const Context *ctxt = nullptr;
    if (info.bits.lo >= 0) {
        if (bits.lo < info.bits.lo) info.bits.lo = bits.lo;
        if (bits.hi > info.bits.hi) info.bits.hi = bits.hi;
    } else {
        info.bits = bits; }
    info.need_mask = -1;  // FIXME -- should look for mask ops and extract them
    if (auto *rel = findContext<IR::Operation::Relation>(ctxt)) {
        if (!rel->is<IR::Equ>() && !rel->is<IR::Neq>()) {
            info.need_range = true;
        } else if (ctxt->child_index > 0) {
            info.xor_with = xor_match;
        } else {
            xor_match = finfo; } }
    return false; }

bool CollectGatewayFields::preorder(const IR::Primitive *prim) {
    if (prim->name != "valid") return true;
    if (auto *hdr = prim->operands[0]->to<IR::HeaderRef>())
        valid_offsets[hdr->toString()] = -1;
    else
        Util::CompilationError("valid of non-header: %s", prim);
    return false; }

bool CollectGatewayFields::compute_offsets() {
    bytes = bits = 0;
    std::vector<decltype(info)::value_type *> sort_by_size;
    for (auto &field : info) {
        sort_by_size.push_back(&field);
        field.second.offsets.clear(); }
    std::sort(sort_by_size.begin(), sort_by_size.end(),
              [](decltype(info)::value_type *a, decltype(info)::value_type *b) -> bool {
                  return a->first->size > b->first->size; });
    for (auto &info : Values(this->info)) {
        if (info.xor_with) {
            auto &with = this->info[info.xor_with];
            info.xor_with->foreach_byte(with.bits, [&](const PhvInfo::Field::alloc_slice &sl) {
                with.offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                info.offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                ++bytes;
            }); } }
    if (bytes > 4) return false;
    for (auto *it : sort_by_size) {
        const PhvInfo::Field &field = *it->first;
        info_t &info = it->second;
        if (!info.offsets.empty()) continue;
        int size = field.container_bytes(info.bits);
        if (ixbar) {
            for (auto &f : ixbar->bit_use) {
                if (f.field == field.name && info.bits.overlaps(f.lo, f.hi())) {
                    auto b = info.bits.intersect(f.lo, f.hi());
                    info.offsets.emplace_back(f.bit + b.lo - f.lo + 32, b);
                    if (f.bit + b.hi - f.lo >= bits)
                        bits = f.bit + b.hi - f.lo + 1; } } }
        if (!info.offsets.empty()) continue;
        if (bytes+size > 4 || info.need_range) {
            info.offsets.emplace_back(bits + 32, info.bits);
            bits += info.bits.size();
        } else {
            field.foreach_byte(info.bits, [&](const PhvInfo::Field::alloc_slice &sl) {
                info.offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                ++bytes;
            }); } }
    if (bytes > 4) return false;
    for (auto &valid : valid_offsets) {
        if (valid.second >= 0) continue;
        const PhvInfo::Field *field = phv.field(valid.first + ".$valid");
        BUG_CHECK(field, "Can't find POV bit for %s", valid.first);
        if (ixbar) {
            for (auto &f : ixbar->bit_use) {
                if (f.field == field->name && f.lo == 0)
                    valid.second = f.bit + 32;
                    if (f.bit >= bits)
                        bits = f.bit + 1;
                    break; } }
        if (valid.second >= 0) continue;
        valid.second = bits++ + 32; }
    return bits <= 12;
}

BuildGatewayMatch:: BuildGatewayMatch(const PhvInfo &phv, CollectGatewayFields &f)
: phv(phv), fields(f) {
    shift = INT_MAX;
    for (auto &info : fields.info)
        for (auto &off : info.second.offsets)
            if (off.first < shift)
                shift = off.first;
    for (auto &off : fields.valid_offsets)
        if (off.second < shift)
            shift = off.second;
}


Visitor::profile_t BuildGatewayMatch::init_apply(const IR::Node *root) {
    match.setwidth(0);  // clear out old value
    match.setwidth(fields.bytes*8 + fields.bits - shift);
    match_field = nullptr;
    andmask = ~0U;
    ormask = 0;
    return Inspector::init_apply(root);
}

bool BuildGatewayMatch::preorder(const IR::Expression *e) {
    PhvInfo::Field::bitrange bits;
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
        auto &field_info = fields.info.at(field);
        auto &match_info = fields.info.at(match_field);
        auto it = field_info.offsets.begin();
        auto end = field_info.offsets.end();
        for (auto &off : match_info.offsets) {
            if (it == end || it->first != off.first || it->second.size() != off.second.size() ||
                it->second.lo - field_info.bits.lo != off.second.lo - match_info.bits.lo) {
                BUG("field equality comparison misaligned in gateway"); }
            uint64_t elmask = ((1U << off.second.size()) - 1) <<
                              (off.second.lo - match_info.bits.lo);
            elmask &= mask;
            int lo = off.first + match_field_bits.lo;
            elmask <<= lo;
            match.word1 &= ~(elmask >> shift);
            ++it; }
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
        match.word1 &= ~(1U << fields.valid_offsets[hdr] >> shift);
    else
        match.word0 &= ~(1U << fields.valid_offsets[hdr] >> shift);
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
        auto &match_info = fields.info.at(match_field);
        for (auto &off : match_info.offsets) {
            uint64_t elmask = ((1U << off.second.size()) - 1) <<
                              (off.second.lo - match_info.bits.lo);
            elmask &= mask;
            int lo = off.first + match_field_bits.lo - shift;
            elmask <<= lo;
            match.word0 &= ~(val << lo) | ~elmask;
            match.word1 &= (val << lo) | ~elmask; }
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
