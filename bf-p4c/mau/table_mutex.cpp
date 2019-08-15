#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/lib/error_type.h"

#include "bf-p4c/lib/error_type.h"

bool IgnoreTableDeps::ignore_deps(const IR::MAU::Table *t1, const IR::MAU::Table *t2) const {
    auto t1_pos = ignore_dep_map.find(t1);
    if (t1_pos != ignore_dep_map.end()) {
        if (t1_pos->second.count(t2))
            return true;
    }

    auto t2_pos = ignore_dep_map.find(t2);
    if (t2_pos != ignore_dep_map.end()) {
        if (t2_pos->second.count(t1))
            return true;
    }
    return false;
}

bool IgnoreTableDeps::preorder(const IR::MAU::Table *tbl) {
    internal_name_to_table[tbl->name] = tbl;
    external_name_to_table[tbl->externalName()] = tbl;

    std::vector<IR::ID> annotation;
    tbl->getAnnotation("ignore_table_dependency", annotation);
    for (auto name : annotation) {
        // Due to P4_14 global name space, a dot is added to the initial table name
        table_to_pragmas[tbl].insert(name);
    }
    return true;
}


void IgnoreTableDeps::end_apply() {
    for (auto entry : table_to_pragmas) {
        const IR::MAU::Table *tbl = entry.first;
        for (auto pragma_val : entry.second) {
            const IR::MAU::Table *ign_tbl = nullptr;
            if (internal_name_to_table.count(pragma_val)) {
                ign_tbl = internal_name_to_table.at(pragma_val);
            } else if (external_name_to_table.count(pragma_val)) {
                // FIXME: For p4-16, honoring the dependency actually forces one of the
                // tables to fit, due to table_seqdeps not understanding the dependency
                // is gone corresponding to bad chain lengths.  Fix this after 9.0
                ign_tbl = external_name_to_table.at(pragma_val);
            } else if (external_name_to_table.count("." + pragma_val)) {
                ign_tbl = external_name_to_table.at("." + pragma_val);
            } else {
                ::warning(BFN::ErrorType::WARN_PRAGMA_USE, "%1%: The ignore_table_dependency "
                   "value %2% on table %3% does not have a corresponding backend match",
                   tbl->srcInfo, pragma_val, tbl->externalName());
                continue;
            }
            ignore_dep_map[tbl].insert(ign_tbl);
            ignore_dep_map[ign_tbl].insert(tbl);
        }
    }
}

safe_vector<IgnoreTableDeps::TablePair> IgnoreTableDeps::pairwise_deps_to_ignore() const {
    safe_vector<TablePair> rv;
    for (auto entry : ignore_dep_map) {
        auto first_tbl = entry.first;
        for (auto second_tbl : entry.second) {
            rv.emplace_back(std::make_pair(first_tbl, second_tbl));
        }
    }
    return rv;
}


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
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
    return mutex(table_ids.at(a), table_ids.at(b));
}

bool TablesMutuallyExclusive::action(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
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
        if (mutex(tbl, check_tbl))
            continue;
        if (mutex.action(tbl, check_tbl))
            continue;
        if (ignore.ignore_deps(tbl, check_tbl)) {
            bitvec check_tbl_bv;
            check_tbl_bv.setbit(table_ids.at(check_tbl));
            _mutex_through_ignore[table_ids.at(tbl)] |= check_tbl_bv;
            continue;
        }
        ::error("table %1% and table %2% are not mutually exclusive, yet share %3%",
                tbl->externalName(), check_tbl->externalName(), am);
    }
    backend_users[am].push_back(tbl);
    return false;
}

bool SharedIndirectAttachedAnalysis
        ::mutex_through_ignore(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
    return _mutex_through_ignore(table_ids.at(a), table_ids.at(b));
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
