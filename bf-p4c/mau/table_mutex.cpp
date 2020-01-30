#include "bf-p4c/mau/table_mutex.h"
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
                   tbl, pragma_val, tbl->externalName());
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

bool TablesMutuallyExclusive::miss_mutex_action_chain(const IR::MAU::Table *tbl,
         const IR::MAU::Action *default_act, cstring &name) {
    ordered_set<cstring> non_def_act_chains;
    for (auto &n : tbl->next) {
        if (default_act->name.originalName == n.first) {
            name = n.first;
            return true;
        } else if (n.first[0] != '$') {
            non_def_act_chains.insert(n.first);
        }
    }

    if (non_def_act_chains.size() != tbl->actions.size() - 1)
        return false;
    if (tbl->has_default_path())
        name = "$default";
    return true;
}

/**
 * The functionality of this algorithm:
 *     - All Tables in a TableSeq are not mutually exclusive with each other
 *     - The successors of these tables are also not mutually exclusive with each other
 *     - A table is not mutually exclusive with any of its successors
 *
 * The reverse of the non-mutex graph is the mutual exclusion
 */
void TablesMutuallyExclusive::postorder(const IR::MAU::Table *tbl) {
    // Compute the table_succ entry for this table.
    bitvec succ;
    for (auto n : Values(tbl->next)) {
        for (auto t : n->tables) {
            succ |= table_succ[t];
        }
    }
    succ.setbit(table_ids.at(tbl));
    table_succ[tbl] = succ;

    // Update the non_mutex entry for this table to account for the successors we just computed.
    non_mutex[table_ids.at(tbl)] |= succ;

    // The rest of this method computes action_mutex, which detects whether two tables that are not
    // mutually exclusive in total can share an ActionProfile.  Honestly this should be updated in
    // a different pull request to be for all indirect stateful tables
    bool miss_mutex = false;
    const IR::MAU::Action *default_act = nullptr;
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
                default_act = act;
            }
        }
    }

    if (!miss_mutex)
        return;

    cstring next_chain_name;
    if (tbl->action_chain() && !miss_mutex_action_chain(tbl, default_act, next_chain_name))
        return;

    // Specific miss case to be handled here:
    bitvec tables_not_on_miss;
    bitvec tables_on_miss;
    for (auto &n : tbl->next) {
        if (n.first == "$miss" || n.first == next_chain_name) {
            for (auto t : n.second->tables)
                tables_on_miss |= table_succ[t];
        } else {
            for (auto t : n.second->tables)
                tables_not_on_miss |= table_succ[t];
        }
    }
    action_mutex[table_ids[tbl]] |= tables_on_miss - tables_not_on_miss;
}

void TablesMutuallyExclusive::postorder(const IR::MAU::TableSeq *seq) {
    /* Update non_mutex to account for join points in the control flow. For example,
     *
     *   switch (t1.apply().action_run) {
     *     a1: { t2.apply(); }
     *     a2: { t3.apply(); }
     *   }
     *   t4.apply();
     *
     * is represented by
     *
     *   [ t1  t4 ]
     *    /  \
     * [t2]  [t3]
     *
     * Here, we ensure that t4 is marked as not mutually exclusive with all of t1's table_succ
     * entries. */
    for (size_t i = 0; i < seq->tables.size(); i++) {
        auto i_tbl = seq->tables.at(i);

        for (size_t j = i+1; j < seq->tables.size(); j++) {
            auto j_tbl = seq->tables.at(j);
            for (auto i_id : table_succ[i_tbl])
                non_mutex[i_id] |= table_succ[j_tbl];
        }
    }
}

bool TablesMutuallyExclusive::operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
    return !non_mutex(table_ids.at(a), table_ids.at(b));
}

bool TablesMutuallyExclusive::action(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
    return action_mutex(table_ids.at(a), table_ids.at(b));
}

bool SharedIndirectAttachedAnalysis::check_attach_action_mutex(const IR::MAU::Table *a,
                                                              const IR::MAU::Table *b,
                                                              const IR::MAU::AttachedMemory *am) {
    if (am->is<IR::MAU::ActionData>() || am->is<IR::MAU::Selector>()) {
        return (mutex.action(a, b));
    }
    const IR::MAU::Action* action_a = nullptr;
    const IR::MAU::Action* action_b = nullptr;
    for (auto act : Values(a->actions)) {
        if (act->stateful_call(am->name)) {
            action_a = act;
            for (auto act : Values(b->actions)) {
                if (act->stateful_call(am->name)) {
                    action_b = act;
                    if (!action_mutex(action_a, action_b)) {
                        return false;
                    }
                }
            }
        }
    }
    return true;
}

bool SharedIndirectAttachedAnalysis::preorder(const IR::MAU::AttachedMemory *am) {
    visitAgain();
    if (am->direct) return false;
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto am_tbl : backend_users[am]) {
        if (tbl == am_tbl)  {
            continue;
        } else if (mutex(tbl, am_tbl)) {
            table_sharing_attached[tbl].insert(am_tbl);
            continue;
        } else if (ignore.ignore_deps(tbl, am_tbl)) {
            bitvec am_tbl_bv;
            am_tbl_bv.setbit(table_ids.at(am_tbl));
            _mutex_through_ignore[table_ids.at(tbl)] |= am_tbl_bv;
            table_sharing_attached[tbl].insert(am_tbl);
            continue;
        } else if (check_attach_action_mutex(tbl, am_tbl, am)) {
           table_sharing_attached[tbl].insert(am_tbl);
           continue;
        } else {
            ::error("table %1% and table %2% cannot share %3% because use of the %3% is not "
                    "mutually exclusive", tbl->externalName(), am_tbl->externalName(), am);
        }
    }
    backend_users[am].push_back(tbl);
    return false;
}

// for gtest
bool SharedIndirectAttachedAnalysis::if_table_share_attach(const IR::MAU::Table *a,
                                                           const IR::MAU::Table *b) const {
    if (table_sharing_attached.count(a)) {
        if (table_sharing_attached.at(a).count(b)) return true;
    }
    if (table_sharing_attached.count(b)) {
        if (table_sharing_attached.at(b).count(a)) return true;
    }
    return false;
}

bool SharedIndirectAttachedAnalysis
        ::mutex_through_ignore(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(table_ids.count(a), "No table info for %1%", a->externalName());
    BUG_CHECK(table_ids.count(b), "No table info for %1%", b->externalName());
    return _mutex_through_ignore(table_ids.at(a), table_ids.at(b));
}
