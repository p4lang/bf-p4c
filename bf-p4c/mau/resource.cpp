#include "resource.h"

/** The goal of this function is to correctly the Memories::Use map from the original Placed
 *  object into the multiple logical tables created for the ATCAM table.  All indirectly
 *  attached object are saved in the Memories::Use object of the first logical table in
 *  the stage.  The direct action table resources is saved with the corresponding direct
 *  logical table.
 */
TableResourceAlloc *TableResourceAlloc::clone_atcam(const IR::MAU::Table *tbl,
    int logical_table, cstring suffix) const {
    TableResourceAlloc *rv = clone_ixbar();

    auto orig_atcam_name = tbl->get_use_name(nullptr, false, 0, logical_table);
    auto atcam_name = orig_atcam_name;
    if (!suffix.isNullOrEmpty())
        atcam_name += suffix;

    rv->memuse.emplace(atcam_name, memuse.at(orig_atcam_name));
    auto &atcam_alloc = rv->memuse[atcam_name];

    for (auto at : tbl->attached) {
        auto orig_at_use_name = tbl->get_use_name(at);
        if (at->direct)
            orig_at_use_name = tbl->get_use_name(at, false, 0, logical_table);

        auto at_use_name = tbl->get_use_name(at, false, 0, logical_table);
        if (!suffix.isNullOrEmpty()) {
            auto back = at_use_name.findlast('$');
            BUG_CHECK(back != nullptr, "Every attached table should have a $ in the "
                      "assembly name");
            BUG_CHECK(orig_atcam_name == at_use_name.before(back), "Atcam name alignment "
                      "does not match up correctly");
            at_use_name = atcam_name + back;
        }
        if (!at->direct) {
            bool already_unattached = memuse.find(orig_at_use_name) == memuse.end();
            // Indirectly accessed tables.  Attach the Memories::Use to the first
            // logical table, unless the Memories::Use table is associated with another table
            // already
            if (!already_unattached) {
                if (logical_table == 0) {
                    rv->memuse.emplace(at_use_name, memuse.at(orig_at_use_name));
                } else {
                    auto lt_0_name = tbl->get_use_name(nullptr, false, 0, 0);
                    atcam_alloc.unattached_tables.emplace(at_use_name, lt_0_name);
                }
            } else {
                auto lt_0_name = tbl->get_use_name(nullptr, false, 0, 0);
                auto orig_unattached = memuse.at(lt_0_name).unattached_tables;
                auto unattached_name = orig_unattached.at(orig_at_use_name);
                atcam_alloc.unattached_tables.emplace(at_use_name, unattached_name);
            }
        } else {
            // Direct action table allocation
            BUG_CHECK(at->is<IR::MAU::ActionData>(), "Cannot have a direct attached table "
                      "currently that is not an Action Data Table");
            rv->memuse.emplace(at_use_name, memuse.at(orig_at_use_name));
        }
    }

    if (tbl->uses_gateway()) {
        auto gw_name = tbl->get_use_name(nullptr, true);
        if (logical_table == 0)
            rv->memuse.emplace(gw_name, memuse.at(gw_name));
    }
    return rv;
}
