#include "bf-p4c/mau/table_placement.h"

#include <boost/range/adaptor/reversed.hpp>

#include <algorithm>
#include <list>
#include <sstream>
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/logging/manifest.h"
#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/field_use.h"
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/table_summary.h"
#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/log.h"
#include "lib/pointer_wrapper.h"
#include "lib/safe_vector.h"
#include "lib/set.h"
#include "bf-p4c/ir/table_tree.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_analysis.h"

/********************************************************************************************
 ** Table placement is done with a fairly simple greedy allocator in a single Transform pass
 ** organized so as to allow backtracking within the greedy allocation, though we do not
 ** currently do any backtracking here.
 **
 ** All of the decisions for placement are done in the preorder(IR::MAU::Pipe *) method --
 ** in this method we go over all the tables in the pipe (directly, not using the visitor
 ** infrastructure) making decisions about which tables should be allocated to which logical
 ** tables and what ixbar an memory resources to use for them.  All of these decisions are
 ** stored in Placed objects (a linked list with one Placed object per logical table) that
 ** is built up in a write-once fashion to allow for backtracking (we can at any time throw
 ** away nodes from the front of the list, backing up and continuing from an earlier point).
 **
 ** After preorder(Pipe) method completes, the transform visits all of the tables in the
 ** pipeline, rewriting them to match the placement decisions made in the Placed list.  This
 ** involves actually combining gateways intopo match tables and splitting tables across
 ** multiple logical tables as decided in the information recorded in the Placed list.
 **
 ** The placement process itself is a fairly standard greedy allocator -- we maintain a
 ** work list (called 'work' throughout the code) of TableSeq objects from which the next
 ** table can be chosen.  We look at all the tables in the work list and, for each table
 ** that can be placed next, we create a new 'Placed' object linked onto the front of the
 ** 'done' list for that placement.  This may involve revisiting the specific resources used
 ** for tables already placed in this stage, though not the logical table assignments.
 ** Once these possible placements have all been created, we compare them with a variety
 ** of metrics encapsulated in the 'is_better' method to determine which is the best choice --
 ** we keep that (one) Placed and repeat, placing additional tables.
 **
 ** One complex part of this process is maintaining the 'work' list.  Because of the limits
 ** of Tofino1 next table processing, when a table A is assigned to a specific logical table,
 ** all tables that are control dependent on A must be assigned to logical tables before any
 ** table after A in the parent control flow.  That means when we place A, and add all control
 ** dependent TableSeqs of A to the work list, we (temporarily) remove the seq containing A
 ** from the work list.  We record that removed seq as the 'parent' of the added seqs, so that
 ** we can add it back once those children are all placed.  These relationships are recorded
 ** in GroupPlace objects (which are what is actually in the work list) -- one for each
 ** IR::MAU::TableSeq being processed.
 **
 ** For Tofino2, we don't have the above restriction, so we don't remove the parent
 ** GroupPlace from the worklist, but we still maintain the parent/child info even though it
 ** isn't really needed (minimizing the difference between Tofino1 and Tofino2 here).
 */

int TablePlacement::placement_round = 1;

TablePlacement::TablePlacement(const BFN_Options &opt, const DependencyGraph* d,
                               const TablesMutuallyExclusive &m, PhvInfo &p,
                               const LayoutChoices &l, const SharedIndirectAttachedAnalysis &s,
                               SplitAttachedInfo &sia, TableSummary &summary_)
: options(opt), deps(d), mutex(m), phv(p), lc(l), siaa(s), ddm(ntp, con_paths, *d), att_info(sia),
  summary(summary_) {}

bool TablePlacement::backtrack(trigger &trig) {
    // If a table does not fit in the available stages, then TableSummary throws an exception.
    // TablePlacement catches that exception and re-runs table placement without considering
    // container conflicts. This gives the "idealized" resource-sensitive table placement that is
    // then used by PHV allocation to minimize the number of container conflicts seen in the final
    // allocation.
    if (trig.is<NoContainerConflictTrigger::failure>()) {
        auto t = dynamic_cast<NoContainerConflictTrigger::failure *>(&trig);
        ignoreContainerConflicts = t->ignoreContainerConflicts;
        return true; }
    ignoreContainerConflicts = false;
    if (trig.is<RedoTablePlacement>()) {
        summary.FinalizePlacement();
        return true; }
    return false;
}

Visitor::profile_t TablePlacement::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    summary.clearPlacementErrors();
    root->apply(ntp);
    root->apply(con_paths);
    LOG1("Table Placement ignores container conflicts? " << ignoreContainerConflicts);
    if (BackendOptions().create_graphs) {
        static unsigned invocation = 0;
        auto pipeId = root->to<IR::BFN::Pipe>()->id;
        auto graphsDir = BFNContext::get().getOutputDirectory("graphs", pipeId);
        cstring fileName = "table_dep_graph_placement_" + std::to_string(invocation++);
        std::ofstream dotStream(graphsDir + "/" + fileName + ".dot", std::ios_base::out);
        DependencyGraph::dump_viz(dotStream, *deps);
        Logging::Manifest::getManifest().addGraph(pipeId, "table", fileName,
                                                  INGRESS);  // this should be both really!
    }
    return MauTransform::init_apply(root);
}

struct TablePlacement::TableInfo {
    int uid = -1;
    const IR::MAU::Table        *table;
    const IR::MAU::TableSeq     *parent;
    bitvec                      tables;  // this table and all tables control dependent on it
};
struct TablePlacement::TableSeqInfo {
    bool        root = false;
    int         uid = -1;
    bitvec      tables;  // the tables in the seqence and their control dependent children
    ordered_set<const IR::MAU::Table *> refs;  // parent tables of this seq
};

class TablePlacement::SetupInfo : public Inspector {
    TablePlacement &self;
    bool preorder(const IR::MAU::Table *tbl) override {
        BUG_CHECK(!self.tblInfo.count(tbl), "Table in both ingress and egress?");
        auto &info = self.tblInfo[tbl];
        info.uid = self.tblInfo.size() - 1;
        info.table = tbl;
        info.parent = getParent<IR::MAU::TableSeq>();
        BUG_CHECK(info.parent, "parent of Table is not TableSeq");
        BUG_CHECK(!self.tblByName.count(tbl->name), "Duplicate tables named %s: %s and %s",
                  tbl->name, tbl, self.tblByName.at(tbl->name)->table);
        self.tblByName[tbl->name] = &info;
        return true; }
    void revisit(const IR::MAU::Table *) override {
        BUG("Table appears twice"); }
    void postorder(const IR::MAU::Table *tbl) override {
        auto &info = self.tblInfo.at(tbl);
        info.tables[info.uid] = 1;
        for (auto &n : tbl->next)
            info.tables |= self.seqInfo.at(n.second).tables; }
    bool preorder(const IR::MAU::BackendAttached *ba) override {
        visitAgain();
        BUG_CHECK(getParent<IR::MAU::Table>(), "parent of BackendAttached is not Table");
        self.attached_to[ba->attached].insert(getParent<IR::MAU::Table>());
        return false; }
    bool preorder(const IR::MAU::TableSeq *seq) override {
        BUG_CHECK(!self.seqInfo.count(seq), "TableSeq in both ingress and egress?");
        auto &info = self.seqInfo[seq];
        info.uid = self.seqInfo.size() - 1;
        if (getContext()) {
            auto tbl = getParent<IR::MAU::Table>();
            BUG_CHECK(tbl, "parent of TableSeq is not a table");
            info.refs.insert(tbl);
        } else {
            info.root = true; }
        return true; }
    void revisit(const IR::MAU::TableSeq *seq) override {
        BUG_CHECK(self.seqInfo.count(seq), "TableSeq not present");
        BUG_CHECK(!self.seqInfo[seq].refs.empty(), "TableSeq is root and non-root");
        auto tbl = getParent<IR::MAU::Table>();
        BUG_CHECK(tbl, "parent of TableSeq is not a table");
        self.seqInfo[seq].refs.insert(tbl); }
    void postorder(const IR::MAU::TableSeq *seq) override {
        auto &tables = self.seqInfo.at(seq).tables;
        for (auto t : seq->tables)
            tables |= self.tblInfo.at(t).tables; }
    bool preorder(const IR::MAU::Action *) override { return false; }
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::V1Table *) override { return false; }

 public:
    explicit SetupInfo(TablePlacement &self_) : self(self_) {}
};


struct TablePlacement::GroupPlace {
    /* tracking the placement of a group of tables from an IR::MAU::TableSeq
     *   parents    groups that must wait until this group is fully placed before any more
     *              tables from them may be placed (so next_table setup works)
     *   ancestors  union of parents and all parent's ancestors
     *   seq        the TableSeq being placed for this group */
    const TablePlacement                &self;
    ordered_set<const GroupPlace *>     parents, ancestors;
    const IR::MAU::TableSeq             *seq;
    const TablePlacement::TableSeqInfo  &info;
    int                                 depth;  // just for debugging?
    GroupPlace(const TablePlacement &self_, ordered_set<const GroupPlace*> &work,
               const ordered_set<const GroupPlace *> &par, const IR::MAU::TableSeq *s)
    : self(self_), parents(par), ancestors(par), seq(s), info(self.seqInfo.at(s)), depth(1) {
        for (auto p : parents) {
            if (depth <= p->depth)
                depth = p->depth+1;
            ancestors |= p->ancestors; }
        LOG4("    new seq " << seq->id << " depth=" << depth << " anc=" << ancestors);
        work.insert(this);
        if (Device::numLongBranchTags() == 0 || self.options.disable_long_branch) {
            // Table run only with next_table, so can't continue placing ancestors until
            // this group is finished
            if (LOGGING(5)) {
                for (auto a : ancestors)
                    if (work.count(a))
                        LOG5("      removing ancestor " << a->seq->id << " from work list"); }
            work -= ancestors; } }

    /// finish a table group -- remove it from the work queue and append its parents
    /// unless the parent or a descendant is already present in the queue.
    /// @returns an iterator to the newly added groups, if any.
    ordered_set<const GroupPlace *>::iterator finish(ordered_set<const GroupPlace *> &work) const {
        auto rv = work.end();
        LOG5("      removing " << seq->id << " from work list (a)");
        work.erase(this);
        for (auto p : parents) {
            if (work.count(p)) continue;
            bool skip = false;
            for (auto *gp : work) {
                if (gp->ancestors.count(p)) {
                    skip = true;
                    break; } }
            if (skip) continue;
            LOG5("      appending " << p->seq->id << " to work queue");
            auto t = work.insert(p);
            if (rv == work.end()) rv = t.first; }
        return rv; }
    void finish_if_placed(ordered_set<const GroupPlace*> &, const Placed *) const;
    static bool in_work(ordered_set<const GroupPlace*> &work, const IR::MAU::TableSeq *s) {
        for (auto pl : work)
            if (pl->seq == s) return true;
        return false; }
    friend std::ostream &operator<<(std::ostream &out,
        const ordered_set<const TablePlacement::GroupPlace *> &set) {
        out << "[";
        const char *sep = " ";
        for (auto grp : set) {
            out << sep << grp->seq->id;
            sep = ", "; }
        out << (sep+1) << "]";
        return out; }
};

struct TablePlacement::Placed {
    /* A linked list of table placement decisions, from last table placed to first (so we
     * can backtrack and create different lists as needed) */
    TablePlacement              &self;
    const int                   id;
    const Placed                *prev = 0;
    const GroupPlace            *group = 0;  // work group chosen from
    cstring                     name;
    int                         entries = 0;
    int                         requested_stage_entries = -1;  // pragma stage requested entries
    attached_entries_t          attached_entries;
    bitvec                      placed;  // fully placed tables after this placement
    bitvec                      match_placed;  // tables where the match table is fully placed,
                                               // but indirect attached tables may not be
    int                         complete_shared = 0;  // tables that share attached tables and
                                        // are completely placed by placing this
    cstring                     stage_advance_log;  // why placement had to go to next stage

    /// True if the table needs to be split across multiple stages, because it
    /// can't fit within a single stage (eg. not enough entries in the stage).
    bool                        need_more = false;
    /// True if the match table (only) needs to be split across stages
    bool                        need_more_match = false;
    // the above two flags are redundant with info in 'placed' and 'match_placed', so could
    // be eliminated and uses replaced by checks of those bitvecs

    cstring                     gw_result_tag;
    const IR::MAU::Table        *table, *gw = 0;
    int                         stage = 0, logical_id = -1;
    /// Information on which stage table this table is associated with.  If the table is
    /// never split, then the stage_split should be -1
    int                         initial_stage_split = -1;
    int                         stage_split = -1;
    StageUseEstimate            use;
    TableResourceAlloc          resources;
    Placed(TablePlacement &self_, const IR::MAU::Table *t, const Placed *done)
        : self(self_), id(++uid_counter), prev(done), table(t) {
        if (t) { name = t->name; }
        if (done) {
            stage = done->stage;
            placed = done->placed;
            match_placed = done->match_placed; }
        traceCreation();
    }

    // test if this table is placed
    bool is_placed(const IR::MAU::Table *tbl) const {
        return placed[self.tblInfo.at(tbl).uid]; }
    bool is_placed(cstring tbl) const {
        return placed[self.tblByName.at(tbl)->uid]; }
    bool is_match_placed(const IR::MAU::Table *tbl) const {
        return match_placed[self.tblInfo.at(tbl).uid]; }
    // test if this table or seq and all its control dependent tables are placed
    bool is_fully_placed(const IR::MAU::Table *tbl) const {
        return placed.contains(self.tblInfo.at(tbl).tables); }
    bool is_fully_placed(const IR::MAU::TableSeq *seq) const {
        return placed.contains(self.seqInfo.at(seq).tables); }
    const GroupPlace *find_group(const IR::MAU::Table *tbl) const {
        for (auto p = this; p; p = p->prev) {
            if (p->table == tbl || p->gw == tbl)
                return p->group; }
        BUG("Can't find group for %s", tbl->name);
        return nullptr; }

    void gateway_merge(const IR::MAU::Table*, cstring);

    /// Update a Placed object to reflect attached tables being allocated in the same stage due
    /// to another table being added to the stage.
    void update_attached(Placed *latest) {
        if (need_more && !need_more_match) {
            need_more = false;
            for (auto *ba : table->attached) {
                if (ba->attached->direct) continue;
                BUG_CHECK(attached_entries.count(ba->attached),
                          "initial_stage_and_entries mismatch for %s", ba->attached);
                auto it = latest->attached_entries.find(ba->attached);
                if (it != latest->attached_entries.end()) {
                    BUG_CHECK(attached_entries[ba->attached] == 0 ||
                              attached_entries[ba->attached] == it->second,
                              "inconsistent size for %s", ba->attached);
                    attached_entries[ba->attached] = it->second; }
                if (attached_entries[ba->attached] < ba->attached->size)
                    need_more = true; }
            if (!need_more) {
                LOG3("    " << table->name << " is now also placed");
                latest->complete_shared++;
                placed[self.tblInfo.at(table).uid] = 1; } }
        if (prev)
            placed |= prev->placed; }

    // update the 'placed' bitvec to reflect tables that were previously partly placed and
    // are now fully placed.
    void update_for_partly_placed(const ordered_set<const IR::MAU::Table *> &partly_placed) {
        for (auto *pp : partly_placed) {
            if (placed[self.tblInfo.at(pp).uid]) continue;  // already done
            if (!match_placed[self.tblInfo.at(pp).uid]) continue;  // not yet done match
            bool check = false;
            // don't bother to recheck tables for which we have not added any attached entries
            for (auto *ba : pp->attached) {
                if (ba->attached->direct) continue;
                if (attached_entries.count(ba->attached)) {
                    check = true;
                    break; } }
            if (!check) continue;
            bool need_more = false;
            for (auto *ba : pp->attached) {
                if (ba->attached->direct) continue;
                int size = 0;
                for (const Placed *p = this; p; p = p->prev) {
                    if (p->attached_entries.count(ba->attached)) {
                        size += p->attached_entries.at(ba->attached);
                        if (size >= ba->attached->size)
                            break; } }
                if (size < ba->attached->size) {
                    need_more = true;
                    break; } }
            if (!need_more) {
                LOG3("    " << pp->name << " is now also placed");
                complete_shared++;
                placed[self.tblInfo.at(pp).uid] = 1; } } }

    // update the action/meter formats in the TableResourceAlloc to match the StageUseEstimate
    void update_formats() {
        if (auto *af = use.preferred_action_format())
            resources.action_format = *af;
        if (auto *mf = use.preferred_meter_format())
            resources.meter_format = *mf; }

    void setup_logical_id() {
        if (prev && prev->stage == stage) {
            if (prev->table->gateway_only())
                logical_id = prev->logical_id + 1;
            else
                logical_id = prev->logical_id + prev->use.preferred()->logical_tables();
        } else {
            logical_id = stage * StageUse::MAX_LOGICAL_IDS;
        }
    }

    friend std::ostream &operator<<(std::ostream &out, const TablePlacement::Placed *pl) {
        out << pl->name;
        return out; }

    Placed(const Placed &p)
        : self(p.self), id(uid_counter++), prev(p.prev), group(p.group), name(p.name),
          entries(p.entries), requested_stage_entries(p.requested_stage_entries),
          attached_entries(p.attached_entries), placed(p.placed),
          match_placed(p.match_placed), complete_shared(p.complete_shared),
          stage_advance_log(p.stage_advance_log),
          need_more(p.need_more), need_more_match(p.need_more_match),
          gw_result_tag(p.gw_result_tag), table(p.table), gw(p.gw), stage(p.stage),
          logical_id(p.logical_id), initial_stage_split(p.initial_stage_split),
          stage_split(p.stage_split), use(p.use), resources(p.resources)
          { traceCreation(); }

    const Placed *diff_prev(const Placed *new_prev) const {
        auto rv = new Placed(*this);
        rv->prev = new_prev;
        return rv;
    }

 private:
    Placed(Placed &&) = delete;
    void traceCreation() { }
    static int uid_counter;
};

int TablePlacement::Placed::uid_counter = 0;

namespace {
class StageSummary {
    IXBar       ixbar;
    Memories    mem;
 public:
    StageSummary(int stage, const TablePlacement::Placed *pl) {
        while (pl && pl->stage > stage) pl = pl->prev;
        while (pl && pl->stage == stage) {
            ixbar.update(pl->table, &pl->resources);
            mem.update(pl->resources.memuse);
            pl = pl->prev; } }
    friend std::ostream &operator<<(std::ostream &out, const StageSummary &sum) {
        return out << sum.ixbar << Log::endl << sum.mem; }
};
}  // end anonymous namespace

class TablePlacement::Backfill {
    /** Used to track tables that could be backfilled into a stage if we run out of other
     *  things to put in that stage.  Whenever we choose to place table such that another
     * table is no longer (immediately) placeable due to next table limits (so only applies
     * to tofino1), we remember that (non-placed) table and if we later run out of things to
     * put into the current stage, we attempt to 'backfill' that remembered table -- place
     * it in the current stage *before* the table that made it non-placeable.
     *
     * Currently backfilling is limited to single tables that have no control dependent tables.
     * We could try backfilling multiple tables but that is less likely to be possible or
     * useful; it is more likely that a general backtracking scheme would be a better approach.
     */
    int                         stage;
    struct table_t {
        const IR::MAU::Table    *table;
        cstring                 before;
    };
    std::vector<table_t>        avail;

 public:
    explicit Backfill(TablePlacement &) {}
    explicit operator bool() const { return !avail.empty(); }
    std::vector<table_t>::iterator begin() { return avail.begin(); }
    std::vector<table_t>::iterator end() { return avail.end(); }
    void set_stage(int st) {
        if (stage != st) avail.clear();
        stage = st; }
    void add(const Placed *tbl, const Placed *before) {
        set_stage(before->stage);
        avail.push_back({ tbl->table, before->name }); }
};

void TablePlacement::GroupPlace::finish_if_placed(
    ordered_set<const GroupPlace*> &work, const Placed *pl
) const {
    if (pl->is_fully_placed(seq)) {
        LOG4("    Finished a sequence (" << seq->id << ")");
        finish(work);
        for (auto p : parents)
            p->finish_if_placed(work, pl);
    } else {
        LOG4("    seq " << seq->id << " not finished"); }
}

static StageUseEstimate get_current_stage_use(const TablePlacement::Placed *pl) {
    StageUseEstimate    rv;
    if (pl) {
        int stage = pl->stage;
        for (; pl && pl->stage == stage; pl = pl->prev)
            rv += pl->use; }
    return rv;
}

static int count(const TablePlacement::Placed *pl) {
    int rv = 0;
    while (pl) {
        pl = pl->prev;
        rv++; }
    return rv;
}

TablePlacement::GatewayMergeChoices
        TablePlacement::gateway_merge_choices(const IR::MAU::Table *table) {
    GatewayMergeChoices rv;
    // Abort and return empty if we're not a gateway
    if (!table->uses_gateway() || table->match_table) {
        LOG2(table->name << " is not a gateway! Aborting search for merge choices");
        return rv;
    }
    std::set<cstring>   gw_tags;
    for (auto &row : table->gateway_rows)
        gw_tags.insert(row.second);

    // Now, use the same criteria as gateway_merge to find viable tables
    for (auto it = table->next.rbegin(); it != table->next.rend(); it++) {
        if (seqInfo.at(it->second).refs.size() > 1) continue;
        bool multiple_tags = false;
        for (auto &el : table->next) {
            if (el.first != it->first && el.second == it->second) {
                multiple_tags = true;
                break; } }
        // FIXME -- if the sequence is used for more than one tag in the gateway, we can't
        // merge with any table in it as we only track one tag to replace.  Could change
        // GatewayMergeChoices and Placed to track a set of tags.
        if (multiple_tags) continue;

        int idx = -1;
        for (auto t : it->second->tables) {
            bool should_skip = false;
            ++idx;

            if (it->second->deps[idx]) continue;

            // The TableSeqDeps does not currently capture dependencies like injected
            // control dependencies and metadata/dark initialization.  These have been folded
            // into the TableDependencyGraph and can be checked.
            // One could possibly fold this into TableSeqDeps, but only if initialization
            // happens in flow order, as the TableSeqDeps works with a LTBitMatrix
            for (auto t2 : it->second->tables) {
                if (deps->happens_logi_before(t2, t)) should_skip = true;
            }

            // If we have dependence ordering problems
            if (should_skip) continue;
            // if (deps->happens_before_control)
            // If this table also uses gateways
            if (t->uses_gateway()) continue;
            // FIXME: Look for notes above preorder for IR::MAU::Table
            if (t->next.count("$hit") || t->next.count("$miss")) continue;
            // Currently would potentially require multiple gateways if split into
            // multiple tables.  Not supported yet during allocation
            if (t->for_dleft()) continue;
            // Liveness problems
            if (!phv.darkLivenessOkay(table, t)) {
                LOG2("\tCannot merge " << table->name << " with " << t->name << " because of "
                     "liveness check");
                continue;
            }

            // Check if we have already seen this table
            if (rv.count(t))
                continue;
            rv[t] = it->first;
        }
    }
    return rv;
}

void TablePlacement::Placed::gateway_merge(const IR::MAU::Table *match, cstring result_tag) {
    // Check that the table we're attempting to merge with is a gateway
    BUG_CHECK((table->uses_gateway() || !table->match_table),
              "Gateway merge called on a non-gateway!");
    BUG_CHECK(!match->uses_gateway(), "Merging a non-match table into a gateway!");
    // Perform the merge
    name = match->name;
    gw = table;
    table = match;
    gw_result_tag = result_tag;
}

/**  @defgroup alloc
 *  Methods for allocating resources in a single stage to meet the choices in Placed objects.
 * These methods all look at the placements for the latest stage on the front of the list and
 * try to fit everything in one stage.  They return true if they succeed and update the
 * 'resources' TableResourceAlloc object(s) to match.  Those that need to reallocate things
 * for the entire stage (not just the last table placed) take a table_resource_t containing
 * the TableResourceAlloc objects for all the trailing tables in the stage (as the 'prev'
 * pointers are const and cannot be updated directly
 * @{
 */

/**
 * The estimates for potential layout options are determined before all information is possibly
 * known:
 *   1. What the actual input xbar layout of the table was, and whether this required more
 *      ixbar groups that estimated, either due to PHV constraints, or other resources
 *      on the input xbar
 *   2. Whether the table is tied to an gateway, and may need an extra bit for actions
 *   3. How many bits can be ghosted off.
 *
 * Thus, some layouts may not actually be possible that were precalculated.  This will adjust
 * potential layouts if the allocation can not fit within the pack format.
 */
bool TablePlacement::pick_layout_option(TablePlacement::Placed *next, bool estimate_set) {
    bool table_format = true;

    int initial_entries = next->entries;

    if (!estimate_set)
        next->use = StageUseEstimate(next->table, next->entries, next->attached_entries, &lc,
                                     next->stage_split > 0);
    // FIXME: This is not the appropriate way to check if a table is a single gateway
    do {
        bool ixbar_fit = try_alloc_ixbar(next);
        if (!ixbar_fit) {
            next->stage_advance_log = "ran out of ixbar";
            return false; }
        if (!next->table->gateway_only()) {
            table_format = try_alloc_format(next, next->gw);
        }

        if (!table_format) {
            bool adjust_possible = next->use.adjust_choices(next->table, initial_entries,
                                                            next->attached_entries);
            if (!adjust_possible) {
                next->stage_advance_log = "adjust_choices failed";
                return false; }
        }
    } while (!table_format);
    return true;
}

bool TablePlacement::shrink_estimate(Placed *next, int &srams_left,
                                     int &tcams_left, int min_entries) {
    if (next->table->gateway_only() || next->table->match_key.empty())
        return false;

    auto t = next->table;
    if (t->for_dleft()) {
        error("Table %1%: cannot split dleft hash tables", t);
        return false;
    }

    if (t->layout.atcam) {
        next->use.calculate_for_leftover_atcams(t, srams_left, next->entries,
                                                next->attached_entries);
    } else if (!t->layout.ternary) {
        if (!next->use.calculate_for_leftover_srams(t, srams_left, next->entries,
                                                    next->attached_entries)) {
            next->stage_advance_log = "ran out of srams";
            return false;
        }
    } else {
        next->use.calculate_for_leftover_tcams(t, tcams_left, srams_left, next->entries,
                                               next->attached_entries); }

    if (next->entries < min_entries) {
        LOG5("Couldn't place minimum entries within table " << t->name);
        if (t->layout.ternary)
            next->stage_advance_log = "ran out of tcams";
        else
            next->stage_advance_log = "ran out of srams";
        return false;
    }
    if (!t->layout.ternary)
        srams_left--;
    else
        tcams_left--;

    LOG3("  - reducing to " << next->entries << " of " << t->name << " in stage " << next->stage);
    if (!pick_layout_option(next, true)) {
        LOG5("\tIXbarAllocation/Table Format error after previous allocation? Table " << t->name);
        return false;
    }
    return true;
}

struct TablePlacement::RewriteForSplitAttached : public Transform {
    TablePlacement &self;
    const Placed *pl;
    RewriteForSplitAttached(TablePlacement &self, const Placed *p) : self(self), pl(p) {}
    const IR::MAU::Table *preorder(IR::MAU::Table *tbl) {
        self.setup_detached_gateway(tbl, pl);
        // don't visit most of the children
        for (auto it = tbl->actions.begin(); it != tbl->actions.end();)  {
            if ((it->second = self.att_info.create_post_split_action(it->second, tbl)))
                ++it;
            else
                it = tbl->actions.erase(it); }
        visit(tbl->attached, "attached");
        prune();
        return tbl; }
    const IR::MAU::BackendAttached *preorder(IR::MAU::BackendAttached *ba) {
        auto *tbl = findContext<IR::MAU::Table>();
        for (auto act : Values(tbl->actions)) {
            if (auto *sc = act->stateful_call(ba->attached->name)) {
                if (auto *hd = sc->index->to<IR::MAU::HashDist>()) {
                    ba->hash_dist = hd;
                    break; } } }
        prune();
        return ba; }
};

bool TablePlacement::try_alloc_ixbar(TablePlacement::Placed *next) {
    next->resources.clear_ixbar();
    IXBar current_ixbar;
    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        current_ixbar.update(p->table, &p->resources);
    }
    current_ixbar.add_collisions();

    const ActionData::Format::Use *action_format = next->use.preferred_action_format();
    auto *table = next->table;
    if (next->entries == 0 && !table->gateway_only()) {
        // detached attached table -- need to rewrite it as a hash_action gateway that
        // tests the enable bit it drives the attached table with the saved index
        // FIXME -- should we memoize this rather than recreating it each time?
        BUG_CHECK(!next->attached_entries.empty(),  "detaching atatched from %s, no "
                  "attached entries?", next->name);
        BUG_CHECK(!next->gw, "Have a gateway merged with a detached attached table?");
        table = table->apply(RewriteForSplitAttached(*this, next));
    }

    if (!current_ixbar.allocTable(table, phv, next->resources, next->use.preferred(),
                                  action_format) ||
        !current_ixbar.allocTable(next->gw, phv, next->resources, next->use.preferred(),
                                  nullptr)) {
        next->resources.clear_ixbar();
        error_message = "The table " + next->table->name + " could not fit within a single "
                        "input crossbar in an MAU stage";
        LOG3("    " << error_message);
        return false;
    }

    IXBar verify_ixbar;
    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev)
        verify_ixbar.update(p->table, &p->resources);
    verify_ixbar.update(next->table, &next->resources);
    verify_ixbar.verify_hash_matrix();
    LOG7(IndentCtl::indent << IndentCtl::indent);
    LOG7(verify_ixbar << IndentCtl::unindent << IndentCtl::unindent);

    return true;
}

static int count_sful_actions(const IR::MAU::Table *tbl) {
    int rv = 0;
    for (auto act : Values(tbl->actions))
        if (!act->stateful_calls.empty())
            ++rv;
    return rv;
}

bool TablePlacement::try_alloc_mem(Placed *next, std::vector<Placed *> whole_stage) {
    Memories current_mem;
    // This is to guarantee for Tofino to have at least a table per gress within a stage, as
    // a path is required from the parser
    std::array<bool, 2> gress_in_stage = { { false, false} };
    bool shrink_lt = false;
    if (Device::currentDevice() == Device::TOFINO) {
        if (next->stage == 0) {
            for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
                gress_in_stage[p->table->gress] = true;
            }
            gress_in_stage[next->table->gress] = true;
            for (int gress_i = 0; gress_i < 2; gress_i++) {
                if (table_in_gress[gress_i] && !gress_in_stage[gress_i])
                    shrink_lt = true;
            }
        }
    }

    if (next->use.format_type == ActionData::POST_SPLIT_ATTACHED &&
        count_sful_actions(next->table) > 1) {
        error_message = "splitting attached tables invkoed from multiple actions not supported";
        return false; }

    if (shrink_lt)
        current_mem.shrink_allowed_lts();

    for (auto *p : whole_stage) {
        BUG_CHECK(p != next && p->stage == next->stage, "invalid whole_stage");
        current_mem.add_table(p->table, p->gw, &p->resources, p->use.preferred(),
                              p->entries, p->stage_split, p->attached_entries);
        p->resources.memuse.clear(); }
    current_mem.add_table(next->table, next->gw, &next->resources, next->use.preferred(),
                          next->entries, next->stage_split, next->attached_entries);
    next->resources.memuse.clear();

    if (!current_mem.allocate_all()) {
        error_message = "The table " + next->table->name + " could not fit in stage " +
                        std::to_string(next->stage) + " with " + std::to_string(next->entries)
                        + " entries";
        LOG3("    " << error_message);
        next->stage_advance_log = "ran out of memories";
        next->resources.memuse.clear();
        for (auto *p : whole_stage)
            p->resources.memuse.clear();
        return false;
    }

    Memories verify_mem;
    if (shrink_lt)
        verify_mem.shrink_allowed_lts();
    for (auto *p : whole_stage)
        verify_mem.update(p->resources.memuse);
    verify_mem.update(next->resources.memuse);
    LOG7(IndentCtl::indent << IndentCtl::indent);
    LOG7(verify_mem << IndentCtl::unindent << IndentCtl::unindent);

    return true;
}

bool TablePlacement::try_alloc_format(TablePlacement::Placed *next, bool gw_linked) {
    const bitvec immediate_mask = next->use.preferred_action_format()->immediate_mask;
    next->resources.table_format.clear();
    TableFormat current_format(*next->use.preferred(), next->resources.match_ixbar,
                               next->resources.proxy_hash_ixbar, next->table,
                               immediate_mask, gw_linked);

    if (!current_format.find_format(&next->resources.table_format)) {
        next->resources.table_format.clear();
        error_message = "The selected pack format for table " + next->table->name + " could "
                        "not fit given the input xbar allocation";
        LOG3("    " << error_message);
        return false;
    }
    return true;
}

bool TablePlacement::try_alloc_adb(Placed *next) {
    if (next->table->gateway_only())
        return true;

    BUG_CHECK(next->use.preferred_action_format() != nullptr,
              "A non gateway table has a null action data format allocation");

    ActionDataBus current_adb;
    next->resources.action_data_xbar.clear();
    next->resources.meter_xbar.clear();

    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        current_adb.update(p->name, &p->resources, p->table);
    }
    if (!current_adb.alloc_action_data_bus(next->table, next->use.preferred_action_format(),
                                           next->resources)) {
        error_message = "The table " + next->table->name + " could not fit in within the "
                        "action data bus";
        LOG3("    " << error_message);
        next->resources.action_data_xbar.clear();
        next->stage_advance_log = "ran out of action data bus space";
        return false;
    }

    /**
     * allocate meter output on adb
     */
    if (!current_adb.alloc_action_data_bus(next->table,
            next->use.preferred_meter_format(), next->resources)) {
        error_message = "The table " + next->table->name + " could not fit its meter "
                        " output in within the action data bus";
        LOG3(error_message);
        next->resources.meter_xbar.clear();
        next->stage_advance_log = "ran out of action data bus space for meter output";
        return false;
    }

    ActionDataBus adb_update;
    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        adb_update.update(p->name, &p->resources, p->table);
    }
    adb_update.update(next->name, &next->resources, next->table);
    return true;
}

bool TablePlacement::try_alloc_imem(Placed *next) {
    if (next->table->gateway_only())
        return true;

    InstructionMemory imem;
    next->resources.instr_mem.clear();

    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        imem.update(p->name, &p->resources, p->table);
    }

    bool gw_linked = next->gw != nullptr;
    if (!imem.allocate_imem(next->table, next->resources.instr_mem, phv, gw_linked)) {
        error_message = "The table " + next->table->name + " could not fit within the "
                        "instruction memory";
        LOG3("    " << error_message);
        next->resources.instr_mem.clear();
        next->stage_advance_log = "ran out of imem";
        return false;
    }

    InstructionMemory verify_imem;
    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        verify_imem.update(p->name, &p->resources, p->table);
    }
    verify_imem.update(next->name, &next->resources, next->table);
    return true;
}

bool TablePlacement::try_alloc_all(Placed *next, std::vector<Placed *> whole_stage,
                                   const char *what, bool no_memory) {
    // FIXME -- for some reason, if we reallocate the format/ixbar/adb for other tables in
    // stage 0 when trying to place a starter pistol (even though that alocation ends up
    // unchanged), placement of memory for the starter pistol may then fail.  So we hack
    // not doing the reallication (just) for starter pistols to avoid the problem.
    bool done_next = false;
    if (!next->table->created_during_tp) {
        for (auto *p : boost::adaptors::reverse(whole_stage)) {
            if (p->prev == next) {
                if (!pick_layout_option(next, false)) {
                    LOG3("    " << what << " ixbar allocation did not fit");
                    return false; }
                done_next = true; }
            if (!pick_layout_option(p, false)) {
                LOG3("    redo of " << p->name << " ixbar allocation did not fit");
                return false; } } }
    if (!done_next && !pick_layout_option(next, false)) {
        LOG3("    " << what << " ixbar allocation did not fit");
        return false; }
    done_next = false;
    if (!next->table->created_during_tp) {
        for (auto *p : boost::adaptors::reverse(whole_stage)) {
            if (p->prev == next) {
                if (!try_alloc_adb(next)) {
                    LOG3("    " << what << " of action data bus did not fit");
                    return false; }
                done_next = true; }
            if (!try_alloc_adb(p)) {
                LOG3("    redo of " << p->name << " action data bus did not fit");
                return false; } } }
    if (!done_next && !try_alloc_adb(next)) {
        LOG3("    " << what << " of action data bus did not fit");
        return false; }
    done_next = false;
    if (!next->table->created_during_tp) {
        for (auto *p : boost::adaptors::reverse(whole_stage)) {
            if (p->prev == next) {
                if (!try_alloc_imem(next)) {
                    LOG3("    " << what << " of instruction memory did not fit");
                    return false; }
                done_next = true; }
            if (!try_alloc_imem(p)) {
                LOG3("    redo of " << p->name << " instruction memory did not fit");
                return false; } } }
    if (!done_next && !try_alloc_imem(next)) {
        LOG3("    " << what << " of instruction memory did not fit");
        return false; }
    if (no_memory) return true;
    if (auto what = get_current_stage_use(next).ran_out()) {
        LOG3("    " << what << " of memory allocation ran out of " << what);
        next->stage_advance_log = "ran out of " + what;
        return false;
    } else if (!try_alloc_mem(next, whole_stage)) {
        LOG3("    " << what << " of memory allocation did not fit");
        return false; }
    return true;
}

/** @} */  // end of alloc

/// Check an indirect attached table to see if it can be duplicated across stages, or if there
/// must be only a single copy of (each element of) the table.  This does not consider
/// whether it is a good idea to duplicate the table (not a good idea for large tables and
/// pointless if it won't fit in a single stage anyways).
bool TablePlacement::can_duplicate(const IR::MAU::AttachedMemory *att) {
    BUG_CHECK(!att->direct, "Not an indirect attached table");
    if (att->is<IR::MAU::Counter>() || att->is<IR::MAU::ActionData>() ||
        att->is<IR::MAU::Selector>())
        return true;
    if (auto *salu = att->to<IR::MAU::StatefulAlu>())
        return salu->synthetic_for_selector;
    return false;
}

bool TablePlacement::initial_stage_and_entries(Placed *rv, int &furthest_stage) {
    auto *t = rv->table;
    if (t->match_table) {
        rv->entries = 512;  // default number of entries -- FIXME does this really make sense?
        if (t->layout.no_match_data())
            rv->entries = 1;
        if (t->layout.pre_classifier)
            rv->entries = t->layout.pre_classifer_number_entries;
        else if (auto k = t->match_table->getConstantProperty("size"))
            rv->entries = k->asInt();
        else if (auto k = t->match_table->getConstantProperty("min_size"))
            rv->entries = k->asInt();
        if (t->layout.has_range) {
            RangeEntries re(phv, rv->entries);
            t->apply(re);
            rv->entries = re.TCAM_lines();
        } else if (t->layout.alpm && t->layout.atcam) {
            // According to Henry Wang, alpm requires one extra entry per partition
            rv->entries += t->layout.partition_count;
        }
        if (t->layout.exact) {
            if (t->layout.ixbar_width_bits < ceil_log2(rv->entries)) {
                rv->entries = 1 << t->layout.ixbar_width_bits;
                ::warning(BFN::ErrorType::WARN_TABLE_PLACEMENT,
                          "Shrinking %1%: with %2% match bits, can only have %3% entries",
                          t, t->layout.ixbar_width_bits, rv->entries);
            }
        }
    } else {
        rv->entries = 0;
    }
    /* Not yet placed tables that share an attached table with this table -- if any of them
     * have a dependency that prevents placement in the current stage, we want to defer */
    ordered_set<const IR::MAU::Table *> tables_with_shared;
    for (auto *ba : rv->table->attached) {
        if (ba->attached->direct) continue;
        rv->attached_entries[ba->attached] = ba->attached->size;
        if (can_duplicate(ba->attached)) continue;
        bool stateful_selector = ba->attached->is<IR::MAU::StatefulAlu>() &&
                                 ba->use == IR::MAU::StatefulUse::NO_USE;
        for (auto *att_to : attached_to.at(ba->attached)) {
            if (att_to == rv->table) continue;
            // If shared with another table that is not placed yet, need to
            // defer the placement of this attached table
            if (!rv->is_match_placed(att_to)) {
                tables_with_shared.insert(att_to);
                rv->attached_entries[ba->attached] = 0;
                if (stateful_selector) {
                    // A Register that is not directly used, but is instead the backing for a
                    // selector.  Since a selector cannot be split from its match table, we
                    // don't want to try to place the table until all the tables that write
                    // to it are placed.
                    auto *att_ba = att_to->get_attached(ba->attached);
                    BUG_CHECK(att_ba, "%s not attached to %s?", ba->attached, att_to);
                    if (att_ba->use != IR::MAU::StatefulUse::NO_USE)
                        return false;
                } else {
                    break; } } } }

    int prev_stage_tables = 0;
    bool repeated_stage = false;
    for (auto *p = rv->prev; p; p = p->prev) {
        if (p->name == rv->name) {
            if (p->need_more == false) {
                BUG(" - can't place %s it's already done", rv->name);
                return false; }
            rv->entries -= p->entries;
            for (auto &ate : p->attached_entries)
                if (!ate.first->direct && !can_duplicate(ate.first))
                    rv->attached_entries[ate.first] -= ate.second;
            prev_stage_tables++;
            if (p->stage == rv->stage) {
                LOG2("  Cannot place multiple sections of an individual table in the same stage");
                rv->stage_advance_log = "cannot split into same stage";
                repeated_stage = true;
                rv->stage++;
                continue;
            }
        } else if (p->stage == rv->stage) {
            if (options.forced_placement)
                continue;
            if (deps->happens_phys_before(p->table, rv->table)) {
                rv->stage++;
                LOG2("  - dependency between " << p->table->name << " and table advances stage");
                rv->stage_advance_log = "dependency on table " + p->table->name;
            } else if (rv->gw && deps->happens_phys_before(p->table, rv->gw)) {
                rv->stage++;
                LOG2("  - dependency between " << p->table->name << " and gateway advances stage");
                rv->stage_advance_log = "gateway dependency on table " + p->table->name;
            } else if (deps->container_conflict(p->table, rv->table)) {
                if (!ignoreContainerConflicts) {
                    rv->stage++;
                    LOG2("  - action dependency between " << p->table->name << " and table " <<
                         rv->table->name << " due to PHV allocation advances stage to " <<
                         rv->stage);
                    rv->stage_advance_log = "container conflict with table " + p->table->name;
                }
            } else {
                for (auto ctbl : tables_with_shared) {
                    // FIXME -- once we can put shared attached tables in different stages, we
                    // probably don't want to do this any more...
                    if (deps->happens_phys_before(p->table, ctbl)) {
                        rv->stage++;
                        LOG2("  - dependency between " << p->table->name << " and " <<
                             ctbl->name << " advances stage");
                        rv->stage_advance_log = "shared table " + ctbl->name +
                            " depends on table " + p->table->name;
                        break;
                    } else if (deps->container_conflict(p->table, ctbl)) {
                        if (!ignoreContainerConflicts) {
                            rv->stage++;
                            LOG2("  - action dependency between " << p->table->name << " and "
                                 "table " << ctbl->name << " due to PHV allocation advances "
                                 "stage to " << rv->stage);
                            rv->stage_advance_log = "shared table " + ctbl->name +
                                " container conflict with table " + p->table->name;
                            break;
                        }
                    }
                }
            }
        }
    }
    if (rv->entries <= 0 && !t->gateway_only()) {
        rv->entries = 0;
        if (repeated_stage) return false;
        // FIXME -- should use std::any_of, but pre C++-17 is too hard to use and verbose
        bool have_attached = false;
        for (auto &ate : rv->attached_entries) {
            if (ate.second > 0) {
                have_attached = true;
                break; } }
        if (!have_attached) return false; }

    auto stage_pragma = t->get_provided_stage(&rv->stage, &rv->requested_stage_entries);
    if (rv->requested_stage_entries > 0)
        LOG5("Using " << rv->requested_stage_entries << " for stage " << rv->stage
             << " out of total " << rv->entries);

    if (stage_pragma >= 0) {
        rv->stage = std::max(stage_pragma, rv->stage);
        furthest_stage = std::max(rv->stage, furthest_stage);
    } else if (options.forced_placement && !t->gateway_only()) {
        ::warning("%s: Table %s has not been provided a stage even though forced placement of "
                  "tables is turned on", t->srcInfo, t->name);
    }

    if (prev_stage_tables > 0) {
        rv->initial_stage_split = prev_stage_tables;
        rv->stage_split = prev_stage_tables;
    }
    for (auto *ba : rv->table->attached)
        if (ba->attached->direct)
            rv->attached_entries[ba->attached] = rv->entries;

    return true;
}

/** When placing a gateway table, the gateway can potential be combined with a match table
 *  to build one logical table.  The gateway_merge function picks a legal table to place with
 *  this table.  This loops through all possible tables to be merged, and will
 *  return a vector of these possible choices to the is_better function to choose
 */
safe_vector<TablePlacement::Placed *>
    TablePlacement::try_place_table(const IR::MAU::Table *t,
                                    const Placed *done, const StageUseEstimate &current,
                                    GatewayMergeChoices& gmc) {
    LOG1("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    safe_vector<TablePlacement::Placed *> rv_vec;
    // Place and save a placement, as a lambda
    auto try_place = [&](Placed* rv) {
                         if ((rv = try_place_table(rv, current)))
                             rv_vec.push_back(rv);
                     };

    // If we're not a gateway or there are no merge options for the gateway, we create exactly one
    // placement for it
    if (!t->uses_gateway() || t->match_table || gmc.size() == 0) {
        auto *rv = new Placed(*this, t, done);
        try_place(rv);
        return rv_vec;
    }

    // Otherwise, we are a gateway, so we need to iterate through all tables it can possibly be
    // merged with
    for (auto mc : gmc) {
        auto *rv = new Placed(*this, t, done);
        // Merge
        LOG1("  Merging with match table " << mc.first->name);
        rv->gateway_merge(mc.first, mc.second);
        // Get a placement
        try_place(rv);
    }
    return rv_vec;
}


TablePlacement::Placed *TablePlacement::try_place_table(Placed *rv,
        const StageUseEstimate &current) {
    int furthest_stage = (rv->prev == nullptr) ? 0 : rv->prev->stage + 1;
    if (!initial_stage_and_entries(rv, furthest_stage)) {
        return nullptr;
    }

    const Placed *done = rv->prev;
    std::vector<Placed *> whole_stage;
    error_message = "";
    // clone the already-placed tables in this stage so they can be re-placed
    for (const Placed **p = &rv->prev; *p && (*p)->stage == rv->stage; ) {
        auto clone = new Placed(**p);
        whole_stage.push_back(clone);
        *p = clone;
        p = &clone->prev; }


    // update shared attached tables in the stage
    for (auto *p : boost::adaptors::reverse(whole_stage))
        p->update_attached(rv);
    if (!whole_stage.empty()) {
        BUG_CHECK(rv->prev && rv->prev->stage == rv->stage, "whole_placed invalid");
        rv->placed |= rv->prev->placed;
        BUG_CHECK(rv->match_placed == rv->prev->match_placed, "match_placed out of date?"); }

    int initial_entries = rv->requested_stage_entries > 0 ? rv->requested_stage_entries :
        rv->entries;
    attached_entries_t initial_attached_entries = rv->attached_entries;

    LOG3("  Initial stage is " << rv->stage << ", initial entries is " << rv->entries);
    BUG_CHECK(rv->stage < 100, "too many stages");

    auto *min_placed = new Placed(*rv);
    if (min_placed->entries > 1)
        min_placed->entries = 1;
    if (min_placed->requested_stage_entries > 0)
        min_placed->entries = rv->requested_stage_entries;

    if (!rv->table->created_during_tp) {
        assert(!rv->placed[tblInfo.at(rv->table).uid]);
    }

    StageUseEstimate stage_current = current;
    // According to the driver team, different stage tables can have different action
    // data allocations, so the algorithm doesn't have to prefer this allocation across
    // stages

    bool allocated = false;

    min_placed->stage = rv->stage;
    min_placed->initial_stage_split = rv->initial_stage_split;
    min_placed->stage_split = rv->stage_split;
    min_placed->attached_entries = rv->attached_entries;

    if (rv->prev && rv->stage != rv->prev->stage)
        stage_current.clear();

    /* Loop to find the right size of entries for a table to place into stage */
    do {
        rv->need_more = false;
        rv->need_more_match = false;
        rv->entries = initial_entries;
        rv->attached_entries = initial_attached_entries;
        // FIXME -- this initialization of rv->use appears to be redundant with the one in
        // pick_layout_option, but it turns out its not.  By doing it twice, calculate_way_sizes
        // ends up being called again, which means small exact tables will end up with 4
        // ways instead of 3.  It might seem to be better to NOT do this, as then these tables
        // will use less space, but for some reason doing that causes switch_16_d0 to need
        // 21 stages instead of 20.
        rv->use = StageUseEstimate(rv->table, rv->entries, rv->attached_entries, &lc,
                                   rv->stage_split > 0);

        auto avail = StageUseEstimate::max();
        bool advance_to_next_stage = false;
        allocated = false;
        if (rv->table->for_dleft() && initial_entries > rv->entries) {
            advance_to_next_stage = true;
            LOG3("    Cannot split a dleft hash table");
            error_message = "splitting dleft tables not supported";
        }

        if (!try_alloc_all(min_placed, whole_stage, "Min use") ||
            !try_alloc_all(rv, whole_stage, "Table use", true)) {
            if (!rv->stage_advance_log)
                if (!(rv->stage_advance_log = min_placed->stage_advance_log))
                    rv->stage_advance_log = "repacking previously placed failed";
            advance_to_next_stage = true; }

        if (rv->prev && rv->stage == rv->prev->stage) {
            avail.srams -= stage_current.srams;
            avail.tcams -= stage_current.tcams;
            avail.maprams -= stage_current.maprams; }

        int srams_left = avail.srams;
        int tcams_left = avail.tcams;
        // If the max needed entries do not fit, shrink the table given the number of available
        // rams until the table is able to be placed
        while (!advance_to_next_stage &&
               (!(rv->use <= avail) ||
               (allocated = try_alloc_mem(rv, whole_stage)) == false)) {
            // If a table contains initialization for dark containers, it cannot be split into
            // multiple stages.
            if (rv->table->has_dark_init) {
                LOG3("    Table with dark initialization cannot be split");
                error_message = "Can't split this table across stages and it's "
                                "too big for one stage";
                advance_to_next_stage = true;
                break;
            }
            if (!shrink_estimate(rv, srams_left, tcams_left, min_placed->entries)) {
                error_message = "Can't split this table across stages and it's "
                                "too big for one stage";
                advance_to_next_stage = true;
                break;
            }

            if (rv->entries < initial_entries) {
                for (auto *ba : rv->table->attached) {
                    if (ba->attached->direct) {
                        rv->attached_entries[ba->attached] = rv->entries;
                    } else if (!can_duplicate(ba->attached)) {
                        if (rv->prev && rv->prev->stage == rv->stage) {
                            // FIXME -- as we can't (yet) have the indirect table in a later
                            // stage, don't try placements that would require it, as they
                            // will always fail with a "can't split" at line ~1427
                            advance_to_next_stage = true;
                            break; }
                        rv->attached_entries[ba->attached] = 0; } }
                rv->need_more = rv->need_more_match = true;
                // If the table is split for the first time, then the stage_split is set to 0
                if (rv->initial_stage_split == -1)
                    rv->stage_split = 0;
            }

            if (!try_alloc_adb(rv)) {
                ERROR("Action Data Bus Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }

            if (!try_alloc_imem(rv)) {
                ERROR("Instruction Memory Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }
        }

        if (advance_to_next_stage) {
            rv->stage++;
            rv->stage_split = rv->initial_stage_split;
            min_placed->stage++;
            min_placed->stage_split = min_placed->initial_stage_split;
            stage_current.clear();
            for (auto *p : whole_stage) delete p;  // help garbage collector
            whole_stage.clear();
            rv->prev = min_placed->prev = done;
        } else if (rv->requested_stage_entries > 0 && rv->requested_stage_entries <= rv->entries) {
            // If the table had a stage pragma, we placed the slice of the table requested by
            // stage pragma and we need to make sure that the rest of entries are going to be
            // placed in subsequent stages.
            rv->requested_stage_entries = -1;
            rv->need_more = rv->need_more_match = true;
        }
    } while (!allocated && rv->stage <= furthest_stage);

    for (auto *ba : rv->table->attached) {
        // indirect attached tables that could not be placed (due to needing other
        // tables placed first) mean we may need more...
        if (!ba->attached->direct && !rv->attached_entries[ba->attached]) {
            rv->need_more = true;
            break; } }

    rv->update_formats();
    if (!rv->table->gateway_only()) {
        BUG_CHECK(rv->use.preferred_action_format() != nullptr,
                  "Action format could not be found for a particular layout option.");
        BUG_CHECK(rv->use.preferred_meter_format() != nullptr,
                  "Meter format could not be found for a particular layout option."); }
    for (auto *t : whole_stage)
        t->update_formats();

    LOG3("  Selected stage: " << rv->stage << "    Furthest stage: " << furthest_stage);
    if (rv->stage > furthest_stage) {
        if (error_message == "")
            error_message = "Unknown error for stage advancement?";
        error("Could not place %s: %s", rv->table, error_message);
        return nullptr;
    }

    rv->setup_logical_id();

    assert((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage);
    LOG2("  try_place_table returning " << rv->entries << " of " << rv->name <<
         " in stage " << rv->stage <<
         (rv->need_more_match ? " (need more match)" : rv->need_more ? " (need more)" : ""));
    LOG5(IndentCtl::indent << IndentCtl::indent << "    " <<
         rv->resources <<
         IndentCtl::unindent << IndentCtl::unindent);

    if (!rv->table->created_during_tp) {
        if (!rv->need_more_match) {
            rv->match_placed[tblInfo.at(rv->table).uid] = true;
            if (!rv->need_more)
                rv->placed[tblInfo.at(rv->table).uid] = true;
        }
        if (rv->gw) {
            rv->match_placed[tblInfo.at(rv->gw).uid] = true;
            rv->placed[tblInfo.at(rv->gw).uid] = true;
        }
    }
    return rv;
}

/**
 * Try to backfill a table in the current stage just before another table, bumping up the
 * logical ids of the later tables, but keeping all in the same stage.
 */
TablePlacement::Placed *TablePlacement::try_backfill_table(
        const Placed *done, const IR::MAU::Table *tbl, cstring before) {
    LOG2("try to backfill " << tbl->name << " before " << before);
    std::vector<Placed *> whole_stage;
    Placed *place_before = nullptr;
    for (const Placed **p = &done; *p && (*p)->stage == done->stage; ) {
        if (!(*p)->table->created_during_tp && !mutex(tbl, (*p)->table) &&
            deps->container_conflict(tbl, (*p)->table)) {
            LOG4("  can't backfill due to container conflict with " << (*p)->name);
            return nullptr; }
        auto clone = new Placed(**p);
        whole_stage.push_back(clone);
        if (clone->name == before) {
            BUG_CHECK(!place_before, "%s placed multiple times in stage %d", before, done->stage);
            place_before = clone; }
        *p = clone;
        p = &clone->prev; }
    if (!place_before) {
        BUG("Couldn't find %s in stage %d", before, done->stage);
        return nullptr; }
    Placed *pl = new Placed(*this, tbl, place_before->prev);
    int furthest_stage = done->stage;
    if (!initial_stage_and_entries(pl, furthest_stage))
        return nullptr;
    if (pl->stage != place_before->stage)
        return nullptr;
    place_before->prev = pl;
    if (!try_alloc_all(pl, whole_stage, "Backfill"))
        return nullptr;
    for (auto &ae : pl->attached_entries)
        if (!ae.second)
            return nullptr;
    int lts = pl->use.preferred()->logical_tables();
    if (lts + (done->logical_id % StageUse::MAX_LOGICAL_IDS) >= StageUse::MAX_LOGICAL_IDS)
        return nullptr;
    for (auto *p : whole_stage) {
        p->logical_id += lts;
        p->placed[tblInfo.at(tbl).uid] = 1;
        p->match_placed[tblInfo.at(tbl).uid] = 1;
        if (p == place_before)
            break; }
    pl->update_formats();
    for (auto *p : whole_stage)
        p->update_formats();
    pl->setup_logical_id();
    pl->placed[tblInfo.at(tbl).uid] = 1;
    pl->match_placed[tblInfo.at(tbl).uid] = 1;
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " << pl->stage << "(" <<
         hex(pl->logical_id) << ")" << " (backfilled)");
    BUG_CHECK(pl->table->next.empty(), "Can't backfill table with control dependencies");
    return whole_stage.front();
}

/**
 * In Tofino specifically, if a table is in ingress or egress, then a table for that pipeline
 * must be placed within stage 0.  The parser requires a pathway into the first stage.
 *
 * Thus, this checks if no table can longer be placed in stage 0, and if a table from a
 * particular gress has not yet been placed, the create a starting table for that pipe in
 * stage 0.
 */
const TablePlacement::Placed *
         TablePlacement::add_starter_pistols(const Placed *done,
                                             safe_vector<const Placed *> &trial,
                                             const StageUseEstimate &current) {
    if (Device::currentDevice() != Device::TOFINO)
        return done;
    if (done != nullptr && done->stage > 0)
        return done;
    for (auto p : trial) {
        if (p->stage == 0)
            return done;
    }

    // Determine if a table has been placed yet within this gress
    std::array<bool, 2> placed_gress = { { false, false } };
    for (auto *p = done; p && p->stage == 0; p = p->prev) {
        placed_gress[p->table->gress] = true;
    }

    const Placed *last_placed = done;
    for (int i = 0; i < 2; i++) {
        gress_t current_gress = static_cast<gress_t>(i);
        if (!placed_gress[i] && table_in_gress[i]) {
            cstring t_name = "$" + toString(current_gress) + "_starter_pistol";
            auto t = new IR::MAU::Table(t_name, current_gress);
            t->created_during_tp = true;
            LOG4("Adding starter pistol for " << current_gress);
            auto *rv = new Placed(*this, t, last_placed);
            rv = try_place_table(rv, current);
            if (rv->stage != 0) {
                error("No table in %s could be placed in stage 0, a requirement for Tofino",
                      toString(current_gress));
                return last_placed;
            }
            last_placed = rv;
            starter_pistol[i] = t;
        }
    }

    // place_table cannot be called on these tables, as they don't appear in the initial IR.
    // Adding them to the placed linked list is sufficient for them to be placed
    for (size_t i = 0; i < trial.size(); i++) {
        trial[i] = trial[i]->diff_prev(last_placed);
    }
    return last_placed;
}


const TablePlacement::Placed *
TablePlacement::place_table(ordered_set<const GroupPlace *>&work, const Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " << pl->stage << "(" <<
         hex(pl->logical_id) << ")" <<
         (pl->need_more_match ? " (need more match)" : pl->need_more ? " (need more)" : ""));

    int stage_pragma = pl->table->get_provided_stage(&pl->stage);
    if (stage_pragma >= 0 && stage_pragma != pl->stage)
        LOG1("  placing in stage " << pl->stage << " dsespite @stage(" << stage_pragma << ")");

    if (!pl->need_more) {
        pl->group->finish_if_placed(work, pl); }
    GroupPlace *gw_match_grp = nullptr;
    /**
     * A gateway cannot be linked with a table that is applied multiple times in different way.
     * Take for instance the following program:
     *
     *     if (t1.apply().hit) {
     *         if (f1 == 0) {   // cond-0
     *             t2.apply();
     *         }
     *     } else {
     *         if (f1 == 1) {
     *             t2.apply();   // cond-1
     *         }
     *     }
     *
     * In this case, table t2 cannot be linked to either of the gateway tables, as by linking
     * a gateway to one would lose the value from others.  This code verifies that a table
     * linked to a gateway is not breaking this constraint.
     */
    if (pl->gw)  {
        bool found_match = false;
        for (auto n : Values(pl->gw->next)) {
            if (!n || n->tables.size() == 0) continue;
            if (GroupPlace::in_work(work, n)) continue;
            bool ready = true;
            // Vector of all control parents of a TableSeq.  In our example, if placing cond-0,
            // the sequence would be [ t2 ], and the parent of that sequence would be
            // [ cond-0, cond-1 ]
            ordered_set<const GroupPlace *> parents;
            for (auto tbl : seqInfo.at(n).refs) {
                if (pl->is_placed(tbl)) {
                    parents.insert(pl->find_group(tbl));
                } else {
                    ready = false;
                    break; } }
            if (n->tables.size() == 1 && n->tables.at(0) == pl->table) {
                BUG_CHECK(!found_match && !gw_match_grp, "Table appears twice");
                // Guaranteeing at most only one parent for linking a gateway
                BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                          "multi-referenced table");
                found_match = true;
                if (pl->need_more)
                    new GroupPlace(*this, work, parents, n);
                continue; }
            // If both cond-1 and cond-0 are placed, then the sequence for t2 can be placed
            GroupPlace *g = ready ? new GroupPlace(*this, work, parents, n) : nullptr;
            // This is based on the assumption that a table appears in a single table sequence
            for (auto t : n->tables) {
                if (t == pl->table) {
                    BUG_CHECK(!found_match && !gw_match_grp, "Table appears twice");
                    BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                              "multi-referenced table");
                    found_match = true;
                    gw_match_grp = g; } } }
        BUG_CHECK(found_match, "Failed to find match table"); }
    if (!pl->need_more_match) {
        for (auto n : Values(pl->table->next)) {
            if (n && n->tables.size() > 0 && !GroupPlace::in_work(work, n)) {
                bool ready = true;
                ordered_set<const GroupPlace *> parents;
               /**
                * Examine the following example:
                *
                *     if (condition) {
                *         switch(t1.apply().action_run) {
                *             a1 : { t3.apply(); }
                *             a2 : { if (t2.apply().hit) { t3.apply(); } }
                *         }
                *     }
                *
                * The algorithm wants to merge the condition with t1.  The tables that become
                * available to place would be t2 and t3.  However, we do not want to add the
                * t3 sequence yet to the algorithm, as it has to wait 
                */
                for (auto tbl : seqInfo.at(n).refs) {
                    if (tbl == pl->table) {
                        parents.insert(gw_match_grp ? gw_match_grp : pl->group);
                    } else if (pl->is_placed(tbl)) {
                        BUG_CHECK(!gw_match_grp, "Failure attaching gateway to table");
                        parents.insert(pl->find_group(tbl));
                    } else {
                        // Basically when placing t1, which is a parent of t3, do not begin
                        // to make t3 an available sequence, as it has to wait.
                        ready = false;
                        break ; } }
                if (ready && pl->need_more) {
                    for (auto t : n->tables) {
                        if (!can_place_with_partly_placed(t, {pl->table}, pl)) {
                            ready = false;
                            break; } } }
                if (ready) {
                    new GroupPlace(*this, work, parents, n); } } } }
    return pl;
}

bool TablePlacement::are_metadata_deps_satisfied(const Placed *placed,
                                                 const IR::MAU::Table* t) const {
    // If there are no reverse metadata deps for this table, return true.
    LOG4("Checking table " << t->name << " for metadata dependencies");
    const ordered_set<cstring> set_of_tables = phv.getReverseMetadataDeps(t);
    for (auto tbl : set_of_tables) {
        if (!placed || !placed->is_placed(tbl)) {
            LOG4("    Table " << tbl << " needs to be placed before table " << t->name);
            return false;
        }
    }
    return true;
}

/* compare two tables to see which one we should prefer placindg next.  Return true if
 * a is better and false if b is better */
bool TablePlacement::is_better(const Placed *a, const Placed *b, choice_t& choice) {
    const IR::MAU::Table *a_table_to_use = a->gw ? a->gw : a->table;
    const IR::MAU::Table *b_table_to_use = b->gw ? b->gw : b->table;

    if (a_table_to_use == b_table_to_use) {
        a_table_to_use = a->table;
        b_table_to_use = b->table;
    }

    // FIXME -- which state should we use for this -- a->prev or b->prev?  Currently they'll
    // be the same (as far as placed tables are concerned) as we only try_place a single table
    // before committing, but in the future...
    BUG_CHECK(a->prev == b->prev || a->prev->match_placed == b->prev->match_placed,
              "Inconsistent previously placed state in is_better");
    const Placed *done = a->prev;
    ddm.update_placed_tables([done](const IR::MAU::Table *tbl)->bool {
        return done ? done->is_match_placed(tbl) : false; });
    const auto down_score = ddm.get_downward_prop_score(a_table_to_use, b_table_to_use);

    ordered_set<const IR::MAU::Table *> already_placed_a;
    for (auto p = a->prev; p && p->stage == a->stage; p = p->prev) {
        if (p->table)
            already_placed_a.emplace(p->table);
        if (p->gw)
            already_placed_a.emplace(p->gw);
    }

    ordered_set<const IR::MAU::Table *> already_placed_b;
    for (auto p = b->prev; p && p->stage == b->stage; p = p->prev) {
        if (p->table) {
            already_placed_b.emplace(p->table);
        }
        if (p->gw)
            already_placed_b.emplace(p->gw);
    }

    LOG5("      Stage A is " << a->name << ((a->gw) ? (" $" + a->gw->name) : "") <<
         " with calculated stage " << a->stage <<
         ", provided stage " << a->table->get_provided_stage(&a->stage) <<
         ", priority " << a->table->get_placement_priority_int());
    LOG5("        downward prop score " << down_score.first);
    LOG5("        local dep score " << deps->stage_info.at(a_table_to_use).dep_stages_control_anti);
    LOG5("        dom frontier " << deps->stage_info.at(a_table_to_use).dep_stages_dom_frontier);
    LOG5("        can place cds in stage "
          << ddm.can_place_cds_in_stage(a_table_to_use, already_placed_a));

    LOG5("      Stage B is " << b->name << ((a->gw) ? (" $" + a->gw->name) : "") <<
         " with calculated stage " << b->stage <<
         ", provided stage " << b->table->get_provided_stage(&b->stage) <<
         ", priority " << b->table->get_placement_priority_int());
    LOG5("        downward prop score " << down_score.second);
    LOG5("        local dep score " << deps->stage_info.at(b_table_to_use).dep_stages_control_anti);
    LOG5("        dom frontier " << deps->stage_info.at(b_table_to_use).dep_stages_dom_frontier);
    LOG5("        can place cds in stage "
          << ddm.can_place_cds_in_stage(b_table_to_use, already_placed_b));

    choice = CALC_STAGE;
    if (a->stage < b->stage) return true;
    if (a->stage > b->stage) return false;

    choice = PROV_STAGE;
    bool provided_stage = false;
    int a_provided_stage = a->table->get_provided_stage(&a->stage);
    int b_provided_stage = b->table->get_provided_stage(&b->stage);

    if (a_provided_stage >= 0 && b_provided_stage >= 0) {
        if (a_provided_stage != b_provided_stage)
            return a_provided_stage < b_provided_stage;
        // Both tables need to be in THIS stage...
        provided_stage = true;
    } else if (a_provided_stage >= 0 && b_provided_stage < 0) {
        return true;
    } else if (b_provided_stage >= 0 && a_provided_stage < 0) {
        return false;
    }

    choice = PRIORITY;
    auto a_priority_str = a->table->get_placement_priority_string();
    auto b_priority_str = b->table->get_placement_priority_string();
    if (a_priority_str.count(b->table->externalName()))
        return true;
    if (b->gw && a_priority_str.count(b->gw->externalName()))
        return true;
    if (b_priority_str.count(a->table->externalName()))
        return false;
    if (a->gw && b_priority_str.count(a->gw->externalName()))
        return false;

    int a_priority = a->table->get_placement_priority_int();
    int b_priority = b->table->get_placement_priority_int();
    if (a_priority > b_priority) return true;
    if (a_priority < b_priority) return false;

    choice = SHARED_TABLES;
    if (a->complete_shared > b->complete_shared) return true;
    if (a->complete_shared < b->complete_shared) return false;

    ///> Downward Propagation - @seealso dynamic_dep_matrix
    choice = DOWNWARD_PROP_DSC;
    if (down_score.first > down_score.second) return !provided_stage;
    if (down_score.first < down_score.second) return provided_stage;

    ///> Downward Dominance Frontier - for definition,
    ///> see TableDependencyGraph::DepStagesThruDomFrontier
    choice = DOWNWARD_DOM_FRONTIER;
    if (deps->stage_info.at(a_table_to_use).dep_stages_dom_frontier == 0 &&
        deps->stage_info.at(b_table_to_use).dep_stages_dom_frontier != 0)
        return true;
    if (deps->stage_info.at(a_table_to_use).dep_stages_dom_frontier != 0 &&
        deps->stage_info.at(b_table_to_use).dep_stages_dom_frontier == 0)
        return false;

    ///> Direct Dependency Chain without propagation
    int a_local = deps->stage_info.at(a_table_to_use).dep_stages_control_anti;
    int b_local = deps->stage_info.at(b_table_to_use).dep_stages_control_anti;
    choice = LOCAL_DSC;
    if (a_local > b_local) return true;
    if (a_local < b_local) return false;


    ///> If the control dominating set is completely placeable
    choice = CDS_PLACEABLE;
    if (ddm.can_place_cds_in_stage(a_table_to_use, already_placed_a) &&
        !ddm.can_place_cds_in_stage(b_table_to_use, already_placed_b))
        return true;

    if (ddm.can_place_cds_in_stage(b_table_to_use, already_placed_b) &&
        !ddm.can_place_cds_in_stage(a_table_to_use, already_placed_a))
        return false;

    ///> If the table needs more match entries.  This can help pack more logical tables earlier
    ///> that have higher stage requirements
    choice = NEED_MORE;
    if (b->need_more_match && !a->need_more_match) return true;
    if (a->need_more_match && !b->need_more_match) return false;

    if (deps->stage_info.at(a_table_to_use).dep_stages_dom_frontier != 0) {
        choice = CDS_PLACE_COUNT;
        int comp = ddm.placeable_cds_count(a_table_to_use, already_placed_a) -
                   ddm.placeable_cds_count(b_table_to_use, already_placed_b);
        if (comp != 0)
            return comp > 0;
    }

    ///> Original dependency metric.  Feels like it should be deprecated
    int a_deps_stages = deps->stage_info.at(a_table_to_use).dep_stages;
    int b_deps_stages = deps->stage_info.at(b_table_to_use).dep_stages;
    choice = LOCAL_DS;
    if (a_deps_stages > b_deps_stages) return true;
    if (a_deps_stages < b_deps_stages) return false;

    ///> Total dependencies with dominance frontier summed
    int a_dom_frontier_deps = ddm.total_deps_of_dom_frontier(a_table_to_use);
    int b_dom_frontier_deps = ddm.total_deps_of_dom_frontier(b_table_to_use);
    choice = DOWNWARD_TD;
    if (a_dom_frontier_deps > b_dom_frontier_deps) return true;
    if (b_dom_frontier_deps > a_dom_frontier_deps) return false;

    ///> Average chain length of all tables within the dominance frontier
    double a_average_cds_deps = ddm.average_cds_chain_length(a_table_to_use);
    double b_average_cds_deps = ddm.average_cds_chain_length(b_table_to_use);
    choice = AVERAGE_CDS_CHAIN;
    if (a_average_cds_deps > b_average_cds_deps) return true;
    if (b_average_cds_deps > a_average_cds_deps) return false;


    ///> If the entirety of the control dominating set is placed vs. not
    choice = NEXT_TABLE_OPEN;
    int a_next_tables_in_use = a_table_to_use == a->gw ? 1 : 0;
    int b_next_tables_in_use = b_table_to_use == b->gw ? 1 : 0;

    int a_dom_set_size = ntp.control_dom_set.at(a_table_to_use).size() - 1;
    int b_dom_set_size = ntp.control_dom_set.at(b_table_to_use).size() - 1;;

    if (a_dom_set_size <= a_next_tables_in_use && b_dom_set_size > b_next_tables_in_use)
        return true;
    if (a_dom_set_size > a_next_tables_in_use && b_dom_set_size <= b_next_tables_in_use)
        return false;

    ///> Local dependencies
    choice = LOCAL_TD;
    int a_total_deps = deps->happens_before_dependences(a->table).size();
    int b_total_deps = deps->happens_before_dependences(b->table).size();
    if (a_total_deps < b_total_deps) return true;
    if (a_total_deps > b_total_deps) return false;

    choice = DEFAULT;
    return true;
}

class DumpSeqTables {
    const IR::MAU::TableSeq     *seq;
    bitvec                      which;
    friend std::ostream &operator<<(std::ostream &out, const DumpSeqTables &);
 public:
    DumpSeqTables(const IR::MAU::TableSeq *s, bitvec w) : seq(s), which(w) {}
};
std::ostream &operator<<(std::ostream &out, const DumpSeqTables &s) {
    const char *sep = "";
    for (auto i : s.which) {
        if (i >= 0 && (size_t)i < s.seq->tables.size())
            out << sep << s.seq->tables[i]->name;
        else
            out << sep << "<oob " << i << ">";
        sep = " "; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const ordered_set<const IR::MAU::Table *> &s) {
    const char *sep = "";
    for (auto *tbl : s) {
        out << sep << tbl->name;
        sep = ", "; }
    return out;
}

/**
 * In Tofino, a table that is split across multiple stages requires using the next table
 * to advance tables, and thus cannot start anything else on the worklist until that table
 * is fully finished.
 *
 * This does not matter when long branches are turned on, as the next table is no longer the
 * limiting factor.
 */
bool TablePlacement::can_place_with_partly_placed(const IR::MAU::Table *tbl,
        const ordered_set<const IR::MAU::Table *> &partly_placed, const Placed *placed) {
     if (!(Device::numLongBranchTags() == 0 || options.disable_long_branch))
         return true;

    for (auto pp : partly_placed) {
        if (pp == tbl || placed->is_match_placed(tbl) || placed->is_match_placed(pp))
            continue;
        if (!mutex(pp, tbl) && !siaa.mutex_through_ignore(pp, tbl)) {
            LOG3("  - skipping " << tbl->name << " as it is not mutually "
                 "exclusive with partly placed " << pp->name);
            return false;
        }
    }
    return true;
}

/**
 * The purpose of this function is to delay the beginning of placing gateway tables in
 * Tofino2 long before any other their control dependent match tables are placeable.
 * The goal of this is to reduce the number of live long branches at the same time.
 *
 * This is a decent holdover until the algorithm can track long branch usage during table
 * placement and guarantee that no constraints are broken from this angle.
 *
 * Basic algorithm:
 *
 * Let's say I have the following program snippet:
 *
 *     dep_table_1.apply();
 *     dep_table_2.apply();
 *
 *     if (cond-0) {
 *         if (cond-1) {
 *             match_table.apply();
 *         }
 *     }
 *
 * Now cond-0 may be placeable very early due to dependences, but the match_table might be
 * in a much later stage.  The goal is to not start placing cond-0 until all of the logical
 * match dependences are not broken.  The tables that must be placed for match_table to be
 * placed ared dep_table_1, dep_table_2, cond-0 and cond-1.  The checks are if a table is
 * already placed (Check #1) or if a table is control dependent on cond-0 (Check #2). 
 *
 * However, I found that this wasn't enough. Examine the following example:
 *
 *     if (cond-0) {
 *         if (cond-1) {
 *             match_table.apply();
 *         }
 *     } else {
 *         if (cond-2) {
 *             match_table.apply();
 *         }
 *     }
 *
 * Now in this example, when trying to place cond-1, the dependencies will notice cond-2 is
 * not placed, and will not start cond-1.  However, when trying to place cond-2, the dependencies
 * will notice cond-1 is not placed either and will not start placing cond-2.  This deadlock
 * is only currently stoppable by Check #3.
 *
 * The eventual goal is to get rid of this check and just verify that the compiler is not
 * running out of long branches.
 */
bool TablePlacement::gateway_thread_can_start(const IR::MAU::Table *tbl, const Placed *placed) {
    if (!Device::hasLongBranches() || options.disable_long_branch)
        return true;
    if (!tbl->uses_gateway())
        return true;
    // The gateway merge constraints are checked in an early function.  This is for unmergeable
    // gateways.
    auto gmc = gateway_merge_choices(tbl);
    if (gmc.size() > 0)
        return true;

    std::set<const IR::MAU::Table *> placeable_cd_gws;
    int non_cd_gw_tbls = 0;
    bool placeable_table_found = false;
    for (auto cd_tbl : ntp.control_dom_set.at(tbl)) {
        if (cd_tbl == tbl) continue;
        if (cd_tbl->uses_gateway()) continue;
        non_cd_gw_tbls++;
        bool any_prev_unaccounted = false;
        for (auto prev : deps->happens_logi_after_map.at(cd_tbl)) {
            if (prev->uses_gateway()) continue;   // Check #3 from comments
            if (placed && placed->is_placed(prev)) continue;   // Check #1 from comments
            if (ntp.control_dom_set.at(tbl).count(prev)) continue;   // Check #2 from comments
            any_prev_unaccounted = true;
            break;
        }
        if (any_prev_unaccounted) continue;
        placeable_table_found = true;
        break;
    }
    return placeable_table_found || non_cd_gw_tbls == 0;
}

IR::Node *TablePlacement::preorder(IR::BFN::Pipe *pipe) {
    LOG_FEATURE("stage_advance", 2, "Stage advance " <<
        (ignoreContainerConflicts ? "" : "not ") << "ignoring container conflicts");
    LOG1("table placement starting " << pipe->name);
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread) );
    tblInfo.clear();
    tblByName.clear();
    seqInfo.clear();
    attached_to.clear();
    ordered_set<const GroupPlace *>     work;  // queue with random-access lookup
    const Placed *placed = nullptr;
    /* all the state for a partial table placement is stored in the work
     * set and placed list, which are const pointers, so we can backtrack
     * by just saving a snapshot of a work set and corresponding placed
     * list and restoring that point */
    size_t gress_index = 0;
    for (auto th : pipe->thread) {
        if (th.mau && th.mau->tables.size() > 0) {
            th.mau->apply(SetupInfo(*this));
            new GroupPlace(*this, work, {}, th.mau);
            table_in_gress[gress_index] = true;
        }
        gress_index++;
    }
    if (pipe->ghost_thread && pipe->ghost_thread->tables.size() > 0) {
        pipe->ghost_thread->apply(SetupInfo(*this));
        new GroupPlace(*this, work, {}, pipe->ghost_thread); }
    for (auto &att : attached_to) {
        if (att.second.size() == 1) continue;
        if (att.first->direct)
            error("direct %s attached to multiple match tables", att.first); }

    ordered_set<const IR::MAU::Table *> partly_placed;
    Backfill backfill(*this);
    while (!work.empty()) {
        erase_if(partly_placed, [placed](const IR::MAU::Table *t) -> bool {
                                        return placed->is_placed(t); });
        if (placed) backfill.set_stage(placed->stage);
        StageUseEstimate current = get_current_stage_use(placed);
        LOG3("stage " << (placed ? placed->stage : 0) << ", work: " << work <<
             ", partly placed " << partly_placed.size() << ", placed " << count(placed) <<
             Log::endl << "    " << current);
        if (!partly_placed.empty())
            LOG5("    partly_placed: " << partly_placed);
        safe_vector<const Placed *> trial;
        for (auto it = work.begin(); it != work.end();) {
            // DANGER -- we iterate over the work queue while possibly removing and
            // appending groups.  So care is required to not invalidate the iterator
            // and not miss newly added groups.
            auto grp = *it;
            LOG4("  group " << grp->seq->id << " depth=" << grp->depth);
            if (placed && placed->placed.contains(grp->info.tables)) {
                LOG4("    group " << grp->seq->id << " is now complete");
                LOG5("      removing " << (*it)->seq->id << " from work list (b)");
                it = work.erase(it);
                auto add = grp->finish(work);
                if (it == work.end()) it = add;
                continue; }
            BUG_CHECK(grp->ancestors.count(grp) == 0, "group is its own ancestor!");
            if (Device::numLongBranchTags() == 0 || options.disable_long_branch) {
                // Table run only with next_table, so can't continue placing ancestors until
                // this group is finished
                if (LOGGING(5)) {
                    for (auto *s : grp->ancestors)
                        if (work.count(s))
                            LOG5("    removing " << s->seq->id << " from work as it is an " <<
                                 "ancestor of " << grp->seq->id); }
                work -= grp->ancestors; }
            int idx = -1;
            bool done = true;
            bitvec seq_placed;
            for (auto t : grp->seq->tables) {
                LOG3("  Group table: " << t->name);
            }
            bool first_not_yet_placed = true;
            for (auto t : grp->seq->tables) {
                ++idx;
                if (placed && placed->is_placed(t)) {
                    seq_placed[idx] = true;
                    LOG3("    - skipping " << t->name << " as its already done");
                    continue; }

                if (options.table_placement_in_order) {
                    if (first_not_yet_placed)
                        first_not_yet_placed = false;
                    else
                        break; }

                bool should_skip = false;  // flag to continue; outer loop;
                for (auto& grp_tbl : grp->seq->tables) {
                    if (deps->happens_before_control(t, grp_tbl) &&
                        (!placed || !(placed->is_placed(grp_tbl)))) {
                        LOG3("  - skipping " << t->name << " due to in-sequence control" <<
                            " dependence on " << grp_tbl->name);
                        done = false;
                        should_skip = true;
                        break; } }
                if (should_skip) continue;

                if (!are_metadata_deps_satisfied(placed, t)) {
                    LOG3("  - skipping " << t->name << " because metadata deps not satisfied");
                    // In theory, could continue, but the analysis at this point would be
                    // incorrect
                    done = false;
                    continue;
                }
                for (auto *prev : deps->happens_logi_after_map.at(t)) {
                    if (!placed || !placed->is_placed(prev)) {
                        LOG3("  - skipping " << t->name << " because it depends on " << prev->name);
                        done = false;
                        should_skip = true;
                        break; } }
                // Find potential tables this table can be merged with (if it's a gateway)

                if (!can_place_with_partly_placed(t, partly_placed, placed)) {
                     done = false;
                     continue;
                }

                auto gmc = TablePlacement::gateway_merge_choices(t);
                // Prune these choices according to happens after
                std::vector<const IR::MAU::Table*> to_erase;
                for (auto mc : gmc) {
                    // Iterate through all of this merge choice's happens afters and make sure
                    // they're placed
                    for (auto* prev : deps->happens_logi_after_map.at(mc.first)) {
                        if (prev == t)
                            continue;
                        if (!placed || !placed->is_placed(prev)) {
                            LOG3("    - removing " << mc.first->name << " from merge list because "
                                 "it depends on " << prev->name);
                            to_erase.push_back(mc.first);
                            break;
                        }
                    }

                    if (!can_place_with_partly_placed(mc.first, partly_placed, placed)) {
                        to_erase.push_back(mc.first);
                    }
                }
                // If we did have choices to merge but all of them are not ready yet, don't try to
                // place this gateway
                if (gmc.size() > 0 && gmc.size() == to_erase.size()) {
                    LOG2("    - skipping gateway " << t->name <<
                         " until mergeable tables are available");
                    should_skip = true;
                    done = false;
                }
                // Finally, erase these choices from gmc
                for (auto mc_unready : to_erase)
                    gmc.erase(mc_unready);

                if (!gateway_thread_can_start(t, placed)) {
                    LOG2("    - skipping gateway " << t->name <<
                         " until any of the control dominating tables can be placed");
                    should_skip = true;
                    done = false;
                }

                // Now skip attempting to place this table if this flag was set at all
                if (should_skip) continue;

                // Attempt to actually place the table
                auto pl_vec = try_place_table(t, placed, current, gmc);
                LOG3("    Pl vector: " << pl_vec);
                done = false;
                for (auto pl : pl_vec) {
                    pl->group = grp;
                    trial.push_back(pl);
                }
            }
            if (done) {
                BUG_CHECK(!placed->is_fully_placed(grp->seq), "Can't find a table to place");
                LOG5("      removing " << (*it)->seq->id << " from work list (c)");
                it = work.erase(it);
            } else {
                it++; } }
        if (work.empty()) break;
        if (trial.empty()) {
            if (errorCount() == 0) {
                error("Table placement cannot make any more progress.  Though some tables have "
                      "not yet been placed, dependency analysis has found that no more tables are "
                      "placeable.%1%", partly_placed.empty() ? "" :
                      "  This may be due to shared attachments on partly placed tables; may be "
                      "able to avoid the problem with @stage on those tables");
                for (auto *tbl : partly_placed)
                    error("partly placed: %s", tbl); }
            break; }
        LOG2("found " << trial.size() << " tables that could be placed: " << trial);
        const Placed *best = 0;
        placed = add_starter_pistols(placed, trial, current);

        choice_t choice = DEFAULT;
        for (auto t : trial) {
            if (t->prev) {
                LOG3("  Check point now " << t->prev << " " << (t->prev->prev == nullptr));
            }
            if (!best || is_better(t, best, choice)) {
                log_choice(t, best, choice);
                best = t;
            } else if (best) {
                log_choice(nullptr, best, choice); } }

        if (placed && best->stage > placed->stage && !options.disable_table_placement_backfill) {
            const Placed *backfilled = nullptr;
            /* look for a table that could be backfilled */
            for (auto &bf : backfill) {
                if (placed->is_placed(bf.table)) continue;
                if ((backfilled = try_backfill_table(placed, bf.table, bf.before))) {
                    BUG_CHECK(backfilled->is_placed(bf.table), "backfill !is_placed abort");
                    /* Found one -- currently we don't priorities if mulitple tables could
                     * be backfilled; just backfill the first found */
                    break; } }
            if (backfilled) {
                placed = backfilled;
                /* backfilling a table -- abort the current placement and go back and do it
                 * again in case something changed.  It seems that nothing ever should change
                 * so we'll end up finding the same table to place nextyt into the next stage
                 * anyways, but to ocntinue here we'd have to fix up the Placed to refer to
                 * the backfilled placed, and *best is (currently) const.  We also don't look
                 * for newly backfillable tables as that would pretty much require backtracking
                 * and redoing everything in the stage after tha backfilled table (would require
                 * checkpointing and restoring the work list) */
                continue; } }

        if (placed && best->stage != placed->stage) {
            LOG_FEATURE("stage_advance", 2,
                        "Stage " << placed->stage << IndentCtl::indent << Log::endl <<
                        StageSummary(placed->stage, best) << IndentCtl::unindent);
            for (auto t : trial) {
                if (t->stage == best->stage)
                    LOG_FEATURE("stage_advance", 2, "can't place " << t->name << " in stage " <<
                                (t->stage-1) << " : " << t->stage_advance_log); } }
        placed = place_table(work, best);

        if (!options.disable_table_placement_backfill) {
            for (auto p : trial) {
                /* Look for tables that are were placeable in this stage and are now not placeable
                 * and remember them for future backfilling.  Currently restricted to tables with
                 * no control dependent tables and no gateway merged */
                if (p != placed && p->stage == placed->stage && !work.count(p->group) &&
                    !p->need_more && !p->gw && p->table->next.empty()) {
                    LOG2("potential backfill " << p->name << " before " << placed->name);
                    backfill.add(p, placed); } } }

        if (placed->need_more)
            partly_placed.insert(placed->table);
        else
            partly_placed.erase(placed->table); }
    LOG1("Table placement placed " << count(placed) << " tables in " <<
         (placed ? placed->stage+1 : 0) << " stages");
    placement = placed;
    table_placed.clear();
    for (auto p = placement; p; p = p->prev) {
        LOG2("  Table " << p->name << " logical id 0x" << hex(p->logical_id) <<
             " entries=" << p->entries);
        for (auto &att : p->attached_entries)
            LOG3("    attached table " << att.first->name << " entries=" << att.second);
        assert(p->name == p->table->name);
        assert(p->need_more || table_placed.count(p->name) == 0);
        table_placed.emplace_hint(table_placed.find(p->name), p->name, p);
        if (p->gw) {
            LOG2("  Gateway " << p->gw->name << " is also logical id 0x" << hex(p->logical_id));
            assert(p->need_more || table_placed.count(p->gw->name) == 0);
            table_placed.emplace_hint(table_placed.find(p->gw->name), p->gw->name, p); } }
    LOG1("Finished table placement decisions " << pipe->name);
    return pipe;
}

/* Human-readable strings for the choice_t enum used to return
 * is_better decision info.
 */
std::ostream &operator<<(std::ostream &out, TablePlacement::choice_t choice) {
    static const char* choice_names[] = {
        "earlier stage calculated",
        "earlier stage provided",
        "more stages needed",
        "completes more shared tables",
        "user-provided priority",
        "longer downward prop control-included dependence tail chain",
        "longer local control-included dependence tail chain",
        "longer control-excluded dependence tail chain",
        "fewer total dependencies",
        "longer downward dominance frontier dependence chain",
        "fewer total dependencies in dominance frontier",
        "direct control dependency difference",
        "control dom set is placeable in this stage",
        "control dom set has more placeable tables",
        "average chain length of control dom set",
        "default choice"
         };
    if (choice < sizeof(choice_names) / sizeof(choice_names[0])) {
        out << choice_names[choice];
    } else {
        out << "unknown choice <0x" << hex(choice) << ">";
    }
    return out;
}

/*  Called when is_better indicates that a better table to place has been found.
 *  Prints a human-readable explanation for why that new table was chosen over
 *  the old one.
 */
void TablePlacement::log_choice(const Placed *t, const Placed *best, choice_t choice) {
    if (!best) {
        LOG3("    Updating best to first table seen: " << t->name);
    } else if (!t) {
        LOG5("    Keeping best " << best->name << " for reason: " << choice);
    } else {
        LOG3("    Updating best to " << t->name << " from " << best->name
             << " for reason: " << choice);
    }
}

IR::Node *TablePlacement::postorder(IR::BFN::Pipe *pipe) {
    tblInfo.clear();
    tblByName.clear();
    seqInfo.clear();
    table_placed.clear();
    LOG3("table placement completed " << pipe->name);
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread));
    return pipe;
}

void TablePlacement::table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *resources,
                                int entries) {
    tbl->resources = resources;
    tbl->layout.entries = entries;
    if (!tbl->ways.empty()) {
        BUG_CHECK(errorCount() > 0 || resources->memuse.count(tbl->unique_id()),
                  "Missing resources for %s", tbl);
        if (!tbl->layout.atcam && resources->memuse.count(tbl->unique_id())) {
            auto &mem = resources->memuse.at(tbl->unique_id());
            assert(tbl->ways.size() == mem.ways.size());
            for (unsigned i = 0; i < tbl->ways.size(); ++i)
                tbl->ways[i].entries = mem.ways[i].size * 1024 * tbl->ways[i].match_groups;
        }
    }
}

/* Sets the layout and ways for a table from the selected table layout option
   from table placement */
static void select_layout_option(IR::MAU::Table *tbl, const LayoutOption *layout_option) {
    tbl->layout = layout_option->layout;
    if (!layout_option->layout.ternary) {
        tbl->ways.resize(layout_option->way_sizes.size());
        int index = 0;
        for (auto &way : tbl->ways) {
            way = layout_option->way;
            way.entries = way.match_groups * 1024 * layout_option->way_sizes[index];
            index++;
        }
    }
}

/* Adds the potential ternary tables necessary for layout options */
static void add_attached_tables(IR::MAU::Table *tbl, const LayoutOption *layout_option,
        const TableResourceAlloc *resources) {
    if (resources->has_tind()) {
        BUG_CHECK(layout_option->layout.no_match_miss_path() ||
                  layout_option->layout.ternary, "Illegally allocating a ternary indirect");
        LOG3("  Adding Ternary Indirect table to " << tbl->name);
        auto *tern_indir = new IR::MAU::TernaryIndirect(tbl->name);
        tbl->attached.push_back(new IR::MAU::BackendAttached(tern_indir->srcInfo, tern_indir));
    }
    if (layout_option->layout.direct_ad_required()) {
        LOG3("  Adding Action Data Table to " << tbl->name);

        // TODO: Add pipe prefix with multi pipe support
        cstring ad_name = tbl->match_table->externalName();
        if (tbl->layout.pre_classifier)
            ad_name = ad_name + "_preclassifier";
        ad_name = ad_name + "$action";
        auto *act_data = new IR::MAU::ActionData(IR::ID(ad_name));
        act_data->direct = true;
        auto *ba = new IR::MAU::BackendAttached(act_data->srcInfo, act_data);
        ba->addr_location = IR::MAU::AddrLocation::DIRECT;
        ba->pfe_location = IR::MAU::PfeLocation::DEFAULT;
        tbl->attached.push_back(ba);
    }
}

/** Similar to splitting a IR::MAU::Table across stages, this is splitting an ATCAM
 *  IR::MAU::Table object into the multiple logical tables specified by the table placement
 *  algorithm.  Like split tables, these tables are chained in a hit miss chain in order
 *  to maintain priority.
 *
 *  For an ATCAM table split across stages, a pointer to the last table in the chain is saved
 *  in the last pointer to chain the last table in the current stage to the first table in
 *  the next stage
 */
IR::MAU::Table *TablePlacement::break_up_atcam(IR::MAU::Table *tbl, const Placed *placed,
    int stage_table, IR::MAU::Table **last) {
    IR::MAU::Table *rv = nullptr;
    IR::MAU::Table *prev = nullptr;
    int logical_tables = placed->use.preferred()->logical_tables();

    BUG_CHECK(stage_table == placed->stage_split, "mismatched stage table id");
    for (int lt = 0; lt < logical_tables; lt++) {
        auto *table_part = tbl->clone();
        if (lt != 0)
            table_part->remove_gateway();
        // Clear gateway_name for the split table
        table_part->logical_id = placed->logical_id + lt;
        table_part->logical_split = lt;
        table_part->logical_tables_in_stage = logical_tables;
        auto rsrcs = placed->resources.clone()->rename(tbl, stage_table, lt);
        int entries = placed->use.preferred()->partition_sizes[lt] * Memories::SRAM_DEPTH;
        table_set_resources(table_part, rsrcs, entries);

        if (!rv) {
            rv = table_part;
            assert(!prev);
        } else {
            prev->next["$try_next_stage"] = new IR::MAU::TableSeq(table_part);
            prev->next.erase("$miss");
        }

        if (last != nullptr)
            *last = table_part;
        prev = table_part;
    }
    return rv;
}

/** Splits a single dleft table into a Vector of tables.  Unlike ATCAM tables or multi-stage
 *  tables, predication is not used to enable or disable tables.   Instead all run, and the
 *  learn/match method is used to determine which table to run.  Thus, the algorithm differs
 *  from the hit miss chaining
 */
IR::Vector<IR::MAU::Table> *TablePlacement::break_up_dleft(IR::MAU::Table *tbl,
    const Placed *placed, int stage_table) {
    auto dleft_vector = new IR::Vector<IR::MAU::Table>();
    int logical_tables = placed->use.preferred()->logical_tables();
    BUG_CHECK(stage_table == placed->stage_split, "mismatched stage table id");

    for (int lt = 0; lt < logical_tables; lt++) {
        auto *table_part = tbl->clone();

        if (lt != 0)
            table_part->remove_gateway();
        table_part->logical_id = placed->logical_id + lt;
        table_part->logical_split = lt;
        table_part->logical_tables_in_stage = logical_tables;

        const IR::MAU::StatefulAlu *salu = nullptr;
        for (auto back_at : tbl->attached) {
            salu = back_at->attached->to<IR::MAU::StatefulAlu>();
            if (salu != nullptr)
                break;
        }
        auto rsrcs = placed->resources.clone()->rename(tbl, stage_table, lt);
        int per_row = RegisterPerWord(salu);
        int entries = placed->use.preferred()->dleft_hash_sizes[lt] * Memories::SRAM_DEPTH
                      * per_row;
        table_set_resources(table_part, rsrcs, entries);
        if (lt != logical_tables - 1)
            table_part->next.clear();

        dleft_vector->push_back(table_part);
    }
    return dleft_vector;
}

void TablePlacement::setup_detached_gateway(IR::MAU::Table *tbl, const Placed *placed) {
    tbl->remove_gateway();
    BUG_CHECK(placed->entries == 0, "match entries present");
    for (auto *ba : placed->table->attached) {
        if (ba->attached->direct || placed->attached_entries.at(ba->attached) == 0)
            continue;
        if (auto *ena = att_info.split_enable(ba->attached)) {
            tbl->gateway_rows.emplace_back(
                new IR::Equ(ena, new IR::Constant(1)), cstring());
            tbl->gateway_cond = ena->toString();
        }
    }
}

/** Note from gateway_merge:
 *
 *  Currently the algorithm is not sophisiticated enough to link a gateway table that has either
 *  a $hit or $miss next table information.  The reason is the following:
 *
 *  Let's say we have the following example before table placement:
 *
 *       cond-1
 *         |
 *         | $true
 *         |
 *      { t1, t2, t3 }
 *         |
 *         | $miss
 *         |
 *      { t1_miss }
 *
 *  where t1 and cond-1 are going to be linked into 1 logical table.
 *
 *  This is currently converted to:
 *
 *             cond-1
 *               t1
 *             /   \
 *      $miss /     \ $default
 *           /       \
 *     { t1_miss }  { t2, t3 }
 *
 *  This is fairly nonsensical, and incorrect.  Now because t1 is linked to the conditional,
 *  in order to run t2 and t3 if t1 does run is to always run t2 and t3 on default.
 *
 *  A correct next table propagation would look like the following:
 *
 *             cond-1
 *               t1
 *             /   \
 *      $miss /     \ $hit
 *           /       \
 *  { t1_miss } ---> { t2, t3 }
 *            $default
 *
 *  Essentially by not having a $default pathway combined with a hit/miss pathway, the control
 *  flow is correct.  Though this case is simple, other corner cases lead to a lot more difficult
 *  next table calculations, i.e. multiple layers of this miss chaining with a conditional.
 *  Thus currently the algorithm restricts linking conditionals with tables that have either
 *  $hit or $miss.
 */

IR::Node *TablePlacement::preorder(IR::MAU::Table *tbl) {
    auto it = table_placed.find(tbl->name);
    if (it == table_placed.end()) {
        BUG_CHECK(errorCount() > 0, "Trying to place a table %s that was never placed", tbl->name);
        return tbl; }
    if (tbl->is_placed())
        return tbl;
    tbl->logical_id = it->second->logical_id;
    // FIXME: Currently the gateway is laid out for every table, so I'm keeping the information
    // in split tables.  In the future, there should be no gw_layout for split tables
    IR::MAU::Table::Layout gw_layout;
    bool gw_only = true;
    bool gw_layout_used = false;

    if (it->second->gw && it->second->gw->name == tbl->name) {
        /* fold gateway and match table together */
        auto match = it->second->table;
        gw_only = false;
        assert(match && tbl->gateway_only() && !match->uses_gateway());
        LOG3("folding gateway " << tbl->name << " onto " << match->name);
        tbl->gateway_name = tbl->name;
        tbl->name = match->name;
        tbl->srcInfo = match->srcInfo;
        for (auto &gw : tbl->gateway_rows)
            if (gw.second == it->second->gw_result_tag)
                gw.second = cstring();
        tbl->match_table = match->match_table;
        tbl->match_key = match->match_key;
        tbl->actions = match->actions;
        tbl->attached = match->attached;
        tbl->entries_list = match->entries_list;
        // Use clone to copy all contents of match above?

        /* Generate the correct table layout from the options */
        gw_layout = tbl->layout;
        gw_layout_used = true;
        auto *seq = tbl->next.at(it->second->gw_result_tag)->clone();
        tbl->next.erase(it->second->gw_result_tag);
        if (seq->tables.size() != 1) {
            bool found = false;
            for (auto it = seq->tables.begin(); it != seq->tables.end(); it++)
                if (*it == match) {
                    seq->tables.erase(it);
                    found = true;
                    break; }
            BUG_CHECK(found, "failed to find match table");
        } else {
            assert(seq->tables[0] == match);
            seq = 0; }
        bool have_default = false;
        for (auto &next : match->next) {
            assert(tbl->next.count(next.first) == 0);
            if (next.first == "$default")
                have_default = true;
            if (seq) {
                auto *new_next = next.second->clone();
                for (auto t : seq->tables)
                    new_next->tables.push_back(t);
                tbl->next[next.first] = new_next;
            } else {
                tbl->next[next.first] = next.second; } }
        if (!have_default && seq)
            tbl->next["$default"] = seq;
        if (have_default || seq)
            for (auto &gw : tbl->gateway_rows)
                if (gw.second && !tbl->next.count(gw.second))
                    tbl->next[gw.second] = new IR::MAU::TableSeq();
    } else if (it->second->table->match_table) {
        gw_only = false;
    }


    if (table_placed.count(tbl->name) == 1) {
        if (!gw_only) {
            select_layout_option(tbl, it->second->use.preferred());
            add_attached_tables(tbl, it->second->use.preferred(), &it->second->resources);
            if (gw_layout_used)
                tbl->layout += gw_layout;
        }
        if (tbl->layout.atcam)
            return break_up_atcam(tbl, it->second);
        else if (tbl->for_dleft())
            return break_up_dleft(tbl, it->second);
        else
            table_set_resources(tbl, it->second->resources.clone(), it->second->entries);
        return tbl;
    }
    int stage_table = 0;
    IR::Vector<IR::MAU::Table> *rv = new IR::Vector<IR::MAU::Table>;
    IR::MAU::Table *prev = 0;
    IR::MAU::Table *atcam_last = nullptr;
    /* split the table into multiple parts per the placement */
    LOG1("splitting " << tbl->name << " across " << table_placed.count(tbl->name) << " stages");
    int deferred_attached = 0;
    for (auto *att : tbl->attached) {
        if (att->attached->direct) continue;
        if (can_duplicate(att->attached)) continue;
        // splitting a table with an un-duplicatable indirect attached table
        // allocate TempVar to propagate index from match to attachment stage
        ++deferred_attached;
        if (att->type_location == IR::MAU::TypeLocation::OVERHEAD)
            P4C_UNIMPLEMENTED("%s with multiple RegisterActions placed in separation stage from "
                              "%s; try using @stage to force them into the same stage",
                              tbl->match_table->name, att->attached->name); }
    if (deferred_attached > 1)
        P4C_UNIMPLEMENTED("Splitting %s with multiple indirect attachements not supported",
                          tbl->match_table->name);
    for (const Placed *pl : ValuesForKey(table_placed, tbl->name)) {
        auto *table_part = tbl->clone();
        // When a gateway is merged against a split table, only the first table created from the
        // split has the merged gateway
        if (!rv->empty())
            table_part->remove_gateway();

        if (stage_table != 0) {
            BUG_CHECK(!rv->empty(), "failed to attach first stage table");
            BUG_CHECK(stage_table == pl->stage_split, "Splitting table %s cannot be "
                      "resolved for stage table %d", table_part->name, stage_table); }
        select_layout_option(table_part, pl->use.preferred());
        add_attached_tables(table_part, pl->use.preferred(), &pl->resources);
        if (gw_layout_used)
            table_part->layout += gw_layout;
        table_part->logical_id = pl->logical_id;
        table_part->stage_split = pl->stage_split;

        if (pl->entries) {
            if (deferred_attached) {
                if (pl->use.format_type != ActionData::PRE_SPLIT_ATTACHED)
                    error("Couldn't find a usable split format for %1% and couldn't place it "
                          "without splitting", tbl);
                for (auto act = table_part->actions.begin(); act != table_part->actions.end();) {
                    if ((act->second = att_info.create_pre_split_action(act->second,
                                                                        table_part, &phv)))
                        ++act;
                    else
                        act = table_part->actions.erase(act); }
                erase_if(table_part->attached, [pl](const IR::MAU::BackendAttached *ba) {
                    return pl->attached_entries.count(ba->attached) &&
                           pl->attached_entries.at(ba->attached) == 0; }); }
            if (table_part->layout.atcam) {
                table_part = break_up_atcam(table_part, pl, pl->stage_split, &atcam_last);
            } else {
                auto rsrcs = pl->resources.clone()->rename(tbl, pl->stage_split);
                table_set_resources(table_part, rsrcs, pl->entries);
            }
        } else {
            if (pl->use.format_type != ActionData::POST_SPLIT_ATTACHED)
                error("Couldn't find a usable split format for %1% and couldn't place it "
                      "without splitting", tbl);
            BUG_CHECK(deferred_attached, "Split match from attached with no attached?");
            for (auto act = table_part->actions.begin(); act != table_part->actions.end();) {
                if ((act->second = att_info.create_post_split_action(act->second, table_part)))
                    ++act;
                else
                    act = table_part->actions.erase(act); }
            auto rsrcs = pl->resources.clone()->rename(tbl, pl->stage_split);
            table_set_resources(table_part, rsrcs, pl->entries);
            table_part->match_key.clear();
            table_part->next.clear();
            table_part->suppress_context_json = true;
            setup_detached_gateway(table_part, pl);
            if (table_part->actions.size() != 1)
                P4C_UNIMPLEMENTED("split attached table with multiple actions");
            erase_if(table_part->attached, [pl](const IR::MAU::BackendAttached *ba) {
                return !pl->attached_entries.count(ba->attached) ||
                       pl->attached_entries.at(ba->attached) == 0; });
            BUG_CHECK(!rv->empty(), "first stage has no match entries?");
            rv->push_back(table_part); }

        if (rv->empty()) {
            rv->push_back(table_part);
            BUG_CHECK(!prev, "didn't add prev stage table?");
        } else if (pl->entries) {
            // FIXME: Long term solution could be the following for these types of actions:
            //    - Clone all actions and set them all to hit_only
            //    - Create a noop action as miss_only
            //    - Get rid of the $try_next_stage and just go through the standard hit/miss
            // Separate control flow processing for try_next_stage vs miss"
            prev->next["$try_next_stage"] = new IR::MAU::TableSeq(table_part);
            prev->next.erase("$miss"); }

        stage_table++;
        prev = table_part;
        if (atcam_last)
            prev = atcam_last;
    }
    assert(!rv->empty());
    return rv;
}

IR::Node *TablePlacement::preorder(IR::MAU::BackendAttached *ba) {
    visitAgain();  // clone these for any table that has been cloned
    auto tbl = findContext<IR::MAU::Table>();
    if (!tbl || !tbl->resources) {
        BUG_CHECK(errorCount() > 0, "No table resources for %s", ba);
        return ba; }
    auto format = tbl->resources->table_format;

    if (ba->attached->is<IR::MAU::Counter>()) {
        if (format.stats_pfe_loc == IR::MAU::PfeLocation::OVERHEAD ||
            format.stats_pfe_loc == IR::MAU::PfeLocation::GATEWAY_PAYLOAD)
            ba->pfe_location = format.stats_pfe_loc;
    } else if (ba->attached->is<IR::MAU::Meter>() || ba->attached->is<IR::MAU::StatefulAlu>() ||
               ba->attached->is<IR::MAU::Selector>()) {
        if (format.meter_pfe_loc == IR::MAU::PfeLocation::OVERHEAD ||
            format.meter_pfe_loc == IR::MAU::PfeLocation::GATEWAY_PAYLOAD)
            ba->pfe_location = format.meter_pfe_loc;
        if (format.meter_type_loc == IR::MAU::TypeLocation::OVERHEAD ||
            format.meter_type_loc == IR::MAU::TypeLocation::GATEWAY_PAYLOAD)
            ba->type_location = format.meter_type_loc;
        if (tbl->layout.hash_action && !ba->attached->direct) {
            // FIXME -- this should actually be GATEWAY_PAYLOAD, but that is not yet set up
            // properly...
            ba->pfe_location = IR::MAU::PfeLocation::DEFAULT;
            // FIXME -- if there's more than one type, this needs to go in a JBay gateway
            // or match overhead of a small synthetic table.  For now we only support this
            ba->type_location = IR::MAU::TypeLocation::DEFAULT;
        }
    }

    for (auto act : Values(tbl->actions)) {
        if (auto *sc = act->stateful_call(ba->attached->name)) {
            if (!sc->index) continue;
            if (auto *hd = sc->index->to<IR::MAU::HashDist>()) {
                ba->hash_dist = hd;
                ba->addr_location = IR::MAU::AddrLocation::HASH;
                break; } } }

    // If the table has been converted to hash action, then the hash distribution unit has
    // to be tied to the BackendAttached object for the assembly output
    if (tbl->layout.hash_action && ba->attached->direct) {
        for (auto &hd_use : tbl->resources->hash_dists) {
            for (auto &ir_alloc : hd_use.ir_allocations) {
                if (ba->attached->is<IR::MAU::Counter>() &&
                    ir_alloc.dest != IXBar::HD_STATS_ADR)
                    continue;
                if (ba->attached->is<IR::MAU::Meter>() &&
                    ir_alloc.dest != IXBar::HD_METER_ADR)
                    continue;
                if (ba->attached->is<IR::MAU::ActionData>() &&
                    ir_alloc.dest != IXBar::HD_ACTIONDATA_ADR)
                    continue;
                BUG_CHECK(ir_alloc.created_hd != nullptr, "Hash Action did not create a "
                    "HashDist object during allocation");
                ba->hash_dist = ir_alloc.created_hd;
                ba->addr_location = IR::MAU::AddrLocation::HASH;
            }
        }
    }

    return ba;
}

IR::Node *TablePlacement::preorder(IR::MAU::TableSeq *seq) {
    // Inserting the starter pistol tables
    if (findContext<IR::MAU::Table>() == nullptr && seq->tables.size() > 0) {
        if (Device::currentDevice() == Device::TOFINO) {
            auto gress = seq->front()->gress;
            if (starter_pistol[gress] != nullptr) {
                seq->tables.push_back(starter_pistol[gress]);
            }
        }
    }
    return seq;
}

IR::Node *TablePlacement::postorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() > 1) {
        std::sort(seq->tables.begin(), seq->tables.end(),
            [](const IR::MAU::Table *a, const IR::MAU::Table *b) -> bool {
                return a->logical_id < b->logical_id;
        });
    }
    seq->deps.clear();  // FIXME -- not needed/valid?  perhaps set to all 1s?
    return seq;
}

std::multimap<cstring, const TablePlacement::Placed *>::const_iterator
TablePlacement::find_placed(cstring name) const {
    auto rv = table_placed.find(name);
    if (rv == table_placed.end()) {
        if (auto p = name.findlast('.'))
            rv = table_placed.find(name.before(p));
        if (auto p = name.findlast('$'))
            rv = table_placed.find(name.before(p));
    }
    return rv;
}

void dump(const ordered_set<const TablePlacement::GroupPlace *> &work) {
    std::cout << work << std::endl; }
