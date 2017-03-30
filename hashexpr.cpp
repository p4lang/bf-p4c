#include "hashexpr.h"
#include "input_xbar.h"
#include "bitvec.h"
#include "bitops.h"

static unsigned crc(unsigned poly, bitvec val) {
    int poly_size = floor_log2(poly) + 1;
    if (!poly_size) return 0;
    val <<= poly_size;
    for (auto i = val.max(); i.index() >= (poly_size-1); --i) {
        assert(*i);
        val ^= bitvec(poly) << (i.index() - (poly_size-1));
    }
    return val.getrange(0, 32);
}

static bool check_ixbar(Phv::Ref &ref, InputXbar *ix, int grp) {
    if (!ref.check(true)) return false;
    if (auto *in = ix->find_exact(*ref, grp))
        return in->lo >= 0;
    else error(ref.lineno, "%s not in group %d", ref.name(), grp);
    return false;
}

class HashExpr::PhvRef : HashExpr {
    Phv::Ref what;
    PhvRef(gress_t gr, const value_t &v) : HashExpr(v.lineno), what(gr, v) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override { return ::check_ixbar(what, ix, grp); }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return what.size(); }
    bool match_phvref(Phv::Ref &ref) {
        if (what->reg != ref->reg || what->lo != ref->lo)
            return false;
        return true; }
};

class HashExpr::Random : HashExpr {
    std::vector<Phv::Ref>       what;
    Random(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto &ref : what)
            rv |= ::check_ixbar(ref, ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return 0; }
};

class HashExpr::Crc : HashExpr {
    unsigned                    poly;
    std::vector<Phv::Ref>       what;
    Crc(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto &ref : what)
            rv |= ::check_ixbar(ref, ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return floor_log2(poly) - 1; }
};

class HashExpr::Xor : HashExpr {
    std::vector<HashExpr *>     what;
    Xor(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto *e : what)
            rv |= e->check_ixbar(ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override {
        int rv = 0;
        for (auto *e : what) {
            int w = e->width();
            if (w > rv) rv = w; }
        return rv; }
};

class HashExpr::Stripe : HashExpr {
    std::vector<HashExpr *>     what;
    Stripe(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto *e : what)
            rv |= e->check_ixbar(ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return 0; }
};

HashExpr *HashExpr::create(gress_t gress, const value_t &what) {
    if (what.type == tCMD) {
        if (what[0] == "random") {
            Random *rv = new Random(what.lineno);
            for (int i = 1; i < what.vec.size; i++)
                rv->what.emplace_back(gress, what[i]);
            return rv;
        } else if (what[0] == "crc" && CHECKTYPE(what[1], tINT)) {
            Crc *rv = new Crc(what.lineno);
            rv->poly = what[1].i*2 + 1;
            for (int i = 2; i < what.vec.size; i++)
                rv->what.emplace_back(gress, what[i]);
            return rv;
        } else if (what[0] == "^") {
            Xor *rv = new Xor(what.lineno);
            for (int i = 1; i < what.vec.size; i++)
                rv->what.push_back(create(gress, what[i]));
            return rv;
        } else if (what[0] == "stripe") {
            Stripe *rv = new Stripe(what.lineno);
            for (int i = 1; i < what.vec.size; i++)
                rv->what.push_back(create(gress, what[i]));
            return rv;
        } else if (what.vec.size == 2) {
            return new PhvRef(gress, what);
        } else
            error(what.lineno, "Unsupported hash operation '%s'", what[0].s);
    } else if (what.type == tSTR) {
        return new PhvRef(gress, what);
    } else
        error(what.lineno, "Syntax error, expecting hash expression");
    return 0;
}

void HashExpr::PhvRef::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    auto *in = ix->find_exact(*what, grp);
    if (in->lo < 0) return;
    data[in->lo%64U + what->lo + bit - in->what->lo] = 1;
}

void HashExpr::Random::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    for (auto &ref : what) {
        auto *in = ix->find_exact(*ref, grp);
        if (in->lo < 0) break;
        int off = in->lo%64U - in->what->lo;
        for (int i = ref->lo; i <= ref->hi; i++)
            data[i + off] = random() & 1;
    }
}

void HashExpr::Crc::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    bitvec crcbit(1UL);
    for (auto &ref : what) {
        auto *in = ix->find_exact(*ref, grp);
        if (in->lo < 0) break;
        int off = in->lo%64U - in->what->lo;
        for (int i = ref->lo; i <= ref->hi; i++, crcbit <<= 1)
            data[i + off] = (crc(poly, crcbit) >> bit) & 1; }
}

void HashExpr::Xor::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    for (auto *e : what)
        e->gen_data(data, bit, ix, grp);
}

void HashExpr::Stripe::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    while (1) {
        int total_size = 0;
        for (auto *e : what) {
            int sz = e->width();
            if (bit < total_size + sz) {
                e->gen_data(data, bit - total_size, ix, grp);
                return; }
            total_size += sz; }
        if (total_size == 0)
            error(lineno, "Can't stripe unsized data");
        bit %= total_size; }
}
