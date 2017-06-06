#ifndef DFA_H
#define DFA_H

#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>

#include <iostream>                  // for std::cout
#include <algorithm>                 // for std::for_each
#include <string>
#include <map>
#include <numeric>                   // for std::accumulate
#include <utility>                   // for std::pair

// TODO: generalize this.
#include "dfa.h"
#include "partition_refinement.h"

std::string id(std::string in) { return in; }

using namespace boost;

// TODO: need to add parameters for equality?

template < class Letter,    // Type of alphabet letters.
           class Label      // Vertex label.
         >
class FiniteAutomaton {

private:

    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::directedS,
        Label,
        Letter> Graph;

    typedef std::map<Label, typename Graph::vertex_descriptor> LabelToVertex;
    typedef std::map<typename Graph::vertex_descriptor, Label> VertexToLabel;

    LabelToVertex labelToVertex;
    VertexToLabel vertexToLabel;

    std::string (*print_letter)(Letter);
    std::string (*print_label)(Label);
    
    Label (*merge)(Label, Label);

    static std::string no_letter_printer(Letter) {
        return "<printer not supplied>";
    }
    static std::string no_label_printer(Label) {
        return "<printer not supplied>";
    }

    typedef std::map<
        typename Graph::vertex_descriptor,
        typename std::vector<typename Graph::edge_descriptor> >
        ReverseOutgoingEdgeMap;
    ReverseOutgoingEdgeMap reverseEdges;

    /* Fold over c.  Undefined for c.size() == 0. */
    template <class T>
    Label accumulate(T c) {
        assert(c.size() > 0);
        Label first = *(c.begin());
        c.erase(c.begin());
        Label merged =
            std::accumulate<
                typename std::set<Label>::iterator,
                Label,
                Label (*)(Label, Label)>(
                    c.begin(),
                    c.end(),
                    first,
                    merge);
        c.insert(first);
        return merged;
    }

public:

    // TODO: this should be private.  Or friend?
    Graph g;
    Label startState;
    std::set<Label> finalStates;

    FiniteAutomaton(
        Label start,
        std::string (*print_letter)(Letter),
        std::string (*print_label)(Label),
        Label (*merger)(Label, Label)
    ) :
        print_letter{print_letter},
        print_label{print_label},
        merge{merger}
    {
        startState = start;
        g = Graph(0);
    }

    FiniteAutomaton(Label start, Label (*merger)(Label, Label)) :
    FiniteAutomaton(start, no_letter_printer, no_label_printer, merger) { }

    void setLetterPrinter(std::string (*letter_printer)(Letter)) {
        print_letter = letter_printer;
    }

    void setLabelPrinter(std::string (*label_printer)(Label)) {
        print_label = label_printer;
    }

    void setLabelMerge(Label (*merger)(Label, Label)) {
        merge = merger;
    }

    bool addVertex(Label name) {
        if (contains(name))
            return false;

        typename Graph::vertex_descriptor v = add_vertex(g);
        g[v] = name;
        labelToVertex[name] = v;
        vertexToLabel[v] = name;

        return true;
    }

    class nondeterministic: public exception {
        virtual const char* what() const throw() {
            return "Added outgoing edge with duplicate letter.";
        }
    };

    void addEdge(Label name1, Label name2, Letter l) {
        if (!contains(name1))
            addVertex(name1);
        if (!contains(name2))
            addVertex(name2);

        typename Graph::out_edge_iterator e_it, e_end;
        for (boost::tie(e_it, e_end) = out_edges(labelToVertex[name1], g);
             e_it != e_end;
             ++e_it)
        {
            if (g[*e_it] == l && labelToVertex[name2] != target(*e_it, g))
                throw nondeterministic();
        }

        std::pair<typename Graph::edge_descriptor, bool> rv =
            add_edge(labelToVertex[name1], labelToVertex[name2], g);
        g[rv.first] = l;

        reverseEdges[labelToVertex[name2]].push_back(rv.first);
    }

    bool contains(Label l) {
        return labelToVertex.count(l) > 0;
    }

    void print(void)
    {
        typename graph_traits<Graph>::edge_iterator ei, ei_end;
        std::cout << "start state: " << print_label(startState) << std::endl;
        std::cout << "edges:" << std::endl;
        for (boost::tie(ei, ei_end) = edges(g); ei != ei_end; ++ei) {
            std::cout << "("
                << print_label(vertexToLabel[source(*ei, g)]) << ", "
                << print_letter(g[*ei]) << ", "
                << print_label(vertexToLabel[target(*ei, g)]) << ")"
                << std::endl;
        }
        std::cout << "final states:";
        for (auto iter = finalStates.begin();
             iter != finalStates.end();
             ++iter)
        {
            std::cout << " " << print_label(*iter);
        }
        std::cout << std::endl;
    }

    void addStartState(Label l) {
        startState = l;
    }

    void addFinalState(Label l) {
        finalStates.insert(l);
    }

    FiniteAutomaton<Letter, Label>
    intersect(FiniteAutomaton<Letter, Label> other) {
        // Start state.
        FiniteAutomaton<Letter, Label> ia(
            merge(startState, other.startState),
            print_letter,
            print_label,
            merge);

        // Edges: For each pair of vertices v11, v12, and each pair of edges (v11,
        // v21), (v12, v22), add ((v11, v12), (v21, v22)) to the intersection
        // automaton.  If v11 or v12 have no outgoing edges, do not add an edge.
        typename graph_traits<Graph>::vertex_iterator vi, vi_end, vi_2, vi_end_2;
        typename graph_traits<Graph>::out_edge_iterator vi_out;
        typename graph_traits<Graph>::out_edge_iterator vi_out_end;
        typename graph_traits<Graph>::out_edge_iterator vi_out_2;
        typename graph_traits<Graph>::out_edge_iterator vi_out_end_2;
        for (boost::tie(vi, vi_end) = vertices(g);
             vi != vi_end;
             ++vi) {
            boost::tie(vi_2, vi_end_2) = vertices(other.g);
            for ( ; vi_2 != vi_end_2; ++vi_2) {
                boost::tie(vi_out, vi_out_end) = out_edges(*vi, g);
                for ( ; vi_out != vi_out_end; ++vi_out) {
                    boost::tie(vi_out_2, vi_out_end_2) = out_edges(*vi_2, other.g);
                    for ( ; vi_out_2 != vi_out_end_2; ++vi_out_2) {
                        if (g[*vi_out] == other.g[*vi_out_2]) {
                            ia.addEdge(
                                merge(g[*vi], other.g[*vi_2]),
                                merge(g[target(*vi_out, g)],
                                      other.g[target(*vi_out_2, other.g)]),
                                g[*vi_out]);
                        }
                    }
                }
            }
        }

        // Final states.
        for (auto it = finalStates.begin(); it != finalStates.end(); ++it) {
            for (auto other_it = other.finalStates.begin();
                 other_it != other.finalStates.end();
                 ++other_it)
            {
                ia.addFinalState(merge(*it, *other_it));
            }
        }

        return ia;
    }

    bool accepts(std::vector<Letter> word) {
        typename Graph::vertex_descriptor state = labelToVertex[startState];
        typename graph_traits<Graph>::out_edge_iterator out_it, out_end;

        for (auto word_it = word.begin(); word_it != word.end(); ++word_it) {
            for ( boost::tie(out_it, out_end) = out_edges(state, g);
                  out_it != out_end;
                  ++out_it )
            {
                if (g[*out_it] == *word_it) {
                    state = target(*out_it, g);
                    break;
                }
            }

            // Return false if no outgoing edge matches this letter.
            if (out_it == out_end)
                return false;
        }
        Label end = vertexToLabel[state];
        for (auto it = finalStates.begin(); it != finalStates.end(); ++it) {
            if (*it == end)
                return true;
        }
        return false;
    }

    FiniteAutomaton< Letter, Label > minimize(void) {
        return remove_unreachable().hopcroft();
    }

private:

    FiniteAutomaton<Letter, Label> remove_unreachable(void) {
        FiniteAutomaton<Letter, Label>
            rv(startState, print_letter, print_label, merge);
        adjacency_list <> tc;
        transitive_closure(g, tc);

        auto start_v = labelToVertex[startState];
        std::set<typename Graph::vertex_descriptor> reachable;
        reachable.insert(start_v);

        typename adjacency_list<>::out_edge_iterator e_out_it, e_out_end;
        for ( boost::tie(e_out_it, e_out_end) = out_edges(start_v, tc);
              e_out_it != e_out_end;
              ++e_out_it )
        {
            reachable.insert(target(*e_out_it, tc));
        }

        typename Graph::edge_iterator e_it, e_end;
        for (boost::tie(e_it, e_end) = edges(g); e_it != e_end; ++e_it) {
            /* Only add an edge to rv if:
             *   1: its source is reachable from the start state, and
             *   2: its target can reach (or is) a final state.
             */
            auto src = source(*e_it, g);
            auto tgt = target(*e_it, g);

            // If not reachable, continue.
            if (reachable.find(src) == reachable.end())
                continue;

            typename adjacency_list<>::out_edge_iterator e_out_it, e_out_end;
            for ( boost::tie(e_out_it, e_out_end) = out_edges(tgt, tc);
                  e_out_it != e_out_end;
                  ++e_out_it )
            {
                // Add if a final state is reachable from tgt...
                if (finalStates.find(vertexToLabel[target(*e_out_it, tc)])
                    != finalStates.end())
                {
                    rv.addEdge(g[source(*e_it, g)], g[tgt], g[*e_it]);
                    break;
                }
            }
            // ...or if tgt IS a final state.
            if (finalStates.find(vertexToLabel[tgt]) != finalStates.end()) {
                rv.addEdge(g[source(*e_it, g)], g[tgt], g[*e_it]);
            }
        }

        // Register reachable final states.
        for (auto it = finalStates.begin(); it != finalStates.end(); ++it) {
            if (reachable.find(labelToVertex[*it]) != reachable.end())
                rv.addFinalState(*it);
        }

        return rv;
    }

    FiniteAutomaton<Letter, Label> hopcroft(void) {
        // Using the Hopcroft DFA minimization algorithm.
        typedef typename Graph::edge_descriptor Edge;

        // TODO: should update partition_refinement to take a pair of
        // iterators.
        std::set<Label> all_vertices, final_state_vertices;
        typename Graph::vertex_iterator v_it, v_end;
        for (boost::tie(v_it, v_end) = vertices(g); v_it != v_end; ++v_it) {
            all_vertices.insert(g[*v_it]);
            if (finalStates.find(g[*v_it]) != finalStates.end())
                final_state_vertices.insert(g[*v_it]);
        }

        PartitionRefinement<Label> partitions(all_vertices);
        partitions.refine(final_state_vertices);
        std::vector< std::set<Label> > worklist = { final_state_vertices };

        while (worklist.size() > 0) {
            std::set<Label> a = worklist.back();
            worklist.pop_back();

            // Build a set x of states that transition into a on the same
            // letter.  The vector xs is one x per letter.
            boost::optional<Letter> l;
            std::map< Letter, std::set<Label> > xs;
            for (auto a_it = a.begin(); a_it != a.end(); ++a_it)
            {
                std::vector<Edge> incoming = reverseEdges[labelToVertex[*a_it]];
                for ( auto inc_it = incoming.begin();
                      inc_it != incoming.end();
                      ++inc_it )
                {
                    Letter this_l = g[*inc_it];

                    if (!l && xs.find(this_l) != xs.end())
                        continue;
                    else if (!l) {
                        l = boost::optional<Letter>(this_l);
                    }

                    // Add the source of this edge to x.
                    if (*l == this_l)
                        xs[this_l].insert(g[source(*inc_it, g)]);
                }
            }

            for ( auto x = xs.begin(); x != xs.end(); ++x)
            {
                auto y_pairs = partitions.refine(x->second);
                for ( auto y_pair = y_pairs.begin();
                      y_pair != y_pairs.end();
                      ++y_pair)
                {
                    std::set<Label> y;
                    y.insert(y_pair->first.begin(), y_pair->first.end());
                    y.insert(y_pair->second.begin(), y_pair->second.end());

                    auto worklist_it = worklist.begin();
                    for (; worklist_it != worklist.end(); ++worklist_it)
                        if (*worklist_it == y)
                            break;
                    if (worklist_it == worklist.end()) {
                        worklist.push_back(
                            y_pair->first.size() < y_pair->second.size() ?
                            y_pair->first : y_pair -> second);
                    } else {
                        worklist.erase(worklist_it);
                        worklist.push_back(y_pair->first);
                        worklist.push_back(y_pair->second);
                    }
                }
            }
        }

        std::set< std::set<Label> > all_partitions =
            partitions.get_partition();

        std::cout << "startState: " << startState << std::endl;
        // Find the new start and final states.
        Label new_start;
        std::set<Label> new_finals;
        for ( auto p_it = all_partitions.begin();
              p_it != all_partitions.end();
              ++p_it)
        {
            Label this_new_state = accumulate< std::set<Label> >(*p_it);

            for (auto i = p_it->begin(); i != p_it->end(); ++i)
                std::cout << *i;
            std::cout << std::endl;
            if (p_it->find(startState) != p_it->end()) {
                new_start = this_new_state;
                std::cout << "NEW START: " << print_label(new_start) << std::endl;
            }

            for ( auto v_it = p_it->begin();
                  v_it != p_it->end();
                  ++v_it )
            {
                if (finalStates.find(*v_it) != finalStates.end())
                {
                    new_finals.insert(this_new_state);
                    break;
                }
            }
        }

        FiniteAutomaton<Letter, Label> rv(new_start, print_letter, print_label, merge);
        for (auto f = new_finals.begin(); f != new_finals.end(); ++f) {
            rv.addFinalState(*f);
        }

        // TODO: optimize this.
        for ( auto new_state = all_partitions.begin();
              new_state != all_partitions.end();
              ++new_state )
        {
            Label new_state_label = accumulate< std::set<Label> >(*new_state);

            for ( auto l = new_state->begin();
                  l != new_state->end();
                  ++l )
            {
                typename Graph::out_edge_iterator e, e_end;
                for ( boost::tie(e, e_end) = out_edges(labelToVertex[*l], g);
                      e != e_end;
                      ++e )
                {
                    Label next = g[target(*e, g)];
                    for ( auto next_state = all_partitions.begin();
                          next_state != all_partitions.end();
                          ++next_state )
                    {
                        Label next_state_label = accumulate< std::set<Label> >(*next_state);
                        if (next_state->find(next) != next_state->end()) {
                            rv.addEdge(new_state_label, next_state_label, g[*e]);
                            break;
                        }
                    }
                }
            }

        }

        return rv;
    }

};

#endif /* DFA_H */
