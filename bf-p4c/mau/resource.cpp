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

/**
 * Return a 2 entry vector indicating which fields are headed to HashDist Immed Lo and
 * HashDist Immediate Hi.  If the hash dist is not used, the a -1 will be returned.
 */
safe_vector<int> TableResourceAlloc::hash_dist_immed_units() const {
    safe_vector<int> rv;
    for (int i = IXBar::HD_IMMED_LO; i <= IXBar::HD_IMMED_HI; i++) {
        int unit = -1;
        for (auto &hd : hash_dists) {
            if (hd.destinations().getbit(i)) {
                BUG_CHECK(unit == -1, "Multiple HashDistUse objects cannot head to the same "
                    "output destination");
                unit = hd.unit;
            }
        }
        rv.push_back(unit);
    }
    return rv;
}

/**
 * Returns which rng unit has been assigned to this table
 */
int TableResourceAlloc::rng_unit() const {
    int rv = -1;
    if (action_data_xbar.rng_locs.empty())
        return rv;
    BUG_CHECK(action_data_xbar.rng_locs.size() == 1, "Current allocation can only allocate one "
        "rng unit per table");
    return action_data_xbar.rng_locs.at(0).unit;
}
