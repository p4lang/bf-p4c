#include "gtest/gtest.h"
#include "bf-p4c/lib/vertex_weighted_coloring.h"

#include <vector>
#include <random>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/erdos_renyi_generator.hpp>
#include <boost/random/linear_congruential.hpp>

namespace Test {

class VertexWeightedColoringTest : public ::testing::Test {};

namespace {

typedef boost::adjacency_list<boost::listS, boost::vecS, boost::undirectedS> Graph;
typedef boost::sorted_erdos_renyi_iterator<boost::minstd_rand, Graph> ERGen;

std::vector<int> gen_n_weights(int n,int v_begin, int v_end, unsigned int seed) {
    std::vector<int> weights(n);
    std::mt19937 gen(seed);
    std::uniform_int_distribution<> dis(v_begin, v_end);
    for (auto & v : weights) {
        v = dis(gen); }
    return weights;
}

VertexWeightedGraph<Graph>
generate_random_graph(int n_vertices, double edge_ratio,
                      std::pair<int,int> weight_range, unsigned int seed)
{
    auto weights = gen_n_weights(n_vertices, weight_range.first, weight_range.second, seed);
    boost::minstd_rand gen;
    gen.seed(seed);
    Graph g(ERGen(gen, n_vertices, edge_ratio), ERGen(), n_vertices);
    return VertexWeightedGraph<Graph>(g, weights, n_vertices);
}

// Forall edges, if exists an e(vi, vj) that color(vi) == color(vj), return false
// otherwise, return true, i.e. it is a valid coloring.
template<class Graph>
bool is_correctly_colored(const VertexWeightedGraph<Graph>& graph) {
    using GraphTraits       = boost::graph_traits<Graph>;
    using VertexItr         = typename GraphTraits::vertex_iterator;
    using VertexAdjacentItr = typename GraphTraits::adjacency_iterator;

    VertexItr vi, viend;
    for (boost::tie(vi, viend) = vertices(graph.graph); vi != viend; ++vi) {
        VertexAdjacentItr vj, vjend;
        for (boost::tie(vj, vjend) = adjacent_vertices(*vi, graph.graph); vj != vjend; ++vj) {
            if (*vi != *vj && get(graph.colors, *vi) == get(graph.colors, *vj)) {
                return false; } } }

    return true;
}

}  // namespace

TEST_F(VertexWeightedColoringTest, Correctness) {
    // Randomly generate 5 graphs to check the correctness
    // Each graph has 400 vertices and 0.7 edge genertate ratio.
    // Weights ranges from 1 to 256, inclusive.
    const int n_times = 5;
    unsigned int seed = 111317;
    for (int i = 0; i < n_times; i++) {
        SCOPED_TRACE(i);
        auto g = generate_random_graph(400, 0.7, std::make_pair(1, 256), seed);
        WeightedGraphColoringSolver<decltype(g.graph), decltype(g.weights),
                                    decltype(g.colors)> solver1(g);
        solver1.run();
        EXPECT_EQ(is_correctly_colored(g), true) << " failed in " << i << " time, seed: " << seed;
    }
}

}  // namespace Test

