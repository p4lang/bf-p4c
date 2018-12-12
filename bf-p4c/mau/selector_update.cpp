#include "selector_update.h"
#include <vector>

bool AddSelectorSalu::AddSaluIfNeeded::preorder(IR::MAU::Table *tbl) {
    std::vector<const IR::MAU::StatefulAlu *> toAdd;
    for (auto &att : tbl->attached) {
        if (auto sel = att->attached->to<IR::MAU::Selector>()) {
            if (!self.sel2salu[sel]) {
                auto *salu = new IR::MAU::StatefulAlu(sel);
                salu->name = IR::ID(sel->name + "$salu");
                salu->width = 1;
                salu->size = 120*1024;  // FIXME -- how should this be set?
                salu->synthetic_for_selector = true;
                self.sel2salu[sel] = salu; }
            toAdd.push_back(self.sel2salu[sel]); } }
    for (auto salu : toAdd)
        tbl->attached.push_back(new IR::MAU::BackendAttached(salu));
    return true;
}
