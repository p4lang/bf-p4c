#ifndef _target_h_
#define _target_h_

#include <config.h>
#include "bfas.h"

/** FOR_ALL_TARGETS -- metamacro that expands a macro for each defined target
 */
#if HAVE_JBAY
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__) \
    M(JBay, ##__VA_ARGS__)
#else
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#endif // HAVE_JBAY

#define EXPAND(...)     __VA_ARGS__
#define INSTANTIATE_TARGET_TEMPLATE(TARGET, FUNC, ...)  template FUNC(Target::TARGET::__VA_ARGS__);
#define DECLARE_TARGET_CLASS(TARGET, ...)       class TARGET __VA_ARGS__;
#define FRIEND_TARGET_CLASS(TARGET, ...)        friend class Target::TARGET __VA_ARGS__;
#define TARGET_OVERLOAD(TARGET, FN, ARGS, ...)  FN(Target::TARGET::EXPAND ARGS) __VA_ARGS__;

#define PER_TARGET_CONSTANTS(M) \
    M(const char *, name) \
    M(int, PARSER_CHECKSUM_UNITS) \
    M(int, DEPARSER_CHECKSUM_UNITS) M(int, DEPARSER_MAX_POV_BYTES) \
    M(int, DEPARSER_CONSTANTS) \
    M(int, MAU_BASE_DELAY) M(int, MAU_BASE_PREDICATION_DELAY) \
    M(int, NUM_MAU_STAGES) M(int, END_OF_PIPE) \
    M(int, PHASE0_FORMAT_WIDTH) \
    M(int, STATEFUL_CMP_UNITS) M(int, STATEFUL_OUTPUT_UNITS) M(int, STATEFUL_PRED_MASK) \
    M(int, STATEFUL_CONST_WIDTH) M(int, STATEFUL_TMATCH_UNITS) \
    M(int, METER_ALU_GROUP_DATA_DELAY)

#define DECLARE_PER_TARGET_CONSTANT(TYPE, NAME) static TYPE NAME();

class Target {
 public:
    class Phv;
    FOR_ALL_TARGETS(DECLARE_TARGET_CLASS)
    PER_TARGET_CONSTANTS(DECLARE_PER_TARGET_CONSTANT)
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
    typedef Target::Tofino target_type;
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
    enum {
        PARSER_CHECKSUM_UNITS = 2,
        NUM_MAU_STAGES = 12,
        ACTION_INSTRUCTION_MAP_WIDTH = 7,
        DEPARSER_CHECKSUM_UNITS = 6,
        DEPARSER_CONSTANTS = 0,
        DEPARSER_MAX_POV_BYTES = 32,
        DEPARSER_MAX_FD_ENTRIES = 384,
        END_OF_PIPE = 0xff,
        MAU_BASE_DELAY = 20,
        MAU_BASE_PREDICATION_DELAY = 11,
        METER_ALU_GROUP_DATA_DELAY = 13,
        // To avoid under run scenarios, there is a minimum egress pipeline latency required
        MINIMUM_REQUIRED_EGRESS_PIPELINE_LATENCY = 160,
        PHASE0_FORMAT_WIDTH = 64,
        STATEFUL_CMP_UNITS = 2,
        STATEFUL_TMATCH_UNITS = 0,
        STATEFUL_OUTPUT_UNITS = 1,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_CONST_WIDTH = 32,
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
    static constexpr const char * const name = "tofino2";
    static constexpr target_t tag = JBAY;
    typedef Target::JBay target_type;
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
        typedef ::JBay::memories_parser_                _memory;
        typedef ::JBay::regs_parser_ingress             _ingress;
        typedef ::JBay::regs_parser_egress              _egress;
        typedef ::JBay::regs_parser_main_               _main;
        typedef ::JBay::regs_parse_merge                _merge;

        ::JBay::memories_parser_                        memory[2];
        ::JBay::regs_parser_ingress                     ingress;
        ::JBay::regs_parser_egress                      egress;
        ::JBay::regs_parser_main_                       main[2];
        ::JBay::regs_parse_merge                        merge;
    };
    typedef ::JBay::regs_match_action_stage_        mau_regs;
    typedef ::JBay::regs_deparser                   deparser_regs;
    enum {
        PARSER_CHECKSUM_UNITS = 5,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES = EMU_OVERRIDE_STAGE_COUNT,
#else
        NUM_MAU_STAGES = 20,
#endif
        ACTION_INSTRUCTION_MAP_WIDTH = 8,
        DEPARSER_CHECKSUM_UNITS = 8,
        DEPARSER_CONSTANTS = 8,
        DEPARSER_MAX_POV_BYTES = 16,
        DEPARSER_CHUNKS_PER_GROUP = 8,
        DEPARSER_CHUNK_SIZE = 8,
        DEPARSER_CHUNK_GROUPS = 16,
        DEPARSER_CLOTS_PER_GROUP = 4,
        DEPARSER_TOTAL_CHUNKS = DEPARSER_CHUNK_GROUPS * DEPARSER_CHUNKS_PER_GROUP,
        END_OF_PIPE = 0x1ff,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        METER_ALU_GROUP_DATA_DELAY = 15,
        PHASE0_FORMAT_WIDTH = 128,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_CONST_WIDTH = 34,
    };
};
void declare_registers(const Target::JBay::top_level_regs *regs);
void undeclare_registers(const Target::JBay::top_level_regs *regs);
void declare_registers(const Target::JBay::parser_regs *regs);
void undeclare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);
#endif // HAVE_JBAY

/** Macro to buid a switch table switching on a target_t, expanding to the same
 *  code for each target, with TARGET being a typedef for the target type */
#define SWITCH_FOREACH_TARGET(VAR, ...)                         \
        switch(VAR) {                                           \
        FOR_ALL_TARGETS(DO_SWITCH_FOREACH_TARGET, __VA_ARGS__)  \
        default: BUG(); }

#define DO_SWITCH_FOREACH_TARGET(TARGET_, ...)                  \
        case Target::TARGET_::tag: {                            \
            typedef Target::TARGET_  TARGET;                    \
            __VA_ARGS__                                         \
            break; }

#endif /* _target_h_ */
