#ifndef _instruction_h_
#define _instruction_h_

#include <functional>
#include "tables.h"

struct Instruction {
    int         lineno;
    int         slot;
    Instruction(int l) : lineno(l), slot(-1) {}
    virtual ~Instruction() {}
    virtual Instruction *pass1(Table *) = 0;
    virtual void pass2(Table *) = 0;
    virtual int encode() = 0;
    virtual void dbprint(std::ostream &) const = 0;
    virtual bool equiv(Instruction *a) = 0;
    virtual void phvRead(std::function<void (const Phv::Slice &sl)>) = 0;
    static Instruction *decode(Table *, const Table::Actions::Action *, const VECTOR(value_t) &);
};

#endif /* _instruction_h_ */
