#ifndef _constants_h_
#define _constants_h_

enum {
    /* global constants related to MAU stage */
    LOGICAL_TABLES_PER_STAGE = 16,
    TCAM_TABLES_PER_STAGE = 8,
    SRAM_ROWS = 8,
    LOGICAL_SRAM_ROWS = 16,
    SRAM_UNITS_PER_ROW = 12,
    MAPRAM_UNITS_PER_ROW = 6,
    MEM_WORD_WIDTH = 128,
    TCAM_ROWS = 12,
    TCAM_UNITS_PER_ROW = 2,
    TCAM_XBAR_GROUPS = 12,
    TCAM_XBAR_GROUP_SIZE = 44,
    TCAM_VPN_BITS = 6,
    TCAM_WORD_BITS = 9,
    EXACT_XBAR_GROUPS = 8,
    EXACT_XBAR_GROUP_SIZE = 128,
    HASH_TABLES = 16,
    EXACT_HASH_GROUPS = 8,
    EXACT_HASH_GROUP_SIZE = 52,
    EXACT_HASH_ADR_BITS = 10,
    EXACT_HASH_ADR_GROUPS = 5,
    EXACT_HASH_SELECT_BITS = 12,
    EXACT_HASH_FIRST_SELECT_BIT = EXACT_HASH_GROUP_SIZE - EXACT_HASH_SELECT_BITS,
    EXACT_VPN_BITS = 9,
    EXACT_WORD_BITS = 10,
    NEXT_TABLE_SUCCESSOR_TABLE_DEPTH = 8,
    MAX_IMMED_ACTION_DATA = 32,
    ACTION_DATA_8B_SLOTS = 16,
    ACTION_DATA_16B_SLOTS = 24,
    ACTION_DATA_32B_SLOTS = 16,
    ACTION_DATA_BUS_SLOTS = ACTION_DATA_8B_SLOTS +
                            ACTION_DATA_16B_SLOTS +
                            ACTION_DATA_32B_SLOTS,
    ACTION_DATA_BUS_BYTES = ACTION_DATA_8B_SLOTS +
                          2*ACTION_DATA_16B_SLOTS +
                          4*ACTION_DATA_32B_SLOTS,
    ACTION_HV_XBAR_SLICES = 8,
    ACTION_HV_XBAR_SLICE_SIZE = 16,
    ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH = 8,
    ACTION_INSTRUCTION_ADR_ENABLE = 0x40,
    ACTION_IMEM_SLOTS = 32,
    ACTION_IMEM_COLORS = 2,
    ACTION_IMEM_ADDR_MAX = ACTION_IMEM_SLOTS*ACTION_IMEM_COLORS,
    SELECTOR_PORTS_PER_WORD = 120,
    STATEFUL_PREDICATION_ENCODE_NOOP = 0,
    STATEFUL_PREDICATION_ENCODE_NOTCMPHI = 3,
    STATEFUL_PREDICATION_ENCODE_NOTCMPLO = 5,
    STATEFUL_PREDICATION_ENCODE_CMPLO = 0xaaaa,
    STATEFUL_PREDICATION_ENCODE_CMPHI = 0xcccc,
    STATEFUL_PREDICATION_ENCODE_CMP0 = 0xaaaa,
    STATEFUL_PREDICATION_ENCODE_CMP1 = 0xcccc,
    STATEFUL_PREDICATION_ENCODE_CMP2 = 0xf0f0,
    STATEFUL_PREDICATION_ENCODE_CMP3 = 0xff00,
    STATEFUL_PREDICATION_ENCODE_UNCOND = 0xffff,
    METER_ALU_GROUP_DATA_DELAY = 13,
    TYPE_ENUM_SHIFT = 24,
    ACTION_HANDLE_START = (0x20 << TYPE_ENUM_SHIFT),
    METER_TYPE_BITS = 3,
    //Order is METER_TYPE, METER_PFE, METER_ADDRESS
    METER_TYPE_START_BIT = 24,
    METER_LOWER_HUFFMAN_BITS = 7,
    METER_ADDRESS_BITS = 27,
    METER_ADDRESS_ZERO_PAD = 23,
    METER_PER_FLOW_ENABLE_START_BIT = 23,
    IDLETIME_ADDRESS_PER_FLOW_ENABLE_START_BIT = 20,
    IDLETIME_ADDRESS_BITS = 21,
    IDLETIME_HUFFMAN_BITS = 4,
    SELECTOR_METER_TYPE_START_BIT = METER_TYPE_START_BIT,
    SELECTOR_LOWER_HUFFMAN_BITS = METER_LOWER_HUFFMAN_BITS,
    SELECTOR_METER_ADDRESS_BITS = METER_ADDRESS_BITS,
    SELECTOR_PER_FLOW_ENABLE_START_BIT = METER_PER_FLOW_ENABLE_START_BIT,
    SELECTOR_VHXBAR_HASH_BUS_INDEX = 3,
    STAT_ADDRESS_BITS = 20,
    STAT_ADDRESS_ZERO_PAD = 7,
    STATISTICS_PER_FLOW_ENABLE_START_BIT = 19,
    STATISTICS_PER_FLOW_SHIFT_COUNT = 7,
    ACTION_ADDRESS_BITS = 23,
    ACTION_DATA_PER_FLOW_ENABLE_START_BIT = ACTION_ADDRESS_BITS - 1,
    // FIXME-COMPILER: Parser header length adjust values should be picked up
    // from assembly
    INGRESS_PARSER_HEADER_LENGTH_ADJUST = 16,
    EGRESS_PARSER_HEADER_LENGTH_ADJUST = 2,
    MAX_PORTS = 288
};

enum METER_ACCESS_TYPE {
    NOP = 0,
    METER_LPF_COLOR_BLIND = 2,
    METER_SELECTOR = 4,
    METER_COLOR_AWARE = 6,
    STATEFUL_INSTRUCTION_0 = 1,
    STATEFUL_INSTRUCTION_1 = 3,
    STATEFUL_INSTRUCTION_2 = 5,
    STATEFUL_INSTRUCTION_3 = 7
};

/* constants for various config params */
#include <math.h>
#undef OVERFLOW         /* get rid of global preproc define from math.h */
namespace UnitRam {
    enum {
        MATCH = 1,
        ACTION = 2,
        STATISTICS = 3,
        METER = 4,
        STATEFUL = 5,
        TERNARY_INDIRECTION = 6,
        SELECTOR = 7,
        HASH_ACTION = 8,
    };
    namespace DataMux {
        enum {
            STATISTICS = 0,
            METER = 1,
            OVERFLOW = 2,
            OVERFLOW2 = 3,
            ACTION = 4,
            NONE = 7,
        };
    }
    namespace AdrMux {
        enum {
            ACTION = 1,
            TERNARY_INDIRECTION = 2,
            OVERFLOW = 4,
            STATS_METERS = 5,
            SELECTOR_ALU = 6,
            SELECTOR_OVERFLOW = 7,
            SELECTOR_ACTION_OVERFLOW = 8,
        };
    }
}
namespace AdrDist {
    enum {
        ACTION = 0,
        STATISTICS = 1,
        METER = 2,
        OVERFLOW = 3,
    };
}
namespace MapRam {
    enum {
        STATISTICS = 1,
        METER = 2,
        STATEFUL = 3,
        IDLETIME = 4,
        COLOR = 5,
        SELECTOR_SIZE = 6,
    };
    namespace Mux {
        enum {
            SYSTEM = 0,
            SYNTHETIC_TWO_PORT = 1,
            IDLETIME = 2,
            COLOR = 3,
        };
    }
    namespace ColorBus {
        enum {
            NONE = 0,
            COLOR = 1,
            OVERFLOW = 2,
            OVERFLOW_2 = 3,
        };
    };
}
namespace BusHashGroup {
    enum {
        SELECTOR_MOD = 0,
        METER_ADDRESS = 1,
        STATISTICS_ADDRESS = 2,
        ACTION_DATA_ADDRESS = 3,
        IMMEDIATE_DATA = 4,
    };
}
namespace MoveReg {
    enum {
        STATS = 0,
        METER = 1,
        IDLE = 2,
    };
}
#endif /* _constants_h_ */
