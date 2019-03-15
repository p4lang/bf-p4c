#include "table_injected_deps.h"
#include <sstream>
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/ltbitmatrix.h"


static std::string printSeq(const IR::MAU::TableSeq* seq) {
    std::stringstream ss;
    for (auto& t : seq->tables) {
        ss << t->name << ", ";
    }
    return ss.str();
}

Visitor::profile_t DominatorAnalysis::init_apply(const IR::Node *node) {
    auto rv = MauInspector::init_apply(node);
    candidate_imm_doms.clear();
    paths_seen.clear();
    return rv;
}

void DominatorAnalysis::end_apply() {
    std::stringstream ss;
    ss << "Dominators are ";
    for (auto& kv : candidate_imm_doms) {
        ss << "(" << printSeq(kv.first) << " for " << kv.second->name << "), ";
    }
    LOG2(ss.str());
    LOG2(dg);
}

void DominatorAnalysis::postorder(const IR::MAU::TableSeq *seq) {
    const Context *ctxt = getContext();
    const IR::MAU::Table *parent = nullptr;
    while (ctxt && !parent) {
            parent = ctxt->node->to<IR::MAU::Table>();
            ctxt = ctxt->parent;
    }

    // Walk up the IR from each TableSeq. The number of paths from any given
    // TableSeq back up to the root of the IR is tracked by paths_seen. Every
    // time two possible paths to the same table join, the join node becomes
    // a possible immediate dominator. The map of candidate immediate dominators
    // stores all immediate dominators after the pass is complete. (Candidates
    // are necessary in case a table is applied 3 or more times.)
    while (ctxt) {
        LOG3("Seq: " << printSeq(seq));
        LOG3("Parent: " << parent->name);
        // Store this sequence in the parent's after getting the old parent value.
        // If the parent already had a non-zero value, update the candidate to the sum
        int old_paths = paths_seen[parent][seq];
        paths_seen[parent][seq]++;
        if (old_paths) {
            candidate_imm_doms[seq] = parent;
        }
        parent = nullptr;
        while (ctxt && !parent) {
            parent = ctxt->node->to<IR::MAU::Table>();
            ctxt = ctxt->parent;
        }
    }
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

void InjectControlDependencies::postorder(const IR::MAU::TableSeq *seq) {
    if (!dominators.count(seq))
        return;
    const IR::MAU::Table *dom = dominators.at(seq);
    const Context *ctxt = getContext();
    const IR::MAU::Table *tbl_parent = nullptr;
    const IR::MAU::TableSeq *seq_parent = nullptr;
    while (ctxt && !tbl_parent) {
        tbl_parent = ctxt->node->to<IR::MAU::Table>();
        ctxt = ctxt->parent;
    }
    while (ctxt) {
        seq_parent = ctxt->node->to<IR::MAU::TableSeq>();
        // Walk up the IR from each duplicated TableSeq, tracking
        // the parent TableSeq and parent Table that the current TableSeq
        // is nested under. Dependencies are inserted between tables in the parent
        // TableSeq and the parent Table
        LOG2("Inject seq: " << printSeq(seq));
        LOG2("Inject parent seq: " << printSeq(seq_parent));
        LOG2("Inject parent table: " << tbl_parent->name);
        if (tbl_parent == dom) {
            LOG2("Halted at dominator " << dom->name);
            break;
        }
        for (auto& t : seq_parent->tables) {
            if (t == tbl_parent) {
                break;
            }
            LOG2("Connecting table " << t->name << " to " << tbl_parent->name);
            dg.add_edge(t, tbl_parent, DependencyGraph::CONTROL);
        }

        tbl_parent = nullptr;
        while (ctxt && !tbl_parent) {
            tbl_parent = ctxt->node->to<IR::MAU::Table>();
            ctxt = ctxt->parent;
        }
    }
}

bool InjectControlDependencies::preorder(const IR::MAU::TableSeq *seq) {
    const Context *ctxt = getContext();
    if (ctxt && dynamic_cast<const IR::MAU::Table *>(ctxt->node)) {
        const IR::MAU::Table* parent;
        parent = dynamic_cast<const IR::MAU::Table *>(ctxt->node);
        for (auto child : seq->tables) {
            dg.add_edge(parent, child, DependencyGraph::CONTROL);
        }
    }

    return true;
}

void InjectControlDependencies::end_apply() {
    // LOG2(dg);
}

/**
 * Gathers all of the tables required to be placed through next table propagation before this
 * table.  Through separate apply statements, there might be more than one way to propagate
 * to another table.
 */
bool GatherPathwaysToTable::preorder(const IR::MAU::Table *tbl) {
    const Context *ctxt = getContext();
    safe_vector<const IR::Node *> pathway;
    pathway.emplace_back(tbl);
    while (ctxt) {
        pathway.push_back(ctxt->node);
        ctxt = ctxt->parent;
    }
    table_pathways[tbl].emplace_back(pathway);
    return true;
}

InjectPoints InjectMetadataControlDependencies::get_inject_points(const IR::MAU::Table *a,
        const IR::MAU::Table *b) {
    InjectPoints rv;
    for (safe_vector<const IR::Node *> a_path : table_pathways.at(a)) {
        for (safe_vector<const IR::Node *> b_path : table_pathways.at(b)) {
            // Attempting to find the first divergence
            const IR::Node *a_first_div = nullptr;
            const IR::Node *b_first_div = nullptr;

            // If one table is within the next table pathway propagation pathway of another,
            // then there is nothing to inject, as this is already control dependendent
            if (std::find(a_path.begin(), a_path.end(), b) != a_path.end())
                BUG("  A metadata use point is not in flow graph order");
            if (std::find(b_path.begin(), b_path.end(), a) != b_path.end())
                continue;

            auto a_path_it = a_path.rbegin();
            auto b_path_it = b_path.rbegin();

            // Start from the Pipe, and work down until the two pathways differ
            while (a_path_it != a_path.rend() && b_path_it != b_path.rend()) {
                if (*a_path_it == *b_path_it) {
                    a_path_it++;
                    b_path_it++;
                    continue;
                }

                a_first_div = *a_path_it;
                b_first_div = *b_path_it;
                break;
            }

            if (a_first_div->is<IR::MAU::TableSeq>()) {
                BUG_CHECK(b_first_div->is<IR::MAU::TableSeq>(), "The first divergence is not "
                    "the same IR node, thus the IR tree is inconsistent");
                continue;
            }

            auto a_dom = a_first_div->to<IR::MAU::Table>();
            if (a_dom != nullptr) {
                auto b_dom = b_first_div->to<IR::MAU::Table>();
                BUG_CHECK(b_dom != nullptr, "The first divergence is not the same IR Node, thus "
                          "the IR tree is inconsistent");
                rv.emplace_back(a_dom, b_dom);
                continue;
            }
            BUG("The Table IR structure has a non-recognizable Node");
        }
    }
    return rv;
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
            auto inject_points = get_inject_points(name_to_table.at(first_table),
                                                   name_to_table.at(second_table));
            BUG_CHECK(fg.can_reach(name_to_table.at(first_table), name_to_table.at(second_table)),
                "Metadata initialization analysis incorrect.  Live ranges between %s and %s "
                "overlap", first_table, second_table);
            dg.add_edge(name_to_table.at(first_table), name_to_table.at(second_table),
                        DependencyGraph::CONTROL);
            for (auto inject_point : inject_points) {
                LOG3("  Metadata inject points " << inject_point.first->name << " "
                     << inject_point.second->name << " from tables " << first_table << " "
                     << second_table);
                BUG_CHECK(fg.can_reach(inject_point.first, inject_point.second), "Metadata "
                     "initialization analysis incorrect.  Cannot inject dependency between %s "
                     "and %s", inject_point.first, inject_point.second);
                dg.add_edge(inject_point.first, inject_point.second, DependencyGraph::CONTROL);
            }
        }
    }
}

TableFindInjectedDependencies
        ::TableFindInjectedDependencies(const PhvInfo &p, DependencyGraph& d)
        : phv(p), dg(d) {
    addPasses({
        new DominatorAnalysis(dg, dominators),
        new InjectControlDependencies(dg, dominators),
        new FindFlowGraph(fg),
        new GatherPathwaysToTable(tp),
        new InjectMetadataControlDependencies(phv, tp, dg, fg)
    });
}

