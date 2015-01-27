#ifndef _input_xbar_h_
#define _input_xbar_h_

#include "tables.h"
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
    class iterator {
	std::map<int, std::vector<Input>>::const_iterator	iter;
    public:
	iterator(std::map<int, std::vector<Input>>::const_iterator it) : iter(it) {}
	std::vector<Input>::const_iterator begin() const { return iter->second.begin(); }
	std::vector<Input>::const_iterator end() const { return iter->second.end(); }
        bool operator==(const iterator &a) const { return iter == a.iter; }
	int operator *() const { return iter->first; }
	iterator &operator++() { ++iter; return *this; }
    };
    //iterator begin() const { return iterator(groups.begin()); }
    //iterator end() const { return iterator(groups.end()); }

    Input *find(Phv::Slice sl, int group);
};

#endif /* _input_xbar_h_ */
