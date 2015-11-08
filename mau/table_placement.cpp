#include "ir/ir.h"
#include "resource_estimate.h"
#include "table_dependency_graph.h"
#include "table_mutex.h"
#include "table_placement.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/log.h"
#include "field_use.h"
#include <algorithm>
#include <list>

struct TablePlacement::GroupPlace {
    /* tracking the placement of a group of tables from an IR::MAU::TableSeq
     *   work	work queue of groups that can have tables chosen to be placed next
     *   parent group that must wait until this group is fully placed before any more
     *		tables from it may be placed (so next_table setup works)
     *   iter	pointer into the work queue for this object (work.end() if not currently
     *		it the queue
     *   seq	the TableSeq being placed for this group
     *   placed	bitmap of tables in seq that are fully placed
     *   waitcount count of other GroupPlace objects we're the parent of (they must all be
     *		placed before we can continue) */
    std::list<GroupPlace*>		&work;
    GroupPlace				*parent;
    std::list<GroupPlace*>::iterator	iter;
    const IR::MAU::TableSeq		*seq;
    bitvec				placed;
    int					waitcount;
    GroupPlace(std::list<GroupPlace*> &w, GroupPlace *p, const IR::MAU::TableSeq *s) :
	work(w), parent(p), seq(s), placed(0U), waitcount(0) {
	    iter = work.insert(work.end(), this);
	    if (parent) {
		if (!parent->waitcount++) {
		    assert(parent->iter != work.end());
		    work.erase(parent->iter);
		    parent->iter = work.end(); } } }
    GroupPlace(std::list<GroupPlace*> &w, const IR::MAU::TableSeq *s) : GroupPlace(w, 0, s) {}
    ~GroupPlace() {
	/* DANGER -- we're not removing this from the worklist -- instead, whoever calls
	 * delete must then erase the element from the worklist, and needs to get anything
	 * we may have just added to the worklist... */
	if (parent && !--parent->waitcount) {
	    assert(parent->iter == work.end());
	    parent->iter = work.insert(work.end(), parent); } }
};

struct TablePlacement::Placed {
    /* A linked list of table placement decisions, from last table placed to first (so we
     * can backtrack and create different lists as needed) */
    const Placed		*prev;
    cstring			name;
    int				entries = 0;
    bool			need_more = false, gw_cond = true;
    const IR::MAU::Table	*table, *gw = 0;
    short			stage, logical_id;
    StageUse			use;
    Placed(const Placed *p, const IR::MAU::Table *t) : prev(p), name(t->name), table(t) {}
};

static StageUse get_current_stage_use(const TablePlacement::Placed *pl) {
    short	stage;
    StageUse	rv;
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



TablePlacement::Placed *TablePlacement::try_place_table(const IR::MAU::Table *t, const Placed *done,
							const StageUse &current) {
    LOG2("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    auto *rv = gateway_merge(new Placed(done, t));
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
    if (rv->entries <= 0) {
	LOG2(" - can't place as its already done");
	return nullptr; }

    StageUse min_use(t, min_entries); // minimum use for part of table to be useful
    rv->use = StageUse(t, rv->entries);
    if (rv->gw) {
	assert(!t->gateway_expr);
	assert(!rv->gw->match_table);
	rv->use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes;
	min_use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes; }

    auto avail = StageUse::max();
    if (rv->stage == (done ? done->stage : 0) && !(rv->use + current <= avail)) {
	if (!(min_use + current <= avail))
	    rv->stage++;
	else {
	    avail.srams -= current.srams;
	    avail.tcams -= current.tcams;
	    avail.maprams -= current.maprams; } }
    assert(min_use <= avail);
    int last_try = rv->entries;
    while (!(rv->use <= avail)) {
	rv->need_more = true;
	if (rv->use.tcams > avail.tcams)
	    rv->entries = min_entries * (avail.tcams / min_use.tcams);
	else if (rv->use.maprams > avail.maprams)
	    rv->entries = min_entries * (avail.maprams / min_use.maprams);
	else if (rv->use.srams > avail.srams)
	    rv->entries = min_entries * (avail.srams / min_use.srams);
	else
	    assert(false);
	if (rv->entries >= last_try)
	    rv->entries = last_try - 100;
	else
	    last_try = rv->entries;
	rv->use = StageUse(t, rv->entries);
	if (rv->gw)
	    rv->use.exact_ixbar_bytes += rv->gw->layout.ixbar_bytes; }
    rv->logical_id = done && done->stage == rv->stage ? done->logical_id + 1
						      : rv->stage * StageUse::MAX_LOGICAL_IDS;
    assert((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage);
    return rv;
}

TablePlacement::Placed *TablePlacement::place_table(GroupPlace *grp, int idx, Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
	 (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " <<
	 pl->stage << (pl->need_more ? " (need more)" : ""));
    if (!pl->need_more) {
	grp->placed[idx] = true;
	if (pl->gw)  {
	    GroupPlace *match_grp = 0;
	    for (auto &n : pl->gw->next)
		if (n.second) {
		    GroupPlace *g = new GroupPlace(grp->work, grp, n.second);
		    for (auto t : n.second->tables) {
			if (t == pl->table) {
			    assert(!match_grp);
			    match_grp = g; } } }
	    assert(match_grp);
	    grp = match_grp; }
	for (auto &n : pl->table->next)
	    if (n.second) new GroupPlace(grp->work, grp, n.second);
    }
    return pl;
}

bool TablePlacement::is_better(const Placed *a, const Placed *b) {
    if (a->stage < b->stage) return true;
    if (b->need_more && !a->need_more) return true;
    if (deps.graph.at(a->name).dep_stages > deps.graph.at(b->name).dep_stages)
	return true;
    return false;
}

class DumpSeqTables {
    const IR::MAU::TableSeq	*seq;
    bitvec			which;
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


IR::Node *TablePlacement::preorder(IR::Tofino::Pipe *pipe) {
    std::list<GroupPlace *>	work;
    for (auto th : pipe->thread)
	if (th.mau) new GroupPlace(work, th.mau);
    Placed *placed = nullptr;
    set<const IR::MAU::Table *> partly_placed;
    LOG1("table placement starting");
    while (!work.empty()) {
	LOG3("stage " << (placed ? placed->stage : 0) << ", work size is " << work.size() <<
	     ", partly placed " << partly_placed.size() << ", placed " << count(placed));
	StageUse current = get_current_stage_use(placed);
	vector<std::tuple<GroupPlace *, int, Placed *>> trial;
	for (auto it = work.begin(); it != work.end();) {
	    auto grp = *it;
	    int idx = -1;
	    bool done = true;
	    for (auto t : grp->seq->tables) {
		if (grp->placed[++idx]) {
		    LOG3(" - skipping " << t->name << " as its already done");
		    continue; }
		if (grp->seq->deps[idx] - grp->placed) {
		    LOG3(" - skipping " << t->name << " as its dependent on: " <<
			 DumpSeqTables(grp->seq, grp->seq->deps[idx] - grp->placed));
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
		    trial.emplace_back(grp, idx, pl);
		} else
		    grp->placed[idx] = true; /* already placed */ }
	    if (done) {
		delete grp;
		it = work.erase(it);
	    } else
		it++; }
	if (work.empty()) break;
	if (trial.empty())
	    throw std::logic_error("No tables placeable, but not all tables placed?");
	LOG2("found " << trial.size() << " tables that could be placed");
	decltype(trial)::value_type *best = 0;
	for (auto &t : trial)
	    if (!best || is_better(std::get<2>(t), std::get<2>(*best)))
		best = &t;
	placed = place_table(std::get<0>(*best), std::get<1>(*best), std::get<2>(*best));
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
	return tbl; }
    int counter = 0;
    IR::MAU::Table *rv = 0, *prev = 0;
    /* split the table into multiple parts per the placement */
    LOG3("splitting " << tbl->name << " across " << table_placed.count(tbl->name) << " stages");
    for (it = table_placed.find(tbl->name); it->first == tbl->name; it++) {
	char suffix[8];
	sprintf(suffix, ".%d", ++counter);
	auto *table_part = tbl->clone();
	table_part->name +=  suffix;
	table_part->logical_id = it->second->logical_id;
	table_part->layout.entries = it->second->entries;
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
