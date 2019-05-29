#include "bf-p4c/mau/table_mutex.h"

void TablesMutuallyExclusive::postorder(const IR::MAU::Table *tbl) {
    // FIXME: Doesn't take into account gateways and match tables merging after table placement
    BUG_CHECK(table_ids.count(tbl), "Table found in postorder not visited in preorder?");
    table_succ[tbl][table_ids[tbl]] = true;
    safe_vector<bitvec> sets;
    for (auto &n : tbl->next) {
        /* find the tables reachable via each next_table chain */
        if (!n.second) continue;
        bitvec succ;
        for (auto t : n.second->tables) {
            succ |= table_succ[t];
        }
        table_succ[tbl] |= succ;
        /* find tables reachable via two or more next chains */
        sets.push_back(succ);
    }

    /**
     * Each table that appears on a next table chain is mutually exclusive from any table
     * that appears on a different next table chain
     */
    for (auto set1 : sets) {
        for (auto set2 : sets) {
            auto common = set1 & set2;
            for (auto t : set1 - common) {
                mutex[t] |= set2 - common;
            }
        }
    }

    bool miss_mutex = false;
    if (!tbl->gateway_only()) {
        // Need to ensure that default action is constant
        int allowed_defaults = 0;
        for (auto act : Values(tbl->actions)) {
            if (act->default_allowed)
                allowed_defaults++;
        }

        for (auto act : Values(tbl->actions)) {
            if (!act->init_default) continue;
            // Ensure that the miss action is a noop
            if (act->action.size() == 0 && allowed_defaults == 1) {
                miss_mutex = true;
            }
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
    /* ingress, ghost and egress are assumed mutually exclusive */
    safe_vector<bitvec> sets;
    for (auto th : pipe->thread)
        if (th.mau) {
            bitvec set;
            for (auto t : th.mau->tables)
                set |= table_succ[t];
            sets.push_back(set); }
    if (pipe->ghost_thread) {
        bitvec set;
        for (auto t : pipe->ghost_thread->tables)
            set |= table_succ[t];
        sets.push_back(set); }
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;
}

bool TablesMutuallyExclusive::operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a);
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b);
    return mutex(table_ids.at(a), table_ids.at(b));
}

bool TablesMutuallyExclusive::action(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a);
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b);
    return action_mutex(table_ids.at(a), table_ids.at(b));
}

bool SharedIndirectAttachedAnalysis::preorder(const IR::MAU::Action *) {
    return false;
}

bool SharedIndirectAttachedAnalysis::preorder(const IR::MAU::AttachedMemory *am) {
    visitAgain();
    if (am->direct)
        return false;
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto *check_tbl : backend_users[am]) {
        if (!mutex(tbl, check_tbl) && !mutex.action(tbl, check_tbl)) {
            error("Tables %s and %s are not mutually exclusive, yet share %s",
                  tbl->name, check_tbl->name, am->name);
        }
    }
    backend_users[am].push_back(tbl);
    return false;
}

void SharedIndirectAttachedAnalysis::end_apply() {
    for (const auto& kv : backend_users) {
        if (kv.first->is<IR::MAU::ActionData>()) {
            for (const auto* tbl_i : kv.second) {
                for (const auto* tbl_j : kv.second) {
                    if (tbl_i != tbl_j) {
                        act_data_shared_tables[tbl_i].insert(tbl_j);
                        act_data_shared_tables[tbl_j].insert(tbl_i);
                    }
                }
            }
        }
    }
}
