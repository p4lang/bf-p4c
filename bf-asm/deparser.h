#ifndef _deparser_h_
#define _deparser_h_

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
        /* a phv reference with optional associated POV phv reference */
        Phv::Ref   val;
        int        tag = -1;
        Phv::Ref   pov;
        const int &lineno = val.lineno;
        Val() {}
        Val(gress_t gr, const value_t &v) : val(gr, v) {}
        Val(gress_t gr, const value_t &v, const value_t &p) : val(gr, v), pov(gr, p) {}
        Val(gress_t gr, int t, const value_t &p) : tag(t), pov(gr, p) {}
        Val &operator=(const Val &a) { val = a.val; tag = a.tag; pov = a.pov; return *this; }
        explicit operator bool() const { return bool(val); }
        Phv::Slice operator*() const { return *val; }
        Phv::Slice operator->() const { return *val; }
        bool check() const { return val.check(); }
    };

    struct FDEntry;

    int                                             lineno[2];
    std::vector<FDEntry>                            dictionary[2];
    std::vector<Val>                                checksum[2][MAX_DEPARSER_CHECKSUM_UNITS];
    /* Stores phv entries that need to be swapped in checksum config.
       This is needed for JBay because checksum entries may not
       follow field order in the packet (due to clots), therefore
       it's impossible for assemler to infer "swap"; compiler needs
       to pass this info explictly in the assembly. */
    std::vector<Phv::Ref>                           checksum_swaps[2][MAX_DEPARSER_CHECKSUM_UNITS];
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
            if (singleton_object.constants[gr].size() > Target::DEPARSER_CONSTANTS())
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
