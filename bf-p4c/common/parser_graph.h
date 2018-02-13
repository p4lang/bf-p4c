#ifndef EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_
#define EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_

// FIXME(zma) this file is missing quite a few headers and yet compiles fine
// thanks to the unified build; not sure if it's a good thing ...

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

class ParserGraph : public DirectedGraph {
 public:
    friend class CollectParserGraph;

    ParserGraph() {}

    const std::set<const IR::BFN::ParserState*>& states() const { return _states; }

    const std::map<const IR::BFN::ParserState*,
                   std::set<const IR::BFN::ParserState*>>& transitions() const {
        return _transitions;
    }

    std::vector<const IR::BFN::ParserState*> topological_sort() const {
        std::vector<int> result = DirectedGraph::topological_sort();
        std::vector<const IR::BFN::ParserState*> mapped_result;
        for (auto id : result)
            mapped_result.push_back(get_state(id));
        return mapped_result;
    }

 private:
    void add_state(const IR::BFN::ParserState* s) {
        _states.insert(s);
    }

    void add_transition(const IR::BFN::ParserState* src, const IR::BFN::ParserState* dst) {
        add_state(src);
        add_state(dst);
        _transitions[src].insert(dst);
    }

    void merge_with(const ParserGraph& other) {
        _states.insert(other.states().begin(), other.states().end());

        for (auto t : other.transitions()) {
            if (_transitions.count(t.first) == 0) {
                _transitions[t.first] = t.second;
            } else {
                for (auto dst : t.second)
                    _transitions[t.first].insert(dst);
            }
        }
    }

    void map_to_boost_graph() {
        for (auto s : _states) {
            int id = DirectedGraph::add_vertex();
            _state_to_id[s] = id;
            _id_to_state[id] = s;
        }

        for (auto t : _transitions)
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
    std::map<const IR::BFN::ParserState*, std::set<const IR::BFN::ParserState*>> _transitions;

    std::map<const IR::BFN::ParserState*, int> _state_to_id;
    std::map<int, const IR::BFN::ParserState*> _id_to_state;
};

class CollectParserGraph : public BFN::ControlFlowVisitor, public PardeInspector {
 public:
    CollectParserGraph() {
        joinFlows = true;
        visitDagOnce = false;

        _graphs[0] = new ParserGraph;
        _graphs[1] = new ParserGraph;
    }

    const ParserGraph& ingress() const { return *(_graphs[0]); }
    const ParserGraph& egress() const { return *(_graphs[1]); }

 private:
    bool filter_join_point(const IR::Node*) override { return true; }

    void flow_merge(Visitor &other_) override {
       CollectParserGraph &other = dynamic_cast<CollectParserGraph &>(other_);

       _graphs[0]->merge_with(other.ingress());
       _graphs[1]->merge_with(other.egress());
    }

    CollectParserGraph* clone() const override {
        return new CollectParserGraph(*this);
    }

    bool preorder(const IR::BFN::ParserState* state) override {
        auto g = _graphs[state->gress];

        g->add_state(state);

        for (auto t : state->transitions)
            if (t->next)
                g->add_transition(state, t->next);

        return true;
    }

    void end_apply() override {
        _graphs[0]->map_to_boost_graph();
        _graphs[1]->map_to_boost_graph();
    }

    std::array<ParserGraph*, 2> _graphs;
};

#endif  /* EXTENSIONS_BF_P4C_COMMON_PARSER_GRAPH_H_ */
