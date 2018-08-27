#include "bf-p4c/mau/table_placement.h"

#include <algorithm>
#include <list>
#include <sstream>
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
#include "lib/safe_vector.h"
#include "lib/set.h"
#include "bf-p4c/ir/table_tree.h"
#include "bf-p4c/phv/phv_fields.h"

TablePlacement::TablePlacement(const DependencyGraph* d, const TablesMutuallyExclusive &m,
                               const PhvInfo &p, const LayoutChoices &l,
                               const SharedIndirectAttachedAnalysis &s, bool fp)
: deps(d), mutex(m), phv(p), lc(l), siaa(s), forced_placement(fp) {}

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
    return false;
}

Visitor::profile_t TablePlacement::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    LOG1("Table Placement ignores container conflicts? " << ignoreContainerConflicts);
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
    bool preorder(const IR::MAU::Action *) override { return false; }
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
    const int                   id;
    const Placed                *prev = 0;
    const GroupPlace            *group = 0;  // work group chosen from
    cstring                     name;
    int                         entries = 0;
    bitvec                      placed;  // fully placed tables after this placement

    /// True if the table needs to be split across multiple stages, because it
    /// can't fit within a single stage (eg. not enough entries in the stage).
    bool                        need_more = false;

    cstring                     gw_result_tag;
    const IR::MAU::Table        *table, *gw = 0;
    int                         stage, logical_id;
    /// Information on which stage table this table is associated with.  If the table is
    /// never split, then the stage_split should be -1
    int                         initial_stage_split = -1;
    int                         stage_split = -1;
    StageUseEstimate            use;
    StageUseEstimate            extra_use;
    const TableResourceAlloc    *resources;
    Placed(TablePlacement &self, const IR::MAU::Table *t)
        : self(self), id(++uid_counter), table(t) {
        if (t) { name = t->name; }
        traceCreation();
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

    bool gateway_merge(ordered_set<const IR::MAU::Table *> &attempted_tables);
    void set_prev(const Placed *p, bool make_new,
                  safe_vector<TableResourceAlloc *> &prev_resources) {
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
            BUG_CHECK(size_t(index) == prev_resources.size(), "Table Placement could not "
                      "correctly clear a stage");
        }
    }
    friend std::ostream &operator<<(std::ostream &out, const TablePlacement::Placed *pl) {
        out << pl->name;
        return out; }

    Placed(const Placed &p)
        : self(p.self), id(uid_counter++), prev(p.prev), group(p.group), name(p.name),
          entries(p.entries), placed(p.placed), need_more(p.need_more),
          gw_result_tag(p.gw_result_tag), table(p.table), gw(p.gw), stage(p.stage),
          logical_id(p.logical_id), initial_stage_split(p.initial_stage_split),
          stage_split(p.stage_split), use(p.use), extra_use(p.extra_use), resources(p.resources)
          { traceCreation(); }

 private:
    Placed(Placed &&) = delete;
    void traceCreation() { }
    static int uid_counter;
};

int TablePlacement::Placed::uid_counter = 0;

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
        for (; pl && pl->stage == stage; pl = pl->prev) {
            rv += pl->use;
            for (auto back_at : pl->table->attached) {
                auto at = back_at->attached;
                rv.shared_attached.insert(at);
            }
        }
    }
    return rv;
}

static int count(const TablePlacement::Placed *pl) {
    int rv = 0;
    while (pl) {
        pl = pl->prev;
        rv++; }
    return rv;
}


bool TablePlacement::Placed::gateway_merge(ordered_set<const IR::MAU::Table *> &attempted_tables) {
    bool can_have_link = true;
    bool has_link = false;
    if (gw || !table->uses_gateway() || table->match_table) {
        can_have_link = false;
    }
    /* table is just a gateway -- look for a dependent match table to combine with */
    cstring result_tag;
    const IR::MAU::Table *match = 0;
    if (can_have_link) {
        for (auto it = table->next.rbegin(); it != table->next.rend(); it++) {
            if (self.seqInfo.at(it->second).refs.size() > 1)
                continue;
            int idx = -1;
            for (auto t : it->second->tables) {
                ++idx;
                if (it->second->deps[idx]) continue;
                bool should_skip = false;
                for (auto t2 : it->second->tables) {
                    if (self.deps->happens_before_control(t, t2))
                        should_skip = true;
                }
                if (should_skip)
                    continue;
                // if (deps->happens_before_control)
                if (t->uses_gateway()) continue;
                // FIXME: Look for notes above preorder for IR::MAU::Table
                if (t->next.count("$hit") || t->next.count("$miss")) continue;
                // Currently would potentially require multiple gateways if split into
                // multiple tables.  Not supported yet during allocation
                if (t->for_dleft()) continue;
                has_link = true;
                if (attempted_tables.count(t))
                    continue;
                match = t;
                result_tag = it->first;
                break;
            }
            if (match) break;
        }
    }
    if (match) {
        LOG2(" - making " << name << " gateway on " << match->name);
        name = match->name;
        gw = table;
        table = match;
        gw_result_tag = result_tag;
        attempted_tables.insert(match);
        return true;
    }

    if (!can_have_link || (can_have_link && !has_link)) {
        if (attempted_tables.count(table) == 0) {
            attempted_tables.insert(table);
            return true;
        }
    }
    return false;
}

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
bool TablePlacement::pick_layout_option(TablePlacement::Placed *next,
        const TablePlacement::Placed *done, TableResourceAlloc *resources,
        StageUseEstimate::StageAttached &shared_attached) {
    bool table_format = true;
    next->use = StageUseEstimate(next->table, next->entries, &lc, shared_attached);
    // FIXME: This is not the appropriate way to check if a table is a single gateway
    do {
        bool ixbar_fit = try_alloc_ixbar(next, done, resources);
        if (!ixbar_fit)
            return false;
        if (!next->table->gateway_only()) {
            table_format = try_alloc_format(next, resources, next->gw);
        }

        if (!table_format) {
            bool adjust_possible = next->use.adjust_choices(next->table, next->entries);
            if (!adjust_possible)
                return false;
        }
    } while (!table_format);
    return true;
}

bool TablePlacement::shrink_estimate(Placed *next, const Placed *done,
        TableResourceAlloc *resources, int &srams_left, int &tcams_left,
        int min_entries) {
    auto t = next->table;
    if (t->for_dleft()) {
        ::error("Cannot currently split dleft hash tables");
        return false;
    }

    if (t->layout.atcam)
        next->use.calculate_for_leftover_atcams(t, srams_left, next->entries);
    else if (!t->layout.ternary)
        next->use.calculate_for_leftover_srams(t, srams_left, next->entries);
    else
        next->use.calculate_for_leftover_tcams(t, tcams_left, srams_left, next->entries);

    if (next->entries < min_entries) {
        ERROR("Couldn't place mininum entries within a table");
        return false;
    }
    if (!t->layout.ternary)
        srams_left--;
    else
        tcams_left--;

    LOG3(" - reducing to " << next->entries << " of " << t->name << " in stage " << next->stage);
    bool ixbar_fit = try_alloc_ixbar(next, done, resources);
    if (!ixbar_fit) {
        ERROR("IXBar Allocation error after previous allocation?");
        return false;
    }

    bool table_format_fit = try_alloc_format(next, resources, next->gw);
    if (!table_format_fit) {
        ERROR("Table Format didn't fit after previous allocation");
        return false;
    }
    return true;
}

bool TablePlacement::try_alloc_ixbar(TablePlacement::Placed *next,
        const TablePlacement::Placed *done, TableResourceAlloc *resources) {
    resources->clear_ixbar();
    IXBar current_ixbar;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        current_ixbar.update(p->name, p->resources);
    }

    if (!current_ixbar.allocTable(next->table, phv, *resources, next->use.preferred(),
                                  next->use.preferred_action_format()) ||
        !current_ixbar.allocTable(next->gw, phv, *resources, next->use.preferred(),
                                  next->use.preferred_action_format())) {
        resources->clear_ixbar();
        error_message = "The table " + next->table->name + " could not fit within a single "
                        "input crossbar in an MAU stage";
        LOG3(error_message);
        return false;
    }


    IXBar verify_ixbar;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        verify_ixbar.update(p->name, p->resources);
    }

    verify_ixbar.update(next->name, resources);
    return true;
}

bool TablePlacement::try_alloc_mem(Placed *next, const Placed *done,
        TableResourceAlloc *resources, safe_vector<TableResourceAlloc *> &prev_resources) {
    Memories current_mem;
    int i = 0;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
         current_mem.add_table(p->table, p->gw, prev_resources[i], p->use.preferred(),
                               p->entries, p->stage_split);
         i++;
    }
    current_mem.add_table(next->table, next->gw, resources, next->use.preferred(), next->entries,
                          next->stage_split);
    resources->memuse.clear();
    for (auto *prev_resource : prev_resources) {
        prev_resource->memuse.clear();
    }
    if (!current_mem.allocate_all()) {
        error_message = "The table " + next->table->name + " could not fit in stage " +
                        std::to_string(next->stage) + " with " + std::to_string(next->entries)
                        + " entries";
        LOG3(error_message);
        resources->memuse.clear();
        for (auto *prev_resource : prev_resources) {
            prev_resource->memuse.clear();
        }
        return false;
    }

    Memories verify_mem;
    for (auto prev_resource : prev_resources)
        verify_mem.update(prev_resource->memuse);
    verify_mem.update(resources->memuse);

    return true;
}

bool TablePlacement::try_alloc_format(TablePlacement::Placed *next, TableResourceAlloc *resources,
        bool gw_linked) {
    const bitvec immediate_mask = next->use.preferred_action_format()->immediate_mask;
    resources->table_format.clear();
    if (!siaa.action_data_shared_tables(next->table).empty())
        gw_linked = true;

    TableFormat current_format(*next->use.preferred(), resources->match_ixbar, next->table,
                                immediate_mask, gw_linked);

    if (!current_format.find_format(&resources->table_format)) {
        resources->table_format.clear();
        error_message = "The selected pack format for table " + next->table->name + " could "
                        "not fit given the input xbar allocation";
        LOG3(error_message);
        return false;
    }
    return true;
}

bool TablePlacement::try_alloc_adb(Placed *next, const Placed *done,
        TableResourceAlloc *resources) {
    if (next->table->gateway_only())
        return true;

    BUG_CHECK(next->use.preferred_action_format() != nullptr,
              "A non gateway table has a null action data format allocation");

    ActionDataBus current_adb;
    resources->action_data_xbar.clear();

    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        current_adb.update(p->name, p->resources, p->table);
    }
    if (!current_adb.alloc_action_data_bus(next->table, next->use.preferred_action_format(),
                                           *resources)) {
        error_message = "The table " + next->table->name + " could not fit in within the "
                        "action data bus";
        LOG3(error_message);
        resources->action_data_xbar.clear();
        return false;
    }

    ActionDataBus adb_update;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        adb_update.update(p->name, p->resources, p->table);
    }
    adb_update.update(next->name, resources, next->table);
    return true;
}

bool TablePlacement::try_alloc_imem(Placed *next, const Placed *done,
        TableResourceAlloc *resources) {
    if (next->table->gateway_only())
        return true;

    InstructionMemory imem;
    resources->instr_mem.clear();

    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        imem.update(p->name, p->resources, p->table);
    }

    bool gw_linked = next->gw != nullptr;
    // FIXME: Because in the assembly, the actions are output with the action data table,
    // in order to ensure that all action profiles have correct mem_codes, the algorithm
    // currently always needs to assume a gateway exists.  This BUG arose from one table
    // with an action profile having a gateway, while the other table did not.  The true
    // fix would be to output the actions separate from the action table and with the
    // table instead
    if (!siaa.action_data_shared_tables(next->table).empty())
        gw_linked = true;
    if (!imem.allocate_imem(next->table, resources->instr_mem, phv, gw_linked)) {
        error_message = "The table " + next->table->name + " could not fit within the "
                        "instruction memory";
        LOG3(error_message);
        resources->instr_mem.clear();
        return false;
    }

    InstructionMemory verify_imem;
    for (auto *p = done; p && p->stage == next->stage; p = p->prev) {
        verify_imem.update(p->name, p->resources, p->table);
    }
    verify_imem.update(next->name, resources, next->table);
    return true;
}

static void coord_selector_xbar(const TablePlacement::Placed *curr,
                                const TablePlacement::Placed *done,
                                TableResourceAlloc *resource,
                                safe_vector<TableResourceAlloc *> &prev_resources) {
    const IR::MAU::Selector *as = nullptr;
    for (auto at : curr->table->attached) {
        if ((as = at->attached->to<IR::MAU::Selector>()) != nullptr) break;
    }
    if (as == nullptr) return;
    auto loc = resource->memuse.find(curr->table->pp_unique_id(as, false, curr->stage_split));
    if (loc == resource->memuse.end() || (loc != resource->memuse.end()
        && !resource->selector_ixbar.use.empty()))
        return;
    int j = 0;
    for (auto *p = done; p && p->stage == curr->stage; p = p->prev) {
        const IR::MAU::Selector *p_as = nullptr;
        if (p == curr) {
            j++;
            continue;
        }
        for (auto back_at : p->table->attached) {
            auto at = back_at->attached;
            if ((p_as = at->to<IR::MAU::Selector>()) != nullptr)
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

static void coord_action_data_xbar(const TablePlacement::Placed *curr,
                                   const TablePlacement::Placed *done,
                                   TableResourceAlloc *resource,
                                   safe_vector<TableResourceAlloc *> &prev_resources) {
    const IR::MAU::ActionData *ad = nullptr;
    for (auto at : curr->table->attached) {
        if ((ad = at->attached->to<IR::MAU::ActionData>()) != nullptr) break;
    }
    if (ad == nullptr) return;
    if (!resource->action_data_xbar.empty())
        return;
    int j = 0;
    for (auto *p = done; p && p->stage == curr->stage; p = p->prev) {
        const IR::MAU::ActionData *p_ad = nullptr;
        if (p == curr) {
            j++;
            continue;
        }
        for (auto back_at : p->table->attached) {
            auto at = back_at->attached;
            if ((p_ad = at->to<IR::MAU::ActionData>()) != nullptr)
                break;
        }
        if (p_ad == ad && !p->resources->action_data_xbar.empty()) {
            resource->action_data_xbar = prev_resources[j]->action_data_xbar;
            resource->instr_mem = prev_resources[j]->instr_mem;
            break;
        }
        j++;
    }
}


bool TablePlacement::initial_stage_and_entries(Placed *rv, const Placed *done,
        int &set_entries, int &furthest_stage) {
    auto *t = rv->table;
    if (t->for_dleft()) {
        const IR::MAU::StatefulAlu *salu = nullptr;
        for (auto *back_at : t->attached) {
            salu = back_at->attached->to<IR::MAU::StatefulAlu>();
            if (salu != nullptr)
                break;
        }
        set_entries = salu->size;
    } else if (t->match_table) {
        if (t->layout.pre_classifier)
            set_entries = t->layout.pre_classifer_number_entries;
        else if (auto k = t->match_table->getConstantProperty("size"))
            set_entries = k->asInt();
        else if (auto k = t->match_table->getConstantProperty("min_size"))
            set_entries = k->asInt();
        if (t->layout.has_range) {
            RangeEntries re(phv, set_entries);
            t->apply(re);
            set_entries = re.TCAM_lines();
        } else if (t->layout.alpm && t->layout.atcam) {
            // According to Henry Wang, alpm requires one extra entry per partition
            set_entries += t->layout.partition_count;
        }
        if (t->layout.exact) {
            if (t->layout.ixbar_width_bits < ceil_log2(set_entries)) {
                set_entries = 1 << t->layout.ixbar_width_bits;
                ::warning("Shrinking table %1%: with %2% match bits, can only have %3% entries",
                          t->name, t->layout.ixbar_width_bits, set_entries);
            }
        }
    }

    int prev_stage_tables = 0;
    for (auto *p = done; p; p = p->prev) {
        if (p->name == rv->name) {
            if (p->need_more == false) {
                BUG(" - can't place %s as its already done");
                return false; }
            set_entries -= p->entries;
            prev_stage_tables++;
            if (p->stage == rv->stage) {
                LOG2("Cannot place multiple sections of an individual table in the same stage");
                rv->stage++;
                continue;
            }
        } else if (p->stage == rv->stage) {
            if (forced_placement)
                continue;
            if (deps->happens_before(p->table, rv->table) && !mutex.action(p->table, rv->table)) {
                rv->stage++;
                LOG2(" - dependency between " << p->table->name << " and table advances stage");
            } else if (rv->gw && deps->happens_before(p->table, rv->gw)) {
                rv->stage++;
                LOG2(" - dependency between " << p->table->name << " and gateway advances stage");
            } else if (deps->container_conflict(p->table, rv->table)) {
                if (!ignoreContainerConflicts) {
                   rv->stage++;
                   LOG2(" - action dependency between " << p->table->name << " and table " <<
                        rv->table->name << " due to PHV allocation advances stage to " <<
                        rv->stage);
                }
            }
        }
    }

    auto stage_pragma = t->get_provided_stage();
    if (stage_pragma >= 0) {
        rv->stage = std::max(stage_pragma, rv->stage);
        furthest_stage = rv->stage + 1;
    } else if (forced_placement && !t->gateway_only()) {
        ::warning("%s: Table %s has not been provided a stage even though forced placement of "
                  "tables is turned on", t->srcInfo, t->name);
    }

    if (prev_stage_tables > 0) {
        rv->initial_stage_split = prev_stage_tables;
        rv->stage_split = prev_stage_tables;
    }

    return true;
}

/** When placing a gateway table, the gateway can potential be combined with a match table
 *  to build one logical table.  The gateway_merge function picks a legal table to place with
 *  this table.  This loops through all possible tables to be merged, and will
 *  return a vector of these possible choices to the is_better function to choose
 */
safe_vector<TablePlacement::Placed *> TablePlacement::try_place_table(const IR::MAU::Table *t,
        const Placed *done, const StageUseEstimate &current) {
    LOG1("try_place_table(" << t->name << ", stage=" << (done ? done->stage : 0) << ")");
    ordered_set<const IR::MAU::Table *> attempted_tables;
    safe_vector<TablePlacement::Placed *> rv_vec;
    while (true) {
        auto *rv = (new Placed(*this, t));
        bool try_allocation = rv->gateway_merge(attempted_tables);
        if (!try_allocation) break;
        rv = try_place_table(rv, t, done, current);
        if (rv == nullptr) {
            rv_vec.clear();
            break;
        }
        rv_vec.push_back(rv);
    }
    return rv_vec;
}


TablePlacement::Placed *TablePlacement::try_place_table(Placed *rv, const IR::MAU::Table *t,
        const Placed *done, const StageUseEstimate &current) {
    auto *min_placed = new Placed(*rv);
    TableResourceAlloc *resources = new TableResourceAlloc;
    TableResourceAlloc *min_resources = new TableResourceAlloc;
    rv->resources = resources;
    safe_vector<TableResourceAlloc *> prev_resources;
    error_message = "";
    for (auto *p = done; p && p->stage == done->stage; p = p->prev) {
        prev_resources.push_back(p->resources->clone_ixbar());
    }
    t = rv->table;
    rv->stage = done ? done->stage : 0;
    int furthest_stage = (done == nullptr) ? 0 : done->stage + 1;
    int set_entries = 512;
    if (!initial_stage_and_entries(rv, done, set_entries, furthest_stage)) {
        return nullptr;
    }


    LOG3("Initial stage is " << rv->stage);

    min_placed->entries = 1;

    assert(!rv->placed[tblInfo.at(rv->table).uid]);
    const safe_vector<LayoutOption> layout_options = lc.get_layout_options(t);
    StageUseEstimate stage_current = current;
    // According to the driver team, different stage tables can have different action
    // data allocations, so the algorithm doesn't have to prefer this allocation across
    // stages
    // StageUseEstimate min_use(t, min_entries, &lc, stage_current.shared_attached);

    bool allocated = false;


    min_placed->stage = rv->stage;
    min_placed->initial_stage_split = rv->initial_stage_split;
    min_placed->stage_split = rv->stage_split;

    if (done && rv->stage != done->stage)
        stage_current.clear();

    /* Loop to find the right size of entries for a table to place into stage */
    do {
        rv->need_more = false;
        rv->entries = set_entries;
        auto avail = StageUseEstimate::max();
        bool advance_to_next_stage = false;
        allocated = false;
        rv->use = StageUseEstimate(t, rv->entries, &lc, stage_current.shared_attached);
        if (t->for_dleft() && set_entries > rv->entries) {
            advance_to_next_stage = true;
            LOG3("Cannot split a dleft hash table");
        }

        // FIXME: This is not the appropriate way to check if a table is a single gateway

        if (!pick_layout_option(min_placed, done, min_resources, stage_current.shared_attached)) {
            advance_to_next_stage = true;
            LOG3("Min Use ixbar allocation did not fit");
        }

        if (!pick_layout_option(rv, done, resources, stage_current.shared_attached)) {
            advance_to_next_stage = true;
            LOG3("Table Use ixbar allocation did not fit");
        }

        if (!advance_to_next_stage
            && (!(min_placed->use + stage_current <= avail)
                || !try_alloc_mem(min_placed, done, min_resources, prev_resources))) {
            advance_to_next_stage = true;
            LOG3("Min use of memory allocation did not fit");
        }

        // FIXME: Min Use vs. Normal Use may be very different, have to fold this into
        // the code better
        if (!advance_to_next_stage &&
            !try_alloc_adb(min_placed, done, min_resources)) {
            advance_to_next_stage = true;
            LOG3("Min use of action data bus did not fit");
        }

        if (!advance_to_next_stage &&
            !try_alloc_adb(rv, done, resources)) {
            advance_to_next_stage = true;
            LOG3("Normal use of action data bus did not fit");
        }

        if (!advance_to_next_stage &&
            !try_alloc_imem(min_placed, done, min_resources)) {
            advance_to_next_stage = true;
            LOG3("Min use of instruction memory did not fit");
        }

        if (!advance_to_next_stage &&
            !try_alloc_imem(rv, done, resources)) {
            advance_to_next_stage = true;
            LOG3("Normal use of instruction memory did not fit");
        }

        if (done && rv->stage == done->stage) {
            avail.srams -= stage_current.srams;
            avail.tcams -= stage_current.tcams;
            avail.maprams -= stage_current.maprams; }

        int srams_left = avail.srams;
        int tcams_left = avail.tcams;
        // If the max needed entries do not fit, shrink the table given the number of available
        // rams until the table is able to be placed
        while (!advance_to_next_stage &&
               (!(rv->use <= avail) ||
               (allocated = try_alloc_mem(rv, done, resources, prev_resources)) == false)) {
            if (!shrink_estimate(rv, done, resources, srams_left, tcams_left,
                                 min_placed->entries)) {
                advance_to_next_stage = true;
                break;
            }

            if (rv->entries < set_entries) {
                rv->need_more = true;
                // If the table is split for the first time, then the stage_split is set to 0
                if (rv->initial_stage_split == -1)
                    rv->stage_split = 0;
            }

            if (!try_alloc_adb(rv, done, resources)) {
                ERROR("Action Data Bus Allocation error after previous allocation?");
                advance_to_next_stage = true;
                break;
            }

            if (!try_alloc_imem(rv, done, resources)) {
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
        }
    } while (!allocated && rv->stage <= furthest_stage);


    if (!t->gateway_only()) {
        auto format = rv->use.preferred_action_format();
        BUG_CHECK(format != nullptr, "Action format could not be found for a particular layout "
                  "option.");
        resources->action_format = *format;
    }

    LOG3("Selected stage: " << rv->stage << "    Furthest stage: " << furthest_stage);
    if (rv->stage > furthest_stage) {
        if (error_message != "")
            BUG("Could not place table : %s", error_message);
        BUG("Unknown error for stage advancement?");
    }

    if (done && done->stage == rv->stage) {
        if (done->table->gateway_only())
            rv->logical_id = done->logical_id + 1;
        else
            rv->logical_id = done->logical_id + done->use.preferred()->logical_tables();
    } else {
        rv->logical_id = rv->stage * StageUse::MAX_LOGICAL_IDS;
    }

    assert((rv->logical_id / StageUse::MAX_LOGICAL_IDS) == rv->stage);
    LOG2("try_place_table returning " << rv->entries << " of " << rv->name <<
         " in stage " << rv->stage << (rv->need_more ? " (need more)" : ""));
    int i = 0;
    for (auto *p = done; p && p->stage == rv->stage; p = p->prev) {
        coord_selector_xbar(p, done, prev_resources[i], prev_resources);
        coord_action_data_xbar(p, done, prev_resources[i], prev_resources);
        i++;
    }
    coord_selector_xbar(rv, done, resources, prev_resources);
    coord_action_data_xbar(rv, done, resources, prev_resources);
    if (done && rv->stage == done->stage) {
        rv->set_prev(done, true, prev_resources);
    } else {
        rv->set_prev(done, false, prev_resources);
    }

    if (!rv->need_more) {
        rv->placed[tblInfo.at(rv->table).uid] = true;
        if (rv->gw)
            rv->placed[tblInfo.at(rv->gw).uid] = true;
    } else {
        int extra_entries = set_entries - rv->entries;
        rv->extra_use = StageUseEstimate(t, extra_entries, &lc);
    }

    return rv;
}

const TablePlacement::Placed *
TablePlacement::place_table(ordered_set<const GroupPlace *>&work, const Placed *pl) {
    LOG1("placing " << pl->entries << " entries of " << pl->name << (pl->gw ? " (with gw " : "") <<
         (pl->gw ? pl->gw->name : "") << (pl->gw ? ")" : "") << " in stage " <<
         pl->stage << (pl->need_more ? " (need more)" : ""));

    if (pl->table->get_provided_stage() >= 0 && pl->table->get_provided_stage() != pl->stage)
        ::warning("%s: The stage specified for the table %s is %d, but the stage actually "
                  "allocated %d are not the same", pl->table->srcInfo, pl->table->name,
                  pl->table->get_provided_stage(), pl->stage);

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
                    BUG_CHECK(!found_match && !gw_match_grp, "No table to place");
                    BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                              "multi-referenced table");
                    found_match = true;
                    continue; }
                GroupPlace *g = ready ? new GroupPlace(*this, work, parents, n) : nullptr;
                for (auto t : n->tables) {
                    if (t == pl->table) {
                        BUG_CHECK(!found_match && !gw_match_grp, "No table to place");
                        BUG_CHECK(ready && parents.size() == 1, "Gateway incorrectly placed on "
                                  "multi-referenced table");
                        found_match = true;
                        gw_match_grp = g; } } }
            BUG_CHECK(found_match, "Failed to find match table"); }
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


bool TablePlacement::is_better(const Placed *a, const Placed *b, choice_t& choice) {
    const IR::MAU::Table *a_table_to_use = a->gw ? a->gw : a->table;
    const IR::MAU::Table *b_table_to_use = b->gw ? b->gw : b->table;

    LOG4("        Stage A is " << a->name << " with deps tail control " <<
        deps->dependence_tail_size_control(a_table_to_use) <<
        ", deps tail " << deps->dependence_tail_size(a_table_to_use) << ", total deps " <<
        deps->happens_before_dependences(a_table_to_use).size() << ", calculated stage " <<
        a->stage << ", and provided stage " << a->table->get_provided_stage());
    LOG4("        Stage B is " << b->name << " with deps tail control " <<
        deps->dependence_tail_size_control(b_table_to_use) <<
        ", deps tail " << deps->dependence_tail_size(b_table_to_use) << ", total deps " <<
        deps->happens_before_dependences(b_table_to_use).size() << ", calculated stage " <<
        b->stage << ", and provided stage " << b->table->get_provided_stage());

    choice = CALC_STAGE;
    if (a->stage < b->stage) return true;
    if (a->stage > b->stage) return false;

    choice = PROV_STAGE;
    int a_provided_stage = a->table->get_provided_stage();
    int b_provided_stage = b->table->get_provided_stage();

    if (a_provided_stage >= 0 && b_provided_stage >= 0) {
        if (a_provided_stage != b_provided_stage)
            return a_provided_stage < b_provided_stage;
    } else if (a_provided_stage >= 0 && b_provided_stage < 0) {
        return true;
    } else if (b_provided_stage >= 0 && a_provided_stage < 0) {
        return false;
    }

    choice = NEED_MORE;
    if (b->need_more && !a->need_more) return true;
    if (a->need_more && !b->need_more) return false;
    // FIXME: This feels like it shouldn't work but is does, keeping the old code around
    // as documentation
    int a_extra_stages = 0;  // a->need_more ? a->extra_use.stages_required() : 0;
    int b_extra_stages = 0;  // b->need_more ? b->extra_use.stages_required() : 0;

    int a_deps_stages_control = deps->dependence_tail_size_control(a_table_to_use) + a_extra_stages;
    int b_deps_stages_control = deps->dependence_tail_size_control(b_table_to_use) + b_extra_stages;



    choice = DEP_TAIL_SIZE_CONTROL;
    if (a_deps_stages_control > b_deps_stages_control) return true;
    if (a_deps_stages_control < b_deps_stages_control) return false;

    int a_deps_stages = deps->dependence_tail_size(a_table_to_use) + a_extra_stages;
    int b_deps_stages = deps->dependence_tail_size(b_table_to_use) + b_extra_stages;

    choice = DEP_TAIL_SIZE;
    if (a_deps_stages > b_deps_stages) return true;
    if (a_deps_stages < b_deps_stages) return false;

    choice = TOTAL_DEPS;
    int a_total_deps = deps->happens_before_dependences(a_table_to_use).size() + a_extra_stages;
    int b_total_deps = deps->happens_before_dependences(b_table_to_use).size() + b_extra_stages;
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

IR::Node *TablePlacement::preorder(IR::BFN::Pipe *pipe) {
    LOG1("table placement starting");
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread) );
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
    if (pipe->ghost_thread && pipe->ghost_thread->tables.size() > 0) {
        pipe->ghost_thread->apply(SetupInfo(*this));
        new GroupPlace(*this, work, {}, pipe->ghost_thread); }
    ordered_set<const IR::MAU::Table *> partly_placed;
    while (!work.empty()) {
        LOG3("stage " << (placed ? placed->stage : 0) << ", work: " << work <<
             ", partly placed " << partly_placed.size() << ", placed " << count(placed));
        StageUseEstimate current = get_current_stage_use(placed);
        safe_vector<const Placed *> trial;
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
                LOG3("Group table: " << t->name);
            }
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

                bool should_skip = false;
                for (auto& grp_tbl : grp->seq->tables) {
                    if (deps->happens_before_control(t, grp_tbl) &&
                        (!placed || !(placed->is_placed(grp_tbl)))) {
                        should_skip = true;
                        LOG1(" - skipping " << t->name << " due to in-sequence control" <<
                            " dependence on " << grp_tbl->name);
                        break;
                    }
                }
                if (should_skip)
                    continue;

                auto pl_vec = try_place_table(t, placed, current);
                if (pl_vec.empty())
                    BUG("Can't find a table to place");

                for (auto pl : pl_vec) {
                    LOG3("Pl vector: " << pl->name);
                }

                for (auto pl : pl_vec) {
                    pl->group = grp;
                    bool defer = false;
                    for (auto t : partly_placed) {
                        if (t == pl->table)
                            continue;
                        if (!mutex(t, pl->table)) {
                            LOG3(" - skipping " << pl->name << " as it is not mutually "
                                 "exclusive with partly placed " << t->name);
                            defer = true;
                            break;
                        }
                    }
                    if (!defer) {
                        done = false;
                        trial.push_back(pl);
                    }
                }
            }
            if (done) {
                BUG_CHECK(!placed->is_fully_placed(grp->seq), "Can't find a table to place");
                it = work.erase(it);
            } else {
                it++; } }
        if (work.empty()) break;
        if (trial.empty())
            BUG("No tables placeable, but not all tables placed?");
        LOG2("found " << trial.size() << " tables that could be placed: " << trial);
        const Placed *best = 0;
        choice_t choice = DEFAULT;
        for (auto t : trial) {
            if (!best || is_better(t, best, choice)) {
                log_choice(t, best, choice);
                best = t;
            }
        }
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

/* Human-readable strings for the choice_t enum used to return
 * is_better decision info.
 */
std::ostream &operator<<(std::ostream &out, TablePlacement::choice_t choice) {
    static const char* choice_names[] = { "earlier stage calculated", "earlier stage provided",
                                    "more stages needed", "longer control-included"
                                    " dependence tail chain", "longer control-excluded dependence"
                                    " tail chain", "fewer total dependencies", "default choice" };
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
    } else {
        LOG3("    Updating best to " << t->name << " from " << best->name
             << " for reason: " << choice);
    }
}

IR::Node *TablePlacement::postorder(IR::BFN::Pipe *pipe) {
    tblInfo.clear();
    seqInfo.clear();
    table_placed.clear();
    LOG3("table placement completed");
    LOG3(TableTree("ingress", pipe->thread[INGRESS].mau) <<
         TableTree("egress", pipe->thread[EGRESS].mau) <<
         TableTree("ghost", pipe->ghost_thread));
    return pipe;
}

static void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *resources,
                                int entries) {
    tbl->resources = resources;
    tbl->layout.entries = entries;
    if (!tbl->ways.empty()) {
        auto &mem = resources->memuse.at(tbl->unique_id());
        if (!tbl->layout.atcam) {
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
static void add_attached_tables(IR::MAU::Table *tbl, const LayoutOption *layout_option) {
    if ((!layout_option->layout.no_match_data() &&
        layout_option->layout.ternary_indirect_required())
        || layout_option->layout.no_match_miss_path()) {
        LOG3("  Adding Ternary Indirect table to " << tbl->name);
        auto *tern_indir = new IR::MAU::TernaryIndirect(tbl->name);
        tbl->attached.push_back(new IR::MAU::BackendAttached(tern_indir->srcInfo, tern_indir));
    }
    if (layout_option->layout.direct_ad_required()) {
        LOG3("  Adding Action Data Table to " << tbl->name);
        cstring ad_name = tbl->name + "$action";
        auto *act_data = new IR::MAU::ActionData(IR::ID(ad_name));
        act_data->direct = true;
        tbl->attached.push_back(new IR::MAU::BackendAttached(act_data->srcInfo, act_data));
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
    for (int lt = 0; lt < logical_tables; lt++) {
        auto *table_part = tbl->clone();
        // Clear gateway_name for the split tables
        if (lt != 0)
            table_part->gateway_name = cstring();
        table_part->logical_id = placed->logical_id + lt;
        table_part->logical_split = lt;
        table_part->logical_tables_in_stage = logical_tables;
        if (lt != 0) {
            tbl->gateway_rows.clear();
        }
        int entries = placed->use.preferred()->partition_sizes[lt] * Memories::SRAM_DEPTH;
        table_set_resources(table_part, placed->resources->clone_rename(tbl, stage_table, lt),
                            entries);  // table_part->ways[0].entries);
        if (!rv) {
            rv = table_part;
            assert(!prev);
        } else {
            for (auto &gw : table_part->gateway_rows)
                table_part->next.erase(gw.second);
            table_part->gateway_rows.clear();
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

    for (int lt = 0; lt < logical_tables; lt++) {
        auto *table_part = tbl->clone();

        if (lt != 0)
            table_part->gateway_name = cstring();
        table_part->logical_id = placed->logical_id + lt;
        table_part->logical_split = lt;
        table_part->logical_tables_in_stage = logical_tables;
        if (lt != 0)
            tbl->gateway_rows.clear();

        const IR::MAU::StatefulAlu *salu = nullptr;
        for (auto back_at : tbl->attached) {
            salu = back_at->attached->to<IR::MAU::StatefulAlu>();
            if (salu != nullptr)
                break;
        }
        int per_row = RegisterPerWord(salu);
        int entries = placed->use.preferred()->dleft_hash_sizes[lt] * Memories::SRAM_DEPTH
                      * per_row;
        table_set_resources(table_part, placed->resources->clone_rename(tbl, stage_table, lt),
                            entries);
        if (lt != logical_tables - 1)
            table_part->next.clear();

        dleft_vector->push_back(table_part);
    }
    return dleft_vector;
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
    BUG_CHECK(it != table_placed.end(), "Trying to place a table %s that was never placed",
              tbl->name);
    if (tbl->is_placed()) {
        BUG_CHECK(tbl->stage_split >= 0 || tbl->logical_split >= 0,
                  "Trying to place a table %s that is already placed", tbl->name);
        return tbl;
    }
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
        for (auto &gw : tbl->gateway_rows)
            if (gw.second == it->second->gw_result_tag)
                gw.second = cstring();
        tbl->match_table = match->match_table;
        tbl->match_key = match->match_key;
        tbl->actions = match->actions;
        tbl->attached = match->attached;

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
            add_attached_tables(tbl, it->second->use.preferred());
            if (gw_layout_used)
                tbl->layout += gw_layout;
        }
        if (tbl->layout.atcam)
            return break_up_atcam(tbl, it->second);
        else if (tbl->for_dleft())
            return break_up_dleft(tbl, it->second);
        else
            table_set_resources(tbl, it->second->resources, it->second->entries);
        return tbl;
    }
    int stage_table = 0;
    IR::MAU::Table *rv = 0, *prev = 0;
    IR::MAU::Table *atcam_last = nullptr;
    /* split the table into multiple parts per the placement */
    LOG1("splitting " << tbl->name << " across " << table_placed.count(tbl->name) << " stages");
    for (it = table_placed.find(tbl->name); it->first == tbl->name; it++) {
        auto *table_part = tbl->clone();
        // When a gateway is merged against a split table, only the first table created from the
        // split must have the name of the merged gateway
        if (stage_table != 0)
            table_part->gateway_name = cstring();
        BUG_CHECK(stage_table == it->second->stage_split, "Splitting table %s cannot be resolved",
                  "for stage table %d", table_part->name, stage_table);
        select_layout_option(table_part, it->second->use.preferred());
        add_attached_tables(table_part, it->second->use.preferred());
        if (gw_layout_used)
            table_part->layout += gw_layout;
        table_part->logical_id = it->second->logical_id;
        table_part->stage_split = stage_table;

        if (table_part->layout.atcam) {
            table_part = break_up_atcam(table_part, it->second, stage_table, &atcam_last);
        } else {
            table_set_resources(table_part, it->second->resources->clone_rename(tbl, stage_table),
                                it->second->entries);
        }
        if (!rv) {
            rv = table_part;
            assert(!prev);
        } else {
            for (auto &gw : table_part->gateway_rows)
                table_part->next.erase(gw.second);
            table_part->gateway_rows.clear();

            // FIXME: Long term solution could be the following for these types of actions:
            //    - Clone all actions and set them all to hit_only
            //    - Create a noop action as miss_only
            //    - Get rid of the $try_next_stage and just go through the standard hit/miss
            // Separate control flow processing for try_next_stage vs miss"
            prev->next["$try_next_stage"] = new IR::MAU::TableSeq(table_part);
            prev->next.erase("$miss");
        }
        stage_table++;
        prev = table_part;
        if (atcam_last)
            prev = atcam_last;
    }
    assert(rv);
    return rv;
}

IR::Node *TablePlacement::preorder(IR::MAU::BackendAttached *ba) {
    auto tbl = findContext<IR::MAU::Table>();
    auto format = tbl->resources->table_format;

    if (ba->attached->is<IR::MAU::Counter>()) {
        if (format.stats_pfe_loc == IR::MAU::PfeLocation::OVERHEAD)
            ba->pfe_location = format.stats_pfe_loc;
    } else if (ba->attached->is<IR::MAU::Meter>() || ba->attached->is<IR::MAU::StatefulAlu>() ||
            ba->attached->is<IR::MAU::Selector>()) {
        if (format.meter_pfe_loc == IR::MAU::PfeLocation::OVERHEAD)
            ba->pfe_location = format.meter_pfe_loc;
        if (format.meter_type_loc == IR::MAU::TypeLocation::OVERHEAD)
            ba->type_location = format.meter_type_loc;
    }
    return ba;
}

IR::Node *TablePlacement::preorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() > 1) {
        std::sort(seq->tables.begin(), seq->tables.end(),
            [this](const IR::MAU::Table *a, const IR::MAU::Table *b) -> bool {
                int a_logical_id = find_placed(a->name)->second->logical_id;
                int b_logical_id = find_placed(b->name)->second->logical_id;
                if (a_logical_id != b_logical_id)
                    return a_logical_id < b_logical_id;
                return a->logical_split < b->logical_split;
        });
    }
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
