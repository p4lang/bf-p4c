#ifndef BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>
#include <map>
#include <set>
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/reduction_or.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/phv/phv_fields.h"

/* The DependencyGraph data structure is a directed graph in which tables are
 * vertices and edges are dependencies.  An edge from t1 to t2 means that t2
 * depends on t1.
 *
 * Edges are annotated with the kind of dependency that exists between tables.
 * Note that there may be more than one edge from one table to another, each
 * representing a different dependency.
 *
 */
class TableGraphNode;
struct DependencyGraph {
    typedef enum {
        NONE                        = 1,          // No dependence label.
        CONTROL_ACTION              = (1 << 1),   // Control dependence due to action.
        CONTROL_COND_TRUE           = (1 << 2),   // Control dependence due to gateway
                                                  // true condition.
        CONTROL_COND_FALSE          = (1 << 3),   // Control dependence due to gateway
                                                  // false condition.
        CONTROL_TABLE_HIT           = (1 << 4),   // Control dependence due to a table hit.
        CONTROL_TABLE_MISS          = (1 << 5),   // Control dependence due to a table miss.
        CONTROL_DEFAULT_NEXT_TABLE  = (1 << 6),   // Control dependence due to default next table.
        IXBAR_READ                  = (1 << 7),   // Read-after-write (data) dependence.
        ACTION_READ                 = (1 << 8),   // Read-after-write dependence.
                                                  // Different from IXBAR_READ for power analysis.
        OUTPUT                      = (1 << 9),  // Write-after-write (output) dependence.(ACTION?)
        REDUCTION_OR_READ           = (1 << 10),  // Read-after-write dependence,
                                                  // Not a true dependency as hardware supports
                                                  // OR'n on action data bus.
        REDUCTION_OR_OUTPUT         = (1 << 11),  // Write-after-write dependece,
                                                  // Not a true dependency as hardware supports
                                                  // OR'n on action data bus.
        CONT_CONFLICT               = (1 << 12),  // Container Conflict between 2 tables sharing
                                                  // the same container
        ANTI_EXIT                   = (1 << 13),  // Dependency due to an action with exit
        ANTI_TABLE_READ             = (1 << 14),  // Action Write to a field read as
                                                  // a previous table key
        ANTI_ACTION_READ            = (1 << 15),  // Action Write to a field read as
                                                  // a previous table action
        ANTI_NEXT_TABLE_DATA        = (1 << 16),  // Data dependency between tables in
                                                  // separate blocks
        ANTI_NEXT_TABLE_CONTROL     = (1 << 17),  // Injected Control Dependency due to next
                                                  // table control flow
        ANTI_NEXT_TABLE_METADATA    = (1 << 18),  // Injected Data Dep due to a metadata field
        CONCURRENT                  = 0           // No dependency.
    } dependencies_t;
    static const unsigned ANTI = ANTI_EXIT
                               | ANTI_TABLE_READ
                               | ANTI_ACTION_READ
                               | ANTI_NEXT_TABLE_DATA
                               | ANTI_NEXT_TABLE_METADATA;
    static const unsigned CONTROL = CONTROL_ACTION
                                  | CONTROL_COND_TRUE
                                  | CONTROL_COND_FALSE
                                  | CONTROL_TABLE_HIT
                                  | CONTROL_TABLE_MISS
                                  | CONTROL_DEFAULT_NEXT_TABLE
                                  | ANTI_NEXT_TABLE_CONTROL;
    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::bidirectionalS,   // Directed edges.
        boost::property<boost::vertex_table_t, const IR::MAU::Table*>,  // Vertex labels
        dependencies_t     // Edge labels.
        > Graph;

    /** A map of all tables that cannot be placed in the same stage as the key table, because
     *  they share an ALU operation over a container.  The following example will indicate why
     *  this is a problem:
     *
     *  action a1(bit<4> x1) { hdr.data.x1 = x1; }
     *  action a2(bit<4> x2) { hdr.data.x2 = x2; }
     *
     *  table t1 { key = { hdr.data.f1; } actions = { a1; } default_action = a1(1); }
     *  table t2 { key = { hdr.data.f1; } actions = { a2; } default_action = a2(1); }
     *
     *  apply { t1.apply(); t2.apply(); }
     *
     *  Now let's say that hdr.data.x1 and hdr.data.x2 are in the same 8 bit PHV container, i.e.
     *  B0.  In the instruction memory, a1 and a2 will have its own VLIW instruction, which itself
     *  contains an opcode for every single PHV ALU.  All actions in the ALUs run in parallel,
     *  and the individual operations to each ALU are brought in as a portion of one stage VLIW
     *  instruction.
     *
     *  This stage VLIW instruction is formed by ORing together all actions (each of which is
     *  its own VLIW instruction) that are intended to be run in the stage.  Thus if a1 and a2
     *  were to be run in the same stage, their operations over container B0 would be ORed
     *  together.  In general ORing these opcodes will lose the meaning of the original
     *  operation.
     *
     *  Note that the constraint does not apply if the actions themselves are mutually exclusive,
     *  i.e. if the apply statement looked like the following:
     *
     *  apply { if (hdr.data.f1 == 1) { t1.apply() } else { t2.apply() } }
     *
     *  then it would be impossible for a1 and a2 to ever be called in the same packet, and thus
     *  the opcode for B0 would never be mucked up by the OR.
     *
     *  However, this is not to be considered an action dependency.  If t2 were action dependent
     *  on t1, then t1 would have to happen before t2.  This is not the case for this program
     *  as t2 does not affect any of the values that t1 is working on.  Instead it just affects
     *  the containers
     */
    std::map<const IR::MAU::Table*,
             std::set<const IR::MAU::Table*>> container_conflicts;

    Graph g;                // Dependency graph.

    // True once the graph has been fully constructed.
    bool finalized;

    // For GTests Only
 public:
    std::map<cstring, const IR::MAU::Table *> name_to_table;

    // NOTE: These maps are reverse named -- happens_after_map[t] is the set of tables that that are
    // before t, while happens_before_map[t] is the set of tables that are after t... This naming
    // comes from the idea that t must happen after anything in the set given by
    // happens_after_map[t] ("t happens after what is in happens_after_map[t]")

    // NOTE: happens_after/before_map are "work lists," used by functions in this file to calculate
    // other happens.*_maps. As such, it is much more prefereable to NOT use them externally. Use
    // the appropriately named map for your situation, which is better for readability
    // anyhow. Currently, happens_after/before_map ends up being the same as
    // happens_phys_after/before_map, although this could change.

    // Work happens after map
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_after_work_map;

    // Work happens before map
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_before_work_map;

    // For a given table t, happens_phys_after_map[t] is the set of tables that must be placed in an
    // earlier stage than t---i.e. there is a data dependence between t and any table in the
    // set. This is the default result of the calc_topological_stage function.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_phys_after_map;

    // Analagous to above, but for the tables that must be placed in a later stage than t
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_phys_before_map;

    // Same as happens_phys_before_map, with the additional inclusion of control dependences when
    // calculating the happens_before relationship.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_before_control_map;

    // Same as happens_phys_after_map, with the additional inclusion of control and anti dependences
    // when calculating the happens_after relationship, which corresponds to an ordering on logical
    // IDs.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_logi_after_map;

    // Analagous to above, but for tables that must be placed into a later logical ID than t. New
    // name for happens_before_control_anti_map
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_logi_before_map;

    std::map<const IR::MAU::Table*, std::map<const IR::MAU::Table*, dependencies_t>> dep_type_map;

    std::map<const IR::MAU::Table*,
             typename Graph::vertex_descriptor> labelToVertex;

    // Map from <t1, t2> to its dependency type
    // e.g.  <tbl1, tbl2> = MATCH means that tbl1 has a match dependency on tbl2
    std::map<std::pair<const IR::MAU::Table*, const IR::MAU::Table*>,
             DependencyGraph::dependencies_t> dependency_map;

    std::map<typename Graph::edge_descriptor, std::map<const PHV::Field*,
             std::pair<ordered_set<const IR::MAU::Action*>,
             ordered_set<const IR::MAU::Action*>>>> data_annotations;

    std::map<typename Graph::edge_descriptor, const std::vector<const IR::MAU::Action*>>
                                                                    data_annotations_exit;
    std::map<typename Graph::edge_descriptor, const PHV::Container> data_annotations_conflicts;
    std::map<typename Graph::edge_descriptor, const PHV::FieldSlice*> data_annotations_metadata;
    std::map<typename Graph::edge_descriptor, std::string> ctrl_annotations;

    struct StageInfo {
        int min_stage,      // Minimum stage at which a table can be placed.
        dep_stages,         // Number of tables that depend on this table and
                            // must be placed in a stage after it.
        dep_stages_control,
        dep_stages_control_anti,
        dep_stages_dom_frontier;
    };

    ordered_map<const IR::MAU::Table*, StageInfo> stage_info;

    using MinEdgeInfo = std::pair<const IR::MAU::Table *, dependencies_t>;
    bool display_min_edges = false;
    std::map<const IR::MAU::Table *, safe_vector<MinEdgeInfo>> min_stage_edges;

    /// The largest value of min_stage encountered when determining min_stage values for table,
    /// across all tables in the program. The minimum number of stages required by the program is
    /// 1 + max_min_stage (stage numbers start from 0, 1, ..., n-1)
    int max_min_stage_per_gress[3] = {-1, -1, -1};
    int max_min_stage = -1;

    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> vertex_rst;

    // Json variables
    cstring passContext;
    bool placed;

    DependencyGraph(void) {
        finalized = false;
    }

    void clear() {
        container_conflicts.clear();
        g.clear();
        finalized = false;
        max_min_stage = -1;
        name_to_table.clear();
        happens_after_work_map.clear();
        happens_before_work_map.clear();
        happens_phys_after_map.clear();
        happens_before_control_map.clear();
        happens_logi_after_map.clear();
        happens_logi_before_map.clear();
        dep_type_map.clear();
        labelToVertex.clear();
        dependency_map.clear();
        data_annotations.clear();
        data_annotations_exit.clear();
        data_annotations_conflicts.clear();
        data_annotations_metadata.clear();
        ctrl_annotations.clear();
        stage_info.clear();
        min_stage_edges.clear();
        for (unsigned i = 0; i < 3; i++)
            max_min_stage_per_gress[i] = -1;
        display_min_edges = false;
        vertex_rst.clear();
        passContext = "";
        placed = false;
    }

    /// @returns boolean indicating if an edge is a type of anti edge
    bool is_anti_edge(DependencyGraph::dependencies_t dep) const;

    /// @returns boolean indicating if an edge is a type of control edge
    bool is_ctrl_edge(DependencyGraph::dependencies_t dep) const;

    /// @returns boolean indicating if an edge is critical, i.e. appears in the
    /// min_stage_edges
    bool is_edge_critical(typename Graph::edge_descriptor e) const {
        auto source = get_vertex(boost::source(e, g));
        auto target = get_vertex(boost::target(e, g));
        if (min_stage_edges.count(target) == 0) return false;
        for (auto s : min_stage_edges.at(target)) {
            if ((s.first == source) && (s.second == g[e])) {
                return true;
            }
        }
        return false;
    }

    /// @returns the length of the dependency based critical path for the program.
    int critical_path_length() const {
        return (1 + max_min_stage);
    }

    /* @returns the table pointer corresponding to a vertex in the dependency graph
     */
    const IR::MAU::Table* get_vertex(typename Graph::vertex_descriptor v) const {
        return boost::get(boost::vertex_table, g)[v];
    }

    /* If a vertex with this label already exists, return it.  Otherwise,
     * create a new vertex with this label. */
    typename Graph::vertex_descriptor add_vertex(const IR::MAU::Table* label) {
        if (labelToVertex.count(label)) {
            return labelToVertex.at(label);
        } else {
            auto v = boost::add_vertex(label, g);
            labelToVertex[label] = v;
            stage_info[label] = {0, 0, 0, 0, 0};
            return v; }
    }

    /* Return an edge descriptor.  If bool is true, then this is a
     * newly-created edge.  If false, then the edge descriptor points to the
     * edge from src to dst with edge_label that already existed.  */
    std::pair<typename Graph::edge_descriptor, bool> add_edge(
        const IR::MAU::Table* src,
        const IR::MAU::Table* dst,
        dependencies_t edge_label);

    bool container_conflict(const IR::MAU::Table *t1, const IR::MAU::Table *t2) const {
        if (container_conflicts.find(t1) == container_conflicts.end())
            return false;
        if (container_conflicts.at(t1).find(t2) == container_conflicts.at(t1).end())
            return false;
        return true;
    }

    bool happens_phys_before(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_phys_before_map.count(t1)) {
            return happens_phys_before_map.at(t1).count(t2);
        } else {
            return false; }
    }

    bool happens_phys_after(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_phys_after_map.count(t1)) {
            return happens_phys_after_map.at(t1).count(t2);
        } else {
            return false; }
    }

    // returns true if any table in s or control dependent on a table in s is
    // data dependent on t1
    bool happens_phys_before_recursive(const IR::MAU::Table* t1,
                                       const IR::MAU::TableSeq* s) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_phys_before_map.count(t1))
            for (auto *t2 : s->tables)
                if (happens_phys_before_recursive(t1, t2)) return true;
        return false;
    }

    // returns true if t2 or any table control dependent on it is data dependent on t1
    bool happens_phys_before_recursive(const IR::MAU::Table* t1,
                                       const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_phys_before_map.count(t1)) {
            if (t2 != t1 && happens_phys_before_map.at(t1).count(t2)) return true;
            for (auto *next : Values(t2->next))
                if (happens_phys_before_recursive(t1, next)) return true; }
        return false;
    }

    bool happens_before_control(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_before_control_map.count(t1)) {
            return happens_before_control_map.at(t1).count(t2);
        } else {
            return false; }
    }

    bool happens_logi_before(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed");
        if (happens_logi_before_map.count(t1))
            return happens_logi_before_map.at(t1).count(t2);
        else
            return false;
    }

    bool happens_logi_after(const IR::MAU::Table *t1, const IR::MAU::Table *t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed");
        if (happens_logi_after_map.count(t1))
            return happens_logi_after_map.at(t1).count(t2);
        else
            return false;
    }

    boost::optional<std::map<const PHV::Field*, std::pair<ordered_set<const IR::MAU::Action*>,
                                                          ordered_set<const IR::MAU::Action*>>>>
    get_data_dependency_info(typename Graph::edge_descriptor edge) const {
        if (!data_annotations.count(edge)) {
            LOG4("Data dependency edge not found");
            return boost::none;
        }
        return data_annotations.at(edge);
    }

    boost::optional<std::string>
    get_ctrl_dependency_info(typename Graph::edge_descriptor edge) const {
        if (!ctrl_annotations.count(edge)) {
            LOG4("Control dependency edge not found");
            return boost::none;
        }
        return ctrl_annotations.at(edge);
    }

    /* Gets table dependency annotations for data dependency edges (IXBAR_READ, ACTION_READ,
       OUTPUT, REDUCTION_OR_READ, REDUCTION_OR_OUTPUT, ANTI).
       Parameters: Upstream table, downstream table connected by data dependency edge.
       Returns: Data annotations map structured as follows:
                Key -- {PHV field causing dependence, Dependence type}
                Value -- {UpstreamActionSet, DownstreamActionSet}, where each ActionSet
                contains all actions in which the relevant PHV field is accessed in either
                the upstream or the downstream table involved in the dependence. If the
                element is not accessed in any actions (i.e. an input crossbar read),
                that particular ActionSet will be empty.
    */
    boost::optional<std::map<std::pair<const PHV::Field*, DependencyGraph::dependencies_t>,
                             std::pair<ordered_set<const IR::MAU::Action*>,
                                       ordered_set<const IR::MAU::Action*>>>>
             get_data_dependency_info(const IR::MAU::Table* upstream,
                                      const IR::MAU::Table* downstream) const {
        if (!labelToVertex.count(upstream)) {
            LOG4("Upstream vertex " << upstream->name << " not found in graph");
            return boost::none;
        }
        if (!labelToVertex.count(downstream)) {
            LOG4("Downstream vertex " << downstream->name << "not found in graph");
            return boost::none;
        }
        auto upstream_v = labelToVertex.at(upstream);
        typename Graph::out_edge_iterator out, end;
        std::map<std::pair<const PHV::Field*, DependencyGraph::dependencies_t>,
                 std::pair<ordered_set<const IR::MAU::Action*>,
                 ordered_set<const IR::MAU::Action*>>> gathered_data;
        bool found_downstream = false;
        for (boost::tie(out, end) = boost::out_edges(upstream_v, g); out != end; ++out) {
            const IR::MAU::Table* test_v = get_vertex(boost::target(*out, g));
            if (test_v == downstream && (!is_ctrl_edge(g[*out]))) {
                found_downstream = true;
                auto edge_type = g[*out];
                auto local_data_opt = get_data_dependency_info(*out);
                if (!local_data_opt)
                    return boost::none;
                auto local_data = local_data_opt.get();
                for (const auto& kv : local_data) {
                    gathered_data[{kv.first, edge_type}].first |= local_data[kv.first].first;
                    gathered_data[{kv.first, edge_type}].second |= local_data[kv.first].second;
                }
            }
        }
        if (!found_downstream) {
            LOG4("Edge not found between tables " << upstream->name << ", " << downstream->name);
            return boost::none;
        }
        return gathered_data;
    }

    /**
      * Returns the dependency type from t1 to t2.
      *
      */
    DependencyGraph::dependencies_t get_dependency(const IR::MAU::Table* t1,
                                                   const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");

        auto p = std::make_pair(t1, t2);
        if (dependency_map.find(p) != dependency_map.end()) {
            return dependency_map.at(p);
        }
        // No dependency between tables
        return DependencyGraph::CONCURRENT;
    }

    int dependence_tail_size(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).dep_stages;
    }

    int dependence_tail_size_control(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).dep_stages_control;
    }

    int dependence_tail_size_control_anti(const IR::MAU::Table *t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).dep_stages_control_anti;
    }

    int min_stage(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).min_stage;
    }

    std::set<const IR::MAU::Table*>
    happens_before_dependences(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return happens_before_work_map.at(t);
    }

    friend std::ostream &operator<<(std::ostream &, const DependencyGraph&);
    static cstring dep_to_name(dependencies_t dep) {
        if ((dep == DependencyGraph::CONTROL)
         || (dep == DependencyGraph::ANTI_NEXT_TABLE_CONTROL)
         || (dep == DependencyGraph::CONTROL_ACTION)
         || (dep == DependencyGraph::CONTROL_COND_TRUE)
         || (dep == DependencyGraph::CONTROL_COND_FALSE)
         || (dep == DependencyGraph::CONTROL_TABLE_HIT)
         || (dep == DependencyGraph::CONTROL_TABLE_MISS)
         || (dep == DependencyGraph::CONTROL_DEFAULT_NEXT_TABLE)) {
            return "control";
        } else if (dep == IXBAR_READ) {
            return "ixbar_read";
        } else if (dep == ACTION_READ) {
            return "action_read";
        } else if ((dep == DependencyGraph::ANTI_EXIT)
     || (dep == DependencyGraph::ANTI_TABLE_READ)
     || (dep == DependencyGraph::ANTI_ACTION_READ)
     || (dep == DependencyGraph::ANTI_NEXT_TABLE_DATA)
     || (dep == DependencyGraph::ANTI_NEXT_TABLE_METADATA)) {
            return "anti";
        } else if (dep == OUTPUT) {
            return "output";
        } else {
            return "concurrent";
        }
    }
    static void dump_viz(std::ostream &out, const DependencyGraph &dg);
    void to_json(Util::JsonObject* dgJson, const FlowGraph &fg, cstring passContext, bool placed);
    static dependencies_t get_control_edge_type(cstring annot) {
        if (annot == "$hit")
            return DependencyGraph::CONTROL_TABLE_HIT;
        else if (annot == "$miss" || annot == "$try_next_stage")
            return DependencyGraph::CONTROL_TABLE_MISS;
        else if (annot == "$default")
            return DependencyGraph::CONTROL_DEFAULT_NEXT_TABLE;
        else if (annot == "$true")
            return DependencyGraph::CONTROL_COND_TRUE;
        else if (annot == "$false")
            return DependencyGraph::CONTROL_COND_FALSE;
        else
            return DependencyGraph::CONTROL_ACTION;
    }

    TableGraphNode create_node(const int id, const IR::MAU::Table *tbl) const;
};

class TableGraphField {
 public:
    cstring gress;
    cstring name;
    int lo;
    int hi;
};

class TableGraphEdge {
 public:
    int id                      = -1;
    int source                  = -1;
    int target                  = -1;
    int phv_number              = -1;
    cstring action_name         = "";
    cstring exit_action_name    = "";
    bool is_critical            = false;

    std::vector<TableGraphField> dep_fields;
    std::vector<cstring> tags;
    bool condition_value;
    DependencyGraph::dependencies_t label;

    // Static maps
    static std::map<DependencyGraph::dependencies_t, cstring> labels_to_types;
    static std::map<DependencyGraph::dependencies_t, cstring> labels_to_sub_types;
    static std::map<DependencyGraph::dependencies_t, cstring> labels_to_anti_types;
    static std::map<DependencyGraph::dependencies_t, bool> labels_to_conds;

    bool add_dep_field(const PHV::Field *s) {
        if (!s) return false;

        TableGraphField f;
        f.name  = cstring::to_cstring(canon_name(s->name));
        f.gress = toString(s->gress);
        f.lo    = 0;
        f.hi    = s->size -1;
        dep_fields.push_back(f);
        LOG5(" Adding Dep Field: "
                << f.name << "[" << f.hi << ":" << f.lo << "] (" << f.gress << ")");
        return true;
    }

    void add_dep_fields_json(Util::JsonObject* edgeMdJson) {
        Util::JsonArray* edgeMdDepFields = new Util::JsonArray();
        if (dep_fields.size() > 0) {
            for (auto field : dep_fields) {
                Util::JsonObject* edgeMdDepField = new Util::JsonObject();
                edgeMdDepField->emplace("gress", field.gress);
                edgeMdDepField->emplace("field_name", field.name);
                edgeMdDepField->emplace("start_bit", field.lo);
                edgeMdDepField->emplace("width", field.hi - field.lo + 1);
                edgeMdDepFields->append(edgeMdDepField);
            }
        }
        edgeMdJson->emplace("dep_fields", edgeMdDepFields);
    }

    void add_action_name_json(Util::JsonObject* edgeMdJson) {
        auto act_name = cstring::to_cstring(canon_name(action_name));
        edgeMdJson->emplace("action_name", act_name);
    }

    void add_exit_action_name_json(Util::JsonObject* edgeMdJson) {
        auto act_name = cstring::to_cstring(canon_name(exit_action_name));
        edgeMdJson->emplace("action_name", act_name);
    }

    void add_phv_number_json(Util::JsonObject* edgeMdJson) {
        edgeMdJson->emplace("phv_number", phv_number);
    }

    void add_condition_value_json(Util::JsonObject* edgeMdJson) {
        if (labels_to_conds.count(label) == 0)
            BUG("Invalid edge type. Cannot determine condition value");
        bool condition_value = labels_to_conds[label];
        edgeMdJson->emplace("condition_value", condition_value);
    }

    void add_anti_type_json(Util::JsonObject* edgeMdJson) {
        if (labels_to_anti_types.count(label) == 0)
            BUG("Invalid edge type. Cannot determine anti type");

        auto anti_type = labels_to_anti_types[label];
        edgeMdJson->emplace("anti_type", anti_type);
    }

    void add_type_json(Util::JsonObject* edgeMdJson) {
        if (labels_to_types.count(label) == 0)
            BUG("Invalid edge type");

        auto type = labels_to_types[label];
        edgeMdJson->emplace("type", type);
    }

    void add_sub_type_json(Util::JsonObject* edgeMdJson) {
        if (labels_to_sub_types.count(label) == 0)
            BUG("Invalid edge type. Cannot determine sub type.");

        auto sub_type = labels_to_sub_types[label];
        edgeMdJson->emplace("sub_type", sub_type);
    }

    Util::JsonObject* create_edge_md_json() {
        Util::JsonObject* edgeMdJson = new Util::JsonObject();

        add_type_json(edgeMdJson);
        add_sub_type_json(edgeMdJson);

        switch (label) {
            case DependencyGraph::IXBAR_READ                :
                add_dep_fields_json(edgeMdJson); break;

            case DependencyGraph::ACTION_READ               :
                add_dep_fields_json(edgeMdJson);
                add_action_name_json(edgeMdJson); break;

            case DependencyGraph::OUTPUT                    :
                add_dep_fields_json(edgeMdJson); break;

            case DependencyGraph::CONT_CONFLICT             :
                add_phv_number_json(edgeMdJson); break;

            case DependencyGraph::REDUCTION_OR_READ         :
            case DependencyGraph::REDUCTION_OR_OUTPUT       :
                add_dep_fields_json(edgeMdJson); break;

            case DependencyGraph::ANTI_TABLE_READ           :
            case DependencyGraph::ANTI_ACTION_READ          :
            case DependencyGraph::ANTI_NEXT_TABLE_DATA      :
            case DependencyGraph::ANTI_NEXT_TABLE_CONTROL   :
            case DependencyGraph::ANTI_NEXT_TABLE_METADATA  :
                add_anti_type_json(edgeMdJson);
                add_dep_fields_json(edgeMdJson); break;

            case DependencyGraph::ANTI_EXIT                 :
                add_exit_action_name_json(edgeMdJson); break;

            case DependencyGraph::CONTROL_ACTION            :
                add_action_name_json(edgeMdJson); break;

            case DependencyGraph::CONTROL_COND_TRUE         :
            case DependencyGraph::CONTROL_COND_FALSE        :
                add_condition_value_json(edgeMdJson); break;

            case DependencyGraph::CONTROL_TABLE_HIT         :
            case DependencyGraph::CONTROL_TABLE_MISS        :
            case DependencyGraph::CONTROL_DEFAULT_NEXT_TABLE:
                break;

            /* Should never reach here */
            default : BUG("Invalid dependency graph edge type");
        }

        if (is_critical)
            edgeMdJson->emplace("is_critical", is_critical);

        if (tags.size() > 0) {
            Util::JsonArray* edgeMdTags = new Util::JsonArray();
            for (auto t : tags)
                edgeMdTags->append(t);
            edgeMdJson->emplace("tags", edgeMdTags);
        }

        return edgeMdJson;
    }

    Util::JsonObject* create_edge_json() {
        Util::JsonObject* edgeJson = new Util::JsonObject();
        edgeJson->emplace("id", new Util::JsonValue(std::to_string(id)));
        edgeJson->emplace("source", new Util::JsonValue(std::to_string(source)));
        cstring targetStr = std::to_string(target);
        if (target == 0) targetStr = "SINK";
        edgeJson->emplace("target", new Util::JsonValue(targetStr));
        edgeJson->emplace("metadata", create_edge_md_json());
        return edgeJson;
    }
};

class TableGraphNode {
 public:
    int id = -1;
    int logical_id = -1;
    int stage_number = -1;
    int min_stage = -1;
    int dep_chain = -1;

    class TableGraphNodeTable {
     public:
        cstring name = "";
        cstring table_type = "";
        cstring match_type = "";
        cstring condition = "";
    };
    std::vector<TableGraphNodeTable> nodeTables;

    static cstring get_node_match_type(const IR::MAU::Table *tbl) {
        auto match_type = tbl->get_table_type_string();
        if (match_type == "exact_match")        return "exact";
        else if (match_type == "ternary_match") return "ternary";
        else if (match_type == "proxy_hash")    return "proxy_hash";
        else if (match_type == "hash_action")   return "hash_action";
        else if (tbl->layout.pre_classifier
                || tbl->layout.alpm)            return "algorithmic_lpm";
        else if (match_type == "atcam_match")   return "algorithmic_tcam";
        return "none";
    }

    static cstring get_attached_table_type(const IR::MAU::AttachedMemory *att) {
        if (att->to<IR::MAU::Counter>())                 return "statistics";
        else if (att->to<IR::MAU::Meter>())              return "meter";
        else if (att->to<IR::MAU::StatefulAlu>())        return "stateful";
        else if (att->to<IR::MAU::Selector>())           return "selection";
        else if (att->to<IR::MAU::ActionData>())         return "action";
        else if (att->to<IR::MAU::TernaryIndirect>())    return "ternary_indirect";
        else if (att->to<IR::MAU::IdleTime>())           return "idletime";
        return "none";
    }

    Util::JsonObject* create_node_md_json() {
        Util::JsonObject* nodeMdJson = new Util::JsonObject();

        if (logical_id >= 0 && stage_number >= 0) {
            Util::JsonObject* placement = new Util::JsonObject();
            placement->emplace("logical_table_id", new Util::JsonValue(logical_id));
            placement->emplace("stage_number", new Util::JsonValue(stage_number));
            nodeMdJson->emplace("placement", placement);
        }

        Util::JsonArray* nodesTJsons = new Util::JsonArray();
        for (auto n : nodeTables) {
            Util::JsonObject* nodeTJson = new Util::JsonObject();
            nodeTJson->emplace("name", new Util::JsonValue(n.name));
            nodeTJson->emplace("table_type", new Util::JsonValue(n.table_type));
            if (n.table_type == "match")
                nodeTJson->emplace("match_type", new Util::JsonValue(n.match_type));
            if (n.table_type == "condition")
                nodeTJson->emplace("condition", new Util::JsonValue(n.condition));
            nodesTJsons->append(nodeTJson);
        }
        nodeMdJson->emplace("tables", nodesTJsons);
        nodeMdJson->emplace("min_stage", min_stage);
        nodeMdJson->emplace("dep_chain", dep_chain);
        return nodeMdJson;
      }

    Util::JsonObject* create_node_json() {
        Util::JsonObject* nodeJson = new Util::JsonObject();
        nodeJson->emplace("id", std::to_string(id));
        nodeJson->emplace("metadata", create_node_md_json());
        return nodeJson;
    }
};


class NameToTableMapBuilder : public MauInspector {
    DependencyGraph &dg;
    bool preorder(const IR::MAU::Table *tbl) override;

 public:
    explicit NameToTableMapBuilder(DependencyGraph &d) : dg(d) {}
};

class FindDataDependencyGraph : public MauInspector, BFN::ControlFlowVisitor {
 public:
    typedef ordered_map<const IR::MAU::Table*, bitvec> cont_write_t;
    typedef struct {
        ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> ixbar_read;
        ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> action_read;
        ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> write;
        ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> reduction_or_write;
        ordered_set<std::pair<const IR::MAU::Table*, const IR::MAU::Action*>> reduction_or_read;
    } access_t;


 private:
    const PhvInfo&                                        phv;
    DependencyGraph&                                      dg;
    const ReductionOrInfo&                                red_info;
    const TablesMutuallyExclusive&                        mutex;
    const IgnoreTableDeps&                                ignore;
    std::map<cstring, access_t>                           access;
    std::map<cstring, cstring>                            red_or_use;
    std::map<PHV::Container, cont_write_t>                cont_write;


    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::MAU::Table *) override;
    bool preorder(const IR::MAU::Action *) override;
    bool preorder(const IR::MAU::TableKey *) override;

    Visitor::profile_t init_apply(const IR::Node* node) override {
        auto rv = Inspector::init_apply(node);
        access.clear();
        cont_write.clear();
        red_or_use.clear();

        const ordered_map<const PHV::Field*, const PHV::Field*>& aliasMap = phv.getAliasMap();
        LOG4("Printing alias map");
        for (auto kv : aliasMap)
            LOG4("  " << kv.first->name << " aliases with " << kv.second->name);

        return rv;
    }


    void flow_merge(Visitor &v) override;

    // void all_bfs(boost::default_bfs_visitor* vis);
    FindDataDependencyGraph *clone() const override { return new FindDataDependencyGraph(*this); }

    class AddDependencies;
    class UpdateAccess;
    class UpdateAttached;

 public:
    FindDataDependencyGraph(const PhvInfo &phv, DependencyGraph& out, const ReductionOrInfo &ri,
        const TablesMutuallyExclusive &m, const IgnoreTableDeps &ig)
    : phv(phv), dg(out), red_info(ri), mutex(m), ignore(ig) {
        joinFlows = true;
    }
};

class CalculateNextTableProp : public MauInspector {
    using NextTableLeaves =
        ordered_map<const IR::MAU::Table *, ordered_set<const IR::MAU::Table *>>;
    using ControlDominatingSet = NextTableLeaves;
    std::map<cstring, const IR::MAU::Table *> name_to_table;

 public:
    /// Maps each table T to its set of next-table leaves, defined inductively. If T has no
    /// next-table entries, then it is its own next-table leaf. Otherwise, the next-table leaves
    /// are those of any table in the sub-trees rooted in T's next-table entries.
    NextTableLeaves next_table_leaves;

    /// Maps each table T to its control-dominating set, which is T itself, and any table found in
    /// the sub-trees rooted in T's next-table entries.
    ControlDominatingSet control_dom_set;

 private:
    void postorder(const IR::MAU::Table *) override;
    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        next_table_leaves.clear();
        control_dom_set.clear();
        name_to_table.clear();
        return rv;
    }

 public:
    const IR::MAU::Table *get_table(cstring name) const {
        if (name_to_table.count(name))
            return name_to_table.at(name);
        return nullptr;
    }
    CalculateNextTableProp() { visitDagOnce = false; }
};

class ControlPathwaysToTable : public MauInspector {
 public:
    using Path = safe_vector<const IR::Node *>;
    using TablePathways = ordered_map<const IR::MAU::Table *, safe_vector<Path>>;
    using InjectPoints = safe_vector<std::pair<const IR::Node *, const IR::Node *>>;

    /// Maps each table T to a list of possible control paths from T out to the top-level of the
    /// pipe.
    TablePathways table_pathways;

 private:
    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        table_pathways.clear();
        return rv;
    }

    bool equiv(const Path &a, const Path &b) const;
    bool equiv_seqs(const IR::MAU::TableSeq *a, const IR::MAU::TableSeq *b) const;
    bool preorder(const IR::MAU::Table *) override;
    Path common_reverse_path(const Path &a, const Path &b, bool check_diff_if_seq = false) const;

 public:
    void print_paths(safe_vector<Path> &paths) const;
    const IR::MAU::Table *find_dominator(const IR::MAU::Table *init) const;
    InjectPoints get_inject_points(const IR::MAU::Table *a, const IR::MAU::Table *b,
        bool tbls_only = true) const;
    ControlPathwaysToTable() { visitDagOnce = false; }
};

class FindDependencyGraph;

class DepStagesThruDomFrontier : public MauInspector {
    const CalculateNextTableProp &ntp;
    DependencyGraph &dg;
    FindDependencyGraph &self;

    void postorder(const IR::MAU::Table *) override;

 public:
    DepStagesThruDomFrontier(const CalculateNextTableProp &n, DependencyGraph &d,
        FindDependencyGraph &s) : ntp(n), dg(d), self(s) {}
};

class PrintPipe : public MauInspector {
    bool preorder(const IR::BFN::Pipe *p) override;

 public:
    PrintPipe() { }
};

class FindCtrlDependencyGraph : public MauInspector {
    DependencyGraph &dg;
    bool preorder(const IR::MAU::Table *t);

 public:
    explicit FindCtrlDependencyGraph(DependencyGraph &out) : dg(out) {}
};

class FindDependencyGraph : public Logging::PassManager {
    /** Check that no ingress table ever depends on an egress table happening
     * first. */
    void verify_dependence_graph(void);
    void finalize_dependence_graph(void);
    void calc_max_min_stage();

    Visitor::profile_t init_apply(const IR::Node *node) override;
    TablesMutuallyExclusive mutex;
    DependencyGraph &dg;
    const BFN_Options *options;
    FlowGraph fg;
    ReductionOrInfo red_info;
    ControlPathwaysToTable con_paths;
    CalculateNextTableProp ntp;
    IgnoreTableDeps ignore;
    cstring dotFile;
    cstring passContext;

    void end_apply(const IR::Node *root) override;
    void add_logical_deps_from_control_deps();

 public:
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
    calc_topological_stage(unsigned deps_flag = 0, DependencyGraph *dg_p = nullptr);
    FindDependencyGraph(const PhvInfo &, DependencyGraph &out, const BFN_Options *o = nullptr,
        cstring dotFileName = "", cstring passContext = "");
};

#endif /* BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
