#ifndef EXTENSIONS_BF_P4C_PARDE_PARSER_INFO_H_
#define EXTENSIONS_BF_P4C_PARDE_PARSER_INFO_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/copy.hpp>
#include <boost/graph/topological_sort.hpp>
#include <boost/graph/graphviz.hpp>

#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/parde/parde_visitor.h"

class DirectedGraph {
    typedef boost::adjacency_list<boost::listS,
                                  boost::vecS,
                                  boost::directedS> Graph;

 public:
    DirectedGraph() {}

    DirectedGraph(const DirectedGraph& other) {
        boost::copy_graph(other._graph, _graph);
    }

    ~DirectedGraph() {}

    int add_vertex() {
        int id = boost::add_vertex(_graph);
        return id;
    }

    void add_edge(int src, int dst) {
        boost::add_edge(src, dst, _graph);
    }

    std::vector<int> topological_sort() const {
        std::vector<int> result;
        boost::topological_sort(_graph, std::back_inserter(result));
        std::reverse(result.begin(), result.end());
        return result;
    }

    void print_stats() const {
        std::cout << "num vertices: " << num_vertices(_graph) << std::endl;
        std::cout << "num edges: " << num_edges(_graph) << std::endl;
        boost::write_graphviz(std::cout, _graph);
    }

 private:
    Graph _graph;
};

template <class State>
struct ParserStateMap : public std::map<const State*, std::set<const State*>> { };

template <class Parser, class State, class Transition>
class ParserGraphImpl : public DirectedGraph {
 public:
    template <class P, class S, class T>
    friend class CollectParserInfoImpl;

    explicit ParserGraphImpl(const Parser* parser) : root(parser->start) {}

    const State* const root;

    const std::set<const State*>& states() const { return _states; }

    const ParserStateMap<State>& successors() const { return _succs; }

    const ParserStateMap<State>& predecessors() const { return _preds; }

    const std::map<const State*,
                   std::set<const Transition*>>& to_pipe() const { return _to_pipe; }

    std::set<const Transition*>
    transitions(const State* src, const State* dst) const {
        if (_transitions.count({src, dst}))
            return _transitions.at({src, dst});

        return {};
    }

    std::set<const Transition*> to_pipe(const State* src) const {
        if (_to_pipe.count(src))
            return _to_pipe.at(src);

        return {};
    }

    std::map<std::pair<const State*, cstring>, std::set<const Transition*>> loopbacks() const {
        return _loopbacks;
    }

    const State* get_state(cstring name) const {
        for (auto s : states()) {
            if (name == s->name)
                return s;
        }

        return nullptr;
    }

 private:
    /// Memoization table.
    mutable std::map<const State*, std::map<const State*, bool>> is_ancestor_;

 public:
    /// Is "src" an ancestor of "dst"?
    bool is_ancestor(const State* src, const State* dst) const {
        if (src == dst)
            return false;

        if (!predecessors().count(dst))
            return false;

        if (predecessors().at(dst).count(src))
            return true;

        if (is_ancestor_.count(src) && is_ancestor_.at(src).count(dst))
            return is_ancestor_.at(src).at(dst);

        /// DANGER -- this assumes parser graph is a unrolled DAG
        for (auto p : predecessors().at(dst))
            if (is_ancestor(src, p)) {
                is_ancestor_[dst][src] = false;
                return is_ancestor_[src][dst] = true;
            }

        return is_ancestor_[src][dst] = false;
    }

    bool is_descendant(const State* src, const State* dst) const {
        return is_ancestor(dst, src);
    }

    bool is_loop_reachable(const State* src, const State* dst) const {
        for (auto &kv : _loopbacks) {
            if (kv.first.first == src) {
                auto loop_state = get_state(kv.first.second);
                if (loop_state == dst || is_ancestor(loop_state, dst))
                    return true;
            }
        }

        return false;
    }

    /// Determines whether @arg src and @arg dst are mutually exclusive states on all paths through
    /// the parser graph.
    bool is_mutex(const State* src, const State* dst) const {
        return src != dst &&
               !is_ancestor(src, dst) &&
               !is_ancestor(dst, src) &&
               !is_loop_reachable(src, dst) &&
               !is_loop_reachable(dst, src);
    }

    std::set<const State*>
    get_all_descendants(const State* src) const {
        std::set<const State*> rv;
        get_all_descendants_impl(src, rv);
        return rv;
    }

    std::vector<const State*> topological_sort() const {
        std::vector<int> result = DirectedGraph::topological_sort();
        std::vector<const State*> mapped_result;
        for (auto id : result)
            mapped_result.push_back(get_state(id));
        return mapped_result;
    }

    // longest path from src to end of parser
    std::vector<const State*> longest_path(const State* src) const {
        std::map<const State*, std::vector<const State*>> path_map;
        return longest_path_impl(src, path_map);
    }

    const IR::BFN::ParserState* get_src(const IR::BFN::Transition* t) const {
        for (auto& kv : _transitions) {
            if (kv.second.count(t))
                return kv.first.first;
        }
        return nullptr;
    }

 private:
    std::vector<const State*> longest_path_impl(const State* src,
            std::map<const State*, std::vector<const State*>>& path_map) const {
        if (path_map.count(src))
            return path_map.at(src);

        const State* longest_succ = nullptr;
        std::vector<const State*> longest_succ_path;

        if (successors().count(src)) {
            for (auto succ : successors().at(src)) {
                auto succ_path = longest_path_impl(succ, path_map);

                if (!longest_succ || succ_path.size() > longest_succ_path.size()) {
                    longest_succ_path = succ_path;
                    longest_succ = succ;
                }
            }
        }

        longest_succ_path.insert(longest_succ_path.begin(), src);

        path_map[src] = longest_succ_path;

        return longest_succ_path;
    }

    void get_all_descendants_impl(const State* src,
                                  std::set<const State*>& rv) const {
        if (!successors().count(src))
            return;

        for (auto succ : successors().at(src)) {
            rv.insert(succ);
            get_all_descendants_impl(succ, rv);
        }
    }

    void add_state(const State* s) {
        _states.insert(s);
    }

    void add_transition(const State* state, const Transition* t) {
        add_state(state);

        if (t->next) {
            add_state(t->next);
            _succs[state].insert(t->next);
            _preds[t->next].insert(state);
            _transitions[{state, t->next}].insert(t);
        } else if (t->loop) {
            _loopbacks[{state, t->loop}].insert(t);
        } else {
            _to_pipe[state].insert(t);
        }
    }

    void map_to_boost_graph() {
        for (auto s : _states) {
            int id = DirectedGraph::add_vertex();
            _state_to_id[s] = id;
            _id_to_state[id] = s;
        }

        for (auto t : _succs)
            for (auto dst : t.second)
                DirectedGraph::add_edge(get_id(t.first), get_id(dst));
    }

    int get_id(const State* s) {
        if (_state_to_id.count(s) == 0)
            add_state(s);
        return _state_to_id.at(s);
    }

    const State* get_state(int id) const {
        return _id_to_state.at(id);
    }

    std::set<const State*> _states;

    ParserStateMap<State> _succs, _preds;

    std::map<std::pair<const State*, const State*>,
             std::set<const Transition*>> _transitions;

    std::map<std::pair<const State*, cstring>,
             std::set<const Transition*>> _loopbacks;

    std::map<const State*,
             std::set<const Transition*>> _to_pipe;

    std::map<const State*, int> _state_to_id;
    std::map<int, const State*> _id_to_state;
};

namespace IR {
namespace BFN {

using ParserGraph = ParserGraphImpl<IR::BFN::Parser,
                                    IR::BFN::ParserState,
                                    IR::BFN::Transition>;

using LoweredParserGraph = ParserGraphImpl<IR::BFN::LoweredParser,
                                           IR::BFN::LoweredParserState,
                                           IR::BFN::LoweredParserMatch>;
}  // namespace BFN
}  // namespace IR

template <class Parser, class State, class Transition>
class CollectParserInfoImpl : public PardeInspector {
    using GraphType = ParserGraphImpl<Parser, State, Transition>;

 public:
    const std::map<const Parser*, GraphType*>& graphs() const { return _graphs; }
    const GraphType& graph(const Parser* p) const { return *(_graphs.at(p)); }

    const Parser* parser(const State* state) const {
        return _state_to_parser.at(state);
    }

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);

        clear_cache();
        _graphs.clear();
        _state_to_parser.clear();

        return rv;
    }

    bool preorder(const Parser* parser) override {
        _graphs[parser] = new GraphType(parser);
        revisit_visited();
        return true;
    }

    bool preorder(const State* state) override {
        auto parser = findContext<Parser>();
        _state_to_parser[state] = parser;

        auto g = _graphs.at(parser);

        g->add_state(state);

        for (auto t : state->transitions)
            g->add_transition(state, t);

        return true;
    }

    /// Clears internal memoization state.
    void clear_cache() {
        all_shift_amounts_.clear();
    }

    // Memoization table. Only contains results for forward paths in the graph.
    mutable std::map<const State*,
                     std::map<const State*, const std::set<int>*>> all_shift_amounts_;

 public:
    /// @return all possible shift amounts, in bits, for all paths from @arg src to @arg dst. If
    ///   the two states are the same, then a singleton 0 is returned. If the states are mutually
    ///   exclusive, an empty set is returned. If @arg src is an ancestor of @arg dst, then the
    ///   shift amounts will be positive; otherwise, if @arg src is a descendant of @arg dst, then
    ///   the shift amounts will be negative.
    //
    // DANGER: This method assumes the parser graph is a DAG.
    const std::set<int>* get_all_shift_amounts(const State* src,
                                               const State* dst) const {
        bool reverse_path = graphs().at(parser(src))->is_ancestor(dst, src);
        if (reverse_path) std::swap(src, dst);

        auto result = get_all_forward_path_shift_amounts(src, dst);

        if (reverse_path) {
            // Need to negate result.
            auto negated = new std::set<int>();
            for (auto shift : *result) negated->insert(-shift);
            result = negated;
        }

        return result;
    }

 private:
    const std::set<int>* get_all_forward_path_shift_amounts(const State* src,
                                                            const State* dst) const {
        if (src == dst) return new std::set<int>({0});

        if (all_shift_amounts_.count(src) && all_shift_amounts_.at(src).count(dst))
            return all_shift_amounts_.at(src).at(dst);

        auto graph = graphs().at(parser(src));
        auto result = new std::set<int>();

        if (graph->is_mutex(src, dst)) {
            return all_shift_amounts_[src][dst] = all_shift_amounts_[dst][src] = result;
        }

        if (!graph->is_ancestor(src, dst)) {
            return all_shift_amounts_[src][dst] = result;
        }

        // Recurse with the successors of the source.
        BUG_CHECK(graph->successors().count(src),
                  "State %s has a descendant %s, but no successors", src->name, dst->name);
        for (auto succ : graph->successors().at(src)) {
            auto amounts = get_all_forward_path_shift_amounts(succ, dst);
            if (!amounts->size()) continue;

            auto transitions = graph->transitions(src, succ);
            BUG_CHECK(!transitions.empty(),
                      "Missing parser transition from %s to %s", src->name, succ->name);

            auto t = *(transitions.begin());

            for (auto amount : *amounts)
                result->insert(amount + t->shift * 8);
        }

        return all_shift_amounts_[src][dst] = result;
    }

    void end_apply() override {
        clear_cache();
        for (auto g : _graphs)
            g.second->map_to_boost_graph();
    }

    std::map<const Parser*, GraphType*> _graphs;
    std::map<const State*, const Parser*> _state_to_parser;
};

using CollectParserInfo = CollectParserInfoImpl<IR::BFN::Parser,
                                                IR::BFN::ParserState,
                                                IR::BFN::Transition>;

using CollectLoweredParserInfo = CollectParserInfoImpl<IR::BFN::LoweredParser,
                                                       IR::BFN::LoweredParserState,
                                                       IR::BFN::LoweredParserMatch>;

#endif  /* EXTENSIONS_BF_P4C_PARDE_PARSER_INFO_H_ */
