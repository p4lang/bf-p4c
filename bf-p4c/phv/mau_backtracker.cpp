#include "bf-p4c/phv/mau_backtracker.h"
#include "lib/log.h"

int MauBacktracker::numInvoked = 0;

bool MauBacktracker::backtrack(trigger &trig) {
    if (trig.is<PHVTrigger::failure>()) {
        tables.clear();
        auto t = dynamic_cast<PHVTrigger::failure *>(&trig);
        LOG1("Backtracking caught at MauBacktracker");
        for (auto entry : t->tableAlloc)
            tables[entry.first] = entry.second;
        LOG4("Inserted tables size: " << tables.size());
        return true; }
    return false;
}

Visitor::profile_t MauBacktracker::init_apply(const IR::Node* root) {
    LOG1("MauBacktracker called " << numInvoked << " time(s)");
    ++numInvoked;
    profile_t rv = Inspector::init_apply(root);
    return rv;
}

void MauBacktracker::end_apply() {
    if (!LOGGING(4)) return;
    if (numInvoked == 1) return;
    printTableAlloc();
}

int MauBacktracker::inSameStage(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
    if (tables.size() == 0) return -1;
    if (tables.at(t1->name) == tables.at(t2->name))
        return tables.at(t1->name);
    return -1;
}

void MauBacktracker::printTableAlloc() {
    if (!LOGGING(3)) return;
    LOG4("Printing Table Placement Before PHV Allocation Pass");
    LOG4("Stage | Table Name");
    for (auto tbl : tables)
        LOG4(boost::format("%5d") % tbl.second << " | " << tbl.first);
}
