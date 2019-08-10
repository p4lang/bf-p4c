#include "jbay_next_table.h"
#include <unordered_map>
#include <unordered_set>
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_layout.h"
#include "device.h"
#include "lib/error.h"
#include "bf-p4c/common/table_printer.h"

/* This pass calculates a map ~props~, which is used in assembly generation to correctly propagate
 * next tables. Conceptually, ~props~ specifies the set of tables a table is responsible for
 * running after itself. More specifically, for a given table and a given table sequence owned by
 * that table, it specifies the set of tables that are to run under that table sequence's
 * condition. The NextTable object captures one table that needs to be run and how that signal is
 * propagated to it (either by LOCAL_EXEC, GLOBAL_EXEC, or LONG_BRANCH). The pass is split into 3
 * stages: EmptyIds, NextTableAlloc and AddDummyTables (which must run in that order).
 * 
 * AT A GLANCE:
 *
 * 1. EmptyIds collects information about how tables were placed. As the name suggests, its primary
 *    use is to find empty logical IDs that can be used by dumb tables, described in
 *    OPTIMIZATIONS. It builds the maps stage_cap, mems, stage_id.
 *
 * 2. NextTableAlloc is where most of the work occurs. It builds the map ~props~, which is the data
 *    structure used by assembly generation to propagate next tables and add long branches. It does
 *    this one table sequence at a time. ~props~ is built additively; that is, an entry is never
 *    removed once added.
 *
 * 3. AddDumbTables performs transformations requested by NextTableAlloc, most of which are related
 *    to dumb table creation, described in OPTIMIZATIONS.
 *
 * OPTIMIZATIONS:
 *
 * This pass attempts to minimize the use of long branches wherever possible, as LOCAL_EXEC and
 * GLOBAL_EXEC are effectively unlimited. Unoptimized NTP would use a long branch across an entire
 * table sequence if *any* of the tables in the sequence were placed 2 stages or
 * later. The following example will be used to illustrate these optimizations:
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
 * 2. Merge contiguous long branches: Long branches in the same table sequence that have an overlap
 *    can be merged. For other reasons (see 4), the long branches created in push-down between
 *    stages 6-9 and stages 9-11 must use different tags even though they don't really overlap. This
 *    can lead to rather poor long branch usage. Instead, we now merge them into a single long
 *    branch, resulting in the following change to the NTP from push-down:
 *
 *    +----+----+---------------------+
 *    | .. | .. | ...                 |
 *    +----+----+---------------------+
 *    | 09 | t4 | long_branch from t2 |
 *    | 09 | t5 | local_exec from t4  |
 *    +----+----+---------------------+
 *    | 11 | t6 | long_branch from t2 | <--- long branch is from t2 instead of t4 now!
 *    | 11 | t7 | local_exec from t6  |
 *    +----+----+---------------------+
 *    | 12 | t8 | global_exec from t8 |
 *    +----+----+---------------------+
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
 *    shorten the first long branch by 1 stage.
 *
 * 4. "Overlap" long branches in the same gress (FIXME UNIMPLEMENTED): Suppose we have one long
 *    branch from stages 2-5 and one from 5-7. These can be on the same tag if and only if they are
 *    both associated with the same gress (technically, ghost and ingress can also overlap, but we
 *    will not consider that case for now). As such, we will overlap the two long branches if they
 *    are from the same gress.
 */

NextTableProp::NextTable::NextTable(const IR::MAU::Table* t, next_t ty)
        : id(get_uid(t)), type(ty), stage(t->stage()) { }

/* Holds next table prop information for a specific table sequence. One created per call to
 * add_table_seq. Note that add_table_seq may be called on the same table sequence multiple times,
 * as table sequences can both be (1) under the same table multiple times (multiple actions run the
 * same tables); (2) under different tables. In the case of (1), we do not need to run it twice, but
 * do so right now out of convenience. In the case of (2), we do need to run it multiple times,
 * since the NTP needs to be associated with different tables. */
struct NextTableProp::NextTableAlloc::NTInfo {
    const IR::MAU::Table* parent;  // Origin of this control flow
    std::vector<std::vector<const IR::MAU::Table*>> stages;  // Tables in each stage
    const int first_stage;
    int last_stage;
    const cstring seq_nm;  // Name of the table sequence
    const IR::MAU::TableSeq* ts;
    bitvec dummies;  // Dumb table usage

    NTInfo(const IR::MAU::Table* tbl, std::pair<cstring, const IR::MAU::TableSeq*> seq)
            : parent(tbl), first_stage(tbl->stage()), seq_nm(seq.first), ts(seq.second) {
        LOG3("Calculating next table propagation for table " << tbl->name << " and sequence "
             << seq.first);
        stages.resize(Device::numStages());
        last_stage = tbl->stage();
        BUG_CHECK(first_stage >= 0, "Unplaced table %s", tbl->name);

        // Collect tables into stages for this sequence
        for (auto t : ts->tables) {
            auto st = t->stage();
            BUG_CHECK(st >= 0, "Unplaced table %s", t->name);
            BUG_CHECK(first_stage <= st, "Table %s placed before parent %s", t->name, tbl->name);
            // Update last stage
            last_stage = st > last_stage ? st : last_stage;
            // Add to the correct vector
            if (size_t(st) >= stages.size())
                stages.resize(st+1);
            stages[st].push_back(t);
        }
    }
};

// Adds a table sequence to the map
void NextTableProp::NextTableAlloc::add_table_seq(const IR::MAU::Table* t, std::pair<cstring,
                                                  const IR::MAU::TableSeq*> next) {
    NTInfo nti(t, next);
    local_prop(nti);
    find_dummies(nti);
    cross_prop(nti);
}

void NextTableProp::NextTableAlloc::local_prop(NTInfo& nti) {
    // Add tables that are in the same stage as the parent to the parent's set of LOCAL_EXEC tables
    // for the given sequence
    for (auto nt : nti.stages[nti.first_stage]) {
        BUG_CHECK(nti.parent->logical_id <= nt->logical_id,
                  "Table %s has LID less than parent table %s", nt->name, nti.parent->name);
        LOG3("  Adding " << nt->name << " to " << nti.seq_nm << " LOCAL_EXEC of parent table "
             << nti.parent->name);
        self.props[get_uid(nti.parent)][nti.seq_nm].insert(NextTable(nt, LOCAL_EXEC));
    }
    // Vertically compress each stage; i.e. calculate all of the local_execs, giving us a single
    // representative table for each stage to use in cross stage propagation
    for (int i = nti.first_stage + 1; i <= nti.last_stage; ++i) {
        auto& tables = nti.stages[i];
        if (tables.empty()) continue;

        // Tables should be in logical ID order. The "representative" table (lowest LID) for this
        // stage and its set of $run_if_ran tables
        auto rep = tables[0];
        auto& r_i_r = self.props[get_uid(rep)]["$run_if_ran"];
        for (auto nt : tables) {
            // Skip the representative
            if (nt == rep) continue;
            BUG_CHECK(rep->logical_id < nt->logical_id,
                      "Tables not in logical ID order; representative %s has greater LID than %s.",
                      rep->name, nt->name);
            LOG3("  Adding " << nt->name << " to $run_if_ran LOCAL_EXEC of table " << rep->name);
            r_i_r.insert(NextTable(nt, LOCAL_EXEC));
        }
    }
}


/* Before we do cross stage propagation, we want to add dummy tables to reduce long branch
 * pressure. We do this in two phases. First, we find the places where we can add dummy
 * stages. After we've found all of these locations, we remove useless ones. Finally, we create
 * these dumb tables and stage them for memory allocation in the end_apply 
 * FIXME: Refactor adding dummies to its own pass so we don't do it so greedily. */
void NextTableProp::NextTableAlloc::find_dummies(NTInfo& nti) {
    auto fs = nti.first_stage;
    auto ls = nti.last_stage;
    auto& dummies = nti.dummies;
    // Look for where we can add tables
    for (int i = fs + 1; i < ls; ++i) {
        // If we have a table in the stage, we don't care
        if (!nti.stages[i].empty()) continue;
        // Can add a dummy if we have an empty logical ID
        if (self.stage_cap[i] < Memories::LOGICAL_TABLES) dummies.setbit(i);
    }
    /* Now, prune out useless dummies. To be useful, one of the following conditions must be met:
     *   - Dummy is in stage first_stage + 1. This frees up first_stage.
     *   - Dummy is in last_stage - 1. This frees up last_stage.
     *   - Dummy is in a chain of dummy tables or real tables of at least length 3.
     * Thus, we start our search at first_stage + 2 and end it at last_stage - 2. 
     * FIXME: Once debubbling has gone in, this condition can be relaxed to a chain of 2. */
    // Check if we have a real OR a dumb table in given stage
    auto have_table = [&](int idx) {
                          bool rv = idx < 0 || size_t(idx) > nti.stages.size() ? false
                              : dummies.getbit(idx) || !nti.stages[idx].empty();
                          return rv;
                      };
    bool in_chain = have_table(fs + 1);
    for (int i = fs + 2; i < ls - 1; ++i) {
        // If we're already in a chain, this one is useful
        if (in_chain) {
            in_chain = have_table(i);
            continue;
        }
        // If this bit isn't set and we're not in a chain than we're still not in a chain
        if (!dummies.getbit(i)) continue;
        // Can be in a chain by having the 2 adjacent, having the previous 2 or having the next two
        if ((have_table(i-1) && have_table(i+1)) || (have_table(i-1) && have_table(i-2))
            || (have_table(i+1) && have_table(i+2))) {
            in_chain = true;
            continue;
        }
        // Otherwise, we don't have a chain and this dummy is useless
        dummies.clrbit(i);
    }
    // Create the dummy tables
    for (int i = fs + 1; i < ls; ++i) {
        if (dummies.getbit(i)) {
            // Create the new dummy table
            cstring tname = "$" + nti.parent->name + "-" + nti.seq_nm
                + "-next-table-forward-" + std::to_string(i);
            LOG3("  Adding dummy table to stage " << i << " for NTP of parent "
                 << nti.parent->name);
            auto *dt = new IR::MAU::Table(tname, nti.parent->thread());
            if (self.stage_id.count(i) == 0) {  // If nothing is in the stage, use min
                dt->logical_id = i * 16;
                self.stage_id[i] = i * 16 + 1;
            } else {  // Otherwise, use one larger than max seen
                dt->logical_id = ++self.stage_id[i];
            }
            nti.stages[i].push_back(dt);  // Add for cross table propagation
            self.stage_cap[i]++;  // Increased num in use
            self.dumb_tbls[nti.ts].push_back(dt);  // Add for insertion into IR
            stage_dumbs[i].push_back(dt);  // Add for memory allocation
        }
    }
}

void NextTableProp::NextTableAlloc::cross_prop(NTInfo& nti) {
    auto stages = nti.stages;
    auto prev_t = nti.parent;  // The table from which we will propagate
    int prev_st = nti.first_stage;  // The stage that prev_t is in
    NextTable* prev_nt = nullptr;  // The previous NextTable object
    const IR::MAU::Table* last_lb_orig = nullptr;  // The last table a long branch originated from
    cstring branch = nti.seq_nm;  // The name of the seq branch. Will be $run_if_ran after parent
    int i = nti.first_stage + 1;

    // Creates a GLOBAL_EXEC NextTable object for rep
    auto ge = [&](const IR::MAU::Table* rep) {
                  LOG3("  Adding " << rep->name << " to " << branch
                       << " GLOBAL_EXEC of table " << prev_t->name << " from stage "
                       << prev_st << " to stage " << i);
                  NextTable* rv = new NextTable(rep, GLOBAL_EXEC);
                  // Associate it with prev_t in the props map
                  self.props[get_uid(prev_t)][branch].insert(*rv);
                  return rv;
              };
    // Creates a LONG_BRANCH NextTable object for rep
    auto lb = [&](const IR::MAU::Table* rep) {
                  BUG_CHECK(prev_t->stage() + 1 < rep->stage(),
                            "LB used between %s in stage %d and %s in stage %d!",
                            prev_t->name, prev_t->stage(), rep->name, rep->stage());
                  NextTable* rv = new NextTable(rep, LONG_BRANCH);
                  // If the previous one was a long branch as well, we can just combine them
                  if (prev_nt && prev_nt->type == LONG_BRANCH) {
                      merge_lb(prev_nt, rv);
                      BUG_CHECK(last_lb_orig, "Previous NT used LB, but last_lb_orig not set!");
                  } else {
                      alloc_lb(rv, prev_st);
                      if (rv->lb.tag >= Device::numLongBranchTags())
                          ::error(ErrorType::ERR_OVERLIMIT, "too many long branches %1%", rep);
                      // Update the last long branch origin, as prev_t is now an lb origin
                      last_lb_orig = prev_t;
                  }
                  // Associate this next table with the last long branch origin
                  self.props[get_uid(last_lb_orig)][branch].insert(*rv);
                  // Add the tables to pretty printer
                  lb_pp[rv->lb.tag][prev_t->stage()] =
                      std::pair<const IR::MAU::Table*, const IR::MAU::Table*>(prev_t, rep);
                  LOG3("  Adding " << rep->name << " to " << branch
                       << " LONG_BRANCH of table " << prev_t->name << " from stage " << prev_st
                       << " to stage " << i << " on tag " << rv->lb.tag);
                  return rv;
              };

    for (; i <= nti.last_stage; ++i) {
        if (stages[i].empty()) continue;
        BUG_CHECK(prev_st < i, "Previous is not previous!");
        // The representative for this stage that will receive (and pass) cross-stage propagation
        auto rep = stages[i][0];

        // Do we need global_exec or long_branch?
        NextTable* nt = prev_st == i-1 ? ge(rep) : lb(rep);
        // Update previous
        prev_t = rep;
        prev_st = i;
        prev_nt = nt;
        branch = "$run_if_ran";
    }
}

// Return the unique ID for this table. Since we're in the weird position of having both unplaced
// and placed tables, we need to check if we are placed or not
UniqueId NextTableProp::get_uid(const IR::MAU::Table* t) {
    return t->is_placed() ? t->unique_id() : t->pp_unique_id();
}

// Allocate a long branch tag for this table
void NextTableProp::NextTableAlloc::alloc_lb(NextTable* nt, int first_stage) {
    auto& lb = nt->lb;
    lb.first_stage = first_stage;
    BUG_CHECK(first_stage >= 0, "Unplaced table");
    lb.rng = bitvec(first_stage, nt->stage + 1 - first_stage);

    // Loop to find an open tag
    lb.tag = 0;
    while (size_t(lb.tag) < stage_use.size()  // See if we're at a completely new tag
           && (stage_use[lb.tag] & lb.rng))  // Check for stage range overlap
        ++lb.tag;
    BUG_CHECK(lb.tag >= 0, "Invalid long branch tag %d", lb.tag);

    // Add this tag to the uses
    stage_use[lb.tag] |= lb.rng;
    // for (int st = first_stage; st <= stage; ++st) {
    //     if (use[st][lb.tag] && use[st][lb.tag] != &lb)
    //         BUG("conflicting allocation for long branch tag %d in stage %d", lb.tag, st);
    //     use[st][lb.tag] = &lb;
    // }
}

// Merge prev lb with nt
void NextTableProp::NextTableAlloc::merge_lb(NextTable* prev, NextTable* nt) {
    // When we merge, we're just going to reuse the same tag from prev but increase the range that
    // it covers. We also need to accordingly update the range in the global stage_use.
    auto& prev_lb = prev->lb;
    auto& lb = nt->lb;
    lb.first_stage = prev_lb.first_stage;
    bitvec rng(lb.first_stage, nt->stage + 1 - lb.first_stage);
    lb.rng = prev_lb.rng = rng;
    lb.tag = prev_lb.tag;
    stage_use[lb.tag] |= rng;
}

bool NextTableProp::NextTableAlloc::preorder(const IR::MAU::Table* t) {
    if (!findContext<IR::MAU::Table>())
        self.al_runs.insert(t->unique_id());
    // Add all of the table's table sequences
    for (auto ts : t->next)
        add_table_seq(t, ts);
    return true;
}

void NextTableProp::NextTableAlloc::end_apply() {
    // Allocate memories for dumb tables
    for (auto stage : stage_dumbs) {
        // Need to store resources until allocation has finished
        std::map<IR::MAU::Table*, TableResourceAlloc*> tras;
        auto& mem = self.mems[stage.first];
        for (auto* t : stage.second) {
            TableResourceAlloc* tra = new TableResourceAlloc;
            tras[t] = tra;
            mem.add_table(t, nullptr, tra, nullptr, 0, 0);
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
    // Pretty print long branch usage
    pretty_print();
    LOG3(log.str());
}

bool NextTableProp::EmptyIds::preorder(const IR::MAU::Table* t) {
    int st = t->stage();
    self.stage_cap[st]++;
    self.mems[st].update(t->resources->memuse);
    if (t->logical_id > self.stage_id[st])
        self.stage_id[st] = t->logical_id;
    return true;
}

IR::Node* NextTableProp::AddDumbTables::preorder(IR::MAU::TableSeq* ts) {
    // Get the original pointer
    auto key = dynamic_cast<const IR::MAU::TableSeq*>(getOriginal());
    // Add new tables
    ts->tables.insert(ts->tables.end(), self.dumb_tbls[key].begin(), self.dumb_tbls[key].end());
    // Put tables into LID sorted order
    std::sort(ts->tables.begin(), ts->tables.end(),
              [](const IR::MAU::Table* t1, const IR::MAU::Table* t2)
              { return t1->logical_id < t2->logical_id; });
    return ts;
}

IR::Node* NextTableProp::AddDumbTables::preorder(IR::MAU::Table* t) {
    if (self.al_runs.count(t->unique_id()))
        t->always_run = true;
    return t;
}

NextTableProp::NextTableProp() {
    addPasses({new EmptyIds(*this), new NextTableAlloc(*this),
               new AddDumbTables(*this)});
}

void NextTableProp::NextTableAlloc::pretty_print() {
    std::vector<std::string> header;
    header.push_back("Tag #");
    int ns = Device::numStages();
    for (int i = 0; i < ns; ++i)
        header.push_back("Stage " + std::to_string(i));

    TablePrinter* tp = new TablePrinter(log, header, TablePrinter::Align::CENTER);
    tp->addSep();

    // Print each tag
    for (unsigned i = 0; i < lb_pp.size(); ++i) {
        std::vector<std::string> row;
        row.push_back(std::to_string(i));
        auto tag_use = lb_pp[i];
        // Iterate through the stages
        for (int j = 0; j < ns; ++j) {
            // If the tag has an entry at this stage
            if (tag_use.count(j)) {
                // Get the tables
                auto src_dest = tag_use.at(j);
                // Add the first table and increment j accordingly.
                std::string nm = src_dest.first->name + "";
                row.push_back(nm);
                ++j;
                // Add fillers
                int k = j;
                for (; k < src_dest.second->stage()-1; ++k)
                    row.push_back("--");
                row.push_back("->");
                // Update j to reflect fillers
                j = k + 1;
                // Finally, add the dest name
                nm = src_dest.second->name + "";
                row.push_back(nm);
            } else {  // Otherwise, add an empty string
                row.push_back("");
            }
        }
        tp->addRow(row);
    }
    tp->print();
    log << std::endl;
}
