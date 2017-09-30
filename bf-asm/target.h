#ifndef _target_h_
#define _target_h_

#include <config.h>
#include "bfas.h"

#if HAVE_JBAY
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__) \
    M(JBay, ##__VA_ARGS__)
#else
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#endif // HAVE_JBAY

#define INSTANTIATE_TARGET_TEMPLATE(TARGET, FUNC, ...) template FUNC(Target::TARGET::__VA_ARGS__);
#define DECLARE_TARGET_CLASS(TARGET, ...)    class TARGET __VA_ARGS__;
#define FRIEND_TARGET_CLASS(TARGET, ...)    friend class Target::TARGET __VA_ARGS__;

class Target {
 public:
    class Phv;
    FOR_ALL_TARGETS(DECLARE_TARGET_CLASS)
};

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

class Target::Tofino : public Target {
 public:
    static constexpr const char * const name = "tofino";
    static constexpr target_t tag = TOFINO;
    class Phv;
    struct                                          top_level_regs {
        typedef ::Tofino::memories_top                  _mem_top;
        typedef ::Tofino::memories_pipe                 _mem_pipe;
        typedef ::Tofino::regs_top                      _regs_top;
        typedef ::Tofino::regs_pipe                     _regs_pipe;

        ::Tofino::memories_top                          mem_top;
        ::Tofino::memories_pipe                         mem_pipe;
        ::Tofino::regs_top                              reg_top;
        ::Tofino::regs_pipe                             reg_pipe;
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

class Target::JBay : public Target {
 public:
    static constexpr const char * const name = "jbay";
    static constexpr target_t tag = JBAY;
    class Phv;
    struct                                          top_level_regs {
        typedef ::JBay::memories_top                    _mem_top;
        typedef ::JBay::memories_pipe                   _mem_pipe;
        typedef ::JBay::regs_top                        _regs_top;
        typedef ::JBay::regs_pipe                       _regs_pipe;

        ::JBay::memories_top                            mem_top;
        ::JBay::memories_pipe                           mem_pipe;
        ::JBay::regs_top                                reg_top;
        ::JBay::regs_pipe                               reg_pipe;
    };
    struct                                          parser_regs {
        typedef ::JBay::memories_all_parser_            _memory;
        typedef ::JBay::regs_ipb_prsr4_reg              _ingress;
        typedef ::JBay::regs_epb_prsr4_reg              _egress;
        typedef ::JBay::regs_parser_main_               _main;
        typedef ::JBay::regs_pmerge_reg                 _merge;

        ::JBay::memories_all_parser_                    memory[2];
        ::JBay::regs_ipb_prsr4_reg                      ingress;
        ::JBay::regs_epb_prsr4_reg                      egress;
        ::JBay::regs_parser_main_                       main[2];
        ::JBay::regs_pmerge_reg                         merge;
    };
    typedef ::JBay::regs_match_action_stage_        mau_regs;
    typedef ::JBay::regs_dprsr_reg                  deparser_regs;
};
void declare_registers(const Target::JBay::top_level_regs *regs);
void undeclare_registers(const Target::JBay::top_level_regs *regs);
void declare_registers(const Target::JBay::parser_regs *regs);
void undeclare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);
#endif // HAVE_JBAY

#endif /* _target_h_ */
