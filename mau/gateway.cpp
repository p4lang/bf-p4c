#include "gateway.h"
#include "split_gateways.h"
#include <deque>

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

const IR::Expression *make_slice(const IR::Expression *e, int lo, int hi) {
    if (lo == 0 && hi == e->type->width_bits() - 1)
        return e;
    BUG_CHECK(hi < e->type->width_bits(), "make_slice slice too big");
    if (auto sl = e->to<IR::Slice>()) {
        lo += sl->getL();
        hi += sl->getL();
        BUG_CHECK(hi <= sl->getH(), "make_slice slice too big");
        e = sl->e0; }
    return new IR::Slice(e, hi, lo);
}

static mpz_class SliceReduce(IR::Operation::Relation *rel, mpz_class val) {
    int slice = 0;
    while ((val & 1) == 0) {
        ++slice;
        val /= 2; }
    if (slice > 0) {
        LOG4("Slicing " << slice << " bits off the bottom of " << rel);
        rel->left = make_slice(rel->left, slice, rel->left->type->width_bits() - 1);
        rel->right = new IR::Constant(val);
        LOG4("Now have " << rel); }
    return val;
}

const IR::Expression *CanonGatewayExpr::postorder(IR::Operation::Relation *e) {
    // only called for Equ and Neq
    if (e->left->is<IR::Constant>()) {
        auto *t = e->left;
        e->left = e->right;
        e->right = t; }
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Leq *e) {
    if (e->left->is<IR::Constant>())
        return postorder(new IR::Geq(e->right, e->left));
    if (auto k = e->right->to<IR::Constant>())
        return postorder(new IR::Lss(e->left, new IR::Constant(k->value + 1)));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Lss *e) {
    if (auto k = e->left->to<IR::Constant>()) {
        BUG_CHECK(!e->right->is<IR::Constant>(), "constant folding failed");
        return postorder(new IR::Geq(e->right, new IR::Constant(k->value + 1))); }
    if (auto k = e->right->to<IR::Constant>())
        if (SliceReduce(e, k->value) == 1 && !isSigned(e->left->type))
            return new IR::Equ(e->left, new IR::Constant(0));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Geq *e) {
    if (auto k = e->left->to<IR::Constant>()) {
        BUG_CHECK(!e->right->is<IR::Constant>(), "constant folding failed");
        return postorder(new IR::Lss(e->right, new IR::Constant(k->value + 1))); }
    if (auto k = e->right->to<IR::Constant>())
        if (SliceReduce(e, k->value) == 1 && !isSigned(e->left->type))
            return new IR::Neq(e->left, new IR::Constant(0));
    return e; }
const IR::Expression *CanonGatewayExpr::postorder(IR::Grt *e) {
    if (e->left->is<IR::Constant>())
        return postorder(new IR::Lss(e->right, e->left));
    if (auto k = e->right->to<IR::Constant>())
        return postorder(new IR::Geq(e->left, new IR::Constant(k->value + 1)));
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
    if (findContext<IR::RangeMatch>()) {
        info.need_range = need_range = true;
    } else if (auto *rel = findContext<IR::Operation::Relation>(ctxt)) {
        if (!rel->is<IR::Equ>() && !rel->is<IR::Neq>()) {
            info.need_range = need_range = true;
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
                if (f.field == field->name && f.lo == 0) {
                    valid.second = f.bit + 32;
                    if (f.bit >= bits)
                        bits = f.bit + 1;
                    break; } } }
        if (valid.second >= 0) continue;
        valid.second = bits++ + 32; }
    return bits <= 12;
}

class GatewayRangeMatch::SetupRanges : public Transform {
    const PhvInfo               &phv;
    const CollectGatewayFields  &fields;
    IR::ActionFunction *preorder(IR::ActionFunction *af) override { prune(); return af; }
    IR::V1Table *preorder(IR::V1Table *t) override { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) override { prune(); return s; }

    const IR::Expression *postorder(IR::Operation::Relation *rel) override {
        PhvInfo::Field::bitrange bits;
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
                      "bad gateway field layout for range match"); }
        if (!base) return rel;
        if (base & 3) {
            bits.lo -= base & 3;
            val <<= base & 3;
            base &= ~3; }
        bits.lo -= orig_lo;
        bits.hi -= orig_lo;
        const IR::Expression *rv = nullptr, *himatch = nullptr;
        LOG5("  bits = " << bits);
        for (int lo = (bits.hi & ~3); lo >= (bits.lo & ~3); lo -= 4) {
            int hi = std::min(lo + 3, bits.hi);
            if (lo < bits.lo) lo = bits.lo;
            unsigned data = 1U << ((val >> (lo - bits.lo)) & 0xf);
            const IR::Expression *eq, *c;
            eq = new IR::RangeMatch(make_slice(rel->left, lo, hi), data);
            if (forceRange) --data;
            if (reverse) {
                data ^= 0xffff;
                if (forceRange && lo != bits.lo)
                    data = (data << 1) & 0xffff; }
            c = new IR::RangeMatch(make_slice(rel->left, lo, hi), data);
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
    PhvInfo::Field::bitrange bits;
    auto field = phv.field(e, &bits);
    if (!field)
        BUG("Unhandled expression in BuildGatewayMatch: %s", e);
    if (!match_field) {
        match_field = field;
        match_field_bits = bits;
        LOG4("  match_field = " << field->name << bits);
    } else {
        size_t size = std::max(bits.size(), match_field_bits.size());
        uint64_t mask = (1ULL << size) - 1;
        mask &= andmask & ~ormask;
        auto &field_info = fields.info.at(field);
        auto &match_info = fields.info.at(match_field);
        auto it = field_info.offsets.begin();
        auto end = field_info.offsets.end();
        for (auto &off : match_info.offsets) {
            if (it == end || it->first != off.first || it->second.size() != off.second.size() ||
                it->second.lo - field_info.bits.lo != off.second.lo - match_info.bits.lo) {
                BUG("field equality comparison misaligned in gateway"); }
            uint64_t elmask = ((1ULL << off.second.size()) - 1) <<
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
        match.word1 &= ~(1ULL << fields.valid_offsets[hdr] >> shift);
    else
        match.word0 &= ~(1ULL << fields.valid_offsets[hdr] >> shift);
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
        auto &match_info = fields.info.at(match_field);
        LOG4("  match_info = " << match_info);
        for (auto &off : match_info.offsets) {
            uint64_t elmask = ((1ULL << off.second.size()) - 1) <<
                              (off.second.lo - match_info.bits.lo);
            elmask &= mask;
            int lo = off.first - shift;
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
bool BuildGatewayMatch::preorder(const IR::RangeMatch *rm) {
    PhvInfo::Field::bitrange bits;
    auto field = phv.field(rm->expr, &bits);
    BUG_CHECK(field, "invalid RangeMatch in BuildGatewayMatch");
    int unit = -1;
    for (auto &alloc : fields.info.at(field).offsets) {
        if (alloc.first < 32 && !alloc.second.overlaps(bits))
            continue;
        unit = (alloc.first + bits.lo - alloc.second.lo - 32) / 4;
        break; }
    BUG_CHECK(unit >= 0 && unit < 3, "invalid RangeMatch unit");
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
