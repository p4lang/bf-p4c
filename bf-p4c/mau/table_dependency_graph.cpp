#include "bf-p4c/mau/table_dependency_graph.h"
#include <assert.h>
#include <boost/graph/breadth_first_search.hpp>
#include <boost/optional.hpp>
#include <algorithm>
#include <numeric>
#include <sstream>
#include "bf-p4c/ir/tofino_write_context.h"
#include "table_injected_deps.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"

static const char* dep_types(DependencyGraph::dependencies_t dep) {
    switch (dep) {
        case DependencyGraph::CONTROL: return "CONTROL";
        case DependencyGraph::IXBAR_READ: return "IXBAR_READ";
        case DependencyGraph::ACTION_READ: return "ACTION_READ";
        case DependencyGraph::ANTI: return "ANTI";
        case DependencyGraph::OUTPUT: return "OUTPUT";
        case DependencyGraph::REDUCTION_OR_READ: return "REDUCTION_OR_READ";
        case DependencyGraph::REDUCTION_OR_OUTPUT: return "REDUCTION_OR_OUTPUT";
        default: return "UNKNOWN";
    }
}

std::ostream &operator<<(std::ostream &out, const DependencyGraph &dg) {
    out << "GRAPH" << std::endl;
    DependencyGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(dg.g);
         edges != edges_end;
         ++edges) {
        auto src = boost::source(*edges, dg.g);
        const IR::MAU::Table* source = dg.get_vertex(src);
        auto dst = boost::target(*edges, dg.g);
        const IR::MAU::Table* target = dg.get_vertex(dst);
        out << "    " << source->name << " -- " << dep_types(dg.g[*edges]) << " --> " <<
            target->name << std::endl; }

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
    AddDependencies(FindDependencyGraph &self,
                    const IR::MAU::Table *t,
                    ordered_set<cstring>& t1) :
        self(self), table(t), ignoreDep(t1) { }

 private:
    profile_t init_apply(const IR::Node* root) override {
        cont_writes.clear();
        return Inspector::init_apply(root);
    }

    void addDeps(ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> tables,
                 DependencyGraph::dependencies_t dep, const PHV::Field *field) {
        for (auto upstream_t_pair : tables) {
            auto upstream_t = upstream_t_pair.first;
            if (upstream_t->match_table
                && ignoreDep.count(upstream_t->match_table->externalName())) {
                LOG3("Ignoring dependency from " << upstream_t->name << " to " << table->name);
                continue;
            }
            auto edge_pair = self.dg.add_edge(upstream_t, table, dep);
            const IR::MAU::Action *action_use_context = findContext<IR::MAU::Action>();
            self.dg.data_annotations[edge_pair.first][field].first.insert(upstream_t_pair.second);
            self.dg.data_annotations[edge_pair.first][field].second.insert(action_use_context);
        }
    }

    void addContDeps(ordered_map<const IR::MAU::Table *, bitvec> tables, bitvec range,
            PHV::Container container) {
        for (auto upstream_t : tables) {
            if (upstream_t.first->match_table &&
                    ignoreDep.count(upstream_t.first->match_table->externalName())) {
                WARN_CHECK(upstream_t.second == range, "Table %s's pragma ignore_table_dependency "
                           "of %s is also ignoring PHV added action dependencies over container "
                           "%s, which may not have been the desired outcome", table->name,
                            upstream_t.first->name, container.toString());
                continue;
            }
            LOG3("Adding container conflict between table " << upstream_t.first->name << " and "
                 << "table " << table->name << " because of container " << container);
            self.dg.container_conflicts[upstream_t.first].insert(table);
            self.dg.container_conflicts[table].insert(upstream_t.first);
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
                    addDeps(self.access[field->name].ixbar_read, DependencyGraph::ANTI, field);
                    addDeps(self.access[field->name].action_read, DependencyGraph::ANTI, field);
                    // Write-after-write dependence.
                    if (isReductionOr()) {
                        addDeps(self.access[field->name].reduction_or_write,
                                DependencyGraph::REDUCTION_OR_OUTPUT, field);
                    } else {
                        addDeps(self.access[field->name].write, DependencyGraph::OUTPUT, field);
                    }
                } else {
                    // Read-after-write dependence.
                    if (isIxbarRead()) {
                        addDeps(self.access[field->name].write,
                                DependencyGraph::IXBAR_READ, field);
                    } else if (isReductionOr()) {
                        addDeps(self.access[field->name].reduction_or_read,
                                DependencyGraph::REDUCTION_OR_READ, field);
                    } else {
                        addDeps(self.access[field->name].write,
                                DependencyGraph::ACTION_READ, field);
                    }
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

    bool preorder(const IR::MAU::StatefulCall *) override {
        return false;
    }

    bool preorder(const IR::MAU::Instruction *) override {
        return true;
    }

    void end_apply() override {
        for (auto entry : cont_writes) {
            addContDeps(self.cont_write[entry.first], entry.second, entry.first);
        }
        for (auto& edge_map_pair : self.dg.data_annotations) {
            for (auto& kv : edge_map_pair.second) {
                kv.second.first.erase(nullptr);
                kv.second.second.erase(nullptr);
            }
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

    // Don't track dependencies of items from
    // attached tables left as primitives by exploring
    // via the primitive. Instead track them by exploring
    // the attached tables directly.
    bool preorder(const IR::MAU::StatefulCall *) override {
        return false;
    }

    // We do still want to explore instructions.
    bool preorder(const IR::MAU::Instruction *) override {
        return true;
    }

    bool preorder(const IR::Expression *e) override {
        auto* originalField = self.phv.field(e);
        if (!originalField) return true;
        ordered_set<const PHV::Field*> candidateFields;
        candidateFields.insert(originalField);
        if (self.phv.getAliasMap().count(originalField))
            candidateFields.insert(self.phv.getAliasMap().at(originalField));

        // This will often be null for expressions that don't appear within actions
        const IR::MAU::Action *action_context = findContext<IR::MAU::Action>();

        for (const PHV::Field* field : candidateFields) {
            if (isWrite()) {
                LOG3("update_access write " << field->name);
                auto &a = self.access[field->name];
                a.ixbar_read.clear();
                a.action_read.clear();
                a.reduction_or_write.clear();
                a.reduction_or_read.clear();
                a.write.clear();
                if (isReductionOr()) {
                    self.access[field->name].reduction_or_write.insert(
                        std::make_pair(table, action_context));
                } else {
                    a.write.insert(std::make_pair(table, action_context));
                }
            } else {
                LOG3("update_access read " << field->name);
                if (isIxbarRead()) {
                    self.access[field->name].ixbar_read.insert(
                        std::make_pair(table, action_context));
                } else if (isReductionOr()) {
                    self.access[field->name].reduction_or_read.insert(
                        std::make_pair(table, action_context));
                } else {
                    self.access[field->name].action_read.insert(
                        std::make_pair(table, action_context));
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

    void end_apply() override {
        for (auto entry : cont_writes) {
            auto &cw = self.cont_write[entry.first];
            cw.emplace(table, entry.second);
        }
    }
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
            dg.add_edge(parent, child, DependencyGraph::CONTROL);
        }
    }

    return true;
}

bool FindDependencyGraph::preorder(const IR::BFN::Pipe *pipe) {
    pipe->apply(TableFindInjectedDependencies(dg));
    // pipe->apply(TableFindInjectedDependencies(dg, EGRESS));
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
    for (auto &at : t->attached)
        at->apply(AddDependencies(*this, t, ignore_tables));

    // Mark fields read/written by this table in accesses.
    // FIXME: Should have a separate gateway row IR to visit rather than other information
    for (auto &gw : t->gateway_rows)
        gw.first->apply(UpdateAccess(*this, t));

    // FIXME: Need to have this as part of the visitors on Actions, rather than on Attached
    // Tables, but these visitor information really needs to be cleaned up.
    for (auto &at : t->attached)
        at->apply(UpdateAccess(*this, t));

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
        access[a.first].ixbar_read |= a.second.ixbar_read;
        access[a.first].action_read |= a.second.action_read;
        access[a.first].write |= a.second.write;
        access[a.first].reduction_or_write |= a.second.reduction_or_write;
        access[a.first].reduction_or_read |= a.second.reduction_or_read;
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
FindDependencyGraph::calc_topological_stage(unsigned dep_flags) {
    typename DependencyGraph::Graph::vertex_iterator v, v_end;
    typename DependencyGraph::Graph::edge_iterator out, out_end;

    bool include_control = dep_flags & DependencyGraph::CONTROL;
    bool include_anti = dep_flags & DependencyGraph::ANTI;

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
        const IR::MAU::Table* label_table = dg.get_vertex(*v);
        happens_after_map[label_table] = {};
        happens_before_map[label_table] = {}; }

    for (boost::tie(out, out_end) = boost::edges(dep_graph);
         out != out_end;
         ++out) {
        if ((include_anti || dep_graph[*out] != DependencyGraph::ANTI)
            && (include_control || dep_graph[*out] != DependencyGraph::CONTROL)
            && dep_graph[*out] != DependencyGraph::REDUCTION_OR_OUTPUT
            && dep_graph[*out] != DependencyGraph::REDUCTION_OR_READ) {
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
            LOG2(dg);
            ::error("There is a loop in the table dependency graph.");
            break; }
        // Remove out-edge destination of these vertices.
        for (auto& v : this_generation) {
            auto out_edge_itr_pair = out_edges(v, dep_graph);
            auto& out = out_edge_itr_pair.first;
            auto& out_end = out_edge_itr_pair.second;
            const auto* table = dg.get_vertex(v);
            for (; out != out_end; ++out) {
                if ((include_anti || dep_graph[*out] != DependencyGraph::ANTI)
                    && (include_control || dep_graph[*out] != DependencyGraph::CONTROL)
                    && dep_graph[*out] != DependencyGraph::REDUCTION_OR_OUTPUT
                    && dep_graph[*out] != DependencyGraph::REDUCTION_OR_READ) {
                    auto vertex_later = boost::target(*out, dep_graph);
                    const auto* table_later = dg.get_vertex(vertex_later);
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
    // Topological sort
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
        topo_rst = calc_topological_stage();


    if (LOGGING(3)) {
        for (size_t i = 0; i < topo_rst.size(); ++i) {
            LOG3(">>> Stage#" << i << ":");
            for (const auto& vertex : topo_rst[i])
                LOG3("Table:  " << vertex << ", " << dg.get_vertex(vertex)->name);
        }
    }


    // Build dep_stages
    for (int i = int(topo_rst.size()) - 1; i >= 0; --i) {
        for (const auto& vertex : topo_rst[i]) {
            const IR::MAU::Table* table = dg.get_vertex(vertex);
            auto& happens_later = dg.happens_before_map[table];
            dg.stage_info[table].dep_stages =
                std::accumulate(happens_later.begin(), happens_later.end(), 0,
                                [this] (int sz, const IR::MAU::Table* later) {
                                    return std::max(sz, dg.stage_info[later].dep_stages + 1); });
        }
    }

    typename DependencyGraph::Graph::edge_iterator edges, edges_end;
    dg.dep_type_map.clear();
    for (boost::tie(edges, edges_end) = boost::edges(dg.g); edges != edges_end; ++edges) {
        const IR::MAU::Table* src = dg.get_vertex(boost::source(*edges, dg.g));
        const IR::MAU::Table* dst = dg.get_vertex(boost::target(*edges, dg.g));
        if ((dg.dep_type_map.count(src) == 0) || (dg.dep_type_map.at(src).count(dst) == 0)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::CONTROL)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::REDUCTION_OR_READ)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::REDUCTION_OR_OUTPUT)) {
            if (dg.g[*edges] != DependencyGraph::ANTI) {
                dg.dep_type_map[src][dst] = dg.g[*edges];
            }
        }
    }

    // Build dep_stages_control
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
        topo_rst_control = calc_topological_stage(DependencyGraph::CONTROL);
    for (int i = int(topo_rst_control.size()) - 1; i >= 0; --i) {
        for (const auto& vertex : topo_rst_control[i]) {
            const IR::MAU::Table* table = dg.get_vertex(vertex);
            auto& happens_later = dg.happens_before_map[table];
            dg.stage_info[table].dep_stages_control = std::accumulate(happens_later.begin(),
                happens_later.end(), 0, [this, table] (int sz, const IR::MAU::Table* later) {
                    int stage_addition = 0;
                    if (dg.dep_type_map.count(table) && dg.dep_type_map.at(table).count(later)
                        && dg.dep_type_map.at(table).at(later) != DependencyGraph::CONTROL
                        && dg.dep_type_map.at(table).at(later) !=
                           DependencyGraph::REDUCTION_OR_READ
                        && dg.dep_type_map.at(table).at(later) !=
                           DependencyGraph::REDUCTION_OR_OUTPUT) {
                            if (dg.dep_type_map.at(table).at(later) == DependencyGraph::ANTI) {
                                LOG3("Adding stage from anti");
                            }
                            stage_addition = 1;
                    }
                    return std::max(sz, dg.stage_info[later].dep_stages_control + stage_addition);
            });
            LOG3("Dep stages of " << dg.stage_info[table].dep_stages <<
                " for table " << table->name);
            LOG3("Dep stages control of " << dg.stage_info[table].dep_stages_control <<
                " for table " << table->name);
        }
    }

    // Build min_stage
    // Min_stage for a table T is the minimum stage in which T (and any table that T is
    // control-dependent upon) can be placed. So, if table T2 has no match or action dependencies
    // but is control dependent on table T1, which -- because of its own match and action
    // dependencies -- must be placed in at least stage 4, then T2 and T1 will both have a
    // min_stage of 4.
    for (size_t i = 0; i < topo_rst_control.size(); ++i) {
        for (const auto& vertex : topo_rst_control[i]) {
            const IR::MAU::Table* table = dg.get_vertex(vertex);
            dg.stage_info[table].min_stage = i;
        }
    }

    // Compress the stages to take out the addition caused by control edges
    for (size_t i = 1; i < topo_rst_control.size(); i++) {
        for (const auto& vertex : topo_rst_control[i]) {
            const auto* tbl = dg.get_vertex(vertex);
            int orig_stage = dg.stage_info[tbl].min_stage;
            int true_min_stage = 0;
            auto in_edges = boost::in_edges(vertex, dg.g);
            for (auto edge = in_edges.first; edge != in_edges.second; edge++) {
                auto src_vertex = boost::source(*edge, dg.g);
                const auto* src_table = dg.get_vertex(src_vertex);
                int src_vertex_stage = dg.stage_info[src_table].min_stage;
                if (dg.g[*edge] == DependencyGraph::ACTION_READ ||
                    dg.g[*edge] == DependencyGraph::IXBAR_READ ||
                    dg.g[*edge] == DependencyGraph::OUTPUT) {
                    true_min_stage = std::max(true_min_stage, src_vertex_stage + 1);
                } else if (dg.g[*edge] == DependencyGraph::CONTROL ||
                           dg.g[*edge] == DependencyGraph::REDUCTION_OR_READ ||
                           dg.g[*edge] == DependencyGraph::REDUCTION_OR_OUTPUT) {
                    true_min_stage = std::max(true_min_stage, src_vertex_stage);
                }
                BUG_CHECK(true_min_stage <= orig_stage, "stage should only decrease");
                // There shouldn't be any edges within a layer,
                // so starting from the lowest stage and moving out should be fine
            }
            dg.stage_info[tbl].min_stage = true_min_stage;
        }
    }

    // dg.happens_before_control_map = dg.happens_before_map;
    for (const auto& kv : dg.happens_before_map) {
        auto* table = kv.first;
        for (const auto* prev : kv.second) {
            dg.happens_before_control_map[prev].insert(table); } }
    if (LOGGING(3)) {
        std::stringstream ss;
        for (auto& kv : dg.happens_before_control_map) {
            ss << "Table " << kv.first->name << " has priors of ";
            for (auto& tbl : kv.second) {
                ss << tbl->name << ", ";
            }
            ss << "\n";
            LOG3(ss.str());
        }
        for (auto& kv_outer : dg.dep_type_map) {
            for (auto& kv_inner : kv_outer.second) {
                auto* initial_table = kv_outer.first;
                auto* later_table = kv_inner.first;
                auto value = kv_inner.second;
                LOG3("Initial table " << initial_table->name << " with later table "
                    << later_table->name << " and value " << value);
            }
        }
    }

    // Calculate dg.happens_before_control_anti_map
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> topo_rst_control_anti =
        calc_topological_stage(DependencyGraph::CONTROL | DependencyGraph::ANTI);
    if (LOGGING(3)) {
        LOG3("Printing results of topological sorting with control and anti dependences included");
        for (size_t i = 0; i < topo_rst_control_anti.size(); ++i) {
            LOG3(">>> Stage#" << i << ":");
            for (const auto& vertex : topo_rst_control_anti[i]) {
                const auto* t = dg.get_vertex(vertex);
                LOG3("Table: " << vertex << ", " << t->name);
            }
        }
    }
    for (const auto& kv : dg.happens_before_map)
        dg.happens_before_control_anti_map[kv.first].insert(kv.second.begin(), kv.second.end());

    if (LOGGING(3)) {
        std::stringstream ss;
        for (auto& kv : dg.happens_before_control_anti_map) {
            ss << "Table " << kv.first->name << " has priors of ";
            for (auto& tbl : kv.second)
                ss << tbl->name << ", ";
            ss << std::endl;
            LOG3(ss.str());
        }
    }

    calc_topological_stage();

    verify_dependence_graph();
    dg.finalized = true;
}

void FindDependencyGraph::verify_dependence_graph() {
    typename DependencyGraph::Graph::edge_iterator out, out_end;
    for (boost::tie(out, out_end) = boost::edges(dg.g);
         out != out_end;
         ++out) {
        const IR::MAU::Table *t1 = dg.get_vertex(boost::source(*out, dg.g));
        const IR::MAU::Table *t2 = dg.get_vertex(boost::target(*out, dg.g));
        if ((t1->gress == EGRESS && t2->gress == INGRESS)
            || (t1->gress == INGRESS && t2->gress == EGRESS))
            BUG("Ingress table '%s' depends on egress table '%s'.", t1->name, t2->name); }
}
