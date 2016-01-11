#ifndef _stage_h_
#define _stage_h_

#include "tables.h"
#include <vector>
#include "alloc.h"
#include "bitvec.h"
#include "gen/regs.mau_addrmap.h"

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
};

class Stage_data {
    /* we encapsulate all the Stage non-static fields in a base class to automate the
     * generation of the move construtor properly */
public:
    int                         stageno;
    std::vector<Table *>        tables;
    std::set<Stage **>          all_refs;
    Alloc2D<Table *, SRAM_ROWS, SRAM_UNITS_PER_ROW>     sram_use;
    Alloc2D<Table *, SRAM_ROWS, 2>                      sram_match_bus_use;
    Alloc2D<Table *, SRAM_ROWS, MAPRAM_UNITS_PER_ROW>   mapram_use;
    Alloc2D<Table *, TCAM_ROWS, TCAM_UNITS_PER_ROW>     tcam_use;
    Alloc2D<Table *, TCAM_ROWS, 2>                      tcam_match_bus_use;
    Alloc2D<Table *, SRAM_ROWS, 2>                      tcam_indirect_bus_use;
    Alloc1D<Table *, LOGICAL_TABLES_PER_STAGE>          logical_id_use;
    Alloc1D<Table *, TCAM_TABLES_PER_STAGE>          	tcam_id_use;
    Alloc1D<std::vector<InputXbar *>, 16>               exact_ixbar;
    Alloc1D<std::vector<InputXbar *>, TCAM_XBAR_GROUPS> tcam_ixbar;
    Alloc1D<std::vector<HashDistribution *>, 6>         hash_dist_use;
    Alloc1D<Table *, ACTION_DATA_BUS_SLOTS>             action_bus_use;
    Alloc1D<Table *, LOGICAL_SRAM_ROWS>                 action_data_use,
                                                        meter_bus_use,
                                                        stats_bus_use,
                                                        overflow_bus_use;
    Alloc2D<Table::Actions::Action *, 2, ACTION_IMEM_ADDR_MAX>		imem_addr_use;
    bitvec      imem_use[ACTION_IMEM_SLOTS];
    enum { USE_TCAM=1, USE_TCAM_PIPED=2, USE_STATEFUL=4, USE_METER=8,
           USE_SELECTOR=16, USE_WIDE_SELECTOR=32 };
    int /* enum */      table_use[2], group_table_use[2];
    enum { NONE=0, CONCURRENT=1, ACTION_DEP=2, MATCH_DEP=3 } stage_dep[2];
    bitvec              match_use[2], action_use[2], action_set[2];
    enum { NO_CONFIG=0, PROPAGATE, MAP_TO_IMMEDIATE, DISABLE_ALL_TABLES }
    			error_mode[2];

    int                         pass1_logical_id, pass1_tcam_id;
    regs_match_action_stage_    regs;
protected:
    Stage_data() {}
    Stage_data(const Stage_data &) = delete;
    Stage_data(Stage_data &&) = default;
    ~Stage_data() {}
};

class Stage : public Stage_data {
public:
    static unsigned char action_bus_slot_map[ACTION_DATA_BUS_BYTES];
    static unsigned char action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

    Stage();
    Stage(Stage &&);
    ~Stage();
    void write_regs();
    int adr_dist_delay(gress_t gress);
    int pipelength(gress_t gress);
    int pred_cycle(gress_t gress);
    int tcam_delay(gress_t gress);
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

#endif /* _stage_h_ */
