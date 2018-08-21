#ifndef EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_
#define EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_

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

using ParserStateMap = std::map<const IR::BFN::ParserState*,
                                std::set<const IR::BFN::ParserState*>>;

struct ParserStateMutex {
    std::set<const IR::BFN::ParserState*> _states_encountered;
    ParserStateMap _mutually_inclusive;
    ParserStateMap _mutually_exclusive;

    const ParserStateMap& mutex_state_map() const { return _mutually_exclusive; }

    bool mutex(const IR::BFN::ParserState* a, const IR::BFN::ParserState* b) const {
        if (_mutually_exclusive.count(a) > 0)
            if (_mutually_exclusive.at(a).count(b) > 0)
                return true;
        return false;
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

class ParserGraph : public DirectedGraph {
 public:
    friend class CollectParserInfo;

    ParserGraph() {}

    const std::set<const IR::BFN::ParserState*>& states() const { return _states; }

    const ParserStateMap& successors() const { return _succs; }

    const ParserStateMap& predecessors() const { return _preds; }

    const std::set<const IR::BFN::ParserState*>& to_pipe() const { return _to_pipe; }

    /// Is "src" an ancestor of "dst"?
    bool is_ancestor(const IR::BFN::ParserState* src, const IR::BFN::ParserState* dst) const {
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

    bool is_descendant(const IR::BFN::ParserState* src, const IR::BFN::ParserState* dst) const {
        return is_ancestor(dst, src);
    }

    std::set<const IR::BFN::ParserState*>
    get_all_descendants(const IR::BFN::ParserState* src) const {
        std::set<const IR::BFN::ParserState*> rv;
        get_all_descendants_impl(src, rv);
        return rv;
    }

    std::vector<const IR::BFN::ParserState*> topological_sort() const {
        std::vector<int> result = DirectedGraph::topological_sort();
        std::vector<const IR::BFN::ParserState*> mapped_result;
        for (auto id : result)
            mapped_result.push_back(get_state(id));
        return mapped_result;
    }

 private:
    void get_all_descendants_impl(const IR::BFN::ParserState* src,
                                  std::set<const IR::BFN::ParserState*>& rv) const {
        if (!successors().count(src))
            return;

        for (auto succ : successors().at(src)) {
            rv.insert(succ);
            get_all_descendants_impl(succ, rv);
        }
    }

    void add_state(const IR::BFN::ParserState* s) {
        _states.insert(s);
    }

    void add_transition(const IR::BFN::ParserState* src, const IR::BFN::ParserState* dst) {
        add_state(src);
        add_state(dst);
        _succs[src].insert(dst);
        _preds[dst].insert(src);
    }

    void add_transition_to_pipe(const IR::BFN::ParserState* src) {
       add_state(src);
       _to_pipe.insert(src);
    }

    void merge_with(const ParserGraph& other) {
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

    int get_id(const IR::BFN::ParserState* s) {
        if (_state_to_id.count(s) == 0)
            add_state(s);
        return _state_to_id.at(s);
    }

    const IR::BFN::ParserState* get_state(int id) const {
        return _id_to_state.at(id);
    }

 private:
    std::set<const IR::BFN::ParserState*> _states;
    ParserStateMap _succs;
    ParserStateMap _preds;
    std::set<const IR::BFN::ParserState*> _to_pipe;

    std::map<const IR::BFN::ParserState*, int> _state_to_id;
    std::map<int, const IR::BFN::ParserState*> _id_to_state;
};

class CollectParserInfo : public BFN::ControlFlowVisitor, public PardeInspector {
 public:
    CollectParserInfo() {
        joinFlows = true;
        visitDagOnce = false;
    }

    const std::map<const IR::BFN::Parser*, ParserGraph*>& graphs() const { return _graphs; }
    const ParserGraph& graph(const IR::BFN::Parser* p) const { return *(_graphs.at(p)); }
    const ParserStateMutex& mutex(const IR::BFN::Parser* p) const { return _mutex.at(p); }

    const IR::BFN::Parser* parser(const IR::BFN::ParserState* state) const {
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

    bool filter_join_point(const IR::Node*) override { return true; }

    void flow_merge(Visitor &other_) override {
       CollectParserInfo &other = dynamic_cast<CollectParserInfo &>(other_);

        for (auto g : _graphs)
            g.second->merge_with(*(other._graphs.at(g.first)));

        for (auto& m : _mutex)
            merge_mutex(m.second, other._mutex.at(m.first));

        _state_to_parser.insert(other._state_to_parser.begin(),
                                other._state_to_parser.end());
    }

    CollectParserInfo* clone() const override {
        return new CollectParserInfo(*this);
    }

    bool preorder(const IR::BFN::Parser* parser) override {
        _graphs[parser] = new ParserGraph;
        _mutex[parser] = ParserStateMutex();
        return true;
    }

    bool preorder(const IR::BFN::ParserState* state) override {
        auto parser = findContext<IR::BFN::Parser>();
        _state_to_parser[state] = parser;

        auto g = _graphs.at(parser);

        g->add_state(state);

        for (auto t : state->transitions)
            if (t->next)
                g->add_transition(state, t->next);
            else
                g->add_transition_to_pipe(state);

        auto& mutex = _mutex.at(parser);
        add_mutex(mutex, state);

        return true;
    }

    void clear_mutex(ParserStateMutex& mutex) {
        mutex._mutually_inclusive.clear();
        mutex._states_encountered.clear();
    }

    void add_mutex(ParserStateMutex& mutex, const IR::BFN::ParserState* state) {
        if (mutex._states_encountered.count(state) == 0) {
            mutex._states_encountered.insert(state);
            merge(mutex._mutually_inclusive[state], mutex._states_encountered);
        }
    }

    void merge_mutex(ParserStateMutex& my, const ParserStateMutex& other) {
        merge(my._states_encountered, other._states_encountered);
        merge(my._mutually_inclusive, other._mutually_inclusive);
    }

    void calculate_mutex(ParserStateMutex& mutex) {
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

    std::map<const IR::BFN::Parser*, ParserGraph*> _graphs;
    std::map<const IR::BFN::Parser*, ParserStateMutex> _mutex;
    std::map<const IR::BFN::ParserState*, const IR::BFN::Parser*> _state_to_parser;
};

#endif  /* EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_ */
