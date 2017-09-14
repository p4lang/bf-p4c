#include "table_dependency_graph.h"
#include <assert.h>
#include <boost/graph/breadth_first_search.hpp>
#include <algorithm>
#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/ir/tofino_write_context.h"


static const char *dep_types[] = { "CONTROL", "DATA", "ANTI", "OUTPUT" };

std::ostream &operator<<(std::ostream &out, const DependencyGraph &dg) {
    out << "GRAPH" << std::endl;
    DependencyGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(dg.g);
         edges != edges_end;
         ++edges) {
        out << "    " << dg.g[boost::source(*edges, dg.g)]->name << " -- "
            << dep_types[dg.g[*edges]] << " --> "
            << dg.g[boost::target(*edges, dg.g)]->name << std::endl; }

    out << "MIN STAGE, DEPENDENCE CHAIN" << std::endl;
    for (auto &kv : dg.stage_info) {
        out << "    " << kv.first->name << ": "
            << kv.second.min_stage << ", " << kv.second.dep_stages
            << std::endl; }

    return out;
}

class FindDependencyGraph::AddDependencies : public MauInspector, TofinoWriteContext {
    FindDependencyGraph         &self;
    const IR::MAU::Table        *table;

 public:
    AddDependencies(FindDependencyGraph &self, const IR::MAU::Table *t)
    : self(self), table(t) { }

    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            if (!self.access.count(field->name)) return false;
            LOG3("add_dependency(" << field->name << ")");
            if (isWrite()) {
                // Write-after-read dependence.
                for (auto upstream_t : self.access[field->name].read)
                    self.dg.add_edge(upstream_t, table, DependencyGraph::ANTI);
                // Write-after-write dependence.
                for (auto upstream_t : self.access[field->name].write)
                    self.dg.add_edge(upstream_t, table, DependencyGraph::OUTPUT);
            } else {
                // Read-after-write dependence.
                for (auto upstream_t : self.access[field->name].write)
                    self.dg.add_edge(upstream_t, table, DependencyGraph::DATA); }
            return false; }
        return true; }
    bool preorder(const IR::Annotation *) override { return false; }
};

class FindDependencyGraph::UpdateAccess : public MauInspector , TofinoWriteContext {
    FindDependencyGraph         &self;
    const IR::MAU::Table        *table;

 public:
    UpdateAccess(FindDependencyGraph &self, const IR::MAU::Table *t) : self(self), table(t) {}
    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            if (isWrite()) {
                LOG3("update_access write " << field->name);
                auto &a = self.access[field->name];
                a.read.clear();
                a.write.clear();
                a.write.insert(table);
            } else {
                LOG3("update_access read " << field->name);
                self.access[field->name].read.insert(table); }
            return false; }
        return true; }
};

class FindDependencyGraph::UpdateAttached : public Inspector {
    FindDependencyGraph         &self;
    const IR::MAU::Table        *table;

 public:
    UpdateAttached(FindDependencyGraph &self, const IR::MAU::Table *t) : self(self), table(t) { }
    void postorder(const IR::MAU::Meter *meter) override {
        if (meter->direct && meter->result) {
            auto *field = self.phv.field(meter->result);
            BUG_CHECK(field, "meter writing to %s", meter->result);
            auto &a = self.access[field->name];
            a.read.clear();
            a.write.clear();
            a.write.insert(table);
        }
        /*
        if (meter->indirect_index) {
            auto *field = self.phv.field(meter->indirect_index);
            if (field != nullptr) {
                auto &a = self.access[field->name];
                a.read.insert(table);
            }
        }
        */
    }

    /*
    void postorder(const IR::MAU::MAUCounter *counter) override {
        if (counter->indirect_index) {
            auto *field = self.phv.field(counter->indirect_index);
            BUG_CHECK(field, "counter reading from %s", counter->indirect_index);
            if (field != nullptr) {
                auto &a = self.access[field->name];
                a.read.insert(table);
            }
        }
    }
    */
};


bool FindDependencyGraph::preorder(const IR::MAU::TableSeq *seq) {
    const Context *ctxt = getContext();
    if (ctxt && ctxt->node->is<IR::BFN::Pipe>()) {
        access.clear();
    } else if (ctxt && dynamic_cast<const IR::MAU::Table *>(ctxt->node)) {
        const IR::MAU::Table* parent;
        parent = dynamic_cast<const IR::MAU::Table *>(ctxt->node);
        for (auto child : seq->tables) {
            dg.add_edge(parent, child, DependencyGraph::CONTROL); } }

    return true;
}

bool FindDependencyGraph::preorder(const IR::MAU::Table *t) {
    LOG3("FindDep table " << t->name);

    // TODO: add a pass in the beginning of the back end that checks for
    // duplicate table instances and, if found, aborts compilation.
    //     error("%s: Multiple applies of table %s not supported", t->srcInfo, t->name); }

    // Add this table as a vertex in the dependency graph if it's not
    // already there.
    dg.add_vertex(t);

    // Add data dependences induced by gateways, matches, and actions.
    for (auto &gw : t->gateway_rows)
        gw.first->apply(AddDependencies(*this, t));
    if (t->match_table && t->match_table->getKey())
        t->match_table->getKey()->apply(AddDependencies(*this, t));
    for (auto &action : Values(t->actions))
        action->apply(AddDependencies(*this, t));

    // Mark fields read/written by this table in accesses.
    for (auto &gw : t->gateway_rows)
        gw.first->apply(UpdateAccess(*this, t));
    for (auto &action : Values(t->actions))
        action->apply(UpdateAccess(*this, t));
    t->apply(UpdateAttached(*this, t));
    return true;
}

template<class T>
inline set<T> &operator |=(set<T> &s, const set<T> &a) {
    s.insert(a.begin(), a.end());
    return s; }

void FindDependencyGraph::flow_merge(Visitor &v) {
    for (auto &a : dynamic_cast<FindDependencyGraph &>(v).access) {
        access[a.first].read |= a.second.read;
        access[a.first].write |= a.second.write;
    }
}

// Should be applied to a reversed graph, so that it populates happens_before_map
// starting at the leaves.
class bfs_happens_before_visitor : public boost::default_bfs_visitor {
  // happens_before_map[t1] = {t2, t3} means t1 happens strictly before t2 and t3.
  map< const IR::MAU::Table*,
       set<const IR::MAU::Table*> >& happens_before_map;

  // happens_not_after[t1] = {t2, t3} means t1 and t2 and/or t3 may happen in
  // the same stage, or t1 may happen first, but neither t2 nor t3 can happen
  // before t1.
  map< const IR::MAU::Table*,
       set<const IR::MAU::Table*> > happens_not_after;

 public:
    bfs_happens_before_visitor(
        map< const IR::MAU::Table*,
             set<const IR::MAU::Table*> >& happens_before_map)
        : happens_before_map(happens_before_map)
    { }

    template <typename Vertex, typename Graph>
    void discover_vertex(Vertex v, const Graph &g) {
        // Ensure that every table gets entered into the happens-before map.
        const IR::MAU::Table* label = g[v];

        if (happens_before_map[label].size() == 0)
            happens_before_map[label] = set<const IR::MAU::Table*>();
        if (happens_not_after[label].size() == 0)
            happens_not_after[label] = set<const IR::MAU::Table*>();
    }

    template <typename Edge, typename Graph>
    void examine_edge(Edge e, const Graph &g) {
        const IR::MAU::Table* src = g[boost::source(e, g)];
        const IR::MAU::Table* dst = g[boost::target(e, g)];

        happens_not_after[dst] |= happens_not_after[src];
        happens_not_after[dst].insert(src);

        happens_before_map[dst] |= happens_before_map[src];
        if (g[e] != DependencyGraph::ANTI &&
            g[e] != DependencyGraph::CONTROL) {
            happens_before_map[dst].insert(src);
        }
    }
};

class bfs_depth_visitor : public boost::default_bfs_visitor {
  std::map<DependencyGraph::Graph::vertex_descriptor, int>& counts;
 public:
    bfs_depth_visitor(
        std::map<DependencyGraph::Graph::vertex_descriptor, int>& counts)
        : counts(counts) { }

    void examine_edge(
        DependencyGraph::Graph::edge_descriptor e,
        const DependencyGraph::Graph& g) {
        DependencyGraph::Graph::vertex_descriptor src, dst;
        src = boost::source(e, g);
        dst = boost::target(e, g);

        // Tables with anti-dependencies (write-after-read) and control
        // dependencies can be placed in the same stage, so don't increment the
        // min stage in that case.
        int count = counts[src];
        if (g[e] != DependencyGraph::ANTI && g[e] != DependencyGraph::CONTROL)
            count++;

        counts[dst] = std::max(count, counts[dst]);
    }
};

void FindDependencyGraph::finalize_dependence_graph(void) {
    typename DependencyGraph::Graph::vertex_iterator v, v_end;
    typename DependencyGraph::Graph::edge_iterator out, out_end;
    set<typename DependencyGraph::Graph::vertex_descriptor> roots;

    // Some operations need to be performed on the reversed graph.
    DependencyGraph::Graph rev_g = dg.g;
    boost::tie(out, out_end) = boost::edges(rev_g);
    while (out != out_end) {
        boost::remove_edge(*out, rev_g);
        boost::tie(out, out_end) = boost::edges(rev_g);
    }
    for (boost::tie(out, out_end) = boost::edges(dg.g);
         out != out_end;
         ++out) {
        DependencyGraph::Graph::vertex_descriptor src, dst;
        dst = boost::target(*out, dg.g);
        src = boost::source(*out, dg.g);

        auto p = boost::add_edge(dst, src, rev_g);
        rev_g[p.first] = dg.g[*out];
        rev_g[dst] = dg.g[dst];
        rev_g[src] = dg.g[src];
     }

    // Build the happens_before_map relation, and for each table, calculate the
    // length of the longest chain of tables that depend on it and must be
    // placed in later stages.

    std::map< DependencyGraph::Graph::vertex_descriptor, int > post_chains;
    bfs_depth_visitor back_vis(post_chains);
    bfs_happens_before_visitor hb_vis(dg.happens_before_map);

    roots.clear();
    for (boost::tie(v, v_end) = boost::vertices(rev_g); v != v_end; ++v) {
        post_chains[*v] = 0;
        roots.insert(*v); }

    for (boost::tie(out, out_end) = boost::edges(rev_g); out != out_end; ++out)
        roots.erase(boost::target(*out, rev_g));

    for (auto root : roots) {
        boost::breadth_first_search(rev_g, root, boost::visitor(hb_vis));
        boost::breadth_first_search(rev_g, root, boost::visitor(back_vis));
    }

    for (auto &kv : post_chains) {
        const IR::MAU::Table* table = rev_g[kv.first];
        dg.stage_info[table].dep_stages = kv.second;
    }

    // For each table, calculate the minimum stage in which it can be placed.
    // This is its depth in the dependence graph.
    std::map<DependencyGraph::Graph::vertex_descriptor, int> pre_chains;
    boost::tie(v, v_end) = boost::vertices(dg.g);
    for (; v != v_end; ++v) pre_chains[*v] = 0;
    bfs_depth_visitor vis(pre_chains);

    roots.clear();
    boost::tie(v, v_end) = boost::vertices(dg.g);
    roots.insert(v, v_end);

    for (boost::tie(out, out_end) = boost::edges(dg.g); out != out_end; ++out)
        roots.erase(boost::target(*out, dg.g));

    for (auto root : roots) {
        boost::breadth_first_search(dg.g, root, boost::visitor(vis));
    }

    for (auto &kv : pre_chains) {
        const IR::MAU::Table* table = dg.g[kv.first];
        dg.stage_info[table].min_stage = kv.second;
    }

    verify_dependence_graph();
    dg.finalized = true;
}

void FindDependencyGraph::verify_dependence_graph() {
    typename DependencyGraph::Graph::edge_iterator out, out_end;
    for (boost::tie(out, out_end) = boost::edges(dg.g);
         out != out_end;
         ++out) {
        const IR::MAU::Table *t1 = dg.g[boost::source(*out, dg.g)];
        const IR::MAU::Table *t2 = dg.g[boost::target(*out, dg.g)];
        if (t1->gress == EGRESS && t2->gress == INGRESS)
            BUG("Ingress table '%s' depends on egress table '%s'.", t1->name, t2->name); }
}
