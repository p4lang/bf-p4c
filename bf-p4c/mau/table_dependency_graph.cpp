#include "bf-p4c/mau/table_dependency_graph.h"
#include <assert.h>
#include <boost/graph/breadth_first_search.hpp>
#include <boost/optional.hpp>
#include <algorithm>
#include <numeric>
#include <sstream>
#include "bf-p4c/common/run_id.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/logging/manifest.h"
#include "table_injected_deps.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/ir/table_tree.h"
#include "ir/ir.h"
#include "lib/cstring.h"
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


    out << "MIN STAGE INFO" << std::endl;
    out << "    Each table also indicates its dependency chain length" << std::endl;

    std::map<int, safe_vector<std::pair<const IR::MAU::Table *, int>>> min_stage_info;
    for (auto &kv : dg.stage_info) {
        min_stage_info[kv.second.min_stage].emplace_back(kv.first,
                                                         kv.second.dep_stages_control_anti);
    }

    for (auto &msi : min_stage_info) {
        out << " Stage #" << msi.first << std::endl;
        for (auto val : msi.second) {
            out << "     " << val.first->name << " " << val.second << std::endl;
            if (!dg.display_min_edges)
                continue;
            if (dg.min_stage_edges.count(val.first) == 0)
                continue;
            for (auto edge : dg.min_stage_edges.at(val.first)) {
                out << "\t- Edge " << dep_types(edge.second) << " " << edge.first->name
                    << std::endl;
            }
        }
    }

    return out;
}

void DependencyGraph::dump_viz(std::ostream &out, const DependencyGraph &dg) {
    static std::map<DependencyGraph::dependencies_t, std::pair<cstring, cstring>> dep_color = {
        { DependencyGraph::CONTROL, std::make_pair("Control", "green") },
        { DependencyGraph::IXBAR_READ, std::make_pair("IXBar read", "blue") },
        { DependencyGraph::ACTION_READ, std::make_pair("Action read", "red") },
        { DependencyGraph::ANTI, std::make_pair("Anti", "brown") },
        { DependencyGraph::OUTPUT, std::make_pair("Output", "navy") },
        { DependencyGraph::REDUCTION_OR_READ, std::make_pair("ReductionOR read", "cyan") },
        { DependencyGraph::REDUCTION_OR_OUTPUT, std::make_pair("ReductionOR output", "pink") },
        { DependencyGraph::CONCURRENT, std::make_pair("Concurrent", "black") }
    };

    auto tableName = [](const IR::MAU::Table *tbl) {
        if (tbl) {
            if (tbl->match_table)
                return tbl->match_table->externalName();
            else
                return tbl->name;
        } else {
            return cstring("SINK");
        }
    };

    auto edgeName = [dg](const IR::MAU::Table *source, const IR::MAU::Table *dest) {
        auto depInfo = dg.get_data_dependency_info(source, dest);
        cstring res("");
        if (depInfo == boost::none) return res;
        for (auto d : depInfo.get()) {
            // the PHV field name
            res += d.first.first->name + "\n";
        }
        return res;
    };

    auto all_vertices = boost::vertices(dg.g);
    if (++all_vertices.first == all_vertices.second) {
        out << "digraph empty {\n}" << std::endl;
        return;
    }
    ordered_map<std::pair<cstring, cstring>, ordered_set<cstring>> name_pairs;
    ordered_map<int, std::set<cstring>> tables_per_stage;
    // order the tables by stage
    for (auto ts : dg.stage_info)
        tables_per_stage[ts.second.min_stage].insert(tableName(ts.first));

    out << "digraph table_deps {" << std::endl
        << "  splines=ortho; rankdir=LR;" << std::endl
        << "  label=\"Program: " << BackendOptions().programName << "\n"
        << "RunId: " << RunId::getId() << "\n\";" << std::endl
        << "  labelloc=t; labeljust=l;" << std::endl;
    // print the root nodes, ranked by the stage
    bool first = true;
    for (auto tables : tables_per_stage) {
        out << "  { ";
        if (!first) out << "rank = same; ";
        else        first = false;
        for (auto t : tables.second) out << "\"" << t << "\"; ";
        out << "}" << std::endl;
    }

    // list the edges
    DependencyGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(dg.g); edges != edges_end; ++edges) {
        auto src = boost::source(*edges, dg.g);
        const IR::MAU::Table* source = dg.get_vertex(src);
        auto dst = boost::target(*edges, dg.g);
        const IR::MAU::Table* target = dg.get_vertex(dst);
        auto src_name = tableName(source);
        auto dst_name = tableName(target);
        cstring edge_name = dep_types(dg.g[*edges]);
        auto p = std::make_pair(src_name.c_str(), dst_name.c_str());
        name_pairs[p].insert(edge_name);
        out << "   \"" << src_name.c_str() << "\" -> \"" <<
            dst_name.c_str() << "\" [ " <<
            "label= \"" << edgeName(source, target) << "\"," <<
            "color=" << dep_color[dg.g[*edges]].second << " ];" << std::endl;
    }

    // Print the legend
    out << "  { rank=max;" << std::endl;
    out << "    subgraph cluster_legend { node [ shape=record; fontsize=10];" << std::endl
        << "      empty [label=<<table border=\"0\" cellborder=\"0\">"
        << "<tr><td colspan=\"8\">Edge colors</td></tr><tr>";
    for (auto c : dep_color)
        out << "<td><font color=\"" << c.second.second << "\">"
            << c.second.first << "</font></td>";
    out << "</tr></table>>;]" << std::endl;
    out << "    }" << std::endl;  // end subgraph
    out << "  }" << std::endl;    // end legend block
    out << "}" << std::endl;      // end digraph

    if (!LOGGING(4))
        return;  // generate other types of graphs only if dumping to console
    out << "digraph table_deps_merged {" << std::endl;
    for (auto& kv : name_pairs) {
        auto table_pair = kv.first;
        auto edges = kv.second;
        out << "    \"" << table_pair.first << "\" -> \"" <<
            table_pair.second << "\" [ label= \"";
        const char* sep = "";
        for (auto& edge : edges) {
            out << sep << edge;
            sep = ",\n";
        }
        out << "\" ];" << std::endl;
    }
    out << "}" << std::endl;
    out << "digraph table_deps_simple {" << std::endl;
    for (auto& kv : name_pairs) {
        auto table_pair = kv.first;
        auto edges = kv.second;
        ordered_set<cstring> simple_edges;
        for (auto& edge : edges) {
            if (edge == "ANTI") {
                continue;
            } else if (edge == "IXBAR_READ" || edge == "ACTION_READ" || edge == "OUTPUT") {
                simple_edges.insert("DATA");
            } else if (edge == "REDUCTION_OR_OUTPUT" || edge == "REDUCTION_OR_READ") {
                simple_edges.insert("REDUCTION_OR");
            } else if (edge == "CONTROL") {
                simple_edges.insert("CONTROL");
            } else {
                simple_edges.insert("UNKNOWN");
            }
        }
        out << "    \"" << table_pair.first << "\" -> \"" <<
            table_pair.second << "\" [ label= \"";
        const char* sep = "";
        for (auto& edge : simple_edges) {
            out << sep << edge;
            sep = ",\n";
        }
        cstring color = "black";
        if (simple_edges.count("DATA") && simple_edges.count("CONTROL"))
            color = "blue";
        else if (simple_edges.count("DATA"))
            color = "red";
        else if (simple_edges.count("CONTROL"))
            color = "green";
        out << "\",color=" << color << " ];" << std::endl;
    }
    out << "}" << std::endl;
}

/**
 * The reduction or dependencies must be tracked so that all tables that are in the same
 * reduction or group do not have any dependencies between them, but they as a block do
 * have dependencies with any other standard reads or writes.
 *
 * Thus when a reduction or is found, it is established whether or not the previous write
 * was the same reduction or group.  If so, no data dependency is added, but if not, then
 * this table is data dependent with this table.
 */
class FindDataDependencyGraph::AddDependencies : public MauInspector, TofinoWriteContext {
    FindDataDependencyGraph                 &self;
    const IR::MAU::Table                *table;
    const ordered_set<cstring>&         ignoreDep;
    std::map<PHV::Container, bitvec>    cont_writes;

 public:
    AddDependencies(FindDataDependencyGraph &self,
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
                LOG4("\tIgnoring dependency from " << upstream_t->name << " to " << table->name);
                continue;
            }
            auto edge_pair = self.dg.add_edge(upstream_t, table, dep);
            LOG5("\tAdd " << dep_types(dep) << " dependency from " << upstream_t->name << " to " <<
                 table->name << " because of field " << field->name);
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
                WARN_CHECK(upstream_t.second == range, BFN::ErrorType::WARN_PRAGMA_USE,
                           "Table %1%: pragma ignore_table_dependency "
                           "of %2% is also ignoring PHV added action dependencies over container "
                           "%3%, which may not have been the desired outcome", table,
                            upstream_t.first->name, container.toString());
                continue;
            }
            LOG5("\tAdd container conflict between table " << upstream_t.first->name
                 << " and table " << table->name << " because of container " << container);
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
            cstring red_or_key;
            bool is_red_or = self.red_info.is_reduction_or(findContext<IR::MAU::Instruction>(),
                                                           table, red_or_key);
            bool non_first_write_red_or = false;
            if (self.access.count(field_name)) {
                LOG6("\t\tadd_dependency(" << field_name << ")");
                if (isWrite()) {
                    // Write-after-read dependence.
                    addDeps(self.access[field->name].ixbar_read, DependencyGraph::ANTI, field);
                    addDeps(self.access[field->name].action_read, DependencyGraph::ANTI, field);
                    // Write-after-write dependence.
                    if (is_red_or) {
                        auto pos = self.red_or_use.find(field->name);
                        // If reduction_or, and the previous write was a reduction_or
                        if (pos != self.red_or_use.end()) {
                            ERROR_CHECK(pos->second == red_or_key, "%s: "
                            "The reduction_or groups collide on field %s, over group %s and "
                            "group %s", table->srcInfo, field->name, red_or_key, pos->second);
                            addDeps(self.access[field->name].reduction_or_write,
                                    DependencyGraph::REDUCTION_OR_OUTPUT, field);
                            non_first_write_red_or = true;
                        } else {
                            // If reduction_or and previous write was not reduction_or
                            addDeps(self.access[field->name].write, DependencyGraph::OUTPUT, field);
                        }
                    } else {
                        // If normal
                        addDeps(self.access[field->name].write, DependencyGraph::OUTPUT, field);
                    }
                } else {
                    // Read-after-write dependence.
                    if (isIxbarRead()) {
                        addDeps(self.access[field->name].write,
                                DependencyGraph::IXBAR_READ, field);
                    } else if (is_red_or) {
                        // If reduction_or, and the previous write was a reduction_or
                        auto pos = self.red_or_use.find(field->name);
                        if (pos != self.red_or_use.end()) {
                            ERROR_CHECK(pos->second == red_or_key, "%s: "
                            "The reduction_or groups collide on field %s, over group %s and "
                            "group %s", table->srcInfo, field->name, red_or_key, pos->second);
                            addDeps(self.access[field->name].reduction_or_write,
                                    DependencyGraph::REDUCTION_OR_READ, field);
                        } else {
                            // If reduction_or, and the previous write was normal
                            addDeps(self.access[field->name].write, DependencyGraph::ACTION_READ,
                                    field);
                        }
                    } else {
                        // If normal
                        addDeps(self.access[field->name].write,
                                DependencyGraph::ACTION_READ, field);
                    }
                }
            }
            if (isWrite() && !non_first_write_red_or && self.phv.alloc_done()) {
                /// FIXME(cc): Do we need to restrict the context here, or is it always the
                /// whole pipeline?
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

class FindDataDependencyGraph::UpdateAccess : public MauInspector , TofinoWriteContext {
    FindDataDependencyGraph                &self;
    const IR::MAU::Table               *table;
    std::map<PHV::Container, bitvec>    cont_writes;

 public:
    UpdateAccess(FindDataDependencyGraph &self, const IR::MAU::Table *t) : self(self), table(t) {}

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
            cstring red_or_key;
            auto &a = self.access[field->name];
            if (isWrite()) {
                LOG6("\t\tupdate_access write " << field->name);
                a.ixbar_read.clear();
                a.action_read.clear();
                a.reduction_or_write.clear();
                a.reduction_or_read.clear();
                a.write.clear();
                bool is_red_or = self.red_info.is_reduction_or(
                                                   findContext<IR::MAU::Instruction>(),
                                                    table, red_or_key);
                if (is_red_or) {
                    a.reduction_or_write.insert(std::make_pair(table, action_context));
                    self.red_or_use[field->name] = red_or_key;
                } else if (self.red_or_use.count(field->name)) {
                    self.red_or_use.erase(self.red_or_use.find(field->name));
                }
                a.write.insert(std::make_pair(table, action_context));
            } else {
                LOG6("\t\tupdate_access read " << field->name);
                if (isIxbarRead()) {
                    self.access[field->name].ixbar_read.insert(
                        std::make_pair(table, action_context));
                } else {
                    bool is_red_or = self.red_info.is_reduction_or(
                                                       findContext<IR::MAU::Instruction>(),
                                                       table, red_or_key);
                    if (is_red_or) {
                        a.reduction_or_read.insert(std::make_pair(table, action_context));
                    }
                    a.action_read.insert(std::make_pair(table, action_context));
                }
            }
            if (isWrite() && self.phv.alloc_done()) {
                /// FIXME(cc): Do we need to restrict the context here, or is it always the
                /// whole pipeline?
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

bool FindDataDependencyGraph::preorder(const IR::MAU::TableSeq * /* seq */) {
    const Context *ctxt = getContext();
    if (ctxt && ctxt->node->is<IR::BFN::Pipe>()) {
        access.clear();
        cont_write.clear();
    }

    return true;
}

bool FindDataDependencyGraph::preorder(const IR::MAU::Table *t) {
    LOG5("\tFindDep table " << t->name);

    // Gather up the names of tables with which dependencies must be ignored, as defined by
    // @pragma ignore_table_dependency
    // Note that multiple ignore_table_dependency pragmas may be inserted for a given table and
    // therefore, we cannot use the get_single() accessor for annotations
    std::vector<IR::ID> annotation;
    ordered_set<cstring> ignore_tables;
    t->getAnnotation("ignore_table_dependency", annotation);
    for (auto name : annotation) {
        // Due to P4_14 global name space, a dot is added to the initial table name
        ignore_tables.insert(name);
        ignore_tables.insert("." + name); }

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

bool FindDataDependencyGraph::preorder(const IR::MAU::TableKey *read) {
    auto tbl = findContext<IR::MAU::Table>();
    read->apply(UpdateAccess(*this, tbl));
    return false;
}

bool FindDataDependencyGraph::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    act->apply(UpdateAccess(*this, tbl));
    return false;
}

template<class T>
inline std::set<T> &operator |=(std::set<T> &s, const std::set<T> &a) {
    s.insert(a.begin(), a.end());
    return s; }

void FindDataDependencyGraph::flow_merge(Visitor &v) {
    for (auto &a : dynamic_cast<FindDataDependencyGraph &>(v).access) {
        access[a.first].ixbar_read |= a.second.ixbar_read;
        access[a.first].action_read |= a.second.action_read;
        access[a.first].write |= a.second.write;
        access[a.first].reduction_or_write |= a.second.reduction_or_write;
        access[a.first].reduction_or_read |= a.second.reduction_or_read;
    }

    for (auto &r : dynamic_cast<FindDataDependencyGraph &>(v).red_or_use) {
        red_or_use[r.first] = r.second;
    }

    for (auto &cw : dynamic_cast<FindDataDependencyGraph &>(v).cont_write) {
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
 *
 * FIXME -- the above comment appears to be completely wrong -- the indexes have
 * nothing to do with the possible stages tables can be placed in.  Instead, the
 * indexes appear to be the depth of the table in the table dependency graph.  The
 * resulting vector is generally used to do a breadth-first traversal of the tables
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
    auto& happens_after_map = dg.happens_after_map;
    auto& happens_before_map = dg.happens_before_map;
    happens_after_map.clear();
    happens_before_map.clear();
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
        // There are no remaining vertices, so it must be a loop.
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
                    n_depending_on[vertex_later]--;
                }
            }
         }

        processed.insert(this_generation.begin(), this_generation.end());
        rst.emplace_back(std::move(this_generation));
    }

    for (const auto& kv : happens_after_map) {
        auto* table = kv.first;
        for (const auto* prev : kv.second) {
            happens_before_map[prev].insert(table); } }
    return rst;
}

/**
 * The purpose of this class is to gather for each table (in Tofino), the set of tables
 * that must be placed due to next table propagation.  Both the leaves as well as the total
 * direct control dominating set are calculated.
 *
 * One cannot use the DependencyGraph to calculate this, as the inject control dependencies
 * calculated in InjectControlDependencies are not what the next table needs to propagate
 * through before the table can fully be placed.
 */
void CalculateNextTableProp::postorder(const IR::MAU::Table *tbl) {
    bool empty_seq = true;
    for (auto seq : Values(tbl->next)) {
        empty_seq &= seq->tables.empty();
    }
    bool no_next_tables = tbl->next.empty() || empty_seq;

    if (no_next_tables) {
        next_table_leaves[tbl].insert(tbl);
    }

    control_dom_set[tbl].insert(tbl);

    for (auto seq : Values(tbl->next)) {
        for (auto control_tbl : seq->tables) {
            next_table_leaves[tbl] |= next_table_leaves.at(control_tbl);
            control_dom_set[tbl] |= control_dom_set.at(control_tbl);
        }
    }
}

/**
 * Tofino specific (currently necessary for JBay until placement algorithm changes)
 *
 * Say we have the following program:
 *
 * if (t1.apply().hit) {
       t2.apply();
 * }
 * t3.apply();
 *
 * Now in Tofino, if t1 is placed, then t2 must always be placed, in order to correctly
 * propagate the next table, before any other table.  Thus if t3 were to a have a dependency
 * either LOGICAL (i.e. ANTI) or DATA (i.e. IXBAR_READ) to t1, any dependency that is directly
 * under CONTROL dependencies would reflect in the dependency chain length of t2.
 *
 * The solution to reflect that chain correctly is to add a LOGICAL dependence between t2 and
 * t3 (given that t1 and t3 have a dependence).   By definition, t3 would have to follow
 * t2, if it would have to follow t1.
 *
 * The algorithm is based on the following:
 *    1. If t_b logical has to be placed after t_a, then t_b has to be logically placed after
 *       all next tables propagation of t_a.
 *    2. Thus if t_b is not directly next table propagation dependent of t_a, add a LOGICAL
 *       dependence on all next table paths out of t_a that are not mutually exclusive with
 *       t_b.
 */
void FindDependencyGraph::add_logical_deps_from_control_deps(void) {
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
        topo_rst = calc_topological_stage(DependencyGraph::ANTI);

    ordered_set<std::pair<const IR::MAU::Table *, const IR::MAU::Table *>> edges_to_add;

    for (int i = int(topo_rst.size()) - 1; i >= 0; --i) {
        for (auto& v : topo_rst[i]) {
            const IR::MAU::Table* table = dg.get_vertex(v);
            auto out_edge_itr_pair = boost::out_edges(v, dg.g);
            auto& out = out_edge_itr_pair.first;
            auto& out_end = out_edge_itr_pair.second;
            for (; out != out_end; ++out) {
                if (dg.g[*out] == DependencyGraph::CONTROL) continue;
                auto vertex_later = boost::target(*out, dg.g);
                const auto* table_later = dg.get_vertex(vertex_later);

                auto &table_nt_leaves = ntp.next_table_leaves.at(table);
                auto &table_dom_set = ntp.control_dom_set.at(table);
                if (table_dom_set.count(table_later)) continue;
                for (auto frontier_leaf : table_nt_leaves) {
                    if (mutex(table_later, frontier_leaf)) continue;
                    edges_to_add.insert(std::make_pair(frontier_leaf, table_later));
                }
            }
        }
    }

    for (auto pair : edges_to_add) {
        dg.add_edge(pair.first, pair.second, DependencyGraph::ANTI);
        calc_topological_stage(DependencyGraph::ANTI | DependencyGraph::CONTROL);
    }
}

void FindDependencyGraph::finalize_dependence_graph(void) {
    if (Device::currentDevice() == Device::TOFINO && _add_logical_deps == true) {
        add_logical_deps_from_control_deps();
    }

    // Topological sort
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
        topo_rst = calc_topological_stage();


    if (LOGGING(4)) {
        for (size_t i = 0; i < topo_rst.size(); ++i) {
            LOG4(">>> Stage#" << i << ":");
            for (const auto& vertex : topo_rst[i])
                LOG4("Table:  " << vertex << ", " << dg.get_vertex(vertex)->name);
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
                                LOG4("Adding stage from anti");
                            }
                            stage_addition = 1;
                    }
                    return std::max(sz, dg.stage_info[later].dep_stages_control + stage_addition);
           });
            LOG4("Dep stages of " << dg.stage_info[table].dep_stages <<
                " for table " << table->name);
            LOG4("Dep stages control of " << dg.stage_info[table].dep_stages_control <<
                " for table " << table->name);
        }
    }

    // dg.happens_before_control_map = dg.happens_before_map;
    for (const auto& kv : dg.happens_before_map) {
        auto* table = kv.first;
        for (const auto* prev : kv.second) {
            dg.happens_before_control_map[prev].insert(table); } }
    if (LOGGING(4)) {
        std::stringstream ss;
        for (auto& kv : dg.happens_before_control_map) {
            ss << "Table " << kv.first->name << " has priors of ";
            for (auto& tbl : kv.second) {
                ss << tbl->name << ", ";
            }
            ss << "\n";
        }
        LOG4(ss.str());
        for (auto& kv_outer : dg.dep_type_map) {
            for (auto& kv_inner : kv_outer.second) {
                auto* initial_table = kv_outer.first;
                auto* later_table = kv_inner.first;
                auto value = kv_inner.second;
                LOG4("Initial table " << initial_table->name << " with later table "
                    << later_table->name << " and value " << value);
            }
        }
    }

    // Calculate dg.happens_before_control_anti_map
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> topo_rst_control_anti =
        calc_topological_stage(DependencyGraph::CONTROL | DependencyGraph::ANTI);
    if (LOGGING(4)) {
        LOG4("Printing results of topological sorting with control and anti dependences included");
        for (size_t i = 0; i < topo_rst_control_anti.size(); ++i) {
            LOG4(">>> Stage#" << i << ":");
            for (const auto& vertex : topo_rst_control_anti[i]) {
                const auto* t = dg.get_vertex(vertex);
                LOG4("Table: " << vertex << ", " << t->name);
            }
        }
    }
    for (const auto& kv : dg.happens_before_map)
        dg.happens_before_control_anti_map[kv.first].insert(kv.second.begin(), kv.second.end());

    if (LOGGING(4)) {
        std::stringstream ss;
        for (auto& kv : dg.happens_before_control_anti_map) {
            ss << "Table " << kv.first->name << " has priors of ";
            for (auto& tbl : kv.second)
                ss << tbl->name << ", ";
            ss << std::endl;
        }
        LOG4(ss.str());
    }
    typename DependencyGraph::Graph::edge_iterator edges2, edges2_end;
    dg.dep_type_map.clear();
    for (boost::tie(edges2, edges2_end) = boost::edges(dg.g); edges2 != edges2_end; ++edges2) {
        const IR::MAU::Table* src = dg.get_vertex(boost::source(*edges2, dg.g));
        const IR::MAU::Table* dst = dg.get_vertex(boost::target(*edges2, dg.g));
        if ((dg.dep_type_map.count(src) == 0) || (dg.dep_type_map.at(src).count(dst) == 0)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::CONTROL)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::REDUCTION_OR_READ)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::REDUCTION_OR_OUTPUT)
            || (dg.dep_type_map.at(src).at(dst) == DependencyGraph::ANTI)) {
            dg.dep_type_map[src][dst] = dg.g[*edges2];
        }
    }

    for (int i = int(topo_rst_control_anti.size()) - 1; i >= 0; --i) {
        for (const auto& vertex : topo_rst_control_anti[i]) {
            const IR::MAU::Table* table = dg.get_vertex(vertex);
            auto& happens_later = dg.happens_before_map[table];
            dg.stage_info[table].dep_stages_control_anti = std::accumulate(happens_later.begin(),
                happens_later.end(), 0, [this, table] (int sz, const IR::MAU::Table* later) {
                    int stage_addition = 0;
                    if (dg.dep_type_map.count(table) && dg.dep_type_map.at(table).count(later)
                        && dg.dep_type_map.at(table).at(later) != DependencyGraph::CONTROL
                        && dg.dep_type_map.at(table).at(later) !=
                           DependencyGraph::REDUCTION_OR_READ
                        && dg.dep_type_map.at(table).at(later) !=
                           DependencyGraph::REDUCTION_OR_OUTPUT
                        && dg.dep_type_map.at(table).at(later) != DependencyGraph::ANTI) {
                        stage_addition = 1;
                    }
                    return std::max(sz, dg.stage_info[later].dep_stages_control_anti
                                        + stage_addition);
            });
            LOG4("Dep stages of " << dg.stage_info[table].dep_stages <<
                " for table " << table->name);
            LOG4("Dep stages control anti of " << dg.stage_info[table].dep_stages_control_anti <<
                " for table " << table->name);
        }
    }

    // Build min_stage
    // Min_stage for a table T is the minimum stage in which T (and any table that T is
    // control-dependent upon) can be placed. So, if table T2 has no match or action dependencies
    // but is control dependent on table T1, which -- because of its own match and action
    // dependencies -- must be placed in at least stage 4, then T2 and T1 will both have a
    // min_stage of 4.
    for (size_t i = 0; i < topo_rst_control_anti.size(); ++i) {
        for (const auto& vertex : topo_rst_control_anti[i]) {
            const IR::MAU::Table* table = dg.get_vertex(vertex);
            dg.stage_info[table].min_stage = i;
        }
    }


    // Compress the stages to take out the addition caused by control edges and anti edges,
    // but the min stage needs to be propagated through these edges
    for (size_t i = 1; i < topo_rst_control_anti.size(); i++) {
        for (const auto& vertex : topo_rst_control_anti[i]) {
            const auto* tbl = dg.get_vertex(vertex);
            int orig_stage = dg.stage_info[tbl].min_stage;
            int true_min_stage = 0;
            auto in_edges = boost::in_edges(vertex, dg.g);

            std::map<int, safe_vector<DependencyGraph::MinEdgeInfo>> min_edges_of_table;

            for (auto edge = in_edges.first; edge != in_edges.second; edge++) {
                auto src_vertex = boost::source(*edge, dg.g);
                const auto* src_table = dg.get_vertex(src_vertex);
                int src_vertex_stage = dg.stage_info[src_table].min_stage;
                int min_stage_from_src;
                DependencyGraph::dependencies_t dep = dg.g[*edge];
                if (dep == DependencyGraph::ACTION_READ || dep == DependencyGraph::IXBAR_READ ||
                    dep == DependencyGraph::OUTPUT) {
                    min_stage_from_src = src_vertex_stage + 1;
                } else if (dep == DependencyGraph::CONTROL ||
                           dep == DependencyGraph::REDUCTION_OR_READ ||
                           dep == DependencyGraph::REDUCTION_OR_OUTPUT ||
                           dep == DependencyGraph::ANTI) {
                    min_stage_from_src = src_vertex_stage;
                } else {
                    BUG("Unhandled dependency");
                    min_stage_from_src = src_vertex_stage;
                }
                true_min_stage = std::max(true_min_stage, min_stage_from_src);
                min_edges_of_table[min_stage_from_src].emplace_back(src_table, dep);
                BUG_CHECK(true_min_stage <= orig_stage, "stage should only decrease");
                // There shouldn't be any edges within a layer,
                // so starting from the lowest stage and moving out should be fine
            }
            dg.min_stage_edges[tbl] = min_edges_of_table[true_min_stage];
            dg.stage_info[tbl].min_stage = true_min_stage;
        }
    }

    if (LOGGING(3))
        dg.display_min_edges = true;


    dg.vertex_rst = topo_rst_control_anti;
    calc_topological_stage();

    verify_dependence_graph();
    if (LOGGING(4))
        DependencyGraph::dump_viz(std::cout, dg);
    calc_max_min_stage();
    dg.finalized = true;
}

void FindDependencyGraph::calc_max_min_stage() {
    for (const auto& kv : dg.stage_info)
        if (kv.second.min_stage > dg.max_min_stage)
            dg.max_min_stage = kv.second.min_stage;
    LOG1("    Maximum stage number according to dependences: " << dg.max_min_stage);
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

bool PrintPipe::preorder(const IR::BFN::Pipe *pipe) {
    LOG2(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread) );
    return false;
}


FindDependencyGraph::FindDependencyGraph(const PhvInfo &phv,
                                         DependencyGraph &out,
                                         cstring dotFileName,
                                         cstring passCont) :
        Logging::PassManager("table_dependency_graph", Logging::Mode::AUTO),
        dg(out), dotFile(dotFileName),
        passContext(passCont) {
    addPasses({
        &mutex,
        &ntp,
        new GatherReductionOrReqs(red_info),
        new TableFindInjectedDependencies(phv, dg),
        new FindDataDependencyGraph(phv, dg, red_info, mutex),
        new PrintPipe
    });
}

Visitor::profile_t FindDependencyGraph::init_apply(const IR::Node *node) {
    auto rv = PassManager::init_apply(node);
    dg.clear();
    if (!passContext.isNullOrEmpty())
        LOG1("FindDependencyGraph : " << passContext);
    return rv;
}

void FindDependencyGraph::end_apply(const IR::Node *root) {
    finalize_dependence_graph();
    LOG2(dg);
    if (BackendOptions().create_graphs && dotFile != "") {
        auto pipeId = root->to<IR::BFN::Pipe>()->id;
        auto graphsDir = BFNContext::get().getOutputDirectory("graphs", pipeId);
        std::ofstream dotStream(graphsDir + "/" + dotFile + ".dot", std::ios_base::out);
        DependencyGraph::dump_viz(dotStream, dg);
        Logging::Manifest::getManifest().addGraph(pipeId, "table", dotFile,
                                                  INGRESS);  // this should be both really!
    }
}
