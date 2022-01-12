/**
 * \defgroup backtracking_phv_allocation_and_table_placement \
 *   Backtracking in PHV allocation and table placement
 * \brief Description of %PHV allocation and table placement phases of compilation
 *
 * \dot
 * digraph phv_allocation_table_placement_backtracking {
 *   node [shape=box,style="rounded,filled",fontname="sans-serif,bold",
 *     margin="0.22,0.11",color=dodgerblue3,fillcolor=dodgerblue3,fontcolor=white]
 *   edge [fontname="sans-serif",color=gray40,fontcolor=gray40]
 *   INITIAL [shape=circle,label="",xlabel="INITIAL",color=dodgerblue4,
 *     fillcolor=dodgerblue4,fontcolor=dodgerblue4]
 *   SUCCESS [color=springgreen3,fillcolor=springgreen3]
 *   FAILURE [color=red,fillcolor=red]
 *   INITIAL -> NOCC_TRY1
 *     [label="placementFailure\nthrow NoContainerConflictTrigger::failure(true);"]
 *   INITIAL -> NOCC_TRY1
 *     [label="!placementFailure || (maxStage > deviceStages ||\nmaxStage > criticalPathLengt \
 * + CRITICAL_PATH_THRESHOLD)\nthrow NoContainerConflictTrigger::failure(true);"]
 *   INITIAL -> SUCCESS
 *     [label="maxStage <= deviceStages &&\nmaxStage <= \
 * criticalPathLength + CRITICAL_PATH_THRESHOLD"]
 *   NOCC_TRY1 -> REDO_PHV1
 *     [label="maxStage <= deviceStages\nthrow PHVTrigger::failure(tableAlloc, firstRoundFit);"]
 *   NOCC_TRY1 -> REDO_PHV1
 *     [label="maxStage > deviceStages\nthrow PHVTrigger::failure(tableAlloc, \
 * firstRoundFit,\nfalse / * ignorePackConflicts * /, true / * metaInitDisable * /);"]
 *   REDO_PHV1 -> SUCCESS
 *     [label="!placementFailure && maxStage <= deviceStages"]
 *   REDO_PHV1 -> NOCC_TRY2
 *     [label="placementFailure || \
 * maxStage > deviceStages\nthrow NoContainerConflictTrigger::failure(true);"]
 *   NOCC_TRY2 -> REDO_PHV2
 *     [label="maxStage <= deviceStages\nthrow PHVTrigger::failure(tableAlloc, firstRoundFit);"]
 *   NOCC_TRY2 -> REDO_PHV2
 *     [label="maxStage > deviceStages\nthrow PHVTrigger::failure(tableAlloc, firstRoundFit,\n\
 * false / * ignorePackConflicts * /, true / * metaInitDisable * /);"]
 *   REDO_PHV2 -> FAILURE [label="placementFailure || maxStage > deviceStages"]
 *   REDO_PHV2 -> SUCCESS [label="!placementFailure && maxStage <= deviceStages"]
 *   SUCCESS -> FINAL_PLACEMENT [label="throw TablePlacement::RedoTablePlacement()"]
 *   FINAL_PLACEMENT -> FAILURE [label="placementFailure || maxStage > deviceStages"]
 *   FINAL_PLACEMENT -> SUCCESS;
 * }
 * \enddot
 */

#include "bf-p4c/mau/table_summary.h"

#include <numeric>
#include <boost/optional/optional_io.hpp>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/ir/gress.h"

#include "lib/hex.h"
#include "lib/map.h"
#include "lib/safe_vector.h"

const char *state_name[] = { "INITIAL", "NOCC_TRY1", "REDO_PHV1", "NOCC_TRY2", "REDO_PHV2",
    "FINAL_PLACEMENT", "FAILURE", "SUCCESS", "ALT_INITIAL", "ALT_FINALIZE_TABLE" };

void TableSummary::FinalizePlacement() {
    state = BFNContext::get().options().alt_phv_alloc ? ALT_FINALIZE_TABLE : FINAL_PLACEMENT;
}

TableSummary::TableSummary(int pipe_id, const DependencyGraph& dg, const PhvInfo& phv)
    : pipe_id(pipe_id), deps(dg), phv(phv) {
    state = BFNContext::get().options().alt_phv_alloc ? ALT_INITIAL : INITIAL;
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
    tables.clear();
    tableAlloc.clear();
    internalTableAlloc.clear();
    tableNames.clear();
    tableINames.clear();
    mergedGateways.clear();
    ixbarBytes.clear();
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

void TableSummary::generateIxbarBytesInfo() {
    LOG3("Generating All Input XBar Usages - STATE : " << state_name[state]);
    for (auto &f : phv.get_all_fields()) {
        le_bitrange bits(0, f.second.size - 1);
        f.second.foreach_alloc(bits, [&](const PHV::AllocSlice& sl) {
            auto fptr = sl.field();
            auto fname = fptr->name;
            auto frange = sl.field_slice();
            auto fs = PHV::FieldSlice(fptr, frange);
            auto bytesOnIxbar = findBytesOnIxbar(fs);
            if (bytesOnIxbar.size() > 0) {
                for (auto i : bytesOnIxbar) {
                    auto stage = i.first;
                    auto ixByt = i.second;
                    ixbarBytes[fname][frange][stage] = ixByt;
                    LOG5("\tAdding entry : " << fname << "-> ("
                        << frange << ", (" << stage << ", " << ixByt << "))");
                }
            }
        });
    }
}

void TableSummary::end_apply() {
    // Generate Input XBar Bytes per Field Slice per stage
    generateIxbarBytesInfo();
    printAllIxbarUsages();
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
    int gid = *t->global_id();
#if HAVE_FLATROCK
    // FIXME -- on flatrock, ingress and egress have independent ids, so the gids are
    // not unique.  To work around this, we or egress ids with 0x10000 to make them distinct
    if (Device::currentDevice() == Device::FLATROCK && t->gress == EGRESS)
        gid |= 0x10000;
#endif
    BUG_CHECK(order.count(gid) == 0,
              "Encountering table multiple times in IR traversal");
    assert(order.count(gid) == 0);
    order[gid] = t;
    logical_ids[t->name] = *t->logical_id;
    LOG3("Table " << t->name << ", id: " << logical_ids[t->name]
            << ", global id : " << t->global_id() << " stage: " << t->stage());
    tableNames[t->name] = getTableName(t);
    tableINames[t->name] = getTableIName(t);
    if (t->gateway_name) {
        mergedGateways[t->name] = t->gateway_name;
        tableNames[t->gateway_name] = t->gateway_name;
        tableINames[t->gateway_name] = t->gateway_name;
    }
    if (t->resources) {
        if (!ixbar[t->stage()]) ixbar[t->stage()].reset(IXBar::create());
        ixbar[t->stage()]->update(t);
        if (!memory[t->stage()]) memory[t->stage()].reset(Memories::create());
        memory[t->stage()]->update(t->resources->memuse);
        if (!action_data_bus[t->stage()])
            action_data_bus[t->stage()].reset(ActionDataBus::create());
        action_data_bus[t->stage()]->update(t);
        imems[t->stage()].update(t);
        tables[t->stage()].insert(t); }
    auto stage_pragma = t->get_provided_stage();
    if (t->match_table && t->stage_split <= 0 && stage_pragma >= 0 && t->stage() != stage_pragma) {
        // FIXME -- move to TablePlacement
        addPlacementWarnError(BaseCompileContext::get().errorReporter().format_message(
                "The stage specified for %s is %d, but we could not place it until stage %d",
                t, t->get_provided_stage(), t->stage())); }
    return true;
}

cstring TableSummary::getTableIName(const IR::MAU::Table* tbl) {
    // For split gateways, refer to the original name.
    if (!tbl->match_table && tbl->name.endsWith("$split")) {
        cstring newName = tbl->name.before(tbl->name.find('$'));
        return newName;
    }
    return tbl->name;
}

cstring TableSummary::getTableName(const IR::MAU::Table* tbl) {
    if (tbl->match_table) {
        BUG_CHECK(tbl->match_table->externalName(), "Table %1% does not have a P4 name", tbl->name);
        return tbl->match_table->externalName();
    }
    // For split gateways, refer to the original name.
    if (tbl->name.endsWith("$split")) {
        cstring newName = tbl->name.before(tbl->name.find('$'));
        return newName;
    }
    // For gateways, return the compiler generated name
    return tbl->name;
}

void TableSummary::postorder(const IR::BFN::Pipe *pipe) {
    LOG7(pipe);
    const int criticalPathLength = deps.critical_path_length();
    const int deviceStages = Device::numStages();
    // TODO(yumin): this variable is misleading as warnings like `cannot satisfy stage pragma`
    // will be stored in tablePlacementErrors. Those warnings should not stop table placement
    // when it is the last round of table placement or maybe even for previous rounds.
    // To avoid fitting exercises on master, we continue to use this variable for normal
    // allocation process.
    const bool placementFailure = (tablePlacementErrors.size() > 0);
    const bool criticalPlacementFailure =
        std::any_of(tablePlacementErrors.begin(), tablePlacementErrors.end(),
                    [](const std::pair<cstring, bool> &kv) { return kv.second; });
    for (auto tbl : Values(order)) {
        // FIXME -- should just use tbl->stage() here?
        int stage = static_cast<int>(*tbl->global_id() / NUM_LOGICAL_TABLES_PER_STAGE);
        maxStage = (maxStage < stage) ? stage : maxStage;
        if (max_stages[tbl->gress] < stage)
            max_stages[tbl->gress] = stage;
        tableAlloc[tableNames[tbl->name]].insert(*tbl->global_id());
        internalTableAlloc[tableINames[tbl->name]].insert(*tbl->global_id());
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
            internalTableAlloc[tableINames[entry.second]].insert(minStage);
        } else {
            ::warning("Source of merged gateway does not have stage allocated"); } }

    const auto print_table_placement_errors = [&]() {
        for (auto &msg : tablePlacementErrors) {
            if (msg.second)
                ::error(msg.first);
            else
                ::warning(msg.first);
        }
    };

    if (BFNContext::get().options().alt_phv_alloc) {
        auto prev_state = state;
        switch (state) {
        case ALT_INITIAL: {
            // table placement succeeded, backtrack to run actual PHV allocation.
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                state = ALT_FINALIZE_TABLE;
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc, firstRoundFit);
            } else {
                // Trivial PHV alloc should yield the best possible table placement. No need to
                // retry if we're not fitting.
                state = FAILURE;
            }
            break;
        }
        case ALT_FINALIZE_TABLE: {
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                state = SUCCESS;
            } else {
                state = FAILURE;
            }
            break;
        }
        default:
            BUG("incorrect current state when alt_phv_alloc is enabled: %1%", state_name[state]);
        }
        if (state == FAILURE) {
            ::fatal_error(
                "table allocation (alt-phv-alloc enabled) failed to allocate tables "
                "within %1% stages. Allocation state: %2%, "
                "stage used: %3%, table placement warnings and errors seen: %4%",
                deviceStages, state_name[prev_state], maxStage, tablePlacementErrors.size());
            print_table_placement_errors();
        } else if (state == SUCCESS) {
            // only warnings will be printed.
            print_table_placement_errors();
        }
        return;
    }

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
            if (state == REDO_PHV2 && maxStage == deviceStages) {
                LOG1("Invoking table placement without metadata initialization because container "
                     "second conflict-free table placement required " << maxStage << " stages.");
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc, firstRoundFit,
                    false /* ignorePackConflicts */, true /* metaInitDisable */);
            } else {
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc, firstRoundFit);
            }
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
        print_table_placement_errors();
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

std::map<int, int> TableSummary::findBytesOnIxbar(const PHV::FieldSlice &slice) const {
    std::map<int, int> ixbarBytesPerStage;
    for (auto &tstage : tables) {
        auto tbl_stage = tstage.first;
        for (auto &tbl : tstage.second) {
            auto *tbl_res = tbl->resources;
            if (!tbl_res) continue;
            auto bytesOnIxbar = tbl_res->findBytesOnIxbar(slice);
            if (bytesOnIxbar > 0) {
                ixbarBytesPerStage[tbl_stage] = bytesOnIxbar;
                LOG5("In stage " << tbl_stage << " on table " << tbl->name
                    << " with Field Slice : " << slice
                    << ", IxbarBytes : " << bytesOnIxbar);
                break;
            }
        }
    }

    return ixbarBytesPerStage;
}

// Print all Input XBar usages on a per field per slice basis
// Usages are determined on each stage the field slice is valid
void TableSummary::printAllIxbarUsages(const PhvInfo *phv_i) const {
    if (!LOGGING(3)) return;
    LOG3("Printing All Input XBar Usages - STATE : " << state_name[state]);
    if (!phv_i) phv_i = &phv;
    std::stringstream ss;
    std::vector<std::string> header;
    header.push_back("FIELD NAME");
    header.push_back("SLICE");
    header.push_back("GRESS");
    // auto deviceStages = Device::numStages();
    auto deviceStages = maxStages() + 1;
    for (auto i = 0; i < deviceStages; i++)
        header.push_back(std::to_string(i));
    TablePrinter tp(ss, header, TablePrinter::Align::CENTER);
    for (auto &f : phv.get_all_fields()) {
        le_bitrange bits(0, f.second.size - 1);
        f.second.foreach_alloc(bits, [&](const PHV::AllocSlice& sl) {
            auto fl = sl.field();
            auto fn = fl->name;
            auto fr = sl.field_slice();
            auto fs = PHV::FieldSlice(fl, fr);
            // auto bytesOnIxbar = findBytesOnIxbar(fs);
            // auto bytesOnIxbar = ixbarBytes[sl.field()][sl.field_slice()];
            if (ixbarBytes.count(fn) == 0) return;
            auto fIxbarBytes = ixbarBytes.at(fn);
            if (fIxbarBytes.count(fr) == 0) return;
            auto bytesOnIxbar = fIxbarBytes.at(fr);
            if (bytesOnIxbar.size() > 0) {
                std::vector<std::string> row;
                row.push_back(std::string(stripThreadPrefix(f.first.c_str())));
                row.push_back(std::string("(" + std::to_string(fr.hi)
                                        + ":" + std::to_string(fr.lo) + ")"));
                row.push_back(std::string(toSymbol(f.second.gress).c_str()));
                for (auto i = 0; i < deviceStages; i++)
                    row.push_back("-");
                for (auto i : bytesOnIxbar) {
                    row[3 + i.first] = std::to_string(i.second);
                }
                tp.addRow(row);
            }
        });
    }
    tp.print();
    LOG3(ss.str());
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
