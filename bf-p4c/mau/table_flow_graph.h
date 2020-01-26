#ifndef BF_P4C_MAU_TABLE_FLOW_GRAPH_H_
#define BF_P4C_MAU_TABLE_FLOW_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>
#include <map>
#include <set>
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"

namespace boost {
    enum vertex_table_t { vertex_table };
    BOOST_INSTALL_PROPERTY(vertex, table);

    enum edge_annotation_t { edge_annotation };
    BOOST_INSTALL_PROPERTY(edge, annotation);
}

/// Represents a control-flow graph between the tables in a program, reflecting the logical control
/// flow through the program.
struct FlowGraph {
    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::bidirectionalS,   // Directed edges.
        // Label vertices with tables.
        boost::property<boost::vertex_table_t, const IR::MAU::Table*>,
        // Label edges with control annotations.
        boost::property<boost::edge_annotation_t, cstring>
    > Graph;

    /// The underlying Boost graph backing this FlowGraph.
    Graph g;

    /// The source node, representing the entry point (i.e., entry from the parser).
    typename Graph::vertex_descriptor v_source;

    /// The sink node, representing the exit point (i.e., entry to the deparser).
    typename Graph::vertex_descriptor v_sink;

    boost::optional<gress_t> gress;

    /// Maps each vertex to the set of IDs for all nodes reachable from that vertex. Vertices are
    /// not considered reachable from themselves unless the graph has cycles.
    std::map<typename Graph::vertex_descriptor, bitvec> reachableNodes;

    /// Maps each table to its corresponding vertex ID in the Boost graph.
    ordered_map<const IR::MAU::Table*, int> tableToVertexIndex;

    // By default, emptyFlowGraph is set to true to indicate that there are no vertices in the
    // graph. Only when the first actual table is added to the flow graph is this member set to
    // false.
    bool emptyFlowGraph = true;

    /// @returns the control-flow annotation for the given edge.
    const cstring
    get_ctrl_dependency_info(typename Graph::edge_descriptor edge) const {
        return boost::get(boost::edge_annotation, g)[edge];
    }

    FlowGraph(void) {
        gress = boost::none;
    }

    /// Maps each table to its associated graph vertex.
    std::map<const IR::MAU::Table*, typename Graph::vertex_descriptor> tableToVertex;

    /// Determines whether this graph is empty.
    // XXX Why not use emptyFlowGraph?
    bool is_empty() const {
        auto all_vertices = boost::vertices(g);
        if (++all_vertices.first == all_vertices.second) {
            return true;
        }
        return false;
    }

    /// Clears the state in this FlowGraph.
    void clear() {
        g.clear();
        gress = boost::none;
        reachableNodes.clear();
        tableToVertexIndex.clear();
        tableToVertex.clear();
        emptyFlowGraph = true;
    }

    void add_sink_vertex() {
        v_sink = add_vertex(nullptr);
    }

    /// @returns true iff there is a path in the flow graph from @t1 to @t2. Passing nullptr for
    /// @t1 or @t2 designates the sink node (consider it the deparser). Tables are not considered
    /// reachable from themselves unless they are part of a cycle in the graph.
    bool can_reach(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (t2 == nullptr) return true;
        if (t1 == nullptr) return false;
        BUG_CHECK(tableToVertexIndex.count(t1), "Table object not found for %1%", t1->name);
        BUG_CHECK(tableToVertexIndex.count(t2), "Table object not found for %1%", t2->name);
        const auto v1 = tableToVertexIndex.at(t1);
        const auto v2 = tableToVertexIndex.at(t2);
        BUG_CHECK(reachableNodes.count(v1), "No reachable nodes entry for %1%", t1->name);
        return reachableNodes.at(v1).getbit(v2);
    }

    /// @returns the table pointer corresponding to a vertex in the flow graph
    const IR::MAU::Table* get_vertex(typename Graph::vertex_descriptor v) const {
        return boost::get(boost::vertex_table, g)[v];
    }

    /// @return the vertex associated with the given table, creating the vertex if one does not
    /// already exist.
    typename Graph::vertex_descriptor add_vertex(const IR::MAU::Table* table) {
        // Initialize gress if needed.
        if (table != nullptr && gress == boost::none)
            gress = table->gress;

        if (tableToVertex.count(table)) {
            return tableToVertex.at(table);
        }

        // Create new vertex.
        auto v = boost::add_vertex(table, g);
        tableToVertex[table] = v;

        // If the vertex being added corresponds to a real table (not the sink), then the flow
        // graph is no longer empty; set the emptyFlowGraph member accordingly.
        if (table != nullptr) emptyFlowGraph = false;

        return v;
    }

    /// Return an edge descriptor from the given src to the given dst, creating the edge if one
    /// doesn't already exist. The returned bool is true when this is a newly-created edge.
    std::pair<typename Graph::edge_descriptor, bool> add_edge(
        const IR::MAU::Table* src,
        const IR::MAU::Table* dst,
        const cstring edge_label
    ) {
        typename Graph::vertex_descriptor src_v, dst_v;
        src_v = add_vertex(src);
        dst_v = add_vertex(dst);

        // Look for a pre-existing edge.
        typename Graph::out_edge_iterator out, end;
        for (boost::tie(out, end) = boost::out_edges(src_v, g); out != end; ++out) {
            if (boost::target(*out, g) == dst_v)
                return {*out, false};
        }

        // No pre-existing edge, so make one.
        auto maybe_new_e = boost::add_edge(src_v, dst_v, g);
        if (!maybe_new_e.second)
            // A vector-based adjacency_list (i.e. Graph) is a multigraph.
            // Inserting edges should always create new edges.
            BUG("Boost Graph Library failed to add edge.");
        boost::get(boost::edge_annotation, g)[maybe_new_e.first] = edge_label;
        return {maybe_new_e.first, true};
    }

    friend std::ostream &operator<<(std::ostream &, const FlowGraph&);
    static void dump_viz(std::ostream &out, const FlowGraph &fg);
};

/// Computes a table control-flow graph for the IR.
//
// FIXME(Jed): This currently only works when gateway conditions are represented as separate table
// objects. After table placement, gateways and match tables are fused into single table objects.
// This pass should be fixed at some point to support this fused representation.
//
// Here are some thoughts on how to this. We can leverage the call structure in
// IR::MAU::Table::visit_children; specifically, the calls to flow_clone, visit(Node, label),
// flow_merge_global_to, and flow_merge. This should give us enough information to track the set of
// tables that could have been the last one to execute before reaching the node being visited. With
// this, we should be able to build the flow graph. Effectively, we would piggyback on the existing
// infrastructure in visit_children for supporting ControlFlowVisitor. We don't actually want to
// write a ControlFlowVisitor here, however, since in its current form, ControlFlowVisitor will
// deadlock when there are cycles in the IR; FindFlowGraph is used in part to check that the IR is
// cycle-free.
class FindFlowGraph : public MauInspector {
 private:
    /// The computed flow graph.
    FlowGraph& fg;

    /**
     * The next table that will be executed after the current branch is done executing. For
     * example, in the following IR fragment, while the subtree rooted at t1 is visited, next_table
     * will be t7; while the subtree rooted at t2 is visited, next_table will be t3. This is
     * nullptr when there is no next table (i.e., if control flow would exit to the deparser).
     *
     *          [ t1  t7 ]
     *           /  \
     *    [t2  t3]  [t6]
     *    /  \
     * [t4]  [t5]
     */
    const IR::MAU::Table* next_table;

    /// Helper for determining whether next_table executes immediately after the given table, and
    /// the appropriate edge label to use.
    std::pair<bool, cstring> next_incomplete(const IR::MAU::Table *t);

    Visitor::profile_t init_apply(const IR::Node* node) override;
    bool preorder(const IR::MAU::TableSeq*) override;
    bool preorder(const IR::MAU::Table *) override;
    void end_apply() override;

 public:
    explicit FindFlowGraph(FlowGraph& out) : fg(out), next_table(nullptr) {
        // We want to re-visit table nodes here, since the table calls can have different
        // next_tables in different contexts.
        visitDagOnce = false;
    }
};

#endif /* BF_P4C_MAU_TABLE_FLOW_GRAPH_H_ */
