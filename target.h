#ifndef _target_h_
#define _target_h_

#include "gen/tofino/memories.prsr_mem_main_rspec.h"
#include "gen/tofino/regs.ibp_rspec.h"
#include "gen/tofino/regs.ebp_rspec.h"
#include "gen/tofino/regs.prsr_reg_merge_rspec.h"
#include "gen/jbay/memories.prsr_mem_main_rspec.h"
#include "gen/jbay/regs.parde_glue_stn_reg.h"
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
    typedef ::Tofino::memories_all_parser_          parser_memory;
    struct                                          parser_regs {
        ::Tofino::regs_all_parser_ingress             ingress;
        ::Tofino::regs_all_parser_egress              egress;
        ::Tofino::regs_all_parse_merge                merge;
    };
    typedef ::Tofino::regs_match_action_stage_      mau_regs;
    struct                                          deparser_regs {
        ::Tofino::regs_all_deparser_input_phase       input;
        ::Tofino::regs_all_deparser_header_phase      header;
    };
};

class Target::JBay : public Target {
 public:
    typedef ::JBay::memories_prsr_mem_main_rspec    parser_memory;
    typedef ::JBay::regs_parde_glue_stn_reg         parser_regs;
    typedef ::JBay::regs_mau_addrmap                mau_regs;
    typedef ::JBay::regs_dprsr_reg                  deparser_regs;
};

void declare_registers(const Target::Tofino::parser_memory *mem, const char *gress);
void declare_registers(const Target::Tofino::parser_regs *regs);
void undeclare_registers(const Target::Tofino::parser_regs *regs);
void declare_registers(const Target::Tofino::mau_regs *regs, int stage);
void declare_registers(const Target::Tofino::deparser_regs *regs);
void undeclare_registers(const Target::Tofino::deparser_regs *regs);

void declare_registers(const Target::JBay::parser_memory *mem, const char *gress);
void declare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);

#endif /* _target_h_ */
