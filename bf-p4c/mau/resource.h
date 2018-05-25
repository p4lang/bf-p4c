#ifndef BF_P4C_MAU_RESOURCE_H_
#define BF_P4C_MAU_RESOURCE_H_

#include <map>
#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/table_format.h"
#include "ir/ir.h"
#include "lib/safe_vector.h"

struct TableResourceAlloc {
    IXBar::Use                          match_ixbar, gateway_ixbar, selector_ixbar,
                                        salu_ixbar, meter_ixbar;
    safe_vector<IXBar::HashDistUse>     hash_dists;
    TableFormat::Use                    table_format;
    std::map<cstring, Memories::Use>    memuse;
    ActionFormat::Use                   action_format;
    ActionDataBus::Use                  action_data_xbar;
    InstructionMemory::Use              instr_mem;
    TableResourceAlloc *clone_ixbar() const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        rv->selector_ixbar = selector_ixbar;
        rv->salu_ixbar = salu_ixbar;
        rv->meter_ixbar = meter_ixbar;
        rv->table_format = table_format;
        // NOT cloning memuse
        rv->action_format = action_format;
        rv->hash_dists = hash_dists;
        rv->action_data_xbar = action_data_xbar;
        rv->instr_mem = instr_mem;
        return rv; }
    TableResourceAlloc *clone_rename(cstring ext, const cstring name) const {
        TableResourceAlloc *rv = clone_ixbar();
        for (auto &use : memuse) {
            if (name == use.first) {
                rv->memuse.emplace(name + ext, use.second);
                auto &unattached = rv->memuse.at(name + ext).unattached_tables;
                unattached.clear();
                for (auto entry : use.second.unattached_tables) {
                    cstring back = entry.first.findlast('$');
                    if (back)
                        unattached.emplace(name + ext + back, entry.second);
                    else
                        unattached.emplace(name + ext, entry.second);
                }
            } else {
                cstring back = use.first.findlast('$');
                if (back)
                    rv->memuse.emplace(name + ext + back, use.second);
                else
                    rv->memuse.emplace(use.first + ext, use.second);
            }
        }
        return rv; }
    TableResourceAlloc *clone_atcam(const IR::MAU::Table *tbl, int logical_table,
                                    cstring suffix) const;
    TableResourceAlloc *clone_dleft(const IR::MAU::Table *tbl, int logical_table,
                                    cstring suffix) const;
    void clear_ixbar() {
        match_ixbar.clear();
        gateway_ixbar.clear();
        selector_ixbar.clear();
        salu_ixbar.clear();
        meter_ixbar.clear();
        hash_dists.clear();
    }
    void clear() {
        clear_ixbar();
        table_format.clear();
        memuse.clear();
        action_format.clear();
        action_data_xbar.clear();
        instr_mem.clear();
    }
    void toJSON(JSONGenerator &json) const { json << "null"; }
    static TableResourceAlloc *fromJSON(JSONLoader &) { return nullptr; }
};

#endif /* BF_P4C_MAU_RESOURCE_H_ */
