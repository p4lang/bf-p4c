#include <algorithm>
#include <list>
#include "ir/ir.h"
#include "resource_estimate.h"
#include "input_xbar.h"
#include "memories.h"
#include "resource.h"
#include "table_dependency_graph.h"
#include "table_mutex.h"
#include "table_placement.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/log.h"
#include "lib/set.h"
#include "field_use.h"
#include "tofino/ir/table_tree.h"
#include "tofino/phv/phv_fields.h"

TablePlacement::TablePlacement(const DependencyGraph &d, const TablesMutuallyExclusive &m,
                               const PhvInfo &p)
: deps(d), mutex(m), phv(p) {}

Visitor::profile_t TablePlacement::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    return MauTransform::init_apply(root);
}

struct TablePlacement::TableInfo {
    int uid = -1;
    const IR::MAU::TableSeq     *parent;
    bitvec                      tables;  // this table and all tables control dependent on it
};
struct TablePlacement::TableSeqInfo {
    bool        root = false;
    int         uid = -1;
    bitvec      tables;  // the tables in the seqence and their control dependent children
    ordered_set<const IR::MAU::Table *> refs;
};

class TablePlacement::SetupInfo : public Inspector {
    TablePlacement &self;
    bool preorder(const IR::MAU::Table *tbl) override {
        BUG_CHECK(!self.tblInfo.count(tbl), "Table in both ingress and egress?");
        auto &info = self.tblInfo[tbl];
        info.uid = self.tblInfo.size() - 1;
        info.parent = getParent<IR::MAU::TableSeq>();
        BUG_CHECK(info.parent, "parent of Table is not TableSeq");
        return true; }
    void revisit(const IR::MAU::Table *) override {
        BUG("Table appears twice"); }
    void postorder(const IR::MAU::Table *tbl) override {
        auto &info = self.tblInfo.at(tbl);
        info.tables[info.uid] = 1;
        for (auto &n : tbl->next)
            info.tables |= self.seqInfo.at(n.second).tables; }
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
    bool preorder(const IR::ActionFunction *) override { return false; }
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::V1Table *) override { return false; }

 public:
    explicit SetupInfo(TablePlacement &self) : self(self) {}
};

struct TablePlacement::GroupPlace {
    /* tracking the placement of a group of tables from an IR::MAU::TableSeq
     *   parents    groups that must wait until this group is fully placed before any more
     *              tables from them may be placed (so next_table setup works)
     *   ancestors  union of parents and all parent's ancestors
     *   seq        the TableSeq being placed for this group */
    ordered_set<const GroupPlace *>     parents, ancestors;
    const IR::MAU::TableSeq             *seq;
    const TablePlacement::TableSeqInfo  &info;
    int                                 depth;  // just for debugging?
    GroupPlace(const TablePlacement &self, ordered_set<const GroupPlace*> &work,
               const ordered_set<const GroupPlace *> &par, const IR::MAU::TableSeq *s)
    : parents(par), ancestors(par), seq(s), info(self.seqInfo.at(s)), depth(1) {
        for (auto p : parents) {
            if (depth <= p->depth)
                depth = p->depth+1;
            ancestors |= p->ancestors; }
        LOG4("new seq " << s->id << " depth=" << depth << " anc=" << ancestors);
        work.insert(this);
        work -= ancestors; }
    void finish(ordered_set<const GroupPlace*> &work) const {
        work.erase(this);
        for (auto p : parents)
            work.insert(p); }
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
    const Placed                *prev = 0;
    const GroupPlace            *group = 0;  // work group chosen from
    cstring                     name;
    int                         entries = 0;
    bitvec                      placed;  // fully placed tables after this placement
    bool                        need_more = false;
    cstring                     gw_result_tag;
    const IR::MAU::Table        *table, *gw = 0;
    int                         stage, logical_id;
    StageUseEstimate            use;
    const TableResourceAlloc    *resources;
    Placed(TablePlacement &self, const IR::MAU::Table *t)
        : self(self), table(t) {
        if (t) { name = t->name; }
    }

    // test if this table is placed
    bool is_placed(const IR::MAU::Table *tbl) const {
        return placed[self.tblInfo.at(tbl).uid]; }
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
    void copy(const Placed *p) {
        name = p->name; entries = p->entries; placed = p->placed;
        need_more = p->need_more; gw_result_tag = p->gw_result_tag; table = p->table;
        gw = p->gw; stage = p->stage; logical_id = p->logical_id; use = p->use;
    }

    TablePlacement::Placed *gateway_merge();
    void set_prev(const Placed *p, bool make_new, vector<TableResourceAlloc *> &prev_resources) {
        if (!make_new) {
            prev = p;
            if (p) {
                placed = p->placed;
            }
        } else {
            int stage = -1;
            int index = 0;
            if (p) {
               placed = p->placed;
               stage = p->stage;
            }
            auto *curr_p = this;
            auto *prev_p = p;
            while (stage != -1) {
                auto *new_p = new Placed(*prev_p);
                new_p->resources = prev_resources[index];
                index++;
                curr_p->prev = new_p;
                curr_p = new_p;
                prev_p = prev_p->prev;
                if (prev_p == nullptr || prev_p->stage != curr_p->stage) {
                    curr_p->prev = prev_p;
                    stage = -1;
                }
            }
        }
    }
    friend std::ostream &operator<<(std::ostream &out, const TablePlacement::Placed *pl) {
        out << pl->name;
        return out; }
};

void TablePlacement::GroupPlace::finish_if_placed(
    ordered_set<const GroupPlace*> &work, const Placed *pl
) const {
    if (pl->is_fully_placed(seq)) {
        LOG4("Finished a sequence (" << seq->id << ")");
        finish(work);
        for (auto p : parents)
            p->finish_if_placed(work, pl);
    } else {
        LOG4("seq " << seq->id << " not finished"); }
}

static StageUseEstimate get_current_stage_use(const TablePlacement::Placed *pl) {
    int                 stage;
    StageUseEstimate    rv;
    if (pl) {
        stage = pl->stage;
        rv = pl->use;
        for (pl = pl->prev; pl && pl->stage == stage; pl = pl->prev)
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

TablePlacement::Placed *TablePlacement::Placed::gateway_merge() {
    if (gw || !table->uses_gateway() || table->match_table) {
        return this;
    }
    /* table is just a gateway -- look for a dependent match table to combine with */
    cstring result_tag;
    const IR::MAU::Table *match = 0;
    for (auto it = table->next.rbegin(); it != table->next.rend(); it++) {
        if (self.seqInfo.at(it->second).refs.size() > 1)
            continue;
        int idx = -1;
        for (auto t : it->second->tables) {
            ++idx;
            if (it->second->deps[idx]) continue;
            if (t->uses_gateway()) continue;
            match = t;
            result_tag = it->first;
            break; }
        if (match) break; }
    if (match) {
        LOG2(" - making " << name << " gateway on " << match->name);
        name = match->name;
        gw = table;
        table = match;
        gw_result_tag = result_tag; }
    return this;
}

static bool try_alloc_ixbar(TablePlacement::Placed *next, const TablePlacement::Placed *done,
                            const PhvInfo &phv, StageUseEstimate &sue,
                            TableResourceAlloc *resources) {
    resources->match_ixbar.clear();
    resources->gateway_ixbar.clear();
    resources->selector_ixbar.clear();
    IXBar current_ixbar;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        current_ixbar.update(p->name, p->resources->match_ixbar);
        current_ixbar.update(p->name + "$gw", p->resources->gateway_ixbar);
        const IR::ActionSelector *as;
        for (auto *at : p->table->attached) {
            if ((as = at->to<IR::ActionSelector>()) != nullptr
                && !p->resources->selector_ixbar.use.empty()) {
                current_ixbar.update(p->name + "$selector", p->resources->selector_ixbar);
                current_ixbar.selectors.emplace(as);
            }
        }
    }
    if (!current_ixbar.allocTable(next->table, phv, resources->match_ixbar,
                                  resources->gateway_ixbar, resources->selector_ixbar,
                                  sue.preferred()) ||
        !current_ixbar.allocTable(next->gw, phv, resources->match_ixbar,
                                  resources->gateway_ixbar, resources->selector_ixbar,
                                  sue.preferred())) {
        resources->match_ixbar.clear();
        resources->gateway_ixbar.clear();
        resources->selector_ixbar.clear();
        return false; }
    return true;
}

static bool try_alloc_mem(TablePlacement::Placed *next, const TablePlacement::Placed *done,
                          int &entries, TableResourceAlloc *resources, StageUseEstimate &sue,
                          vector<TableResourceAlloc *> &prev_resources) {
    Memories current_mem;
    int i = 0;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
         current_mem.add_table(p->table, p->gw, prev_resources[i], p->use.preferred(),
                               p->entries);
         i++;
    }
    current_mem.add_table(next->table, next->gw, resources, sue.preferred(), entries);
    resources->memuse.clear();
    for (auto *prev_resource : prev_resources) {
        prev_resource->memuse.clear();
    }
    if (!current_mem.allocate_all()) {
        resources->memuse.clear();
        for (auto *prev_resource : prev_resources) {
            prev_resource->memuse.clear();
        }
        return false;
    }
    return true;
}

static void coord_selector_xbar(const TablePlacement::Placed *curr,
                                const TablePlacement::Placed *done,
                                TableResourceAlloc *resource,
                                vector<TableResourceAlloc *> &prev_resources) {
    const IR::ActionSelector *as = nullptr;
    for (auto at : curr->table->attached) {
        if ((as = at->to<IR::ActionSelector>()) != nullptr) break;
    }
    if (as == nullptr) return;
    auto loc = resource->memuse.find(curr->table->name + "$selector");
    if (loc == resource->memuse.end() || (loc != resource->memuse.end()
        && !resource->selector_ixbar.use.empty()))
        return;
    int j = 0;
    for (auto *p = done; p && p->stage == curr->stage; p = p->prev) {
        const IR::ActionSelector *p_as = nullptr;
        if (p == curr) {
            j++;
            continue;
        }
        for (auto at : p->table->attached) {
            if ((p_as = at->to<IR::ActionSelector>()) != nullptr)
                break;
        }
        if (p_as == as && !p->resources->selector_ixbar.use.empty()) {
            resource->selector_ixbar = prev_resources[j]->selector_ixbar;
            prev_resources[j]->selector_ixbar.clear();
            break;
        }
        j++;
    }
}

TablePlacement::Placed *TablePlacement::try_place_table(const IR::MAU::Table *t, const Placed *done,
                                                        const StageUseEstimate &current) {
    LOG1("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    auto *rv = (new Placed(*this, t))->gateway_merge();
    TableResourceAlloc *resources = new TableResourceAlloc;
    TableResourceAlloc *min_resources = new TableResourceAlloc;
    rv->resources = resources;
    vector<TableResourceAlloc *> prev_resources;
    for (auto *p = done; p && p->stage == done->stage; p = p->prev) {
        prev_resources.push_back(p->resources->clone_ixbar());
    }
    t = rv->table;
    rv->stage = done ? done->stage : 0;
    int min_entries = 1;
    int set_entries = 512;
    if (t->match_table) {
        if (t->match_table->size)
            set_entries = t->match_table->size;
        else if (t->match_table->min_size)
            set_entries = t->match_table->min_size; }
    auto &rvdeps = deps.graph.at(rv->name);
    bool prev_placed = false;  bool has_action_data = false;
    for (auto *p = done; p; p = p->prev) {
        if (p->name == rv->name) {
            prev_placed = true;
            has_action_data = p->use.preferred()->layout->action_data_required();
            if (p->need_more == false) {
                LOG2(" - can't place as its already done");
                return nullptr; }
            set_entries -= p->entries;
        } else if (p->stage == rv->stage && rvdeps.data_dep.count(p->name) &&
                   rvdeps.data_dep.at(p->name) >= DependencyGraph::Table::ACTION) {
            rv->stage++; } }
    assert(!rv->placed[tblInfo.at(rv->table).uid]);

    StageUseEstimate min_use(t, min_entries, prev_placed, has_action_data);
    StageUseEstimate stage_current = current;
    if (done && rv->stage != done->stage)
        stage_current.clear();

    bool allocated = false;
    bool ixbar_allocation_bug = false;
    bool mem_allocation_bug = false;
    int furthest_stage = (done == nullptr) ? 0 : done->stage + 1;

    /* Loop to find the right size of entries for a table to place into stage */
    do {
        rv->entries = set_entries;
        auto avail = StageUseEstimate::max();
        bool advance_to_next_stage = false;
        allocated = false; ixbar_allocation_bug = false; mem_allocation_bug = false;
        rv->use = StageUseEstimate(t, rv->entries, prev_placed, has_action_data);

        if (!try_alloc_ixbar(rv, done, phv, min_use, min_resources)) {
            advance_to_next_stage = true;
            ixbar_allocation_bug = true;
            LOG3("Min Use ixbar allocation did not fit");
        }

        if (!try_alloc_ixbar(rv, done, phv, rv->use, resources)) {
            advance_to_next_stage = true;
            ixbar_allocation_bug = true;
            LOG3("Table Use ixbar allocation did not fit");
        }

        if (!advance_to_next_stage && (!( min_use + stage_current <= avail)
            || !try_alloc_mem(rv, done, min_entries, min_resources, min_use, prev_resources))) {
            mem_allocation_bug = true;
            advance_to_next_stage = true;
            LOG3("Min use of memory allocation did not fit");
        }

        if (done && rv->stage == done->stage) {
            avail.srams -= stage_current.srams;
            avail.tcams -= stage_current.tcams;
            avail.maprams -= stage_current.maprams; }

        int srams_left = avail.srams;
        int tcams_left = avail.tcams;
        while (!advance_to_next_stage &&
               (!(rv->use <= avail) ||
               (allocated = try_alloc_mem(rv, done, rv->entries, resources,
                                          rv->use, prev_resources)) == false)) {
            rv->need_more = true;
            if (!t->layout.ternary)
                rv->use.calculate_for_leftover_srams(t, srams_left, rv->entries);
            else
                rv->use.calculate_for_leftover_tcams(t, tcams_left, srams_left, rv->entries);

            if (rv->entries < min_entries) {
                mem_allocation_bug = true;
                advance_to_next_stage = true;
                ERROR("Couldn't place mininum entries within a table");
                break;
            }
            if (!t->layout.ternary)
                srams_left--;
            else
                tcams_left--;

            LOG3(" - reducing to " << rv->entries << " of " << t->name
                 << " in stage " << rv->stage);
            if (!try_alloc_ixbar(rv, done, phv, rv->use, resources)) {
                ixbar_allocation_bug = true;
                ERROR("IXBar Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }
        }
        if (advance_to_next_stage) {
            rv->stage++;
            stage_current.clear();
        }
    } while (!allocated && rv->stage <= furthest_stage);

    // FIXME: for a particular test case, adding more entries actually filled in the table better
    if (rv->need_more && rv->entries > set_entries)
        rv->need_more = false;

    if (rv->stage > furthest_stage) {
        if (ixbar_allocation_bug)
            BUG("Can't fit table %s in input xbar by itself", rv->name);
        if (mem_allocation_bug)
            BUG("Can't fit the minimum number of table %s entries within the memories", rv->name);
        BUG("Unknown error for stage advancement?");
    }

    rv->logical_id = done && done->stage == rv->stage ? done->logical_id + 1
                                                      : rv->stage * StageUse::MAX_LOGICAL_IDS;
    assert((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage);
    LOG2("try_place_table returning " << rv->entries << " of " << rv->name <<
         " in stage " << rv->stage << (rv->need_more ? " (need more)" : ""));
    int i = 0;
    for (auto *p = done; p && p->stage == rv->stage; p = p->prev) {
        coord_selector_xbar(p, done, prev_resources[i], prev_resources);
        i++;
    }
    coord_selector_xbar(rv, done, resources, prev_resources);
    if (done && rv->stage == done->stage) {
        rv->set_prev(done, true, prev_resources);
    } else {
        rv->set_prev(done, false, prev_resources);
    }

    if (!rv->need_more) {
        rv->placed[tblInfo.at(rv->table).uid] = true;
        if (rv->gw)
            rv->placed[tblInfo.at(rv->gw).uid] = true; }
    /* FIXME -- need to redo IXBar alloc if we moved to the next stage?  Or if we need less
     * hash indexing bits for smaller ways? */
    return rv;
}

const TablePlacement::Placed *
TablePlacement::place_table(ordered_set<const GroupPlace *>&work, const Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " <<
         pl->stage << (pl->need_more ? " (need more)" : ""));
    if (!pl->need_more) {
        pl->group->finish_if_placed(work, pl);
        GroupPlace *gw_match_grp = nullptr;
        if (pl->gw)  {
            bool found_match = false;
            for (auto n : Values(pl->gw->next)) {
                if (!n || n->tables.size() == 0) continue;
                if (GroupPlace::in_work(work, n)) continue;
                bool ready = true;
                ordered_set<const GroupPlace *> parents;
                for (auto tbl : seqInfo.at(n).refs) {
                    if (pl->is_placed(tbl)) {
                        parents.insert(pl->find_group(tbl));
                    } else {
                        ready = false;
                        break; } }
                if (n->tables.size() == 1 && n->tables.at(0) == pl->table) {
                    assert(!found_match && !gw_match_grp);
                    BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                              "multi-referenced table");
                    found_match = true;
                    continue; }
                GroupPlace *g = ready ? new GroupPlace(*this, work, parents, n) : nullptr;
                for (auto t : n->tables) {
                    if (t == pl->table) {
                        assert(!found_match && !gw_match_grp);
                        BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                                  "multi-referenced table");
                        found_match = true;
                        gw_match_grp = g; } } }
            assert(found_match); }
        for (auto n : Values(pl->table->next)) {
            if (n && n->tables.size() > 0 && !GroupPlace::in_work(work, n)) {
                bool ready = true;
                ordered_set<const GroupPlace *> parents;
                for (auto tbl : seqInfo.at(n).refs) {
                    if (tbl == pl->table) {
                        parents.insert(gw_match_grp ? gw_match_grp : pl->group);
                    } else if (pl->is_placed(tbl)) {
                        BUG_CHECK(!gw_match_grp, "Failure attaching gateway to table");
                        parents.insert(pl->find_group(tbl));
                    } else {
                        BUG_CHECK(!gw_match_grp, "Failure attaching gateway with multi-ref table");
                        ready = false;
                        break ; } }
                if (ready) {
                    new GroupPlace(*this, work, parents, n); } } } }
    return pl;
}

bool TablePlacement::is_better(const Placed *a, const Placed *b) {
    if (a->stage < b->stage) return true;
    if (a->stage > b->stage) return false;
    if (b->need_more && !a->need_more) return true;
    if (a->need_more && !b->need_more) return false;
    if (deps.graph.at(a->name).dep_stages > deps.graph.at(b->name).dep_stages)
        return true;
    if (deps.graph.at(a->name).dep_stages < deps.graph.at(b->name).dep_stages)
        return false;
    if (deps.graph.at(a->name).data_dep.size() < deps.graph.at(b->name).data_dep.size())
        return true;
    return false;
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

IR::Node *TablePlacement::preorder(IR::Tofino::Pipe *pipe) {
    LOG1("table placement starting");
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau));
    tblInfo.clear();
    seqInfo.clear();
    ordered_set<const GroupPlace *>     work;
    const Placed *placed = nullptr;
    /* all the state for a partial table placement is stored in the work
     * set and placed list, which are const pointers, so we can backtrack
     * by just saving a snapshot of a work set and corresponding placed
     * list and restoring that point */
    for (auto th : pipe->thread)
        if (th.mau && th.mau->tables.size() > 0) {
            th.mau->apply(SetupInfo(*this));
            new GroupPlace(*this, work, {}, th.mau); }
    ordered_set<const IR::MAU::Table *> partly_placed;
    while (!work.empty()) {
        LOG3("stage " << (placed ? placed->stage : 0) << ", work: " << work <<
             ", partly placed " << partly_placed.size() << ", placed " << count(placed));
        StageUseEstimate current = get_current_stage_use(placed);
        vector<const Placed *> trial;
        for (auto it = work.begin(); it != work.end();) {
            auto grp = *it;
            LOG4("group " << grp->seq->id << " depth=" << grp->depth);
            if (placed && placed->placed.contains(grp->info.tables)) {
                BUG("group %d already done?", grp->seq->id);
                it = work.erase(it);
                grp->finish(work);  // is 'it' still valid?  might be end()
                continue; }
            BUG_CHECK(grp->ancestors.count(grp) == 0, "group is its own ancestor!");
            work -= grp->ancestors;
            int idx = -1;
            bool done = true;
            bitvec seq_placed;
            for (auto t : grp->seq->tables) {
                ++idx;
                if (placed && placed->is_placed(t)) {
                    seq_placed[idx] = true;
                    LOG3(" - skipping " << t->name << " as its already done");
                    continue; }
                if (grp->seq->deps[idx] - seq_placed) {
                    LOG3(" - skipping " << t->name << " as its dependent on: " <<
                         DumpSeqTables(grp->seq, grp->seq->deps[idx] - seq_placed));
                    done = false;
                    continue; }
                if (auto pl = try_place_table(t, placed, current)) {
                    pl->group = grp;
                    done = false;
                    if (!partly_placed.count(pl->table)) {
                        bool defer = false;
                        for (auto t : partly_placed)
                            if (!mutex(t, pl->table)) {
                                LOG3(" - skipping " << pl->name << " as it is not mutually "
                                     "exclusive with partly placed " << t->name);
                                defer = true;
                                break; }
                        if (defer) continue; }
                    trial.push_back(pl);
                } else {
                    BUG("Can't place a table"); } }
            if (done) {
                BUG("Can't find a table to place");
                it = work.erase(it);
            } else {
                it++; } }
        if (work.empty()) break;
        if (trial.empty())
            BUG("No tables placeable, but not all tables placed?");
        LOG2("found " << trial.size() << " tables that could be placed: " << trial);
        const Placed *best = 0;
        for (auto t : trial)
            if (!best || is_better(t, best))
                best = t;
        placed = place_table(work, best);
        if (placed->need_more)
            partly_placed.insert(placed->table);
        else
            partly_placed.erase(placed->table); }
    LOG1("Table placement placed " << count(placed) << " tables in " <<
         (placed ? placed->stage+1 : 0) << " stages");
    placement = placed;
    table_placed.clear();
    for (auto p = placement; p; p = p->prev) {
        LOG1("Table name is " << p->name << " with logical id " << p->logical_id);
        assert(p->name == p->table->name);
        assert(p->need_more || table_placed.count(p->name) == 0);
        table_placed.emplace_hint(table_placed.find(p->name), p->name, p);
        if (p->gw) {
            assert(p->need_more || table_placed.count(p->gw->name) == 0);
            table_placed.emplace_hint(table_placed.find(p->gw->name), p->gw->name, p); } }
    LOG1("Finished table placement");
    return pipe;
}

IR::Node *TablePlacement::postorder(IR::Tofino::Pipe *pipe) {
    tblInfo.clear();
    seqInfo.clear();
    table_placed.clear();
    LOG3("table placement completed");
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau));
    return pipe;
}

static void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *resources,
                                int entries) {
    tbl->resources = resources;
    tbl->layout.entries = entries;
    if (!tbl->ways.empty()) {
        auto &mem = resources->memuse.at(tbl->name);
        assert(tbl->ways.size() == mem.ways.size());
        for (unsigned i = 0; i < tbl->ways.size(); ++i)
            tbl->ways[i].entries = mem.ways[i].size * 1024 * tbl->ways[i].match_groups; }
}

/* Sets the layout and ways for a table from the selected table layout option 
   from table placement */
static void select_layout_option(IR::MAU::Table *tbl,
                                 const IR::MAU::Table::LayoutOption *layout_option) {
    tbl->layout = *(layout_option->layout);
    if (!layout_option->layout->ternary) {
        tbl->ways.resize(layout_option->way_sizes.size());
        int index = 0;
        for (auto &way : tbl->ways) {
            way = *(layout_option->way);
            way.entries = way.match_groups * 1024 * layout_option->way_sizes[index];
            index++;
        }
    }
}

/* Adds the potential ternary tables necessary for layout options */
static void add_attached_tables(IR::MAU::Table *tbl,
                                const IR::MAU::Table::LayoutOption *layout_option) {
    if (layout_option->layout->ternary_indirect_required()) {
        LOG3("  Adding Ternary Indirect table to " << tbl->name);
        auto *tern_indir = new IR::MAU::TernaryIndirect(tbl->name);
        tbl->attached.push_back(tern_indir);
    }
    if (layout_option->layout->action_data_required()) {
        LOG3("  Adding Action Data Table to " << tbl->name);
        auto *act_data = new IR::MAU::ActionData(tbl->name);
        tbl->attached.push_back(act_data);
    }
}


IR::Node *TablePlacement::preorder(IR::MAU::Table *tbl) {
    auto it = table_placed.find(tbl->name);
    if (it == table_placed.end()) {
        assert(strchr(tbl->name, '.'));
        return tbl; }
    tbl->logical_id = it->second->logical_id;
    // FIXME: Currently the gateway is laid out for every table, so I'm keeping the information
    // in split tables.  In the future, there should be no gw_layout for split tables
    IR::MAU::Table::Layout gw_layout;
    bool gw_layout_used = false;

    if (it->second->gw && it->second->gw->name == tbl->name) {
        /* fold gateway and match table together */
        auto match = it->second->table;
        assert(match && !tbl->match_table && !match->uses_gateway());
        LOG3("folding gateway " << tbl->name << " onto " << match->name);
        tbl->name = match->name;
        for (auto &gw : tbl->gateway_rows)
            if (gw.second == it->second->gw_result_tag)
                gw.second = cstring();
        tbl->match_table = match->match_table;
        tbl->actions = match->actions;
        tbl->attached = match->attached;
        /* Generate the correct table layout from the options */
        gw_layout = tbl->layout;
        gw_layout_used = true;
        tbl->layout_options = match->layout_options;
        select_layout_option(tbl, it->second->use.preferred());
        add_attached_tables(tbl, it->second->use.preferred());
        tbl->layout += gw_layout;
        auto *seq = tbl->next.at(it->second->gw_result_tag)->clone();
        tbl->next.erase(it->second->gw_result_tag);
        if (seq->tables.size() != 1) {
            bool found = false;
            for (auto it = seq->tables.begin(); it != seq->tables.end(); it++)
                if (*it == match) {
                    seq->tables.erase(it);
                    found = true;
                    break; }
            assert(found);
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
        select_layout_option(tbl, it->second->use.preferred());
        add_attached_tables(tbl, it->second->use.preferred());
    }


    if (table_placed.count(tbl->name) == 1) {
        table_set_resources(tbl, it->second->resources, it->second->entries);
        return tbl;
    }
    int counter = 0;
    IR::MAU::Table *rv = 0, *prev = 0;
    /* split the table into multiple parts per the placement */
    LOG1("splitting " << tbl->name << " across " << table_placed.count(tbl->name) << " stages");
    for (it = table_placed.find(tbl->name); it->first == tbl->name; it++) {
        char suffix[8];
        snprintf(suffix, sizeof(suffix), ".%d", ++counter);
        auto *table_part = tbl->clone_rename(suffix);
        select_layout_option(table_part, it->second->use.preferred());
        if (gw_layout_used)
            table_part->layout += gw_layout;
        table_part->logical_id = it->second->logical_id;
        table_set_resources(table_part, it->second->resources->clone_rename(suffix, tbl->name),
                            it->second->entries);
        if (!rv) {
            rv = table_part;
            assert(!prev);
        } else {
            for (auto &gw : table_part->gateway_rows)
                table_part->next.erase(gw.second);
            table_part->gateway_rows.clear();
            prev->next["$miss"] = new IR::MAU::TableSeq(table_part); }
        prev = table_part; }
    assert(rv);
    return rv;
}

IR::Node *TablePlacement::preorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() > 1) {
        std::sort(seq->tables.begin(), seq->tables.end(),
            [this](const IR::MAU::Table *a, const IR::MAU::Table *b) -> bool {
                return find_placed(a->name)->second->logical_id <
                       find_placed(b->name)->second->logical_id; }); }
    return seq;
}

std::multimap<cstring, const TablePlacement::Placed *>::const_iterator
TablePlacement::find_placed(cstring name) const {
    auto rv = table_placed.find(name);
    if (rv == table_placed.end())
        if (auto p = name.findlast('.'))
            rv = table_placed.find(name.before(p));
    return rv;
}

void dump(const ordered_set<const TablePlacement::GroupPlace *> &work) {
    std::cout << work << std::endl; }
