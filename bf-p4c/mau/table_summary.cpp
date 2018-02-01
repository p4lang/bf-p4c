#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/hex.h"
#include "lib/map.h"
#include "lib/safe_vector.h"

int TableSummary::numInvoked = 0;

Visitor::profile_t TableSummary::init_apply(const IR::Node *root) {
    auto rv = MauInspector::init_apply(root);
    order.clear();
    ixbar.clear();
    memory.clear();
    action_data_bus.clear();
    tableAlloc.clear();
    maxStage = 0;
    ingressDone = false;
    egressDone = false;
    ++numInvoked;
    LOG1("Table allocation done " << numInvoked << " time(s)");
    return rv;
}

void TableSummary::postorder(const IR::BFN::Pipe* pipe) {
    LOG7(pipe);
    throwBacktrackException();
}

void TableSummary::end_apply() {
    if (Log::verbose() || LOGGING(1))
        std::cout << *this;
}

bool TableSummary::preorder(const IR::MAU::Table *t) {
    BUG_CHECK(order.count(t->logical_id) == 0, "Encountering table multiple times in IR traversal");
    assert(order.count(t->logical_id) == 0);
    order[t->logical_id] = t;
    if (t->resources) {
        ixbar[t->stage()].update(t);
        memory[t->stage()].update(t->resources->memuse); }
    action_data_bus[t->stage()].update(t);
    return true;
}

void TableSummary::throwBacktrackException() {
    for (auto entry : order) {
        int stage = static_cast<int>(entry.first/NUM_LOGICAL_TABLES_PER_STAGE);
        maxStage = (maxStage < stage) ? stage : maxStage;
        tableAlloc[entry.second->name] = stage; }
    LOG4("Number of tables allocated: " << order.size());
    // maxStage is counted from 0 to n-1
    ++maxStage;
    LOG2("Number of stages in table allocation: " << maxStage);

    // First round
    // First round of table placement places tables in less than 12 stages, no backtracking invoked
    // If first round of table placement places tables in more than 12 stages, then a
    // NoContainerConflictTrigger() is thrown which redoes table placement, ignoring container
    // conflicts (second round of table placement)
    if (numInvoked == 1 && maxStage > NUM_STAGES) {
        LOG1("Invoking table placement without container conflicts");
        throw NoContainerConflictTrigger::failure(true); }

    // Right now we only do one backtracking round
    // If second round of table placement fits in less than 12 stages, then trigger a
    // PHVTrigger::failure to initiate a second round of PHV allocation with additional no pack
    // constraints between fields written in the same stage.
    if (numInvoked == 2 && maxStage <= NUM_STAGES) {
        LOG1("Invoking reallocation of PHVs");
        throw PHVTrigger::failure(tableAlloc); }
}

void TableSummary::printTablePlacement() {
    LOG3("Printing Table Placement");
    LOG3("Stage | Table Name");
    for (auto tbl : tableAlloc)
        LOG3(boost::format("%5d") % tbl.second << " | " << tbl.first);
}

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    out << " id G                     name       xb  hb g sr tc mr ab" << std::endl;
    for (auto *t : Values(ts.order)) {
        safe_vector<LayoutOption> lo;
        safe_vector<ActionFormat::Use> action_formats;
        ordered_set<const IR::MAU::AttachedMemory *> sa;
        LayoutChoices lc;
        if (t->layout.ternary || t->layout.no_match_data())
            lo.emplace_back(t->layout);
        else
            lo.emplace_back(t->layout, t->ways[0]);
        action_formats.push_back(t->resources->action_format);
        lc.total_layout_options[t->name] = lo;
        lc.total_action_formats[t->name] = action_formats;

        int entries = t->layout.entries;
        StageUseEstimate use(t, entries, &lc, sa, true);
        out << hex(t->logical_id, 3) << ' ' << (t->gress ? 'E' : 'I')
            << ' ' << std::setw(30) << t->name
            << ' ' << std::setw(2) << t->layout.ixbar_bytes
            << ' ' << std::setw(3) << t->layout.match_width_bits
            << ' ' << (t->uses_gateway() ? '1' : '0')
            << ' ' << std::setw(2) << use.srams
            << ' ' << std::setw(2) << use.tcams
            << ' ' << std::setw(2) << use.maprams
            << ' ' << std::setw(2) << t->layout.action_data_bytes
            << std::endl;
    }
    for (auto &i : ts.ixbar)
        out << "Stage " << i.first << std::endl << i.second << ts.memory.at(i.first);

    return out;
}
