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
    DEPARSER_LEARN_GROUPS = 8,
    DEPARSER_CHECKSUM_UNITS = 6,
};

class Deparser : public Section {
public:
    class RefOrChksum : public Phv::Ref {
        static Phv::Register checksum_units[2*DEPARSER_CHECKSUM_UNITS];
    public:
        RefOrChksum(gress_t g, const value_t &v) : Phv::Ref(g, v) {}
        bool check() const;
        Phv::Slice operator *() const;
        Phv::Slice operator->() const { return **this; }
    };
    int                                 lineno[2];
    regs_all_deparser_input_phase       inp_regs;
    regs_all_deparser_header_phase      hdr_regs;
    std::vector<std::pair<RefOrChksum, Phv::Ref>>  dictionary[2];
    std::vector<Phv::Ref>               checksum[2][DEPARSER_CHECKSUM_UNITS];
    std::vector<Phv::Ref>               pov_order[2];
    bitvec                              phv_use[2];
    struct Intrinsic;
    struct Learning {
        Phv::Ref                                select;
        std::map<int, std::vector<Phv::Ref>>    layout;
    } learn;
    std::vector<std::pair<Intrinsic *, std::vector<Phv::Ref>>> intrinsics;
    Deparser();
    ~Deparser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    static Deparser singleton_object;
};

#endif /* _deparser_h_ */
