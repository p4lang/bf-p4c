#ifndef _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

/* The DependencyGraph data structure is a directed graph in which tables are
 * vertices and edges are dependencies.  An edge from t1 to t2 means that t2
 * depends on t1.
 *
 * Edges are annotated with the kind of dependency that exists between tables.
 * Note that there may be more than one edge from one table to another, each
 * representing a different dependency.
 *
 * The dependencies are:
 *
 *  - t1 -- CONTROL --> t2: Table t1 sets next-table information that decides
 *    whether t2 is applied.
 *
 *  - t1 -- OUTPUT ---> t2: Table t1 may write a field that t2 may also write.
 *
 *  - t1 -- DATA -----> t2: Table t1 may write a field that t2 may read.
 *
 *  - t1 -- ANTI -----> t2: Table t1 may read a field that t1 may write.
 */

struct DependencyGraph {
    typedef enum {
        CONTROL,    // Control dependence.
        DATA,       // Read-after-write (data) dependence.
        ANTI,       // Write-after-read (anti) dependence.
        OUTPUT      // Write-after-write (output) dependence.
    } dependencies_t;
    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::bidirectionalS,   // Directed edges.
        const IR::MAU::Table*,   // Vertex labels.
        dependencies_t     // Edge labels.
        > Graph;

    Graph g;                // Dependency graph.

    // True once the graph has been fully constructed.
    bool finalized;

    // happens_before[t1] = {t2, t3} means that t1 happens strictly before t1
    // and t2: t1 MUST be placed in an earlier stage.
    map< const IR::MAU::Table*,
         set<const IR::MAU::Table*> > happens_before_map;

    map<const IR::MAU::Table*,
        typename Graph::vertex_descriptor> labelToVertex;

    struct StageInfo {
        int min_stage,      // Minimum stage at which a table can be placed.
        dep_stages;         // Number of tables that depend on this table and
                            // must be placed in a stage after it.
    };
    map<const IR::MAU::Table*, StageInfo> stage_info;

    DependencyGraph(void) { finalized = false; }

    /* If a vertex with this label already exists, return it.  Otherwise,
     * create a new vertex with this label. */ 
    typename Graph::vertex_descriptor add_vertex(const IR::MAU::Table* label) {
        try {
            return labelToVertex.at(label); }
        catch (std::out_of_range& oor) {
            auto v = boost::add_vertex(g);
            g[v] = label;
            labelToVertex[label] = v;
            stage_info[label] = {0, 0};
            return v; }
    }

    /* Return an edge descriptor.  If bool is true, then this is a
     * newly-created edge.  If false, then the edge descriptor points to the
     * edge from src to dst with edge_label that already existed.  */
    std::pair<typename Graph::edge_descriptor, bool> add_edge(
        const IR::MAU::Table* src,
        const IR::MAU::Table* dst,
        dependencies_t edge_label) {
        typename Graph::vertex_descriptor src_v, dst_v;
        src_v = add_vertex(src);
        dst_v = add_vertex(dst);

        typename Graph::out_edge_iterator out, end;
        for (boost::tie(out, end) = boost::out_edges(src_v, g); out != end; ++out) {
            if (boost::target(*out, g) == dst_v && g[*out] == edge_label)
                return {*out, false};
        }

        auto maybe_new_e = boost::add_edge(src_v, dst_v, g);
        if (!maybe_new_e.second)
            // A vector-based adjacency_list (i.e. Graph) is a multigraph.
            // Inserting edges should always create new edges.
            BUG("Boost Graph Library failed to add edge.");
        g[maybe_new_e.first] = edge_label;

        return {maybe_new_e.first, true};
    }

    bool happens_before(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        try {
            auto downstream = happens_before_map.at(t1);
            return downstream.find(t2) != downstream.end(); }
        catch (std::out_of_range& oor) {
            return false; }
    }

    int dependence_tail_size(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).dep_stages;
    }

    int min_stage(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).min_stage;
    }

    set<const IR::MAU::Table*>
    happens_before_dependences(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return happens_before_map.at(t);
    }

    friend std::ostream &operator<<(std::ostream &, const DependencyGraph&);
};

class FindDependencyGraph : public MauInspector, ControlFlowVisitor {
 public:
    typedef struct { ordered_set<const IR::MAU::Table*> read, write; } access_t;

 private:
    PhvInfo                                              &phv;
    DependencyGraph                                      &dg;
    map<cstring, access_t>                               access;

    void finalize_dependence_graph(void);

    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::MAU::Table *) override;
    void end_apply() override { finalize_dependence_graph(); }

    void flow_merge(Visitor &v) override;

    void all_bfs(boost::default_bfs_visitor* vis);
    bool filter_join_point(const IR::Node *n) override { return !n->is<IR::MAU::TableSeq>(); }
    FindDependencyGraph *clone() const override { return new FindDependencyGraph(*this); }

    class AddDependencies;
    class UpdateAccess;
    class UpdateAttached;

 public:
    explicit FindDependencyGraph(PhvInfo &phv, DependencyGraph& out)
    : phv(phv), dg(out) { joinFlows = true; }
};

#endif /* _TOFINO_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
