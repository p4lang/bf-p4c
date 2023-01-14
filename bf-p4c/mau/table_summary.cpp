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
 *     [label="placementFailure\nthrow RerunTablePlacementTrigger::failure(true);"]
 *   INITIAL -> NOCC_TRY1
 *     [label="!placementFailure || (maxStage > deviceStages ||\nmaxStage > criticalPathLengt \
 * + CRITICAL_PATH_THRESHOLD)\nthrow RerunTablePlacementTrigger::failure(true);"]
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
 * maxStage > deviceStages\nthrow RerunTablePlacementTrigger::failure(true);"]
 *   NOCC_TRY2 -> REDO_PHV2
 *     [label="maxStage <= deviceStages\nthrow PHVTrigger::failure(tableAlloc, firstRoundFit);"]
 *   NOCC_TRY2 -> REDO_PHV2
 *     [label="maxStage > deviceStages\nthrow PHVTrigger::failure(tableAlloc, firstRoundFit,\n\
 * false / * ignorePackConflicts * /, true / * metaInitDisable * /);"]
 *   REDO_PHV2 -> FAILURE [label="placementFailure || maxStage > deviceStages"]
 *   REDO_PHV2 -> SUCCESS [label="!placementFailure && maxStage <= deviceStages"]
 *   SUCCESS -> FINAL_PLACEMENT [label="throw TablePlacement::FinalRerunTablePlacementTrigger()"]
 *   FINAL_PLACEMENT -> FAILURE [label="placementFailure || maxStage > deviceStages"]
 *   FINAL_PLACEMENT -> SUCCESS;
 * }
 * \enddot
 */

#include "bf-p4c/mau/table_summary.h"

#include <numeric>
#include <sstream>

#include <boost/optional/optional_io.hpp>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/ir/gress.h"

#include "lib/hex.h"
#include "lib/map.h"

static std::vector<cstring> state_name = {
    "INITIAL",
    "NOCC_TRY1",
    "REDO_PHV1",
    "NOCC_TRY2",
    "REDO_PHV2",
    "FINAL_PLACEMENT",
    "FAILURE",
    "SUCCESS",
    "ALT_INITIAL",
    "ALT_RETRY_ENHANCED_TP",
    "ALT_FINALIZE_TABLE_SAME_ORDER",
    "ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED",
    "ALT_FINALIZE_TABLE",
    "FINAL"  // Should never reach this state
};

void TableSummary::FinalizePlacement() {
    state = BFNContext::get().options().alt_phv_alloc ? ALT_FINALIZE_TABLE : FINAL_PLACEMENT;
}

void TableSummary::resetPlacement() {
    state = BFNContext::get().options().alt_phv_alloc ? ALT_INITIAL : INITIAL;
}

TableSummary::TableSummary(int pipe_id, const DependencyGraph& dg, const PhvInfo& phv)
    : pipe_id(pipe_id), deps(dg), phv(phv) {
    state = BFNContext::get().options().alt_phv_alloc ? ALT_INITIAL : INITIAL;
    static std::set<int>        ids_seen;
    BUG_CHECK(ids_seen.count(pipe_id) == 0, "Duplicate pipe id %d", pipe_id);
    ids_seen.insert(pipe_id);
}

ordered_map<cstring, std::set<const IR::MAU::Table*>> TableSummary::tblName2IRptr;

Visitor::profile_t TableSummary::init_apply(const IR::Node *root) {
    if (BackendOptions().verbose > 0) {
        const IR::BFN::Pipe *pipe = root->to<IR::BFN::Pipe>();
        tsLog = new Logging::FileLog(pipe->canon_id(), "table_summary.log");
    }

    auto rv = MauInspector::init_apply(root);
    order.clear();
    for (auto gress : { INGRESS, EGRESS }) {
        ixbar[gress].clear();
        memory[gress].clear();
        action_data_bus[gress].clear();
        imems[gress].clear(); }
    tables.clear();
    tableAlloc.clear();
    internalTableAlloc.clear();
    tableNames.clear();
    tableINames.clear();
    TableSummary::clearTblName2IRptr();
    mergedGateways.clear();
    ixbarBytes.clear();
    maxStage = 0;
    ingressDone = false;
    egressDone = false;
    no_errors_before_summary = placementErrorCount() == 0;
    ++numInvoked;
    for (auto gress : { INGRESS, EGRESS }) max_stages[gress] = -1;
    placedTables.clear();
    table_replay_failed_table = boost::none;
    LOG1("Table allocation done " << numInvoked << " time(s), state = " <<
         getActualStateStr());
    return rv;
}

void TableSummary::generateIxbarBytesInfo() {
    LOG3("Generating All Input XBar Usages - STATE : " << getActualStateStr());
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

void TableSummary::printPlacedTables() const {
    for (auto &pt : placedTables)
        LOG5(*pt.second);
}

void TableSummary::end_apply() {
    // Generate Input XBar Bytes per Field Slice per stage
    generateIxbarBytesInfo();
    LOG3(ixbarUsagesStr());
    printTablePlacement();
    LOG2(*this);
    printPlacedTables();
    Logging::FileLog::close(tsLog);
}

bool TableSummary::preorder(const IR::MAU::Table *t) {
    LOG5("TableSummary preorder on table : " << t->name << " with gw : " << t->gateway_name);
    TableSummary::addTablePtr(t);
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
        mergedGateways[t->name] = std::make_pair(t->gateway_name, t->gateway_result_tag);
        tableNames[t->gateway_name] = t->gateway_name;
        tableINames[t->gateway_name] = t->gateway_name;
    }
    if (t->resources) {
        int gress = INGRESS;
#if HAVE_FLATROCK
        if (!Device::threadsSharePipe(INGRESS, EGRESS))
            gress = t->thread();
#endif
        if (!ixbar[gress][t->stage()])
            ixbar[gress][t->stage()].reset(IXBar::create());
        ixbar[gress][t->stage()]->update(t);
        if (!memory[gress][t->stage()]) memory[gress][t->stage()].reset(Memories::create());
        memory[gress][t->stage()]->update(t->resources->memuse);
        if (!action_data_bus[gress][t->stage()])
            action_data_bus[gress][t->stage()].reset(ActionDataBus::create());
        action_data_bus[gress][t->stage()]->update(t);
        if (!imems[gress][t->stage()])
            imems[gress][t->stage()].reset(InstructionMemory::create());
        imems[gress][t->stage()]->update(t);
        tables[t->stage()].insert(t); }
    auto stage_pragma = t->get_provided_stage();
    if (t->match_table && t->stage_split <= 0 && stage_pragma >= 0 && t->stage() != stage_pragma) {
        // FIXME -- move to TablePlacement
        addPlacementWarnError(BaseCompileContext::get().errorReporter().format_message(
                "The stage specified for %s is %d, but we could not place it until stage %d",
                t, t->get_provided_stage(), t->stage())); }

    // Create / Update a PlacedTable Object
    bool pTMerge = false;
    for (auto &pt : Values(placedTables)) {
        // For ALPM's / DLEFT tables which can be split within the same stage
        // consolidate the entries into a single placed table object TP in the
        // next round will do the split during TransformTables (break_up_atcam /
        // dleft)
        // However split gateway tables should not be merged as these are split
        // through SplitComplexGateways earlier during Table Alloc, hence TP
        // should see the split gateways as is
        if ((pt->internalTableName == getTableIName(t))
            && (pt->stage == t->stage())
            && (!t->is_a_gateway_table_only())) {
            pt->add(t);
            pTMerge = true;
            LOG5("\tMerging with PlacedTable : " << pt->internalTableName);
            break;
        }
    }
    if (!pTMerge)
        placedTables[*t->global_id()] = new PlacedTable(t);

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

void TableSummary::addTablePtr(const IR::MAU::Table* tbl) {
    cstring ref_name = tbl->name;
    if (ref_name.endsWith("$split"))
        ref_name = tbl->name.before(tbl->name.find('$'));
    tblName2IRptr[ref_name].insert(tbl);
    LOG6("   Adding table " << tbl->name << " as " << ref_name <<" to pointer " << tbl);
    if (tbl->gateway_name.size() && (tbl->gateway_name != ref_name.c_str())) {
        tblName2IRptr[tbl->gateway_name].insert(tbl);
        LOG6("   Adding gw table " << tbl->gateway_name <<" to pointer " << tbl);
    }
}

std::set<const IR::MAU::Table*> TableSummary::getTablePtr(const cstring t_name){
    std::set<const IR::MAU::Table*> empty;
    if (tblName2IRptr.count(t_name))
        return tblName2IRptr.at(t_name);
    return empty;
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
            tableAlloc[tableNames[entry.second.first]].insert(minStage);
            internalTableAlloc[tableINames[entry.second.first]].insert(minStage);
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

    prev_state = state;
    if (BFNContext::get().options().alt_phv_alloc) {
        switch (state) {
        case ALT_INITIAL: {
            // table placement succeeded, backtrack to run actual PHV allocation.
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                LOG1("Alt phv alloc: Success after ALT_INITIAL");
                generateIxbarBytesInfo();
                LOG1(ixbarUsagesStr());
                state = ALT_FINALIZE_TABLE_SAME_ORDER;
                // collect table placement result after trivial phv allocation.
                trivial_tableAlloc.clear();
                trivial_tableAlloc.insert(tableAlloc.begin(), tableAlloc.end());
                trivial_internalTableAlloc.clear();
                trivial_internalTableAlloc.insert(
                    internalTableAlloc.begin(), internalTableAlloc.end());
                trivial_mergedGateways.clear();
                trivial_mergedGateways.insert(mergedGateways.begin(), mergedGateways.end());
                trivial_placedTables.clear();
                trivial_placedTables.insert(placedTables.begin(), placedTables.end());
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc,
                                          mergedGateways, firstRoundFit);
            } else {
                if (maxStage > deviceStages) {
                    // retry with table backtrack and resource-based allocation enabled.
                    // DO NOT ignore container conflict conflict.
                    state = ALT_RETRY_ENHANCED_TP;
                    LOG1("Alt phv alloc: Invoking ALT_RETRY_ENHANCED_TP after ALT_INITIAL");
                    throw RerunTablePlacementTrigger::failure(false);
                } else {
                    // critical failures, do not retry.
                    state = FAILURE;
                    LOG1("Alt phv alloc: Failure after ALT_INITIAL");
                }
            }
            break;
        }
        case ALT_RETRY_ENHANCED_TP: {
            // table placement succeeded, backtrack to run actual PHV allocation.
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                LOG1("Alt phv alloc: Success after ALT_RETRY_ENHANCED_TP");
                generateIxbarBytesInfo();
                LOG1(ixbarUsagesStr());
                state = ALT_FINALIZE_TABLE_SAME_ORDER;
                // collect table placement result after trivial phv allocation.
                trivial_tableAlloc.clear();
                trivial_tableAlloc.insert(tableAlloc.begin(), tableAlloc.end());
                trivial_internalTableAlloc.clear();
                trivial_internalTableAlloc.insert(
                    internalTableAlloc.begin(), internalTableAlloc.end());
                trivial_mergedGateways.clear();
                trivial_mergedGateways.insert(mergedGateways.begin(), mergedGateways.end());
                trivial_placedTables.clear();
                trivial_placedTables.insert(placedTables.begin(), placedTables.end());
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc,
                                              mergedGateways, firstRoundFit);
            } else {
                // Use real physical stage for smart packer instead of minstage. This should get
                // better packing result that can ultimately make it fit. Only going back to the
                // initial stage once. The resource based allocation physical placement will be
                // the one used to decide if two fields can be pack on the same container or not.
                if (numInvoked == FIRST_ALT_RETRY_ENHANCED_TP_INVOCATION) {
                    state = ALT_INITIAL;
                    throw PHVTrigger::failure(tableAlloc, internalTableAlloc,
                                              mergedGateways, firstRoundFit);
                } else {
                    LOG1("Alt phv alloc: Failure after ALT_RETRY_ENHANCED_TP");
                    state = FAILURE;
                }
            }
            break;
        }
        case ALT_FINALIZE_TABLE_SAME_ORDER: {
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                LOG1("Alt phv alloc: Success post ALT_FINALIZE_TABLE_SAME_ORDER");
                state = SUCCESS;
            } else {
                LOG1("Alt phv alloc: Failure post ALT_FINALIZE_TABLE_SAME_ORDER");
                // if table replay failed when placing the first table, select the first table to
                // fix.
                // TODO(Changhao): this is a very naive selection method. Eventually, we should
                // select tables that, due to difference between trivial allocation and real phv
                // allocation, do not fit in ixbar, do not fit on the same stage, or cause other
                // tables not fit on the same stage. This requires we check the table layout and
                // ixbar usage information. We need to check more profiles that fail during table
                // replay stage to find out what is the best heuristic to select these problematic
                // tables.
                if (placedTables.size() == 0) {
                    table_replay_failed_table =
                        trivial_placedTables.begin()->second->internalTableName;
                }
                // if ALT_FINALIZE_TABLE_SAME_ORDER failed, jump to
                // ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED and also restore the table placement
                // result after trivial phv allocation.
                if (table_replay_failed_table != boost::none &&
                    alt_phv_alloc_table_fixed < ALT_PHV_ALLOC_TABLE_FIX_THRESHOLD){
                    alt_phv_alloc_table_fixed++;
                    state = ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED;
                    placedTables.clear();
                    placedTables.insert(trivial_placedTables.begin(), trivial_placedTables.end());
                    // rerun real phv allocation, since some pa_container_size constraints have been
                    // added.
                    throw PHVTrigger::failure(trivial_tableAlloc, trivial_internalTableAlloc,
                                                trivial_mergedGateways, firstRoundFit);
                } else {
                    tableAlloc.clear();
                    internalTableAlloc.clear();
                    placedTables.clear();
                    state = ALT_FINALIZE_TABLE;
                    throw RerunTablePlacementTrigger::failure(false);
                }
            }
            break;
        }
        case ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED: {
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                state = SUCCESS;
            } else {
                if (table_replay_failed_table != boost::none &&
                    alt_phv_alloc_table_fixed < ALT_PHV_ALLOC_TABLE_FIX_THRESHOLD) {
                    alt_phv_alloc_table_fixed++;
                    state = ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED;
                } else {
                    // if failed, jump to ALT_FINALIZE_TABLE, and restore the table placement result
                    // after trivial phv allocation.
                    state = ALT_FINALIZE_TABLE;
                }

                placedTables.clear();
                placedTables.insert(trivial_placedTables.begin(), trivial_placedTables.end());
                // rerun real phv allocation, since some pa_container_size constraints have been
                // removed.
                throw PHVTrigger::failure(trivial_tableAlloc, trivial_internalTableAlloc,
                                            trivial_mergedGateways, firstRoundFit);
            }
            break;
        }
        case ALT_FINALIZE_TABLE: {
            if (!criticalPlacementFailure && maxStage <= deviceStages) {
                LOG1("Alt phv alloc: Success post ALT_FINALIZE_TABLE");
                state = SUCCESS;
            } else {
                LOG1("Alt phv alloc: Failure post ALT_FINALIZE_TABLE");
                state = FAILURE;
            }
            break;
        }
        default:
            BUG("incorrect current state when alt_phv_alloc is enabled: %1%", getActualStateStr());
        }
        if (state == FAILURE) {
            print_table_placement_errors();
            if (maxStage > deviceStages || criticalPlacementFailure) {
                ::fatal_error(
                    "table allocation (alt-phv-alloc enabled) failed to allocate tables "
                    "within %1% stages. Allocation state: %2%, "
                    "stage used: %3%, table placement warnings and errors seen: %4%",
                    deviceStages, state_name[prev_state], maxStage, tablePlacementErrors.size());
            }
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
            throw RerunTablePlacementTrigger::failure(true); }
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
            throw RerunTablePlacementTrigger::failure(true);
        }
        LOG1("Invoking table placement without container conflicts because first round of table "
             "placement required " << maxStage << " stages.");
        throw RerunTablePlacementTrigger::failure(true);

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
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc,
                                            mergedGateways, firstRoundFit,
                    false /* ignorePackConflicts */, true /* metaInitDisable */);
            } else {
                throw PHVTrigger::failure(tableAlloc, internalTableAlloc,
                                            mergedGateways, firstRoundFit);
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
            throw PHVTrigger::failure(tableAlloc, internalTableAlloc, mergedGateways, firstRoundFit,
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
        throw RerunTablePlacementTrigger::failure(true);

    case FINAL_PLACEMENT:
    case REDO_PHV2:
        if (!placementFailure && maxStage <= deviceStages)
            state = SUCCESS;
        else
            state = FAILURE;
        print_table_placement_errors();
        return;

    default:
        BUG("TableSummary state %s (pass %d) not handled", getActualStateStr(), numInvoked);
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
cstring TableSummary::ixbarUsagesStr(const PhvInfo *phv_i) const {
    std::stringstream ss;
    ss << "All Input XBar Usages - STATE : " << getActualStateStr() << "\n";
    if (!phv_i) phv_i = &phv;
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
        auto fn = f.second.name;
        if (ixbarBytes.count(fn) == 0) continue;
        for (const auto& ixbar_alloc : ixbarBytes.at(fn)) {
            const auto& fr = ixbar_alloc.first;
            const auto& bytesOnIxbar = ixbar_alloc.second;
            if (bytesOnIxbar.size() > 0) {
                std::vector<std::string> row;
                row.push_back(std::string(stripThreadPrefix(f.first.c_str())));
                row.push_back(
                    std::string("(" + std::to_string(fr.hi) + ":" + std::to_string(fr.lo) + ")"));
                row.push_back(std::string(toSymbol(f.second.gress).c_str()));
                for (auto i = 0; i < deviceStages; i++) row.push_back("-");
                for (auto i : bytesOnIxbar) {
                    row[3 + i.first] = std::to_string(i.second);
                }
                tp.addRow(row);
            }
        }
    }
    tp.print();
    return ss.str();
}

cstring TableSummary::getActualStateStr() const {
    BUG_CHECK((state >= INITIAL && state < FINAL),
            "Placement in an invalid state");
    return state_name.at(state);
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
        for (auto gress : { INGRESS, EGRESS }) {
            for (auto &i : ts.ixbar[gress]) {
                if (!Device::threadsSharePipe(INGRESS, EGRESS)) out << gress << " ";
                out << "Stage " << i.first << std::endl << *i.second
                    << *ts.memory[gress].at(i.first); }
            if (Device::threadsSharePipe(INGRESS, EGRESS)) break;
        }
    }

    return out;
}

void TableSummary::PlacedTable::add(const IR::MAU::Table *t) {
    if (!t) return;
    if (!t->resources) return;
    if (t->resources->memuse.count(t->unique_id()) == 0) return;  // BUG_CHECK?
    auto mem = t->resources->memuse.at(t->unique_id());
    if (t->ways.size() > 0) {
        auto match_groups = t->ways[0].match_groups;
        for (auto mem_way : mem.ways) {
            entries += match_groups * mem_way.size * Memories::SRAM_DEPTH;
            LOG3("Adding entries to table : " << t->name << ", match_groups: " << match_groups
                    << ", mem.ways: " << mem.ways);
        }
    }
    for (auto &ba : t->attached) {
        auto att = ba->attached;
        auto memName = att->name;
        auto attEntries = att->size;
        // If table is direct same entries as match table
        attached_entries[memName] += attEntries;
    }
}

TableSummary::PlacedTable::PlacedTable(const IR::MAU::Table *t) {
    BUG_CHECK(t, "PlacedTable called with no valid table");
    LOG5("Populating PlacedTable for Table : " << t->name);

    tableName = getTableName(t);
    internalTableName = t->is_a_gateway_table_only() ? t->name : getTableIName(t);

    if (t->gateway_name) {
        gatewayName = t->gateway_name;
        gatewayMergeCond = t->gateway_result_tag;
    }

    stage = t->stage();
    logicalId = *t->logical_id;
    entries = t->layout.entries;
    // TBD: Fix layout to have the correct entries and ways for all table types
    // This should ideally happen in TP possibly during TransformTables pass
    // Do we need to do anything different for DLEFT for entries calculation
    // here?
    if (t->layout.atcam) {
        entries = 0;
        auto mem = t->resources->memuse.at(t->unique_id());
        auto match_groups = t->ways[0].match_groups;
        for (auto mem_way : mem.ways) {
            entries += match_groups * mem_way.size * Memories::SRAM_DEPTH;
            LOG3("Adding entries to table : " << t->name << ", match_groups: " << match_groups
                    << ", mem.ways: " << mem.ways);
        }
    }

    for (auto &ba : t->attached) {
        auto att = ba->attached;
        auto memName = att->name;
        auto attEntries = att->size;
        // If table is direct same entries as match table
        attached_entries[memName] = attEntries;
    }

    layout = t->resources->layout_option;
}

std::ostream &operator<<(std::ostream &out, const TableSummary::PlacedTable &pl) {
    Log::TempIndent indent;
    out << "Placed Table : " << pl.tableName << "(" << pl.internalTableName << ")";
    out << indent << Log::endl;
    out << "stage: " << pl.stage << ", logicalId: " << pl.logicalId;
    out << ", entries: " << pl.entries << Log::endl;
    if (pl.gatewayName)
        out << "gateway: " << pl.gatewayName << "(" << pl.gatewayMergeCond << ")";
    for (auto att : pl.attached_entries)
        out << "Attached Table : " << att.first << ", entries : " << att.second << Log::endl;
    out << pl.layout << Log::endl;
    return out;
}
