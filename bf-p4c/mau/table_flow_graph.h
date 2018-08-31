#ifndef BF_P4C_MAU_TABLE_FLOW_GRAPH_H_
#define BF_P4C_MAU_TABLE_FLOW_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>
#include <map>
#include <set>
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/default_next.h"

struct FlowGraph {
    typedef enum {
        CONTROL = 1,     // Control dependence.
        CONCURRENT = 0   // No dependency.
    } dependencies_t;
    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::bidirectionalS,   // Directed edges.
        boost::property<boost::vertex_table_t, const IR::MAU::Table*>,  // Vertex labels
        dependencies_t     // Edge labels.
        > Graph;

    Graph g;
    typename Graph::vertex_descriptor v_sink, v_source;

    FlowGraph(void) {
        v_sink = add_vertex(nullptr);
    }
    std::map<const IR::MAU::Table*,
        typename Graph::vertex_descriptor> labelToVertex;

    /* @returns the table pointer corresponding to a vertex in the flow graph
     */
    const IR::MAU::Table* get_vertex(typename Graph::vertex_descriptor v) const {
        return boost::get(boost::vertex_table, g)[v];
    }

    /* If a vertex with this label already exists, return it.  Otherwise,
     * create a new vertex with this label. */
    typename Graph::vertex_descriptor add_vertex(const IR::MAU::Table* label) {
        if (labelToVertex.count(label)) {
            return labelToVertex.at(label);
        } else {
            auto v = boost::add_vertex(label, g);
            labelToVertex[label] = v;
            return v;
        }
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

    friend std::ostream &operator<<(std::ostream &, const FlowGraph&);
};

class FindFlowGraph : public MauInspector {
 private:
    FlowGraph&                                      fg;
    DefaultNext *def_next;

    bool preorder(const IR::MAU::Table *) override;
    Visitor::profile_t init_apply(const IR::Node* node) override;
    bool next_incomplete(const IR::MAU::Table *t);
    void end_apply() override;

 public:
    explicit FindFlowGraph(FlowGraph& out)
    : fg(out) {}
};

#endif /* BF_P4C_MAU_TABLE_FLOW_GRAPH_H_ */
