#ifndef BF_P4C_MAU_UPWARD_DOWNWARD_PROP_H_
#define BF_P4C_MAU_UPWARD_DOWNWARD_PROP_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <map>
#include <set>
#include <vector>
#include <iostream>
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/mau_visitor.h"

class UpwardDownwardPropagation {
 public:
    enum {
        DEPS_STAGES_CONTROL_ANTI,  // Length of the dependence chain from this node onwards
        // (i.e. ) this node and all its data-dependent successors. Propagates through
        // control and anti dependencies, although they do not increase the chain length
        // themselves.
        DEPS_STAGES,  // Same as DEPS_STAGES_CONTROL, but does not propagate through control
        // dependencies.
        TOTAL_DEPS,  // Total dependent tables following this table, not necessarily
        // all in a chain.
        NUM_HEURISTICS
    } heuristic_t;
    enum {
        DOWNWARD,  // Propagation pass that transfers dependencies to all related
        // nodes in the same subgraph beneath (but not including) the dominator
        // between the two compared nodes. (See cpp implementation for details.)
        UPWARD,  // Propagation pass that pull in the dependencies from all successor
        // nodes into the current node, drawing the dependencies up through the graph
        // into the current node.
        LOCAL,  // Local dependencies from the current node only.
        NUM_PROP_TYPES
    } prop_t;
    struct PlaceScore {
        int deps_stages_control_anti, deps_stages, total_deps;
        ordered_set<const IR::MAU::Table*> tables;
        bool is_zero;
        static PlaceScore combine_scores(PlaceScore& a, PlaceScore& b) {
            UpwardDownwardPropagation::PlaceScore new_score;
            if (a.is_zero && b.is_zero) {
                new_score.is_zero = true;
            } else if (a.is_zero) {
                new_score = b;
            } else if (b.is_zero) {
                new_score = a;
            } else {
                new_score.deps_stages_control_anti = std::max(a.deps_stages_control_anti,
                                                              b.deps_stages_control_anti);
                new_score.deps_stages = std::max(a.deps_stages, b.deps_stages);
                // Table placement prioritizes tables with the fewest total dependencies
                new_score.total_deps = std::min(a.total_deps, b.total_deps);
                new_score.tables = a.tables;
                new_score.tables |= b.tables;
                new_score.is_zero = false;
            }
            return new_score;
        }
        static PlaceScore score_zero() {
            PlaceScore zero;
            zero.deps_stages_control_anti = 0;
            zero.deps_stages = 0;
            zero.total_deps = 0;
            zero.is_zero = true;
            return zero;
        }
    };
    friend std::ostream &operator<<(std::ostream &, const PlaceScore&);

 private:
    const DependencyGraph& dg;
    PlaceScore calculate_local_score(const IR::MAU::Table *t);
    void build_vertex_local_maps();
    void build_upward_prop_map();


    ordered_map<const IR::MAU::Table*, PlaceScore> local_score;
    ordered_map<const IR::MAU::Table*, PlaceScore> upward_prop;
    ordered_map<const IR::MAU::Table*, PlaceScore> upward_prop_unplaced;
    ordered_set<const IR::MAU::Table*> placed_tables;
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> vertex_rst;
    ordered_map<const IR::MAU::Table*, DependencyGraph::Graph::vertex_descriptor> table_vertex_map;

 public:
    explicit UpwardDownwardPropagation(const DependencyGraph &out) : dg(out) {
        calculate_scores(dg.vertex_rst);
    }
    void calculate_scores(
        const std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>& rst);
    std::pair<PlaceScore, PlaceScore> get_local_score(const IR::MAU::Table *a,
                                                      const IR::MAU::Table *b);
    std::pair<PlaceScore, PlaceScore> get_upward_prop_score(const IR::MAU::Table *a,
                                                            const IR::MAU::Table *b);
    std::pair<PlaceScore, PlaceScore> get_downward_prop_score(const IR::MAU::Table *a,
                                                              const IR::MAU::Table *b,
                                                              bool use_unplaced = false);

    std::pair<PlaceScore, PlaceScore> get_upward_prop_unplaced_score(const IR::MAU::Table *a,
                                                                     const IR::MAU::Table *b);
    std::pair<PlaceScore, PlaceScore> get_downward_prop_unplaced_score(const IR::MAU::Table *a,
                                                                       const IR::MAU::Table *b);
    void update_placed_tables(ordered_set<const IR::MAU::Table*>& placed_tables);
};




#endif /* BF_P4C_MAU_UPWARD_DOWNWARD_PROP_H_ */
