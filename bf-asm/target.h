#ifndef _target_h_
#define _target_h_

#include <config.h>

#include "gen/tofino/memories.pipe_addrmap.h"
#include "gen/tofino/memories.pipe_top_level.h"
#include "gen/tofino/memories.prsr_mem_main_rspec.h"
#include "gen/tofino/regs.dprsr_hdr.h"
#include "gen/tofino/regs.dprsr_inp.h"
#include "gen/tofino/regs.ebp_rspec.h"
#include "gen/tofino/regs.ibp_rspec.h"
#include "gen/tofino/regs.mau_addrmap.h"
#include "gen/tofino/regs.pipe_addrmap.h"
#include "gen/tofino/regs.prsr_reg_merge_rspec.h"
#include "gen/tofino/regs.tofino.h"

#if HAVE_JBAY
#include "gen/jbay/memories.jbay_mem.h"
#include "gen/jbay/memories.pipe_addrmap.h"
#include "gen/jbay/memories.prsr_mem_main_rspec.h"
#include "gen/jbay/regs.dprsr_reg.h"
#include "gen/jbay/regs.epb_prsr4_reg.h"
#include "gen/jbay/regs.ipb_prsr4_reg.h"
#include "gen/jbay/regs.jbay_reg.h"
#include "gen/jbay/regs.mau_addrmap.h"
#include "gen/jbay/regs.pipe_addrmap.h"
#include "gen/jbay/regs.pmerge_reg.h"
#include "gen/jbay/regs.prsr_reg_main_rspec.h"
#endif // HAVE_JBAY

class Target {
 public:
    class Tofino;
#if HAVE_JBAY
    class JBay;
#endif // HAVE_JBAY
};

class Target::Tofino : public Target {
 public:
    struct                                          top_level_regs {
        typedef ::Tofino::memories_top                  _mem_top;
        typedef ::Tofino::memories_pipe                 _mem_pipe;
        typedef ::Tofino::regs_top                      _regs_top;
        typedef ::Tofino::regs_pipe                     _regs_pipe;

        ::Tofino::memories_top                          mem_top;
        ::Tofino::memories_pipe                         mem_pipe;
        ::Tofino::regs_top                              regs_top;
        ::Tofino::regs_pipe                             regs_pipe;
    };
    struct                                          parser_regs {
        typedef ::Tofino::memories_all_parser_          _memory;
        typedef ::Tofino::regs_all_parser_ingress       _ingress;
        typedef ::Tofino::regs_all_parser_egress        _egress;
        typedef ::Tofino::regs_all_parse_merge          _merge;

        ::Tofino::memories_all_parser_                  memory[2];
        ::Tofino::regs_all_parser_ingress               ingress;
        ::Tofino::regs_all_parser_egress                egress;
        ::Tofino::regs_all_parse_merge                  merge;
    };
    typedef ::Tofino::regs_match_action_stage_      mau_regs;
    struct                                          deparser_regs {
        typedef ::Tofino::regs_all_deparser_input_phase         _input;
        typedef ::Tofino::regs_all_deparser_header_phase        _header;

        ::Tofino::regs_all_deparser_input_phase         input;
        ::Tofino::regs_all_deparser_header_phase        header;
    };
};

void declare_registers(const Target::Tofino::top_level_regs *regs);
void undeclare_registers(const Target::Tofino::top_level_regs *regs);
void declare_registers(const Target::Tofino::parser_regs *regs);
void undeclare_registers(const Target::Tofino::parser_regs *regs);
void declare_registers(const Target::Tofino::mau_regs *regs, int stage);
void declare_registers(const Target::Tofino::deparser_regs *regs);
void undeclare_registers(const Target::Tofino::deparser_regs *regs);

#if HAVE_JBAY
class Target::JBay : public Target {
 public:
    struct                                          top_level_regs {
        typedef ::JBay::memories_jbay_mem               _mem_top;
        typedef ::JBay::memories_pipe_addrmap           _mem_pipe;
        typedef ::JBay::regs_jbay_reg                   _regs_top;
        typedef ::JBay::regs_pipe_addrmap               _regs_pipe;

        ::JBay::memories_jbay_mem                       mem_top;
        ::JBay::memories_pipe_addrmap                   mem_pipe;
        ::JBay::regs_jbay_reg                           regs_top;
        ::JBay::regs_pipe_addrmap                       regs_pipe;
    };
    struct                                          parser_regs {
        typedef ::JBay::memories_prsr_mem_main_rspec    _memory;
        typedef ::JBay::regs_ipb_prsr4_reg              _ingress;
        typedef ::JBay::regs_epb_prsr4_reg              _egress;
        typedef ::JBay::regs_prsr_reg_main_rspec        _main;
        typedef ::JBay::regs_pmerge_reg                 _merge;

        ::JBay::memories_prsr_mem_main_rspec            memory[2];
        ::JBay::regs_ipb_prsr4_reg                      ingress;
        ::JBay::regs_epb_prsr4_reg                      egress;
        ::JBay::regs_prsr_reg_main_rspec                main[2];
        ::JBay::regs_pmerge_reg                         merge;
    };
    typedef ::JBay::regs_mau_addrmap                mau_regs;
    typedef ::JBay::regs_dprsr_reg                  deparser_regs;
};
void declare_registers(const Target::JBay::top_level_regs *regs);
void undeclare_registers(const Target::JBay::top_level_regs *regs);
void declare_registers(const Target::JBay::parser_regs *regs);
void undeclare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);
#endif // HAVE_JBAY

#if HAVE_JBAY
#define FOR_ALL_TARGETS(M, ...) \
    M(TOFINO, Target::Tofino, ##__VA_ARGS__) \
    M(JBAY, Target::JBay, ##__VA_ARGS__)
#else
#define FOR_ALL_TARGETS(M, ...) \
    M(TOFINO, Target::Tofino, ##__VA_ARGS__)
#endif // HAVE_JBAY

#define INSTANTIATE_TARGET_TEMPLATE(ETAG, TTYPE, FUNC, ...) template FUNC(TTYPE::__VA_ARGS__);

#endif /* _target_h_ */
