#include "bf-p4c/mau/action_mutex.h"

void ActionMutuallyExclusive::postorder(const IR::MAU::Table *tbl) {
    // map action name to IR::MAU::Action*
    std::map<cstring, const IR::MAU::Action*> name_to_actions;
    // actions inside a same table are mutex with each other.
    for (const auto* act1 : Values(tbl->actions)) {
        name_to_actions[act1->name.originalName] = act1;
        for (const auto* act2 : Values(tbl->actions)) {
            if (act1 != act2) {
                mutex(action_ids[act1], action_ids[act2]) = true;
            } } }


    bitvec all_actions_in_table;
    for (const auto *act : Values(tbl->actions))
        all_actions_in_table.setbit(action_ids[act]);

    // set actions on different branches to be mutex.
    safe_vector<bitvec> sets;

    bitvec common;
    bitvec all_so_far;
    bitvec actions_seen;

    std::map<cstring, bitvec> actions_running_on_branch;

    // Determine which actions are going to run on which branches, and include those in
    // that particular branch.
    // A table is not an action_chain if it has one and only one path ($default).  Comes when
    // one wants to force a control dependency in the program
    if (tbl->action_chain() || tbl->has_default_path()) {
        for (const auto *act : Values(tbl->actions)) {
            if (tbl->next.count(act->name.originalName) > 0) {
                actions_running_on_branch[act->name.originalName].setbit(action_ids[act]);
            } else if (tbl->has_default_path()) {
                actions_running_on_branch["$default"].setbit(action_ids[act]);
            }
        }
    } else if (tbl->hit_miss_p4()) {
        for (const auto *act : Values(tbl->actions)) {
            if (tbl->next.count("$hit") > 0 && !act->miss_only())
                actions_running_on_branch["$hit"].setbit(action_ids[act]);
            if (tbl->next.count("$miss") > 0 && !act->hit_only()) {
                actions_running_on_branch["$miss"].setbit(action_ids[act]);
            }
        }
    }

    for (const auto next_table_seq_kv : tbl->next) {
        /* find the tables reachable via each next_table chain */
        cstring branch_name = next_table_seq_kv.first;
        const auto* next_table_seq = next_table_seq_kv.second;
        bitvec succ;
        // chained action is included that branch
        actions_seen |= actions_running_on_branch[branch_name];
        succ |= actions_running_on_branch[branch_name];
        for (auto next_table : next_table_seq->tables) {
            succ |= action_succ[next_table]; }
        sets.push_back(succ);
        action_succ[tbl] |= succ;

        /* find actions reachable via two or more next chains */
        common |= (succ & all_so_far);
        all_so_far |= succ;
    }

    // If the $default pathway or only one $hit or $miss pathway is provided, then all actions
    // not yet included directly in a branch are mutually exclusive with all actions included
    // in a path, as well as all actions underneath that path.
    bitvec actions_not_yet_seen = all_actions_in_table - actions_seen;
    if (!actions_not_yet_seen.empty())
        sets.push_back(actions_not_yet_seen);

    // TODO(yumin): It is imprecise in that:
    // switch (A.apply().result_run) {
    //  act_1 : { B.apply(); A.apply(); }
    //  act_2 : { C.apply(); A.apply(); }
    //  act_3 : { D.apply(); }
    // }
    // Here A and D won't be marked as mutex. Same issue in table_mutex.
    // Now we do not handle this case.
    for (auto &set : sets)
        set -= common;

    /* each action only reachable via one chain is mutually exclusive with
     * all actions only reachable via a different chain */
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;

    // update action_succ
    for (const auto* act : Values(tbl->actions)) {
        action_succ[tbl][action_ids[act]] = true; }
}

void ActionMutuallyExclusive::postorder(const IR::BFN::Pipe *pipe) {
    /* ingress and egress are mutually exclusive */
    safe_vector<bitvec> sets;
    for (auto th : pipe->thread)
        if (th.mau) {
            bitvec set;
            for (auto t : th.mau->tables)
                set |= action_succ[t];
            sets.push_back(set); }
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;
}

