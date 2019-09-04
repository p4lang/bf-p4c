#ifndef BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>
#include <map>
#include <set>
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/reduction_or.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/phv_fields.h"

namespace boost {
    enum vertex_table_t { vertex_table };
    BOOST_INSTALL_PROPERTY(vertex, table);
}

/* The DependencyGraph data structure is a directed graph in which tables are
 * vertices and edges are dependencies.  An edge from t1 to t2 means that t2
 * depends on t1.
 *
 * Edges are annotated with the kind of dependency that exists between tables.
 * Note that there may be more than one edge from one table to another, each
 * representing a different dependency.
 *
 * The dependencies are:
 *
 *  - t1 -- CONTROL --> t2: Table t1 sets next-table information that decides
 *    whether t2 is applied.
 *
 *  - t1 -- OUTPUT ---> t2: Table t1 may write a field that t2 may also write.
 *
 *  - t1 -- DATA -----> t2: Table t1 may write a field that t2 may read.
 *
 *  - t1 -- ANTI -----> t2: Table t1 may read a field that t2 may write.
 */

struct DependencyGraph {
    typedef enum {
        CONTROL = 1,     // Control dependence.
        IXBAR_READ = (1 << 1),  // Read-after-write (data) dependence.
        ACTION_READ = (1 << 2),  // Read-after-write dependence.
                      // Different from IXBAR_READ for power analysis.
        ANTI = (1 << 3),        // Write-after-read (anti) dependence.
        OUTPUT = (1 << 4),      // Write-after-write (output) dependence. (ACTION?)
        REDUCTION_OR_READ = (1 << 5),  // Read-after-write dependence,
                            // Not a true dependency as hardware supports OR'n on
                            // action data bus.
        REDUCTION_OR_OUTPUT = (1 << 6),  // Write-after-write dependece,
                              // Not a true dependency as hardware supports OR'n on
                              // action data bus.
        CONCURRENT = 0   // No dependency.
    } dependencies_t;
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

    struct StageInfo {
        int min_stage,      // Minimum stage at which a table can be placed.
        dep_stages,         // Number of tables that depend on this table and
                            // must be placed in a stage after it.
        dep_stages_control,
        dep_stages_control_anti;
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

    DependencyGraph(void) {
        finalized = false;
    }

    void clear() {
        container_conflicts.clear();
        g.clear();
        finalized = false;
        max_min_stage = -1;
        happens_before_work_map.clear();
        happens_before_control_map.clear();
        dependency_map.clear();
        labelToVertex.clear();
        stage_info.clear();
        min_stage_edges.clear();
        for (unsigned i = 0; i < 3; i++)
            max_min_stage_per_gress[i] = -1;
        display_min_edges = false;
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
            stage_info[label] = {0, 0, 0, 0};
            return v; }
    }

    /* Return an edge descriptor.  If bool is true, then this is a
     * newly-created edge.  If false, then the edge descriptor points to the
     * edge from src to dst with edge_label that already existed.  */
    std::pair<typename Graph::edge_descriptor, bool> add_edge(
        const IR::MAU::Table* src,
        const IR::MAU::Table* dst,
        dependencies_t edge_label) {
        typename Graph::vertex_descriptor src_v, dst_v;
        src_v = add_vertex(src);
        dst_v = add_vertex(dst);

        typename Graph::out_edge_iterator out, end;
        for (boost::tie(out, end) = boost::out_edges(src_v, g); out != end; ++out) {
            if (boost::target(*out, g) == dst_v && g[*out] == edge_label)
                return {*out, false};
        }

        auto maybe_new_e = boost::add_edge(src_v, dst_v, g);
        if (!maybe_new_e.second)
            // A vector-based adjacency_list (i.e. Graph) is a multigraph.
            // Inserting edges should always create new edges.
            BUG("Boost Graph Library failed to add edge.");
        g[maybe_new_e.first] = edge_label;
        auto p = std::make_pair(dst, src);
        dependency_map.emplace(p, edge_label);
        // LOG1("DST " << dst->name << " has dep " << edge_label << " to SRC " << src->name);
        return {maybe_new_e.first, true};
    }

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

    // returns true if any table in s or control dependent on a table in s is data dependent on t1
    bool happens_phys_before_recursive(const IR::MAU::Table* t1, const IR::MAU::TableSeq* s) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_phys_before_map.count(t1))
            for (auto *t2 : s->tables)
                if (happens_phys_before_recursive(t1, t2)) return true;
        return false;
    }

    // returns true if t2 or any table control dependent on it is data dependent on t1
    bool happens_phys_before_recursive(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
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
            if (test_v == downstream && g[*out] != DependencyGraph::CONTROL) {
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
        if (dep == CONTROL) {
            return "control";
        } else if (dep == IXBAR_READ) {
            return "ixbar_read";
        } else if (dep == ACTION_READ) {
            return "action_read";
        } else if (dep == ANTI) {
            return "anti";
        } else if (dep == OUTPUT) {
            return "output";
        } else {
            return "concurrent";
        }
    }

    static void dump_viz(std::ostream &out, const DependencyGraph &dg);
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
    using TablePathways = ordered_map<const IR::MAU::Table *,
                                       safe_vector<safe_vector<const IR::Node *>>>;
    using InjectPoints = safe_vector<std::pair<const IR::MAU::Table *, const IR::MAU::Table *>>;

    /// Maps each table T to a list of possible control paths from T out to the top-level of the
    /// pipe.
    TablePathways table_pathways;

 private:
    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        table_pathways.clear();
        return rv;
    }

    bool preorder(const IR::MAU::Table *) override;

 public:
    InjectPoints get_inject_points(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
};

class PrintPipe : public MauInspector {
    bool preorder(const IR::BFN::Pipe *p) override;

 public:
    PrintPipe() { }
};


class FindDependencyGraph : public Logging::PassManager {
    bool _add_logical_deps = true;
    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
    calc_topological_stage(unsigned deps_flag = 0);

    /** Check that no ingress table ever depends on an egress table happening
     * first. */
    void verify_dependence_graph(void);
    void add_logical_deps_from_control_deps(void);
    void finalize_dependence_graph(void);
    void calc_max_min_stage();

    Visitor::profile_t init_apply(const IR::Node *node) override;
    TablesMutuallyExclusive mutex;
    DependencyGraph &dg;
    ReductionOrInfo red_info;
    ControlPathwaysToTable con_paths;
    CalculateNextTableProp ntp;
    IgnoreTableDeps ignore;
    cstring dotFile;
    cstring passContext;


    void end_apply(const IR::Node *root) override;

 public:
    void set_add_logical_deps(bool add) { _add_logical_deps = add; }
    FindDependencyGraph(const PhvInfo &, DependencyGraph &out, cstring dotFileName = "",
        cstring passContext = "");
};

#endif /* BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
