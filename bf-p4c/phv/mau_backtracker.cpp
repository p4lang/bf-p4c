#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "lib/log.h"

int MauBacktracker::numInvoked = 0;

bool MauBacktracker::backtrack(trigger &trig) {
    if (trig.is<PHVTrigger::failure>()) {
        tables.clear();
        auto t = dynamic_cast<PHVTrigger::failure *>(&trig);
        LOG1("Backtracking caught at MauBacktracker");
        for (auto entry : t->tableAlloc) {
            tables[entry.first] = entry.second;
            for (int st : entry.second)
                maxStage = (maxStage < st) ? st : maxStage; }
        LOG4("Inserted tables size: " << tables.size());
        // The OR operation ensures that live range analysis and metadata initialization, once
        // disabled, is not enabled for the rest of the compilation process.
        metaInitDisable |= t->metaInitDisable;
        return true;
    } else if (trig.is<BridgedPackingTrigger::failure>()) {
        auto t = dynamic_cast<BridgedPackingTrigger::failure *>(&trig);
        noPackFields.insert(t->bridgedFieldNames.begin(), t->bridgedFieldNames.end());
        return true;
    }
    return false;
}

Visitor::profile_t MauBacktracker::init_apply(const IR::Node* root) {
    LOG1("MauBacktracker called " << numInvoked << " time(s)");
    LOG1("  Is metadata initialization disabled? " << (metaInitDisable ? "YES" : "NO"));
    ++numInvoked;
    overlay.clear();
    profile_t rv = Inspector::init_apply(root);
    return rv;
}

void MauBacktracker::end_apply() {
    if (!LOGGING(4)) return;
    if (numInvoked == 1) return;
    printTableAlloc();
}

ordered_set<int>
MauBacktracker::inSameStage(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
    BUG_CHECK(t1, "Null table!");
    BUG_CHECK(t2, "Null table!");
    ordered_set<int> rs;
    if (tables.size() == 0) return rs;
    // Some tables in the list of tableActions maintained by PackConflicts may not have an
    // allocation (dead code eliminated away). The following if condition handles that case.
    if (!tables.count(TableSummary::getTableName(t1)) ||
            !tables.count(TableSummary::getTableName(t2)))
        return rs;
    const ordered_set<int>& t1Stages = tables.at(TableSummary::getTableName(t1));
    const ordered_set<int>& t2Stages = tables.at(TableSummary::getTableName(t2));
    BUG_CHECK(t1Stages.size() > 0, "No allocation for table %1%", t1->name);
    BUG_CHECK(t2Stages.size() > 0, "No allocation for table %2%", t2->name);
    for (int a : t1Stages) {
        for (int b : t2Stages) {
            if (a == b) rs.insert(a); } }
    return rs;
}

void MauBacktracker::printTableAlloc() const {
    if (!LOGGING(3)) return;
    LOG4("Printing Table Placement Before PHV Allocation Pass");
    LOG4("Stage | Table Name");
    for (auto tbl : tables)
        for (int st : tbl.second)
            LOG4(boost::format("%5d") % st << " | " << tbl.first);
}

bool MauBacktracker::hasTablePlacement() const {
    return (tables.size() > 0);
}

ordered_set<int> MauBacktracker::stage(const IR::MAU::Table* t) const {
    ordered_set<int> emptySet;
    if (tables.size() == 0) return emptySet;
    cstring tableName = TableSummary::getTableName(t);
    if (!tables.count(tableName))
        return emptySet;
    return tables.at(tableName);
}

int MauBacktracker::numStages() const {
    return maxStage;
}
