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
        LOG1("Seq: " << printSeq(seq));
        LOG1("Parent: " << parent->name);
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

TableFindInjectedDependencies::TableFindInjectedDependencies(DependencyGraph& dg) : PassManager {
    new DominatorAnalysis(dg, dominators),
    new InjectControlDependencies(dg, dominators)
} {
    visitDagOnce = false;
}

