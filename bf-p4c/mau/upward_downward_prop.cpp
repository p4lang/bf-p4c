#include "bf-p4c/mau/upward_downward_prop.h"
#include <algorithm>
#include <numeric>
#include <sstream>
#include <queue>
#include "ir/ir.h"
#include "lib/log.h"

std::ostream &operator<<(std::ostream &out,
    const UpwardDownwardPropagation::PlaceScore &score) {
    if (DBPrint::dbgetflags(out) & DBPrint::Brief) {
        out << score.deps_stages_control << "/" << score.deps_stages << "/" << score.total_deps;
    } else {
        out << "Score: [DSC=" << score.deps_stages_control << ", DS=" << score.deps_stages
            << ", TD=" << score.total_deps << ", IS_ZERO=" << score.is_zero << "]"; }
    return out;
}

void UpwardDownwardPropagation::build_vertex_local_maps() {
    const auto& dep_graph = dg.g;
    typename DependencyGraph::Graph::vertex_iterator v, v_end;
    for (boost::tie(v, v_end) = boost::vertices(dep_graph); v != v_end; v++) {
        table_vertex_map[dg.get_vertex(*v)] = *v;
        local_score[dg.get_vertex(*v)] = calculate_local_score(dg.get_vertex(*v));
    }
}

/* Starting at the least dependent nodes in the dependency graph,
walk up the DAG accumulating the score of each child node
within each parent node. Combined score (given by PlaceScore::combine_scores)
will be the max dependency length of the current node and all its children.
upward_prop contains the score for each table after running once.
upward_prop_unplaced depends on what tables have already been placed
by table placement and must be re-computed for each attempted placement.
*/
void UpwardDownwardPropagation::build_upward_prop_map() {
    auto& dep_graph = dg.g;
    for (int i = int(vertex_rst.size()) - 1; i >= 0; i--) {
        for (const auto& vertex : vertex_rst[i]) {
            UpwardDownwardPropagation::PlaceScore score = local_score[dg.get_vertex(vertex)];
            UpwardDownwardPropagation::PlaceScore score_unplaced;
            if (placed_tables.count(dg.get_vertex(vertex))) {
                score_unplaced = UpwardDownwardPropagation::PlaceScore::score_zero();
            } else {
                score_unplaced = local_score[dg.get_vertex(vertex)];
            }
            auto next_edges = boost::out_edges(vertex, dep_graph);
            for (auto edge = next_edges.first; edge != next_edges.second; edge++) {
                if (dep_graph[*edge] == DependencyGraph::REDUCTION_OR_READ ||
                    dep_graph[*edge] == DependencyGraph::REDUCTION_OR_OUTPUT) {
                    continue;
                }
                const auto& next_vertex = boost::target(*edge, dep_graph);
                const IR::MAU::Table* next_vertex_table = dg.get_vertex(next_vertex);
                score = UpwardDownwardPropagation::PlaceScore::combine_scores(
                    score, upward_prop[next_vertex_table]);
                score_unplaced = UpwardDownwardPropagation::PlaceScore::combine_scores(
                    score_unplaced, upward_prop_unplaced[next_vertex_table]);
            }
            upward_prop[dg.get_vertex(vertex)] = score;
            upward_prop_unplaced[dg.get_vertex(vertex)] = score_unplaced;
        }
    }
}

/* Called by table placement after building the dependency graph
and vertex_rst (a topologically sorted representation of the dependence graph
nodes that accounts for both control and data dependencies)
*/
void UpwardDownwardPropagation::calculate_scores(
    const std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>& rst) {
    vertex_rst = rst;
    if (LOGGING(3)) {
        LOG3("UpDownProp vertex_rst:");
        int idx = 0;
        for (auto &s : vertex_rst) {
            std::stringstream tmp;
            const char *sep = "";
            for (auto v : s) {
                tmp << sep << dg.get_vertex(v)->name;
                sep = ", "; }
            LOG3("    " << idx++ << " {" << tmp.str() << "}"); } }
    build_vertex_local_maps();
    build_upward_prop_map();
    if (LOGGING(3)) {
        for (auto &lscore : local_score) {
            auto *tbl = lscore.first;
            LOG3(DBPrint::Brief << "  " << tbl->name << ": local " << lscore.second <<
                 " up " << upward_prop.at(tbl)); } }
}

/* Called by is_better to recalculate the placement dependent upward propagation info */
void UpwardDownwardPropagation::update_placed_tables(
    ordered_set<const IR::MAU::Table*>& placed_tables) {
    this->placed_tables = placed_tables;
    build_upward_prop_map();
}

/* Packs all heuristics that can be tied to a table into a single PlaceScore
   object. Does not include stage, or needs_more heuristics,
   since those are associated with Placed objects, not tables, and are
   either guided by user pragmas or by table placement, not by program structure
*/
UpwardDownwardPropagation::PlaceScore UpwardDownwardPropagation::calculate_local_score(
    const IR::MAU::Table *t) {
    PlaceScore score;
    score.deps_stages_control = dg.dependence_tail_size_control(t);
    score.deps_stages = dg.dependence_tail_size(t);
    int provided_stage = t->get_provided_stage();
    if (provided_stage >= 0) {
        // If there's a stage pragma, treat the table as having at least as many
        // stage dependencies as there are stages after the @pragma stage.
        int after_stages = Device::numStages() - provided_stage;
        if (score.deps_stages_control < after_stages)
            score.deps_stages_control = after_stages;
        if (score.deps_stages < after_stages)
            score.deps_stages = after_stages; }
    score.total_deps = dg.happens_before_dependences(t).size();
    score.tables.insert(t);
    score.is_zero = false;
    return score;
}

/* Public-facing helper to get score of a single table. */
std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
UpwardDownwardPropagation::get_local_score(const IR::MAU::Table *a, const IR::MAU::Table *b) {
    UpwardDownwardPropagation::PlaceScore& a_score = local_score[a];
    UpwardDownwardPropagation::PlaceScore& b_score = local_score[b];
    return std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
                                                                                (a_score, b_score);
}

/* Public-facing helper to get upward propagated score, covering a table and its children
   while including previous placement decisions. */
std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
UpwardDownwardPropagation::get_upward_prop_unplaced_score(const IR::MAU::Table *a,
                                                          const IR::MAU::Table *b) {
    UpwardDownwardPropagation::PlaceScore& a_score = upward_prop_unplaced[a];
    UpwardDownwardPropagation::PlaceScore& b_score = upward_prop_unplaced[b];
    return std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
                                                                                (a_score, b_score);
}

/* Public-facing helper to get downward propagated score, covering a table and its children
   while including previous placement decisions. */
std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
UpwardDownwardPropagation::get_downward_prop_unplaced_score(const IR::MAU::Table *a,
                                                            const IR::MAU::Table *b) {
    return get_downward_prop_score(a, b, true);
}

/* Public-facing helper to get upward propagated score, covering a table and its children
   but ignoring previous placement decisions. */
std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
UpwardDownwardPropagation::get_upward_prop_score(const IR::MAU::Table *a,
                                                 const IR::MAU::Table *b) {
    UpwardDownwardPropagation::PlaceScore& a_score = upward_prop[a];
    UpwardDownwardPropagation::PlaceScore& b_score = upward_prop[b];
    return std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
                                                                                (a_score, b_score);
}

/* Given two tables A and B, calculate the best possible heuristics for each of their
   corresponding subgraphs. The subgraph for A includes A, all its children, and all of
   its parents up to (but not including) the dominator node for A and B. The subgraph for
   B similarly includes B, all its children, and all its parents up to (but not including)
   the dominator. The effect is that A and B each receive a score corresponding to the
   longest dependence chain they are most closely associated with, regardless of whether
   or not that chain falls below or in sequence with the original node in the program's
   control flow. This function returns scores for both tables that each depend on both
   tables -- so table A might give a different score when compared with table B versus
   table C, for example.
*/
std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
UpwardDownwardPropagation::get_downward_prop_score(const IR::MAU::Table *a,
                                                   const IR::MAU::Table *b, bool use_unplaced) {
    auto& a_descriptor = table_vertex_map[a];
    auto& b_descriptor = table_vertex_map[b];
    auto& dep_graph = dg.g;
    std::queue<DependencyGraph::Graph::vertex_descriptor> queue;
    ordered_set<DependencyGraph::Graph::vertex_descriptor> a_visited, b_visited, common_visited;

    // Walk up the DAG from A, building a set of all visited tables.
    queue.push(a_descriptor);
    while (!queue.empty()) {
        const auto& vertex = queue.front();
        queue.pop();
        if (a_visited.count(vertex))
            continue;
        a_visited.insert(vertex);
        auto in_edges = boost::in_edges(vertex, dep_graph);
        for (auto e = in_edges.first; e != in_edges.second; ++e) {
            if (dep_graph[*e] == DependencyGraph::REDUCTION_OR_READ ||
                dep_graph[*e] == DependencyGraph::REDUCTION_OR_OUTPUT) {
                continue;
            }
            const auto& src_vertex = boost::source(*e, dep_graph);
            queue.push(src_vertex);
        }
    }

    // Walk up the DAG from B, building a set of all visited tables.
    queue.push(b_descriptor);
    while (!queue.empty()) {
        const auto& vertex = queue.front();
        queue.pop();
        if (b_visited.count(vertex))
            continue;
        b_visited.insert(vertex);
        auto in_edges = boost::in_edges(vertex, dep_graph);
        for (auto e = in_edges.first; e != in_edges.second; ++e) {
            if (dep_graph[*e] == DependencyGraph::REDUCTION_OR_READ ||
                dep_graph[*e] == DependencyGraph::REDUCTION_OR_OUTPUT) {
                continue;
            }
            const auto& src_vertex = boost::source(*e, dep_graph);
            queue.push(src_vertex);
        }
    }

    // Remove any tables that are common ancestors of both A and B
    // (from the immediate dominator on up)
    common_visited = a_visited;
    common_visited &= b_visited;
    a_visited -= common_visited;
    b_visited -= common_visited;

    // Gather the results of combining each of the scores for A and B
    UpwardDownwardPropagation::PlaceScore a_score =
        UpwardDownwardPropagation::PlaceScore::score_zero();
    for (const auto& vertex : a_visited) {
        UpwardDownwardPropagation::PlaceScore score_to_use;
        if (use_unplaced)
            score_to_use = upward_prop_unplaced[dg.get_vertex(vertex)];
        else
            score_to_use = upward_prop[dg.get_vertex(vertex)];
        a_score = UpwardDownwardPropagation::PlaceScore::combine_scores(a_score, score_to_use);
    }

    UpwardDownwardPropagation::PlaceScore b_score =
        UpwardDownwardPropagation::PlaceScore::score_zero();
    for (const auto& vertex : b_visited) {
        UpwardDownwardPropagation::PlaceScore score_to_use;
        if (use_unplaced)
            score_to_use = upward_prop_unplaced[dg.get_vertex(vertex)];
        else
            score_to_use = upward_prop[dg.get_vertex(vertex)];
        b_score = UpwardDownwardPropagation::PlaceScore::combine_scores(b_score, score_to_use);
    }

    return std::pair<UpwardDownwardPropagation::PlaceScore, UpwardDownwardPropagation::PlaceScore>
                                                                                (a_score, b_score);
}
