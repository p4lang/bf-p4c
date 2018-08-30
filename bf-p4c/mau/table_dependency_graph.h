#ifndef BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <boost/optional.hpp>
#include <map>
#include <set>
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"
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
     *  apply { if (hdr.data.f1 == 1) { t1.apply() } else { t2.apply() }
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

    // happens_before[t1] = {t2, t3} means that t1 happens strictly before t2
    // and t3: t1 MUST be placed in an earlier stage.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_before_map;

    // Same as happens_before_map, with the additional inclusion of control dependences when
    // calculating the happens_before relationship.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>> happens_before_control_map;

    // Same as happens_before_map, with the additional inclusion of control and anti dependences
    // when calculating the happens_before relationship.
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>>
        happens_before_control_anti_map;

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
        dep_stages_control;
    };
    std::map<const IR::MAU::Table*, StageInfo> stage_info;

    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>> vertex_rst;

    DependencyGraph(void) {
        finalized = false;
    }

    void clear() {
        container_conflicts.clear();
        g.clear();
        finalized = false;
        happens_before_map.clear();
        happens_before_control_map.clear();
        happens_before_control_anti_map.clear();
        dependency_map.clear();
        labelToVertex.clear();
        stage_info.clear();
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
            stage_info[label] = {0, 0, 0};
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

    bool happens_before(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_before_map.count(t1)) {
            return happens_before_map.at(t1).count(t2);
        } else {
            return false; }
    }

    bool happens_before_control(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        if (happens_before_control_map.count(t1)) {
            return happens_before_control_map.at(t1).count(t2);
        } else {
            return false; }
    }

    bool happens_before_control_anti(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed");
        if (happens_before_control_anti_map.count(t1))
            return happens_before_control_anti_map.at(t1).count(t2);
        else
            return false;
    }

    boost::optional<std::map<const PHV::Field*, std::pair<ordered_set<const IR::MAU::Action*>,
             ordered_set<const IR::MAU::Action*>>>>
             get_data_dependency_info(typename Graph::edge_descriptor edge) {
        if (!data_annotations.count(edge)) {
            LOG1("Data dependency edge not found");
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
                                      const IR::MAU::Table* downstream) {
        if (!labelToVertex.count(upstream)) {
            LOG1("Upstream vertex not found in graph");
            return boost::none;
        }
        if (!labelToVertex.count(downstream)) {
            LOG1("Downstream vertex not found in graph");
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
                if (!local_data_opt.is_initialized())
                    return boost::none;
                auto local_data = local_data_opt.get();
                for (const auto& kv : local_data) {
                    gathered_data[{kv.first, edge_type}].first |= local_data[kv.first].first;
                    gathered_data[{kv.first, edge_type}].second |= local_data[kv.first].second;
                }
            }
        }
        if (!found_downstream) {
            LOG1("Edge not found between provided tables");
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

    int min_stage(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).min_stage;
    }

    std::set<const IR::MAU::Table*>
    happens_before_dependences(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return happens_before_map.at(t);
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
};



class FindDependencyGraph : public MauInspector, BFN::ControlFlowVisitor {
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
    std::map<cstring, access_t>                           access;
    std::map<PHV::Container, cont_write_t>                cont_write;

    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
    calc_topological_stage(unsigned deps_flag = 0);


    /** Check that no ingress table ever depends on an egress table happening
     * first. */
    void verify_dependence_graph(void);
    void finalize_dependence_graph(void);

    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::MAU::Table *) override;
    bool preorder(const IR::MAU::Action *) override;
    bool preorder(const IR::MAU::InputXBarRead *) override;
    bool preorder(const IR::BFN::Pipe *pipe) override;

    Visitor::profile_t init_apply(const IR::Node* node) override {
        auto rv = Inspector::init_apply(node);
        dg.clear();
        access.clear();
        cont_write.clear();

        const ordered_map<const PHV::Field*, const PHV::Field*>& aliasMap = phv.getAliasMap();
        LOG1("Printing alias map");
        for (auto kv : aliasMap)
            LOG1("  " << kv.first->name << " aliases with " << kv.second->name);

        return rv;
    }

    void end_apply() override {
        finalize_dependence_graph();
        LOG3(dg);
    }

    void flow_dead() override;
    void flow_merge(Visitor &v) override;

    void all_bfs(boost::default_bfs_visitor* vis);
    FindDependencyGraph *clone() const override { return new FindDependencyGraph(*this); }

    class AddDependencies;
    class UpdateAccess;
    class UpdateAttached;

 public:
    explicit FindDependencyGraph(const PhvInfo &phv, DependencyGraph& out)
    : phv(phv), dg(out) {
        joinFlows = true;
    }
};

#endif /* BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
