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
    TCAM_ROWS = 12,
    TCAM_UNITS_PER_ROW = 2,
    TCAM_XBAR_GROUPS = 12,
    EXACT_XBAR_GROUPS = 8,
    EXACT_HASH_GROUPS = 8,
    NEXT_TABLE_SUCCESSOR_TABLE_DEPTH = 8,
    MAX_IMMED_ACTION_DATA = 32,
    ACTION_DATA_8B_SLOTS = 16,
    ACTION_DATA_16B_SLOTS = 28,
    ACTION_DATA_32B_SLOTS = 22,
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

class Stage {
public:
    friend class AsmStage;
    int                         stageno;
    std::vector<Table *>        tables;
    Alloc2D<Table *, SRAM_ROWS, SRAM_UNITS_PER_ROW>     sram_use;
    Alloc2D<Table *, SRAM_ROWS, 2>                      sram_match_bus_use;
    Alloc2D<Table *, TCAM_ROWS, TCAM_UNITS_PER_ROW>     tcam_use;
    Alloc2D<Table *, TCAM_ROWS, 2>                      tcam_match_bus_use;
    Alloc2D<Table *, SRAM_ROWS, 2>                      tcam_indirect_bus_use;
    Alloc1D<Table *, LOGICAL_TABLES_PER_STAGE>          logical_id_use;
    Alloc1D<Table *, TCAM_TABLES_PER_STAGE>          	tcam_id_use;
    Alloc1D<std::vector<InputXbar *>, 8>                exact_ixbar;
    Alloc1D<std::vector<InputXbar *>, 16>               tcam_ixbar;
    Alloc1D<Table *, ACTION_DATA_BUS_SLOTS>             action_bus_use;
    Alloc1D<Table *, LOGICAL_SRAM_ROWS>                 action_data_use,
                                                        meter_use, stats_use, overflow_use;
    bitvec      imem_addr_use[2], imem_use[ACTION_IMEM_SLOTS];
    enum { USE_TCAM=1, USE_TCAM_PIPED=2, USE_STATEFUL=4,
           USE_METER=8, USE_SELECTOR=16, };
    int /* enum */      table_use[2], group_table_use[2];
    enum { NONE=0, CONCURRENT=1, ACTION_DEP=2, MATCH_DEP=3 } stage_dep[2];
    bitvec              match_use[2], action_use[2], action_set[2];
    static unsigned char action_bus_slot_map[ACTION_DATA_BUS_BYTES];
    static unsigned char action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

    int                         pass1_logical_id, pass1_tcam_id;
    regs_match_action_stage_    regs;
    Stage() {
        table_use[0] = table_use[1] = NONE;
        stage_dep[0] = stage_dep[1] = NONE;
        declare_registers(&regs, sizeof(regs),
            [this](std::ostream &out, const char *addr, const void *end) {
                out << "mau[" << stageno << "]";
                regs.emit_fieldname(out, addr, end); }); }
    ~Stage() { undeclare_registers(&regs); }
    void write_regs();
    struct P4TableInfo {
        json::map       *desc;
        json::vector    *stage_tables;
        P4TableInfo() : desc(0), stage_tables(0) {}
    };
    static std::map<std::string, P4TableInfo>   p4_tables;
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

#endif /* _stage_h_ */
