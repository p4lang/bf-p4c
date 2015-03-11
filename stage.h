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
    SRAM_UNITS_PER_ROW = 12,
    TCAM_ROWS = 12,
    TCAM_UNITS_PER_ROW = 2,
    TCAM_XBAR_GROUPS = 16,
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
    bitvec      imem_addr_use[2], imem_use[ACTION_IMEM_SLOTS];
    enum { NONE=0, USE_TCAM=1, USE_TCAM_PIPED=2, USE_STATEFUL=4,
            USE_METER=8, USE_SELECTOR=16, };

    int                 table_use[2];
    bitvec              match_use[2], action_use[2], action_set[2];
    static unsigned char action_bus_slot_map[ACTION_DATA_BUS_BYTES];
    static unsigned char action_bus_slot_size[ACTION_DATA_BUS_SLOTS];

    int                         pass1_logical_id, pass1_tcam_id;
    regs_match_action_stage_    regs;
    Stage() {
        table_use[0] = table_use[1] = NONE;
        declare_registers(&regs, sizeof(regs),
            [this](std::ostream &out, const char *addr, const void *end) {
                out << "mau[" << stageno << "]";
                regs.emit_fieldname(out, addr, end); }); }
    ~Stage() { undeclare_registers(&regs); }
    void write_regs();

    int find_on_ixbar(Phv::Slice, int group);
};

#endif /* _stage_h_ */
