#ifndef BF_ASM_TARGET_H_
#define BF_ASM_TARGET_H_

#include <config.h>
#include "bfas.h"
#include "map.h"
#include "asm-types.h"
#include "bf-p4c/common/flatrock_parser.h"

/** FOR_ALL_TARGETS -- metamacro that expands a macro for each defined target
 *  FOR_ALL_REGISTER_SETS -- metamacro that expands for each distinct register set;
 *              basically a subset of targets with one per distinct register set
 */
#if HAVE_FLATROCK  /* for now also implies HAVE_CLOUDBREAK and HAVE_JBAY */
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)     \
    M(Tofino2H, ##__VA_ARGS__) \
    M(Tofino2M, ##__VA_ARGS__) \
    M(Tofino2U, ##__VA_ARGS__) \
    M(Tofino2A0, ##__VA_ARGS__) \
    M(Cloudbreak, ##__VA_ARGS__) \
    M(Flatrock, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__) \
    M(Cloudbreak, ##__VA_ARGS__) \
    M(Flatrock, ##__VA_ARGS__)
#elif HAVE_CLOUDBREAK  /* for now also implies HAVE_JBAY */
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)     \
    M(Tofino2H, ##__VA_ARGS__) \
    M(Tofino2M, ##__VA_ARGS__) \
    M(Tofino2U, ##__VA_ARGS__) \
    M(Tofino2A0, ##__VA_ARGS__) \
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
    M(Tofino2U, ##__VA_ARGS__) \
    M(Tofino2A0, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)   \
    M(JBay, ##__VA_ARGS__)
#else
#define FOR_ALL_TARGETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#define FOR_ALL_REGISTER_SETS(M, ...) \
    M(Tofino, ##__VA_ARGS__)
#endif  /* !HAVE_FLATROCK && !HAVE_CLOUBREAK && !HAVE_JBAY */

#define EXPAND(...)     __VA_ARGS__
#define INSTANTIATE_TARGET_TEMPLATE(TARGET, FUNC, ...)  template FUNC(Target::TARGET::__VA_ARGS__);
#define DECLARE_TARGET_CLASS(TARGET, ...)       class TARGET __VA_ARGS__;
#define FRIEND_TARGET_CLASS(TARGET, ...)        friend class Target::TARGET __VA_ARGS__;
#define TARGET_OVERLOAD(TARGET, FN, ARGS, ...)  FN(Target::TARGET::EXPAND ARGS) __VA_ARGS__;

#define PER_TARGET_CONSTANTS(M) \
    M(const char *, name) \
    M(target_t, register_set)  \
    M(int, DEPARSER_CHECKSUM_UNITS) \
    M(int, DEPARSER_CONSTANTS) \
    M(int, DEPARSER_MAX_FD_ENTRIES) \
    M(int, DEPARSER_MAX_POV_BYTES) \
    M(int, DEPARSER_MAX_POV_PER_USE) \
    M(int, DYNAMIC_CONFIG) \
    M(int, DYNAMIC_CONFIG_INPUT_BITS) \
    M(bool, EGRESS_SEPARATE) \
    M(int, END_OF_PIPE) \
    M(int, GATEWAY_PAYLOAD_GROUPS) \
    M(bool, GATEWAY_SINGLE_XBAR_GROUP) \
    M(bool, HAS_MPR) \
    M(int, INSTR_SRC2_BITS) \
    M(int, IMEM_COLORS) \
    M(int, IXBAR_HASH_GROUPS) \
    M(int, IXBAR_HASH_INDEX_MAX) \
    M(int, IXBAR_HASH_INDEX_STRIDE) \
    M(int, LONG_BRANCH_TAGS) \
    M(int, MAX_OVERHEAD_OFFSET) \
    M(int, MAX_OVERHEAD_OFFSET_NEXT) \
    M(int, MATCH_BYTE_16BIT_PAIRS) \
    M(int, MATCH_REQUIRES_PHYSID) \
    M(int, MAU_BASE_DELAY) \
    M(int, MAU_BASE_PREDICATION_DELAY) \
    M(int, METER_ALU_GROUP_DATA_DELAY) \
    M(int, MINIMUM_INSTR_CONSTANT) \
    M(bool, NEXT_TABLE_EXEC_COMBINED) \
    M(int, NUM_MAU_STAGES_PRIVATE) \
    M(int, NUM_EGRESS_STAGES_PRIVATE) \
    M(int, NUM_PARSERS) \
    M(int, NUM_PIPES) \
    M(bool, OUTPUT_STAGE_EXTENSION_PRIVATE) \
    M(int, PARSER_CHECKSUM_UNITS) \
    M(bool, PARSER_EXTRACT_BYTES) \
    M(int, PARSER_DEPTH_MAX_BYTES_INGRESS) \
    M(int, PARSER_DEPTH_MAX_BYTES_EGRESS) \
    M(int, PHASE0_FORMAT_WIDTH) \
    M(bool, REQUIRE_TCAM_ID) \
    M(int, SRAM_EGRESS_ROWS) \
    M(int, SRAM_GLOBAL_ACCESS) \
    M(int, SRAM_INGRESS_ROWS) \
    M(int, SRAM_LAMBS_PER_STAGE) \
    M(int, SRAM_UNITS_PER_ROW) \
    M(int, STATEFUL_ALU_ADDR_WIDTH) \
    M(int, STATEFUL_ALU_CONST_MASK) \
    M(int, STATEFUL_ALU_CONST_MAX) \
    M(int, STATEFUL_ALU_CONST_MIN) \
    M(int, STATEFUL_ALU_CONST_WIDTH) \
    M(int, STATEFUL_CMP_ADDR_WIDTH) \
    M(int, STATEFUL_CMP_CONST_MASK) \
    M(int, STATEFUL_CMP_CONST_MAX) \
    M(int, STATEFUL_CMP_CONST_MIN) \
    M(int, STATEFUL_CMP_CONST_WIDTH) \
    M(int, STATEFUL_CMP_UNITS) \
    M(int, STATEFUL_OUTPUT_UNITS) \
    M(int, STATEFUL_PRED_MASK) \
    M(int, STATEFUL_REGFILE_CONST_WIDTH) \
    M(int, STATEFUL_REGFILE_ROWS) \
    M(int, STATEFUL_TMATCH_UNITS) \
    M(bool, SUPPORT_ALWAYS_RUN) \
    M(bool, SUPPORT_CONCURRENT_STAGE_DEP) \
    M(bool, SUPPORT_OVERFLOW_BUS) \
    M(bool, SUPPORT_SALU_FAST_CLEAR) \
    M(bool, SUPPORT_TRUE_EOP) \
    M(bool, TABLES_REQUIRE_ROW) \

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
    static int NUM_EGRESS_STAGES() {
        int egress_stages = NUM_EGRESS_STAGES_PRIVATE();
        return numMauStagesOverride && numMauStagesOverride < egress_stages
               ? numMauStagesOverride : egress_stages;
    }
    static int NUM_STAGES(gress_t gr) {
        return gr == EGRESS ? NUM_EGRESS_STAGES() : NUM_MAU_STAGES();
    }

    static int OUTPUT_STAGE_EXTENSION() {
        return numMauStagesOverride ? 1 : OUTPUT_STAGE_EXTENSION_PRIVATE();
    }

    static void OVERRIDE_NUM_MAU_STAGES(int num);

    static int SRAM_ROWS(gress_t gr) {
        return gr == EGRESS ? SRAM_EGRESS_ROWS() : SRAM_INGRESS_ROWS();
    }

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
    struct                                          parser_regs : public ParserRegisterSet {
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
        PARSER_EXTRACT_BYTES = false,
        PARSER_DEPTH_MAX_BYTES_INGRESS = (((1<<10)-1)*16),
        PARSER_DEPTH_MAX_BYTES_EGRESS = (((1<<10)-1)*16),
        MATCH_BYTE_16BIT_PAIRS = true,
        MATCH_REQUIRES_PHYSID = false,
        MAX_OVERHEAD_OFFSET = 64,
        MAX_OVERHEAD_OFFSET_NEXT = 40,
        NUM_MAU_STAGES_PRIVATE = 12,
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
        ACTION_INSTRUCTION_MAP_WIDTH = 7,
        DEPARSER_CHECKSUM_UNITS = 6,
        DEPARSER_CONSTANTS = 0,
        DEPARSER_MAX_POV_BYTES = 32,
        DEPARSER_MAX_POV_PER_USE = 1,
        DEPARSER_MAX_FD_ENTRIES = 192,
        DYNAMIC_CONFIG = 0,
        DYNAMIC_CONFIG_INPUT_BITS = 0,
        EGRESS_SEPARATE = false,
        END_OF_PIPE = 0xff,
        GATEWAY_PAYLOAD_GROUPS = 1,
        GATEWAY_SINGLE_XBAR_GROUP = true,
        SUPPORT_TRUE_EOP = 0,
        INSTR_SRC2_BITS = 4,
        IMEM_COLORS = 2,
        IXBAR_HASH_GROUPS = 8,
        IXBAR_HASH_INDEX_MAX = 40,
        IXBAR_HASH_INDEX_STRIDE = 10,
        LONG_BRANCH_TAGS = 0,
        MAU_BASE_DELAY = 20,
        MAU_BASE_PREDICATION_DELAY = 11,
        METER_ALU_GROUP_DATA_DELAY = 13,
        // To avoid under run scenarios, there is a minimum egress pipeline latency required
        MINIMUM_REQUIRED_EGRESS_PIPELINE_LATENCY = 160,
        NEXT_TABLE_EXEC_COMBINED = false,  // no next_exec on tofino1 at all
        PHASE0_FORMAT_WIDTH = 64,
        REQUIRE_TCAM_ID = false,   // miss-only tables do not need a tcam id
        SRAM_EGRESS_ROWS = 8,
        SRAM_GLOBAL_ACCESS = false,
        SRAM_INGRESS_ROWS = 8,
        SRAM_LAMBS_PER_STAGE = 0,
        SRAM_UNITS_PER_ROW = 12,
        STATEFUL_CMP_UNITS = 2,
        STATEFUL_CMP_ADDR_WIDTH = 2,
        STATEFUL_CMP_CONST_WIDTH = 4,
        STATEFUL_CMP_CONST_MASK = 0xf,
        STATEFUL_CMP_CONST_MIN = -8,
        STATEFUL_CMP_CONST_MAX = 7,
        STATEFUL_TMATCH_UNITS = 0,
        STATEFUL_OUTPUT_UNITS = 1,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_REGFILE_ROWS = 4,
        STATEFUL_REGFILE_CONST_WIDTH = 32,
        SUPPORT_ALWAYS_RUN = 0,
        HAS_MPR = 0,
        SUPPORT_CONCURRENT_STAGE_DEP = 1,
        SUPPORT_OVERFLOW_BUS = 1,
        SUPPORT_SALU_FAST_CLEAR = 0,
        STATEFUL_ALU_ADDR_WIDTH = 2,
        STATEFUL_ALU_CONST_WIDTH = 4,
        STATEFUL_ALU_CONST_MASK = 0xf,
        STATEFUL_ALU_CONST_MIN = -8,  // TODO Is the same as the following one?
        STATEFUL_ALU_CONST_MAX = 7,
        MINIMUM_INSTR_CONSTANT = -8,  // TODO
        NUM_PARSERS = 18,
        NUM_PIPES = 4,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
        TABLES_REQUIRE_ROW = 1,
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
    struct                                          parser_regs : public ParserRegisterSet {
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
        PARSER_EXTRACT_BYTES = true,
        PARSER_DEPTH_MAX_BYTES_INGRESS = (((1<<10)-1)*16),
        PARSER_DEPTH_MAX_BYTES_EGRESS = (32*16),
        MATCH_BYTE_16BIT_PAIRS = false,
        MATCH_REQUIRES_PHYSID = false,
        MAX_OVERHEAD_OFFSET = 64,
        MAX_OVERHEAD_OFFSET_NEXT = 40,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
#else
        NUM_MAU_STAGES_PRIVATE = 20,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
#endif
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
        ACTION_INSTRUCTION_MAP_WIDTH = 8,
        DEPARSER_CHECKSUM_UNITS = 8,
        DEPARSER_CONSTANTS = 8,
        DEPARSER_MAX_POV_BYTES = 16,
        DEPARSER_MAX_POV_PER_USE = 1,
        DEPARSER_CHUNKS_PER_GROUP = 8,
        DEPARSER_CHUNK_SIZE = 8,
        DEPARSER_CHUNK_GROUPS = 16,
        DEPARSER_CLOTS_PER_GROUP = 4,
        DEPARSER_TOTAL_CHUNKS = DEPARSER_CHUNK_GROUPS * DEPARSER_CHUNKS_PER_GROUP,
        DEPARSER_MAX_FD_ENTRIES = DEPARSER_TOTAL_CHUNKS,
        DYNAMIC_CONFIG = 0,
        DYNAMIC_CONFIG_INPUT_BITS = 0,
        EGRESS_SEPARATE = false,
        END_OF_PIPE = 0x1ff,
        GATEWAY_PAYLOAD_GROUPS = 5,
        GATEWAY_SINGLE_XBAR_GROUP = true,
        SUPPORT_TRUE_EOP = 1,
        INSTR_SRC2_BITS = 5,
        IMEM_COLORS = 2,
        IXBAR_HASH_GROUPS = 8,
        IXBAR_HASH_INDEX_MAX = 40,
        IXBAR_HASH_INDEX_STRIDE = 10,
        LONG_BRANCH_TAGS = 8,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        METER_ALU_GROUP_DATA_DELAY = 15,
        NEXT_TABLE_EXEC_COMBINED = true,
        PHASE0_FORMAT_WIDTH = 128,
        REQUIRE_TCAM_ID = false,   // miss-only tables do not need a tcam id
        SRAM_EGRESS_ROWS = 8,
        SRAM_GLOBAL_ACCESS = false,
        SRAM_INGRESS_ROWS = 8,
        SRAM_LAMBS_PER_STAGE = 0,
        SRAM_UNITS_PER_ROW = 12,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_CMP_ADDR_WIDTH = 2,
        STATEFUL_CMP_CONST_WIDTH = 6,
        STATEFUL_CMP_CONST_MASK = 0x3f,
        STATEFUL_CMP_CONST_MIN = -32,
        STATEFUL_CMP_CONST_MAX = 31,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_REGFILE_ROWS = 4,
        STATEFUL_REGFILE_CONST_WIDTH = 34,
        SUPPORT_ALWAYS_RUN = 1,
        HAS_MPR = 1,
        SUPPORT_CONCURRENT_STAGE_DEP = 0,
        SUPPORT_OVERFLOW_BUS = 0,
        SUPPORT_SALU_FAST_CLEAR = 1,
        STATEFUL_ALU_ADDR_WIDTH = 2,
        STATEFUL_ALU_CONST_WIDTH = 4,
        STATEFUL_ALU_CONST_MASK = 0xf,
        STATEFUL_ALU_CONST_MIN = -8,  // TODO Is the same as the following one?
        STATEFUL_ALU_CONST_MAX = 7,
        MINIMUM_INSTR_CONSTANT = -4,  // TODO
        NUM_PARSERS = 36,
        NUM_PIPES = 4,
        TABLES_REQUIRE_ROW = 1,
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
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
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
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
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
        NUM_MAU_STAGES_PRIVATE = 20,
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
    };
};

class Target::Tofino2A0 : public Target::JBay {
 public:
    static constexpr const char * const name = "tofino2a0";
    static constexpr target_t tag = TOFINO2A0;
    typedef Target::Tofino2A0 target_type;
    class Phv;
    enum {
        NUM_MAU_STAGES_PRIVATE = 20,
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
    };
};

void emit_parser_registers(const Target::JBay::top_level_regs *regs, std::ostream &);

#endif  /* HAVE_JBAY */

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
    struct                                          parser_regs : public ParserRegisterSet {
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
        PARSER_EXTRACT_BYTES = true,
        PARSER_DEPTH_MAX_BYTES_INGRESS = (((1<<10)-1)*16),
        PARSER_DEPTH_MAX_BYTES_EGRESS = (32*16),
        MATCH_BYTE_16BIT_PAIRS = false,
        MATCH_REQUIRES_PHYSID = false,
        MAX_OVERHEAD_OFFSET = 64,
        MAX_OVERHEAD_OFFSET_NEXT = 40,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
#else
        NUM_MAU_STAGES_PRIVATE = 20,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
#endif
        NUM_EGRESS_STAGES_PRIVATE = NUM_MAU_STAGES_PRIVATE,
        ACTION_INSTRUCTION_MAP_WIDTH = 8,
        DEPARSER_CHECKSUM_UNITS = 8,
        DEPARSER_CONSTANTS = 8,
        DEPARSER_MAX_POV_BYTES = 16,
        DEPARSER_MAX_POV_PER_USE = 1,
        DEPARSER_CHUNKS_PER_GROUP = 8,
        DEPARSER_CHUNK_SIZE = 8,
        DEPARSER_CHUNK_GROUPS = 16,
        DEPARSER_CLOTS_PER_GROUP = 4,
        DEPARSER_TOTAL_CHUNKS = DEPARSER_CHUNK_GROUPS * DEPARSER_CHUNKS_PER_GROUP,
        DEPARSER_MAX_FD_ENTRIES = DEPARSER_TOTAL_CHUNKS,
        DYNAMIC_CONFIG = 0,
        DYNAMIC_CONFIG_INPUT_BITS = 0,
        EGRESS_SEPARATE = false,
        END_OF_PIPE = 0x1ff,
        GATEWAY_PAYLOAD_GROUPS = 5,
        GATEWAY_SINGLE_XBAR_GROUP = true,
        INSTR_SRC2_BITS = 5,
        IMEM_COLORS = 2,
        IXBAR_HASH_GROUPS = 8,
        IXBAR_HASH_INDEX_MAX = 40,
        IXBAR_HASH_INDEX_STRIDE = 10,
        LONG_BRANCH_TAGS = 8,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        METER_ALU_GROUP_DATA_DELAY = 15,
        NEXT_TABLE_EXEC_COMBINED = true,
        PHASE0_FORMAT_WIDTH = 128,
        REQUIRE_TCAM_ID = false,   // miss-only tables do not need a tcam id
        SRAM_EGRESS_ROWS = 8,
        SRAM_GLOBAL_ACCESS = false,
        SRAM_INGRESS_ROWS = 8,
        SRAM_LAMBS_PER_STAGE = 0,
        SRAM_UNITS_PER_ROW = 12,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_CMP_ADDR_WIDTH = 2,
        STATEFUL_CMP_CONST_WIDTH = 6,
        STATEFUL_CMP_CONST_MASK = 0x3f,
        STATEFUL_CMP_CONST_MIN = -32,
        STATEFUL_CMP_CONST_MAX = 31,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_REGFILE_ROWS = 4,
        STATEFUL_REGFILE_CONST_WIDTH = 34,
        SUPPORT_ALWAYS_RUN = 1,
        HAS_MPR = 1,
        SUPPORT_CONCURRENT_STAGE_DEP = 0,
        SUPPORT_OVERFLOW_BUS = 0,
        SUPPORT_SALU_FAST_CLEAR = 1,
        STATEFUL_ALU_ADDR_WIDTH = 2,
        STATEFUL_ALU_CONST_WIDTH = 4,
        STATEFUL_ALU_CONST_MASK = 0xf,
        STATEFUL_ALU_CONST_MIN = -8,  // TODO Is the same as the following one?
        STATEFUL_ALU_CONST_MAX = 7,
        MINIMUM_INSTR_CONSTANT = -4,  // TODO
        NUM_PARSERS = 36,
        /**
         * @brief Number of pipes per subdev.
         *
         * Cloudbreak has 2 subdevs with 4 pipes in address space of each subdev.
         * Currently assembler generates the binary only for one subdev,
         * thus we consider only address space of one subdev.
         *
         * See also chip.schema.
         */
        NUM_PIPES = 4,
        TABLES_REQUIRE_ROW = 1,
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

#endif  /* HAVE_CLOUDBREAK */

#if HAVE_FLATROCK
#include "gen/flatrock/memories.ftr_mem.h"
#include "gen/flatrock/memories.pipe_addrmap.h"
#include "gen/flatrock/memories.ingress_parser.h"
#include "gen/flatrock/memories.ingress_deparser.h"
#include "gen/flatrock/memories.egress_parser.h"
#include "gen/flatrock/memories.egress_deparser.h"
#include "gen/flatrock/regs.ftr_reg.h"
#include "gen/flatrock/regs.pipe_addrmap.h"
#include "gen/flatrock/regs.mau_addrmap.h"
#include "gen/flatrock/regs.ingress_parser.h"
#include "gen/flatrock/regs.ingress_deparser.h"
#include "gen/flatrock/regs.egress_parser.h"
#include "gen/flatrock/regs.egress_deparser.h"

class Target::Flatrock : public Target {
 public:
    static constexpr const char * const name = "tofino5";
    static constexpr target_t tag = FLATROCK;
    static constexpr target_t register_set = FLATROCK;
    typedef Target::Flatrock target_type;
    typedef Target::Flatrock register_type;
    class Phv;
    struct                                          top_level_regs {
        typedef ::Flatrock::regs_top                    _regs_top;
        typedef ::Flatrock::regs_pipe                   _regs_pipe;

        ::Flatrock::memories_top                        mem_top;
        ::Flatrock::memories_pipe                       mem_pipe;
        ::Flatrock::regs_top                            reg_top;
        ::Flatrock::regs_pipe                           reg_pipe;
    };
    struct                              parser_regs : public ParserRegisterSet {
        ::Flatrock::memories_ingress_parser             prsr_mem;
        ::Flatrock::memories_egress_parser              pprsr_mem;
        ::Flatrock::regs_ingress_parser                 prsr;
        ::Flatrock::regs_egress_parser                  pprsr;
    };
    typedef ::Flatrock::regs_match_action_stage_        mau_regs;
    struct                              deparser_regs {
        ::Flatrock::memories_ingress_deparser           mdp_mem;
        ::Flatrock::memories_egress_deparser            dprsr_mem;
        ::Flatrock::regs_ingress_deparser               mdp;
        ::Flatrock::regs_egress_deparser                dprsr;
    };

    enum {
        PARSER_CHECKSUM_UNITS = 2,
        PARSER_EXTRACT_BYTES = true,
        PARSER_DEPTH_MAX_BYTES_INGRESS = (((1 << 10) - 1) * 16),
        PARSER_DEPTH_MAX_BYTES_EGRESS = (32 * 16),
        MATCH_BYTE_16BIT_PAIRS = false,
        MATCH_REQUIRES_PHYSID = true,
#ifdef EMU_OVERRIDE_STAGE_COUNT
        NUM_MAU_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        NUM_EGRESS_STAGES_PRIVATE = EMU_OVERRIDE_STAGE_COUNT,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 1,
#else
        // max of ingress and egress stages (ingress=16, egress=12)
        NUM_MAU_STAGES_PRIVATE = 16,
        NUM_EGRESS_STAGES_PRIVATE = 12,
        OUTPUT_STAGE_EXTENSION_PRIVATE = 0,
#endif
        ACTION_INSTRUCTION_MAP_WIDTH = 8,
        DEPARSER_CHECKSUM_UNITS = 4,
        DEPARSER_CONSTANTS = 0,
        DEPARSER_MAX_POV_BYTES = 16,
        DEPARSER_MAX_POV_PER_USE = 2,
        DEPARSER_CLOTS_PER_GROUP = 0,
        DEPARSER_MAX_FD_ENTRIES = 256,  // actuall up to 32 "strings", each up to 16 bytes
        DYNAMIC_CONFIG = 2,
        DYNAMIC_CONFIG_INPUT_BITS = 8,
        EGRESS_SEPARATE = true,
        END_OF_PIPE = 0xff,
        GATEWAY_PAYLOAD_GROUPS = 4,
        GATEWAY_SINGLE_XBAR_GROUP = false,
        INSTR_SRC2_BITS = 0,
        IMEM_COLORS = 4,
        IXBAR_HASH_GROUPS = 16,  // actually XME indexes
        IXBAR_HASH_INDEX_MAX = 45,
        IXBAR_HASH_INDEX_STRIDE = 1,
        LONG_BRANCH_TAGS = 32,
        MAU_BASE_DELAY = 23,
        MAU_BASE_PREDICATION_DELAY = 13,
        MAX_OVERHEAD_OFFSET = 128,
        MAX_OVERHEAD_OFFSET_NEXT = 128,
        METER_ALU_GROUP_DATA_DELAY = 15,
        NEXT_TABLE_EXEC_COMBINED = false,
        PHASE0_FORMAT_WIDTH = 128,  // FIXME -- what should it be?
        REQUIRE_TCAM_ID = true,
        SRAM_EGRESS_ROWS = 4,
        SRAM_GLOBAL_ACCESS = true,
        SRAM_INGRESS_ROWS = 6,
        SRAM_LAMBS_PER_STAGE = 8,
        SRAM_UNITS_PER_ROW = 8,
        STATEFUL_CMP_UNITS = 4,
        STATEFUL_CMP_ADDR_WIDTH = 2,
        STATEFUL_CMP_CONST_WIDTH = 6,
        STATEFUL_CMP_CONST_MASK = 0x3f,
        STATEFUL_CMP_CONST_MIN = -32,
        STATEFUL_CMP_CONST_MAX = 31,
        STATEFUL_TMATCH_UNITS = 2,
        STATEFUL_OUTPUT_UNITS = 4,
        STATEFUL_PRED_MASK = (1U << (1 << STATEFUL_CMP_UNITS)) - 1,
        STATEFUL_REGFILE_ROWS = 4,
        STATEFUL_REGFILE_CONST_WIDTH = 34,
        SUPPORT_ALWAYS_RUN = 1,
        HAS_MPR = 0,
        SUPPORT_CONCURRENT_STAGE_DEP = 0,
        SUPPORT_OVERFLOW_BUS = 0,
        SUPPORT_SALU_FAST_CLEAR = 1,
        STATEFUL_ALU_ADDR_WIDTH = 2,
        STATEFUL_ALU_CONST_WIDTH = 4,
        STATEFUL_ALU_CONST_MASK = 0xf,
        STATEFUL_ALU_CONST_MIN = -8,  // TODO Is the same as the following one?
        STATEFUL_ALU_CONST_MAX = 7,
        MINIMUM_INSTR_CONSTANT = -4,  // TODO
        NUM_PARSERS = 1,
        NUM_PIPES = 8,  // TODO what is the correct number here?
        TABLES_REQUIRE_ROW = 0,
        PARSER_CSUM_MASKS = 4,
        PARSER_CSUM_MASK_WIDTH = 7,
        PARSER_CSUM_MASK_REG_WIDTH = 32,  // Each checksum mask is written into 7 32b wide registers
        PARSER_CSUM_MASK_BITS = PARSER_CSUM_MASK_WIDTH * PARSER_CSUM_MASK_REG_WIDTH,
        PARSER_CSUM_MATCH_WIDTH = 32,
        PARSER_BRIDGE_MD_WIDTH = 64,
        PARSER_SEQ_ID_MAX = 254,  // Max value of header sequence ID; 255 reserved for escape value
        PARSER_HDR_ID_MAX = 254,  // Max value of hdr_id; 255 is reserved for invalid header
        PARSER_BASE_LEN_MAX = 255,
        PARSER_NUM_COMP_BITS_MAX = 15,
        PARSER_SCALE_MAX = 3,
        // Byte width of per-port metadata
        PARSER_PORT_METADATA_WIDTH = ::Flatrock::PARSER_PORT_METADATA_WIDTH,
        // Fpp_params.pm: N_PORT
        PARSER_PORT_METADATA_ITEMS = ::Flatrock::PARSER_PORT_METADATA_ITEMS,
        PARSER_PORT_METADATA_ITEM_MAX = 255,
        PARSER_INBAND_METADATA_WIDTH = 8,  // MD8
        PARSER_PROFILES = ::Flatrock::PARSER_PROFILES,  // Fpp_params.pm: N_PHV_TCAM_DEPTH
        PARSER_STATE_WIDTH = ::Flatrock::PARSER_STATE_WIDTH,  // 8 + 2 bytes
        PARSER_STATE_MATCH_WIDTH = 8,      // only lower 8 bytes participate in TCAM matching
        PARSER_FLAGS_WIDTH = ::Flatrock::PARSER_FLAGS_WIDTH,
        PARSER_PTR_MAX = ::Flatrock::PARSER_PTR_MAX,
        PARSER_W_WIDTH = ::Flatrock::PARSER_W_WIDTH,  // Width of W0, W1, W2 registers
        PARSER_W_OFFSET_MAX = ::Flatrock::PARSER_W_OFFSET_MAX,
        PARSER_PROFILE_PKTLEN_MAX = ::Flatrock::PARSER_PROFILE_PKTLEN_MAX,
        PARSER_PROFILE_SEGLEN_MAX = ::Flatrock::PARSER_PROFILE_SEGLEN_MAX,
        // 8bit port_info = {2'b0, logic_port#(6b)}
        PARSER_PROFILE_PORT_BIT_WIDTH = ::Flatrock::PARSER_PROFILE_PORT_BIT_WIDTH,
        PARSER_PROFILE_MD_SEL_NUM = ::Flatrock::PARSER_PROFILE_MD_SEL_NUM,
        PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC = 0x00,
        // Index of logical port number in port metadata array
        PARSER_PROFILE_MD_SEL_LOGICAL_PORT_NUMBER_INDEX = 15,
        PARSER_PROFILE_MD_SEL_INBAND_METADATA_ENC = 0x40,
        PARSER_PROFILE_MD_SEL_TIMESTAMP_ENC = 0x80,
        PARSER_PROFILE_MD_SEL_COUNTER_ENC = 0xc0,
        PARSER_PROFILE_MD_SEL_TIMESTAMP_INDEX_MAX = 7,
        PARSER_PROFILE_MD_SEL_COUNTER_INDEX_MAX = 7,
        PARSER_ANALYZER_STAGES = ::Flatrock::PARSER_ANALYZER_STAGES,
        PARSER_ANALYZER_STAGE_RULES = 24,
        PARSER_PRED_VEC_TCAM_DEPTH = 16,   // Fpp_params.pm: N_PHV_TCAM_DEPTH
        // Fpp_params.pm: N_PHV_TCAM
        PARSER_PHV_BUILDER_GROUPS = ::Flatrock::PARSER_PHV_BUILDER_GROUPS,
        PARSER_POV_SELECT_NUM = ::Flatrock::PARSER_POV_SELECT_NUM,
        // Fpp_params.pm: N_PHV_TCAM_DEPTH
        PARSER_PHV_BUILDER_GROUP_EXTRACTS_NUM = ::Flatrock::PARSER_PHV_BUILDER_GROUP_EXTRACTS_NUM,
        PARSER_PHV_BUILDER_GROUP_PHE8_MIN = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MIN,
        PARSER_PHV_BUILDER_GROUP_PHE8_MAX = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MAX,
        PARSER_PHV_BUILDER_GROUP_PHE16_MIN = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MIN,
        PARSER_PHV_BUILDER_GROUP_PHE16_MAX = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MAX,
        PARSER_PHV_BUILDER_GROUP_PHE32_MIN = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MIN,
        PARSER_PHV_BUILDER_GROUP_PHE32_MAX = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MAX,
        PARSER_PHV_BUILDER_GROUP_PHE_SOURCES = ::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES,
        PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES =
            ::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES,
        PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES =
            ::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES,
        PARSER_PHV_BUILDER_PACKET_PHE32_SOURCES =
            ::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE32_SOURCES,
        PARSER_PHV_BUILDER_OTHER_PHE_SOURCES = 4,
        PARSER_ALU0_OPCODE0_ENC = 0x0000,
        PARSER_ALU0_OPCODE1_ENC = 0x1000,
        PARSER_ALU0_OPCODE2_ENC = 0x2000,
        PARSER_ALU0_OPCODE3_ENC = 0x3000,
        PARSER_ALU0_OPCODE4_ENC = 0x4000,
        PARSER_ALU0_OPCODE5_ENC = 0x5000,
        PARSER_ALU0_OPCODE6_ENC = 0x6000,
        PARSER_ALU0_RESERVED_ENC = 0x7000,
        PARSER_ALU1_OPCODE0_ENC = 0x0000,
        PARSER_ALU1_OPCODE1_ENC = 0x10000,
        PARSER_ALU1_OPCODE2_ENC = 0x20000,
        PARSER_ALU1_OPCODE3_ENC = 0x30000,
        PARSER_ALU1_OPCODE4_ENC = 0x40000,
        PARSER_ALU1_OPCODE5_ENC = 0x50000,
        PARSER_ALU1_OPCODE6_ENC = 0x60000,
        PARSER_ALU1_OPCODE7_ENC = 0x70000,
        POV_WIDTH = 128,
        DEPARSER_PBO_VAR_OFFSET_LEN_WIDTH_MAX = 9,  // Payload body offset: maximum length of the
                                                    // variable offset component. The length
                                                    // in the config register must be in the range
                                                    // [0, DEPARSER_PBO_VAR_OFFSET_LEN_MAX].
        MDP_HDR_ID_COMP_ROWS = 255,
    };
    static int encodeConst(int src) {
        return src;
    }
};
void declare_registers(const Target::Flatrock::top_level_regs *regs);
void undeclare_registers(const Target::Flatrock::top_level_regs *regs);
void declare_registers(const Target::Flatrock::parser_regs *regs);
void undeclare_registers(const Target::Flatrock::parser_regs *regs);
void declare_registers(const Target::Flatrock::mau_regs *regs, int stage);
void declare_registers(const Target::Flatrock::deparser_regs *regs);

void emit_parser_registers(const Target::Flatrock::top_level_regs *regs, std::ostream &);

#endif  /* HAVE_FLATROCK */

/** Macro to buid a switch table switching on a target_t, expanding to the same
 *  code for each target, with TARGET being a typedef for the target type */
#define SWITCH_FOREACH_TARGET(VAR, ...)                         \
        switch (VAR) {                                          \
        FOR_ALL_TARGETS(DO_SWITCH_FOREACH_TARGET, __VA_ARGS__)  \
        default: BUG("invalid target"); }

#define DO_SWITCH_FOREACH_TARGET(TARGET_, ...)                  \
        case Target::TARGET_::tag: {                            \
            typedef Target::TARGET_  TARGET;                    \
            __VA_ARGS__                                         \
            break; }

#endif /* BF_ASM_TARGET_H_ */
