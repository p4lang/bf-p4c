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
    int         lineno;
    Table	*table;
    bool        ternary;
    std::map<int, std::vector<Input>>   groups;
    bool conflict(std::vector<Input> &a, std::vector<Input> &b);
    void add_use(unsigned &byte_use, std::vector<Input> &a);
public:
    InputXbar(Table *table, bool ternary, VECTOR(pair_t) &data);
    void pass1(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void pass2(Alloc1Dbase<std::vector<InputXbar *>> &use, int size);
    void write_regs();
};

#endif /* _input_xbar_h_ */
