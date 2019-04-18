#include "bf-p4c/mau/table_summary.h"
#include <numeric>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/hex.h"
#include "lib/map.h"
#include "lib/safe_vector.h"

int TableSummary::numInvoked[] = {0};
bool TableSummary::firstRoundFit = false;

Visitor::profile_t TableSummary::init_apply(const IR::Node *root) {
    if (BackendOptions().verbose > 0) {
        const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
        tsLog = new Logging::FileLog(pipe->id, "table_summary_pipe.log");
    }

    auto rv = MauInspector::init_apply(root);
    order.clear();
    ixbar.clear();
    memory.clear();
    action_data_bus.clear();
    imems.clear();
    tableAlloc.clear();
    tableNames.clear();
    mergedGateways.clear();
    maxStage = 0;
    ingressDone = false;
    egressDone = false;
    placementFailure = false;
    ++numInvoked[pipe_id];
    LOG1("Table allocation done " << numInvoked[pipe_id] << " time(s)");
    return rv;
}

void TableSummary::postorder(const IR::BFN::Pipe* pipe) {
    LOG7(pipe);
    throwBacktrackException();
}

void TableSummary::end_apply() {
    printTablePlacement();
    LOG2(*this);
    if (tsLog != nullptr) {
        delete tsLog;
        tsLog = nullptr;
    }
}

bool TableSummary::preorder(const IR::MAU::Table *t) {
    BUG_CHECK(order.count(t->logical_id) == 0, "Encountering table multiple times in IR traversal");
    assert(order.count(t->logical_id) == 0);
    order[t->logical_id] = t;
    LOG3("Table " << t->name);
    tableNames[t->name] = getTableName(t);
    if (t->gateway_name) {
        mergedGateways[t->name] = t->gateway_name;
        tableNames[t->gateway_name] = t->gateway_name; }
    if (t->resources) {
        ixbar[t->stage()].update(t);
        memory[t->stage()].update(t->resources->memuse);
        action_data_bus[t->stage()].update(t);
        imems[t->stage()].update(t); }
    if (t->match_table && t->get_provided_stage() >= 0 && t->stage() != t->get_provided_stage()) {
        placementFailure = true;
        // if this is pass 1 or pass 3, we will throw NoContainerConflictTrigger::failure to
        // redo table placement, so don't flag this as a hard error.  Otherwise report it.
        if (numInvoked[pipe_id] != 1 && numInvoked[pipe_id] != 3) {
            error("The stage specified for %s is %d, but we could not place it until stage %d",
                  t, t->get_provided_stage(), t->stage()); } }
    return true;
}

cstring TableSummary::getTableName(const IR::MAU::Table* tbl) {
    if (tbl->match_table) {
        BUG_CHECK(tbl->match_table->externalName(), "Table %1% does not have a P4 name", tbl->name);
        return tbl->match_table->externalName();
    } else {
        // For gateways, return the compiler generated name
        return tbl->name; }
}

void TableSummary::throwBacktrackException() {
    const int criticalPathLength = deps.critical_path_length();
    const int deviceStages = Device::numStages();
    for (auto entry : order) {
        int stage = static_cast<int>(entry.first/NUM_LOGICAL_TABLES_PER_STAGE);
        maxStage = (maxStage < stage) ? stage : maxStage;
        tableAlloc[tableNames[entry.second->name]].insert(stage); }
    // maxStage is counted from 0 to n-1
    ++maxStage;
    LOG1("Number of stages in table allocation: " << maxStage);
    LOG1("Critical path length through the table dependency graph: " << criticalPathLength);

    for (auto entry : mergedGateways) {
        ordered_set<int> tblStages = tableAlloc[tableNames[entry.first]];
        // Make sure that the table to which the gateway has been merged has been allocated to a
        // stage
        if (!tblStages.count(-1)) {
            ordered_set<int> stages = tableAlloc[tableNames[entry.first]];
            int const & (*min)(int const &, int const &) = std::min<int>;
            // If a gateway is merged with a P4 table split into multiple stages, then the placement
            // of the gateway is always in the earliest stage into which the P4 table has been split
            int minStage = std::accumulate(stages.begin(), stages.end(), maxStage + 1, min);
            tableAlloc[tableNames[entry.second]].insert(minStage);
        } else {
            ::warning("Source of merged gateway does not have stage allocated"); } }

    // Do not perform more than 5 rounds of table placement; this maximum would entail 3 rounds of
    // PHVs, 3 rounds of table placement with container conflicts, and 2 rounds of table placement
    // without container conflicts.
    if (numInvoked[pipe_id] >= 5) return;

    // First round.
    if (numInvoked[pipe_id] == 1) {
        // If there was a placement failure, then rerun table placements without container
        // conflicts.
        if (placementFailure) throw NoContainerConflictTrigger::failure(true);
        // If maxStage <= criticalPathLength + CRITICAL_PATH_THRESHOLD, then OK. No backtracking.
        if (maxStage <= deviceStages && maxStage <= criticalPathLength + CRITICAL_PATH_THRESHOLD)
            return;
        // If criticalPathLength + CRITICAL_PATH_THRESHOLD < maxStages <= deviceStages, note that
        // the first round of table placement fit.
        // For this case and for the case where maxStages > deviceStages, then rerun table placement
        // without container conflicts, and rerun PHV allocation based on the generated placement.
        // This will invoke a second round of PHV allocation, which will be more table placement
        // friendly because of the introduced pack conflicts.
        if (maxStage <= deviceStages) {
            LOG1("Invoking table placement without container conflicts to generate a more "
                 "compact placement.");
            firstRoundFit = true;
            throw NoContainerConflictTrigger::failure(true);
        }
        LOG1("Invoking table placement without container conflicts because first round of table "
             "placement required " << maxStage << " stages.");
        throw NoContainerConflictTrigger::failure(true);
    }

    // Even rounds of table placement, all without container conflicts.
    if (numInvoked[pipe_id] % 2 == 0) {
        // If there is no table placement failure, and if the number of stages are less than the
        // available physical stages, redo PHV allocation, while taking into account all the pack
        // conflicts produced by this table placement round, and also keeping metadata
        // initialization enabled.
        if (!placementFailure && maxStage <= deviceStages)
            throw PHVTrigger::failure(tableAlloc, firstRoundFit);

        // If there is not table placement failure and the number of stages without container
        // conflicts are greater than the available physical stages, redo PHV allocation, while
        // taking into account al the pack conflicts produced by this table placement round, and
        // also disabling metadata initialization. This is because metadata initialization has been
        // found to increase the dependency chain length occasionally.
        if (!placementFailure && maxStage > deviceStages) {
            LOG1("Invoking table placement without metadata initialization because container "
                 "conflict-free table placement required " << maxStage << " stages.");
            throw PHVTrigger::failure(tableAlloc, firstRoundFit, false /* ignorePackConflicts */,
                                      true /* metaInitDisable */);
        }
    }

    // Third round of table placement.
    if (numInvoked[pipe_id] == 3) {
        // If there is no placement failure and we fit within deviceStages, then table placement is
        // successful. No further backtracking required.
        if (!placementFailure && maxStage <= deviceStages) return;
        // If there is table placement failure or if this round of table placement requires more
        // than deviceStages, then redo table placement without container conflicts.
        LOG1("Invoking table placement without container conflicts because previous round of "
             "table placement took " << maxStage << " stages.");
        throw NoContainerConflictTrigger::failure(true);
    }
}

const ordered_set<int> TableSummary::stages(const IR::MAU::Table* tbl) const {
    ordered_set<int> rs;
    cstring tbl_name = getTableName(tbl);
    if (!tableAlloc.count(tbl_name)) return rs;
    return tableAlloc.at(tbl_name);
}

void TableSummary::printTablePlacement() {
    LOG1("Number of tables allocated: " << order.size());
    LOG1("Stage | Table Name");
    for (auto tbl : tableAlloc) {
        for (int st : tbl.second)
            LOG1(boost::format("%5d") % st << " | " << tbl.first);
    }
}

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    size_t maxname = 20;  // always use at least 20 columns
    for (auto *t : Values(ts.order))
        maxname = std::max(maxname, t->name.size());
    out << " id G " << std::setw(maxname) << "name     " << " xb  hb g sr tc mr ab" << std::endl;
    for (auto *t : Values(ts.order)) {
        safe_vector<LayoutOption> lo;
        safe_vector<ActionData::Format::Use> action_formats;
        StageUseEstimate::attached_entries_t attached_entries;
        LayoutChoices lc;
        if (t->layout.ternary || t->layout.no_match_rams())
            lo.emplace_back(t->layout, 0);
        else
            lo.emplace_back(t->layout, t->ways[0], 0);
        action_formats.push_back(t->resources->action_format);
        lc.total_layout_options[t->name] = lo;
        lc.total_action_formats[t->name] = action_formats;

        int entries = t->layout.entries;
        StageUseEstimate use(t, entries, attached_entries, &lc, false, true);
        out << hex(t->logical_id, 3) << ' ' << (t->gress ? 'E' : 'I')
            << ' ' << std::setw(maxname) << t->name
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
