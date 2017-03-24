#ifndef _target_h_
#define _target_h_

#include "gen/tofino/memories.prsr_mem_main_rspec.h"
#include "gen/tofino/regs.ibp_rspec.h"
#include "gen/tofino/regs.ebp_rspec.h"
#include "gen/tofino/regs.prsr_reg_merge_rspec.h"
#include "gen/jbay/memories.prsr_mem_main_rspec.h"
#include "gen/jbay/regs.ipb_csr_regs.h"
#include "gen/jbay/regs.epb_regs.h"
#include "gen/jbay/regs.prsr_reg_main_rspec.h"
#include "gen/jbay/regs.pmerge_reg.h"

#include "gen/tofino/regs.mau_addrmap.h"
#include "gen/jbay/regs.mau_addrmap.h"

#include "gen/tofino/regs.dprsr_hdr.h"
#include "gen/tofino/regs.dprsr_inp.h"
#include "gen/jbay/regs.dprsr_reg.h"


class Target {
 public:
    class Tofino;
    class JBay;
};

class Target::Tofino : public Target {
 public:
    struct                                          parser_regs {
        ::Tofino::memories_all_parser_                  memory[2];
        ::Tofino::regs_all_parser_ingress               ingress;
        ::Tofino::regs_all_parser_egress                egress;
        ::Tofino::regs_all_parse_merge                  merge;
    };
    typedef ::Tofino::regs_match_action_stage_      mau_regs;
    struct                                          deparser_regs {
        ::Tofino::regs_all_deparser_input_phase         input;
        ::Tofino::regs_all_deparser_header_phase        header;
    };
};

class Target::JBay : public Target {
 public:
    struct                                          parser_regs {
        ::JBay::memories_prsr_mem_main_rspec            memory[2];
        ::JBay::regs_ipb_csr_regs                       ingress;
        ::JBay::regs_epb_regs                           egress;
        ::JBay::regs_prsr_reg_main_rspec                main;
        ::JBay::regs_pmerge_reg                         merge;
    };
    typedef ::JBay::regs_mau_addrmap                mau_regs;
    typedef ::JBay::regs_dprsr_reg                  deparser_regs;
};

void declare_registers(const Target::Tofino::parser_regs *regs);
void undeclare_registers(const Target::Tofino::parser_regs *regs);
void declare_registers(const Target::Tofino::mau_regs *regs, int stage);
void declare_registers(const Target::Tofino::deparser_regs *regs);
void undeclare_registers(const Target::Tofino::deparser_regs *regs);

void declare_registers(const Target::JBay::parser_regs *regs);
void undeclare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);

#define FOR_ALL_TARGETS(M, ...) \
    M(Target::Tofino, ##__VA_ARGS) \
    M(Target::JBay, ##__VA_ARGS)

#endif /* _target_h_ */
