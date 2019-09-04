#include "jbay_next_table.h"
#include <unordered_map>
#include <unordered_set>
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_layout.h"
#include "device.h"
#include "lib/error.h"
#include "bf-p4c/common/table_printer.h"


/* This pass calculates 2 data structures used during assembly generation:
 *   1. ~props~ specifies a set of tables to be run after a given table is applied and a certain
 *      condition is met. This specifies how the next table "signal" propagtes through tables at
 *      runtime.  More specifically, for a given table and a given table sequence owned by that
 *      table, it specifies the set of table that are to run under that table sequence's
 *      condition.   The NextTable object captures one table that needs to be run and how that
 *      signal is propagate to it (either by LOCAL_EXEC, GLOBAL_EXEC, or LONG_BRANCH).  The pass
 *      is split into 3 stages: EmptyIds, NextTableAlloc, and AddDummyTables (which must run in that
 *      order).
 *   2. ~lbs~ specifies the long branch tags that a source table needs to set and which tables need
 *      to be associated with each tag. This is necessary to generate the correct ASM, although
 *      effectively captures similar information in props, just in a format that is more usable in
 *      assembly generation.
 *
 * AT A GLANCE:
 *
 * 1. Prop calculates the ~props~ map. It does so according to push-down, as described in the
 *    optimizations section. Additionally, it collects a lot of data that is used throughout the
 *    rest of the pass. In building the ~props~ map, it builds the information needed to run
 *    LBAlloc, the next pass. Furthermore, it finds which tables are to be set to always run, which
 *    is then added by TagReduce.
 *
 * 2. LBAlloc doesn't really need to be a pass, as it does not actually iterate over the graph. In
 *    the init_apply, it takes the data captured by Prop and allocates all of the long branch uses
 *    into tags.
 *
 * 3. TagReduce is responsible for two things: (1) setting always run on tables; and (2) reducing
 *    the number of long branch tags to a level that is supported by the device. It accomplishes (2)
 *    by adding dumb tables, as described below. If it is able to merge tags, it sets Prop and
 *    LBAlloc to run again.
 *
 * Passes are run in order: Prop, LBAlloc, TagReduce, Prop (if needed), LBAlloc (if needed). Prop
 * and LBAlloc are only repeated if TagReduce reduced the number of tags.
 *
 * OPTIMIZATIONS:
 *
 * This pass attempts to minimize the use of long branches wherever possible, as LOCAL_EXEC and
 * GLOBAL_EXEC are effectively unlimited. This is accomplished via push-down, which achieves a
 * minimal usage of long branches for a given table placement. Unoptimized NTP would use a long
 * branch across an entire table sequence if *any* of the tables in the sequence were placed 2
 * stages or later. The following example will be used to illustrate these optimizations:
 *
 *                    t3       t5     t7
 *              t  t1 t2       t4     t6  t8        TABLES
 * -----------------------------------------------
 *  0  1  2  3  4  5  6  7  8  9  10  11  12 (...)  STAGES
 *              |                          |
 *         first_stage                 last_stage
 *
 * where t is the parent table and t1-t8 are the tables in one of its table sequences (e.g. $miss).
 *
 * 1. Next table push-down: Tables in a table sequence may be made responsible for propagating next
 *    table signals from their parent. Unoptimized NTP would run a long branch from table t in stage
 *    4 to stage 11, setting t1 through t8 to run off that long branch. With push-down, NTP becomes
 *    as follows:
 *
 *    +----+----+---------------------+
 *    | 05 | t1 | global_exec from t  |
 *    +----+----+---------------------+
 *    | 06 | t2 | global_exec from t1 |
 *    | 06 | t3 | local_exec from t2  |
 *    +----+----+---------------------+
 *    | 09 | t4 | long_branch from t2 |
 *    | 09 | t5 | local_exec from t4  |
 *    +----+----+---------------------+
 *    | 11 | t6 | long_branch from t4 |
 *    | 11 | t7 | local_exec from t6  |
 *    +----+----+---------------------+
 *    | 12 | t8 | global_exec from t6 |
 *    +----+----+---------------------+
 *
 *    This limits long_branch usage to stage 6 to 9 and 9 to 11. Notice how our parent table t is
 *    now only responsible for propagating the signal to t1, which then propagates the signal to t2,
 *    etc. This functionality is accomplished by adding a $run_if_ran "branch" (a sort of fake table
 *    sequence). The $run_if_ran branch for a table t is a set of tables that should be run whenever
 *    t is run. During assembly generation, tables in $run_if_ran are added to every other table
 *    sequence.
 *
 * 2. Tag allocation: Once we have our uses, we must allocate them into tags. Tags can be used for
 *    multiple long branches as long as the live ranges do not overlap. If the uses are on different
 *    gresses, there is an additional restriction that there must be a 1 stage gap between the two
 *    uses, to account for the different timings of the gresses. See below for a clarifying example.
 *
 *       0  1  2  3  4  5  6  7  8  9
 *    0  |--------|-----|             <--- Tightest merge when two uses are on same gress
 *    1  |========|  |--------|       <--- Tightest merge when two uses are on different gresses
 *                ^^^^ Single stage bubble for timing
 *
 * 3. Add dumb tables: Inject tables that do nothing more than propagate a global exec signal. This
 *    is the most aggressive optimization, often capable of entirely eliminating long branches. When
 *    a stage that has no tables from this table sequence is also not completely full, we inject a
 *    dumb table into it and use global exec instead. For sake of argument, suppose that stages 7
 *    and 10 are not full (unused logical IDs) but stage 8 is full. The resulting NTP is as follows:
 *
 *    +----+----+---------------------+
 *    | 05 | t1 | global_exec from t  |
 *    +----+----+---------------------+
 *    | 06 | t2 | global_exec from t1 |
 *    | 06 | t3 | local_exec from t2  |
 *    +----+----+---------------------+
 *    | 07 | d1 | global_exec from t2 | <--- new dumb table added!
 *    +----+----+---------------------+
 *    | 09 | t4 | long_branch from d1 | <--- long branch comes from d1, not t2!
 *    | 09 | t5 | local_exec from t4  |
 *    +----+----+---------------------+
 *    | 10 | d2 | global_exec from t4 | <--- new dumb table added!
 *    +----+----+---------------------+
 *    | 11 | t6 | global_exec from d2 | <--- global exec from d2 instead of long branch from t2
 *    | 11 | t7 | local_exec from t6  |
 *    +----+----+---------------------+
 *    | 12 | t8 | global_exec from t6 |
 *    +----+----+---------------------+
 *
 *    Note how in this version we got rid of the second long branch entirely and were able to
 *    shorten the first long branch by 1 stage. However, this optimization comes at a cost of adding
 *    logical IDs, which may be a precious resource. As such, the TagReduce algorithm only performs
 *    dumb table injection when the number of tags has exceeded the device limits. Additionally, it
 *    attempts to find an injection that uses the fewest number of tables possible. See merging
 *    methods in TagReduce for full algorithm.
 *
 */

/*
*/

/* Holds next table prop information for a specific table sequence. One created per call to
 * add_table_seq. Note that add_table_seq may be called on the same table sequence multiple times,
 * as table sequences can both be (1) under the same table multiple times (multiple actions run the
 * same tables); (2) under different tables. In the case of (1), we do not need to run it twice, but
 * do so right now out of convenience. In the case of (2), we do need to run it multiple times,
 * since the NTP needs to be associated with different tables. */
struct NextTable::Prop::NTInfo {
    const IR::MAU::Table* parent;  // Origin of this control flow
    dyn_vector<dyn_vector<const IR::MAU::Table*>> stages;  // Tables in each stage
    const int first_stage;
    int last_stage;
    const cstring seq_nm;  // Name of the table sequence
    const IR::MAU::TableSeq* ts;

    NTInfo(const IR::MAU::Table* tbl, std::pair<cstring, const IR::MAU::TableSeq*> seq)
            : parent(tbl), first_stage(tbl->stage()), seq_nm(seq.first), ts(seq.second) {
        LOG1("NTP for " << tbl->name << " and sequence "
             << seq.first << ":");
        last_stage = tbl->stage();
        BUG_CHECK(first_stage >= 0, "Unplaced table %s", tbl->name);

        // Collect tables into stages for this sequence
        for (auto t : ts->tables) {
            auto st = t->stage();
            BUG_CHECK(st >= 0, "Unplaced table %s", t->name);
            BUG_CHECK(first_stage <= st, "Table %s (LID: %d) placed before parent %s (LID: %d)",
                      t->name, t->logical_id, tbl->name, tbl->logical_id);
            // Update last stage
            last_stage = st > last_stage ? st : last_stage;
            // Add to the correct vector
            stages[st].push_back(t);
        }
    }
};

// Checks if there is any overlap between two tags
bool NextTable::LBUse::operator&(const LBUse& r) const {
    BUG_CHECK(fst <= lst && r.fst <= r.lst, "LBUse first and last have been corrupted!");
    if ((lst - fst) < 2 || (r.lst - r.fst) < 2)
        return false;
    else if (thread() == r.thread())
        return !(fst >= r.lst || lst <= r.fst);
    else
        return !(fst > r.lst || lst < r.fst);
}

void NextTable::LBUse::extend(const IR::MAU::Table* t) {
    ssize_t st = t->stage();
    BUG_CHECK(ssize_t(st) < lst, "Table %s trying to long branch to earlier stage!", t->name);
    BUG_CHECK(multiply_applied, "Table %1% requires more than one long branch pathways is only "
                                "applied once?", t->name);
    // If tables are in the same stage, we don't need to do anything
    if (st == fst) return;
    fst = st < fst ? st : fst;
}

bool NextTable::Tag::add_use(const LBUse& lbu) {
    for (auto u : uses)
        if (u & lbu) return false;
    uses.push_back(lbu);
    return true;
}

NextTable::profile_t NextTable::Prop::init_apply(const IR::Node* root) {
    if (!self.rebuild) return MauInspector::init_apply(root);  // Early exit
    // Clear maps, since we have to rebuild them
    self.props.clear();
    self.stage_id.clear();
    self.lbus.clear();
    self.dest_src.clear();
    self.dest_ts.clear();
    self.al_runs.clear();
    self.max_stage = 0;
    LOG1("BEGINNING NEXT TABLE PROPAGATION");
    return MauInspector::init_apply(root);
}

bool NextTable::Prop::preorder(const IR::BFN::Pipe*) {
    return self.rebuild;
}

void NextTable::Prop::local_prop(const NTInfo& nti) {
    // Add tables that are in the same stage as the parent to the parent's set of LOCAL_EXEC tables
    // for the given sequence
    if (size_t(nti.first_stage) >= nti.stages.size()) return;
    for (auto nt : nti.stages.at(nti.first_stage)) {
        BUG_CHECK(nti.parent->logical_id <= nt->logical_id,
                  "Table %s has LID %d, less than parent table %s (LID %d)", nt->name,
                  nt->logical_id, nti.parent->name, nti.parent->logical_id);
        LOG3("  - " << nt->name << " to " << nti.seq_nm << "; LOCAL_EXEC from " << nti.parent->name
             << " in stage " << nt->stage());
        self.props[get_uid(nti.parent)][nti.seq_nm].insert(get_uid(nt));
    }
    // Vertically compress each stage; i.e. calculate all of the local_execs, giving us a single
    // representative table for each stage to use in cross stage propagation
    for (int i = nti.first_stage + 1; i <= nti.last_stage && size_t(i) < nti.stages.size(); ++i) {
        auto& tables = nti.stages.at(i);
        if (tables.empty()) continue;  // Skip empty stages

        // Tables should be in logical ID order. The "representative" table (lowest LID) for this
        // stage and its set of $run_if_ran tables
        auto rep = tables.at(0);
        auto& r_i_r = self.props[get_uid(rep)]["$run_if_ran"];
        for (auto nt : tables) {
            // Skip the representative
            if (nt == rep) continue;
            BUG_CHECK(rep->logical_id < nt->logical_id,
                      "Tables not in logical ID order; representative %s has greater LID than %s.",
                      rep->name, nt->name);
            LOG3("  - " << nt->name << " on $run_if_ran; LOCAL_EXEC from " << rep->name
                 << " in stage " << nt->stage());
            r_i_r.insert(get_uid(nt));
        }
    }
}

void NextTable::Prop::cross_prop(const NTInfo& nti) {
    auto stages = nti.stages;
    auto prev_t = nti.parent;  // The table from which we will propagate
    int prev_st = nti.first_stage;  // The stage that prev_t is in
    cstring branch = nti.seq_nm;  // The name of the seq branch. Will be $run_if_ran after parent

    for (int i = nti.first_stage + 1; i <= nti.last_stage; ++i) {
        if (stages[i].empty()) continue;
        BUG_CHECK(prev_st < i, "Previous is not previous!");
        // The representative for this stage that will receive (and pass) cross-stage propagation
        auto rep = stages[i][0];

        // Logging
        if (prev_st == i-1) {  // Global exec
            LOG3("  - " << rep->name << " on " << branch
                 << "; GLOBAL_EXEC from " << prev_t->name << " on range [" << prev_st << " -- "
                 << i << "]");
        } else {  // Long branch
            BUG_CHECK(prev_t->stage() + 1 < rep->stage(),
                      "LB used between %s in stage %d and %s in stage %d!",
                      prev_t->name, prev_t->stage(), rep->name, rep->stage());
            LOG3("  - " << rep->name << " on " << branch
                 << "; LONG_BRANCH from " << prev_t->name << " on range [" << prev_st << " -- "
                 << i << "]");
            if (self.lbus.count(LBUse(rep))) {  // If we already have an lb for this dest, extend it
                auto it = self.lbus.find(LBUse(rep));
                auto lb = *it;
                self.lbus.erase(it);
                lb.extend(prev_t);
                self.lbus.insert(lb);
            } else {  // Otherwise, create a new LBUse
                self.lbus.insert(
                    LBUse(rep, prev_st, i, self.multi_applies.multi_applied_table(rep)));
            }
            self.dest_src[get_uid(rep)].insert(get_uid(prev_t));
            self.dest_ts[get_uid(rep)] = nti.ts;
        }
        // Add to the propagation map for asm gen
        self.props[get_uid(prev_t)][branch].insert(get_uid(rep));
        // Update previous
        prev_t = rep;
        prev_st = i;
        branch = "$run_if_ran";
    }
}

bool NextTable::Prop::preorder(const IR::MAU::Table* t) {
    int st = t->stage();
    self.max_stage = st > self.max_stage ? st : self.max_stage;
    self.mems[st].update(t->resources->memuse);
    if (t->logical_id > self.stage_id[st])
        self.stage_id[st] = t->logical_id;
    if (!findContext<IR::MAU::Table>())
        self.al_runs.insert(t->unique_id());
    // Add all of the table's table sequences
    for (auto ts : t->next) {
        NTInfo nti(t, ts);
        local_prop(nti);
        cross_prop(nti);
    }
    return true;
}

void NextTable::Prop::end_apply() {
    for (int i = 0; i < self.max_stage; ++i) {  // Fix up stage_id
        if (self.stage_id[i] < i * Memories::LOGICAL_TABLES)
            self.stage_id[i] = i * Memories::LOGICAL_TABLES;
        else
            self.stage_id[i]++;  // Collected max, but need next open one
    }
    if (!self.rebuild) return;
    LOG1("FINISHED NEXT TABLE PROPAGATION");
}


/**
 * Currently, a compiler limitation in the compiler restricts certain long branches from
 * being reduced via dummy tables.
 *
 * Let's use the following example:
 *
 *    if (t1.apply().hit) {
 *         t3.apply();
 *    } else if (t2.apply().hit) {
 *         t3.apply();
 *    }
 *
 * In this example, t3 is applied twice.  Let's use the following placement:
 *
 *     t1    t2          t3           TABLES
 * -----------------------------------------------
 *  0  1  2  3  4  5  6  7  8  (...)  STAGES
 *     |                 |
 * first_stage       last_stage
 *
 *
 * Now if this was to be dummy tabled, the dummy tables would have to range from stage 2
 * to stage 6.
 *
 * The original table sequence graph is:
 *
 *    t1    t2
 *     \    |
 *      \   |
 *  $hit \  | $hit
 *        \ |
 *         t3 
 *
 * is now replaced by
 *
 *     t1    t2
 *      |    /
 *      |   /
 * $hit |  / $hit
 *      | /    
 *     [ dummy2, dummy3, dummy4, dummy5, dummy6, t3]
 *
 * But this is illegal, as t2 would happen after dummy2 logical but precedes it in the
 * table sequence.
 *
 * The TableGraph IR solution would be:
 *     t1
 *      |
 *      | 
 * $hit |
 *      |    
 *    [ dummy2, dummy3 ]    t2
 *                  |       /
 *         $default |      /
 *                  |     / $hit
 *                  |    /
 *                [ dummy4, dummy5, dummy6, t3]
 *
 * but currently the long branch allocation does not have support for this, so we just prevent
 * it from being dummy tabled.
 */
bool NextTable::MultiAppliedTables::preorder(const IR::MAU::Table *tbl) {
    if (tables_visited.count(tbl))
        repeated_tables.insert(tbl);
    tables_visited.insert(tbl);
    LOG1("   Table visited " << tbl->name);
    return true;
} NextTable::profile_t NextTable::LBAlloc::init_apply(const IR::Node* root) {
    if (!self.rebuild) return MauInspector::init_apply(root);  // Early exit
    // Clear old values
    self.stage_tags.clear();
    self.lbs.clear();
    self.max_tag = -1;
    self.use_tags.clear();
    LOG1("BEGIN LONG BRANCH TAG ALLOCATION");
    // Get LBU's in order of their first stage, for better merging
    std::vector<LBUse> lbus(self.lbus.begin(), self.lbus.end());
    std::sort(lbus.begin(), lbus.end(), [](const LBUse& l, const LBUse& r)
                                            { return (l.fst < r.fst); });
    // Loop through all of the tags in order of their first stage
    for (auto& u : lbus) {
        int tag = alloc_lb(u);
        LOG3("  Long branch targeting " << u.dest->name << " allocated on tag " << tag);
        // Loop through all sources and mark them in the map we expose
        for (auto src : self.dest_src[get_uid(u.dest)]) {
            LOG5("    - source: " << src.build_name());
            self.lbs[src][tag].insert(get_uid(u.dest));
        }
    }
    // FIXME: Change to Device::numLongBranchTags()
    self.rebuild = self.stage_tags.size() >= size_t(Device::numLongBranchTags());
    LOG1("FINISHED LONG BRANCH TAG ALLOCATION");
    return MauInspector::init_apply(root);
}

int NextTable::LBAlloc::alloc_lb(const LBUse& u) {
    int tag = 0;
    bool need_new = true;
    // Keep looping and trying to add LB to a tag
    for (; size_t(tag) < self.stage_tags.size(); ++tag) {
        if (self.stage_tags[tag].add_use(u)) {
            need_new = false;
            break;
        }
    }
    if (need_new) {
        tag = self.stage_tags.size();
        Tag t;
        t.add_use(u);
        self.stage_tags.push_back(t);
        self.max_tag = tag;
    }
    self.use_tags[u] = tag;
    return tag;
}

bool NextTable::LBAlloc::preorder(const IR::BFN::Pipe*) {
    return false;
}

// Pretty prints tag information
void NextTable::LBAlloc::pretty_tags() {
    std::vector<std::string> header;
    header.push_back("Tag #");
    for (int i = 0; i < self.max_stage; ++i)
        header.push_back("Stage " + std::to_string(i));

    std::map<gress_t, std::string> gress_char;
    gress_char[INGRESS] = "-";
    gress_char[EGRESS] = "+";
    gress_char[GHOST] = "=";
    log << "======KEY======" << std::endl
        << "INGRESS: " << gress_char[INGRESS] << std::endl
        << "EGRESS:  " << gress_char[EGRESS] << std::endl
        << "GHOST:   " << gress_char[GHOST] << std::endl;

    TablePrinter* tp = new TablePrinter(log, header, TablePrinter::Align::CENTER);
    tp->addSep();

    // Print each tag's occupied stages
    int tag_num = 0;
    for (auto t : self.stage_tags) {
        std::vector<std::string> row;
        row.push_back(std::to_string(tag_num));
        std::map<int, std::string> stage_occ;
        for (auto u : t) {  // Iterate through all of the uses
            if (u.fst >= u.lst - 1) continue;  // skip reduced uses
            std::string spacer = gress_char[u.dest->thread()];
            stage_occ[u.fst] += "|" + spacer;
            for (ssize_t i = u.fst + 1; i < u.lst; ++i) {
                stage_occ[i] = spacer + spacer;
            }
            stage_occ[u.lst] = spacer + ">" + stage_occ[u.lst];
        }
        for (int i = 0; i < self.max_stage; ++i) {
            if (stage_occ.count(i))
                row.push_back(stage_occ[i]);
            else
                row.push_back("");
        }
        tp->addRow(row);
        ++tag_num;
    }
    tp->print();
    log << std::endl;
}

void NextTable::LBAlloc::pretty_srcs() {
    std::vector<std::string> header({"Dest. table", "Tag #", "Range", "Src tables"});
    TablePrinter* tp = new TablePrinter(log, header, TablePrinter::Align::CENTER);
    tp->addSep();

    for (auto kv : self.use_tags) {
        std::vector<std::string> row;
        row.push_back(get_uid(kv.first.dest).build_name());
        row.push_back(std::to_string(kv.second));
        row.push_back("[ " + std::to_string(kv.first.fst) + " -- " + std::to_string(kv.first.lst)
                      + " ]");
        std::string srcs("[ ");
        for (auto s : self.dest_src[get_uid(kv.first.dest)])
            srcs += s.build_name() + ", ";
        srcs.pop_back();  // Delete last space ...
        srcs.pop_back();  // and comma
        srcs += " ]";
        row.push_back(srcs);
        tp->addRow(row);
    }
    tp->print();
    log << std::endl;
}

void NextTable::LBAlloc::end_apply() {
    pretty_tags();
    LOG2(log.str());
    // Reset and print source dest info
    log.clear();
    pretty_srcs();
    LOG3(log.str());
}

NextTable::profile_t NextTable::TagReduce::init_apply(const IR::Node* root) {
    self.num_dts = 0;
    return MauTransform::init_apply(root);
}

IR::Node* NextTable::TagReduce::preorder(IR::BFN::Pipe* p) {
    if (!self.rebuild) {  // Short circuit when we don't need dumb tables
        return p;
    }
    // Try to merge tags
    LOG1("BEGINNING TAG REDUCTION");
    bool success = merge_tags();
    if (!success) {
        LOG1("TAG REDUCTION FAILED! BACKTRACKING AND RETRYING WITHOUT LONG BRANCHES!");
        // Backtrack, because we can't add DTs to fix the problem!
        prune();
        return p;
    }
    // Allocate memories for DTs
    alloc_dt_mems();
    LOG1("FINISHED TAG REDUCTION SUCCESSFULLY, INSERTING TABLES INTO IR");
    return p;
}

IR::Node* NextTable::TagReduce::preorder(IR::MAU::TableSeq* ts) {
    // Get the original pointer
    auto key = dynamic_cast<const IR::MAU::TableSeq*>(getOriginal());
    // Add new tables
    ts->tables.insert(ts->tables.end(), dumb_tbls[key].begin(), dumb_tbls[key].end());
    // Put tables into LID sorted order
    std::sort(ts->tables.begin(), ts->tables.end(),
              [](const IR::MAU::Table* t1, const IR::MAU::Table* t2)
              { return t1->logical_id < t2->logical_id; });
    return ts;
}

IR::Node* NextTable::TagReduce::preorder(IR::MAU::Table* t) {
    if (self.al_runs.count(t->unique_id()))
        t->always_run = true;
    return t;
}

/* Represents a symmetric matrix as a flattened vector. (i, j) = (j, i) */
template <class T>
class NextTable::TagReduce::sym_matrix {
    std::vector<T> m;
    size_t dim;
    inline bool inrng(size_t i) const { return i < dim; }
    // Converts 2D indexing to 1D
    inline size_t conv(size_t i, size_t j) const {
        if (!inrng(i) || !inrng(j))
            throw std::out_of_range("Index out of range in tag matrix!");
        size_t x = std::max(i, j);
        size_t y = std::min(i, j);
        return x * (x + 1) / 2 + y;
    }
    // Takes an index in the 1D vector and converts back to a coordinate pair. Always returns in
    // order (smaller, larger)
    static std::pair<size_t, size_t> invert(size_t z) {
        size_t x = floor((sqrt(double(8*z + 1)) - 1.0)/2.0);
        size_t y = z - (x * (x + 1)) / 2;
        return std::pair<size_t, size_t>(y, x);
    }

 public:
    explicit sym_matrix(size_t num) : m((num*(num+1))/2, T()), dim(num) {}
    // Lookup (i,j)
    T operator()(size_t i, size_t j) const {
        return m.at(conv(i, j));
    }
    // Assign vec to (i,j), returns old value
    T operator()(size_t i, size_t j, T val) {
        T old = m[conv(i, j)];
        m[conv(i, j)] = val;
        return old;
    }
    // Returns index of an object given a comparison function. comp should return true if the left
    // argument is to be preferred. Returns index in order (smaller, larger)
    std::pair<size_t, size_t> get(std::function<bool(T, T)> comp) const {
        size_t idx = 0;
        T best = m.at(0);
        for (size_t i = 1; i < m.size(); ++i) {
            if (comp(m.at(i), best)) {
                idx = i;
                best = m.at(i);
            }
        }
        return invert(idx);
    }
};

struct NextTable::TagReduce::merge_t {
    Tag merged;
    std::map<LBUse, std::set<int>> dum;
    bool success;
    bool finalized;
    size_t num_dts;
    merge_t() : success(true), finalized(false), num_dts(0) {}
};

NextTable::TagReduce::merge_t NextTable::TagReduce::merge(Tag l, Tag r) const {
    merge_t rv;
    std::map<int, int> stage_id(self.stage_id);  // Need our own copy
    auto cap = [&](int k) {  // Check the capacity of a stage. 0 means full
                   return (k+1) * Memories::LOGICAL_TABLES - stage_id[k];
               };
    auto addrng = [&](int fst, int lst) {  // Returns a set containing [fst, lst)
                      std::set<int> dts;
                      for (; fst < lst; ++fst) {
                          if (!cap(fst)) rv.success = false;
                          dts.insert(fst);
                          rv.num_dts++;
                      }
                      return dts;
                  };
    for (auto& lu : l) {
        for (auto& ru : r) {
            if (!(lu & ru)) continue;  // Skip if there's no overlap
            if (!lu.can_dt() && !ru.can_dt()) {  // Early exit if overlap and can't DT both
                rv.success = false;
                return rv;
            }
            std::set<int> dts;
            LBUse* key;  // The LB which dummy tables were added to
            // Handles when one tag fully covers another
            auto overlap = [&](LBUse* lrg, LBUse* sml) {
                               if (sml->can_dt()) {  // Try to get rid of smaller
                                   dts = addrng(sml->fst + 1, sml->lst);
                                   sml->fst = sml->lst;
                                   key = sml;
                               } else {  // Get rid of larger o.w.
                                   dts = addrng(lrg->fst + 1, lrg->lst);
                                   lrg->fst = lrg->lst;
                                   key = lrg;
                               }
                           };
            // Handles when one tag only partially covers another
            auto partial
                = [&](LBUse* lft, LBUse* rgt) {
                      // Here, we can add rf--ll-1 to the left or rf+1--ll if on. If off, we can add
                      // max(lf + 1, rf - 1)--ll-1 to the left or rf+1--min(ll + 1, rl - 1) to the
                      // right
                      bool on = lft->same_gress(*rgt);
                      int lbeg = on ? lft->fst : std::max(lft->fst + 1, rgt->fst - 1);
                      int rend = on ? lft->lst : std::min(lft->lst + 1, rgt->lst - 1);
                      if (!rgt->can_dt() || cap(lbeg) > cap(rend)) {
                          dts = addrng(lbeg, lft->lst);
                          lft->lst = lbeg;
                          key = lft;
                      } else {
                          dts = addrng(rgt->fst + 1, rend + 1);
                          rgt->fst = rend;
                          key = rgt;
                      }
                  };
            // Four ways to conflict:
            if (lu.fst <= ru.fst && ru.lst <= lu.lst)  // lu completely overlaps ru
                overlap(&lu, &ru);
            else if (ru.fst <= lu.fst && lu.lst <= ru.lst)  // ru completely overlaps lu
                overlap(&ru, &lu);
            else if (lu.fst < ru.fst && lu.lst < ru.lst)  // lu partially overlaps ru
                partial(&lu, &ru);
            else  // ru partially overlaps lu
                partial(&ru, &lu);
            if (!rv.success) return rv;
            BUG_CHECK(dts.size() > 0, "Two uses overlap but don't need dummy tables to merge??");
            // Insert into map, update the key
            for (auto i : dts) {
                rv.dum[*key].insert(i);
                stage_id[i]++;
            }
        }
    }
    // Merge tags
    for (auto u : l)
        rv.merged.add_use(u);
    for (auto u : r)
        rv.merged.add_use(u);
    rv.finalized = true;
    return rv;
}

// Only called after we determine we need dumb tables. Finds (locally) minimal configuration of dumb
// tables
NextTable::TagReduce::sym_matrix<NextTable::TagReduce::merge_t>
NextTable::TagReduce::find_merges() const {
    // Comparison between tag i and tag j
    sym_matrix<merge_t> m(self.stage_tags.size());
    // Get all of the possible dummy tables
    for (size_t i = 0; i < self.stage_tags.size(); ++i) {
        // Compare to tags greater than i (comparisons are commutative
        for (size_t j = i + 1; j < self.stage_tags.size(); ++j)
            m(i, j, merge(self.stage_tags.at(i), self.stage_tags.at(j)));
    }
    return m;
}

// Merges tags until we've reduced long branch pressure far enough. Returns true if LB pressure can
// be lowered to below device limtis, false o.w.
bool NextTable::TagReduce::merge_tags() {
    // Continue merging until our long branches have been minimized
    for (int num_merges = self.stage_tags.size() - Device::numLongBranchTags();
         num_merges; --num_merges) {
        auto m = find_merges();  // Find the merges we can do on this iteration
        // Get the coordinates of the smallest vector that is not empty
        size_t fst, snd;
        std::tie(fst, snd) = m.get([&](merge_t l, merge_t r) {
                                       if (!l.success || !l.finalized) return false;
                                       if (!r.success || !r.finalized) return true;
                                       return l.num_dts < r.num_dts;
                                   });
        merge_t mrg = m(fst, snd);  // Dumb tables needed to merge fst and snd
        if (!mrg.success || !mrg.finalized) {  // If we can't find a successful merge, fail
            return false;
        }
        LOG2("  Merging tags " << fst << " and " << snd);
        for (auto kv : mrg.dum) {  // Associate all of the dummy tables with the table sequence
            auto ts = self.dest_ts[get_uid(kv.first.dest)];
            auto dtbls =
                std::accumulate(kv.second.begin(), kv.second.end(), std::vector<IR::MAU::Table*>(),
                                [&](std::vector<IR::MAU::Table*> a, int st) {
                                    cstring tname = "$next-table-forward-to-" + kv.first.dest->name
                                        + "-" + std::to_string(st);
                                    LOG3("    - " << tname << " in stage " << st
                                         << ", targeting dest " << kv.first.dest->name);
                                    auto* dt = new IR::MAU::Table(tname, kv.first.thread());
                                    dt->logical_id = self.stage_id[st]++;
                                    stage_dts[st].push_back(dt);
                                    a.push_back(dt);
                                    return a;
                                });
            dumb_tbls[ts].insert(dumb_tbls[ts].end(), dtbls.begin(), dtbls.end());
        }
        // Delete the old tags and add the merged tag
        self.stage_tags[fst] = mrg.merged;
        self.stage_tags.erase(self.stage_tags.begin() + snd);
    }
    return true;
}

void NextTable::TagReduce::alloc_dt_mems() {
    // Allocate memories for dumb tables
    for (auto stage : stage_dts) {
        // Need to store resources until allocation has finished
        std::map<IR::MAU::Table*, TableResourceAlloc*> tras;
        auto& mem = self.mems[stage.first];
        for (auto* t : stage.second) {
            TableResourceAlloc* tra = new TableResourceAlloc;
            tras[t] = tra;
            mem.add_table(t, nullptr, tra, nullptr, 0, 0);
            self.num_dts++;
        }
        bool success = mem.allocate_all_dummies();
        // Just to check that allocation succeeded. If a logical ID is available (which we check
        // when allocating dummy tables), we should be allocate a dummy table since there are 16 gws
        // NOTE: Chris says that this can actually be done with an always miss logical table. May
        // want to change this later to not allocate a gateway!
        BUG_CHECK(success, "Could not allocate all dummy tables in stage %d!", stage.first);
        // Set the resources
        for (auto res : tras)
            res.first->resources = res.second;
    }
}

// FIXME: best to add a ConditionalVisitor to pass_manager.h. Ask Chris about this and see PR#3474
NextTable::NextTable() {
    addPasses({&multi_applies,
               new Prop(*this),
               &multi_applies,
               new LBAlloc(*this),
               new TagReduce(*this),
               &multi_applies,
               new Prop(*this),
               new LBAlloc(*this)});
}
