#include "hashexpr.h"
#include "input_xbar.h"
#include "bitvec.h"
#include "bitops.h"

static bitvec crc(bitvec poly, bitvec val) {
    int poly_size = poly.max().index() + 1;
    if (!poly_size) return bitvec(0);
    val <<= poly_size - 1;
    for (auto i = val.max(); i.index() >= (poly_size-1); --i) {
        assert(*i);
        val ^= poly << (i.index() - (poly_size-1)); }
    return val;
}

static bool check_ixbar(Phv::Ref &ref, InputXbar *ix, int grp) {
    if (!ref.check()) return false;
    if (ref->reg.mau_id() < 0) {
        error(ref.lineno, "%s not accessable in mau", ref->reg.name);
        return false; }
    if (grp < 0) return true;
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
    int input_size() override { return what.size(); }
    bool match_phvref(Phv::Ref &ref) override {
        if (what->reg != ref->reg || what->lo != ref->lo)
            return false;
        return true; }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const PhvRef &>(a_);
        return *what == *a.what; }
};

class HashExpr::Random : HashExpr {
    std::vector<Phv::Ref>       what;
    Random(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto &ref : what)
            rv &= ::check_ixbar(ref, ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return 0; }
    int input_size() override {
        int rv = 0;
        for (auto &ref : what) rv += ref->size();
        return rv; }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const Random &>(a_);
        if (what.size() != a.what.size()) return false;
        auto it = a.what.begin();
        for (auto &el : what)
            if (*el != **it++) return false;
        return true; }
};

class HashExpr::Crc : HashExpr {
    bitvec                      poly;
    bitvec                      init;
    std::map<int, Phv::Ref>     what;
    std::vector<Phv::Ref>       vec_what;
    bool                        reverse = false;
    Crc(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override;
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return poly.max().index(); }
    int input_size() override {
        if (what.empty()) {
            int rv = 0;
            for (auto &ref : vec_what) rv += ref->size();
            return rv;
        } else {
            return what.rbegin()->first + what.rbegin()->second->size(); } }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const Crc &>(a_);
        if (what.size() != a.what.size()) return false;
        if (vec_what.size() != a.vec_what.size()) return false;
        auto it = a.what.begin();
        for (auto &el : what)
            if (el.first != it->first || *el.second != *(it++)->second)
                return false;
        auto it2 = a.vec_what.begin();
        for (auto &el : vec_what)
            if (*el != **it2++) return false;
        return true; }
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
    int input_size() override {
        int rv = 0;
        for (auto *e : what) rv += e->input_size();
        return rv; }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const Xor &>(a_);
        if (what.size() != a.what.size()) return false;
        auto it = a.what.begin();
        for (auto &el : what)
            if (*el != **it++) return false;
        return true; }
};

class HashExpr::Stripe : HashExpr {
    std::vector<HashExpr *>     what;
    bool supress_error_cascade = false;
    Stripe(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        bool rv = true;
        for (auto *e : what)
            rv |= e->check_ixbar(ix, grp);
        return rv; }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
    int width() override { return 0; }
    int input_size() override {
        int rv = 0;
        for (auto *e : what) rv += e->input_size();
        return rv; }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const Stripe &>(a_);
        if (what.size() != a.what.size()) return false;
        auto it = a.what.begin();
        for (auto &el : what)
            if (*el != **it++) return false;
        return true; }
};

class HashExpr::Slice : HashExpr {
    HashExpr    *what = nullptr;
    int         start = 0, _width = 0;
    Slice(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        return what->check_ixbar(ix, grp); }
    void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override {
        what->gen_data(data, bit + start, ix, grp); }
    int width() override {
        if (_width == 0) {
            _width = what->width();
            if (_width > 0) {
                _width -= start;
                if (_width <= 0) _width = -1; } }
        return _width; }
    int input_size() override { return what->input_size(); }
    bool operator==(const HashExpr &a_) const override {
        if (typeid(*this) != typeid(a_)) return false;
        auto &a = static_cast<const Slice &>(a_);
        if (start != a.start || _width != a._width) return false;
        return *what == *a.what;
    }
};


HashExpr *HashExpr::create(gress_t gress, const value_t &what) {
    if (what.type == tCMD) {
        if (what[0] == "random") {
            Random *rv = new Random(what.lineno);
            for (int i = 1; i < what.vec.size; i++)
                rv->what.emplace_back(gress, what[i]);
            return rv;
        } else if ((what[0] == "crc" || what[0] == "crc_rev" || what[0] == "crc_reverse") &&
                   CHECKTYPE2(what[1], tBIGINT, tINT)) {
            Crc *rv = new Crc(what.lineno);
            if (what[0] != "crc") rv->reverse = true;
            if (what[1].type == tBIGINT)
                rv->poly.setraw(what[1].bigi.data, what[1].bigi.size);
            else
                rv->poly.setraw(what[1].i & 0xFFFFFFFF);
            // Shift and set LSB to 1 to generate polynomial from Koopman number
            // provided in assembly
            rv->poly <<= 1;
            rv->poly[0] = 1;
            int i = 3;
            if (what.vec.size > 2) {
                if (what[2].type == tBIGINT)
                    rv->init.setraw(what[2].bigi.data, what[2].bigi.size);
                else if (what[2].type == tINT)
                    rv->init.setraw(what[2].i & 0xFFFFFFFF);
                else
                    i--; }
            if (what.vec.size == i+1 && what[i].type == tMAP) {
                for (auto &kv : what[i].map) {
                    if (CHECKTYPE(kv.key, tINT)) {
                        if (rv->what.count(kv.key.i))
                            error(kv.value.lineno, "Duplicate field at offset %ld", kv.value.i);
                        else
                            rv->what.emplace(kv.key.i, Phv::Ref(gress, kv.value)); } }
            } else {
                for (; i < what.vec.size; i++) {
                    rv->vec_what.emplace_back(gress, what[i]); } }
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
        } else if (what[0] == "slice") {
            if (what.vec.size < 3 ||
                what[2].type == tRANGE
                    ?  what.vec.size > 3 || what[2].hi < what[2].lo
                    : what[2].type != tINT || what.vec.size > 4 ||
                      (what.vec.size == 4 && what[3].type != tINT)) {
                error(what.lineno, "Invalid slice operation");
                return nullptr; }
            Slice *rv = new Slice(what.lineno);
            rv->what = create(gress, what[1]);
            if (what[2].type == tRANGE) {
                rv->start = what[2].lo;
                rv->_width = what[2].hi - what[2].lo + 1;
            } else {
                rv->start = what[2].i;
                if (what.vec.size > 3)
                    rv->_width = what[3].i; }
            return rv;
        } else if (what.vec.size == 2) {
            return new PhvRef(gress, what);
        } else
            error(what.lineno, "Unsupported hash operation '%s'", what[0].s);
    } else if (what.type == tSTR) {
        return new PhvRef(gress, what);
    } else
        error(what.lineno, "Syntax error, expecting hash expression");
    return nullptr;
}

void HashExpr::PhvRef::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    auto *in = ix->find_exact(*what, grp);
    if (!in || in->lo < 0) return;
    data[in->lo%64U + what->lo + bit - in->what->lo] = 1;
}

void HashExpr::Random::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    for (auto &ref : what) {
        auto *in = ix->find_exact(*ref, grp);
        if (!in || in->lo < 0) break;
        int off = in->lo%64U - in->what->lo;
        for (int i = ref->lo; i <= ref->hi; i++)
            data[i + off] = random() & 1;
    }
}

bool HashExpr::Crc::check_ixbar(InputXbar *ix, int grp) {
    bool rv = true;
    if (!vec_what.empty()) {
        int off = 0;
        for (auto &ref : vec_what) {
            rv &= ::check_ixbar(ref, ix, -1);
            if (ref) {
                if (auto *in = ix->find_exact(*ref, grp))
                    if (in->lo >= 0)
                        what.emplace(off, ref);
                off += ref.size(); } }
        vec_what.clear();
    } else {
        int max = -1;
        for (auto &ref : what) {
            if (ref.first < max)
                error(ref.second.lineno, "Overlapping fields in crc input");
            if (ref.second)
                max = ref.first + ref.second->size() - 1;
            rv &= ::check_ixbar(ref.second, ix, grp); } }
    return rv;
}

void HashExpr::Crc::gen_data(bitvec &data, int bit, InputXbar *ix, int grp) {
    bitvec init = this->init << input_size();
    // A crc_rev reverses the bits used in the polynomial
    if (reverse)
        bit = poly.max().index() - 1 - bit;
    for (auto &ref : what) {
        auto *in = ix->find_exact(*ref.second, grp);
        if (!in || in->lo < 0) continue;
        int off = in->lo%64U - in->what->lo + ref.second->lo;
        for (int i = 0; i < ref.second->size(); i++) {
            bitvec crcinput = init;
            if (reverse)
                crcinput[(ref.first + i)^7] = 1;  // reverse the bits of each byte.
            else
                crcinput[ref.first + i] = 1;
            data[i + off] = crc(poly, crcinput).getbit(bit); } }
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
        if (total_size == 0) {
            if (!supress_error_cascade) {
                error(lineno, "Can't stripe unsized data");
                supress_error_cascade = true; }
            break; }
        bit %= total_size; }
}
