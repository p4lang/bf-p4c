#include "bf-p4c/mau/mau_spec.h"

IR::Node *FlatrockMauSpec::postTransformTables(IR::MAU::Table *tbl) const {
    if (tbl->layout.hash_action) {
        // flatrock hash_action needs to run everything from the table -- can't use a
        // run_table miss action to do anything.
        for (auto &gw : tbl->gateway_rows) {
            if (!gw.second) {
                gw.second = tbl->get_default_action()->name;
                BUG_CHECK(gw.second, "No default action in %s", tbl); }
            if (tbl->actions.count(gw.second))
                tbl->gateway_payload[gw.second].first = gw.second;
            else
                tbl->gateway_payload[gw.second].first = cstring();
        }
    }
    return tbl;
}
