#ifndef BF_P4C_MAU_TABLE_INJECTED_DEPS_H_
#define BF_P4C_MAU_TABLE_INJECTED_DEPS_H_

#include <map>
#include <stack>
#include "mau_visitor.h"
#include "table_dependency_graph.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "lib/ordered_set.h"
#include "lib/ordered_map.h"



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

/// Common functionality for injecting dependencies into a DependencyGraph.
class AbstractDependencyInjector : public MauInspector {
 protected:
    bool tables_placed = false;
    DependencyGraph &dg;
    const ControlPathwaysToTable &ctrl_paths;

    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        tables_placed = false;
        return rv;
    }

    bool preorder(const IR::MAU::Table *t) override {
        tables_placed |= t->is_placed();
        return true;
    }

 public:
    AbstractDependencyInjector(DependencyGraph &dg, const ControlPathwaysToTable &cp)
        : dg(dg), ctrl_paths(cp) {}
};

/**
 * Currently it is not safe to run the flow graph after Table Placement in JBay, as the
 * DefaultNext pass won't be secure, we currently don't run it.  The flow graph really
 * just needs to be updated to run as a ControlFlowVisitor
 */
class InjectMetadataControlDependencies : public AbstractDependencyInjector {
    const PhvInfo &phv;
    const FlowGraph &fg;
    bool run_flow_graph;
    std::map<cstring, const IR::MAU::Table *> name_to_table;

    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = AbstractDependencyInjector::init_apply(node);
        name_to_table.clear();
        return rv;
    }

    bool preorder(const IR::MAU::Table *t) override {
        auto rv = AbstractDependencyInjector::preorder(t);
        name_to_table[t->name] = t;
        return rv;
    }

    void end_apply() override;

 public:
    InjectMetadataControlDependencies(const PhvInfo &p, DependencyGraph &g, const FlowGraph &f,
            const ControlPathwaysToTable &cp, bool rgf )
        : AbstractDependencyInjector(g, cp), phv(p), fg(f), run_flow_graph(rgf) { }
};

class InjectActionExitAntiDependencies : public AbstractDependencyInjector {
    const CalculateNextTableProp& cntp;

    void postorder(const IR::MAU::Table* table) override;

 public:
    InjectActionExitAntiDependencies(DependencyGraph &g, const CalculateNextTableProp &cntp,
            const ControlPathwaysToTable &cp)
        : AbstractDependencyInjector(g, cp), cntp(cntp) { }
};

class TableFindInjectedDependencies : public PassManager {
    const PhvInfo &phv;
    DependencyGraph &dg;
    ControlPathwaysToTable ctrl_paths;
    FlowGraph fg;
    CalculateNextTableProp cntp;

    profile_t init_apply(const IR::Node *root) override {
        auto rv = PassManager::init_apply(root);
        fg.clear();
        return rv;
    }

 public:
    explicit TableFindInjectedDependencies(const PhvInfo &p, DependencyGraph& dg,
        bool run_flow_graph);
 private:
    // Duplicates to dominators
    ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*> dominators;
};

#endif /* BF_P4C_MAU_TABLE_INJECTED_DEPS_H_ */
