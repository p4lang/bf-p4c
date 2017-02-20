#ifndef _constants_h_
#define _constants_h_

enum {
    /* global constants related to MAU stage */
    NUM_MAU_STAGES = 12,
    LOGICAL_TABLES_PER_STAGE = 16,
    TCAM_TABLES_PER_STAGE = 8,
    SRAM_ROWS = 8,
    LOGICAL_SRAM_ROWS = 16,
    SRAM_UNITS_PER_ROW = 12,
    MAPRAM_UNITS_PER_ROW = 6,
    TCAM_ROWS = 12,
    TCAM_UNITS_PER_ROW = 2,
    TCAM_XBAR_GROUPS = 12,
    TCAM_XBAR_GROUP_SIZE = 44,
    EXACT_XBAR_GROUPS = 8,
    EXACT_XBAR_GROUP_SIZE = 128,
    HASH_TABLES = 16,
    EXACT_HASH_GROUPS = 8,
    EXACT_HASH_GROUP_SIZE = 52,
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
    ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH = 8,
    ACTION_IMEM_SLOTS = 32,
    ACTION_IMEM_COLORS = 2,
    ACTION_IMEM_ADDR_MAX = ACTION_IMEM_SLOTS*ACTION_IMEM_COLORS,
    SELECTOR_PORTS_PER_WORD = 120,
};

/* constants for various config params */
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
