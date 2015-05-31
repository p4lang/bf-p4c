#ifndef _hashexpr_h_
#define _hashexpr_h_

#include "phv.h"

class InputXbar;

class HashExpr {
    class PhvRef;
    class Random;
    class Crc;
    class Xor;
public:
    static HashExpr *create(gress_t, const value_t &);
    virtual bool check_ixbar(InputXbar *ix, int grp) = 0;
    virtual void gen_data(bitvec &data, int bit, InputXbar *ix, int grp) = 0;
    virtual int width() = 0;
};

#endif /* _hashexpr_h_ */
