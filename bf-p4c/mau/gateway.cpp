#include "gateway.h"
#include <deque>
#include "split_gateways.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"

class CanonGatewayExpr::NeedNegate : public Inspector {
    bool        rv = false;
    bool preorder(const IR::Neq *) override { rv = true; return false; }

 public:
    explicit NeedNegate(const IR::Expression *e) { e->apply(*this); }
    explicit operator bool() const { return rv; }
};

/* FIXME -- should be a global function somewhere */
static bool isSigned(const IR::Type *t) {
    if (auto b = t->to<IR::Type::Bits>())
        return b->isSigned;
    return false;
}

static mpz_class SliceReduce(IR::Operation::Relation *rel, mpz_class val) {
    int slice = 0;
    while (val != 0 && (val & 1) == 0) {
        ++slice;
        val /= 2; }
    if (slice > 0) {
        LOG4("Slicing " << slice << " bits off the bottom of " << rel);
        rel->left = MakeSlice(rel->left, slice, rel->left->type->width_bits() - 1);
        rel->right = new IR::Constant(val);
        LOG4("Now have " << rel); }
    return val;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Operation::Relation *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::Rel " << e);
    // only called for Equ and Neq
    if (e->left->equiv(*e->right))  // if the two sides are the same expression, fold it
        return new IR::BoolLiteral(e->is<IR::Equ>() ? true : false);
    // If comparing with a constant, normalize the condition.
    // However, if both terms are constant, do not swap them, otherwise the IR tree
    // will continuously change, resulting in an infinite loop for GatewayOpt::PassRepeat
    if (e->left->is<IR::Constant>() && !e->right->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Leq *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::Leq " << e);
    if (e->left->equiv(*e->right))  // if the two sides are the same expression, fold it
        return new IR::BoolLiteral(true);
    if (e->left->is<IR::Constant>())
        return postorder(new IR::Geq(e->right, e->left));
    if (auto k = e->right->to<IR::Constant>())
        return postorder(new IR::Lss(e->left, new IR::Constant(k->value + 1)));
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Lss *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::Lss " << e);
    if (e->left->equiv(*e->right))  // if the two sides are the same expression, fold it
        return new IR::BoolLiteral(false);
    if (auto k = e->left->to<IR::Constant>()) {
        BUG_CHECK(!e->right->is<IR::Constant>(), "constant folding failed");
        return postorder(new IR::Geq(e->right, new IR::Constant(k->value + 1))); }
    if (auto k = e->right->to<IR::Constant>()) {
        if (k->value == 0) {
            if (isSigned(e->left->type)) {
                int signbit = e->left->type->width_bits() - 1;
                return new IR::Equ(MakeSlice(e->left, signbit, signbit), new IR::Constant(1));
            } else {
                return new IR::BoolLiteral(false); } }
        if (SliceReduce(e, k->value) == 1 && !isSigned(e->left->type))
            return new IR::Equ(e->left, new IR::Constant(0)); }
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Geq *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::Geq " << e);
    if (e->left->equiv(*e->right))  // if the two sides are the same expression, fold it
        return new IR::BoolLiteral(true);
    if (auto k = e->left->to<IR::Constant>()) {
        BUG_CHECK(!e->right->is<IR::Constant>(), "constant folding failed");
        return postorder(new IR::Lss(e->right, new IR::Constant(k->value + 1))); }
    if (auto k = e->right->to<IR::Constant>()) {
        if (k->value == 0) {
            if (isSigned(e->left->type)) {
                int signbit = e->left->type->width_bits() - 1;
                return new IR::Equ(MakeSlice(e->left, signbit, signbit), new IR::Constant(0));
            } else {
                return new IR::BoolLiteral(true); } }
        if (SliceReduce(e, k->value) == 1 && !isSigned(e->left->type))
            return new IR::Neq(e->left, new IR::Constant(0)); }
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Grt *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::Grt " << e);
    if (e->left->equiv(*e->right))  // if the two sides are the same expression, fold it
        return new IR::BoolLiteral(false);
    if (e->left->is<IR::Constant>())
        return postorder(new IR::Lss(e->right, e->left));
    if (auto k = e->right->to<IR::Constant>())
        return postorder(new IR::Geq(e->left, new IR::Constant(k->value + 1)));
    return e;
}

/// Simplify as fast as possible to avoid expansion when going between deMorgan
/// and distribution
const IR::Expression *CanonGatewayExpr::preorder(IR::LAnd *e) {
    if (e->left->equiv(*e->right))
        return e->left;
    if (auto k = e->left->to<IR::Constant>())
        return k->value ? e->right : k;
    if (auto k = e->left->to<IR::BoolLiteral>())
        return k->value ? e->right : k;
    if (auto k = e->right->to<IR::Constant>())
        return k->value ? e->left : k;
    if (auto k = e->right->to<IR::BoolLiteral>())
        return k->value ? e->left : k;
    return e;
}

const IR::Expression *CanonGatewayExpr::preorder(IR::LOr *e) {
    if (e->left->equiv(*e->right))
        return e->left;
    if (auto k = e->left->to<IR::Constant>())
        return k->value ? k : e->right;
    if (auto k = e->left->to<IR::BoolLiteral>())
        return k->value ? k : e->right;
    if (auto k = e->right->to<IR::Constant>())
        return k->value ? k : e->left;
    if (auto k = e->right->to<IR::BoolLiteral>())
        return k->value ? k : e->left;
    return e;
}

const IR::Expression *CanonGatewayExpr::preorder(IR::LNot *e) {
    if (auto a = e->expr->to<IR::LNot>()) {
        LOG5(_debugIndent << "r IR::LNot " << e);
        return a->expr;
    }
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::LAnd *e) {
    if (isVisited(e)) return e;
    LOG5(_debugIndent << "IR::LAnd " << e);
    _debugIndent++;
    addVisited(e);
    const IR::Expression *rv = e;
    if (e->left->equiv(*e->right))
        return e->left;
    if (auto k = e->left->to<IR::Constant>())
        return k->value ? e->right : k;
    if (auto k = e->left->to<IR::BoolLiteral>())
        return k->value ? e->right : k;
    if (auto k = e->right->to<IR::Constant>())
        return k->value ? e->left : k;
    if (auto k = e->right->to<IR::BoolLiteral>())
        return k->value ? e->left : k;
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
            LOG5(_debugIndent << "? IR::LAnd " << rv);
        } else {
            auto c1 = postorder(new IR::LAnd(l->left, e->right));
            auto c2 = postorder(new IR::LAnd(l->right, e->right));
            rv = new IR::LOr(c1, c2); }
        LOG5(_debugIndent << "/ IR::LAnd " << rv);
    } else if (auto r = e->right->to<IR::LOr>()) {
        auto c1 = postorder(new IR::LAnd(e->left, r->left));
        auto c2 = postorder(new IR::LAnd(e->left, r->right));
        rv = new IR::LOr(c1, c2);
        LOG5(_debugIndent << "* IR::LAnd " << rv);
    }
    if (rv != e)
        visit(rv);
    _debugIndent--;
    LOG5(_debugIndent << "- IR::LAnd " << rv);
    return rv;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::LOr *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::LOr " << e);
    _debugIndent++;
    if (e->left->equiv(*e->right))
        return e->left;
    if (auto k = e->left->to<IR::Constant>())
        return k->value ? k : e->right;
    if (auto k = e->left->to<IR::BoolLiteral>())
        return k->value ? k : e->right;
    if (auto k = e->right->to<IR::Constant>())
        return k->value ? k : e->left;
    if (auto k = e->right->to<IR::BoolLiteral>())
        return k->value ? k : e->left;
    while (auto r = e->right->to<IR::LOr>()) {
        e->left = postorder(new IR::LOr(e->left, r->left));
        e->right = r->right; }
    _debugIndent--;
    LOG5(_debugIndent << "-IR::LOr " << e);
    return e;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::LNot *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    LOG5(_debugIndent << "IR::LNot " << e);
    _debugIndent++;
    const IR::Expression *rv = e;
    if (auto a = e->expr->to<IR::LNot>()) {
        LOG5(_debugIndent << "r IR::LNot " << e);
        _debugIndent--;
        return a->expr;
    }
    if (auto a = e->expr->to<IR::LAnd>()) {
        rv = new IR::LOr(postorder(new IR::LNot(a->left)), postorder(new IR::LNot(a->right)));
    } else if (auto a = e->expr->to<IR::LOr>()) {
        rv = new IR::LAnd(postorder(new IR::LNot(a->left)), postorder(new IR::LNot(a->right)));
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
    _debugIndent--;
    LOG5(_debugIndent << "-IR::LNot " << rv);
    return rv;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::BAnd *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e;
}
const IR::Expression *CanonGatewayExpr::postorder(IR::BOr *e) {
    if (isVisited(e)) return e;
    addVisited(e);
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e;
}

const IR::Node *CanonGatewayExpr::postorder(IR::MAU::Table *tbl) {
    // reset the visited expressions for every new condition.
    // Each condition is associated with a Gateway table.
    resetVisited();

    auto &rows = tbl->gateway_rows;
    if (rows.empty() || !rows[0].first)
        return tbl;
    LOG2("CanonGateway on table " << tbl->name);
    // Remove rows that can never match because they're after a row that always matches,
    // or because their condition is 'false'.  While doing that, track the next tags
    // that we remove and keep.
    bool erase_rest = false;
    std::set<cstring>   removed, present;  // next tags in the table from the gateway
    for (auto row = rows.begin(); row != rows.end();) {
        if (erase_rest) {
            removed.insert(row->second);
            row = rows.erase(row);
        } else if (!row->first) {
            erase_rest = true;
            present.insert(row->second);
            ++row;
        } else if (auto k = row->first->to<IR::Constant>()) {
            if (k->value == 0) {
                removed.insert(row->second);
                row = rows.erase(row);
            } else {
                row->first = nullptr; }
        } else if (auto k = row->first->to<IR::BoolLiteral>()) {
            if (k->value == 0) {
                removed.insert(row->second);
                row = rows.erase(row);
            } else {
                row->first = nullptr; }
        } else {
            present.insert(row->second);
            ++row; } }
    // If we removed ALL gateway rows that refer to a next tag, remove that tag from
    // next, as it's unreachable.  This relies on the fact that gateway next tags and
    // action next tags are always disjoint.
    for (auto next_tag : removed)
        if (!present.count(next_tag))
            tbl->next.erase(next_tag);
    if (rows.empty() || !rows[0].first) {
        if (tbl->gateway_only()) {
            LOG3("eliminating completely dead gateway-only table " << tbl->name);
            if (!rows.empty() && tbl->next.count(rows.front().second))
                return &tbl->next.at(rows.front().second)->tables;
            return nullptr; }
        return tbl; }
    /* split logical-OR operations across rows */
    for (auto it = rows.begin(); it != rows.end(); ++it) {
        LOG3("    " << it->first << " -> " << it->second);
        while (auto *e = dynamic_cast<const IR::LOr *>(it->first)) {
            auto act = it->second;
            it->first = e->left;
            it = rows.emplace(++it, e->right, act);
            --it; } }
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

bool CollectGatewayFields::preorder(const IR::MAU::Table *tbl) {
    unsigned row = 0;
    if (tbl->uses_gateway())
        LOG5("CollectGatewayFields for table " << tbl->name);
    for (auto &gw : tbl->gateway_rows) {
        if (++row > row_limit)
            return false;
        visit(gw.first, "gateway_row"); }
    return false;
}

bool CollectGatewayFields::preorder(const IR::Expression *e) {
    boost::optional<cstring> aliasSourceName = phv.get_alias_name(e);
    le_bitrange bits;
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
    if (findContext<IR::RangeMatch>()) {
        info.need_range = need_range = true;
    } else if (auto *rel = findContext<IR::Operation::Relation>(ctxt)) {
        if (!rel->is<IR::Equ>() && !rel->is<IR::Neq>()) {
            info.need_range = need_range = true;
        } else if (ctxt->child_index > 0) {
            if (xor_match)
                info.xor_with.insert(xor_match);
            else
                info.const_eq = true;
        } else {
            xor_match = finfo; }
    } else {
        info.const_eq = true; }
    if (aliasSourceName != boost::none) {
        info_to_uses[&info] = *aliasSourceName;
        LOG5("Adding entry to info_to_uses: " << &info << " : " << *aliasSourceName);
    }
    return false;
}

void CollectGatewayFields::postorder(const IR::Literal *) {
    if (xor_match && getParent<IR::Operation::Relation>())
        info[xor_match].const_eq = true;
}

bool CollectGatewayFields::compute_offsets() {
    LOG5("CollectGatewayFields::compute_offsets");
    bytes = bits = 0;
    std::vector<decltype(info)::value_type *> sort_by_size;
    for (auto &field : info) {
        sort_by_size.push_back(&field);
        field.second.offsets.clear();
        field.second.xor_offsets.clear(); }
    std::sort(sort_by_size.begin(), sort_by_size.end(),
              [](decltype(info)::value_type *a, decltype(info)::value_type *b) -> bool {
                  return a->first->size > b->first->size; });
    for (auto &i : this->info) {
        auto *field = i.first;
        auto &info = i.second;
        for (auto xor_with : info.xor_with) {
            auto &with = this->info[xor_with];
            xor_with->foreach_byte(with.bits, [&](const PHV::Field::alloc_slice &sl) {
                with.offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                info.xor_offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                LOG5("  byte " << bytes << " " << sl << " " << field->name << " xor " <<
                     xor_with->name);
                ++bytes;
            }); } }
    if (bytes > 4) return false;
    for (auto *it : sort_by_size) {
        const PHV::Field &field = *it->first;
        info_t &info = it->second;
        if (!info.need_range && !info.const_eq) continue;
        int size = field.container_bytes(info.bits);
        if (ixbar) {
            bool done = false;
            for (auto &f : ixbar->bit_use) {
                if (f.field == field.name && info.bits.overlaps(f.lo, f.hi())) {
                    auto b = info.bits.unionWith(f.lo, f.hi());
                    info.offsets.emplace_back(f.bit + b.lo - f.lo + 32, b);
                    LOG5("  bit " << f.bit + b.lo - f.lo + 32 << " " << field.name);
                    done = true;
                    if (f.bit + b.hi - f.lo >= bits)
                        bits = f.bit + b.hi - f.lo + 1; } }
            if (done) continue; }
        if (bytes+size > 4 || info.need_range) {
            info.offsets.emplace_back(bits + 32, info.bits);
            LOG5("  bit " << bits + 32 << " " << field.name);
            bits += info.bits.size();
        } else {
            field.foreach_byte(info.bits, [&](const PHV::Field::alloc_slice &sl) {
                info.offsets.emplace_back(bytes*8U + sl.container_bit%8U, sl.field_bits());
                LOG5("  byte " << bytes << " " << sl << " " << field.name);
                ++bytes;
            }); } }
    if (bytes > 4) return false;
    return bits <= 12;
}

class GatewayRangeMatch::SetupRanges : public Transform {
    const PhvInfo               &phv;
    const CollectGatewayFields  &fields;
    IR::MAU::Action *preorder(IR::MAU::Action *af) override { prune(); return af; }
    IR::P4Table *preorder(IR::P4Table *t) override { prune(); return t; }
    IR::Attached *preorder(IR::Attached *a) override { prune(); return a; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) override { prune(); return s; }

    const IR::Expression *postorder(IR::Operation::Relation *rel) override {
        le_bitrange bits;
        auto f = phv.field(rel->left, &bits);
        if (!f || !rel->right->is<IR::Constant>() || !fields.info.count(f)) return rel;
        LOG3("SetupRange for " << rel);
        bool forceRange = !(rel->is<IR::Equ>() || rel->is<IR::Neq>());
        bool reverse = (rel->is<IR::Geq>() || rel->is<IR::Neq>());
        auto info = fields.info.at(f);
        long val = rel->right->to<IR::Constant>()->asLong();
        BUG_CHECK(!forceRange || (val & 1), "Non-canonicalized range value");
        int base = 0;
        int orig_lo = bits.lo;
        for (auto &alloc : info.offsets) {
            if (alloc.first < 32) {
                if (!forceRange && alloc.second.hi <= bits.lo) {
                    val >>= (bits.lo - alloc.second.hi + 1);
                    bits.lo = alloc.second.hi + 1;
                    if (bits.lo > bits.hi) {
                        LOG4("  all bits in lower 32, skipping");
                        return rel; } }
                continue; }
            if (!alloc.second.overlaps(bits)) continue;
            BUG_CHECK(base == 0, "bits for %s split in range match", f->name);
            base = alloc.first + bits.lo - alloc.second.lo;
            BUG_CHECK(base >= 32 && base + bits.size() <= alloc.first + alloc.second.size(),
                      "bad gateway field layout for range match");
            break; }
        if (!base) return rel;
        if (base & 3) {
            bits.lo -= base & 3;
            val <<= base & 3;
            base &= ~3; }
        bits.lo -= orig_lo;
        bits.hi -= orig_lo;
        const IR::Expression *rv = nullptr, *himatch = nullptr;
        LOG5("  bits = " << bits);
        for (int lo = ((bits.hi - bits.lo) & ~3) + bits.lo; lo >= bits.lo; lo -= 4) {
            int hi = std::min(lo + 3, bits.hi);
            unsigned data = 1U << ((val >> (lo - bits.lo)) & 0xf);
            const IR::Expression *eq, *c;
            eq = new IR::RangeMatch(MakeSlice(rel->left, std::max(0, lo), hi), data);
            if (forceRange) --data;
            if (reverse) {
                data ^= 0xffff;
                if (forceRange && lo != bits.lo)
                    data = (data << 1) & 0xffff; }
            c = new IR::RangeMatch(MakeSlice(rel->left, std::max(0, lo), hi), data);
            if (forceRange)
                c = himatch ? new IR::LAnd(himatch, c) : c;
            if (rv) {
                if (forceRange || reverse)
                    rv = new IR::LOr(rv, c);
                else
                    rv = new IR::LAnd(rv, c);
            } else {
                rv = c; }
            himatch = himatch ? new IR::LAnd(himatch, eq) : eq; }
        LOG3("SetupRange result: " << rv);
        return rv;
    }

 public:
    SetupRanges(const PhvInfo &phv, const CollectGatewayFields &fields)
    : phv(phv), fields(fields) {}
};

void GatewayRangeMatch::postorder(IR::MAU::Table *tbl) {
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (!collect.need_range) return;
    if (!collect.compute_offsets()) return;
    SetupRanges setup(phv, collect);
    for (auto &gw : tbl->gateway_rows)
        if (gw.first) gw.first = gw.first->apply(setup);
}

bool CheckGatewayExpr::preorder(const IR::MAU::Table *tbl) {
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (!collect.compute_offsets())
        error("%s: condition too complex, limit of 4 bytes + 12 bits of PHV input exceeded",
              tbl->srcInfo);
    return true;
}

bool CheckGatewayExpr::preorder(const IR::Expression *e) {
    if (!phv.field(e))
        error("%s: condition expression too complex", e->srcInfo);
    return false;
}

bool CheckGatewayExpr::preorder(const IR::Operation::Relation *rel) {
    if (!rel->right->is<IR::Constant>()) {
        error("%s: condition too complex, one operand must be constant",
              rel->srcInfo);
        return false; }
    return true;
}

BuildGatewayMatch::BuildGatewayMatch(const PhvInfo &phv, CollectGatewayFields &f)
: phv(phv), fields(f) {
    shift = INT_MAX;
    for (auto &info : fields.info)
        for (auto &off : info.second.offsets)
            if (off.first < shift)
                shift = off.first;
}

Visitor::profile_t BuildGatewayMatch::init_apply(const IR::Node *root) {
    LOG3("BuildGatewayMatch for " << root);
    match.setwidth(0);  // clear out old value
    if (fields.need_range || !fields.bits) {
        if (fields.bytes)
            match.setwidth(fields.bytes*8 - shift);
    } else {
        match.setwidth(32 + fields.bits - shift); }
    range_match.clear();
    match_field = nullptr;
    andmask = ~0ULL;
    ormask = 0;
    return Inspector::init_apply(root);
}

bool BuildGatewayMatch::preorder(const IR::Expression *e) {
    le_bitrange bits;
    auto field = phv.field(e, &bits);
    if (!field)
        BUG("Unhandled expression in BuildGatewayMatch: %s", e);
    if (!match_field) {
        match_field = field;
        match_field_bits = bits;
        LOG4("  match_field = " << field->name << ' ' << bits);
        if (bits.size() == 1 && !getParent<IR::Operation::Relation>()) {
            auto &match_info = fields.info.at(match_field);
            LOG4("  match_info = " << match_info);
            for (auto &off : match_info.offsets) {
                if (getParent<IR::LNot>())
                    match.word1 &= ~(1ULL << off.first >> shift);
                else
                    match.word0 &= ~(1ULL << off.first >> shift); } }
    } else {
        LOG4("  xor_field = " << field->name << ' ' << bits);
        size_t size = std::max(bits.size(), match_field_bits.size());
        uint64_t mask = (1ULL << size) - 1, donemask = 0;
        mask &= andmask & ~ormask;
        mask <<= match_field_bits.lo;
        auto &field_info = fields.info.at(field);
        auto &match_info = fields.info.at(match_field);
        LOG4("  match_info = " << match_info << ", mask=0x" << hex(mask) << " shift=" << shift);
        LOG4("  xor_match_info = " << field_info);
        auto it = field_info.xor_offsets.begin();
        auto end = field_info.xor_offsets.end();
        for (auto &off : match_info.offsets) {
            while (it != end && it->first < off.first) ++it;
            if (it == end) break;
            if (off.first < it->first) continue;
            if (it->first != off.first || it->second.size() != off.second.size() ||
                it->second.lo - field_info.bits.lo != off.second.lo - match_info.bits.lo) {
                BUG("field equality comparison misaligned in gateway"); }
            uint64_t elmask = ((1ULL << off.second.size()) - 1) << off.second.lo;
            if ((elmask &= mask) == 0) continue;
            int shft = off.first - off.second.lo - shift;
            LOG6("    elmask=0x" << hex(elmask) << " shft=" << shft);
            if (shft >= 0)
                match.word1 &= ~(elmask << shft);
            else
                match.word1 &= ~(elmask >> -shft);
            LOG6("    match now " << match);
            donemask |= mask;
            if (++it == end) break; }
        BUG_CHECK(mask == donemask, "failed to match all bits of %s",
                  findContext<IR::Operation::Relation>());
        match_field = nullptr; }
    return false;
}

bool BuildGatewayMatch::preorder(const IR::Primitive *) {
    return false;
}

bool BuildGatewayMatch::preorder(const IR::Constant *c) {
    auto ctxt = getContext();
    if (ctxt->node->is<IR::BAnd>()) {
        andmask = c->asLong();
        LOG4("  andmask = 0x" << hex(andmask));
    } else if (ctxt->node->is<IR::BOr>()) {
        ormask = c->asLong();
        LOG4("  ormask = 0x" << hex(ormask));
    } else if (match_field) {
        uint64_t mask = (1ULL << match_field_bits.size()) - 1;
        uint64_t val = c->asLong() & mask;
        if ((val & mask & ~andmask) || (~val & mask & ormask))
            BUG("masked comparison in gateway can never match");
        mask &= andmask & ~ormask;
        mask <<= match_field_bits.lo;
        val <<= match_field_bits.lo;
        auto &match_info = fields.info.at(match_field);
        LOG4("  match_info = " << match_info << ", val=" << val << " mask=0x" << hex(mask) <<
             " shift=" << shift);
        for (auto &off : match_info.offsets) {
            uint64_t elmask = ((1ULL << off.second.size()) - 1) << off.second.lo;
            if ((elmask &= mask) == 0) continue;
            int shft = off.first - off.second.lo - shift;
            LOG6("    elmask=0x" << hex(elmask) << " shft=" << shft);
            if (shft >= 0) {
                match.word0 &= ~(val << shft) | ~(elmask << shft);
                match.word1 &= (val << shft) | ~(elmask << shft);
            } else {
                match.word0 &= ~(val >> -shft) | ~(elmask >> -shft);
                match.word1 &= (val >> -shft) | ~(elmask >> -shft); }
            LOG6("    match now " << match); }
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
bool BuildGatewayMatch::preorder(const IR::RangeMatch *rm) {
    le_bitrange bits;
    auto field = phv.field(rm->expr, &bits);
    BUG_CHECK(field, "invalid RangeMatch in BuildGatewayMatch");
    int unit = -1;
    for (auto &alloc : fields.info.at(field).offsets) {
        if (alloc.first < 32 || !alloc.second.overlaps(bits))
            continue;
        unit = (alloc.first + bits.lo - alloc.second.lo - 32) / 4;
        BUG_CHECK(unit == (alloc.first + bits.hi - alloc.second.lo - 32) / 4,
                  "RangeMatch source (%s) misaligned at %d..%d", rm->expr,
                  alloc.first + bits.lo - alloc.second.lo, alloc.first + bits.lo - alloc.second.lo);
        break; }
    BUG_CHECK(unit >= 0 && unit < 3, "invalid RangeMatch unit %d", unit);
    LOG4("RangeMatch " << rm->expr << " unit=" << unit << " size=" << bits.size() <<
         " data=0x" << hex(rm->data));
    while (range_match.size() <= size_t(unit))
        range_match.push_back(0xffff);
    unsigned val = rm->data;
    int size = bits.size();
    if (size < 2) {
        val &= 0x3;
        val |= val << 2; }
    if (size < 3) {
        val &= 0xf;
        val |= val << 4; }
    if (size < 4) {
        val &= 0xff;
        val |= val << 8; }
    range_match.at(unit) &= val;
    return false;
}

std::ostream &operator<<(std::ostream &out, const BuildGatewayMatch &m) {
    if (m.range_match.empty())
        return out << m.match;
    // only used as a gateway key, so format it as a YAML complex key
    out << "? [ ";
    for (int i = m.range_match.size()-1; i >= 0; --i)
        out << "0x" << hex(m.range_match[i]) << ", ";
    return out << m.match << " ] ";
}

GatewayOpt::GatewayOpt(const PhvInfo &phv) : PassManager {
    new PassRepeated {
        new CanonGatewayExpr,
        new SplitComplexGateways(phv),
        new GatewayRangeMatch(phv) },
    new CheckGatewayExpr(phv)
} {}
