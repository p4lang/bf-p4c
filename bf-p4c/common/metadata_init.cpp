#include "bf-p4c/common/metadata_init.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/mau/table_mutex.h"
#include "lib/path.h"
#include "lib/nullstream.h"

namespace {

/** A helper class that maps phv::Field to a IR::Expression.
 * It also provide a helper function to generate a IR::MAU::Instruction to initialize a
 * field to zero.
 */
class MapFieldToExpr : public Inspector {
 private:
    const PhvInfo& phv;
    ordered_map<int, const IR::Expression*>     fieldExpressions;

    profile_t init_apply(const IR::Node* root) override {
        fieldExpressions.clear();
        return Inspector::init_apply(root);
    }

    /// For every IR::Expression object in the program, populate the fieldExpressions map.
    /// This might return a Field for slice and cast expressions on fields. It will
    /// work out ok solely becuase this is a preorder and you don't prune, so it
    /// will also visit the child, which is the field, and then replace the entry in the map.
    bool preorder(const IR::Expression* expr) override {
        if (expr->is<IR::Cast>() || expr->is<IR::Slice>())
            return true;
        auto* f = phv.field(expr);
        if (!f)
            return true;
        fieldExpressions[f->id] = expr;
        return true; }

 public:
    explicit MapFieldToExpr(const PhvInfo& p)
        : phv(p) { }

    const IR::Expression* getExpr(const PHV::Field* field) const {
        BUG_CHECK(fieldExpressions.count(field->id),
                  "Missing IR::Expression mapping of %1%", field->name);
        return fieldExpressions.at(field->id)->clone();
    }

    /// Returns a instruction that initialize this field.
    const IR::MAU::Instruction* generateInitInstruction(const PHV::Field* f) const {
        BUG_CHECK(f, "Field is nullptr in generateInitInstruction");
        const IR::Expression* zero_expr = new IR::Constant(new IR::Type_Bits(f->size, false), 0);
        const IR::Expression* field_expr = getExpr(f);
        auto* prim = new IR::MAU::Instruction("set", { field_expr, zero_expr });
        return prim;
    }
};

/** Calculate tables that we can not insert initialization of field into, because they are after
 * a write to that field. Also, this pass build a map that maps a field to a set of actions
 * that wrote to this field.
 */
class AfterWriteTables : public BFN::ControlFlowVisitor, public MauInspector, TofinoWriteContext {
 private:
    /// Map a PHV::Field.id to a set a table that may show up after any write to the field.
    /// It is wrong to insert any initialization of this field to those tables.
    using AfterWriteTableList = std::map<int, std::set<const IR::MAU::Table*>>;

    const PhvInfo                                      &phv;
    const SharedIndirectAttachedAnalysis               &shared;
    AfterWriteTableList                                after_write_tables;
    std::set<int>                                      been_written;
    std::map<int, std::set<const IR::MAU::Action*>>    written_in;

    bool preorder(const IR::Expression *e) override {
        auto *f = phv.field(e);
        // Prevent visiting HeaderRefs in Members when PHV lookup fails, eg. for
        // $valid fields before allocatePOV.
        if (!f && e->is<IR::Member>()) return false;
        if (!f) return true;

        // We add this field into been_written list after calculating the
        // after_write_tables for f. The reason to do so is that we can insert
        // initialization on actions of this table as long as they do not set f.
        if (isWrite()) {
            been_written.insert(f->id);
            if (auto* action = findContext<IR::MAU::Action>()) {
                written_in[f->id].insert(action);
            } else {
                LOG1("Can not find action context for, f = " << f);
            }
        }
        return true;
    }

    bool preorder(const IR::MAU::Table* table) override {
        for (int id : been_written) {
            if (phv.field(id)->gress != table->gress) {
                continue; }
            after_write_tables[id].insert(table);
        }
        return true;
    }

    profile_t init_apply(const IR::Node* root) override {
        after_write_tables.clear();
        been_written.clear();
        written_in.clear();
        for (const auto& f : phv) {
            after_write_tables[f.id] = {};
            written_in[f.id] = {};
        }
        return Inspector::init_apply(root);
    }

    void end_apply() override {
        // Mark tables that share action profile to be after-written, if one table is.
        // XXX(yumin): This relation is transitive because each table can only have one
        // of each type of shared resource.
        for (const auto& f : phv) {
            std::vector<const IR::MAU::Table*> to_insert;
            for (const auto* tbl : after_write_tables[f.id]) {
                for (const auto* shared_tbl : shared.action_data_shared_tables(tbl)) {
                    to_insert.push_back(shared_tbl);
                    LOG5("Mark after-write for " << f.name << " because " << shared_tbl->name
                         << " is resource-shared table with " << tbl->name);
                }
            }
            // Insert all tables that shared action profile to be after write.
            for (const auto* tbl : to_insert) {
                after_write_tables[f.id].insert(tbl); }
        }

        if (LOGGING(5)) {
            LOG5("After Write Table List:");
            for (const auto& f : phv) {
                LOG5(f.name << " has: ");
                for (const auto* tbl : after_write_tables[f.id]) {
                    LOG5("After-write table: " << tbl->name); }
                for (const auto* act : written_in[f.id]) {
                    LOG5("Written in action: " << act->name); }
            }
        }
    }

    AfterWriteTables *clone() const override { return new AfterWriteTables(*this); }

    /// Unlike defuse, because this one does not to need to maintain an internal state
    /// that requires deletion, i.e. all the operations on intern state
    /// are `merge only`, which make it look like an identity to the following states.
    /// It is OK to clear been_written here, though fields will be added back when flow_merge,
    /// so we skip it here.
    void flow_dead() override {}

    void flow_merge(Visitor& other) override {
        AfterWriteTables& v = dynamic_cast<AfterWriteTables&>(other);
        been_written.insert(v.been_written.begin(), v.been_written.end());
        for (const auto& f : phv) {
            after_write_tables[f.id].insert(
                    v.after_write_tables[f.id].begin(), v.after_write_tables[f.id].end()); }
        for (const auto& kv : v.written_in) {
            written_in[kv.first].insert(kv.second.begin(), kv.second.end());
        }
    };

 public:
    explicit AfterWriteTables(const PhvInfo &p, const SharedIndirectAttachedAnalysis& shared)
        : phv(p), shared(shared) {
        joinFlows = true;
        visitDagOnce = false;
    }

    bool isAfterWrite(const PHV::Field* f, const IR::MAU::Table* table) const {
        return after_write_tables.at(f->id).count(table);
    }

    bool isWrittenIn(const PHV::Field* f, const IR::MAU::Action* act) const {
        BUG_CHECK(written_in.count(f->id), "Missing field written result %1%", f->name);
        return written_in.at(f->id).count(act);
    }
};

/** An adjacent list graph used for data flow dependency of a specific field.
 * The reason of not using boost::graph here is that, we have to perform some kind
 * flow_merge and prune on some event, which can not be done by boost::graph::dfs_visitor,
 * for the correctness of algorithm.
 * TODO(yumin): We can have our own visitor to support the above features and
 * then use boost::graph library.
 */
struct DataDependencyGraph {
    using VertexId         =  int;
    using AdjacentVertices =  std::vector<VertexId>;
    using AdjacentList     =  std::vector<AdjacentVertices>;

    std::map<const IR::MAU::Table*, VertexId> table_id;
    std::vector<const IR::MAU::Table*> id_table;

    AdjacentList adjacent_list;
    std::set<VertexId> starts;  // Nodes that does not have any dependency.

    /// Clear the data structure, removing all vertices, edges, and other
    /// internal state.
    void clear() {
        table_id.clear();
        id_table.clear();
        adjacent_list.clear();
        starts.clear();
    }

    /// Generate a new node corresponding to a table.
    VertexId getNode(const IR::MAU::Table* table) {
        if (table_id.count(table)) {
            return table_id.at(table);
        } else {
            VertexId id = id_table.size();
            id_table.push_back(table);
            table_id[table] = id;
            adjacent_list.push_back({});
            starts.insert(id);
            return id;
        }
    }

    /// Add a dependency: @p from must be done first before @p to.
    void addEdge(const IR::MAU::Table* from, const IR::MAU::Table* to) {
        auto from_id = getNode(from);
        auto to_id   = getNode(to);
        adjacent_list[from_id].push_back(to_id);
        starts.erase(to_id);
    }

    const IR::MAU::Table* getTable(VertexId id) const {
        BUG_CHECK(id >= 0 && id < int(id_table.size()), "Invalid Id: %1%", id);
        return id_table[id]; }
};

/** A base class for dfs-like searching, providing a helper function
 * to check whether a node is currently being on the visiting path.
 */
class DataDependencyGraphSearchBase {
 public:
    using VertexId = DataDependencyGraph::VertexId;
    const DataDependencyGraph& graph;
    std::set<VertexId> vis;

    class Visiting {
        DataDependencyGraphSearchBase& self;
        VertexId v;
     public:
        Visiting(DataDependencyGraphSearchBase& self, VertexId id)
            : self(self), v(id) { self.vis.insert(v); }
        ~Visiting() { self.vis.erase(v); }
    };

    void init_vis()                        { vis.clear(); }
    bool visited(VertexId id)              { return vis.count(id); }

    explicit DataDependencyGraphSearchBase(const DataDependencyGraph& graph)
        : graph(graph) { }
};

/** Initial @p field in actions in @p table, as long as not wrote in that action.
 */
struct MetaInitPlan {
    const PHV::Field* field;
    const IR::MAU::Table* table;
    MetaInitPlan(const PHV::Field* field,
                 const IR::MAU::Table* table)
        : field(field), table(table) { }
    bool operator<(const MetaInitPlan& other) const {
        if (field->id != other.field->id) {
            return field->id < other.field->id;
        } else if (table->name != other.table->name) {
            return table->name < other.table->name; }
        return false;
    }
};

#ifndef NDEBUG
// Used only in DEBUG mode
std::ostream& operator<<(std::ostream& s, const MetaInitPlan& c) {
    s << "Initialize "<< c.field << " ...at... " << c.table->name;
    return s;
}
#endif  // NDEBUG

/** A greedy algorithm that insert initialization as long as,
 * 1. Needed, meaning that there is uninitialized read after this table.
 * 2. Valid, in that,
 *    + This table will not be applied after any write to that field.
 *    + Field is not used in this table. If it is used in this table
 *      then initializing it here won't be able to eliminate that possible
 *      uninitialized read.
 * This greedy algorithm does not guarantee that all the metadata can be initialized.
 * Cases that it is known not able to handle,
 * 1. Table that has uninitialized reads does not have any data dependency before it.
 *    In this case, we need to insert a table to initialize the field, which will extend
 *    the dependency chain. It matches what glass does right now.
 *
 * This algorithm will not introduce any data dependency.
 *
 * TODO(yumin): It can be enhanced in following ways:
 * 1. Taking table_dep_tail_size into account.
 * 2. When there is no data dependency of that table, insert a generated table if estimated
 *    new table dependency is within limitation.
 */
class GreedyMetaInit : public DataDependencyGraphSearchBase {
 private:
    using TableList = ordered_set<const IR::MAU::Table*>;
    using InitTableResult = std::pair<TableList, bool>;

    const DependencyGraph                &dg;
    const AfterWriteTables               &after_write_tables;
    const TablesMutuallyExclusive        &mutex;
    const SharedIndirectAttachedAnalysis &shared;
    std::set<const IR::MAU::Table*> uses;
    std::set<const IR::MAU::Table*> writes;
    std::set<const IR::MAU::Table*> touched;
    const PHV::Field* field;

    bool usedIn(const IR::MAU::Table* tb)   { return uses.count(tb); }

    /** Allocate initialization for a field.
     * Algorithm:
     * DFS into the dependency graph. If a node is before some uninitialized read,
     * the field is not used in this table, and this table is not after any write to the
     * table, we initialized it in this table. This greedy strategy ensures that fields
     * are initialized to have the minimal live range, without introducing any new data
     * dependency.
     */
    InitTableResult greedy_allocate(VertexId v, const TableList& inited) {
        if (visited(v)) {
            LOG1("Found a loop in data dependency table");
            return { { }, false }; }

        Visiting visiting(*this, v);
        auto* table = graph.getTable(v);
        bool on_use = usedIn(table);
        bool need_init = false;
        TableList init_rst;

        // Already in initialization plans.
        if (inited.count(table)) {
            return { { }, false }; }

        // If this table is after write, then we can not insert initialization
        // onto or after this table. Tables followed by this table will either
        // be initialized, or have some other uninitialized path, which will be
        // visited.
        if (after_write_tables.isAfterWrite(field, table)) {
            return {init_rst, on_use}; }
        // If data-shared table is after write, then we can not neither.
        for (const auto* shared_tbl : shared.action_data_shared_tables(table)) {
            if (after_write_tables.isAfterWrite(field, shared_tbl)) {
                return {init_rst, on_use}; } }

        for (const auto& next : graph.adjacent_list[v]) {
            if (!visited(next)) {
                auto rst = greedy_allocate(next, inited);
                // Keep all the initialization that following nodes has done.
                for (const auto& tbl : rst.first) {
                    init_rst.insert(tbl); }
                need_init = (need_init || rst.second);
            }
        }

        // Insert Initialization if,
        // 1. Needed.
        // 2. This table does not uses of that field.
        // 3. Not a table possibly after writting, neither does shared tables. (already checked)
        if (need_init && !on_use) {
            bool can_insert = true;
            if (willCreateNewDepsWithTouched(table)) {
                can_insert = false; }
            // If init at this table, need to init at all action-data-shared tables as well.
            for (auto* shared_tbl : shared.action_data_shared_tables(table)) {
                if (willCreateNewDepsWithTouched(shared_tbl)) {
                    can_insert = false;
                    break; } }
            // Add initialization in this table and data-shared tables.
            if (can_insert) {
                init_rst = { table };
                for (auto* shared_tbl : shared.action_data_shared_tables(table)) {
                    init_rst.insert(shared_tbl); }
                need_init = false;
            }
        }

        return {init_rst, on_use || need_init};
    }

 public:
    GreedyMetaInit(const DependencyGraph& dg,
                   const DataDependencyGraph& graph,
                   const FieldDefUse& defuse,
                   const AfterWriteTables& af,
                   const TablesMutuallyExclusive& mutex,
                   const SharedIndirectAttachedAnalysis &shared,
                   const PHV::Field* field)
        : DataDependencyGraphSearchBase(graph), dg(dg), after_write_tables(af),
          mutex(mutex), shared(shared), field(field) {
        // Populate uses.
        for (const auto& use : defuse.getAllUses(field->id)) {
            if (auto* table = use.first->to<IR::MAU::Table>()) {
                uses.insert(table);
                touched.insert(table); } }
        // Populate writes.
        for (const auto& write : defuse.getAllDefs(field->id)) {
            if (auto* table = write.first->to<IR::MAU::Table>()) {
                writes.insert(table);
                touched.insert(table); } }
    }

    bool willCreateNewDepsWithTouched(const IR::MAU::Table* candidate) {
        for (const auto& other : touched) {
            if (willCreateNewDeps(candidate, other)) {
                return true; } }
        return false;
    }

    /// Initialization will create a new dependency when:
    /// 1. Not mutex with some other table that read/write to the field.
    /// 2. and it does not have data dependency with that table.
    bool willCreateNewDeps(const IR::MAU::Table* candidate, const IR::MAU::Table* other) {
        if (candidate == other) {
            return false; }
        if (mutex(candidate, other)) {
            return false; }
        if (dg.happens_before(candidate, other) || dg.happens_before(other, candidate)) {
            return false; }
        LOG2("Init " << field->name << " ..at.. " << candidate->name << " will create "
             << "dependency with " << other->name << ", skipped.");
        return true;
    }

    /** Update the initialization list. Insert into list if it is mutex with previous tables.
     * or it is a data dependency to all previous tables.
     */
    TableList updateInitList(const TableList& previous, const TableList& candidates) {
        if (candidates.empty()) {
            return previous; }

        TableList rst = previous;
        bool can_init = true;
        for (const auto& candidate : candidates) {
            if (willCreateNewDepsWithTouched(candidate)) {
                can_init = false; }
            // Either all tables can be inserted or none of them,
            // because if one can not be inserted, then there will
            // be a path that the field is uninitialized. Also,
            // since we pack table and its action data shared tables all
            // inside candidates, if one can not, none of them can.
            for (const auto& other : candidates) {
                if (willCreateNewDeps(candidate, other)) {
                    can_init = false;
                    break; } }
            for (const auto& other : rst) {
                if (willCreateNewDeps(candidate, other)) {
                    can_init = false;
                    break; } }
        }
        if (can_init) {
            for (const auto& candidate : candidates) {
                LOG2("Plan to init " << field->name << " at " << candidate->name);
                rst.insert(candidate);
            }
        }
        return rst;
    }

    /** An algorithm to generate metadata initialization.
     */
    std::set<MetaInitPlan> generateMetaInitPlans() {
        LOG4("Generating InitPlan for " << field);
        init_vis();
        std::set<MetaInitPlan> result;
        TableList init_at_tables;
        for (const auto& start : graph.starts) {
            LOG4("Start from, start = " << graph.getTable(start)->name);
            BUG_CHECK(!visited(start), "Not a valid start: %1%", start);
            auto rst = greedy_allocate(start, init_at_tables);
            // if the any start table need init, then,
            // no need to do initialization on this path.
            if (rst.second) {
                continue; }

            init_at_tables = updateInitList(init_at_tables, rst.first);
        }

        // Generate meta init plans.
        for (const auto& tb : init_at_tables) {
            result.insert(MetaInitPlan(field, tb)); }
        return result;
    }
};

/** Generate metadata initialization using the greedy algorithm.
 * This pass will first build a table data dependency graph and then
 * for each field that can be initialized, generate initialization plan,
 * which specify `init field.x on all actions(excluding actions already
 * write to the field) in table.y.
 */
class ComputeMetadataInit : public Inspector {
    const TablesMutuallyExclusive        &mutex;
    const SharedIndirectAttachedAnalysis &shared;
    const PhvInfo                        &phv;
    const FieldDefUse                    &defuse;
    const DependencyGraph                &dg;
    const AfterWriteTables               &after_write_tables;
    const ordered_set<const PHV::Field*> &pragma_no_init;

    std::vector<const PHV::Field*> to_be_inited;
    DataDependencyGraph graph;

    /** A field can be initialized if:
     * 1. container valid bits are not used for some purposes.
     * 2. not deparsed to tm.
     * 3. not a bridged field.
     * 4. has uninitialized read and never extracted in parser.
     */
    void calcToBeInitedFields() {
        int n_bits = 0;
        for (const auto& f : phv) {
            if (f.read_container_valid_bit()) continue;
            if (f.deparsed_to_tm()) continue;
            if (f.bridged) continue;
            if (pragma_no_init.count(&f)) {
                LOG1("\tIgnoring metadata initialization because of pa_no_init: " << f);
                continue;
            }
            if (!defuse.hasUninitializedRead(f.id)) continue;

            auto& defs = defuse.getAllDefs(f.id);
            bool defined_in_parser =
                std::any_of(defs.begin(), defs.end(), [] (const FieldDefUse::locpair& loc) {
                    return loc.first->is<IR::BFN::ParserState>()
                    && !loc.second->is<ImplicitParserInit>(); });
            if (defined_in_parser) {
                continue; }

            LOG4("MetaInit, Can be initialized, f = " << f);
            n_bits += f.size;
            to_be_inited.push_back(&f);
        }
        LOG4("TOTAL uninitialized bits: " << n_bits);
    }

    /// Build data dependency graph by simply adding dependency edges.
    void buildControlGraph() {
        DependencyGraph::Graph::edge_iterator e, e_end;
        for (std::tie(e, e_end) = edges(dg.g); e != e_end; ++e) {
            // We only need the subgraph of tables that is a actual dependency.
            if (dg.g[*e] == DependencyGraph::CONTROL ||
                dg.g[*e] == DependencyGraph::ANTI) continue;

            BUG_CHECK(dg.g[*e] == DependencyGraph::IXBAR_READ ||
                      dg.g[*e] == DependencyGraph::ACTION_READ ||
                      dg.g[*e] == DependencyGraph::REDUCTION_OR_OUTPUT ||
                      dg.g[*e] == DependencyGraph::REDUCTION_OR_READ ||
                      dg.g[*e] == DependencyGraph::OUTPUT,
                     "Unknown dependency table label");

            auto src = boost::source(*e, dg.g);
            auto dest = boost::target(*e, dg.g);
            auto src_table = dg.g[src];
            auto dest_table = dg.g[dest];
            graph.addEdge(src_table, dest_table);
        }
    }

    // Run the algorithm.
    profile_t init_apply(const IR::Node *root) override {
        // Reset state.
        to_be_inited.clear();
        graph.clear();
        init_summay.clear();

        calcToBeInitedFields();
        buildControlGraph();
        for (const auto* f : to_be_inited) {
            GreedyMetaInit init_strategy(dg, graph, defuse, after_write_tables,
                                         mutex, shared, f);
            std::set<MetaInitPlan> plans = init_strategy.generateMetaInitPlans();
            for (const auto& v : plans) {
                init_summay[v.table].push_back(v.field);
            }
        }
        return Inspector::init_apply(root);
    }

 public:
    ComputeMetadataInit(const TablesMutuallyExclusive& mutex,
                        const SharedIndirectAttachedAnalysis &shared,
                        const PhvInfo& phv,
                        const FieldDefUse& defuse,
                        const DependencyGraph& dg,
                        const AfterWriteTables& after_write,
                        const ordered_set<const PHV::Field*>& pragma)
        : mutex(mutex), shared(shared), phv(phv),
          defuse(defuse), dg(dg), after_write_tables(after_write), pragma_no_init(pragma) { }

    std::map<const IR::MAU::Table*, std::vector<const PHV::Field*>> init_summay;

    const DataDependencyGraph& getDataDepGraph() {
        return graph; }
};

/** Insert initialization to actions.
 */
class ApplyMetadataInitialization : public MauTransform {
    const ComputeMetadataInit        &rst;
    const MapFieldToExpr             &phv_to_expr;
    const AfterWriteTables           &after_write;

 public:
    ApplyMetadataInitialization(const ComputeMetadataInit& rst,
                                const MapFieldToExpr& phv_to_expr,
                                const AfterWriteTables& after_write)
        : rst(rst), phv_to_expr(phv_to_expr), after_write(after_write) { }

    const IR::MAU::Action *postorder(IR::MAU::Action * act) override {
        auto* act_orig = getOriginal<IR::MAU::Action>();
        auto* table_orig = findOrigCtxt<IR::MAU::Table>();
        if (!rst.init_summay.count(table_orig)) {
            return act; }
        auto& fields = rst.init_summay.at(table_orig);
        for (const auto& f : fields) {
            if (after_write.isWrittenIn(f, act_orig)) {
                LOG4("Field " << f->name << " has been written in " << act_orig->name.name
                     << " .. skipped");
                continue; }
            auto* prim = phv_to_expr.generateInitInstruction(f);
            act->action.push_back(prim);
        }
        return act;
    }
};

/** Insert a table in the beginning of the pipe to initialize all fields
 * that are still uninitialized. This pass is an experimental, and it is not enabled
 * by default. It will definitely introduce new dependencies. Also, it is not correctly
 * right now in that it will make mutex exclusive field be initialized in a action, which
 * will make them not mutex anymore.
 */
class ApplyAlwaysInit : public MauTransform {
    const PhvInfo                    &phv;
    const FieldDefUse                &defuse;
    const MapFieldToExpr             &phv_to_expr;

 public:
    ApplyAlwaysInit(const PhvInfo& phv,
                    const FieldDefUse& defuse,
                    const MapFieldToExpr& phv_to_expr)
        : phv(phv), defuse(defuse), phv_to_expr(phv_to_expr) { }

    const IR::MAU::TableSeq* addInit(const IR::MAU::TableSeq* seq, gress_t gress) {
        auto* action = new IR::MAU::Action("___init___");
        action->default_allowed = action->init_default = true;
        auto* table  = new IR::MAU::Table(
                "__init_metadata_begin_" + cstring::to_cstring(gress), gress);
        table->actions[action->name.originalName] = action;
        auto p4name = "__init_metadata_begin_p4_" + cstring::to_cstring(gress);
        table->match_table = new IR::P4Table(
                p4name.c_str(), new IR::TableProperties());
        auto* table_seq = new IR::MAU::TableSeq();
        table_seq->tables.push_back(table);
        for (const auto* tb : seq->tables) {
            table_seq->tables.push_back(tb); }

        // TODO(yumin): Fields that are mutex should be initialized in their closed
        // control branch.
        for (const auto& f : phv) {
            if (f.gress != gress) continue;
            if (f.read_container_valid_bit()) continue;
            if (f.deparsed_to_tm()) continue;
            if (f.bridged) continue;
            if (!defuse.hasUninitializedRead(f.id)) continue;

            auto& defs = defuse.getAllDefs(f.id);
            bool defined_in_parser =
                std::any_of(defs.begin(), defs.end(), [] (const FieldDefUse::locpair& loc) {
                    return loc.first->is<IR::BFN::ParserState>()
                    && !loc.second->is<ImplicitParserInit>(); });
            if (defined_in_parser) {
                continue; }
            auto* prim = phv_to_expr.generateInitInstruction(&f);
            action->action.push_back(prim);
        }
        LOG1("Adding init table to the beginning");
        LOG1(table);
        return table_seq;
    }

    const IR::BFN::Pipe* postorder(IR::BFN::Pipe* pipe) {
        pipe->thread[INGRESS].mau = addInit(pipe->thread[INGRESS].mau, INGRESS);
        pipe->thread[EGRESS].mau = addInit(pipe->thread[EGRESS].mau, EGRESS);
        return pipe;
    }
};

/// A helper class to generate a table dependency graph dot file.
class TableGraphGen : public Inspector {
 private:
    const DependencyGraph& dg;
    const DataDependencyGraph& dfg;

    void end_apply() {
        gen("table_graph"); }

    cstring purify(cstring str) {
        return str.replace('-', '_'); }

    void gen(cstring file_name) {
        auto path = file_name + ".dot";
        auto output = openFile(path, false);
        if (output == nullptr) {
            ::error("Failed to open file %1%", path);
            return;
        }

        std::set<const IR::MAU::Table*> starts;
        for (const auto& s : dfg.starts) {
            starts.insert(dfg.getTable(s)); }

        (*output) << "digraph " << "table" << "{" << std::endl;

        typename DependencyGraph::Graph::vertex_iterator v, v_end;
        typename DependencyGraph::Graph::edge_iterator out, out_end;
        const auto& dep_graph = dg.g;

        for (boost::tie(v, v_end) = boost::vertices(dep_graph);
             v != v_end;
             ++v) {
            cstring label = dep_graph[*v]->name;
            cstring shape = "rectangle";
            if (starts.count(dep_graph[*v])) {
                shape = "doublecircle";
            }
            (*output) << purify(label) << " [shape=" << shape << ",label=\"" <<
                label << "\"]" << std::endl; }

        std::set<std::pair<const IR::MAU::Table*, const IR::MAU::Table*>> printed;
        for (boost::tie(out, out_end) = boost::edges(dep_graph);
             out != out_end;
             ++out) {
            cstring label;
            auto edge_type = dep_graph[*out];
            auto source = dg.g[boost::source(*out, dep_graph)];
            auto target = dg.g[boost::target(*out, dep_graph)];

            if (printed.count(std::make_pair(source, target))) continue;
            printed.insert(std::make_pair(source, target));

            if (edge_type == DependencyGraph::ANTI) {
                label = "anti";
                continue;
            } else if (edge_type == DependencyGraph::CONTROL) {
                label = "ctrl";
                continue;
            } else if (edge_type == DependencyGraph::IXBAR_READ) {
                label = "ixbar_read";
            } else if (edge_type == DependencyGraph::ACTION_READ) {
                label = "action_read";
            } else if (edge_type == DependencyGraph::OUTPUT) {
                label = "output";
            } else if (edge_type == DependencyGraph::REDUCTION_OR_OUTPUT) {
                label = "output*";
            } else if (edge_type == DependencyGraph::REDUCTION_OR_READ) {
                label = "action_read*";
            }

            *output << purify(source->name) << " -> " << purify(target->name) <<
                " [label=\"" << label << "\"]" << std::endl;
        }
        *output << "}" << std::endl;
    }

 public:
    TableGraphGen(const DependencyGraph& dg,
                  const DataDependencyGraph& dfg)
        : dg(dg), dfg(dfg) { }
};

/// Print out uninitialized metadata.
class MetadataInitSummary : public Inspector {
 private:
    const PhvInfo& phv;
    const FieldDefUse& defuse;

    void end_apply() {
        int n_bits = 0;
        for (const auto& f : phv) {
            if (f.read_container_valid_bit()) continue;
            if (f.deparsed_to_tm()) continue;
            if (f.bridged) continue;
            if (!defuse.hasUninitializedRead(f.id)) continue;

            auto& defs = defuse.getAllDefs(f.id);
            bool defined_in_parser =
                std::any_of(defs.begin(), defs.end(), [] (const FieldDefUse::locpair& loc) {
                    return loc.first->is<IR::BFN::ParserState>()
                    && !loc.second->is<ImplicitParserInit>(); });
            if (defined_in_parser) {
                continue; }

            n_bits += f.size;
            LOG3("MetadataInit failed to init: " << f);
        }
        LOG1("Total uninitialized metadata bits: " << n_bits);
    }

 public:
    MetadataInitSummary(const PhvInfo& phv,
                        const FieldDefUse& defuse)
        : phv(phv), defuse(defuse) { }
};

}  // namespace

MetadataInitialization::MetadataInitialization(bool always_init_metadata, const PhvInfo& phv,
                                               FieldDefUse& defuse, const DependencyGraph& dg) {
    auto* mutex = new TablesMutuallyExclusive();
    auto* shared_tables = new SharedIndirectAttachedAnalysis(*mutex);
    auto* field_to_expr = new MapFieldToExpr(phv);
    auto* after_write = new AfterWriteTables(phv, *shared_tables);
    auto* pragma_no_init = new PragmaNoInit(phv);
    auto* gen_init_plans = new ComputeMetadataInit(*mutex, *shared_tables,
                                                   phv, defuse, dg, *after_write,
                                                   pragma_no_init->getFields());
    auto* apply_init_insert =
        new ApplyMetadataInitialization(*gen_init_plans, *field_to_expr, *after_write);
    addPasses({
        mutex,
        shared_tables,
        field_to_expr,
        after_write,
        // new TableGraphGen(dg, init_alloc->getDataDepGraph()),
        pragma_no_init,
        gen_init_plans,
        apply_init_insert,
        always_init_metadata ? new ApplyAlwaysInit(phv, defuse, *field_to_expr) : nullptr,
        &defuse,
        new MetadataInitSummary(phv, defuse),
    });
}
