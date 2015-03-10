#ifndef _input_xbar_h_
#define _input_xbar_h_

#include "tables.h"
#include "stage.h"
#include "phv.h"

class InputXbar {
    struct Input {
        Phv::Ref        what;
        int             lo, hi;
        Input(const Phv::Ref &a) : what(a), lo(-1), hi(-1) {}
        Input(const Phv::Ref &a, int s) : what(a), lo(s), hi(-1) {}
        Input(const Phv::Ref &a, int l, int h) : what(a), lo(l), hi(h) {}
    };
    struct HashCol {
        bitvec          data;
        unsigned        valid, seed;
        HashCol() : valid(0), seed(0) {}
    };
    Table	*table;
    bool        ternary;
    std::map<unsigned, std::vector<Input>>              groups;
    std::vector<std::map<unsigned, std::vector<Input>>::iterator>   group_order;
    std::map<unsigned, std::map<int, HashCol>>          hash_groups;
    unsigned parity_groups[EXACT_HASH_GROUPS];
    static bool conflict(std::vector<Input> &a, std::vector<Input> &b);
    static bool conflict(std::map<int, HashCol> &a, std::map<int, HashCol> &b);
    void add_use(unsigned &byte_use, std::vector<Input> &a);
public:
    const int	lineno;
    InputXbar(Table *table, bool ternary, VECTOR(pair_t) &data);
    void pass1(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void pass2(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void write_regs();

    unsigned width() const { return groups.size(); }
    unsigned group_for_word(unsigned w) {
        assert(w < group_order.size());
        return group_order[w]->first; }
    void add_to_parity(unsigned group, unsigned parity) {
        assert(group <= EXACT_HASH_GROUPS);
        assert(parity <= EXACT_HASH_GROUPS);
        parity_groups[group] |= 1U << parity; }
    class all_iter {
        decltype(group_order)::const_iterator   outer;
        bool                                    inner_valid;
        std::vector<Input>::iterator            inner;
        void mk_inner_valid() {
            if (!inner_valid) inner = (**outer).second.begin();
            while (inner == (**outer).second.end())
                inner = (**++outer).second.begin();
            inner_valid = true; }
        struct iter_deref : public std::pair<unsigned, Input &> {
            iter_deref(const std::pair<unsigned, Input &> &a) : std::pair<unsigned, Input &>(a) {}
            iter_deref *operator->() { return this; } };
    public:
        all_iter(decltype(group_order)::const_iterator o) :
            outer(o), inner_valid(false) {}
        bool operator==(const all_iter &a) {
            if (outer != a.outer) return false;
            if (inner_valid != a.inner_valid) return false;
            return inner_valid ? inner == a.inner : true; }
        all_iter &operator++() {
            mk_inner_valid();
            if (++inner == (**outer).second.end()) {
                ++outer;
                inner_valid = false; } 
            return *this; }
        std::pair<unsigned, Input &> operator*() {
            mk_inner_valid();
            return std::pair<unsigned, Input &>((**outer).first, *inner); }
        iter_deref operator->() { return iter_deref(**this); }
    };
    all_iter all_begin() const { return all_iter(group_order.begin()); }
    all_iter all_end() const { return all_iter(group_order.end()); }

    Input *find(Phv::Slice sl, int group);
};

#endif /* _input_xbar_h_ */
