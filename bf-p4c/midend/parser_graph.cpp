#include "parser_graph.h"

#include <boost/graph/strong_components.hpp>
#include <boost/graph/topological_sort.hpp>

using namespace boost;

typedef adjacency_list<vecS, vecS, directedS> Graph;

Graph
P4ParserGraphs::create_boost_graph(const IR::P4Parser* parser,
    std::map<int, cstring>& id_to_state) const {
  std::map<cstring, int> state_to_id;

  Graph g;

  for (auto s : states.at(parser)) {
    auto id = add_vertex(g);
    state_to_id[s->name] = id;
    id_to_state[id] = s->name;
  }

  for (auto t : transitions.at(parser)) {
    auto src = state_to_id.at(t->sourceState->name);
    auto dst = state_to_id.at(t->destState->name);
    add_edge(src, dst, g);
  }

  return g;
}

/// Compute the strongly connected components in the frontend parser IR.
/// We will use SCCs to figure out where the loops are in the parser.
std::set<std::set<cstring>>
P4ParserGraphs::compute_strongly_connected_components(const IR::P4Parser* parser) const {
  std::map<int, cstring> id_to_state;
  auto g = create_boost_graph(parser, id_to_state);

  std::vector<int> component(num_vertices(g)), discover_time(num_vertices(g));
  strong_components(g, make_iterator_property_map(component.begin(),
                                                  get(vertex_index, g)));

  std::map<unsigned, std::set<cstring>> cid_to_sccs;

  for (unsigned i = 0; i != component.size(); ++i)
    cid_to_sccs[component[i]].insert(id_to_state[i]);

  std::set<std::set<cstring>> sccs;

  for (auto& kv : cid_to_sccs)
    sccs.insert(kv.second);

  return sccs;
}

std::set<std::set<cstring>>
P4ParserGraphs::compute_loops(const IR::P4Parser* parser) const {
  auto sccs = compute_strongly_connected_components(parser);

  std::set<std::set<cstring>> loops;

  for (auto& s : sccs) {
    if (s.size() > 1) {
      loops.insert(s);
    } else if (s.size() == 1) {
      auto a = *s.begin();
      if (succs.count(a) && succs.at(a).count(a))
        loops.insert(s);
    }
  }

  return loops;
}

std::vector<cstring>
P4ParserGraphs::topological_sort(const IR::P4Parser* parser) const {
  std::map<int, cstring> id_to_state;
  auto g = create_boost_graph(parser, id_to_state);

  typedef boost::graph_traits<Graph>::vertex_descriptor Vertex;

  std::vector<Vertex> sorted;;
  boost::topological_sort(g, std::back_inserter(sorted));

  std::vector<cstring> rv;

  for (auto it = sorted.rbegin(); it != sorted.rend(); ++it)
    rv.push_back(id_to_state.at(*it));

  return rv;
}
