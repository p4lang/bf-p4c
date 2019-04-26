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

/**
 * A ternary indirect table might have been created, when the original layout did not have
 * one, as a gateway is overriding the original TCAM table.
 */
bool TableResourceAlloc::has_tind() const {
    bool rv = false;
    for (auto &kv : memuse) {
        if (kv.second.type != Memories::Use::TIND)
            continue;
        rv = true;
        break;
    }
    if (rv)
        BUG_CHECK(table_format.has_overhead(), "A ternary indirect table is currently "
            "required with no overhead");
    return rv;
}
