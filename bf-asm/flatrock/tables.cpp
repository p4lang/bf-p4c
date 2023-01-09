#include "stage.h"
#include "tables.h"

/* STM is confusingly orgainzed into "units" each of which contain 2 rams, left and right.
 * So a "column" number might be a "unit" column or a "ram" column, with 2 "ram" columns
 * per "unit" column.  Unit columns are 0-4 in each stage, while ram columns are 0-9 */

/* here lo_col/hi_col are "unit" column numbers in the stage */
void Table::alloc_global_bus(Layout &row, Layout::bus_type_t bus_kind, int lo_stage,
                                      int lo_col, int hi_stage, int hi_col) {
    if (!row.bus.count(bus_kind)) {
        if (!row.bus.count(Layout::SEARCH_BUS))
            error(row.lineno, "No %s allocated on row %d of %s", to_string(bus_kind).c_str(),
                  row.row, name());
        else
            row.bus[bus_kind] = row.bus.at(Layout::SEARCH_BUS); }
    if (row.bus.count(bus_kind)) {
        int hbus = row.bus.at(bus_kind) + Target::SRAM_HBUSSES_PER_ROW()/2;
        for (int st = lo_stage; st <= hi_stage; st++) {
            int lim = st == hi_stage ? hi_col
                    : Target::SRAM_HBUS_SECTIONS_PER_STAGE();
            for (int c = st == lo_stage ? lo_col : 0; c < lim; ++c) {
                auto &old = Stage::stage(gress, st)->stm_hbus_use.at(row.row, c, hbus);
                if (old)
                    error(row.lineno, "%s wants to use %s %d:%d:%d:%d, already in "
                          "use by %s", name(), to_string(bus_kind).c_str(), row.row, st, c,
                          hbus - Target::SRAM_HBUSSES_PER_ROW()/2, old->name());
                else
                    old = this; } } }
}

void Table::alloc_global_busses() {
    int tbl_stage = stage->stageno;
    int tbl_col = stm_vbus_column();
    for (auto &row : layout) {
        int minstage, mincol, maxstage, maxcol;
        Target::Flatrock::stage_col_range(row.memunits, minstage, mincol, maxstage, maxcol);
        if (minstage == tbl_stage ? mincol/2 < tbl_col : minstage < tbl_stage) {
            alloc_global_bus(row, Layout::R2L_BUS, minstage, mincol/2, tbl_stage, tbl_col); }
        if (maxstage == tbl_stage ? maxcol/2 > tbl_col : maxstage > tbl_stage) {
            alloc_global_bus(row, Layout::L2R_BUS, tbl_stage, tbl_col, maxstage, maxcol/2); }
    }
}

void Table::alloc_global_srams() {
    for (auto &row : layout) {
        for (auto &ram : row.memunits) {
            try {
                BUG_CHECK(ram.stage >= 0 && ram.row == row.row, "invalid ram");
                auto &use = AsmStage::stages(gress).at(ram.stage).sram_use[ram.row][ram.col];
                if (use && !allow_ram_sharing(this, use))
                    error(lineno, "Table %s trying to use %s which is already in use "
                          "by table %s", name(), ram.desc(), use->name());
                use = this;
            } catch(std::out_of_range) {
                error(lineno, "Table %s using out-of-bounds %s", name(), ram.desc());
            }
        }
    }
}

void Table::alloc_global_tcams() {
    for (auto &row : layout) {
        for (auto &ram : row.memunits) {
            int istage = gress != EGRESS ? ram.stage
                       : Target::Flatrock::EGRESS_STAGE0_INGRESS_STAGE - ram.stage;
            try {
                BUG_CHECK(ram.row == row.row, "invalid ram");
                auto *stage = &AsmStage::stages(INGRESS).at(istage);
                auto &use = stage->tcam_use[ram.row][ram.col];
                if (use && !allow_ram_sharing(this, use))
                    error(lineno, "Table %s trying to use %s which is already in use "
                          "by table %s", name(), ram.desc(), use->name());
                use = this;
            } catch(std::out_of_range) {
                auto tmp = ram;
                tmp.stage = istage;
                error(lineno, "Table %s using out-of-bounds TCAM %s", name(), tmp.desc());
            }
        }
    }
}
