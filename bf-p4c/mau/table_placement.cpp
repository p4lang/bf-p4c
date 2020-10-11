#include "bf-p4c/mau/table_placement.h"

#include <boost/range/adaptor/reversed.hpp>

#include <algorithm>
#include <list>
#include <sstream>
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/ir/table_tree.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/logging/manifest.h"
#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/field_use.h"
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/payload_gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/log.h"
#include "lib/pointer_wrapper.h"
#include "lib/safe_vector.h"
#include "lib/set.h"

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
    auto rv = PassManager::init_apply(root);
    alloc_done = phv.alloc_done();
    summary.clearPlacementErrors();
    LOG1("Table Placement ignores container conflicts? " << ignoreContainerConflicts);
    if (BackendOptions().create_graphs) {
        static unsigned invocation = 0;
        auto pipeId = root->to<IR::BFN::Pipe>()->id;
        auto graphsDir = BFNContext::get().getOutputDirectory("graphs", pipeId);
        cstring fileName = "table_dep_graph_placement_" + std::to_string(invocation++);
        std::ofstream dotStream(graphsDir + "/" + fileName + ".dot", std::ios_base::out);
        DependencyGraph::dump_viz(dotStream, deps);
        Logging::Manifest::getManifest().addGraph(pipeId, "table", fileName,
                                                  INGRESS);  // this should be both really!
    }
    return rv;
}

class TablePlacement::SetupInfo : public Inspector {
    TablePlacement &self;
    bool preorder(const IR::MAU::Table *tbl) override {
        BUG_CHECK(!self.tblInfo.count(tbl), "Table in both ingress and egress?");
        auto &info = self.tblInfo[tbl];
        info.uid = self.tblInfo.size() - 1;
        info.table = tbl;
        auto *seq = getParent<IR::MAU::TableSeq>();
        BUG_CHECK(seq, "parent of Table is not TableSeq");
        info.refs.insert(seq);
        BUG_CHECK(!self.tblByName.count(tbl->name), "Duplicate tables named %s: %s and %s",
                  tbl->name, tbl, self.tblByName.at(tbl->name)->table);
        self.tblByName[tbl->name] = &info;
        return true; }
    void revisit(const IR::MAU::Table *tbl) override {
        auto *seq = getParent<IR::MAU::TableSeq>();
        BUG_CHECK(seq, "parent of Table is not TableSeq");
        self.tblInfo.at(tbl).refs.insert(seq); }
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
        if (auto tbl = getParent<IR::MAU::Table>()) {
            info.refs.insert(tbl);
        } else if (getParent<IR::BFN::Pipe>()) {
            info.root = true;
        } else {
            BUG("parent of TableSeq is not a table or pipe");
        }
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

    profile_t init_apply(const IR::Node *node) override {
        auto rv = Inspector::init_apply(node);
        self.tblInfo.clear();
        self.tblByName.clear();
        self.seqInfo.clear();
        self.attached_to.clear();
        return rv;
    }

    void end_apply() override {
        for (auto &att : self.attached_to) {
            if (att.second.size() == 1) continue;
            if (att.first->direct)
                self.error("direct %s attached to multiple match tables", att.first); }
        for (auto &seq : Values(self.seqInfo))
            for (auto *tbl : seq.refs)
                seq.parents.setbit(self.tblInfo.at(tbl).uid);
        for (auto &tbl : Values(self.tblInfo))
            for (auto *seq : tbl.refs)
                tbl.parents |= self.seqInfo.at(seq).parents;
    }

 public:
    explicit SetupInfo(TablePlacement &self_) : self(self_) {}
};


struct DecidePlacement::GroupPlace {
    /* tracking the placement of a group of tables from an IR::MAU::TableSeq
     *   parents    groups that must wait until this group is fully placed before any more
     *              tables from them may be placed (so next_table setup works)
     *   ancestors  union of parents and all parent's ancestors
     *   seq        the TableSeq being placed for this group */
    const DecidePlacement                &self;
    ordered_set<const GroupPlace *>     parents, ancestors;
    const IR::MAU::TableSeq             *seq;
    const TablePlacement::TableSeqInfo  &info;
    int                                 depth;  // just for debugging?
    GroupPlace(const DecidePlacement &self_, ordered_set<const GroupPlace*> &work,
               const ordered_set<const GroupPlace *> &par, const IR::MAU::TableSeq *s)
    : self(self_), parents(par), ancestors(par), seq(s), info(self.self.seqInfo.at(s)), depth(1) {
        for (auto p : parents) {
            if (depth <= p->depth)
                depth = p->depth+1;
            ancestors |= p->ancestors; }
        LOG4("    new seq " << seq->id << " depth=" << depth << " anc=" << ancestors);
        work.insert(this);
        if (Device::numLongBranchTags() == 0 || self.self.options.disable_long_branch) {
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
    void finish_if_placed(ordered_set<const GroupPlace*> &, const TablePlacement::Placed *) const;
    static bool in_work(ordered_set<const GroupPlace*> &work, const IR::MAU::TableSeq *s) {
        for (auto pl : work)
            if (pl->seq == s) return true;
        return false; }
    friend std::ostream &operator<<(std::ostream &out,
        const ordered_set<const DecidePlacement::GroupPlace *> &set) {
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
    const int                   id, clone_id;
    const Placed                *prev = 0;
    const DecidePlacement::GroupPlace *group = 0;  // work group chosen from
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
        : self(self_), id(++uid_counter), clone_id(id), prev(done), table(t) {
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
    const DecidePlacement::GroupPlace *find_group(const IR::MAU::Table *tbl) const {
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
                    BUG_CHECK(attached_entries.at(ba->attached).entries == 0 ||
                              attached_entries.at(ba->attached).entries == it->second.entries,
                              "inconsistent size for %s", ba->attached);
                    attached_entries.at(ba->attached) = it->second; }
                if (attached_entries.at(ba->attached).need_more)
                    need_more = true; }
            if (!need_more) {
                LOG3("    " << table->name << " is now also placed (1)");
                latest->complete_shared++;
                placed[self.tblInfo.at(table).uid] = 1; } }
        if (prev)
            placed |= prev->placed; }

#if 0
    // now unused -- maybe rotted
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
                if (attached_entries.at(ba->attached).need_more) {
                    need_more = true;
                    break; } }
            if (!need_more) {
                LOG3("    " << pp->name << " is now also placed (2)");
                complete_shared++;
                placed[self.tblInfo.at(pp).uid] = 1; } } }
#endif

    // update the action/meter formats in the TableResourceAlloc to match the StageUseEstimate
    void update_formats() {
        if (auto *af = use.preferred_action_format())
            resources.action_format = *af;
        if (auto *mf = use.preferred_meter_format())
            resources.meter_format = *mf; }

    void setup_logical_id() {
        LOG7("\t\tSetting logical id for table " << table->externalName());
        if (table->is_always_run_action()) {
            logical_id = -1;
            return;
        }

        auto curr = prev;
        while (curr && curr->table->is_always_run_action()) {
            curr = curr->prev;
        }

        if (curr && curr->stage == stage) {
            if (curr->table->conditional_gateway_only()) {
                logical_id = curr->logical_id + 1;
            } else {
                logical_id = curr->logical_id + curr->use.preferred()->logical_tables();
            }
        } else {
            logical_id = stage * StageUse::MAX_LOGICAL_IDS;
        }
        LOG7("\t\t\tLogical ID: " << logical_id);
    }

    friend std::ostream &operator<<(std::ostream &out, const TablePlacement::Placed *pl) {
        out << pl->name;
        return out; }

    Placed(const Placed &p)
        : self(p.self), id(++uid_counter), clone_id(p.clone_id), prev(p.prev), group(p.group),
           name(p.name), entries(p.entries), requested_stage_entries(p.requested_stage_entries),
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

class DecidePlacement::Backfill {
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
    explicit Backfill(DecidePlacement &) {}
    explicit operator bool() const { return !avail.empty(); }
    std::vector<table_t>::iterator begin() { return avail.begin(); }
    std::vector<table_t>::iterator end() { return avail.end(); }
    void set_stage(int st) {
        if (stage != st) avail.clear();
        stage = st; }
    void add(const TablePlacement::Placed *tbl, const TablePlacement::Placed *before) {
        set_stage(before->stage);
        avail.push_back({ tbl->table, before->name }); }
};

void DecidePlacement::GroupPlace::finish_if_placed(
    ordered_set<const GroupPlace*> &work, const TablePlacement::Placed *pl
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

            // table in more than one seq -- can't merge with gateway controling (only) one.
            if (tblInfo.at(t).refs.size() > 1) continue;

            if (it->second->deps[idx]) continue;

            // The TableSeqDeps does not currently capture dependencies like injected
            // control dependencies and metadata/dark initialization.  These have been folded
            // into the TableDependencyGraph and can be checked.
            // One could possibly fold this into TableSeqDeps, but only if initialization
            // happens in flow order, as the TableSeqDeps works with a LTBitMatrix
            for (auto t2 : it->second->tables) {
                if (deps.happens_logi_before(t2, t)) should_skip = true;
            }

            // If we have dependence ordering problems
            if (should_skip) continue;
            // If this table also uses gateways
            if (t->uses_gateway()) continue;
            // Always Run Instructions are not logical tables
            if (t->is_always_run_action()) continue;
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

/** count the numbner of distinct stateful actions invoked on a stateful alu in this table
 * if there is more than one, then which salu action to run will need to be selected in the
 * meter_type part of the meter address bus, and can't be set from the default
 * FIXME -- is this correct?  It seems to count all the calls, regardless of which instruction
 * they invoke -- multiple table actions that all call the same salu action should jsut be
 * counted as one sful action.
 */
static int count_sful_actions(const IR::MAU::Table *tbl) {
    int rv = 0;
    for (auto act : Values(tbl->actions))
        if (!act->stateful_calls.empty())
            ++rv;
    return rv;
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
bool TablePlacement::pick_layout_option(Placed *next, bool estimate_set) {
    bool table_format = true;

    int initial_entries = next->entries;

    if (!estimate_set)
        next->use = StageUseEstimate(next->table, next->entries, next->attached_entries, &lc,
                                     next->stage_split > 0, next->gw != nullptr);
    // FIXME: This is not the appropriate way to check if a table is a single gateway

    if (next->use.format_type == ActionData::POST_SPLIT_ATTACHED &&
        count_sful_actions(next->table) > 1) {
        // FIXME -- currently can't split a stateful table that require meter_type to select
        // which action to run
        error_message = next->name + " requires a meter_type, so can't split the attached "
                        "stateful table as a result";
        return false; }

    do {
        bool ixbar_fit = try_alloc_ixbar(next);
        if (!ixbar_fit) {
            next->stage_advance_log = "ran out of ixbar";
            return false; }
        if (next->use.format_type == ActionData::POST_SPLIT_ATTACHED) {
            // if post-split, there's no match in this stage (just a gateway running the
            // attached table(s), so no need for match formatting
            return true; }
        if (!next->table->conditional_gateway_only() && !next->table->is_always_run_action()) {
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

bool TablePlacement::shrink_estimate(Placed *next, int &srams_left, int &tcams_left,
        int min_entries) {
    if (next->table->is_a_gateway_table_only() || next->table->match_key.empty())
        return false;

    for (auto *ba : next->table->attached) {
        auto *att = ba->attached;
        if (att->direct || !can_split(att) || next->attached_entries.at(att).entries == 0) continue;
        if (next->entries > 0) {
            LOG3("  - splitting " << att->name << " to later stage(s)");
            next->attached_entries.at(att).entries = 0;
            next->attached_entries.at(att).need_more = true;
            // may need new layout&format type
            return pick_layout_option(next, false);
        } else {
            // FIXME -- need a better way of reducing the size to what will fit in the stage
            // Also need to fix the memories.cpp code to adjust the numbers to match how
            // many entries are actually allocated if it is not an extact match up.
            // Also need some way of telling ixbar allocation that more entries will be
            // needed in later stages, so it can chain_vpn properly.
            int delta = 1 << std::max(10, ceil_log2(next->attached_entries.at(att).entries) - 4);
            if (delta < next->attached_entries.at(att).entries) {
                next->attached_entries.at(att).entries -= delta;
                auto redo_layout = !next->attached_entries.at(att).need_more;
                next->attached_entries.at(att).need_more = true;
                LOG3("  - reducing size of " << att->name << " by " << delta << " to " <<
                     next->attached_entries.at(att).entries);
                if (redo_layout) {
                    // need new layout to allow for chain_vpn
                    return pick_layout_option(next, false); }
                return true; }
        }
    }

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
    const TablePlacement::Placed *pl;
    RewriteForSplitAttached(TablePlacement &self, const Placed *p)
        : self(self), pl(p) {}
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
        if (ba->attached->is<IR::MAU::Counter>() || ba->attached->is<IR::MAU::Meter>() ||
            ba->attached->is<IR::MAU::StatefulAlu>()) {
            ba->pfe_location = IR::MAU::PfeLocation::DEFAULT;
            if (!ba->attached->is<IR::MAU::Counter>())
                ba->type_location = IR::MAU::TypeLocation::DEFAULT;
        }
        prune();
        return ba; }
};

bool TablePlacement::try_alloc_ixbar(Placed *next) {
    next->resources.clear_ixbar();
    IXBar current_ixbar;
    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        current_ixbar.update(p->table, &p->resources);
    }
    current_ixbar.add_collisions();

    const ActionData::Format::Use *action_format = next->use.preferred_action_format();
    auto *table = next->table;
    if (next->entries == 0 && !table->conditional_gateway_only() &&
        !table->is_always_run_action()) {
        // detached attached table -- need to rewrite it as a hash_action gateway that
        // tests the enable bit it drives the attached table with the saved index
        // FIXME -- should we memoize this rather than recreating it each time?
        BUG_CHECK(!next->attached_entries.empty(),  "detaching attached from %s, no "
                  "attached entries?", next->name);
        BUG_CHECK(!next->gw, "Have a gateway merged with a detached attached table?");
        table = table->apply(RewriteForSplitAttached(*this, next));
    }

    if (!current_ixbar.allocTable(table, phv, next->resources, next->use.preferred(),
                                  action_format, next->attached_entries) ||
        !current_ixbar.allocTable(next->gw, phv, next->resources, next->use.preferred(),
                                  nullptr, next->attached_entries)) {
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

    if (shrink_lt)
        current_mem.shrink_allowed_lts();

    const IR::MAU::Table *table_to_add = nullptr;
    for (auto *p : whole_stage) {
        table_to_add = p->table;
        if (p->use.format_type == ActionData::POST_SPLIT_ATTACHED)
            table_to_add = table_to_add->apply(RewriteForSplitAttached(*this, p));
        BUG_CHECK(p != next && p->stage == next->stage, "invalid whole_stage");
        // Always Run Tables cannot be counted in the logical table check
        current_mem.add_table(table_to_add, p->gw, &p->resources, p->use.preferred(),
                              p->use.preferred_action_format(), p->use.format_type,
                              p->entries, p->stage_split, p->attached_entries);
        p->resources.memuse.clear(); }
    table_to_add = next->table;
    if (next->use.format_type == ActionData::POST_SPLIT_ATTACHED)
        table_to_add = table_to_add->apply(RewriteForSplitAttached(*this, next));
    current_mem.add_table(table_to_add, next->gw, &next->resources, next->use.preferred(),
                          next->use.preferred_action_format(), next->use.format_type,
                          next->entries, next->stage_split, next->attached_entries);
    next->resources.memuse.clear();

    if (!current_mem.allocate_all()) {
        error_message = next->table->toString() + " could not fit in stage " +
                        std::to_string(next->stage) + " with " + std::to_string(next->entries)
                        + " entries";
        const char *sep = " along with ";
        for (auto &ae : next->attached_entries) {
            if (ae.second.entries > 0) {
                error_message += sep + std::to_string(ae.second.entries) + " entries of " +
                                 ae.first->toString();
                sep = " and "; } }
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

bool TablePlacement::try_alloc_format(Placed *next, bool gw_linked) {
    const bitvec immediate_mask = next->use.preferred_action_format()->immediate_mask;
    next->resources.table_format.clear();
    gw_linked |= next->use.preferred()->layout.gateway &&
                 next->use.preferred()->layout.hash_action;
    TableFormat current_format(*next->use.preferred(), next->resources.match_ixbar,
                               next->resources.proxy_hash_ixbar, next->table,
                               immediate_mask, gw_linked, lc.fpc);

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
    if (next->table->conditional_gateway_only())
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

bool TablePlacement::try_alloc_imem(TablePlacement::Placed *next) {
    if (next->table->conditional_gateway_only())
        return true;

    InstructionMemory imem;
    next->resources.instr_mem.clear();

    for (auto *p = next->prev; p && p->stage == next->stage; p = p->prev) {
        imem.update(p->name, &p->resources, p->table);
    }

    bool gw_linked = next->gw != nullptr;
    gw_linked |= next->use.preferred()->layout.gateway &&
                 next->use.preferred()->layout.hash_action;
    if (!imem.allocate_imem(next->table, next->resources.instr_mem, phv, gw_linked,
                            next->use.format_type, att_info)) {
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
    if (auto ran_out = get_current_stage_use(next).ran_out()) {
        LOG3("    " << what << " of memory allocation ran out of " << ran_out);
        next->stage_advance_log = "ran out of " + ran_out;
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

/// Check if an indirect attached table can be split acorss stages
bool TablePlacement::can_split(const IR::MAU::AttachedMemory *att) {
    BUG_CHECK(!att->direct, "Not an indirect attached table");
    if (Device::currentDevice() == Device::TOFINO) {
        // Tofino not supported yet -- need vpn check in gateway
        return false; }
    if (BackendOptions().disable_split_attached)
        return false;
    if (att->is<IR::MAU::Selector>())
        return false;
    if (auto *salu = att->to<IR::MAU::StatefulAlu>())
        return !salu->synthetic_for_selector;
    // non-stateful need vpn checks in gateway (as on Tofino1), as the JBay vpn offset/range
    // check only works on stateful tables.
    // FIXME -- there are stats_vpn_range regs that could work for counters on Jbay (but
    // no stats_vpn_offset to adjust, and no support in the assembler yet).  stateful
    // address to adb path looks like it might be generic for meter address, so could be
    // used for meters as well?  Also no assembler support yet.
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
        if (!rv->attached_entries.emplace(ba->attached, ba->attached->size).second)
            BUG("%s attached more than once", ba->attached);
        if (can_duplicate(ba->attached)) continue;
        bool stateful_selector = ba->attached->is<IR::MAU::StatefulAlu>() &&
                                 ba->use == IR::MAU::StatefulUse::NO_USE;
        for (auto *att_to : attached_to.at(ba->attached)) {
            if (att_to == rv->table) continue;
            // If shared with another table that is not placed yet, need to
            // defer the placement of this attached table
            if (!rv->is_match_placed(att_to)) {
                tables_with_shared.insert(att_to);

                // Can't split indirect attached table when more than one stateful action exist
                if (count_sful_actions(rv->table) > 1)
                    continue;

                rv->attached_entries.at(ba->attached).entries = 0;
                rv->attached_entries.at(ba->attached).need_more = true;
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
    auto init_attached = rv->attached_entries;
    std::set<const IR::MAU::AttachedMemory *> need_defer;
    for (auto *p = rv->prev; p; p = p->prev) {
        if (p->name == rv->name) {
            if (p->need_more == false) {
                BUG(" - can't place %s it's already done", rv->name);
                return false; }
            rv->entries -= p->entries;
            for (auto &ate : p->attached_entries) {
                if (ate.first->direct) continue;
                if (can_duplicate(ate.first) &&
                    init_attached.at(ate.first).entries <= ate.second.entries)
                    continue;
                rv->attached_entries.at(ate.first).entries -= ate.second.entries;
                // if the match table is split, can't currently put any of the indirect
                // attached tables in the same stage as (part of) the match, so need to
                // move all entries to a later stage UNLESS we're finished with the match
                need_defer.insert(ate.first); }
            prev_stage_tables++;
            if (p->stage == rv->stage) {
                LOG2("  Cannot place multiple sections of an individual table in the same stage");
                rv->stage_advance_log = "cannot split into same stage";
                rv->stage++; }
        } else if (p->stage == rv->stage) {
            if (options.forced_placement)
                continue;
            if (deps.happens_phys_before(p->table, rv->table)) {
                rv->stage++;
                LOG2("  - dependency between " << p->table->name << " and table advances stage");
                rv->stage_advance_log = "dependency on table " + p->table->name;
            } else if (rv->gw && deps.happens_phys_before(p->table, rv->gw)) {
                rv->stage++;
                LOG2("  - dependency between " << p->table->name << " and gateway advances stage");
                rv->stage_advance_log = "gateway dependency on table " + p->table->name;
            } else if (deps.container_conflict(p->table, rv->table)) {
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
                    if (deps.happens_phys_before(p->table, ctbl)) {
                        rv->stage++;
                        LOG2("  - dependency between " << p->table->name << " and " <<
                             ctbl->name << " advances stage");
                        rv->stage_advance_log = "shared table " + ctbl->name +
                            " depends on table " + p->table->name;
                        break;
                    } else if (deps.container_conflict(p->table, ctbl)) {
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
    if (rv->entries <= 0 && !t->conditional_gateway_only() && !t->is_always_run_action()) {
        rv->entries = 0;
        // FIXME -- should use std::any_of, but pre C++-17 is too hard to use and verbose
        bool have_attached = false;
        for (auto &ate : rv->attached_entries) {
            if (ate.second.entries > 0) {
                have_attached = true;
                break; } }
        if (!have_attached) return false;
    } else {
        for (auto *at : need_defer) {
            // if the match table is split, can't currently put any of the indirect
            // attached tables in the same stage as (part of) the match
            rv->attached_entries.at(at).need_more = rv->attached_entries.at(at).entries > 0;
            rv->attached_entries.at(at).entries = 0; } }

    auto stage_pragma = t->get_provided_stage(&rv->stage, &rv->requested_stage_entries);
    if (rv->requested_stage_entries > 0)
        LOG5("Using " << rv->requested_stage_entries << " for stage " << rv->stage
             << " out of total " << rv->entries);

    if (stage_pragma >= 0) {
        rv->stage = std::max(stage_pragma, rv->stage);
        furthest_stage = std::max(rv->stage, furthest_stage);
    } else if (options.forced_placement && !t->conditional_gateway_only()) {
        ::warning("%s: Table %s has not been provided a stage even though forced placement of "
                  "tables is turned on", t->srcInfo, t->name);
    }

    if (prev_stage_tables > 0) {
        rv->initial_stage_split = prev_stage_tables;
        rv->stage_split = prev_stage_tables;
    }
    for (auto *ba : rv->table->attached) {
        if (ba->attached->direct &&
            !rv->attached_entries.emplace(ba->attached, rv->entries).second)
            BUG("%s attached more than once", ba->attached); }

    return true;
}

/** When placing a gateway table, the gateway can potential be combined with a match table
 *  to build one logical table.  The gateway_merge function picks a legal table to place with
 *  this table.  This loops through all possible tables to be merged, and will
 *  return a vector of these possible choices to the is_better function to choose
 */
safe_vector<TablePlacement::Placed *>
    TablePlacement::try_place_table(const IR::MAU::Table *t, const Placed *done,
        const StageUseEstimate &current, GatewayMergeChoices& gmc) {
    LOG1("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    safe_vector<Placed *> rv_vec;
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
    if (count_sful_actions(rv->table) > 1) {
        // FIXME -- can't currently split tables with multiple stateful actions, as doing so
        // would require passing the meter_type via tempvar somehow.
    } else {
        for (auto &att : min_placed->attached_entries) {
            if (att.first->direct) continue;
            if (can_split(att.first)) {
                att.second.entries = 0;
                att.second.need_more = true; } } }

    if (!rv->table->created_during_tp) {
        assert(!rv->placed[tblInfo.at(rv->table).uid]);
    }

    StageUseEstimate stage_current = current;
    // According to the driver team, different stage tables can have different action
    // data allocations, so the algorithm doesn't have to prefer this allocation across
    // stages

    bool allocated = false;

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
                                   rv->stage_split > 0, rv->gw != nullptr);

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
                error_message = "PHV allocation doesn't want this table split, and it's "
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
                        rv->attached_entries.at(ba->attached).entries = rv->entries;
                        rv->attached_entries.at(ba->attached).need_more = true;
                    } else if (!can_duplicate(ba->attached)) {
                        if (can_split(ba->attached)) {
                            // FIXME -- we can't currently have an indirect attached table in
                            // the same stage as part of the match but not all of it.
                            rv->attached_entries.at(ba->attached).entries = 0;
                            rv->attached_entries.at(ba->attached).need_more = true;
                        } else {
                            advance_to_next_stage = true;
                            break; } } }
                rv->need_more = rv->need_more_match = true;
                // If the table is split for the first time, then the stage_split is set to 0
                if (rv->initial_stage_split == -1)
                    rv->stage_split = 0;
            }

            if (!try_alloc_adb(rv)) {
                LOG1("ERROR: Action Data Bus Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }

            if (!try_alloc_imem(rv)) {
                LOG1("ERROR: Instruction Memory Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }
        }

        if (advance_to_next_stage) {
            rv->stage++;
            rv->stage_split = rv->initial_stage_split;
            min_placed->stage++;
            min_placed->stage_split = min_placed->initial_stage_split;
            if (done) {
                rv->placed -= rv->prev->placed - done->placed;
                min_placed->placed -= min_placed->prev->placed - done->placed; }
            rv->prev = min_placed->prev = done;
            stage_current.clear();
            for (auto *p : whole_stage) delete p;  // help garbage collector
            whole_stage.clear();
        } else if (rv->requested_stage_entries > 0 && rv->requested_stage_entries <= rv->entries) {
            // If the table had a stage pragma, we placed the slice of the table requested by
            // stage pragma and we need to make sure that the rest of entries are going to be
            // placed in subsequent stages.
            rv->requested_stage_entries = -1;
            rv->need_more = rv->need_more_match = true;
        }
    } while (!allocated && rv->stage <= furthest_stage);

    for (auto *ba : rv->table->attached) {
        auto *att = ba->attached;
        if (att->direct) continue;
        // indirect attached tables that could not be completely placed (due to needing other
        // tables placed first, or not enough room) mean we may need more...
        if (rv->attached_entries.at(att).need_more) {
            rv->need_more = true;
            break; } }

    rv->update_formats();
    if (!rv->table->conditional_gateway_only()) {
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

    if (!rv->table->is_always_run_action())
       BUG_CHECK((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage, "Table %s is not "
                 "assigned to the same stage (%d) at its logical id (%d)",
                 rv->table->externalName(), rv->stage, rv->logical_id);
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
TablePlacement::Placed *DecidePlacement::try_backfill_table(
        const TablePlacement::Placed *done, const IR::MAU::Table *tbl, cstring before) {
    LOG2("try to backfill " << tbl->name << " before " << before);
    std::vector<TablePlacement::Placed *> whole_stage;
    TablePlacement::Placed *place_before = nullptr;
    for (const TablePlacement::Placed **p = &done; *p && (*p)->stage == done->stage; ) {
        if (!(*p)->table->created_during_tp && !self.mutex(tbl, (*p)->table) &&
            self.deps.container_conflict(tbl, (*p)->table)) {
            LOG4("  can't backfill due to container conflict with " << (*p)->name);
            return nullptr; }
        auto clone = new TablePlacement::Placed(**p);
        whole_stage.push_back(clone);
        if (clone->name == before) {
            BUG_CHECK(!place_before, "%s placed multiple times in stage %d", before, done->stage);
            place_before = clone; }
        *p = clone;
        p = &clone->prev; }
    if (!place_before) {
        BUG("Couldn't find %s in stage %d", before, done->stage);
        return nullptr; }
    TablePlacement::Placed *pl = new TablePlacement::Placed(self, tbl, place_before->prev);
    int furthest_stage = done->stage;
    if (!self.initial_stage_and_entries(pl, furthest_stage))
        return nullptr;
    if (pl->stage != place_before->stage)
        return nullptr;
    place_before->prev = pl;
    if (!self.try_alloc_all(pl, whole_stage, "Backfill"))
        return nullptr;
    for (auto &ae : pl->attached_entries)
        if (ae.second.entries == 0 || ae.second.need_more)
            return nullptr;
    int lts = pl->use.preferred()->logical_tables();
    if (lts + (done->logical_id % StageUse::MAX_LOGICAL_IDS) >= StageUse::MAX_LOGICAL_IDS)
        return nullptr;
    for (auto *p : whole_stage) {
        p->logical_id += lts;
        p->placed[self.tblInfo.at(tbl).uid] = 1;
        p->match_placed[self.tblInfo.at(tbl).uid] = 1;
        if (p == place_before)
            break; }
    pl->update_formats();
    for (auto *p : whole_stage)
        p->update_formats();
    pl->setup_logical_id();
    pl->placed[self.tblInfo.at(tbl).uid] = 1;
    pl->match_placed[self.tblInfo.at(tbl).uid] = 1;
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " << pl->stage << "(" <<
         hex(pl->logical_id) << ") " << pl->use.format_type << " (backfilled)");
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
const TablePlacement::Placed *TablePlacement::add_starter_pistols(const Placed *done,
        safe_vector<const Placed *> &trial, const StageUseEstimate &current) {
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
DecidePlacement::place_table(ordered_set<const GroupPlace *>&work,
        const TablePlacement::Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " << pl->stage << "(" <<
         hex(pl->logical_id) << ") " << pl->use.format_type <<
         (pl->need_more_match ? " (need more match)" : pl->need_more ? " (need more)" : ""));

    if (pl->table) {
        int dep_chain = self.deps.stage_info[pl->table].dep_stages_control_anti;
        if (pl->stage + dep_chain >= Device::numStages())
            LOG1(" Dependence chain longer than available stages");
    }
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
            for (auto tbl : self.seqInfo.at(n).refs) {
                if (pl->is_placed(tbl)) {
                    parents.insert(pl->find_group(tbl));
                } else {
                    ready = false;
                    break; } }
            if (n->tables.size() == 1 && n->tables.at(0) == pl->table) {
                BUG_CHECK(!found_match && !gw_match_grp,
                          "Table appears twice: %s", pl->table->name);
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
                    BUG_CHECK(!found_match && !gw_match_grp,
                              "Table appears twice: %s", t->name);
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
                for (auto tbl : self.seqInfo.at(n).refs) {
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

bool DecidePlacement::are_metadata_deps_satisfied(const TablePlacement::Placed *placed,
                                                 const IR::MAU::Table* t) const {
    // If there are no reverse metadata deps for this table, return true.
    LOG4("Checking table " << t->name << " for metadata dependencies");
    const ordered_set<cstring> set_of_tables = self.phv.getReverseMetadataDeps(t);
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
    const TablePlacement::Placed *done = a->prev;
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
    LOG5("        local dep score " << deps.stage_info.at(a_table_to_use).dep_stages_control_anti);
    LOG5("        dom frontier " << deps.stage_info.at(a_table_to_use).dep_stages_dom_frontier);
    LOG5("        can place cds in stage "
          << ddm.can_place_cds_in_stage(a_table_to_use, already_placed_a));

    LOG5("      Stage B is " << b->name << ((a->gw) ? (" $" + a->gw->name) : "") <<
         " with calculated stage " << b->stage <<
         ", provided stage " << b->table->get_provided_stage(&b->stage) <<
         ", priority " << b->table->get_placement_priority_int());
    LOG5("        downward prop score " << down_score.second);
    LOG5("        local dep score " << deps.stage_info.at(b_table_to_use).dep_stages_control_anti);
    LOG5("        dom frontier " << deps.stage_info.at(b_table_to_use).dep_stages_dom_frontier);
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
    if (deps.stage_info.at(a_table_to_use).dep_stages_dom_frontier == 0 &&
        deps.stage_info.at(b_table_to_use).dep_stages_dom_frontier != 0)
        return true;
    if (deps.stage_info.at(a_table_to_use).dep_stages_dom_frontier != 0 &&
        deps.stage_info.at(b_table_to_use).dep_stages_dom_frontier == 0)
        return false;

    ///> Direct Dependency Chain without propagation
    int a_local = deps.stage_info.at(a_table_to_use).dep_stages_control_anti;
    int b_local = deps.stage_info.at(b_table_to_use).dep_stages_control_anti;
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

    if (deps.stage_info.at(a_table_to_use).dep_stages_dom_frontier != 0) {
        choice = CDS_PLACE_COUNT;
        int comp = ddm.placeable_cds_count(a_table_to_use, already_placed_a) -
                   ddm.placeable_cds_count(b_table_to_use, already_placed_b);
        if (comp != 0)
            return comp > 0;
    }

    ///> Original dependency metric.  Feels like it should be deprecated
    int a_deps_stages = deps.stage_info.at(a_table_to_use).dep_stages;
    int b_deps_stages = deps.stage_info.at(b_table_to_use).dep_stages;
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
    int a_total_deps = deps.happens_before_dependences(a->table).size();
    int b_total_deps = deps.happens_before_dependences(b->table).size();
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
bool DecidePlacement::can_place_with_partly_placed(const IR::MAU::Table *tbl,
        const ordered_set<const IR::MAU::Table *> &partly_placed,
        const TablePlacement::Placed *placed) {
     if (!(Device::numLongBranchTags() == 0 || self.options.disable_long_branch))
         return true;

    for (auto pp : partly_placed) {
        if (pp == tbl || placed->is_match_placed(tbl) || placed->is_match_placed(pp))
            continue;
        if (!self.mutex(pp, tbl) && !self.siaa.mutex_through_ignore(pp, tbl)) {
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
bool DecidePlacement::gateway_thread_can_start(const IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed) {
    if (!Device::hasLongBranches() || self.options.disable_long_branch)
        return true;
    if (!tbl->uses_gateway())
        return true;
    // The gateway merge constraints are checked in an early function.  This is for unmergeable
    // gateways.
    auto gmc = self.gateway_merge_choices(tbl);
    if (gmc.size() > 0)
        return true;

    std::set<const IR::MAU::Table *> placeable_cd_gws;
    int non_cd_gw_tbls = 0;
    bool placeable_table_found = false;
    for (auto cd_tbl : self.ntp.control_dom_set.at(tbl)) {
        if (cd_tbl == tbl) continue;
        if (cd_tbl->uses_gateway()) continue;
        non_cd_gw_tbls++;
        bool any_prev_unaccounted = false;
        for (auto prev : self.deps.happens_logi_after_map.at(cd_tbl)) {
            if (prev->uses_gateway()) continue;   // Check #3 from comments
            if (placed && placed->is_placed(prev)) continue;   // Check #1 from comments
            if (self.ntp.control_dom_set.at(tbl).count(prev)) continue;   // Check #2 from comments
            any_prev_unaccounted = true;
            break;
        }
        if (any_prev_unaccounted) continue;
        placeable_table_found = true;
        break;
    }
    return placeable_table_found || non_cd_gw_tbls == 0;
}

void DecidePlacement::initForPipe(const IR::BFN::Pipe *pipe,
        ordered_set<const GroupPlace *> &work) {
    size_t gress_index = 0;
    for (auto th : pipe->thread) {
        if (th.mau && th.mau->tables.size() > 0) {
            new GroupPlace(*this, work, {}, th.mau);
            self.table_in_gress[gress_index] = true;
        }
        gress_index++;
    }
    if (pipe->ghost_thread && pipe->ghost_thread->tables.size() > 0) {
        new GroupPlace(*this, work, {}, pipe->ghost_thread); }
}

bool DecidePlacement::preorder(const IR::BFN::Pipe *pipe) {
    LOG_FEATURE("stage_advance", 2, "Stage advance " <<
        (self.ignoreContainerConflicts ? "" : "not ") << "ignoring container conflicts");
    LOG1("table placement starting " << pipe->name);
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread) );
    ordered_set<const GroupPlace *>     work;  // queue with random-access lookup
    const TablePlacement::Placed *placed = nullptr;
    /* all the state for a partial table placement is stored in the work
     * set and placed list, which are const pointers, so we can backtrack
     * by just saving a snapshot of a work set and corresponding placed
     * list and restoring that point */
    initForPipe(pipe, work);

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
        safe_vector<const TablePlacement::Placed *> trial;
        bitvec  trial_tables;
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
            if (Device::numLongBranchTags() == 0 || self.options.disable_long_branch) {
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
                auto &info = self.tblInfo.at(t);
                if (trial_tables[info.uid])
                    continue;
                if (info.parents && (!placed || (info.parents - placed->match_placed))) {
                    LOG3("    - skipping " << t->name << " as a parent is not yet placed");
                    continue; }

                if (self.options.table_placement_in_order) {
                    if (first_not_yet_placed)
                        first_not_yet_placed = false;
                    else
                        break; }

                bool should_skip = false;  // flag to continue; outer loop;
                for (auto& grp_tbl : grp->seq->tables) {
                    if (self.deps.happens_before_control(t, grp_tbl) &&
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
                for (auto *prev : self.deps.happens_logi_after_map.at(t)) {
                    if (!placed || !placed->is_match_placed(prev)) {
                        LOG3("  - skipping " << t->name << " because it depends on " << prev->name);
                        done = false;
                        should_skip = true;
                        break; } }
                // Find potential tables this table can be merged with (if it's a gateway)

                if (!can_place_with_partly_placed(t, partly_placed, placed)) {
                     done = false;
                     continue;
                }

                auto gmc = self.gateway_merge_choices(t);
                // Prune these choices according to happens after
                std::vector<const IR::MAU::Table*> to_erase;
                for (auto mc : gmc) {
                    // Iterate through all of this merge choice's happens afters and make sure
                    // they're placed
                    for (auto* prev : self.deps.happens_logi_after_map.at(mc.first)) {
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
                auto pl_vec = self.try_place_table(t, placed, current, gmc);
                LOG3("    Pl vector: " << pl_vec);
                done = false;
                for (auto pl : pl_vec) {
                    pl->group = grp;
                    trial.push_back(pl);
                    trial_tables.setbit(self.tblInfo.at(pl->table).uid);
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
        const TablePlacement::Placed *best = 0;
        placed = self.add_starter_pistols(placed, trial, current);

        TablePlacement::choice_t choice = TablePlacement::DEFAULT;
        for (auto t : trial) {
            if (best)
                LOG3("For trial t : " << t->name << " with best: " << best->name);
            if (!best || self.is_better(t, best, choice)) {
                self.log_choice(t, best, choice);
                best = t;
            } else if (best) {
                self.log_choice(nullptr, best, choice); } }

        if (placed && best->stage > placed->stage &&
            !self.options.disable_table_placement_backfill) {
            const TablePlacement::Placed *backfilled = nullptr;
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

        if (!self.options.disable_table_placement_backfill) {
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
    self.placement = placed;
    self.table_placed.clear();
    for (auto p = self.placement; p; p = p->prev) {
        LOG2("  Table " << p->name << " logical id 0x" << hex(p->logical_id) <<
             " entries=" << p->entries);
        for (auto &att : p->attached_entries)
            LOG3("    attached table " << att.first->name << " entries=" << att.second.entries <<
                 (att.second.need_more ? " (need_more)" : ""));
        assert(p->name == p->table->name);
        assert(p->need_more || self.table_placed.count(p->name) == 0);
        self.table_placed.emplace_hint(self.table_placed.find(p->name), p->name, p);
        if (p->gw) {
            LOG2("  Gateway " << p->gw->name << " is also logical id 0x" << hex(p->logical_id));
            assert(p->need_more || self.table_placed.count(p->gw->name) == 0);
            self.table_placed.emplace_hint(self.table_placed.find(p->gw->name), p->gw->name, p); } }
    LOG1("Finished table placement decisions " << pipe->name);
    return false;
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
        LOG3("    Keeping best " << best->name << " for reason: " << choice);
    } else {
        LOG3("    Updating best to " << t->name << " from " << best->name
             << " for reason: " << choice);
    }
}

IR::Node *TransformTables::postorder(IR::BFN::Pipe *pipe) {
    self.tblInfo.clear();
    self.tblByName.clear();
    self.seqInfo.clear();
    self.table_placed.clear();
    LOG3("table placement completed " << pipe->name);
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread));
    return pipe;
}

void TransformTables::table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *resources,
                                int entries) {
    tbl->resources = resources;
    tbl->layout.entries = entries;
    if (!tbl->ways.empty()) {
        BUG_CHECK(errorCount() > 0 || resources->memuse.count(tbl->unique_id()),
                  "Missing resources for %s", tbl);
        if (!tbl->layout.atcam && resources->memuse.count(tbl->unique_id())) {
            auto &mem = resources->memuse.at(tbl->unique_id());
            // mismatch between tbl->ways and mem.ways is an error, but is diagnosed elsewhere
            // and we don't want to crash here.
            unsigned i = 0;
            for (auto &w : tbl->ways) {
                if (i < mem.ways.size())
                    w.entries = mem.ways[i++].size * 1024 * w.match_groups;
                else
                    w.entries = 0;
            }
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
IR::MAU::Table *TransformTables::break_up_atcam(IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed,
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
        table_part->set_global_id(placed->logical_id + lt);
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
IR::Vector<IR::MAU::Table> *TransformTables::break_up_dleft(IR::MAU::Table *tbl,
    const TablePlacement::Placed *placed, int stage_table) {
    auto dleft_vector = new IR::Vector<IR::MAU::Table>();
    int logical_tables = placed->use.preferred()->logical_tables();
    BUG_CHECK(stage_table == placed->stage_split, "mismatched stage table id");

    for (int lt = 0; lt < logical_tables; lt++) {
        auto *table_part = tbl->clone();

        if (lt != 0)
            table_part->remove_gateway();
        table_part->set_global_id(placed->logical_id + lt);
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
        if (ba->attached->direct || placed->attached_entries.at(ba->attached).entries == 0)
            continue;
        if (auto *ena = att_info.split_enable(ba->attached)) {
            tbl->gateway_rows.emplace_back(
                new IR::Equ(ena, new IR::Constant(1)), cstring());
            tbl->gateway_cond = ena->toString();
        }
    }
}


/**
 * When merging a match table and a gateway, the next map of these tables have to be merged.
 * Consider the following example, where the condition will be merged with table t2:
 *
 *    if (cond) {
 *        t1.apply();
 *        t2.apply();
 *        t3.apply();
 *    }
 *
 * The original IR graph would look something like:
 *
 * cond
 *   |
 *   | $true
 *   |
 * [ t1, t2, t3 ] 
 *
 * Now after the merge, the IR graph would look like:
 *
 *  cond
 *   t2
 *   |
 *   | $default
 *   |
 * [ t1, t3 ]
 *
 * In this case, when the condition cond is true, the gateway will then run the table t2.
 *
 * Now another example:
 *
 *     if (cond) {
 *         t1.apply();
 *         t2.apply();
 *         t3.apply();
 *     } else {
 *         t4.apply();
 *     }
 *              cond
 *              / \
 *       $true /   \ $false
 *            /     \
 * [ t1, t2, t3 ]    [ t4 ]
 *
 * After the linkage:
 *
 *              cond
 *              t2
 *              / \
 *    $default /   \ $false
 *            /     \
 * [ t1, t3 ]       [ t4 ]
 *
 * A $default path is added for the replacement branch, as the $true branch is removed from
 * the gateway rows, instead representing to run table.
 *
 * Now this gets a bit trickier if the merged table has control flow off of it as well.  Say t2
 * is an action chain, e.g.:
 *
 *    if (cond) {
 *        t1.apply();
 *        switch (t2.apply().action_run()) {
 *            a1 : { t2_a1.apply(); }
 *        }
 *        t3.apply();
 *    }
 *
 * Original IR graph:
 *
 * cond
 *   |
 *   | $true
 *   |
 * [ t1, t2, t3 ]
 *       |
 *       | a1 
 *       |
 *     [ t2_al ] 
 *
 * Post merge:
 *              cond
 *              t2
 *              / \
 *    $default /   \ a1 
 *            /     \
 * [ t1, t3 ]       [ t2_a1, t1, t3 ]
 *
 * A default pathway has been added, and to all pathways, the tables on the same sequence are
 * added.  If t2 had a default pathway already, then, simply t1 and t3 would have been added to
 * the next table graph.
 *
 * Last corner case is instead of an action chain, the table is a hit or miss:
 *
 *    if (cond) {
 *        t1.apply();
 *        if (t2.apply().miss) {
 *            t2_miss.apply();
 *        }
 *        t3.apply();
 *    }
 *
 * Original IR graph:
 *
 * cond
 *   |
 *   | $true
 *   |
 * [ t1, t2, t3 ]
 *       |
 *       | $miss 
 *       |
 *     [ t2_miss ] 
 *
 * Now, a $default pathway cannot be added to a hit miss table, currently in the IR.  Thus instead
 * the IR will be transformed to:
 *
 *              cond
 *              t2
 *              / \
 *        $hit /   \ $miss 
 *            /     \
 * [ t1, t3 ]       [ t2_miss, t1, t3 ]
 *
 * This ensure that the tables t1 and t3 are run on both pathways.
 */
void TransformTables::merge_match_and_gateway(IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed, IR::MAU::Table::Layout &gw_layout) {
    auto match = placed->table;
    BUG_CHECK(match && tbl->conditional_gateway_only() && !match->uses_gateway(),
        "Table IR is not set up in the preorder");
    LOG3("folding gateway " << tbl->name << " onto " << match->name);

    tbl->gateway_name = tbl->name;
    tbl->name = match->name;
    tbl->srcInfo = match->srcInfo;
    for (auto &gw : tbl->gateway_rows)
        if (gw.second == placed->gw_result_tag)
            gw.second = cstring();

    // Clone IR Information
    tbl->match_table = match->match_table;
    tbl->match_key = match->match_key;
    tbl->actions = match->actions;
    tbl->attached = match->attached;
    tbl->entries_list = match->entries_list;

    // Generate the correct table layout from the options
    gw_layout = tbl->layout;

    // Remove the conditional sequence under the branch
    auto *seq = tbl->next.at(placed->gw_result_tag)->clone();
    tbl->next.erase(placed->gw_result_tag);
    if (seq->tables.size() != 1) {
        bool found = false;
        for (auto it = seq->tables.begin(); it != seq->tables.end(); it++) {
            if (*it == match) {
                seq->tables.erase(it);
                found = true;
                break;
            }
        }
        BUG_CHECK(found, "failed to find match table");
    } else {
        BUG_CHECK(seq->tables[0] == match, "Only a single match table in the problem");
        seq = 0;
    }

    // Add all of the tables in the same sequence (i.e. t1 and t3) to all of the branches
    for (auto &next : match->next) {
        BUG_CHECK(tbl->next.count(next.first) == 0, "Added to another table");
        if (seq) {
            auto *new_next = next.second->clone();
            for (auto t : seq->tables)
                new_next->tables.push_back(t);
            tbl->next[next.first] = new_next;
        } else {
            tbl->next[next.first] = next.second;
        }
    }

    // Create the missing $hit, $miss, or $default branch if the program does not have it
    if (match->hit_miss_p4()) {
        if (match->next.count("$hit") == 0 && seq)
            tbl->next["$hit"] = seq;
        if (match->next.count("$miss") == 0 && seq)
            tbl->next["$miss"] = seq;
    } else if (!match->has_default_path() && seq) {
        tbl->next["$default"] = seq;
    }

    for (auto &gw : tbl->gateway_rows)
        if (gw.second && !tbl->next.count(gw.second))
            tbl->next[gw.second] = new IR::MAU::TableSeq();
}

IR::Node *TransformTables::preorder(IR::MAU::Table *tbl) {
    auto it = self.table_placed.find(tbl->name);
    if (it == self.table_placed.end()) {
        BUG_CHECK(errorCount() > 0, "Trying to place a table %s that was never placed", tbl->name);
        return tbl; }
    if (tbl->is_placed())
        return tbl;
    // FIXME: Currently the gateway is laid out for every table, so I'm keeping the information
    // in split tables.  In the future, there should be no gw_layout for split tables
    IR::MAU::Table::Layout gw_layout;
    bool gw_only = true;
    bool gw_layout_used = false;

    if (it->second->use.preferred() &&
        it->second->use.preferred()->layout.hash_action &&
        it->second->use.preferred()->layout.gateway) {
        tbl = self.lc.fpc.convert_to_gateway(tbl);
        gw_only = false;
    } else if (it->second->gw && it->second->gw->name == tbl->name) {
        /* fold gateway and match table together */
        merge_match_and_gateway(tbl, it->second, gw_layout);
        gw_only = false;
        gw_layout_used = true;
    } else if (it->second->table->match_table) {
        gw_only = false;
    }

    if (tbl->is_always_run_action())
        tbl->stage_ = it->second->stage;
    else
        tbl->set_global_id(it->second->logical_id);

    if (self.table_placed.count(tbl->name) == 1) {
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
    int prev_entries = 0;
    bool reduction_or = false;  // need reduction_or on post-split actions
    IR::Vector<IR::MAU::Table> *rv = new IR::Vector<IR::MAU::Table>;
    IR::MAU::Table *prev = 0;
    IR::MAU::Table *atcam_last = nullptr;
    /* split the table into multiple parts per the placement */
    LOG1("splitting " << tbl->name << " across " << self.table_placed.count(tbl->name)
         << " stages");
    int deferred_attached = 0;
    for (auto *att : tbl->attached) {
        if (att->attached->direct) continue;
        if (!it->second->attached_entries.at(att->attached).need_more) continue;
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
    for (const TablePlacement::Placed *pl : ValuesForKey(self.table_placed, tbl->name)) {
        auto *table_part = tbl->clone();
        // When a gateway is merged against a split table, only the first table created from the
        // split has the merged gateway
        if (!rv->empty())
            table_part->remove_gateway();

        if (stage_table != 0) {
            BUG_CHECK(!rv->empty(), "failed to attach first stage table");
            BUG_CHECK(stage_table == pl->stage_split, "Splitting table %s on stage %d cannot be "
                      "resolved for stage table %d", table_part->name, pl->stage, stage_table); }
        select_layout_option(table_part, pl->use.preferred());
        add_attached_tables(table_part, pl->use.preferred(), &pl->resources);
        if (gw_layout_used)
            table_part->layout += gw_layout;
        table_part->set_global_id(pl->logical_id);
        table_part->stage_split = pl->stage_split;
        TableResourceAlloc *rsrcs = nullptr;

        if (pl->entries) {
            if (deferred_attached) {
                if (pl->use.format_type != ActionData::PRE_SPLIT_ATTACHED)
                    error("Couldn't find a usable split format for %1% and couldn't place it "
                          "without splitting", tbl);
                for (auto act = table_part->actions.begin(); act != table_part->actions.end();) {
                    if ((act->second = self.att_info.create_pre_split_action(act->second,
                                                                        table_part, &self.phv)))
                        ++act;
                    else
                        act = table_part->actions.erase(act); }
                erase_if(table_part->attached, [pl](const IR::MAU::BackendAttached *ba) {
                    return pl->attached_entries.count(ba->attached) &&
                           pl->attached_entries.at(ba->attached).entries == 0; }); }
            if (table_part->layout.atcam) {
                table_part = break_up_atcam(table_part, pl, pl->stage_split, &atcam_last);
            } else {
                rsrcs = pl->resources.clone()->rename(tbl, pl->stage_split);
                table_set_resources(table_part, rsrcs, pl->entries);
            }
        } else {
            if (pl->use.format_type != ActionData::POST_SPLIT_ATTACHED)
                error("Couldn't find a usable split format for %1% and couldn't place it "
                      "without splitting", tbl);
            else
                BUG_CHECK(deferred_attached, "Split match from attached with no attached?");
            for (auto act = table_part->actions.begin(); act != table_part->actions.end();) {
                if ((act->second = self.att_info.create_post_split_action(act->second, table_part,
                                                                          reduction_or)))
                    ++act;
                else
                    act = table_part->actions.erase(act); }
            rsrcs = pl->resources.clone()->rename(tbl, pl->stage_split);
            table_set_resources(table_part, rsrcs, pl->entries);
            table_part->match_key.clear();
            table_part->next.clear();
            table_part->suppress_context_json = true;
            self.setup_detached_gateway(table_part, pl);
            if (table_part->actions.size() != 1)
                P4C_UNIMPLEMENTED("split attached table with multiple actions");
            erase_if(table_part->attached, [pl](const IR::MAU::BackendAttached *ba) {
                return !pl->attached_entries.count(ba->attached) ||
                       pl->attached_entries.at(ba->attached).entries == 0; });
            for (size_t i = 0; i < table_part->attached.size(); i++) {
                auto ba_clone = new IR::MAU::BackendAttached(*(table_part->attached.at(i)));
                // This needs to be reset, as the backend attached is initialized as DEFAULT
                if (ba_clone->attached->is<IR::MAU::Counter>() ||
                    ba_clone->attached->is<IR::MAU::Meter>() ||
                    ba_clone->attached->is<IR::MAU::StatefulAlu>()) {
                    ba_clone->pfe_location = IR::MAU::PfeLocation::DEFAULT;
                    if (!ba_clone->attached->is<IR::MAU::Counter>())
                        ba_clone->type_location = IR::MAU::TypeLocation::DEFAULT;
                }
                table_part->attached.at(i) = ba_clone;
            }

            BUG_CHECK(!rv->empty(), "first stage has no match entries?");
            rv->push_back(table_part);
            reduction_or = true; }

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

        // check for any attached tables not completely placed as of this stage and do any
        // address updates needed for later stages.
        for (auto &ba : table_part->attached) {
            auto *att = ba->attached;
            if (att->direct) continue;
            if (pl->attached_entries.at(att).entries == 0) continue;
            if (pl->attached_entries.at(att).need_more) {
                if (Device::currentDevice() == Device::TOFINO) {
                    error("splitting %s across stages not supported on Tofino", att);
                } else {
                    for (auto &act : Values(table_part->actions)) {
                        if (act->stateful_call(att->name)) {
                            if (auto *idx = self.att_info.split_index(att)) {
                                auto *adj_idx = new IR::MAU::StatefulCounter(idx->type, att);
                                auto *set = new IR::MAU::Instruction("set", idx, adj_idx);
                                clone_update(act)->action.push_back(set); } } }
                    if (!ba->chain_vpn) {
                        // Need to chain the vpn to the next stage, which means we need to do
                        // the subword shift with meter_adr_shift and NOT with the hash_dist
                        for (auto &hdu : rsrcs->hash_dists) {
                            for (auto &alloc : hdu.ir_allocations) {
                                if (alloc.dest == IXBar::HD_METER_ADR) {
                                    BUG_CHECK(hdu.shift == 0, "Can't shift chained address in "
                                              "hash dist");
                                    break; } } }
                        clone_update(ba)->chain_vpn = true; } } } }

        stage_table++;
        prev = table_part;
        if (atcam_last)
            prev = atcam_last;
        prev_entries += pl->entries;
    }
    assert(!rv->empty());
    return rv;
}

IR::Node *TransformTables::preorder(IR::MAU::BackendAttached *ba) {
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

IR::Node *TransformTables::preorder(IR::MAU::TableSeq *seq) {
    // Inserting the starter pistol tables
    if (findContext<IR::MAU::Table>() == nullptr && seq->tables.size() > 0) {
        if (Device::currentDevice() == Device::TOFINO) {
            auto gress = seq->front()->gress;
            if (self.starter_pistol[gress] != nullptr) {
                seq->tables.push_back(self.starter_pistol[gress]);
            }
        }
    }
    return seq;
}

IR::Node *TransformTables::postorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() > 1) {
        std::stable_sort(seq->tables.begin(), seq->tables.end(),
            // Always Run Action will appear logically after all tables in its stage but before
            // all tables in subsequent stages
            [](const IR::MAU::Table *a, const IR::MAU::Table *b) -> bool {
                bool a_always_run = a->is_always_run_action();
                bool b_always_run = b->is_always_run_action();
                if (!a_always_run && !b_always_run) {
                    auto a_id = a->global_id();
                    auto b_id = b->global_id();
                    return a_id ? b_id ? *a_id < *b_id : true : false; }
                if (a->stage() != b->stage())
                    return a->stage() < b->stage();
                if (!a_always_run || !b_always_run)
                    return !a_always_run;
                return a->name < b->name;
        });
    }
    seq->deps.clear();  // FIXME -- not needed/valid?  perhaps set to all 1s?
    return seq;
}

/**
 * The goal of this pass is to merge all of the pre table-placement always run objects into a
 * single IR::MAU::Table.  Each always run action during table placement is placed
 * separately, however in the hardware, the action is a single IR::MAU::Action, and thus
 * must be merged together.
 *
 * The idea behind this is that if each always run action is indeed always run, then this table
 * must appear on every single IR pathway while honoring the IR rules of topological order.
 * Thus, by replacing a single always run table per stage and per gress will indeed place the
 * merged always run action in a legal place.  This is essentially what this pass does.
 *
 * The Scan pass is to find all always run action, and create a set of post table placement
 * tables that are merged per stage and gress.  The second step will find a single original
 * always run action per stage and gress, and replace it with this merged table.  All other
 * always run actions will be replaced with a nullptr.
 */
bool MergeAlwaysRunActions::Scan::preorder(const IR::MAU::Table *tbl) {
    if (tbl->is_always_run_action()) {
        AlwaysRunKey ark(tbl->stage(), tbl->gress);
        self.ar_tables_per_stage[ark].insert(tbl);
        LOG7("\t Merge Scan - ARA Table: " << tbl->name <<  "    Gress " << tbl->gress
             << "  phys stage:" << tbl->stage());
    }
    return true;
}

bool MergeAlwaysRunActions::Scan::preorder(const IR::MAU::Primitive *prim) {
    auto *tbl = findContext<IR::MAU::Table>();
    if (tbl != nullptr && tbl->is_always_run_action()) {
        for (uint32_t idx = 0; idx < prim->operands.size(); ++idx) {
            auto expr = prim->operands.at(idx);
            le_bitrange bits;
            PHV::Field* exp_f = self.self.phv.field(expr, &bits);
            if (!exp_f) continue;

            PHV::FieldSlice fslice = PHV::FieldSlice(exp_f, bits);

            if (idx != 0)
                self.read_fldSlice[tbl].insert(fslice);
            else
                self.written_fldSlice[tbl].insert(fslice);
        }

        LOG5("\tPrimitive " << *prim << "\n\t\t written slices: " << self.written_fldSlice <<
         "\n\t\t read slices: "  << self.read_fldSlice);
    }

    return true;
}

void MergeAlwaysRunActions::Scan::end_apply() {
    for (auto entry : self.ar_tables_per_stage) {
        const AlwaysRunKey& araKey = entry.first;
        auto& tables = entry.second;

        IR::MAU::Table *merged_table = new IR::MAU::Table(cstring(), araKey.gress);
        merged_table->stage_ = araKey.stage;
        merged_table->always_run = IR::MAU::AlwaysRun::ACTION;
        IR::MAU::Action *act = new IR::MAU::Action("$always_run_act");
        TableResourceAlloc *resources = new TableResourceAlloc();
        int ar_row = Device::alwaysRunIMemAddr() / 2;
        int ar_color = Device::alwaysRunIMemAddr() % 2;
        InstructionMemory::Use::VLIW_Instruction single_instr(bitvec(), ar_row, ar_color);
        resources->instr_mem.all_instrs.emplace("$always_run", single_instr);
        std::set<int> minDgStages;
        // Should really only be an Action and an instr_mem allocation
        for (auto tbl : tables) {
            LOG7("Physical stage for merge-scan table " << tbl->name << " : " << tbl->stage());
            BUG_CHECK(tbl->actions.size() == 1, "Always run tables can only have one action");
            const IR::MAU::Action *local_act = *(Values(tbl->actions).begin());
            for (auto instr : local_act->action)
                act->action.push_back(instr);
            resources->merge_instr(tbl->resources);
            for (auto stg : PhvInfo::minStage(tbl)) minDgStages.insert(stg);
        }

        auto tbl_to_replace = self.ar_replacement(araKey.stage, araKey.gress);
        merged_table->name = tbl_to_replace->name;
        merged_table->actions.emplace("$always_run_act", act);
        merged_table->resources = resources;
        self.merge_per_stage.emplace(araKey, merged_table);
        self.mergedARAwitNewStage = self.mergedARAwitNewStage || (minDgStages.size() > 1);
        self.merged_ar_minStages[araKey] = minDgStages;
        LOG7("\t Status of mergedARAwitNewStage:" << self.mergedARAwitNewStage);
    }
}

const IR::MAU::Table *MergeAlwaysRunActions::Update::preorder(IR::MAU::Table *tbl) {
    auto orig_tbl = getOriginal()->to<IR::MAU::Table>();
    if (!tbl->is_always_run_action())
        return tbl;
    AlwaysRunKey ark(tbl->stage(), tbl->gress);

    auto tbl_to_replace = self.ar_replacement(ark.stage, ark.gress);
    if (tbl_to_replace == orig_tbl) {
        return self.merge_per_stage.at(ark);
    } else {
        return nullptr;
    }
}

void MergeAlwaysRunActions::Update::end_apply() {
    // Print Fields involved in Always Run Actions
    for (auto pr : self.read_fldSlice) {
        LOG7("\t  Read slices for " << *(pr.first));
        for (auto sl : pr.second) {
            LOG7("\t\t" << *(sl.field()) << " num allocs: " << sl.field()->alloc_size());
        }
    }

    for (auto pr : self.written_fldSlice) {
        LOG7("\t  Written slices for " << *(pr.first));
        for (auto sl : pr.second) {
            LOG7("\t\t" << *(sl.field()) << " num allocs: " << sl.field()->alloc_size());
        }
    }

    // Update liveranges of AllocSlice's impacted by merged tables
    for (auto entry : self.ar_tables_per_stage) {
        const AlwaysRunKey& araKey = entry.first;
        auto& tables = entry.second;
        BUG_CHECK(self.merged_ar_minStages.count(araKey),
                  "No minStage info for ARA tables in stage %1% of gress %2%",
                  araKey.stage,
                  araKey.gress);

        LOG7("\t Merge Update - Phys stage (gress): " << araKey.stage
             << "(" << entry.first.gress << ") "
             << " #ARA tables: " << tables.size()
             << " #minStages:" << self.merged_ar_minStages[araKey].size());

        // Nothing to do if stage does not contain merged Always Run Action tables
        if (tables.size() <= 1)
            continue;

        // Nothing to do if merged tables have same minStage
        if (self.merged_ar_minStages.at(araKey).size() <= 1)
            continue;

        // Get table that will be replaced by merged table
        auto *merged_tbl = self.merge_per_stage.at(araKey);

        // Get max minStage of merged tables - This will be used as
        // the new minStage of the merged table
        int newStg = *(self.merged_ar_minStages.at(araKey).rbegin());

        std::stringstream ss;
        ss << "Merged tables: ";

        for (auto tbl : tables) {
            int oldStg = *(PhvInfo::minStage(tbl).begin());

            ss << tbl->externalName() << "  (stage:" << oldStg << ")  ";

            // If the minStage of the table has not changed there is nothing to do
            if (oldStg == newStg)
                continue;

            // Since (newStg != oldStg), we need to update all the affected AllocSlices
            // First look into the read slices
            for (auto fslice : self.read_fldSlice.at(tbl)) {
                PHV::Field *fld = const_cast<PHV::Field*>(fslice.field());
                le_bitrange rng = fslice.range();

                for (auto &alc_slice : fld->get_alloc()) {
                    if (!(alc_slice.field_slice().overlaps(rng)))
                        continue;

                    // The AlwaysRunAction table may be the last live stage of the slice or ...
                    if ((alc_slice.getLatestLiveness().first == oldStg) &&
                        (alc_slice.getLatestLiveness().second.isRead())) {
                        alc_slice.setLatestLiveness(
                            std::make_pair(newStg, alc_slice.getLatestLiveness().second));

                        LOG7("\tUpdate last stage from " << oldStg << " to " << newStg <<
                             " for read slice: " << alc_slice);
                        // Keep track of original slice LR END before merge
                        self.premergeLRend[&alc_slice][merged_tbl] = oldStg;
                    }
                }
            }

            // Then look into the written slices
            for (auto fslice : self.written_fldSlice.at(tbl)) {
                PHV::Field *fld = const_cast<PHV::Field*>(fslice.field());
                le_bitrange rng = fslice.range();

                for (auto &alc_slice : fld->get_alloc()) {
                    if (!(alc_slice.field_slice().overlaps(rng)))
                        continue;

                    // The AlwaysRunAction table may be the first live stage of the slice or ...
                    if ((alc_slice.getEarliestLiveness().first == oldStg) &&
                        (alc_slice.getEarliestLiveness().second.isWrite())) {
                        alc_slice.setEarliestLiveness(
                            std::make_pair(newStg, alc_slice.getEarliestLiveness().second));

                        LOG7("\tUpdate first stage from " << oldStg << " to " << newStg <<
                             " for written slice: " << alc_slice);
                        // Keep track of original slice LR START before merge
                        self.premergeLRstart[&alc_slice][merged_tbl] = oldStg;
                    }
                }
            }
        }

        ss << std::endl;
        LOG7(ss.str());
        PhvInfo::addMinStageEntry(merged_tbl, newStg, true);
    }

    LOG7("\t premergeLRend: ");
    for (auto slTblStg : self.premergeLRend) {
        LOG7("\t\t AllocSlice: " << slTblStg.first);
        for (auto tblStg : slTblStg.second) {
            LOG7("\t\t table " << tblStg.first->name << "  old LREnd stage: " << tblStg.second);
        }
    }

    LOG7("\t premergeLRstart: ");
    for (auto slTblStg : self.premergeLRstart) {
        LOG7("\t\t AllocSlice: " << slTblStg.first);
        for (auto tblStg : slTblStg.second) {
            LOG7("\t\t table " << tblStg.first->name << "  old LRStart stage: " << tblStg.second);
        }
    }

    // MinSTage status after updating slice liveranges and merged table minStage
    LOG7("MIN STAGE DEPARSER stage: " << self.self.phv.getDeparserStage());
    LOG7(PhvInfo::reportMinStages());
    LOG7("DG DEPARSER stage: " << (self.self.deps.max_min_stage + 1));
    LOG7(self.self.deps);
}

bool MergeAlwaysRunActions::UpdateAffectedTableMinStage::preorder(const IR::MAU::Table *tbl) {
    if (!PhvInfo::hasMinStageEntry(tbl) || !self.mergedARAwitNewStage)
        return false;

    revisit_visited();

    int oldMinStage = *(PhvInfo::minStage(tbl).begin());
    int newMinStage = self.self.deps.min_stage(tbl);

    tableMinStageShifts[tbl] = std::make_pair(oldMinStage, newMinStage);
    LOG4("\t\tMerge-affected table:" << tbl->name << " old minStage: " << oldMinStage <<
         " --> new minStage: " << newMinStage);
    return true;
}

// Go through IR Expression's to identify slices that need their liverange updated
// ---
bool MergeAlwaysRunActions::UpdateAffectedTableMinStage::preorder(const IR::Expression *t_expr) {
    if (!self.mergedARAwitNewStage)
        return false;

    auto *tbl = findContext<IR::MAU::Table>();
    if (tbl == nullptr) {
        LOG4("\t\t\t" << tableMinStageShifts.count(tbl) << " tables found for Expression "
             << *t_expr);
        return false;
    }
    bool is_write = isWrite();

    LOG4("  ---> Visiting "
         << (is_write ? "written" : "") <<" expr " << *t_expr);

    revisit_visited();

    LOG4("\t  - wrt table: " << tbl->name);

    // 1. Get field and bitrange
    le_bitrange bits;
    PHV::Field* exp_f = self.self.phv.field(t_expr, &bits);
    if (!exp_f) return true;

    LOG7("\t  - range " << bits << "  " << *exp_f);

    int oldStg = tableMinStageShifts.at(tbl).first;
    int newStg = tableMinStageShifts.at(tbl).second;
    auto deparsStg = PhvInfo::getDeparserStage();
    // PHV::FieldUse(PHV::FieldUse::WRITE));
    LOG7("\t  - oldStg " << oldStg);
    LOG7("\t  - newStg " << newStg);
    LOG7("\t  - oldDeparseStg " << deparsStg);

    // 2. Iterate over AllocSlices
    for (auto & sl : exp_f->get_alloc()) {
        if (!(sl.field_slice().overlaps(bits)))
            continue;

        bool modifyStart = false;
        bool modifyEnd = false;
        bool modifyDepars = false;
        bool singlePointLR = (sl.getEarliestLiveness() == sl.getLatestLiveness());
        int mergOldStg = oldStg;
        bool mergeAffectedSlice = false;
        bool no_tbl_LRstart_overlap = false;
        bool no_tbl_LRend_overlap = false;
        bool no_tbl_LR_overlap = false;

        LOG7("\t  - minLR " << sl.getEarliestLiveness());
        LOG7("\t  - maxLR " << sl.getLatestLiveness());

        // Check if AllocSlice LR has been affected by table merge
        PHV::StageAndAccess LRstart = sl.getEarliestLiveness();
        PHV::StageAndAccess LRend  = sl.getLatestLiveness();

        // Mark if slice's liverange is modified due to table merging;
        // if it is, update the slice liverange and the table old
        // stage to the pre-merge values (to avoid overlapping of the
        // liveranges of different allocated slices corresponding to
        // the same field slice.
        if (self.premergeLRstart.count(&sl)) {
            mergeAffectedSlice = true;
            if (self.premergeLRstart[&sl].count(tbl)) {
                LRstart.first = mergOldStg = self.premergeLRstart[&sl][tbl];
                LOG7("\t  - premerge LRstart oldStg " <<  mergOldStg);
            } else {
                no_tbl_LRstart_overlap = true;
            }
        }
        if (self.premergeLRend.count(&sl)) {
            mergeAffectedSlice = true;
            if (self.premergeLRend[&sl].count(tbl)) {
                LRend.first = mergOldStg =  self.premergeLRend[&sl][tbl];
                LOG7("\t  - premerge LRend oldStg " <<  mergOldStg);
            } else {
                no_tbl_LRend_overlap = true;
            }
        }

        // For allocated slices of field slices  that are not
        // originally accessed by merged tables set no_tbl_LR_overlap.
        // This helps bypass the liverange extension used to handle (non merged)
        // intermediate tables accessing field slices.
        if (!mergeAffectedSlice) {
            for (auto slTblStg : self.premergeLRstart) {
                if (slTblStg.second.count(tbl)) {
                    no_tbl_LR_overlap = true;
                }
            }
            for (auto slTblStg : self.premergeLRend) {
                if (slTblStg.second.count(tbl)) {
                    no_tbl_LR_overlap = true;
                }
            }
        }

        // Check first if maxStage is set to Deparser and mark for update
        // Then check if min/max stage matches oldStg and mark accordingly
        if ((deparsStg != (self.self.deps.max_min_stage + 1)) &&
            LRend.first == deparsStg &&
            (LRend.second.isWrite() || exp_f->deparsed())) {
            LOG7("\tUpdate last (deparser) stage from " << sl.getLatestLiveness() << " to " <<
                 (self.self.deps.max_min_stage+1) << " for slice: " << sl);
            modifyDepars = true;
        }

        if (!no_tbl_LR_overlap) {
            if (is_write) {
                if ((LRend.first == mergOldStg) &&
                    LRend.second.isWrite() &&
                    !tbl->is_always_run_action()) {
                    LOG7("\tUpdate last stage from " << mergOldStg << " to " << newStg <<
                         " for WRITTEN slice: " << sl);
                    modifyEnd = true;
                }

                if (singlePointLR && modifyEnd) {
                    LOG4("\tNot modifying LR start (same as end) for AllocSlice: " << sl);
                } else {
                    if (!no_tbl_LRstart_overlap &&
                        (LRstart.first == mergOldStg) &&
                        LRstart.second.isWrite()) {
                        LOG7("\tUpdate first stage from " << mergOldStg << " to " << newStg <<
                             " for WRITTEN slice: " << sl);
                        modifyStart = true;
                    }
                }

            } else {
                if (!no_tbl_LRend_overlap &&
                    (LRend.first == mergOldStg) &&
                    LRend.second.isRead()) {
                    LOG7("\tUpdate last stage from " << mergOldStg << " to " << newStg <<
                         " for  READ slice: " << sl);
                    modifyEnd = true;
                }

                if (singlePointLR && modifyEnd) {
                    LOG4("\tNot modifying LR start (same as end) for AllocSlice: " << sl);
                } else {
                    if ((LRstart.first == mergOldStg) &&
                        LRstart.second.isRead() &&
                        !tbl->is_always_run_action()) {
                        LOG7("\tUpdate first stage from " << mergOldStg << " to " << newStg <<
                             " for READ slice: " << sl);
                        modifyStart = true;
                    }
                }
            }
        }

        // Store liverange updates in order to apply all of them later
        auto sl_LR = std::make_pair(LRstart.first, LRend.first);
        auto sl_mod = std::make_pair(false, false);
        bool prvStart = false;
        bool prvEnd = false;

        if (sliceLRmodifies.count(&sl)) {
            sl_mod = sliceLRmodifies.at(&sl);

            if (sl_mod.first) {
                sl_LR.first = sliceLRshifts.at(&sl).first;
                prvStart = true;
            }
            if (sl_mod.second) {
                sl_LR.second = sliceLRshifts.at(&sl).second;
                prvEnd = true;
            }
        }

        if (modifyStart) {
            if (!prvStart) {
                sl_LR.first = newStg;
                sl_mod.first = true;
            } else if (sl_LR.first > newStg) {
                // extend LR if previous update was due to table
                // access in the middle of the LR
                sl_LR.first = newStg;
                sl_mod.first = true;
            }
        }

        if (modifyDepars) {
            sl_LR.second = (self.self.deps.max_min_stage + 1);
            sl_mod.second = true;
        } else if (modifyEnd) {
            if (!prvEnd) {
                sl_LR.second = newStg;
                sl_mod.second = true;
            } else if (sl_LR.second < newStg) {
                // extend LR if previous update was due to table
                // access in the middle of the LR
                sl_LR.second = newStg;
                sl_mod.second = true;
            }
        }

        sliceLRshifts[&sl] = sl_LR;
        sliceLRmodifies[&sl] = sl_mod;
        LOG7("   <--- Storing LR for " << sl << "  ===  [" << sl_LR.first << " : "
             << sl_LR.second << "]");
        LOG7("\t\t      mod: " <<  "  ===  [" << (sl_mod.first ? "vld" : " - ") <<
             " , " << (sl_mod.second ? "vld" : " - ") << "]");
    }  // for (auto & sl ...

    return false;
}

// Apply updates to table stages and slice liveranges
// ---
void MergeAlwaysRunActions::UpdateAffectedTableMinStage::end_apply() {
    if (!self.mergedARAwitNewStage)
        return;

    // Update the minStage of all tables affected by table merging
    // (stored in tableMinStageShifts)
    LOG4("\t Updating " << tableMinStageShifts.size() << " merge-affected tables:");

    for (auto entry : tableMinStageShifts) {
        int newStg = entry.second.second;

        PhvInfo::addMinStageEntry(entry.first, newStg, true);
    }

    // Update the liverange of all slices affected by table merging
    // (stored in sliceLRshifts)
    LOG4("\t Updating merge-affected slices:");

    for (auto entry : sliceLRshifts) {
        auto *sl = entry.first;

        LOG4("\t Modifying LR for slice " << *sl);

        sl->setLiveness(std::make_pair(entry.second.first, sl->getEarliestLiveness().second),
                        std::make_pair(entry.second.second, sl->getLatestLiveness().second));

        LOG4("\t\t ... to: " << sl->getEarliestLiveness() << " , " << sl->getLatestLiveness());
    }

    // Update the deparser-based liverange of slices not updated previously
    for (auto& fld : self.self.phv) {
        for (auto& sl : fld.get_alloc()) {
            if (sl.getLatestLiveness().first == self.self.phv.getDeparserStage()) {
                if (sliceLRshifts.count(&sl)) {
                    LOG5("\t WARNING: Modified LR still has old deparser LR stage for slice: " <<
                         sl);
                }
                sl.setLatestLiveness(
                    std::make_pair((self.self.deps.max_min_stage + 1),
                                   sl.getLatestLiveness().second));
            }
        }
    }

    // Update the deparser stage in minStages
    self.self.phv.setDeparserStage(self.self.deps.max_min_stage + 1);

    LOG7("MIN STAGE DEPARSER stage: " << self.self.phv.getDeparserStage());
    LOG7(PhvInfo::reportMinStages());
    LOG7("DG DEPARSER stage: " << (self.self.deps.max_min_stage + 1));
    LOG7(self.self.deps);
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

void dump(const ordered_set<const DecidePlacement::GroupPlace *> &work) {
    std::cout << work << std::endl; }

TablePlacement::TablePlacement(const BFN_Options &opt, DependencyGraph &d,
                               const TablesMutuallyExclusive &m, PhvInfo &p,
                               LayoutChoices &l, const SharedIndirectAttachedAnalysis &s,
                               SplitAttachedInfo &sia, TableSummary &summary_)
    : options(opt), deps(d), mutex(m), phv(p), lc(l), siaa(s),
      ddm(ntp, con_paths, d), att_info(sia), summary(summary_) {
     addPasses({
         &ntp,
         &con_paths,
         new SetupInfo(*this),
         new DecidePlacement(*this),
         new TransformTables(*this)
         // new MergeAlwaysRunActions(*this)
     });
}
