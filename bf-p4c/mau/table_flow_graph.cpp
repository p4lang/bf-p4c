#include <boost/graph/graphviz.hpp>
#include "bf-p4c/mau/table_flow_graph.h"

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
        auto desc = fg.get_ctrl_dependency_info(*edges);
        out << "    " << (source ? source->name : "SINK") <<
            (src == fg.v_source ? " (SOURCE)" : "") << " -- " << desc << " --> " <<
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

const std::set<const IR::MAU::Table*>
FlowGraph::get_dominators(const IR::MAU::Table* table) const {
    if (!dominators) {
        // Compute dominator sets. Taken from the Wikipedia article on dominators.
        using TableSet = std::set<const IR::MAU::Table*>;
        using DominatorMap = std::map<const IR::MAU::Table*, TableSet>;
        dominators = boost::optional<DominatorMap>(DominatorMap());
        auto& dominators = *this->dominators;

        // The start node dominates itself. For all other nodes, set all nodes as the
        // dominators.
        auto* source = get_vertex(v_source);
        for (auto* table : tables) {
            if (table == source) dominators[table].insert(table);
            else
                dominators[table] = tables;
        }
        dominators[nullptr] = tables;

        // The dominator set for each table is the intersection of the dominator sets of all the
        // table's predecessors. This means that any time we recompute a table's dominator set, its
        // successors will also need to be recomputed.
        //
        // Start by recomputing all of the start node's successors.
        TableSet toRecompute;
        typename FlowGraph::Graph::out_edge_iterator out_edges, out_edges_end;
        boost::tie(out_edges, out_edges_end) = boost::out_edges(v_source, g);
        for (; out_edges != out_edges_end; ++out_edges) {
            auto target = boost::target(*out_edges, g);
            toRecompute.insert(get_vertex(target));
        }

        while (!toRecompute.empty()) {
            auto* table = *toRecompute.begin();
            toRecompute.erase(table);

            // Recompute the dominator set for the current table. Take the intersection of
            // the current dominator sets of all the table's predecessors.
            TableSet recomputed = tables;

            typename FlowGraph::Graph::in_edge_iterator edges, edges_end;
            boost::tie(edges, edges_end) = boost::in_edges(get_vertex(table), g);
            BUG_CHECK(edges != edges_end, "Table flow graph has more than one source node");
            for (; edges != edges_end; ++edges) {
                auto src = boost::source(*edges, g);
                const IR::MAU::Table* parent = get_vertex(src);
                TableSet parentDominators = dominators.at(parent);
                TableSet intersection;
                std::set_intersection(recomputed.begin(), recomputed.end(),
                                      parentDominators.begin(), parentDominators.end(),
                                      std::inserter(intersection, intersection.begin()));

                recomputed = std::move(intersection);
            }

            // Add the current table itself to the recomputed set.
            recomputed.insert(table);

            if (recomputed != dominators.at(table)) {
                // Save the recomputed set and add the current table's successors to the set of
                // tables whose dominator sets need to be recomputed.
                dominators[table] = std::move(recomputed);

                boost::tie(out_edges, out_edges_end) = boost::out_edges(get_vertex(table), g);
                for (; out_edges != out_edges_end; ++out_edges) {
                    auto target = boost::target(*out_edges, g);
                    toRecompute.insert(get_vertex(target));
                }
            }
        }

        // Remove the null table from the dominator set for the sink.
        dominators[nullptr].erase(nullptr);
    }

    return dominators->at(table);
}

bool FlowGraph::is_always_reached(const IR::MAU::Table* table) const {
    // Check that the table dominates the graph's sink node.
    return get_dominators(nullptr).count(table);
}

Visitor::profile_t FindFlowGraph::init_apply(const IR::Node* node) {
    auto rv = Inspector::init_apply(node);
    fg.clear();
    fg.add_sink_vertex();
    return rv;
}

bool FindFlowGraph::preorder(const IR::MAU::TableSeq* table_seq) {
    if (table_seq->tables.size() < 2) {
        return Inspector::preorder(table_seq);
    }

    // Override the behaviour for visiting table sequences so that we accurately track next_table.

    const auto* saved_next_table = next_table;

    bool first_iter = true;
    const IR::MAU::Table* cur_table = nullptr;
    for (const auto* next_table : table_seq->tables) {
        if (!first_iter) {
            // Visit cur_table with the new next_table.
            this->next_table = next_table;
            apply_visitor(cur_table);
        }

        first_iter = false;
        cur_table = next_table;
    }

    // Restore the saved next_table and visit the last table in the sequence.
    this->next_table = saved_next_table;
    apply_visitor(cur_table);

    return false;
}

std::pair<bool, cstring> FindFlowGraph::next_incomplete(const IR::MAU::Table *t) {
    // TODO: Handle $try_next_stage
    if (t->next.count("$hit") && t->next.count("$miss"))
        return std::make_pair(false, "");

    if (t->next.count("$hit"))
        // Miss falls through to next_table.
        return std::make_pair(true, "$miss");

    if (t->next.count("$miss"))
        // Hit falls through to next_table.
        return std::make_pair(true, "$hit");

    if (t->next.count("$true") && t->next.count("$false"))
        return std::make_pair(false, "");

    if (t->next.count("$true"))
        // "false" case falls through to next_table.
        return std::make_pair(true, "$false");

    if (t->next.count("$false"))
        // "true" case falls through to next_table.
        return std::make_pair(true, "$true");

    if (t->next.count("$default"))
        return std::make_pair(false, "");

    if (t->next.size() == 0)
        return std::make_pair(true, "$default");

    // See if we have a next-table entry for every action. If not, next_table can be executed after
    // the given table.
    for (auto kv : t->actions) {
        if (!t->next.count(kv.first)) {
            return std::make_pair(true, "$hit");
        }
    }

    return std::make_pair(false, "");
}

bool FindFlowGraph::preorder(const IR::MAU::Table *t) {
    // Add edges for next-table entries.
    for (auto& next_entry : t->next) {
        auto& action_name = next_entry.first;
        auto& next_table_seq = next_entry.second;

        const IR::MAU::Table *dst;
        if (next_table_seq->tables.size() > 0) {
            dst = next_table_seq->tables[0];
        } else {
            // This will sometimes be null, which will cause an edge to be added to v_sink
            dst = next_table;
        }
        auto dst_name = dst ? dst->name : "SINK";
        LOG1("Parent : " << t->name << " --> " << action_name << " --> " << dst_name);
        fg.add_edge(t, dst, action_name);
    }

    // Add edge for t -> next_table, if needed.
    LOG3("Table: " << t->name << " Next: " <<
        (next_table ? next_table->name : "<null>"));
    auto n = next_incomplete(t);
    LOG3("next - " << n.first << ":" << n.second);
    if (n.first) {
        auto dst_name = next_table ? next_table->name : "SINK";
        LOG1("Parent : " << t->name << " --> " << n.second << " --> " << dst_name);
        // This will sometimes be null, which will cause an edge to be added to v_sink
        fg.add_edge(t, next_table, n.second);
    }
    return true;
}

void FindFlowGraph::end_apply() {
    // Find the source node (i.e., the node with no incoming edges), and make sure there is only
    // one. As we do this, also populate tableToVertexIndex.
    typename FlowGraph::Graph::vertex_iterator v, v_end;
    bool source_found = false;
    for (boost::tie(v, v_end) = boost::vertices(fg.g); v != v_end; ++v) {
        fg.tableToVertexIndex[fg.get_vertex(*v)] = *v;

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

    // Compute reachability with Floyd-Warshall. Absent cycles, do not consider nodes to be
    // self-reachable.
    FlowGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(fg.g); edges != edges_end; ++edges) {
        auto src = boost::source(*edges, fg.g);
        auto dst = boost::target(*edges, fg.g);

        fg.reachableNodes[src].setbit(dst);
    }
    typename FlowGraph::Graph::vertex_iterator mid, mid_end;
    for (boost::tie(mid, mid_end) = boost::vertices(fg.g); mid != mid_end; ++mid) {
        // Ignore the sink node.
        if (*mid == fg.v_sink) continue;

        typename FlowGraph::Graph::vertex_iterator src, src_end;
        for (boost::tie(src, src_end) = boost::vertices(fg.g); src != src_end; ++src) {
            // Ignore the sink node.
            if (*src == fg.v_sink) continue;

            // If we can't reach mid from src, don't bother going through dsts.
            if (!fg.reachableNodes[*src].getbit(*mid)) continue;

            // This is a vectorized form of an inner loop that goes through all dsts and sets
            //
            //   fg.reachableNodes[src][dst] |=
            //     fg.reachableNodes[src][mid] & fg.reachableNodes[mid][dst]
            //
            // while taking advantage of the fact that we know that
            //
            //   fg.reachableNodes[src][mid] = 1
            fg.reachableNodes[*src] |= fg.reachableNodes[*mid];
        }
    }
}

Visitor::profile_t FindFlowGraphs::init_apply(const IR::Node* root) {
    // Clear the flow graphs every time the visitor is applied.
    auto result = Inspector::init_apply(root);
    flow_graphs.clear();
    return result;
}

bool FindFlowGraphs::preorder(const IR::MAU::TableSeq* thread) {
    // Each top-level TableSeq should represent the whole MAU pipeline for a single gress. Build
    // the control-flow graph for that.
    if (!thread->empty()) {
        auto gress = thread->front()->gress;
        thread->apply(FindFlowGraph(flow_graphs[gress]));
    }

    // Prune the visitor.
    return false;
}
