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
#include "field_use.h"
#include <algorithm>
#include <list>

class SetupUids : public Inspector {
    map<cstring, unsigned>      &table_uids;
    bool preorder(const IR::MAU::Table *tbl) {
        assert(table_uids.count(tbl->name) == 0);
        table_uids.emplace(tbl->name, table_uids.size());
        return true; }
public:
    SetupUids(map<cstring, unsigned> &t) : table_uids(t) {}
};


struct TablePlacement::GroupPlace {
    /* tracking the placement of a group of tables from an IR::MAU::TableSeq
     *   parent group that must wait until this group is fully placed before any more
     *          tables from it may be placed (so next_table setup works)
     *   seq    the TableSeq being placed for this group */
    const GroupPlace                    *parent;
    const IR::MAU::TableSeq             *seq;
    int                                 depth;
    GroupPlace(ordered_set<const GroupPlace*> &work, const GroupPlace *p,
               const IR::MAU::TableSeq *s)
    : parent(p), seq(s), depth(p ? p->depth+1 : 1) {
        work.insert(this);
        if (parent)
            work.erase(parent); }
    GroupPlace(ordered_set<const GroupPlace*> &work, const IR::MAU::TableSeq *s)
    : GroupPlace(work, 0, s) {}
    void finish(ordered_set<const GroupPlace*> &work) const {
        assert(work.count(this) == 1);
        work.erase(this);
        if (parent) {
            for (auto o : work)
                if (o->parent == parent) return;
            work.insert(parent); } }
};

struct TablePlacement::Placed {
    /* A linked list of table placement decisions, from last table placed to first (so we
     * can backtrack and create different lists as needed) */
    TablePlacement              &self;
    const Placed                *prev;
    cstring                     name;
    int                         entries = 0;
    bitvec                      placed;  // fully placed tables after this placement
    bool                        need_more = false, gw_cond = true;
    const IR::MAU::Table        *table, *gw = 0;
    short                       stage, logical_id;
    StageUseEstimate            use;
    const TableResourceAlloc    *resources;
    Placed(TablePlacement &self, const Placed *p, const IR::MAU::Table *t)
        : self(self), prev(p), name(t->name), table(t) {
            if (prev) placed = prev->placed; }
    bool is_placed(cstring name) const { return placed[self.table_uids.at(name)]; }
    bool is_placed(const IR::MAU::Table *tbl) const { return is_placed(tbl->name); }
    bool is_placed(const IR::MAU::TableSeq *seq) const {
        for (auto tbl : seq->tables)
            if (!is_placed(tbl)) return false;
        return true; }
};

static StageUseEstimate get_current_stage_use(const TablePlacement::Placed *pl) {
    short               stage;
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

TablePlacement::Placed *gateway_merge(TablePlacement::Placed *pl) {
    if (pl->gw || !pl->table->gateway_expr || pl->table->match_table)
        return pl;
    /* table is just a gateway -- look for a dependent match table to combine with */
    bool cond = true;
    const IR::MAU::Table *match = 0;
    for (auto it = pl->table->next.rbegin(); it != pl->table->next.rend(); it++) {
        int idx = -1;
        for (auto t : it->second->tables) {
            ++idx;
            if (it->second->deps[idx]) continue;
            if (t->gateway_expr) continue;
            match = t;
            cond = it->first == "true";
            break; }
        if (match) break; }
    if (match) {
        LOG2(" - making " << pl->name << " gateway on " << match->name);
        pl->name = match->name;
        pl->gw = pl->table;
        pl->table = match;
        pl->gw_cond = cond; }
    return pl;
}

static bool try_alloc_mem(TablePlacement::Placed *next, const TablePlacement::Placed *done, int &entries, TableResourceAlloc *resources) {
    Memories current_mem;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev)
        current_mem.update(p->resources->memuse);
    int gw_entries = 1;
    if (!current_mem.allocTable(next->table, entries, resources->memuse) ||
        (next->gw && !current_mem.allocTable(next->gw, gw_entries, resources->memuse))) {
        resources->memuse.clear();
        return false; }
    return true;
}

TablePlacement::Placed *TablePlacement::try_place_table(const IR::MAU::Table *t, const Placed *done,
                                                        const StageUseEstimate &current) {
    LOG2("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    auto *rv = gateway_merge(new Placed(*this, done, t));
    TableResourceAlloc *resources = new TableResourceAlloc;
    rv->resources = resources;
    t = rv->table;
    rv->stage = done ? done->stage : 0;
    int min_entries = 1;
    rv->entries = 512;
    if (t->match_table) {
        if (t->match_table->size)
            rv->entries = t->match_table->size;
        else if (t->match_table->min_size)
            rv->entries = t->match_table->min_size; }
    auto &rvdeps = deps.graph.at(rv->name);
    for (auto *p = done; p; p = p->prev) {
        if (p->name == rv->name) {
            if (p->need_more == false) {
                LOG2(" - can't place as its already done");
                return nullptr; }
            rv->entries -= p->entries;
        } else if (p->stage == rv->stage && rvdeps.data_dep.count(p->name) &&
                   rvdeps.data_dep.at(p->name) >= DependencyGraph::Table::ACTION)
            rv->stage++; }
    assert(!rv->placed[table_uids.at(rv->name)]);

#if 1
    IXBar current_ixbar;
    for (auto *p = done; p && p->stage == rv->stage; p = p->prev) {
        current_ixbar.update(p->resources->match_ixbar);
        current_ixbar.update(p->resources->gateway_ixbar); }
    if (!current_ixbar.allocTable(rv->table, resources->match_ixbar, resources->gateway_ixbar) ||
        !current_ixbar.allocTable(rv->gw, resources->match_ixbar, resources->gateway_ixbar)) {
        rv->stage++;
        current_ixbar.clear();
        if (!current_ixbar.allocTable(rv->table, resources->match_ixbar, resources->gateway_ixbar)||
            !current_ixbar.allocTable(rv->gw, resources->match_ixbar, resources->gateway_ixbar))
            throw Util::CompilerBug("Can't fit table %s in ixbar by itself", rv->name); }
#endif

    LOG3(" - will try " << rv->entries << " of " << t->name << " in stage " << rv->stage);
    StageUseEstimate min_use(t, min_entries); // minimum use for part of table to be useful
    int increment_entries = min_entries + 1;
    StageUseEstimate increment_use(t, increment_entries); // next bigger than min_use
    rv->use = StageUseEstimate(t, rv->entries);
    if (rv->gw) {
        assert(!t->gateway_expr);
        assert(!rv->gw->match_table);
        rv->use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes;
        min_use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes;
        increment_use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes; }

    auto avail = StageUseEstimate::max();
    if (rv->stage == (done ? done->stage : 0)) {
        if (!(min_use + current <= avail) || !try_alloc_mem(rv, done, min_entries, resources))
            rv->stage++;
        resources->memuse.clear(); }
    if (done && rv->stage == done->stage) {
        avail.srams -= current.srams;
        avail.tcams -= current.tcams;
        avail.maprams -= current.maprams; }
    assert(min_use <= avail);
    int last_try = rv->entries;
    while (!(rv->use <= avail) || !try_alloc_mem(rv, done, rv->entries, resources)) {
        rv->need_more = true;
        int scale = 0;
        if (rv->use.tcams > avail.tcams)
            scale = (avail.tcams - min_use.tcams) / (increment_use.tcams - min_use.tcams);
        else if (rv->use.maprams > avail.maprams)
            scale = (avail.maprams - min_use.maprams) / (increment_use.maprams - min_use.maprams);
        else if (rv->use.srams > avail.srams)
            scale = (avail.srams - min_use.srams) / (increment_use.srams - min_use.srams);
        if (scale)
            rv->entries = scale * increment_entries - (scale-1) * min_entries;
        if (rv->entries >= last_try) {
            rv->entries = last_try - 500;
            if (rv->entries < min_entries && min_entries < last_try)
                rv->entries = min_entries; }
        assert(rv->entries >= min_entries);
        last_try = rv->entries;
        LOG3(" - reducing to " << rv->entries << " of " << t->name << " in stage " << rv->stage);
        rv->use = StageUseEstimate(t, rv->entries);
        if (rv->gw)
            rv->use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes; }

    rv->logical_id = done && done->stage == rv->stage ? done->logical_id + 1
                                                      : rv->stage * StageUse::MAX_LOGICAL_IDS;
    assert((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage);
    LOG2("try_place_table returning " << rv->entries << " of " << rv->name <<
         " in stage " << rv->stage);
    if (!rv->need_more) {
        rv->placed[table_uids.at(rv->name)] = true;
        if (rv->gw)
            rv->placed[table_uids.at(rv->gw->name)] = true; }
    return rv;
}

const TablePlacement::Placed *TablePlacement::place_table(ordered_set<const GroupPlace *>&work, const GroupPlace *grp, const Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " <<
         pl->stage << (pl->need_more ? " (need more)" : ""));
    if (!pl->need_more) {
        while (grp && pl->is_placed(grp->seq)) {
            grp->finish(work);
            grp = grp->parent; }
        if (pl->gw)  {
            GroupPlace *match_grp = 0;
            bool found_match = false;
            for (auto n : Values(pl->gw->next)) {
                if (!n || n->tables.size() == 0) continue;
                if (n->tables.size() == 1 && n->tables.at(0) == pl->table) {
                    assert(!found_match && !match_grp);
                    found_match = true;
                    continue; }
                GroupPlace *g = new GroupPlace(work, grp, n);
                for (auto t : n->tables) {
                    if (t == pl->table) {
                        assert(!found_match && !match_grp);
                        found_match = true;
                        match_grp = g; } } }
            assert(found_match);
            if (match_grp)
                grp = match_grp; }
        for (auto n : Values(pl->table->next))
            if (n && n->tables.size() > 0)
                new GroupPlace(work, grp, n);
    }
    return pl;
}

bool TablePlacement::is_better(const Placed *a, const Placed *b) {
    if (a->stage < b->stage) return true;
    if (a->stage > b->stage) return false;
    if (b->need_more && !a->need_more) return true;
    if (a->need_more && !b->need_more) return false;
    if (deps.graph.at(a->name).dep_stages > deps.graph.at(b->name).dep_stages)
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
    bool first = true;
    for (auto i : s.which) {
        if (first) first = false;
        else out << ' ';
        if (i >= 0 && (size_t)i < s.seq->tables.size())
            out << s.seq->tables[i]->name;
        else
            out << "<oob " << i << ">"; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const std::pair<const TablePlacement::GroupPlace *, const TablePlacement::Placed *> &v) {
    out << v.second->name;
    return out;
}

IR::Node *TablePlacement::preorder(IR::Tofino::Pipe *pipe) {
    table_uids.clear();
    pipe->apply(SetupUids(table_uids));
    ordered_set<const GroupPlace *>     work;
    const Placed *placed = nullptr;
    /* all the state for a partial table placement is stored in the work
     * set and placed list, which are const pointers, so we can backtrack
     * by just saving a snapshot of a work set and corresponding placed
     * list and restoring that point */
    for (auto th : pipe->thread)
        if (th.mau && th.mau->tables.size() > 0) new GroupPlace(work, th.mau);
    ordered_set<const IR::MAU::Table *> partly_placed;
    LOG1("table placement starting");
    while (!work.empty()) {
        LOG3("stage " << (placed ? placed->stage : 0) << ", work size is " << work.size() <<
             ", partly placed " << partly_placed.size() << ", placed " << count(placed));
        StageUseEstimate current = get_current_stage_use(placed);
        vector<std::pair<const GroupPlace *, const Placed *>> trial;
        for (auto it = work.begin(); it != work.end();) {
            auto grp = *it;
            LOG4("group " << grp << " depth=" << grp->depth);
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
                    trial.emplace_back(grp, pl);
                } else
                    assert(0); }
            if (done)
                assert(0);
            else
                it++; }
        if (work.empty()) break;
        if (trial.empty())
            throw Util::CompilerBug("No tables placeable, but not all tables placed?");
        LOG2("found " << trial.size() << " tables that could be placed: " << trial);
        decltype(trial)::value_type *best = 0;
        for (auto &t : trial)
            if (!best || is_better(t.second, best->second))
                best = &t;
        placed = place_table(work, best->first, best->second);
        if (placed->need_more)
            partly_placed.insert(placed->table);
        else
            partly_placed.erase(placed->table); }
    LOG1("Table placement placed " << count(placed) << " tables in " << (placed->stage+1) <<
         " stages");
    placement = placed;
    table_placed.clear();
    for (auto p = placement; p; p = p->prev) {
        assert(p->name == p->table->name);
        assert(p->need_more || table_placed.count(p->name) == 0);
        table_placed.emplace_hint(table_placed.find(p->name), p->name, p);
        if (p->gw) {
            assert(p->need_more || table_placed.count(p->gw->name) == 0);
            table_placed.emplace_hint(table_placed.find(p->gw->name), p->gw->name, p); } }
    return pipe;
}

IR::Node *TablePlacement::preorder(IR::MAU::Table *tbl) {
    auto it = table_placed.find(tbl->name);
    if (it == table_placed.end()) {
        assert(strchr(tbl->name, '.'));
        return tbl; }
    tbl->logical_id = it->second->logical_id;
    if (it->second->gw && it->second->gw->name == tbl->name) {
        /* fold gateway and match table together */
        auto match = it->second->table;
        assert(match && !tbl->match_table && !match->gateway_expr);
        LOG3("folding gateway " << tbl->name << " onto " << match->name);
        tbl->name = match->name;
        tbl->gateway_cond = it->second->gw_cond;
        tbl->match_table = match->match_table;
        tbl->actions = match->actions;
        tbl->attached = match->attached;
        tbl->layout += match->layout;
        auto *seq = tbl->next.at(tbl->gateway_cond ? "true" : "false")->clone();
        tbl->next.erase(tbl->gateway_cond ? "true" : "false");
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
            if (next.first == "default")
                have_default = true;
            if (seq) {
                auto *new_next = next.second->clone();
                for (auto t : seq->tables)
                    new_next->tables.push_back(t);
                tbl->next[next.first] = new_next;
            } else
                tbl->next[next.first] = next.second; }
        if (!have_default && seq)
            tbl->next["default"] = seq; }
    if (table_placed.count(tbl->name) == 1) {
        tbl->layout.entries = it->second->entries;
        tbl->resources = it->second->resources;
        return tbl; }
    int counter = 0;
    IR::MAU::Table *rv = 0, *prev = 0;
    /* split the table into multiple parts per the placement */
    LOG3("splitting " << tbl->name << " across " << table_placed.count(tbl->name) << " stages");
    for (it = table_placed.find(tbl->name); it->first == tbl->name; it++) {
        char suffix[8];
        sprintf(suffix, ".%d", ++counter);
        auto *table_part = tbl->clone_rename(suffix);
        table_part->logical_id = it->second->logical_id;
        table_part->layout.entries = it->second->entries;
        table_part->resources = it->second->resources->clone_rename(suffix);
        if (!rv) {
            rv = table_part;
            assert(!prev);
        } else {
            table_part->gateway_expr = 0;
            table_part->gateway_cond = true;
            prev->next["$miss"] = new IR::MAU::TableSeq(table_part); }
        prev = table_part; }
    assert(rv);
    return rv;
}

IR::Node *TablePlacement::preorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() > 1) {
        std::sort(seq->tables.begin(), seq->tables.end(),
            [this](const IR::MAU::Table *a, const IR::MAU::Table *b) -> bool {
                return table_placed.find(a->name)->second->logical_id <
                       table_placed.find(b->name)->second->logical_id; }); }
    return seq;
}
