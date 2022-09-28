#include "stage.h"
#include "tables.h"

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
            try {
                BUG_CHECK(ram.stage >= 0 && ram.row == row.row, "invalid ram");
                auto *stage = &AsmStage::stages(gress).at(ram.stage);
                if (stage->shared_tcam_stage)
                    stage = stage->shared_tcam_stage;
                auto &use = stage->tcam_use[ram.row][ram.col];
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
