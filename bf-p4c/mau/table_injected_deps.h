#ifndef BF_P4C_MAU_TABLE_INJECTED_DEPS_H_
#define BF_P4C_MAU_TABLE_INJECTED_DEPS_H_

#include <map>
#include <stack>
#include "mau_visitor.h"
#include "table_dependency_graph.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "lib/ordered_set.h"
#include "lib/ordered_map.h"


class TableFindInjectedDependencies : public PassManager {
 public:
    explicit TableFindInjectedDependencies(DependencyGraph& dg);
 private:
    // Duplicates to dominators
    ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*> dominators;
};

class InjectControlDependencies : public MauInspector {
    void postorder(const IR::MAU::TableSeq *seq) override;
    bool preorder(const IR::MAU::TableSeq *seq) override;
    void end_apply() override;
 private:
    DependencyGraph& dg;
    // Duplicates to dominators
    ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*>& dominators;
 public:
    explicit InjectControlDependencies(DependencyGraph& out,
                   ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*>& dom_in)
    : dg(out), dominators(dom_in) {
        visitDagOnce = false;
    }
};

class DominatorAnalysis : public MauInspector {
    Visitor::profile_t init_apply(const IR::Node *node) override;
    void postorder(const IR::MAU::TableSeq *seq) override;
    void end_apply() override;
 private:
    DependencyGraph& dg;
    // Duplicates to possible dominators
    ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*>& candidate_imm_doms;
    // For each node, the number of paths for each node up through it
    ordered_map<const IR::MAU::Table*, ordered_map<const IR::MAU::TableSeq*, int>> paths_seen;
 public:
    explicit DominatorAnalysis(DependencyGraph& out,
                ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*>& dom_out)
    : dg(out), candidate_imm_doms(dom_out) {
        visitDagOnce = false;
    }
};

#endif /* BF_P4C_MAU_TABLE_INJECTED_DEPS_H_ */
