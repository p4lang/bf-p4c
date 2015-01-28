#ifndef _deparser_h_
#define _deparser_h_

#include "sections.h"
#include "gen/regs.dprsr_hdr.h"
#include "gen/regs.dprsr_inp.h"
#include "phv.h"
#include <vector>

enum {
    DEPARSER_MAX_POV_BYTES = 32,
    DEPARSER_MAX_FD_ENTRIES = 384,
};

class Deparser : public Section {
    int                                 lineno[2];
    regs_all_deparser_input_phase       inp_regs;
    regs_all_deparser_header_phase      hdr_regs;
    std::vector<std::pair<Phv::Ref, Phv::Ref>>  dictionary[2];
    std::vector<Phv::Ref>               pov_order[2];
    bitvec                              phv_use[2];
    Deparser();
    ~Deparser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    static Deparser singleton_object;
};

#endif /* _deparser_h_ */
