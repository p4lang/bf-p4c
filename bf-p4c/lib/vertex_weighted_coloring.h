#ifndef EXTENSIONS_BF_P4C_LIB_VERTEX_WEIGHTED_COLORING_H_
#define EXTENSIONS_BF_P4C_LIB_VERTEX_WEIGHTED_COLORING_H_

#include <boost/graph/graph_concepts.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/optional.hpp>
#include <boost/property_map/property_map.hpp>

#include <algorithm>
#include <functional>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

/** A struct that holds a Graph-type graph, and two property_map.
  *
  * Property Maps:
  * colors: The color of the vertex.
  * weights: The weight of the vertex.
  *
  * Both weight_vec and color_vec are indexed by vertex_id, which is
  * an integer you will get when calling add_vertex(weight) in the graphbuilder.
  *
  */
template<class Graph>
struct VertexWeightedGraph {
    using vertex_index_map =
        typename boost::property_map<Graph, boost::vertex_index_t>::const_type;
    using vertex_int_property_map =
        boost::iterator_property_map<std::vector<int>::iterator, vertex_index_map>;

    Graph graph;
    std::vector<int> weight_vec;
    std::vector<int> color_vec;
    vertex_int_property_map weights;
    vertex_int_property_map colors;
    VertexWeightedGraph(const Graph& graph, const std::vector<int>& wv, int n_vertices)
        : graph(graph), weight_vec(wv), color_vec(n_vertices, 0)
      , weights(weight_vec.begin(), get(boost::vertex_index, graph))
      , colors(color_vec.begin(), get(boost::vertex_index, graph))
    {}
};

/** A graph builder that returns a VertexWeightedGraph<Graph>.
  *
  * Graph: the type of the graph strored,
  *        e.g. adjacency_list<listS, vecS, undirectedS>
  *
  * Usage Example:
  *
  * VertexWeightedGraphBuilder<Graph> graph_builder;
  * int A_id = graph_builder.add_vertex(1);
  * int B_id = graph_builder.add_vertex(2);
  * graph_builder.add_edge(A_id, B_id);
  * auto result = graph_builder.build();
  *
  * This above example will builds this graph:
  *  A(1) <---> B(2)
  *
  */
template<class Graph>
class VertexWeightedGraphBuilder {
    using Edge = std::pair<int, int>;
    using vertex_index_map = typename boost::property_map<Graph, boost::vertex_index_t>::const_type;
    using vertex_int_property_map =
            boost::iterator_property_map<std::vector<int>::iterator, vertex_index_map>;

    BOOST_CONCEPT_ASSERT((boost::MutableBidirectionalGraphConcept<Graph>));

 public:
    VertexWeightedGraphBuilder()
        : n_vertices_(0) {}

    int add_vertex(int weight) {
        weights_.push_back(weight);
        return n_vertices_++;
    }

    void add_edge(int from, int to) { edges_.emplace_back(from, to); }

    VertexWeightedGraph<Graph>
    build() {
        return VertexWeightedGraph<Graph>(Graph(edges_.begin(), edges_.end(), n_vertices_),
                                          weights_,
                                          n_vertices_);
    }

 private:
    int n_vertices_;
    std::vector<int> weights_;
    std::vector<Edge> edges_;
};

/** A function signature of the coloring process when picking the next vertex.
  * to pick the next vertex to color by values(largest first).
  * This function takes (int phi, int weight, int degree)
  * and returns an int, as the weight to decide the next vertex.
  * Definition of parameters:
  * phi: the number of adjacent different color + 1.
  * weight: the weight of the vertex.
  * degree: the degree of the vertex.
  * We can change the order of coloring by providing different weight function.
  * For example:
  * Largest weight vertex first: [](int p,int w,int d){ return w; }
  * Largest degree first:        [](int p,int w,int d){ return d; }
  * weight-phi-production:       [](int p,int w,int d){ return p * w; }
  * When constructing, if not provided, 'weight-phi-production' is used as default.
  */
using VertexPickWeightFunc = std::function<int(int, int, int)>;

/** The algorithm for weighted vertex coloring.
  *
  * The goal of this algorithm is to minimize the sum of the maximum weight
  * of each color. This is the model of field overlay in PHV allocation.
  *
  * Graph: the type of the graph
  *        concept requirements: VertexListGraphConcept and BidirectionalGraphConcept.
  * VertexWeight: the property map of vertex weight, indexed by vertex_index_t
  * Color: the property map of vetex color, indexed by vertex_index_t
  *
  * Usage:
  * 1. Construct a graph and pass it in the constructor.
  * 2. Call run().
  * 3. The color property map will now have colors of each vertex, starting from 0.
  *
  * Self-loops and parallel edges will affect the choice of the first node to color,
  * but the algorithm should still yield a correct result.
  */
template<class Graph, class VertexWeight, class Color>
class WeightedGraphColoringSolver {
 private:
    using GraphTraits       = boost::graph_traits<Graph>;
    using Vertex            = typename GraphTraits::vertex_descriptor;
    using VertexItr         = typename GraphTraits::vertex_iterator;
    using VertexAdjacentItr = typename GraphTraits::adjacency_iterator;
    using VertexSizeType    = typename GraphTraits::vertices_size_type;
    using DegreeSizeType    = typename GraphTraits::degree_size_type;
    using WeightType        = typename boost::property_traits<VertexWeight>::value_type;
    using ColorType         = typename boost::property_traits<Color>::value_type;

    BOOST_CONCEPT_ASSERT((boost::VertexListGraphConcept<Graph>));
    BOOST_CONCEPT_ASSERT((boost::BidirectionalGraphConcept<Graph>));
    BOOST_CONCEPT_ASSERT((boost::concepts::AdjacencyGraph<Graph>));
    BOOST_CONCEPT_ASSERT((boost::ReadWritePropertyMapConcept<Color, Vertex>));
    BOOST_CONCEPT_ASSERT((boost::IntegerConcept<ColorType>));
    BOOST_CONCEPT_ASSERT((boost::ReadablePropertyMapConcept<VertexWeight, Vertex>));

    const Graph& graph_;
    VertexWeight& weights_;
    Color& colors_;
    const VertexSizeType n_vertices_;
    VertexPickWeightFunc calc_pick_weight_;
    std::unordered_set<Vertex> colored_;
    std::unordered_map<Vertex, std::unordered_set<ColorType>> phi_;
    std::vector<int> costs_;
    ColorType max_color_;
    int total_costs_;

    /// Color the @p current node with @p color.
    void do_color(Vertex current, ColorType color) {
        colored_.insert(current);
        put(colors_, current, color);
        costs_[color] = std::max(costs_[color], get(weights_, current));

        // Update phi: insert new color to all current's adjacent vertices' sets.
        VertexAdjacentItr v, vend;
        for (std::tie(v, vend) = adjacent_vertices(current, graph_); v != vend; ++v) {
            phi_[*v].insert(color);}
    }

    /// @prerequisite: graph_ is not a empty graph.
    /// Find the vertex that has maximum degree.
    Vertex find_max_degree_vertex() {
        VertexItr v, vend;
        DegreeSizeType max_degree = (std::numeric_limits<DegreeSizeType>::min)();
        boost::optional<Vertex> result;
        for (std::tie(v, vend) = vertices(graph_); v != vend; ++v) {
            if (!result || degree(*v, graph_) > max_degree) {
                max_degree = degree(*v, graph_);
                result = *v; } }

        return *result;
    }

    /** Pick the best color
      * @p current, the node to find the best possible color.
      * @p maximum_used_color, the largest color used.
      * @return the best color(lowest one in current implementation).
      *
      * Currently we do not choose the color that has closest value with current vertex,
      * because we found that result is better without it in our performance testing.
      * However, we can construct some small test cases that closest-weight-color-picking will
      * yield better result. But in the large cases, where better coloring is really needed,
      * pick the lowest is better than pick the closest-weight.
      */
    int pick_best_color(Vertex current, int maximum_used_color) {
        // length is the maximum_color + 1, as the index is used to as color, which starts from 0.
        std::vector<bool> color_used(maximum_used_color + 1, false);
        VertexAdjacentItr v, vend;
        for (std::tie(v, vend) = adjacent_vertices(current, graph_); v != vend; ++v) {
            if (!colored_.count(*v)) continue;
            color_used[get(colors_, *v)] = true;
        }

        // choose the lowest possible color
        for (ColorType i = 0; i <= maximum_used_color; ++i) {
            if (!color_used[i]) {
                return i; } }

        return maximum_used_color + 1;
    }

    /// pick the next vertex to color based on func(phi(v))
    Vertex pick_next_vertex() {
        int max_val = (std::numeric_limits<int>::min)();
        boost::optional<Vertex> nxt;
        VertexItr v, vend;
        for (std::tie(v, vend) = vertices(graph_); v != vend; ++v) {
            if (colored_.count(*v)) continue;
            // phi(v) is the number of adjacent different color + 1.
            int p = static_cast<int>(phi_[*v].size()) + 1;
            int val = calc_pick_weight_(p, get(weights_, *v), static_cast<int>(degree(*v, graph_)));
            if (!nxt || val > max_val) {
                nxt = *v;
                max_val = val; } }

        return *nxt;
    }

    /// The best heuristic we found in performace test.
    static int default_pick_weight_func(int p, int weight, int) {
        return p * weight;
    }

 public:
    WeightedGraphColoringSolver(const Graph& graph,
                                VertexWeight& weights,
                                Color& colors,
                                boost::optional<VertexPickWeightFunc> f = boost::none)
        : graph_(graph), weights_(weights)
        , colors_(colors), n_vertices_(num_vertices(graph_)) {
        init(f);
    }

    explicit WeightedGraphColoringSolver(VertexWeightedGraph<Graph>& g,
                                         boost::optional<VertexPickWeightFunc> f = boost::none)
        : graph_(g.graph), weights_(g.weights)
        , colors_(g.colors), n_vertices_(num_vertices(graph_)) {
        init(f);
    }

    /// Reset all states.
    void init(boost::optional<VertexPickWeightFunc> f) {
        total_costs_ = 0;
        costs_ = std::vector<int>(n_vertices_, 0);
        if (f) {
            calc_pick_weight_ = f.value();
        } else {
            calc_pick_weight_ = default_pick_weight_func; }

        VertexItr v, vend;
        for (std::tie(v, vend) = vertices(graph_); v != vend; ++v) {
            phi_[*v] = {}; }
    }

    /// Execute the algorithm.
    void run() {
        VertexItr v, vend;
        // Do not run it is an empty graph.
        std::tie(v, vend) = vertices(graph_);
        if (v == vend) {
            return; }

        ColorType maximum_used_color = 0;
        Vertex current = find_max_degree_vertex();

        // Color the first node the color 0.
        do_color(current, maximum_used_color);

        // start coloring
        for (VertexSizeType colored = 1; colored < n_vertices_; ++colored) {
            // Pick next node, O(N)
            current = pick_next_vertex();
            // Color this node with lowest possible color.
            int color_for_current = pick_best_color(current, maximum_used_color);
            do_color(current, color_for_current);
            maximum_used_color = std::max(color_for_current, maximum_used_color); }

        max_color_ = maximum_used_color;
        for (ColorType i = 0; i <= max_color_; ++i) {
            total_costs_ += costs_[i]; }
    }

    ColorType max_color() { return max_color_; }
    int total_cost() { return total_costs_; }
};

#endif  /* EXTENSIONS_BF_P4C_LIB_VERTEX_WEIGHTED_COLORING_H_ */
