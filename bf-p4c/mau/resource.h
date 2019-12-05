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
    // TODO: Currently we only have a std::map for the UniqueId objects for Memories.  This would
    // make sense to eventually move to IXBar::Use, and even potentially
    // ActionFormat::Use/ActionDataBus::Use for the different types of allocations
    IXBar::Use                          match_ixbar, gateway_ixbar, proxy_hash_ixbar,
                                        selector_ixbar, salu_ixbar, meter_ixbar;
    safe_vector<IXBar::HashDistUse>     hash_dists;
    TableFormat::Use                    table_format;
    std::map<UniqueId, Memories::Use>   memuse;
    ActionData::Format::Use             action_format;
    MeterALU::Format::Use               meter_format;
    ActionDataBus::Use                  action_data_xbar, meter_xbar;
    InstructionMemory::Use              instr_mem;
    TableResourceAlloc *clone() const { return new TableResourceAlloc(*this); }
    TableResourceAlloc *rename(const IR::MAU::Table *tbl, int stage_table = -1,
                               int logical_table = -1);

    void clear_ixbar() {
        match_ixbar.clear();
        gateway_ixbar.clear();
        proxy_hash_ixbar.clear();
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
        meter_format.clear();
        meter_xbar.clear();
    }
    void toJSON(JSONGenerator &json) const { json << "null"; }
    static TableResourceAlloc *fromJSON(JSONLoader &) { return nullptr; }

    bool has_tind() const;
    safe_vector<int> hash_dist_immed_units() const;
    int rng_unit() const;
};

std::ostream &operator<<(std::ostream &, const TableResourceAlloc &);

#endif /* BF_P4C_MAU_RESOURCE_H_ */