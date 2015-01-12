#ifndef _deparser_h_
#define _deparser_h_

#include "sections.h"
#include "gen/memories.dprsr_mem_rspec.h"
#include "gen/regs.dprsr_reg_rspec.h"

class Deparser : public Section {
    memories_all_deparser_        mem[2];
    regs_all_deparser_            reg[2];
    Deparser();
    ~Deparser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    static Deparser singleton_object;
};

#endif /* _deparser_h_ */
