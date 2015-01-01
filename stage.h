#ifndef _stage_h_
#define _stage_h_

#include "tables.h"
#include <vector>
#include "alloc.h"
#include "gen/regs.mau_addrmap.h"

enum {
    /* global constants related to MAU stage */
    NUM_MAU_STAGES = 12,
    LOGICAL_TABLES_PER_STAGE = 16,
    SRAM_ROWS = 8,
    SRAM_UNITS_PER_ROW = 12,
    TCAM_ROWS = 16,
    TCAM_UNITS_PER_ROW = 2,
    NEXT_TABLE_SUCCESSOR_TABLE_DEPTH = 8,
    ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH = 8,
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
    Alloc1D<std::vector<InputXbar *>, 8>                exact_ixbar;
    Alloc1D<std::vector<InputXbar *>, 16>               tcam_ixbar;
    int                         pass1_logical_id;
    regs_match_action_stage_    regs;
    Stage() {
        declare_registers(&regs, sizeof(regs), [this](std::ostream &out, const char *addr) {
            out << "mau[" << stageno << "]";
            regs.emit_fieldname(out, addr);
        }); }
    ~Stage() { undeclare_registers(&regs); }
};

#endif /* _stage_h_ */
