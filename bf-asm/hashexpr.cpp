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

/**
 * Generating a list of ixbar_input_t and hash_matrix_output_t to be sent to the
 * dynamic_hash library.  The vectors are part of the function call as they
 * must be on the stack to avoid using new and delete
 */
void HashExpr::gen_ixbar_init(ixbar_init_t *ixbar_init, std::vector<ixbar_input_t> &inputs,
        std::vector<hash_matrix_output_t> &outputs, int logical_hash_bit, InputXbar *ix,
        int hash_table) {
    inputs.clear();
    outputs.clear();

    gen_ixbar_inputs(inputs, ix, hash_table);
    hash_matrix_output_t hmo;
    hmo.hash_output_bit = logical_hash_bit;
    hmo.galois_start_bit = 0;
    hmo.bit_size = 1;
    outputs.push_back(hmo);
 

    ixbar_init->ixbar_inputs = inputs.data();
    ixbar_init->inputs_sz = inputs.size();
    ixbar_init->hash_matrix_outputs = outputs.data();
    ixbar_init->outputs_sz = outputs.size();
}

/**
 * The function call for the Random, Identity, and Crc function.  The input xbar is
 * initialized, and the data returned writes out a vector of inputs.  For Stripe,
 * Slice, and others, they recursively will call this function
 */
void HashExpr::gen_data(bitvec &data, int logical_hash_bit, InputXbar *ix, int hash_table) {
    ixbar_init_t ixbar_init;
    hash_column_t hash_matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN] = { 0 };
    std::vector<ixbar_input_t> inputs;
    std::vector<hash_matrix_output_t> outputs;

    gen_ixbar_init(&ixbar_init, inputs, outputs, logical_hash_bit, ix, hash_table);

    determine_hash_matrix(&ixbar_init, ixbar_init.ixbar_inputs, ixbar_init.inputs_sz,
                          &hash_algorithm, hash_matrix);
    uint64_t hash_column = hash_matrix[hash_table][0].column_value;
    data |= hash_column; 
}

class HashExpr::PhvRef : HashExpr {
    Phv::Ref what;
    PhvRef(gress_t gr, const value_t &v) : HashExpr(v.lineno), what(gr, v) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override { return ::check_ixbar(what, ix, grp); }
    // void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) override;
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
    void build_algorithm() override {
        hash_algorithm.hash_alg = IDENTITY_DYN;
        hash_algorithm.msb = false;
        hash_algorithm.extend = false;
        hash_algorithm.final_xor = 0ULL;
        hash_algorithm.poly = 0ULL;
        hash_algorithm.init = 0ULL;
        hash_algorithm.reverse = false;
    }

    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override;
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
    void build_algorithm() override {
        hash_algorithm.hash_alg = RANDOM_DYN;
        hash_algorithm.msb = false;
        hash_algorithm.extend = false;
        hash_algorithm.final_xor = 0ULL;
        hash_algorithm.poly = 0ULL;
        hash_algorithm.init = 0ULL;
        hash_algorithm.reverse = false;
    }
    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override;
};

class HashExpr::Crc : HashExpr {
    bitvec                      poly;
    bitvec                      init;
    std::map<int, Phv::Ref>     what;
    std::vector<Phv::Ref>       vec_what;
    bool                        reverse = false;
    int                         total_input_bits = -1;
    Crc(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override;
    int width() override { return poly.max().index(); }
    int input_size() override {
        if (total_input_bits >= 0)
            return total_input_bits;
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
    void build_algorithm() override {
        hash_algorithm.size = poly.max().index();
        hash_algorithm.hash_alg = CRC_DYN;
        hash_algorithm.reverse = reverse;
        hash_algorithm.poly = poly.getrange(32, 32) << 32;
        hash_algorithm.poly |= poly.getrange(0, 32);
        hash_algorithm.init = init.getrange(32, 32) << 32; 
        hash_algorithm.init |= init.getrange(0, 32);
        hash_algorithm.final_xor = 0ULL;
        hash_algorithm.extend = false;
        hash_algorithm.msb = false;
    }

    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override;
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
    void gen_data(bitvec &data, int logical_hash_bit, InputXbar *ix, int hash_table) override;
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
    void build_algorithm() override {
        for (auto *e : what) {
             e->build_algorithm();
        }
    }

    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override { }
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
    void gen_data(bitvec &data, int logical_hash_bit, InputXbar *ix, int hash_table) override;
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
    void build_algorithm() override {
        for (auto *e : what) {
             e->build_algorithm();
        }
        // Does not set the extend algorithm, as the gen_data for extend does this
        // in the source 
    }

    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override { }
};

class HashExpr::Slice : HashExpr {
    HashExpr    *what = nullptr;
    int         start = 0, _width = 0;
    Slice(int lineno) : HashExpr(lineno) {}
    friend class HashExpr;
    bool check_ixbar(InputXbar *ix, int grp) override {
        return what->check_ixbar(ix, grp); }
    void gen_data(bitvec &data, int logical_hash_bit, InputXbar *ix, int hash_table) override {
        what->gen_data(data, logical_hash_bit + start, ix, hash_table); }
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
    void build_algorithm() override {
         what->build_algorithm();
    }
    void gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
            int hash_table) override { }
};

// The ordering for crc expression is:
// crc(poly, @optional init, @optional input_bits, map)
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
            int i = 2;

            if (what.vec.size > 2) {
                if (what[2].type == tBIGINT) {
                    rv->init.setraw(what[2].bigi.data, what[2].bigi.size);
                    i++;
                } else if (what[2].type == tINT) {
                    rv->init.setraw(what[2].i & 0xFFFFFFFF);
                    i++;
                }

                if (what.vec.size > 3) {
                    if (what[3].type == tINT) {
                        rv->total_input_bits == what[3].i;
                        i++;
                    }
                }
            }

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

void HashExpr::find_input(Phv::Ref what, std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table) {
   bool found = false;
   auto vec = ix->find_all_exact(*what, (hash_table / 2));
   for (auto *in : vec) {
        int group_bit_position = in->lo + (what->lo - in->what->lo);
        if ((group_bit_position / 64 != (hash_table % 2)) ||
            (group_bit_position + what->size() - 1) / 64 != (hash_table % 2))
            continue; 
    
        ixbar_input_t input;
        input.ixbar_bit_position = group_bit_position + (hash_table / 2) * 128;
        input.bit_size = what->size();
        input.valid = true;
        inputs.push_back(input);
        found = true;
        break;
    }
    if (!found) {
        error(ix->lineno, "Cannot find associated field %s[%d:%d] in hash_table %d",
              what->reg.name, what->hi, what->lo, hash_table);
    }
}


/**
 * Creates a vector with a single entry corresponding to the identity input
 */
void HashExpr::PhvRef::gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table) {
    find_input(what, inputs, ix, hash_table);
}

/**
 * Iterates through the list of references to build a corresponding vector for the
 * dynamic hash library
 */
void HashExpr::Random::gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table) {
    for (auto &ref : what) {
        find_input(ref, inputs, ix, hash_table);
    }
}

/**
 * Iterates through the crc map, and will generate ixbar_input_t inputs for the holes.
 * These are marked as invalid, so that the hash calculation will be correct
 */
void HashExpr::Crc::gen_ixbar_inputs(std::vector<ixbar_input_t> &inputs, InputXbar *ix,
        int hash_table) {
    int previous_range_hi = 0;
    for (auto &entry : what) {
        ixbar_input_t normal_input;
        ixbar_input_t invalid_input;
        if (previous_range_hi != entry.first) {
            invalid_input.valid = false;
            invalid_input.bit_size = entry.first - previous_range_hi; 
            inputs.push_back(invalid_input);
        }

        auto &ref = entry.second;
        find_input(ref, inputs, ix, hash_table); 
        previous_range_hi = entry.first + ref->size();
    }
    if (previous_range_hi != input_size()) {
        ixbar_input_t invalid_input;
        invalid_input.valid = false;
        invalid_input.bit_size = input_size() - previous_range_hi;
        inputs.push_back(invalid_input);
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
