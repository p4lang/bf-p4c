#include "table_mutex.h"

void TablesMutuallyExclusive::postorder(const IR::MAU::Table *tbl) {
    // FIXME: Doesn't take into account gateways and match tables merging after table placement
    assert(table_ids.count(tbl));
    table_succ[tbl][table_ids[tbl]] = true;
    vector<bitvec> sets;
    bitvec common;
    for (auto &n : tbl->next) {
        /* find the tables reachable via each next_table chain */
        if (!n.second) continue;
        bitvec succ;
        for (auto t : n.second->tables) {
            succ |= table_succ[t];
        }
        table_succ[tbl] |= succ;
        /* find tables reachable via two or more next chains */
        for (auto &set : sets)
            common |= (set & succ);
        sets.push_back(succ);
    }
    for (auto &set : sets)
        set -= common;
    /* each table only reachable via one chain is mutually exclusive with
     * all tables only reachable via a different chain */
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;

    bool miss_mutex = false;
    if (tbl->match_table) {
        // Need to ensure that default action is constant
        auto defact = tbl->match_table->getDefaultAction();
        for (auto action : tbl->actions) {
            if (defact->toString() != action.first) continue;
            // Ensure that the miss action is a noop
            if (action.second->action.size() == 0)
                miss_mutex = true;
        }
    }

    if (!miss_mutex)
        return;

    // Specific miss case to be handled here:
    for (auto &n : tbl->next) {
        if (n.first != "$miss") continue;
        bitvec succ;
        for (auto t : n.second->tables) {
            succ |= table_succ[t];
        }
        action_mutex[table_ids[tbl]] |= succ;
    }
}

void TablesMutuallyExclusive::postorder(const IR::BFN::Pipe *pipe) {
    /* ingress and egress are mutually exclusive */
    vector<bitvec> sets;
    for (auto th : pipe->thread)
        if (th.mau) {
            bitvec set;
            for (auto t : th.mau->tables)
                set |= table_succ[t];
            sets.push_back(set); }
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;
}

bool SharedIndirectActionAnalysis::preorder(const IR::MAU::Table *t) {
    const IR::MAU::ActionData *ad = nullptr;
    for (auto at : t->attached) {
        if ((ad = at->to<IR::MAU::ActionData>()) != nullptr)
            break;
    }
    if (ad == nullptr || ad->direct) return true;
    for (auto *check_tbl : ad_users[ad]) {
        if (!mutex(t, check_tbl) && !mutex.action(t, check_tbl)) {
            error("Tables %s and %s are not mutually exclusive, yet share action profile %s",
                  t->name, check_tbl->name, ad->name);
        }
    }
    ad_users[ad].push_back(t);
    return true;
}
