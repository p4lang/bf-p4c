#include "bf-p4c/mau/table_dependency_graph.h"
#include <assert.h>
#include <boost/graph/breadth_first_search.hpp>
#include <boost/optional.hpp>
#include <algorithm>
#include <numeric>
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"

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
    FindDependencyGraph                 &self;
    const IR::MAU::Table                *table;
    const ordered_set<cstring>&         ignoreDep;
    std::map<PHV::Container, bitvec>    cont_writes;

 public:
    AddDependencies(FindDependencyGraph &self, const IR::MAU::Table *t, ordered_set<cstring>& t1) :
        self(self), table(t), ignoreDep(t1) { }

 private:
    profile_t init_apply(const IR::Node* root) override {
        cont_writes.clear();
        return Inspector::init_apply(root);
    }

    void addDeps(ordered_set<const IR::MAU::Table *> tables, const IR::MAU::Table* tbl,
            DependencyGraph::dependencies_t dep) {
        for (auto upstream_t : tables) {
            if (upstream_t->match_table
                && ignoreDep.count(upstream_t->match_table->externalName())) {
                LOG3("Ignoring dependency from " << upstream_t->name << " to " << tbl->name);
                continue; }
            self.dg.add_edge(upstream_t, table, dep); }
    }

    void addContDeps(ordered_map<const IR::MAU::Table *, bitvec> tables,
                     const IR::MAU::Table *t, bitvec range, PHV::Container container) {
        for (auto upstream_t : tables) {
            if (upstream_t.first->match_table &&
                    ignoreDep.count(upstream_t.first->match_table->externalName())) {
                WARN_CHECK(upstream_t.second == range, "Table %s's pragma ignore_table_dependency "
                           "of %s is also ignoring PHV added action dependencies over container "
                           "%s, which may not have been the desired outcome", t->name,
                            upstream_t.first->name, container.toString());
                continue;
            }
            LOG3("Adding container conflict between table " << upstream_t.first->name << " and "
                 << "table " << t->name << " because of container " << container);
            self.dg.container_conflicts[upstream_t.first].insert(t);
            self.dg.container_conflicts[t].insert(upstream_t.first);
        }
    }

    bool preorder(const IR::Expression *e) override {
        auto* originalField = self.phv.field(e);
        if (!originalField) return true;
        ordered_set<const PHV::Field*> candidateFields;
        candidateFields.insert(originalField);
        if (self.phv.getAliasMap().count(originalField))
            candidateFields.insert(self.phv.getAliasMap().at(originalField));
        for (const PHV::Field* field : candidateFields) {
            cstring field_name = field->name;
            if (self.access.count(field_name)) {
                LOG3("add_dependency(" << field_name << ")");
                if (isWrite()) {
                    // Write-after-read dependence.
                    addDeps(self.access[field->name].read, table, DependencyGraph::ANTI);
                    // Write-after-write dependence.
                    addDeps(self.access[field->name].write, table, DependencyGraph::OUTPUT);
                } else {
                    // Read-after-write dependence.
                    addDeps(self.access[field->name].write, table, DependencyGraph::DATA);
                }
            }
            if (isWrite() && self.phv.alloc_done()) {
                field->foreach_alloc([&](const PHV::Field::alloc_slice &sl) {
                    bitvec range(sl.container_bit, sl.width);
                    cont_writes[sl.container] |= range;
                });
            }
        }
        return false;
    }

    bool preorder(const IR::Annotation *) override { return false; }
    void end_apply() override {
        for (auto entry : cont_writes) {
            addContDeps(self.cont_write[entry.first], table, entry.second, entry.first);
        }
    }
};

class FindDependencyGraph::UpdateAccess : public MauInspector , TofinoWriteContext {
    FindDependencyGraph                &self;
    const IR::MAU::Table               *table;
    std::map<PHV::Container, bitvec>    cont_writes;

 public:
    UpdateAccess(FindDependencyGraph &self, const IR::MAU::Table *t) : self(self), table(t) {}

    profile_t init_apply(const IR::Node* root) override {
        cont_writes.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::Expression *e) override {
        auto* originalField = self.phv.field(e);
        if (!originalField) return true;
        ordered_set<const PHV::Field*> candidateFields;
        candidateFields.insert(originalField);
        if (self.phv.getAliasMap().count(originalField))
            candidateFields.insert(self.phv.getAliasMap().at(originalField));
        for (const PHV::Field* field : candidateFields) {
            cstring field_name = field->name;
            if (isWrite()) {
                LOG3("update_access write " << field->name);
                auto &a = self.access[field->name];
                a.read.clear();
                a.write.clear();
                a.write.insert(table);
            } else {
                LOG3("update_access read " << field->name);
                self.access[field->name].read.insert(table);
            }
            if (isWrite() && self.phv.alloc_done()) {
                field->foreach_alloc([&](const PHV::Field::alloc_slice &sl) {
                    bitvec range(sl.container_bit, sl.width);
                    cont_writes[sl.container] |= range;
                });
            }
        }
        return false;
    }

    void end_apply() override {
        for (auto entry : cont_writes) {
            auto &cw = self.cont_write[entry.first];
            cw.emplace(table, entry.second);
        }
    }
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
        cont_write.clear();
    } else if (ctxt && dynamic_cast<const IR::MAU::Table *>(ctxt->node)) {
        const IR::MAU::Table* parent;
        parent = dynamic_cast<const IR::MAU::Table *>(ctxt->node);
        for (auto child : seq->tables) {
            dg.add_edge(parent, child, DependencyGraph::CONTROL); } }

    return true;
}

bool FindDependencyGraph::preorder(const IR::MAU::Table *t) {
    LOG3("FindDep table " << t->name);

    // Gather up the names of tables with which dependencies must be ignored, as defined by
    // @pragma ignore_table_dependency
    // Note that multiple ignore_table_dependency pragmas may be inserted for a given table and
    // therefore, we cannot use the get_single() accessor for annotations
    ordered_set<cstring> ignore_tables;
    if (t->match_table) {
        auto annot = t->match_table->getAnnotations();
        for (auto ann : annot->annotations) {
            if (ann->name.name != "ignore_table_dependency") continue;
            if (ann->expr.size() != 1) continue;
            auto tbl_name = ann->expr.at(0)->to<IR::StringLiteral>();
            if (!tbl_name) continue;
            // Due to P4_14 global name space, a dot is added to the initial table name
            auto value = tbl_name->value;
            ignore_tables.insert(value);
            value = "." + value;
            ignore_tables.insert(value);
        }
    }

    // TODO: add a pass in the beginning of the back end that checks for
    // duplicate table instances and, if found, aborts compilation.
    //     error("%s: Multiple applies of table %s not supported", t->srcInfo, t->name); }

    // Add this table as a vertex in the dependency graph if it's not
    // already there.
    dg.add_vertex(t);

    // Add data dependences induced by gateways, matches, and actions.
    for (auto &gw : t->gateway_rows)
        gw.first->apply(AddDependencies(*this, t, ignore_tables));
    for (auto ixbar_read : t->match_key)
        ixbar_read->apply(AddDependencies(*this, t, ignore_tables));
    for (auto &action : Values(t->actions))
        action->apply(AddDependencies(*this, t, ignore_tables));

    // Mark fields read/written by this table in accesses.
    // FIXME: Should have a separate gateway row IR to visit rather than other information
    for (auto &gw : t->gateway_rows)
        gw.first->apply(UpdateAccess(*this, t));

    // FIXME: Need to have this as part of the visitors on Actions, rather than on Attached
    // Tables, but these visitor information really needs to be cleaned up.
    t->apply(UpdateAttached(*this, t));
    return true;
}

bool FindDependencyGraph::preorder(const IR::MAU::InputXBarRead *read) {
    auto tbl = findContext<IR::MAU::Table>();
    read->apply(UpdateAccess(*this, tbl));
    return false;
}

bool FindDependencyGraph::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    act->apply(UpdateAccess(*this, tbl));
    return false;
}

template<class T>
inline std::set<T> &operator |=(std::set<T> &s, const std::set<T> &a) {
    s.insert(a.begin(), a.end());
    return s; }

void FindDependencyGraph::flow_dead() {
    access.clear();
    cont_write.clear();
}

void FindDependencyGraph::flow_merge(Visitor &v) {
    for (auto &a : dynamic_cast<FindDependencyGraph &>(v).access) {
        access[a.first].read |= a.second.read;
        access[a.first].write |= a.second.write;
    }

    for (auto &cw : dynamic_cast<FindDependencyGraph &>(v).cont_write) {
        for (auto entry : cw.second) {
            cont_write[cw.first][entry.first] |= entry.second;
        }
    }
}

/** Topological Sorting Algorithm, but
 *  return a vector of set of vertices, where,
 *  the index of the vector represent the min_stage of vertices in that set.
 *  i.e., generations of vertices sorted by the stage#.
 *
 *  Example:
 *  rst[0] = {A, B}
 *  rst[1] = {C, D}
 *  means that A, B could be in stage#0 and C, B could be in at least state#1.
 */
std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
FindDependencyGraph::calc_topological_stage() {
    typename DependencyGraph::Graph::vertex_iterator v, v_end;
    typename DependencyGraph::Graph::edge_iterator out, out_end;

    // Current in-degree of vertices
    std::map<DependencyGraph::Graph::vertex_descriptor, int> n_depending_on;

    // Build initial n_depending_on, and happens_after_map
    const auto& dep_graph = dg.g;
    std::map<const IR::MAU::Table*,
             std::set<const IR::MAU::Table*>> happens_after_map;
    auto& happens_before_map = dg.happens_before_map;
    for (boost::tie(v, v_end) = boost::vertices(dep_graph);
         v != v_end;
         ++v) {
        n_depending_on[*v] = 0;
        happens_after_map[dep_graph[*v]] = {};
        happens_before_map[dep_graph[*v]] = {}; }

    for (boost::tie(out, out_end) = boost::edges(dep_graph);
         out != out_end;
         ++out) {
        if (dep_graph[*out] != DependencyGraph::ANTI
            && dep_graph[*out] != DependencyGraph::CONTROL) {
            auto dst = boost::target(*out, dep_graph);
            n_depending_on[dst]++; } }

    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> rst;
    std::set<DependencyGraph::Graph::vertex_descriptor> processed;
    while (processed.size() < num_vertices(dep_graph)) {
        std::set<DependencyGraph::Graph::vertex_descriptor> this_generation;
        // Select vertices of those current in-degree is 0 as members of this_generation.
        // as long as they have not been processed yet.
        for (auto& kv : n_depending_on) {
            if (!processed.count(kv.first) && kv.second == 0)
                this_generation.insert(kv.first); }
        // There are remaining vertices, so it must be a loop.
        if (this_generation.size() == 0) {
            ::error("There is a loop in the table dependency graph.");
            break; }
        // Remove out-edge destination of these vertices.
        for (auto& v : this_generation) {
            auto out_edge_itr_pair = out_edges(v, dep_graph);
            auto& out = out_edge_itr_pair.first;
            auto& out_end = out_edge_itr_pair.second;
            const auto* table = dep_graph[v];
            for (; out != out_end; ++out) {
                if (dep_graph[*out] != DependencyGraph::ANTI
                    && dep_graph[*out] != DependencyGraph::CONTROL) {
                    auto vertex_later = boost::target(*out, dep_graph);
                    auto table_later = dep_graph[vertex_later];
                    happens_after_map[table_later].insert(table);
                    happens_after_map[table_later].insert(happens_after_map[table].begin(),
                                                          happens_after_map[table].end());
                    n_depending_on[vertex_later]--; } } }

        processed.insert(this_generation.begin(), this_generation.end());
        rst.emplace_back(std::move(this_generation));
    }

    for (const auto& kv : happens_after_map) {
        auto* table = kv.first;
        for (const auto* prev : kv.second) {
            happens_before_map[prev].insert(table); } }

    return rst;
}

void FindDependencyGraph::finalize_dependence_graph(void) {
    typename DependencyGraph::Graph::vertex_iterator v, v_end;
    typename DependencyGraph::Graph::edge_iterator out, out_end;

    // Topological sort
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
        topo_rst = calc_topological_stage();

    if (LOGGING(3)) {
        for (size_t i = 0; i < topo_rst.size(); ++i) {
            LOG3(">>> Stage#" << i << ":");
            for (const auto& vertex : topo_rst[i]) {
                LOG3("Tabel:  " << vertex << ", " << dg.g[vertex]->name); } } }

    // Build min_stage
    for (size_t i = 0; i < topo_rst.size(); ++i) {
        for (const auto& vertex : topo_rst[i]) {
            const IR::MAU::Table* table = dg.g[vertex];
            dg.stage_info[table].min_stage = i; } }

    // Build dep_stages
    for (int i = int(topo_rst.size()) - 1; i >= 0; --i) {
        for (const auto& vertex : topo_rst[i]) {
            const IR::MAU::Table* table = dg.g[vertex];
            auto& happens_later = dg.happens_before_map[table];
            dg.stage_info[table].dep_stages =
                std::accumulate(happens_later.begin(), happens_later.end(), 0,
                                [this] (int sz, const IR::MAU::Table* later) {
                                    return std::max(sz, dg.stage_info[later].dep_stages + 1); });
        } }

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
        if ((t1->gress == EGRESS && t2->gress == INGRESS)
            || (t1->gress == INGRESS && t2->gress == EGRESS))
            BUG("Ingress table '%s' depends on egress table '%s'.", t1->name, t2->name); }
}
