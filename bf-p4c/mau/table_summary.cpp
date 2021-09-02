#include "bf-p4c/mau/table_summary.h"
#include <numeric>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/hex.h"
#include "lib/map.h"
#include "lib/safe_vector.h"

const char *state_name[] = { "INITIAL", "NOCC_TRY1", "REDO_PHV1", "NOCC_TRY2", "REDO_PHV2",
    "FINAL_PLACEMENT", "FAILURE", "SUCCESS" };

TableSummary::TableSummary(int pipe_id, const DependencyGraph& dg) : pipe_id(pipe_id), deps(dg) {
    static std::set<int>        ids_seen;

    BUG_CHECK(ids_seen.count(pipe_id) == 0, "Duplicate pipe id %d", pipe_id);
    ids_seen.insert(pipe_id);
}

Visitor::profile_t TableSummary::init_apply(const IR::Node *root) {
    if (BackendOptions().verbose > 0) {
        const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
        tsLog = new Logging::FileLog(pipe->id, "table_summary.log");
    }

    auto rv = MauInspector::init_apply(root);
    order.clear();
    ixbar.clear();
    memory.clear();
    action_data_bus.clear();
    imems.clear();
    tableAlloc.clear();
    internalTableAlloc.clear();
    tableNames.clear();
    mergedGateways.clear();
    maxStage = 0;
    ingressDone = false;
    egressDone = false;
    no_errors_before_summary = placementErrorCount() == 0;
    ++numInvoked;
    for (auto gress : { INGRESS, EGRESS }) max_stages[gress] = -1;
    LOG1("Table allocation done " << numInvoked << " time(s), state = " <<
         state_name[state]);
    return rv;
}

void TableSummary::end_apply() {
    printTablePlacement();
    LOG2(*this);
    Logging::FileLog::close(tsLog);
}

bool TableSummary::preorder(const IR::MAU::Table *t) {
    if (t->is_always_run_action()) {
        if (t->stage() == -1 && no_errors_before_summary)
            addPlacementError(t->toString() + " not placed");
        return true;
    } else if (!t->global_id()) {
        if (no_errors_before_summary)
            addPlacementError(t->toString() + " not placed");
        return true; }
    BUG_CHECK(order.count(*t->global_id()) == 0,
              "Encountering table multiple times in IR traversal");
    assert(order.count(*t->global_id()) == 0);
    order[*t->global_id()] = t;
    LOG3("Table " << t->name);
    tableNames[t->name] = getTableName(t);
    if (t->gateway_name) {
        mergedGateways[t->name] = t->gateway_name;
        tableNames[t->gateway_name] = t->gateway_name; }
    if (t->resources) {
        if (!ixbar[t->stage()]) ixbar[t->stage()].reset(IXBar::create());
        ixbar[t->stage()]->update(t);
        if (!memory[t->stage()]) memory[t->stage()].reset(Memories::create());
        memory[t->stage()]->update(t->resources->memuse);
        action_data_bus[t->stage()].update(t);
        imems[t->stage()].update(t); }
    auto stage_pragma = t->get_provided_stage();
    if (t->match_table && t->stage_split <= 0 && stage_pragma >= 0 && t->stage() != stage_pragma) {
        // FIXME -- move to TablePlacement
        addPlacementWarnError(BaseCompileContext::get().errorReporter().format_message(
                "The stage specified for %s is %d, but we could not place it until stage %d",
                t, t->get_provided_stage(), t->stage())); }
    return true;
}

cstring TableSummary::getTableName(const IR::MAU::Table* tbl) {
    if (tbl->match_table) {
        BUG_CHECK(tbl->match_table->externalName(), "Table %1% does not have a P4 name", tbl->name);
        return tbl->match_table->externalName();
    } else {
        // For split gateways, refer to the original name.
        if (tbl->name.endsWith("$split")) {
            cstring newName = tbl->name.before(tbl->name.find('$'));
            return newName;
        }
        // For gateways, return the compiler generated name
        return tbl->name; }
}

void TableSummary::postorder(const IR::BFN::Pipe* pipe) {
    LOG7(pipe);
    const int criticalPathLength = deps.critical_path_length();
    const int deviceStages = Device::numStages();
    bool placementFailure = (tablePlacementErrors.size() > 0);
    for (auto entry : order) {
        int stage = static_cast<int>(entry.first/NUM_LOGICAL_TABLES_PER_STAGE);
        maxStage = (maxStage < stage) ? stage : maxStage;
        if (max_stages[entry.second->gress] < stage)
            max_stages[entry.second->gress] = stage;
        tableAlloc[tableNames[entry.second->name]].insert(entry.first);
        internalTableAlloc[entry.second->name].insert(entry.first);
    }
    // maxStage is counted from 0 to n-1
    ++maxStage;
    for (auto gress : { INGRESS, EGRESS }) max_stages[gress] += 1;
    LOG1("Number of stages in table allocation: " << maxStage);
    for (auto gress : { INGRESS, EGRESS })
        LOG1("  Number of stages for " << gress << " table allocation: " << max_stages[gress]);
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
            int minStage = std::accumulate(stages.begin(), stages.end(),
                    (maxStage + 1) * NUM_LOGICAL_TABLES_PER_STAGE, min);
            tableAlloc[tableNames[entry.second]].insert(minStage);
            internalTableAlloc[entry.second].insert(minStage);
        } else {
            ::warning("Source of merged gateway does not have stage allocated"); } }

    if (BFNContext::get().options().alt_phv_alloc) {
        // with phv alloc after table placement, none of this backtracking is useful
        return; }

    switch (state) {
    case INITIAL:
        // If there was a placement failure, then rerun table placements without container
        // conflicts.
        if (placementFailure) {
            state = NOCC_TRY1;
            throw NoContainerConflictTrigger::failure(true); }
        // If maxStage <= criticalPathLength + CRITICAL_PATH_THRESHOLD, then OK. No backtracking.
        if (maxStage <= deviceStages && maxStage <= criticalPathLength + CRITICAL_PATH_THRESHOLD) {
            state = SUCCESS;
            return; }
        // If criticalPathLength + CRITICAL_PATH_THRESHOLD < maxStages <= deviceStages, note that
        // the first round of table placement fit.
        // For this case and for the case where maxStages > deviceStages, then rerun table placement
        // without container conflicts, and rerun PHV allocation based on the generated placement.
        // This will invoke a second round of PHV allocation, which will be more table placement
        // friendly because of the introduced pack conflicts.
        state = NOCC_TRY1;
        if (maxStage <= deviceStages) {
            LOG1("Invoking table placement without container conflicts to generate a more "
                 "compact placement.");
            firstRoundFit = true;
            throw NoContainerConflictTrigger::failure(true);
        }
        LOG1("Invoking table placement without container conflicts because first round of table "
             "placement required " << maxStage << " stages.");
        throw NoContainerConflictTrigger::failure(true);

    case NOCC_TRY1:
    case NOCC_TRY2:
        // If there is no table placement failure, and if the number of stages are less than the
        // available physical stages, redo PHV allocation, while taking into account all the pack
        // conflicts produced by this table placement round, and also keeping metadata
        // initialization enabled.
        if (maxStage <= deviceStages) {
            state = state == NOCC_TRY1 ? REDO_PHV1 : REDO_PHV2;
            throw PHVTrigger::failure(tableAlloc, internalTableAlloc, firstRoundFit);
        } else {
            // If there is not table placement failure and the number of stages without container
            // conflicts are greater than the available physical stages, redo PHV allocation, while
            // taking into account al the pack conflicts produced by this table placement round, and
            // also disabling metadata initialization. This is because metadata initialization has
            // been found to increase the dependency chain length occasionally.
            LOG1("Invoking table placement without metadata initialization because container "
                 "conflict-free table placement required " << maxStage << " stages.");
            state = state == NOCC_TRY1 ? REDO_PHV1 : REDO_PHV2;
            throw PHVTrigger::failure(tableAlloc, internalTableAlloc, firstRoundFit,
                    false /* ignorePackConflicts */, true /* metaInitDisable */);
        }

    case REDO_PHV1:
        // If there is no placement failure and we fit within deviceStages, then table placement is
        // successful. No further backtracking required.
        if (!placementFailure && maxStage <= deviceStages) {
            state = SUCCESS;
            return; }
        // If there is table placement failure or if this round of table placement requires more
        // than deviceStages, then redo table placement without container conflicts.
        LOG1("Invoking table placement without container conflicts because previous round of "
             "table placement took " << maxStage << " stages.");
        PhvInfo::darkSpillARA = false;
        state = NOCC_TRY2;
        throw NoContainerConflictTrigger::failure(true);

    case FINAL_PLACEMENT:
    case REDO_PHV2:
        if (!placementFailure && maxStage <= deviceStages)
            state = SUCCESS;
        else
            state = FAILURE;
        for (auto &msg : tablePlacementErrors)
            if (msg.second)
                error(msg.first);
            else
                warning(msg.first);
        return;

    default:
        BUG("TableSummary state %s (pass %d) not handled", state_name[state], numInvoked);
    }
}

const ordered_set<int> TableSummary::stages(const IR::MAU::Table* tbl, bool internal) const {
    ordered_set<int> rs;
    const ordered_map<cstring, ordered_set<int>> *tableAllocPtr;
    cstring tbl_name;

    if (internal) {
        tableAllocPtr = &internalTableAlloc;
        tbl_name = tbl->name;
    } else {
        tableAllocPtr = &tableAlloc;
        tbl_name = getTableName(tbl);
    }

    if (!tableAllocPtr->count(tbl_name)) return rs;
    for (auto logical_id : tableAllocPtr->at(tbl_name))
        rs.insert(logical_id / NUM_LOGICAL_TABLES_PER_STAGE);
    return rs;
}

void TableSummary::printTablePlacement() {
    LOG1("Number of tables allocated: " << order.size());

    std::stringstream ss;
    TablePrinter tp(ss, {"Stage", "Table Name"}, TablePrinter::Align::LEFT);

    for (auto tbl : tableAlloc) {
        for (int logical_id : tbl.second) {
            int stage = logical_id / NUM_LOGICAL_TABLES_PER_STAGE;
            tp.addRow({std::to_string(stage), std::string(tbl.first.c_str())});
        }
    }

    tp.print();
    LOG1(ss.str());
}

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    TablePrinter tp(out, {"Stage", "Logical ID", "Gress", "Name", "Ixbar Bytes", "Match Bits",
                          "Gateway", "Action Data Bytes"},
                    TablePrinter::Align::CENTER);

    int prev_stage = 0;
    for (auto *t : Values(ts.order)) {
        int curr_stage = t->stage();
        if (curr_stage != prev_stage)
            tp.addSep();

        tp.addRow({
            std::to_string(curr_stage),
            std::to_string(*t->global_id()),
            std::string(1, (t->gress ? 'E' : 'I')),
            std::string(t->externalName().c_str()),
            std::to_string(t->layout.ixbar_bytes),
            std::to_string(t->layout.match_width_bits),
            std::string(1, (t->uses_gateway() ? 'Y' : 'N')),
            std::to_string(t->layout.action_data_bytes),
          });

        prev_stage = curr_stage;
    }

    tp.print();

    if (LOGGING(3)) {
        for (auto &i : ts.ixbar)
            out << "Stage " << i.first << std::endl << *i.second << *ts.memory.at(i.first);
    }

    return out;
}
