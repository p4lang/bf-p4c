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
    bool preorder(const IR::MAU::TableSeq *seq) override;

 private:
    DependencyGraph& dg;

 public:
    explicit InjectControlDependencies(DependencyGraph& out) : dg(out) {
        visitDagOnce = false;
    }
};


class PredicationBasedControlEdges : public MauInspector {
    DependencyGraph *dg;
    const ControlPathwaysToTable &ctrl_paths;
    ordered_map<const IR::MAU::Table *, ordered_set<const IR::MAU::Table *>> edges_to_add;

 public:
    std::map<cstring, const IR::MAU::Table *> name_to_table;

 private:
    profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        edges_to_add.clear();
        return rv;
    }

    void postorder(const IR::MAU::Table *) override;
    void end_apply() override;

 public:
    bool edge(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
        if (edges_to_add.count(a) == 0) return false;
        return edges_to_add.at(a).count(b);
    }

    PredicationBasedControlEdges(DependencyGraph *d, const ControlPathwaysToTable &cp)
        : dg(d), ctrl_paths(cp) {}
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
            const ControlPathwaysToTable &cp)
        : AbstractDependencyInjector(g, cp), phv(p), fg(f) { }
};

class InjectActionExitAntiDependencies : public AbstractDependencyInjector {
    const CalculateNextTableProp& cntp;

    void postorder(const IR::MAU::Table* table) override;

 public:
    InjectActionExitAntiDependencies(DependencyGraph &g, const CalculateNextTableProp &cntp,
            const ControlPathwaysToTable &cp)
        : AbstractDependencyInjector(g, cp), cntp(cntp) { }
};


class InjectDarkAntiDependencies : public AbstractDependencyInjector {
    const PhvInfo &phv;
    bool placed = false;
    std::map<UniqueId, const IR::MAU::Table *> id_to_table;

    profile_t init_apply(const IR::Node *node) override {
        auto rv = AbstractDependencyInjector::init_apply(node);
        placed = false;
        id_to_table.clear();
        return rv;
    }

    bool preorder(const IR::MAU::Table *) override;
    void end_apply() override;

 public:
    InjectDarkAntiDependencies(const PhvInfo &p, DependencyGraph &g,
            const ControlPathwaysToTable &cp)
        : AbstractDependencyInjector(g, cp), phv(p) { }
};

class TableFindInjectedDependencies : public PassManager {
    const PhvInfo &phv;
    DependencyGraph &dg;
    FlowGraph &fg;
    ControlPathwaysToTable ctrl_paths;
    CalculateNextTableProp cntp;

    profile_t init_apply(const IR::Node *root) override {
        auto rv = PassManager::init_apply(root);
        fg.clear();
        return rv;
    }

 public:
    explicit TableFindInjectedDependencies(const PhvInfo &p, DependencyGraph& dg,
        FlowGraph& fg, const BFN_Options *options = nullptr);
 private:
    // Duplicates to dominators
    ordered_map<const IR::MAU::TableSeq*, const IR::MAU::Table*> dominators;
};

#endif /* BF_P4C_MAU_TABLE_INJECTED_DEPS_H_ */
