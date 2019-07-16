#include "jbay_next_table.h"
#include <unordered_map>
#include <unordered_set>
#include "device.h"
#include "lib/error.h"
#include "bf-p4c/common/table_printer.h"

/* This function calculates how the next table sequence ~next~ will be propagated from the table ~t~
 * through the 3 available methods in JBay: LOCAL_EXEC, GLOBAL_EXEC, LONG_BRANCH. Since the
 * LOCAL/GLOBAL_EXEC are both effectively unlimited, we aim to use these whenever possible instead
 * of LONG_BRANCH. 
 *
 * Primary data structure here can be thought of as:
 *                    t3       t6
 *              t  t1 t2    t4 t5                   TABLES
 * -----------------------------------------------
 *  0  1  2  3  4  5  6  7  8  9  10  11  12 (...)  STAGES
 *              |              |
 *         first_stage     last_stage
 *
 *  Old long branch allocation would use a long_branch tag from stage 4 all the way to stage
 *  9. However, in combination with global_exec and local_exec, we only need a long branch from 6 to
 *  8. Thus, this method calculates (and stores in a useful way) the following information:
 *  +----+---------------------+
 *  | t1 | global_exec from t  |
 *  +----+---------------------+
 *  | t2 | global_exec from t1 |
 *  | t3 | local_exec from t2  |
 *  +----+---------------------+
 *  | t4 | long_branch from t2 |
 *  +----+---------------------+
 *  | t5 | global_exec from t4 |
 *  | t6 | local_exec from t5  |
 *  +----+---------------------+
 */
void NextTableProp::add_table_seq(
        const IR::MAU::Table* t, std::pair<cstring, const IR::MAU::TableSeq*> next) {
    // Stages x vector of tables in that stage
    std::vector<std::vector<const IR::MAU::Table*>> stages(Device::numStages());
    int last_stage = t->stage(), first_stage = last_stage;
    BUG_CHECK(first_stage >= 0, "Unplaced table %s", t->name);
    auto ts = next.second;

    // Collect stages for this sequence
    for (auto nt : ts->tables) {
        auto st = nt->stage();
        BUG_CHECK(st >= 0, "Unplaced table %s", nt->name);
        // Update last stage
        last_stage = st > last_stage ? st : last_stage;
        // Add to the correct vector
        if (size_t(st) >= stages.size())
            stages.resize(st+1);
        stages[st].push_back(nt);
    }

    // Add tables that are in the same stage as the parent to the parent's set of LOCAL_EXEC tables
    // for the given sequence
    for (auto nt : stages[first_stage]) {
        BUG_CHECK(t->logical_id < nt->logical_id,
                 "Table %s has LID greater than parent table %s", nt->name, t->name);
        LOG3("Adding " << nt->name << " to " << next.first << " LOCAL_EXEC of parent table "
             << t->name);
        props[t->unique_id()][next.first].insert(NextTable(nt, LOCAL_EXEC));
    }

    // Vertically compress the stages data structure; i.e. calculate all of the local_execs,
    // reducing the number of tables we need to handle in each stage to at most 1.
    for (int i = first_stage + 1; i <= last_stage; ++i) {
        auto& tables = stages[i];
        if (tables.empty()) continue;

        // Tables should be in logical ID order. The "representative" table (lowest LID) for this
        // stage and its set of $run_if_ran tables
        auto rep = tables[0];
        auto& al_run = props[rep->unique_id()]["$run_if_ran"];
        for (auto nt : tables) {
            // Skip the representative
            if (nt == rep) continue;
            BUG_CHECK(rep->logical_id < nt->logical_id,
                      "Tables not in logical ID order; representative %s has greater LID than %s.",
                      rep->name, nt->name);
            LOG3("Adding " << nt->name << " to $run_if_ran LOCAL_EXEC of table " << rep->name);
            al_run.insert(NextTable(nt, LOCAL_EXEC));
        }
    }

    // Now, we need to calculate cross stage propagation
    auto prev_t = t;
    int prev_st = first_stage;
    // The name of the table sequence branch. After 1st iteration, will be $run_if_ran
    cstring branch = next.first;
    for (int i = first_stage + 1; i <= last_stage; ++i) {
        if (stages[i].empty()) continue;
        BUG_CHECK(prev_st < i, "Previous is not previous!");
        // The representative for this stage that will receive cross-stage prop
        auto rep = stages[i][0];
        // Do we need global_exec or long_branch
        next_t ty = prev_st == i-1 ? GLOBAL_EXEC : LONG_BRANCH;
        NextTable nt(rep, ty);

        // Allocate long branch if need be
        if (ty == LONG_BRANCH) {
            BUG_CHECK(prev_t->stage() + 1 < rep->stage(),
                      "LB used between %s in stage %d and %s in stage %d!",
                      prev_t->name, prev_t->stage(), rep->name, rep->stage());
            alloc(nt, prev_st);
            if (nt.lb.tag >= Device::numLongBranchTags())
                ::error(ErrorType::ERR_OVERLIMIT, "too many long branches %1%", rep);
            // Add the tables to pretty printer
            lb_pp[nt.lb.tag][prev_t->stage()] =
                std::pair<const IR::MAU::Table*, const IR::MAU::Table*>(prev_t, rep);
        }

        // Add the representative table for this stage to prev's set
        LOG3("Adding " << rep->name << " to " << branch
             << (ty == LONG_BRANCH ? " LONG_BRANCH" : " GLOBAL_EXEC") << " of table "
             << prev_t->name << " from stage " << prev_st << " to stage " << i
             << (ty == LONG_BRANCH ? " on tag " + std::to_string(nt.lb.tag) : ""));
        props[prev_t->unique_id()][branch].insert(nt);

        // Update previous
        prev_t = rep;
        prev_st = i;
        branch = "$run_if_ran";
    }
}

NextTableProp::NextTable::NextTable(const IR::MAU::Table* t, next_t ty) {
    id = t->unique_id();
    stage = t->stage();
    type = ty;
}

// Allocate a long branch tag for this table
void NextTableProp::alloc(NextTable& nt, int first_stage) {
    auto& lb = nt.lb;
    lb.first_stage = first_stage;
    BUG_CHECK(first_stage >= 0, "Unplaced table");
    lb.rng = bitvec(first_stage, nt.stage + 1 - first_stage);

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

bool NextTableProp::preorder(IR::MAU::Table* t) {
    if (!findContext<IR::MAU::Table>())
        t->always_run = true;
    // Add all of the table's table sequences
    for (auto ts : t->next)
        add_table_seq(t, ts);
    return true;
}

void NextTableProp::end_apply() {
    // Pretty print long branch usage
    LOG3(pretty_print());
}

std::string NextTableProp::pretty_print() {
    std::stringstream ss;
    std::vector<std::string> header;
    header.push_back("Tag #");
    int ns = Device::numStages();
    for (int i = 0; i < ns; ++i)
        header.push_back("Stage " + std::to_string(i));

    TablePrinter* tp = new TablePrinter(ss, header, TablePrinter::Align::CENTER);
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
    ss << std::endl;
    return ss.str();
}
