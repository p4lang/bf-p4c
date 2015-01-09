#ifndef _instruction_h_
#define _instruction_h_

#include "asm-types.h"

class Table;

struct Instruction {
    int         lineno;
    int         slot, bits;
    Instruction(int l) : lineno(l), slot(-1), bits(0) {}
    virtual ~Instruction() {}
    virtual void encode(Table *) = 0;
    static Instruction *decode(Table *, const VECTOR(value_t) &);
};

#endif /* _instruction_h_ */
