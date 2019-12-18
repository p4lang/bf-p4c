#include <boost/graph/graphviz.hpp>
#include "bf-p4c/mau/table_flow_graph.h"

static const char* dep_types(FlowGraph::dependencies_t dep) {
    switch (dep) {
        case FlowGraph::CONTROL: return "CONTROL";
        default: return "UNKNOWN";
    }
}

std::ostream &operator<<(std::ostream &out, const FlowGraph &fg) {
    auto all_vertices = boost::vertices(fg.g);
    if (++all_vertices.first == all_vertices.second) {
        out << "FLOW_GRAPH EMPTY" << std::endl;
        return out;
    }
    auto source_gress = fg.get_vertex(fg.v_source)->gress;
    out << "FLOW_GRAPH (" << source_gress << ")" << std::endl;
    FlowGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(fg.g); edges != edges_end; ++edges) {
        auto src = boost::source(*edges, fg.g);
        const IR::MAU::Table* source = fg.get_vertex(src);
        auto dst = boost::target(*edges, fg.g);
        const IR::MAU::Table* target = fg.get_vertex(dst);
        out << "    " << (source ? source->name : "SINK") <<
            (src == fg.v_source ? " (SOURCE)" : "") << " -- " <<
            dep_types(fg.g[*edges]) << " --> " <<
            (target ? target->name : "SINK") << std::endl;
    }
    return out;
}

void FlowGraph::dump_viz(std::ostream &out, const FlowGraph &fg) {
    auto all_vertices = boost::vertices(fg.g);
    if (++all_vertices.first == all_vertices.second) {
        out << "digraph empty {\n}" << std::endl;
        return;
    }
    auto source_gress = fg.get_vertex(fg.v_source)->gress;
    out << "digraph " << source_gress << " {" << std::endl;
    FlowGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(fg.g); edges != edges_end; ++edges) {
        auto src = boost::source(*edges, fg.g);
        const IR::MAU::Table* source = fg.get_vertex(src);
        auto dst = boost::target(*edges, fg.g);
        const IR::MAU::Table* target = fg.get_vertex(dst);
        std::string src_name = std::string(source ? source->name : "SINK");
        std::string dst_name = std::string(target ? target->name : "SINK");
        std::replace(src_name.begin(), src_name.end(), '-', '_');
        std::replace(dst_name.begin(), dst_name.end(), '-', '_');
        std::replace(src_name.begin(), src_name.end(), '.', '_');
        std::replace(dst_name.begin(), dst_name.end(), '.', '_');
        out << "    " << src_name.c_str() << (src == fg.v_source ? "_SOURCE" : "") << " -> " <<
            dst_name.c_str() << std::endl;
    }
    out << "}" << std::endl;
}

Visitor::profile_t FindFlowGraph::init_apply(const IR::Node* node) {
    auto rv = Inspector::init_apply(node);
    fg.clear();
    fg.add_sink_vertex();
    // Currently already running the default next pass before
    def_next = new DefaultNext(false);
    node->apply(*def_next);
    return rv;
}

std::pair<bool, cstring> FindFlowGraph::next_incomplete(const IR::MAU::Table *t) {
    // TODO: Handle $try_next_stage
    if (t->next.count("$hit") && t->next.count("$miss"))
        return std::make_pair(false, "");
    if (t->next.count("$hit") || t->next.count("$miss")) {
        if (t->next.count("$hit")) {
            return std::make_pair(true, "$miss");
        }
        return std::make_pair(true, "$hit");
    }
    if (t->next.count("$true") && t->next.count("$false"))
        return std::make_pair(false, "");
    if (t->next.count("$true") || t->next.count("$false")) {
        // BUG("Gateway has one of true or false but not both");
        if (t->next.count("$true")) {
            return std::make_pair(true, "$false");
        }
        return std::make_pair(true, "$true");
    }
    if (t->next.count("$default"))
        return std::make_pair(false, "");
    if (t->next.size() == 0)
        return std::make_pair(true, "$default");
    for (auto kv : t->actions) {
        if (!t->next.count(kv.first)) {
            return std::make_pair(true, "$hit");
        }
    }
    return std::make_pair(false, "");
}

bool FindFlowGraph::preorder(const IR::MAU::Table *t) {
    for (auto options : t->next) {
        const IR::MAU::Table *dst;
        if (options.second->tables.size() > 0) {
            dst = options.second->tables[0];
        } else {
            // This will sometimes be null, which will cause an edge to be added to v_sink
            dst = def_next->next(t);
        }
        auto dst_name = dst ? dst->name : "SINK";
        LOG1("Parent : " << t->name << " --> " << options.first << " --> " << dst_name);
        auto edge_pair = fg.add_edge(t, dst, FlowGraph::CONTROL);
        fg.ctrl_annotations[edge_pair.first] = options.first;
    }
    LOG3("Table: " << t->name << " Next: " <<
        (def_next->next(t) ? def_next->next(t)->name : "<null>"));
    auto n = next_incomplete(t);
    LOG3("next - " << n.first << ":" << n.second);
    if (n.first) {
        const IR::MAU::Table *default_next = def_next->next(t);
        auto dst_name = default_next ? default_next->name : "SINK";
        LOG1("Parent : " << t->name << " --> " << n.second << " --> " << dst_name);
        // This will sometimes be null, which will cause an edge to be added to v_sink
        auto edge_pair = fg.add_edge(t, default_next, FlowGraph::CONTROL);
        fg.ctrl_annotations[edge_pair.first] = n.second;
    }
    return true;
}

void FindFlowGraph::end_apply() {
    typename FlowGraph::Graph::vertex_iterator v, v_end;
    bool source_found = false;
    for (boost::tie(v, v_end) = boost::vertices(fg.g); v != v_end; ++v) {
        if (*v == fg.v_sink)
            continue;
        auto in_edge_pair = boost::in_edges(*v, fg.g);
        if (in_edge_pair.first == in_edge_pair.second) {
            if (source_found) {
                LOG1("Source already seen -- are you running the flow graph on >1 gresses?");
                LOG1("Possible v_source extra is " << fg.get_vertex(*v)->name);
            } else {
                fg.v_source = *v;
                source_found = true;
            }
        }
    }
    LOG4(fg);
    if (LOGGING(4))
        FlowGraph::dump_viz(std::cout, fg);

    for (boost::tie(v, v_end) = boost::vertices(fg.g); v != v_end; ++v) {
        if (*v != fg.v_sink)
            fg.tableToVertexIndex[fg.get_vertex(*v)] = *v;
        bitvec visited_vertices;
        BFSVisitor vis(visited_vertices);
        boost::breadth_first_search(fg.g, *v, boost::visitor(vis));
        fg.reachableNodes[*v] = visited_vertices;
    }
}
