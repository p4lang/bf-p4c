#include "deparse_graph.h"

DeparseGraph::Node DeparseGraph::addField(const PHV::Field* f) {
    if (fieldToVertex.count(f)) return fieldToVertex.at(f);

    fields.insert(f);
    reachability.clear();
    return fieldToVertex[f] = boost::add_vertex(NodeInfo(f), g);
}

DeparseGraph::Node DeparseGraph::addConst(const IR::Constant* c) {
    reachability.clear();
    return boost::add_vertex(NodeInfo(c), g);
}

bool DeparseGraph::addEdge(Node src, Node dst) {
    // Look for a pre-existing edge.
    typename Graph::out_edge_iterator out, end;
    for (boost::tie(out, end) = boost::out_edges(src, g); out != end; ++out) {
        if (boost::target(*out, g) == dst) return false;
    }

    // No pre-existing edge, so make one.
    auto maybeNewEdge = boost::add_edge(src, dst, g);

    // A vector-based adjacency_list (i.e. Graph) is a multigraph.
    // Inserting edges should always create new edges.
    BUG_CHECK(maybeNewEdge.second, "Boost Graph Library failed to add edge.");

    reachability.clear();

    return true;
}

bool DeparseGraph::canReach(const PHV::Field* f1, const PHV::Field* f2) const {
    BUG_CHECK(fieldToVertex.count(f1), "Field %1% not found in deparser graph", f1->name);
    BUG_CHECK(fieldToVertex.count(f2), "Field %1% not found in deparser graph", f2->name);

    auto n1 = fieldToVertex.at(f1);
    auto n2 = fieldToVertex.at(f2);

    return reachability.canReach(n1, f1->name, n2, f2->name);
}

const std::vector<DeparseGraph::NodeInfo>
DeparseGraph::nodesBetween(const PHV::Field* f1, const PHV::Field* f2) const {
    BUG_CHECK(fieldToVertex.count(f1), "Field %1% not found in deparser graph", f1->name);
    BUG_CHECK(fieldToVertex.count(f2), "Field %1% not found in deparser graph", f2->name);

    auto n1 = fieldToVertex.at(f1);
    auto n2 = fieldToVertex.at(f2);

    std::vector<NodeInfo> result;
    for (auto node : reachability.reachableBetween(n1, f1->name, n2, f2->name)) {
        result.push_back(g[node]);
    }

    return result;
}

void DeparseGraph::clear() {
    g.clear();
    reachability.clear();
    fields.clear();
    fieldToVertex.clear();
}