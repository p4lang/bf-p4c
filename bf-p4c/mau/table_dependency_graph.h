#ifndef BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_
#define BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/transitive_closure.hpp>
#include <map>
#include <set>
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

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
        CONTROL,     // Control dependence.
        DATA,        // Read-after-write (data) dependence.
        ANTI,        // Write-after-read (anti) dependence.
        OUTPUT       // Write-after-write (output) dependence.
    } dependencies_t;
    typedef boost::adjacency_list<
        boost::vecS,
        boost::vecS,
        boost::directedS,   // Directed edges.
        const IR::MAU::Table*,   // Vertex labels.
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
    std::map<const IR::MAU::Table*,
             std::set<const IR::MAU::Table*>> happens_before_map;

    std::map<const IR::MAU::Table*,
             typename Graph::vertex_descriptor> labelToVertex;

    struct StageInfo {
        int min_stage,      // Minimum stage at which a table can be placed.
        dep_stages;         // Number of tables that depend on this table and
                            // must be placed in a stage after it.
    };
    std::map<const IR::MAU::Table*, StageInfo> stage_info;

    DependencyGraph(void) { finalized = false; }

    void clear() {
        container_conflicts.clear();
        g.clear();
        finalized = false;
        happens_before_map.clear();
        labelToVertex.clear();
        stage_info.clear();
    }

    /* If a vertex with this label already exists, return it.  Otherwise,
     * create a new vertex with this label. */
    typename Graph::vertex_descriptor add_vertex(const IR::MAU::Table* label) {
        if (labelToVertex.count(label)) {
            return labelToVertex.at(label);
        } else {
            auto v = boost::add_vertex(g);
            g[v] = label;
            labelToVertex[label] = v;
            stage_info[label] = {0, 0};
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

    int dependence_tail_size(const IR::MAU::Table* t) const {
        if (!finalized)
            BUG("Dependence graph used before being fully constructed.");
        return stage_info.at(t).dep_stages;
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
};



class FindDependencyGraph : public MauInspector, BFN::ControlFlowVisitor {
 public:
    typedef ordered_map<const IR::MAU::Table*, bitvec> cont_write_t;
    typedef struct { ordered_set<const IR::MAU::Table*> read, write; } access_t;

 private:
    const PhvInfo&                                        phv;
    DependencyGraph&                                      dg;
    std::map<cstring, access_t>                           access;
    std::map<PHV::Container, cont_write_t>                cont_write;

    std::vector<std::set<DependencyGraph::Graph::vertex_descriptor>>
    calc_topological_stage();

    void finalize_dependence_graph(void);

    /** Check that no ingress table ever depends on an egress table happening
     * first. */
    void verify_dependence_graph(void);

    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::MAU::Table *) override;
    bool preorder(const IR::MAU::Action *) override;
    bool preorder(const IR::MAU::InputXBarRead *) override;

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
        if (Log::verbose())
            std::cout << dg; }

    void flow_dead() override;
    void flow_merge(Visitor &v) override;

    void all_bfs(boost::default_bfs_visitor* vis);
    FindDependencyGraph *clone() const override { return new FindDependencyGraph(*this); }

    class AddDependencies;
    class UpdateAccess;
    class UpdateAttached;

 public:
    explicit FindDependencyGraph(const PhvInfo &phv, DependencyGraph& out)
    : phv(phv), dg(out) { joinFlows = true; }
};

#endif /* BF_P4C_MAU_TABLE_DEPENDENCY_GRAPH_H_ */
