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

    // set actions on different branches to be mutex.
    safe_vector<bitvec> sets;
    bitvec common;
    bitvec all_so_far;
    for (const auto next_table_seq_kv : tbl->next) {
        /* find the tables reachable via each next_table chain */
        cstring branch_name = next_table_seq_kv.first;
        const auto* next_table_seq = next_table_seq_kv.second;
        bitvec succ;
        // chained action is included that branch
        if (name_to_actions.count(branch_name)) {
            succ[action_ids[name_to_actions[branch_name]]] = true; }
        for (auto next_table : next_table_seq->tables) {
            succ |= action_succ[next_table]; }
        sets.push_back(succ);
        action_succ[tbl] |= succ;

        /* find actions reachable via two or more next chains */
        common |= (succ & all_so_far);
        all_so_far |= succ;
    }

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

