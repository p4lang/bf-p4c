#include <vector>
#include "selector_update.h"
#include "backends/tofino/mau/resource_estimate.h"

bool AddSelectorSalu::AddSaluIfNeeded::preorder(IR::MAU::Table *tbl) {
    std::vector<const IR::MAU::StatefulAlu *> toAdd;
    for (auto &att : tbl->attached) {
        if (auto sel = att->attached->to<IR::MAU::Selector>()) {
            if (!self.sel2salu[sel]) {
                auto *salu = new IR::MAU::StatefulAlu(sel);
                salu->name = IR::ID(sel->name + "$salu");
                salu->width = 1;
                // JIRA-DOC: P4C-2388:
                // For the driver, the size of the stateful ALU must be the exact
                // number of entries within the stateful SRAM
                int ram_lines = SelectorRAMLinesPerEntry(sel);
                ram_lines *= sel->num_pools;
                ram_lines = ((ram_lines + 1023) / 1024) * 1024;
                salu->size = ram_lines * 128;
                salu->synthetic_for_selector = true;
                self.sel2salu[sel] = salu; }
            toAdd.push_back(self.sel2salu[sel]); } }
    for (auto salu : toAdd)
        tbl->attached.push_back(new IR::MAU::BackendAttached(salu));
    return true;
}
