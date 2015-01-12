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
    TCAM_ROWS = 16,
    TCAM_UNITS_PER_ROW = 2,
    NEXT_TABLE_SUCCESSOR_TABLE_DEPTH = 8,
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
    bitvec      imem_addr_use[2], imem_use[ACTION_IMEM_SLOTS];
    enum { NONE=0, USE_TCAM=1, USE_STATEFUL=2, USE_TCAM_PIPED=4, };
    int                 table_use[2];
    bitvec              phv_use[2];

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
};

#endif /* _stage_h_ */
