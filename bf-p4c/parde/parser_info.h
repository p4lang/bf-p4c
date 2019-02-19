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

template <typename T>
static void merge(std::set<T> &my, const std::set<T> &other) {
    my.insert(other.begin(), other.end());
}

template <typename K, typename V>
static void merge(std::map<K, V> &my, const std::map<K, V> &other) {
    for (auto &kv : other) {
        if (my.count(kv.first) == 0)
            my[kv.first] = kv.second;
        else
            BUG_CHECK(my[kv.first] == kv.second, "cannot merge two map");
    }
}

template <typename T>
static void merge(std::map<T, std::set<T>> &my,
                  const std::map<T, std::set<T>> &other) {
    for (auto t : other) {
        if (my.count(t.first) == 0)
            my[t.first] = t.second;
        else
            merge(my[t.first], t.second);
    }
}

template <class State>
struct ParserStateMap : public std::map<const State*, std::set<const State*>> { };

template <class Parser, class State, class Transition>
struct ParserStateMutex {
    std::set<const State*> _states_encountered;

    ParserStateMap<State> _mutually_inclusive;
    ParserStateMap<State> _mutually_exclusive;

    const ParserStateMap<State>& mutex_state_map() const { return _mutually_exclusive; }

    bool mutex(const State* a, const State* b) const {
        if (_mutually_exclusive.count(a) > 0)
            if (_mutually_exclusive.at(a).count(b) > 0)
                return true;
        return false;
    }

    void merge_with(ParserStateMutex& other) {
        merge(_states_encountered, other._states_encountered);
        merge(_mutually_inclusive, other._mutually_inclusive);
    }
};

/*
static void print(const std::set<const IR::BFN::ParserState*>& ss) {
    for (auto s : ss)
        std::cout << "    " << s->name << std::endl;
}

static void print(const ParserStateMap& psm) {
    for (auto ss : psm) {
        std::cout << ss.first->name << " :" << std::endl;
        print(ss.second); }
    std::cout << std::endl;
}
*/

template <class Parser, class State, class Transition>
class ParserGraphImpl : public DirectedGraph {
 public:
    template <class P, class S, class T>
    friend class CollectParserInfoImpl;

    ParserGraphImpl() {}

    const std::set<const State*>& states() const { return _states; }

    const ParserStateMap<State>& successors() const { return _succs; }

    const ParserStateMap<State>& predecessors() const { return _preds; }

    const std::map<const State*,
                   const Transition*>& to_pipe() const { return _to_pipe; }

    const Transition*
    transition(const State* src,
               const State* dst) const {
        if (_transitions.count({src, dst}))
            return _transitions.at({src, dst});

        return nullptr;
    }

    const Transition* to_pipe(const State* src) const {
        if (_to_pipe.count(src))
            return _to_pipe.at(src);

        return nullptr;
    }

    /// Is "src" an ancestor of "dst"?
    bool is_ancestor(const State* src, const State* dst) const {
        if (src == dst)
            return false;

        if (!predecessors().count(dst))
            return false;

        if (predecessors().at(dst).count(src))
            return true;

        /// DANGER -- this assumes parser graph is a unrolled DAG
        for (auto p : predecessors().at(dst))
            if (is_ancestor(src, p))
                return true;

        return false;
    }

    bool is_descendant(const State* src, const State* dst) const {
        return is_ancestor(dst, src);
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
        if (t->next) {
            add_state(state);
            add_state(t->next);
            _succs[state].insert(t->next);
            _preds[t->next].insert(state);
            _transitions[{state, t->next}] = t;
        } else {
            add_state(state);
            _to_pipe[state] = t;
        }
    }

    void merge_with(const ParserGraphImpl& other) {
        _states.insert(other.states().begin(), other.states().end());

        merge(_succs, other.successors());
        merge(_preds, other.predecessors());
        merge(_to_pipe, other.to_pipe());
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

 private:
    std::set<const State*> _states;

    ParserStateMap<State> _succs, _preds;

    std::map<std::pair<const State*, const State*>,
             const Transition*> _transitions;

    std::map<const State*,
             const Transition*> _to_pipe;

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
class CollectParserInfoImpl : public BFN::ControlFlowVisitor,
                              public PardeInspector {
    using StateMutexType = ParserStateMutex<Parser, State, Transition>;
    using GraphType = ParserGraphImpl<Parser, State, Transition>;

 public:
    CollectParserInfoImpl() {
        joinFlows = true;
        visitDagOnce = false;
    }

    const std::map<const Parser*, GraphType*>& graphs() const { return _graphs; }
    const GraphType& graph(const Parser* p) const { return *(_graphs.at(p)); }
    const StateMutexType & mutex(const Parser* p) const { return _mutex.at(p); }

    const Parser* parser(const State* state) const {
        return _state_to_parser.at(state);
    }

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);

        _graphs.clear();
        _mutex.clear();
        _state_to_parser.clear();

        return rv;
    }

    bool filter_join_point(const IR::Node*) override {
        return true; }

    void flow_merge(Visitor &other_) override {
        CollectParserInfoImpl &other = dynamic_cast<CollectParserInfoImpl &>(other_);
        LOG3("CollectParserInfoImpl(" << (void *)this << "): merging " << (void *)&other_);
        for (auto& g : other._graphs) {
            if (_graphs.count(g.first) == 0)
                _graphs.emplace(g.first, g.second);
            else
                _graphs.at(g.first)->merge_with(*(g.second)); }

        for (auto& m : other._mutex) {
            if (_mutex.count(m.first) == 0)
                _mutex.emplace(m.first, m.second);
            else
                _mutex.at(m.first).merge_with(m.second); }

        _state_to_parser.insert(other._state_to_parser.begin(),
                                other._state_to_parser.end());
    }

    CollectParserInfoImpl* clone() const override {
        return new CollectParserInfoImpl(*this);
    }

    bool preorder(const Parser* parser) override {
        _graphs[parser] = new GraphType;
        _mutex[parser] = StateMutexType();
        return true;
    }

    bool preorder(const State* state) override {
        auto parser = findContext<Parser>();
        _state_to_parser[state] = parser;

        auto g = _graphs.at(parser);

        g->add_state(state);

        for (auto t : state->transitions)
            g->add_transition(state, t);

        auto& mutex = _mutex.at(parser);
        add_mutex(mutex, state);

        return true;
    }

    void clear_mutex(StateMutexType & mutex) {
        mutex._mutually_inclusive.clear();
        mutex._states_encountered.clear();
    }

    void add_mutex(StateMutexType& mutex, const State* state) {
        if (mutex._states_encountered.count(state) == 0) {
            mutex._states_encountered.insert(state);
            merge(mutex._mutually_inclusive[state], mutex._states_encountered);
        }
    }

    void merge_mutex(StateMutexType& my, const StateMutexType& other) {
        merge(my._states_encountered, other._states_encountered);
        merge(my._mutually_inclusive, other._mutually_inclusive);
    }

    void calculate_mutex(StateMutexType& mutex) {
        LOG4("mutually exclusive states:");
        for (auto it1 = mutex._states_encountered.begin();
                  it1 != mutex._states_encountered.end(); ++it1 ) {
            for (auto it2 = it1; it2 != mutex._states_encountered.end(); ++it2) {
                // TODO(zma) what about states that have header added?

                if (mutex._mutually_inclusive.count(*it1) > 0)
                    if (mutex._mutually_inclusive.at(*it1).count(*it2) > 0)
                        continue;

                if (mutex._mutually_inclusive.count(*it2) > 0)
                    if (mutex._mutually_inclusive.at(*it2).count(*it1) > 0)
                        continue;

                mutex._mutually_exclusive[*it1].insert(*it2);
                mutex._mutually_exclusive[*it2].insert(*it1);
                LOG4("(" << (*it1)->name << ", " << (*it2)->name << ")");
            }
        }
    }

    void end_apply() override {
        for (auto g : _graphs)
            g.second->map_to_boost_graph();

        for (auto& m : _mutex)
            calculate_mutex(m.second);
    }

    std::map<const Parser*, GraphType*> _graphs;
    std::map<const Parser*, StateMutexType> _mutex;
    std::map<const State*, const Parser*> _state_to_parser;
};

using CollectParserInfo = CollectParserInfoImpl<IR::BFN::Parser,
                                                IR::BFN::ParserState,
                                                IR::BFN::Transition>;

using CollectLoweredParserInfo = CollectParserInfoImpl<IR::BFN::LoweredParser,
                                                       IR::BFN::LoweredParserState,
                                                       IR::BFN::LoweredParserMatch>;

#endif  /* EXTENSIONS_BF_P4C_PARDE_PARSER_INFO_H_ */
