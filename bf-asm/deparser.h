#ifndef _deparser_h_
#define _deparser_h_

#include "bitops.h"
#include "sections.h"
#include "phv.h"
#include <vector>

enum {
    // limits over all targets
    MAX_DEPARSER_CHECKSUM_UNITS = 8,
};

class Deparser : public Section {
    static Deparser singleton_object;
public:
    struct Val {
        /* a phv or clot reference with optional associated POV phv reference */
        Phv::Ref   val;
        int        tag = -1;
        Phv::Ref   pov;
        const int &lineno = val.lineno;
        Val() {}
        virtual ~Val() {}
        Val(gress_t gr, const value_t &v) : val(gr, v) {}
        Val(gress_t gr, const value_t &v, const value_t &p) : val(gr, v), pov(gr, p) {}
        Val(gress_t gr, int tag, const value_t &p) : tag(tag), pov(gr, p) {}
        Val &operator=(const Val &a) { val = a.val; tag = a.tag; pov = a.pov; return *this; }
        explicit operator bool() const { return is_phv() || is_clot(); }
        Phv::Slice operator*() const { return *val; }
        Phv::Slice operator->() const { return *val; }
        bool is_phv() const { return bool(val); }
        bool is_clot() const { return tag >= 0; }
        virtual bool check() const {
            if (is_phv() && is_clot()) {
                error(lineno, "Reference cannot be phv and clot at the same time");
                return false; }
            if (is_phv())
                return val.check();
            else if (is_clot()) {
                if (!(bool)pov) {
                    error(lineno, "Clot requires a pov bit");
                    return false;
                }
            } else {
                error(lineno, "Unknown val");
                return false;
            }
            return true;
        }
    };

    struct ChecksumVal : public Val {
        int mask = 0;
        int swap = 0;
        ChecksumVal(gress_t gr, const value_t &v, const value_t &m) : Val(gr, v) {
            if ((val->lo % 8 != 0) || (val->hi % 8 != 7))
                error(lineno, "Can only do checksums on byte-aligned container slices");
            
            mask = ((1 << (val->hi + 1)/8) - 1) ^ ((1 << val->lo/8) - 1);

            if (CHECKTYPE(m, tMAP)) {
                for (auto &kv : m.map) {
                    if (kv.key == "pov") {
                        if (pov) error(kv.value.lineno, "Duplicate POV");
                        pov = ::Phv::Ref(gr, kv.value);
                    } else if (kv.key == "swap" && CHECKTYPE(kv.value, tINT))
                        swap = kv.value.i;
                    else
                        error(m.lineno, "Unknown key for checksum: %s", value_desc(kv.key)); } }
        }
        ChecksumVal(gress_t gr, int tag, const value_t &p) : Val(gr, tag, p) {}
        ChecksumVal &operator=(const ChecksumVal &a) {
            Val::operator=(a); mask = a.mask; swap = a.swap; return *this; }

        bool check() const override {
            if (is_phv()) {
                if (mask == 0)
                    error(lineno, "mask is 0 for phv checkum value?");
                if (swap < 0 || swap > 3)
                    error(lineno, "Invalid swap for phv checksum");
            }
            return Val::check();
        }
    };

    struct FDEntry;

    int                                             lineno[2];
    std::vector<FDEntry>                            dictionary[2];
    std::vector<ChecksumVal>                        checksum[2][MAX_DEPARSER_CHECKSUM_UNITS];
    std::vector<Phv::Ref>                           pov_order[2];
    ordered_map<const Phv::Register *, unsigned>    pov[2];
    bitvec                                          phv_use[2];
    std::set<int>                                   constants[2];
    struct Intrinsic {
        struct Type;
        Type                    *type;
        int                     lineno;
        std::vector<Val>        vals;
        Intrinsic(Type *t, int l) : type(t), lineno(l) {}
    };
    std::vector<Intrinsic>      intrinsics;
    struct Digest {
        struct Type;
        Type                                    *type;
        int                                     lineno;
        Val                                     select;
        int                                     shift = 0;
        std::map<int, std::vector<Phv::Ref>>    layout;
        std::unique_ptr<json::map>              context_json;
        Digest(Type *t, int lineno, VECTOR(pair_t) &data);
    };
    std::vector<Digest>                 digests;
    Deparser();
    ~Deparser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);
    template<class REGS> void gen_learn_quanta(REGS &, json::vector&);
    template<class REGS> void write_config(REGS &);

    static const bitvec &PhvUse(gress_t gr) {
        return singleton_object.phv_use[gr]; }

    static bool add_constant(gress_t gr, int c) {
        if (!singleton_object.constants[gr].count(c)) {
            singleton_object.constants[gr].insert(c);
            if (int(singleton_object.constants[gr].size()) > Target::DEPARSER_CONSTANTS())
                return false;
        }
        return true;
    }

    static int constant_idx(gress_t gr, int c) {
        if (singleton_object.constants[gr].count(c))
            return std::distance(singleton_object.constants[gr].begin(),
                                 singleton_object.constants[gr].find(c));
        return -1; }
};

#endif /* _deparser_h_ */
