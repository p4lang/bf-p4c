#include "table_mutex.h"

void TablesMutuallyExclusive::postorder(const IR::MAU::Table *tbl) {
    assert(table_ids.count(tbl));
    table_succ[tbl][table_ids[tbl]] = true;
    vector<bitvec> sets;
    bitvec common;
    for (auto &n : tbl->next) {
        /* find the tables reachable via each next_table chain */
        if (!n.second) continue;
        bitvec succ;
        for (auto t : n.second->tables)
            succ |= table_succ[t];
        table_succ[tbl] |= succ;
        /* find tables reachable via two or more next chains */
        for (auto &set : sets)
            common |= (set & succ);
        sets.push_back(succ); }
    for (auto &set : sets)
        set -= common;
    /* each table only reachable via one chain is mutually exclusive with
     * all tables only reachable via a different chain */
    for (auto &set : sets)
        for (auto t : set)
            for (auto &other : sets)
                if (&set != &other)
                    mutex[t] |= other;
}

void TablesMutuallyExclusive::postorder(const IR::Tofino::Pipe *pipe) {
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
