#ifndef _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include "mau_visitor.h"

struct DependencyGraph {
    struct Table {
        enum depend_t { WRITE, ACTION, MATCH };
        cstring         name;
        gress_t         gress;
        int             min_stage = -1, dep_stages = -1;
        map<cstring, depend_t>                  data_dep;
        map<cstring, cstring>                   control_dep;
        Table(cstring n, gress_t gr) : name(n), gress(gr) {}
    };
    struct access_t { set<Table *> read, write; };
    map<cstring, Table>         graph;
    void clear() { graph.clear(); }
    friend std::ostream &operator<<(std::ostream &, const DependencyGraph&);
};

class FindDependencyGraph : public MauInspector, ControlFlowVisitor {
    typedef DependencyGraph::Table      Table;
    typedef DependencyGraph::access_t   access_t;
    const IR::Tofino::Pipe              *maupipe;
    map<cstring, Table>                 &graph;
    gress_t                             gress;
    map<cstring, access_t>              access;
    void add_control_dependency(Table *, const IR::Node * = 0);
    void recompute_dep_stages();

    // alt 3 functions
    bool preorder(const IR::Tofino::Pipe *p) override {
        graph.clear(); maupipe = p; return true; }
    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::MAU::Table *) override;
    void postorder(const IR::Tofino::Pipe *) override { recompute_dep_stages(); }

    void flow_merge(Visitor &v) override;
    FindDependencyGraph *clone() const override { return new FindDependencyGraph(*this); }
 public:
    explicit FindDependencyGraph(DependencyGraph *out) : graph(out->graph) {}
};

#endif /* _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
