#ifndef BF_ASM_TARGET_H_
#define BF_ASM_TARGET_H_

#include <config.h>
#include "bfas.h"
#include "map.h"

/** FOR_ALL_TARGETS -- metamacro that expands a macro for each defined target
 *  FOR_ALL_REGISTER_SETS -- metamacro that expands for each distinct register set;
 *              basically a subset of targets with one per distinct register set
 */
#if HAVE_CLOUDBREAK  /* for now also implies HAVE_JBAY */
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)     \
    M(Tofino2H, ##__VA_ARGS__) \
    M(Tofino2M, ##__VA_ARGS__) \
    M(Tofino2U, ##__VA_ARGS__) \
    M(Cloudbreak, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__) \
    M(Cloudbreak, ##__VA_ARGS__)
#elif HAVE_JBAY
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)     \
    M(Tofino2H, ##__VA_ARGS__) \
    M(Tofino2M, ##__VA_ARGS__) \
    M(Tofino2U, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)
#else
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#endif  // HAVE_CLOUBREAK/JBAY

#define EXPAND(...)     __VA_ARGS__
#define INSTANTIATE_TARGET_TEMPLATE(TARGET, FUNC, ...)  template FUNC(Target::TARGET::__VA_ARGS__);
#define DECLARE_TARGET_CLASS(TARGET, ...)       class TARGET __VA_ARGS__;
#define FRIEND_TARGET_CLASS(TARGET, ...)        friend class Target::TARGET __VA_ARGS__;
#define TARGET_OVERLOAD(TARGET, FN, ARGS, ...)  FN(Target::TARGET::EXPAND ARGS) __VA_ARGS__;

#define PER_TARGET_CONSTANTS(M) \
    M(const char *, name) \
    M(target_t, register_set)  \
    M(int, PARSER_CHECKSUM_UNITS) \
    M(int, MATCH_BYTE_16BIT_PAIRS) \
    M(int, DEPARSER_CHECKSUM_UNITS) M(int, DEPARSER_MAX_POV_BYTES) \
    M(int, DEPARSER_CONSTANTS) \
    M(int, GATEWAY_PAYLOAD_GROUPS) \
    M(int, INSTR_SRC2_BITS) \
    M(int, LONG_BRANCH_TAGS) \
    M(int, MAU_BASE_DELAY) M(int, MAU_BASE_PREDICATION_DELAY) \
    M(int, NUM_MAU_STAGES_PRIVATE) M(int, END_OF_PIPE) \
    M(bool, SUPPORT_TRUE_EOP) \
    M(int, PHASE0_FORMAT_WIDTH) \
    M(int, STATEFUL_CMP_UNITS) M(int, STATEFUL_OUTPUT_UNITS) M(int, STATEFUL_PRED_MASK) \
    M(int, STATEFUL_CONST_WIDTH) M(int, STATEFUL_TMATCH_UNITS) \
    M(int, METER_ALU_GROUP_DATA_DELAY) \
    M(bool, SUPPORT_ALWAYS_RUN) \
    M(bool, HAS_MPR) \
    M(bool, SUPPORT_CONCURRENT_STAGE_DEP) \
    M(bool, SUPPORT_OVERFLOW_BUS) \
    M(bool, SUPPORT_SALU_FAST_CLEAR) \
    M(bool, OUTPUT_STAGE_EXTENSION_PRIVATE) \
    M(int, MINIMUM_INSTR_CONSTANT) \
    M(int, NUM_PARSERS)

#define DECLARE_PER_TARGET_CONSTANT(TYPE, NAME) static TYPE NAME();

class Target {
 public:
    class Phv;
    FOR_ALL_TARGETS(DECLARE_TARGET_CLASS)
    PER_TARGET_CONSTANTS(DECLARE_PER_TARGET_CONSTANT)

    static int encodeConst(int src);

    static int NUM_MAU_STAGES() {
        return numMauStagesOverride ? numMauStagesOverride : NUM_MAU_STAGES_PRIVATE();
    }

    static int OUTPUT_STAGE_EXTENSION() {
        return numMauStagesOverride ? 1 : OUTPUT_STAGE_EXTENSION_PRIVATE();
    }

    static int OVERRIDE_NUM_MAU_STAGES(int num);

 private:
    static int numMauStagesOverride;
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
    static constexpr target_t register_set = TOFINO;
    typedef Target::Tofino target_type;
    typedef Target::Tofino register_type;
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

        // map from handle to parser regs
        std::map<unsigned, ::Tofino::memories_all_parser_*>     parser_memory[2];
        std::map<unsigned, ::Tofino::regs_all_parser_ingress*>  parser_ingress;
        std::map<unsigned, ::Tofino::regs_all_parser_egress*>   parser_egress;
        ::Tofino::regs_all_parse_merge                          parser_merge;
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
        MATCH_BYTE_16BIT_PAIRS = true,
        NUM_MAU_STAGES_PRIVATE = 12,
        ACTION_INSTRUCTION_MAP_WIDTH = 7,
        DEPARSER_CHECKSUM_UNITS = 6,
        DEPARSER_CONSTANTS = 0,
        DEPARSER_MAX_POV_BYTES = 32,
        DEPARSER_MAX_FD_ENTRIES = 192,
        END_OF_PIPE = 0xff,
        GATEWAY_PAYLOAD_GROUPS = 1,
        SUPPORT_TRUE_EOP = 0,
        INSTR_SRC2_BITS = 4,
        LONG_BRANCH_TAGS = 0,
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
        SUPPORT_ALWAYS_RUN = 0,
        HAS_MPR = 0,
        SUPPORT_CONCURRENT_STAGE_DEP = 1,
        SUPPORT_OVERFLOW_BUS = 1,
        SUPPORT_SALU_FAST_CLEAR = 0,
        MINIMUM_INSTR_CONSTANT = -8,
        NUM_PARSERS = 18,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
    };
    static int encodeConst(int src) {
        return (src >> 10 << 15) | (0x8 << 10) | (src & 0x3ff);
    }
};

void declare_registers(const Target::Tofino::top_level_regs *regs);
void undeclare_registers(const Target::Tofino::top_level_regs *regs);
void declare_registers(const Target::Tofino::parser_regs *regs);
void undeclare_registers(const Target::Tofino::parser_regs *regs);
void declare_registers(const Target::Tofino::mau_regs *regs, int stage);
void declare_registers(const Target::Tofino::deparser_regs *regs);
void undeclare_registers(const Target::Tofino::deparser_regs *regs);
void emit_parser_registers(const Target::Tofino::top_level_regs *regs, std::ostream &);

#if HAVE_JBAY || HAVE_CLOUDBREAK
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
    static constexpr target_t register_set = JBAY;
    typedef Target::JBay target_type;
    typedef Target::JBay register_type;
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

        // map from handle to parser regs
        std::map<unsigned, ::JBay::memories_parser_*>    parser_memory[2];
        std::map<unsigned, ::JBay::regs_parser_ingress*> parser_ingress;
        std::map<unsigned, ::JBay::regs_parser_egress*>  parser_egress;
        std::map<unsigned, ::JBay::regs_parser_main_*>   parser_main[2];
        ::JBay::regs_parse_merge                         parser_merge;
    };
    struct                                          parser_regs {
        typedef ::JBay::memories_parser_                _memory;
        typedef ::JBay::regs_parser_ingress             _ingress;  // [9]
        typedef ::JBay::regs_parser_egress              _egress;   // [9]
        typedef ::JBay::regs_parser_main_               _main;     // [9]
        typedef ::JBay::regs_parse_merge                _merge;    // [1]

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
        MATCH_BYTE_16BIT_PAIRS = false,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
#else
        NUM_MAU_STAGES_PRIVATE = 20,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
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
        GATEWAY_PAYLOAD_GROUPS = 5,
        SUPPORT_TRUE_EOP = 1,
        INSTR_SRC2_BITS = 5,
        LONG_BRANCH_TAGS = 8,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        METER_ALU_GROUP_DATA_DELAY = 15,
        PHASE0_FORMAT_WIDTH = 128,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_CONST_WIDTH = 34,
        SUPPORT_ALWAYS_RUN = 1,
        HAS_MPR = 1,
        SUPPORT_CONCURRENT_STAGE_DEP = 0,
        SUPPORT_OVERFLOW_BUS = 0,
        SUPPORT_SALU_FAST_CLEAR = 1,
        MINIMUM_INSTR_CONSTANT = -4,
        NUM_PARSERS = 36,
    };
    static int encodeConst(int src) {
        return (src >> 11 << 16) | (0x8 << 11) | (src & 0x7ff);
    }
};
void declare_registers(const Target::JBay::top_level_regs *regs);
void undeclare_registers(const Target::JBay::top_level_regs *regs);
void declare_registers(const Target::JBay::parser_regs *regs);
void undeclare_registers(const Target::JBay::parser_regs *regs);
void declare_registers(const Target::JBay::mau_regs *regs, int stage);
void declare_registers(const Target::JBay::deparser_regs *regs);

class Target::Tofino2H : public Target::JBay {
 public:
    static constexpr const char * const name = "tofino2h";
    static constexpr target_t tag = TOFINO2H;
    typedef Target::Tofino2H target_type;
    class Phv;
    enum {
        NUM_MAU_STAGES_PRIVATE = 6,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
    };
};

class Target::Tofino2M : public Target::JBay {
 public:
    static constexpr const char * const name = "tofino2m";
    static constexpr target_t tag = TOFINO2M;
    typedef Target::Tofino2M target_type;
    class Phv;
    enum {
        NUM_MAU_STAGES_PRIVATE = 12,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
    };
};

class Target::Tofino2U : public Target::JBay {
 public:
    static constexpr const char * const name = "tofino2u";
    static constexpr target_t tag = TOFINO2U;
    typedef Target::Tofino2U target_type;
    class Phv;
    enum {
        NUM_MAU_STAGES_PRIVATE = 20
    };
};

void emit_parser_registers(const Target::JBay::top_level_regs *regs, std::ostream &);

#endif  // HAVE_JBAY

#if HAVE_CLOUDBREAK
#include "gen/cloudbreak/memories.cb_mem.h"
#include "gen/cloudbreak/memories.pipe_addrmap.h"
#include "gen/cloudbreak/memories.prsr_mem_main_rspec.h"
#include "gen/cloudbreak/regs.dprsr_reg.h"
#include "gen/cloudbreak/regs.epb_prsr4_reg.h"
#include "gen/cloudbreak/regs.ipb_prsr4_reg.h"
#include "gen/cloudbreak/regs.cb_reg.h"
#include "gen/cloudbreak/regs.mau_addrmap.h"
#include "gen/cloudbreak/regs.pipe_addrmap.h"
#include "gen/cloudbreak/regs.pmerge_reg.h"
#include "gen/cloudbreak/regs.prsr_reg_main_rspec.h"

class Target::Cloudbreak : public Target {
 public:
    static constexpr const char * const name = "tofino3";
    static constexpr target_t tag = CLOUDBREAK;
    static constexpr target_t register_set = CLOUDBREAK;
    typedef Target::Cloudbreak target_type;
    typedef Target::Cloudbreak register_type;
    class Phv;
    struct                                          top_level_regs {
        typedef ::Cloudbreak::memories_top                    _mem_top;
        typedef ::Cloudbreak::memories_pipe                   _mem_pipe;
        typedef ::Cloudbreak::regs_top                        _regs_top;
        typedef ::Cloudbreak::regs_pipe                       _regs_pipe;

        ::Cloudbreak::memories_top                            mem_top;
        ::Cloudbreak::memories_pipe                           mem_pipe;
        ::Cloudbreak::regs_top                                reg_top;
        ::Cloudbreak::regs_pipe                               reg_pipe;

        // map from handle to parser regs
        std::map<unsigned, ::Cloudbreak::memories_parser_*>    parser_memory[2];
        std::map<unsigned, ::Cloudbreak::regs_parser_ingress*> parser_ingress;
        std::map<unsigned, ::Cloudbreak::regs_parser_egress*>  parser_egress;
        std::map<unsigned, ::Cloudbreak::regs_parser_main_*>   parser_main[2];
        ::Cloudbreak::regs_parse_merge                         parser_merge;
    };
    struct                                          parser_regs {
        typedef ::Cloudbreak::memories_parser_                _memory;
        typedef ::Cloudbreak::regs_parser_ingress             _ingress;  // [9]
        typedef ::Cloudbreak::regs_parser_egress              _egress;   // [9]
        typedef ::Cloudbreak::regs_parser_main_               _main;     // [9]
        typedef ::Cloudbreak::regs_parse_merge                _merge;    // [1]

        ::Cloudbreak::memories_parser_                        memory[2];
        ::Cloudbreak::regs_parser_ingress                     ingress;
        ::Cloudbreak::regs_parser_egress                      egress;
        ::Cloudbreak::regs_parser_main_                       main[2];
        ::Cloudbreak::regs_parse_merge                        merge;
    };

    typedef ::Cloudbreak::regs_match_action_stage_        mau_regs;
    typedef ::Cloudbreak::regs_deparser                   deparser_regs;
    enum {
        PARSER_CHECKSUM_UNITS = 5,
        MATCH_BYTE_16BIT_PAIRS = false,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
#else
        NUM_MAU_STAGES_PRIVATE = 20,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
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
        GATEWAY_PAYLOAD_GROUPS = 5,
        INSTR_SRC2_BITS = 5,
        LONG_BRANCH_TAGS = 8,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        METER_ALU_GROUP_DATA_DELAY = 15,
        PHASE0_FORMAT_WIDTH = 128,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_CONST_WIDTH = 34,
        SUPPORT_ALWAYS_RUN = 1,
        HAS_MPR = 1,
        SUPPORT_CONCURRENT_STAGE_DEP = 0,
        SUPPORT_OVERFLOW_BUS = 0,
        SUPPORT_SALU_FAST_CLEAR = 1,
        MINIMUM_INSTR_CONSTANT = -4,
        NUM_PARSERS = 36,
    };
    static int encodeConst(int src) {
        return (src >> 11 << 16) | (0x8 << 11) | (src & 0x7ff);
    }
};
void declare_registers(const Target::Cloudbreak::top_level_regs *regs);
void undeclare_registers(const Target::Cloudbreak::top_level_regs *regs);
void declare_registers(const Target::Cloudbreak::parser_regs *regs);
void undeclare_registers(const Target::Cloudbreak::parser_regs *regs);
void declare_registers(const Target::Cloudbreak::mau_regs *regs, int stage);
void declare_registers(const Target::Cloudbreak::deparser_regs *regs);

void emit_parser_registers(const Target::Cloudbreak::top_level_regs *regs, std::ostream &);

#endif  // HAVE_CLOUDBREAK


/** Macro to buid a switch table switching on a target_t, expanding to the same
 *  code for each target, with TARGET being a typedef for the target type */
#define SWITCH_FOREACH_TARGET(VAR, ...)                         \
        switch (VAR) {                                           \
        FOR_ALL_TARGETS(DO_SWITCH_FOREACH_TARGET, __VA_ARGS__)  \
        default: BUG(); }

#define DO_SWITCH_FOREACH_TARGET(TARGET_, ...)                  \
        case Target::TARGET_::tag: {                            \
            typedef Target::TARGET_  TARGET;                    \
            __VA_ARGS__                                         \
            break; }

#endif /* BF_ASM_TARGET_H_ */
