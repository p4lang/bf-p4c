#include "parser_graph.h"

#include <boost/graph/strong_components.hpp>
#include <boost/graph/adjacency_list.hpp>

/// Compute the strongly connected components in the frontend parser IR.
/// We will use SCCs to figure out where the loops are in the parser.
std::set<std::set<cstring>>
P4ParserGraphs::compute_strongly_connected_components(const IR::P4Parser* parser) const {
  using namespace boost;

  std::map<cstring, int> state_to_id;
  std::map<int, cstring> id_to_state;

  typedef adjacency_list<vecS, vecS, directedS> Graph;
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

  std::vector<int> component(num_vertices(g)), discover_time(num_vertices(g));
  int num = strong_components(g, make_iterator_property_map(component.begin(),
                                 get(vertex_index, g)));

  std::map<unsigned, std::set<cstring>> cid_to_sccs;

  for (int i = 0; i != component.size(); ++i)
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
