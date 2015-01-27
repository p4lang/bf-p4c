#ifndef _deparser_h_
#define _deparser_h_

#include "sections.h"
#include "gen/regs.dprsr_hdr.h"
#include "gen/regs.dprsr_inp.h"

class Deparser : public Section {
    regs_all_deparser_input_phase       inp_regs;
    regs_all_deparser_header_phase      hdr_regs;
    Deparser();
    ~Deparser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    static Deparser singleton_object;
};

#endif /* _deparser_h_ */
