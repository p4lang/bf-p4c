#ifndef _input_xbar_h_
#define _input_xbar_h_

#include "tables.h"
#include "stage.h"
#include "phv.h"
#include "ordered_map.h"

class HashExpr;

class InputXbar {
    struct Input {
        Phv::Ref        what;
        int             lo, hi;
        Input(const Phv::Ref &a) : what(a), lo(-1), hi(-1) {}
        Input(const Phv::Ref &a, int s) : what(a), lo(s), hi(-1) {}
        Input(const Phv::Ref &a, int l, int h) : what(a), lo(l), hi(h) {}
    };
    struct HashCol {
        int                     lineno = -1;
        HashExpr                *fn = 0;
        int                     bit = 0;
        bitvec                  data;
        unsigned                valid = 0;
    };
    struct HashGrp {
        int             lineno = -1;
        unsigned        tables = 0;
        uint64_t        seed = 0;
    };
    Table       *table;
    bool        ternary;
    ordered_map<unsigned, std::vector<Input>>           groups;
    std::map<unsigned, std::map<int, HashCol>>          hash_tables;
    std::map<unsigned, HashGrp>                         hash_groups;
    static bool conflict(const std::vector<Input> &a, const std::vector<Input> &b);
    static bool conflict(const std::map<int, HashCol> &a, const std::map<int, HashCol> &b);
    static bool conflict(const HashGrp &a, const HashGrp &b);
    uint64_t hash_columns_used(unsigned hash);
    bool can_merge(HashGrp &a, HashGrp &b);
    void add_use(unsigned &byte_use, std::vector<Input> &a);
    void setup_hash(std::map<int, HashCol> &, int, gress_t, value_t &, int lineno, int lo, int hi);
    struct GroupSet {
        unsigned        group;
        const std::vector<InputXbar *> &use;
        GroupSet(const std::vector<InputXbar *> &u, unsigned g) : group(g), use(u) {}
        GroupSet(Alloc1Dbase<std::vector<InputXbar *>> &u, unsigned g) : group(g), use(u[g]) {}
        void dbprint(std::ostream &) const;
        Input *find(Phv::Slice sl) const;
    };
public:
    const int   lineno;
    InputXbar(Table *table, bool ternary) : table(table), ternary(ternary), lineno(-1) {}
    InputXbar(Table *table, bool ternary, VECTOR(pair_t) &data);
    void pass1(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void pass2(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void write_regs();

    int hash_group() const {
        /* used by gateways to get the associated hash group */
        if (hash_groups.size() != 1) return -1;
        return hash_groups.begin()->first; }
    bitvec hash_group_bituse() const;
    std::vector<const HashCol *> hash_column(int col, int grp = -1) const;
    int match_group() {
        /* used by gateways to get the associated match group */
        if (groups.size() != 1) return -1;
        return groups.begin()->first; }
    /* functions for tcam ixbar that take into account funny byte/word group stuff */
    unsigned tcam_width();
    int tcam_byte_group(int n);
    int tcam_word_group(int n);

    class all_iter {
        decltype(groups)::const_iterator        outer, outer_end;
        bool                                    inner_valid;
        std::vector<Input>::const_iterator      inner;
        void mk_inner_valid() {
            if (!inner_valid) {
                if (outer == outer_end) return;
                inner = outer->second.begin(); }
            while (inner == outer->second.end()) {
                if (++outer == outer_end) return;
                inner = outer->second.begin(); }
            inner_valid = true; }
        struct iter_deref : public std::pair<unsigned, const Input &> {
            iter_deref(const std::pair<unsigned, const Input &> &a)
            : std::pair<unsigned, const Input &>(a) {}
            iter_deref *operator->() { return this; } };
    public:
        all_iter(decltype(groups)::const_iterator o, decltype(groups)::const_iterator oend)
        : outer(o), outer_end(oend), inner_valid(false) { mk_inner_valid(); }
        bool operator==(const all_iter &a) {
            if (outer != a.outer) return false;
            if (inner_valid != a.inner_valid) return false;
            return inner_valid ? inner == a.inner : true; }
        all_iter &operator++() {
            if (inner_valid && ++inner == outer->second.end()) {
                ++outer;
                inner_valid = false;
                mk_inner_valid(); }
            return *this; }
        std::pair<unsigned, const Input &> operator*() {
            return std::pair<unsigned, const Input &>(outer->first, *inner); }
        iter_deref operator->() { return iter_deref(**this); }
    };
    all_iter begin() const { return all_iter(groups.begin(), groups.end()); }
    all_iter end() const { return all_iter(groups.end(), groups.end()); }

    Input *find(Phv::Slice sl, int group = -1);
};

#endif /* _input_xbar_h_ */
