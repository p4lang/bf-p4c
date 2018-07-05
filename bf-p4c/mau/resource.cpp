#include "resource.h"

TableResourceAlloc *TableResourceAlloc::clone_rename(const IR::MAU::Table *tbl, int stage_table,
        int logical_table) const {
    TableResourceAlloc *rv = clone_ixbar();
    UniqueId u_id = tbl->pp_unique_id();
    u_id.stage_table = stage_table;
    u_id.logical_table = logical_table;

    // Only keep resource nodes that are part of the same stage table and logical table
    for (auto &kv : memuse) {
        auto key_u_id = kv.first;
        if (u_id.equal_table(key_u_id)) {
            rv->memuse[kv.first] = kv.second;
        }
    }
    return rv;
}
