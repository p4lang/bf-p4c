#include "table_injected_deps.h"
#include <sstream>
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/ltbitmatrix.h"

bool InjectControlDependencies::preorder(const IR::MAU::TableSeq *seq) {
    const Context *ctxt = getContext();
    if (ctxt && dynamic_cast<const IR::MAU::Table *>(ctxt->node)) {
        const IR::MAU::Table* parent;
        parent = dynamic_cast<const IR::MAU::Table *>(ctxt->node);


        for (auto child : seq->tables) {
             auto edge_label = DependencyGraph::NONE;
            auto ctrl_annot = "";
            // Find control type relationship between parent & child
            for (auto options : parent->next) {
                for (auto dst : options.second->tables) {
                    if (dst == child) {
                        ctrl_annot = options.first;
                        edge_label = DependencyGraph::get_control_edge_type(ctrl_annot);
                        break;
                    }
                }
            }
            BUG_CHECK(edge_label != DependencyGraph::NONE,
                    "Cannot resolve Injected Control Edge Type");

            auto edge_pair = dg.add_edge(parent, child, edge_label);
            LOG3("Injecting CONTROL edge between " << parent->name << " --> " << child->name);

            dg.ctrl_annotations[edge_pair.first] = ctrl_annot;  // Save annotation
        }
    }

    return true;
}

//     apply {
//         switch (t1.apply().action_run) {
//             default : {
//                 if (hdr.data.f2 == hdr.data.f1) {
//                     t2.apply();
//                     switch (t3.apply().action_run) {
//                         noop : {
//                             t4.apply();
//                         }
//                     }
//                 }
//             }
//             a1 : {
//                 t4.apply();
//             }
//         }
//     }

// In this example, InjectControlDependencies walks up the IR starting at t4
// and inserts a control dependence within t4's parent table sequence [t2, t3]
// between t2 and t4's parent, t3. The walk up the IR stop's at t1, t4's dominator.


/**
 * In Tofino, extra ordering is occasionally required due to the requirements of each table
 * having a single next table.  Examine the following program:
 * 
 *     apply {
 *         switch (t1.apply().action_run) {
 *             a1 : {
 *                 t2.apply();
 *                 switch (t3.apply().action_run) {
 *                     noop : { t4.apply(); }
 *                 }
 *             }
 *             default : { t4.apply(); }
 *         }
 *     }
 *     t5.apply();
 *
 * In this example, for Tofino only, the table t4 must have the same default next table out of
 * every single execution.  This means on all branches under t1, t4 must be the last table that is
 * applied.  Now examine the sequence under branch a1, where both t2 and t3 can be applied.
 * If t2 and t3 have no dependencies, (and their children have no dependencies), they can be
 * reordered.  However, next table dictates that when a table is placed, all of it's control
 * dependent tables must be placed as well.  Means that if t3 is to be placed before t2, t4 would
 * also be placed.  This, however, would break the constraint that t4 has a single next table.
 *
 * Thus, in order to map this constraint to table placement, an ordering dependency is placed
 * between t2 and t3 to correctly propagate next table data.
 *
 * This pass now works on the new IR rules for Tables and TableSeqs.  Tests verifying this pass
 * are contained in the table_dependency gtest under PredicationEdges Tests
 */
void PredicationBasedControlEdges::postorder(const IR::MAU::Table *tbl) {
    name_to_table[tbl->externalName()] = tbl;
    auto dom = ctrl_paths.find_dominator(tbl);
    if (dom == tbl)
        return;
    auto paths = ctrl_paths.table_pathways.at(tbl);

    std::set<const IR::MAU::Table *> ignore_tables;
    bool first_seq = true;
    /**
     * In the previous example, the table t4, due to next table propagation, required table
     * t2 and t3 to have an order.  But some examples don't require an order.  Examine the
     * following example:
     *
     *     switch (t1.apply().action_run) {
     *         a1 : { t2.apply(); t3.apply(); t4.apply(); }
     *         a2 : { t3.apply(); t4.apply(); }
     *     }
     *     t5.apply();
     *
     * Now if there were no dependencies between these tables, it would seem that table t4
     * would have to appear last for next table propagation to table t5.  However, t3 always
     * precedes t4 in every single application, and thus could in theory be reordered.
     *
     * Thus in the analysis for t4, the ignore tables will determine that t3 always precedes it
     * in all applications, and thus is safe not to add a dependency.
     */
    for (auto path : paths) {
        auto seq = path[1]->to<IR::MAU::TableSeq>();
        std::set<const IR::MAU::Table *> local_set;
        for (auto seq_table : seq->tables) {
            if (seq_table == tbl) break;
            local_set.insert(seq_table);
        }
        if (first_seq) {
            ignore_tables.insert(local_set.begin(), local_set.end());
            first_seq = false;
        } else {
            std::set<const IR::MAU::Table *> intersection;
            std::set_intersection(ignore_tables.begin(), ignore_tables.end(),
                                  local_set.begin(), local_set.end(),
                                  std::inserter(intersection, intersection.begin()));
            ignore_tables = intersection;
        }
    }

    // Walk up the table pathways for any table that precedes this table, and add a dependency
    // between these tables and the current table, as long as its not in the ignore_tables set
    for (auto path : paths) {
        auto it = path.begin();
        const IR::MAU::Table *local_check = (*it)->to<IR::MAU::Table>();
        BUG_CHECK(local_check == tbl, "Table Pathways not correct");
        while (true) {
            it++;
            auto higher_seq = (*it)->to<IR::MAU::TableSeq>();
            BUG_CHECK(it != path.end() && higher_seq != nullptr, "Table Pathways not correct");
            for (auto seq_table : higher_seq->tables) {
                if (local_check == seq_table) break;
                if (ignore_tables.count(seq_table)) continue;
                edges_to_add[seq_table].insert(local_check);
            }

            it++;
            auto higher_tbl = (*it)->to<IR::MAU::Table>();
            BUG_CHECK(it != path.end() && higher_tbl != nullptr, "Table Pathways not correct");
            if (higher_tbl == dom) break;
            local_check = higher_tbl;
        }
    }
}

void PredicationBasedControlEdges::end_apply() {
    if (dg == nullptr) return;
    for (auto &kv : edges_to_add) {
        for (auto dst : kv.second) {
            dg->add_edge(kv.first, dst, DependencyGraph::ANTI_NEXT_TABLE_CONTROL);
        }
    }
}

/**
 * The purpose of this function is to add the extra control dependencies for metadata
 * initialization for Tofino.  Metadata initialization works in the following way:
 *
 * Metadata is assumed to always be initialized to 0.  Two pieces of metadata that are live in
 * the same packet can be overlaid if and only if the metadata have mutually exclusive live
 * ranges.  Before any read of a metadata, the metadata must be set to 0, which generally
 * comes from the parser.  In the overlay cases, however, the metadata itself in the later live
 * range must be written to 0 explicitly.
 *
 * This analysis to guarantee these possibilities is all handled by PHV allocation.  However,
 * the allocation implicitly adds dependencies that cannot be directly tracked by the table
 * dependency graph.  The rule is that all tables that use the metadata in the first live range
 * must appear before any tables using metadata in the second live range.
 * This by definition is a control dependence between two tables.
 *
 * In Tofino, specifically, putting a control dependence in the current analysis won't necessarily
 * work.  The table placement algorithm only works by placing all tables that require next table
 * propagation through them.  Data dependencies between any next table propagation of these
 * two tables are tracked through the TableSeqDeps (a separate analysis than PHV).  However,
 * control dependencies, like this metadata overlay, are not possible to track.
 *
 * The only way to truly track these, while still being able to use the correct analysis of
 * the dependency analysis is to mark two tables in the same TableSeq as Control Dependent.
 * Specifically the two tables marked as CONTROL Dependent are the two tables in the same
 * TableSeq object that require the two actual control dependent tables to follow due to next
 * table propagation limits in Tofino.
 *
 * This constraint is much looser than JBay, and perhaps can be replaced by getting rid of
 * TableSeqDeps, and just using an analysis on the DependencyGraph to pull this information,
 * rather than calculating it directly.
 */
void InjectMetadataControlDependencies::end_apply() {
    if (tables_placed)
        return;

    for (auto kv_pair : phv.getMetadataDeps()) {
        cstring first_table = kv_pair.first;
        BUG_CHECK(name_to_table.count(first_table), "Table %s has a metadata dependency, but "
                  "doesn't appear in the TableGraph?", first_table);
        for (cstring second_table : kv_pair.second) {
            BUG_CHECK(name_to_table.count(second_table), "Table %s has a metadata dependency, but "
                      "doesn't appear in the TableGraph?", second_table);
            auto inject_points = ctrl_paths.get_inject_points(name_to_table.at(first_table),
                                                             name_to_table.at(second_table));
            BUG_CHECK(fg.can_reach(name_to_table.at(first_table), name_to_table.at(second_table)),
                "Metadata initialization analysis incorrect.  Live ranges between %s and %s "
                "overlap", first_table, second_table);
            auto edge_pair = dg.add_edge(name_to_table.at(first_table),
                    name_to_table.at(second_table), DependencyGraph::ANTI_NEXT_TABLE_METADATA);
            auto tpair = std::make_pair(first_table, second_table);
            auto mdDepFields = phv.getMetadataDepFields();
            if (mdDepFields.count(tpair)) {
                auto mdDepField = mdDepFields.at(tpair);
                dg.data_annotations_metadata.emplace(edge_pair.first, mdDepField);
            }
            LOG5("  Injecting ANTI dep between " << first_table << " and " << second_table
                 << " due to metadata initializaation");
            for (auto inject_point : inject_points) {
                auto inj1 = inject_point.first->to<IR::MAU::Table>();
                auto inj2 = inject_point.second->to<IR::MAU::Table>();
                LOG3("  Metadata inject points " << inj1->name << " " << inj2->name
                     << " from tables " << first_table << " " << second_table);
                BUG_CHECK(fg.can_reach(inj1, inj2), "Metadata initialization analysis incorrect.  "
                     "Cannot inject dependency between %s and %s", inj1, inj2);
                // Instead of adding injection points at the control point, just going to
                // rely on the metadata check in table placement, as this could eventually be
                // replaced, along with TableSeqDeps, with a function call
                // dg.add_edge(inject_point.first, inject_point.second, DependencyGraph::CONTROL);
            }
        }
    }
}

/**
 * Adds anti-dependency edges for tables with exiting actions.
 *
 * In Tofino2, `exit()` is desugared into an assignment to an `hasExited` variable, which gets
 * threaded through the program. This results in a read-write dependence between any table with an
 * exiting action and all subsequent tables in the control flow. Here, we mimic this dependence for
 * Tofino's benefit, except we use anti-dependency edges instead of flow dependency edges, and we
 * add edges in a way that maintains the correct chain-length metric for tables.
 *
 * Edges are added as follows. For each table T with an exiting action, start at T and walk up to
 * the top level of the pipe along all possible control-flow paths. For the table T' at each level
 * (including T itself), let S be the table sequence containing T', and add the following
 * anti-dependency edges:
 *   - to T' from the next-table leaves of every predecessor of T' in S.
 *   - from each next-table leaf of T' to every successor of T' in S.
 */
void InjectActionExitAntiDependencies::postorder(const IR::MAU::Table* table) {
    if (tables_placed) return;
    if (!table->has_exit_action()) return;

    std::set<const IR::MAU::Table*> processed;

    // Walk up to the top level of the pipe along each control-flow path to the table.
    for (auto path : ctrl_paths.table_pathways.at(table)) {
        const IR::MAU::Table* curTable = nullptr;
        for (auto parent : path) {
            if (auto t = parent->to<IR::MAU::Table>()) {
                curTable = t;
                continue;
            }

            auto tableSeq = parent->to<IR::MAU::TableSeq>();
            if (!tableSeq) continue;

            if (processed.count(curTable)) continue;

            bool predecessor = true;  // Tracks whether "sibling" is a predecessor of "curTable".
            for (auto sibling : tableSeq->tables) {
                if (sibling == curTable) {
                    predecessor = false;
                    continue;
                }

                if (predecessor) {
                    // Add an anti-dependency to curTable from each next-table leaf of the
                    // predecessor.
                    for (auto leaf : cntp.next_table_leaves.at(sibling)) {
                        auto edge_pair = dg.add_edge(leaf, curTable, DependencyGraph::ANTI_EXIT);
                        dg.data_annotations_exit.emplace(edge_pair.first,
                                                            table->get_exit_actions());
                    }
                } else {
                    // Add an anti-dependency edge from each next-table leaf of curTable to the
                    // successor.
                    for (auto leaf : cntp.next_table_leaves.at(curTable)) {
                        auto edge_pair = dg.add_edge(leaf, sibling, DependencyGraph::ANTI_EXIT);
                        dg.data_annotations_exit.emplace(edge_pair.first,
                                                            table->get_exit_actions());
                    }
                }
            }
        }
    }
}

TableFindInjectedDependencies
        ::TableFindInjectedDependencies(const PhvInfo &p, DependencyGraph& d,
                                        FlowGraph& f, const BFN_Options *options)
        : phv(p), dg(d), fg(f) {
    addPasses({
        // new DominatorAnalysis(dg, dominators),
        // new InjectControlDependencies(dg, dominators),
        // After Table Placement for JBay, it is unsafe to run DefaultNext, which is run for
        // flow graph at the moment.  This is only used for a validation check for metadata
        // dependencies, nothing else.  Has never failed after table placement
        new InjectControlDependencies(dg),
        new FindFlowGraph(fg),
        &ctrl_paths,
        ((options && options->disable_long_branch) || !Device::hasLongBranches())
             ? new PredicationBasedControlEdges(&dg, ctrl_paths) : nullptr,
        new InjectMetadataControlDependencies(phv, dg, fg, ctrl_paths),
        &cntp,
        new InjectActionExitAntiDependencies(dg, cntp, ctrl_paths)
    });
}
