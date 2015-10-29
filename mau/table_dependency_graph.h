#ifndef _table_dependency_graph_h_
#define _table_dependency_graph_h_

#include "ir/ir.h"

struct DependencyGraph {
    struct Table {
	enum depend_t { WRITE, ACTION, MATCH };
	cstring		name;
	gress_t		gress;
	int		min_stage = -1, dep_stages = -1;
	map<cstring, depend_t>			data_dep;
	map<cstring, cstring>			control_dep;
	Table(cstring n, gress_t gr) : name(n), gress(gr) {}
    };
    struct access_t { set<Table *> read, write; };
    map<cstring, Table>		graph;
    void clear() { graph.clear(); }
    friend std::ostream &operator<<(std::ostream &, const DependencyGraph&);
};

class FindDependencyGraph : public Inspector, ControlFlowVisitor {
    typedef DependencyGraph::Table	Table;
    typedef DependencyGraph::access_t	access_t;
    const IR::MAU::Pipe			*maupipe;
    map<cstring, Table>			&graph;
    gress_t				gress;
    map<cstring, access_t>		access;
    void add_control_dependency(Table *, const IR::Node * = 0);
    void recompute_dep_stages();

    // alt 3 functions
    bool preorder(const IR::MAU::Pipe *p) override {
	graph.clear(); maupipe = p; return true; }
    bool preorder(const IR::MAU::TableSeq *s) override;
    bool preorder(const IR::MAU::Table *c) override;
    void postorder(const IR::MAU::Pipe *p) override { recompute_dep_stages(); }

    void flow_merge(Visitor &v) override;
    Visitor *clone() const override { return new FindDependencyGraph(*this); }
public:
    FindDependencyGraph(DependencyGraph *out) : graph(out->graph) {}
};

#endif /* _table_dependency_graph_h_ */
