#include "backends/tofino/mau/mau_spec.h"
#include "input_xbar.h"

IR::Node *FlatrockMauSpec::postTransformTables(IR::MAU::Table *tbl) const {
    if (tbl->layout.hash_action) {
        // flatrock hash_action needs to run everything from the table -- can't use a
        // run_table miss action to do anything.
        for (auto &gw : tbl->gateway_rows) {
            if (!gw.second) {
                BUG_CHECK(tbl->get_default_action(), "No default action in %s", tbl);
                gw.second = tbl->get_default_action()->name.name;
                BUG_CHECK(gw.second, "No default action name in %s", tbl); }
            if (tbl->actions.count(gw.second))
                tbl->gateway_payload[gw.second].first = gw.second;
            else
                tbl->gateway_payload[gw.second].first = cstring();
        }
    }
    return tbl;
}

int FlatrockIXBarSpec::getExactOrdBase(int group) const {
    return group * Flatrock::IXBar::EXACT_BYTES_PER_GROUP;
}

int FlatrockIXBarSpec::getTernaryOrdBase(int group) const {
    return Flatrock::IXBar::EXACT_GROUPS * Flatrock::IXBar::EXACT_BYTES_PER_GROUP +
           group * Flatrock::IXBar::TERNARY_BYTES_PER_GROUP;
}
