#ifndef BF_P4C_MAU_TABLE_MUTEX_H_
#define BF_P4C_MAU_TABLE_MUTEX_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/safe_vector.h"
#include "lib/symbitmatrix.h"

/** In order for tables to be considered mutually exclusive, the following premise can be
 *  considered as two tables that will never run on the same packet.  This will only
 *  happen if two tables are in separate TableSeqs that can never be accessed together,
 *  such as:
 *      - in an if-else branch, the tables under the if are mutually exclusive from
 *        the tables under the else
 *      - in an hit-miss branch, the tables under the hit branch are mutually exclusive
 *        from the tables under the miss
 *      - in an action chain, the tables under each action branch are mutually exclusive
 *        from one another
 *  These different examples all stem from the structure of an IR tree.  The IR::MAU::Table
 *  class has a map of IR::MAU::TableSeqs.  This map corresponds to the different mutually
 *  paths that can lead from the execution of this table, whether it is a gateway, hitmiss,
 *  or action chain.
 *
 *
 *  The benefits of mutually exclusive tables are the following in Table Placement
 *     1. sequences of mutually exclusive tables can be placed simultaneously, as the next
 *        table pointer can skip over these tables
 *     2. data dependencies do not exist between mutually exclusive tables
 *     3. mutually exclusive tables can share action data bus locations
 *     4. mutually exclusive tables can share instruction memory locations
 *     5. mutually exclusive tables can share indirect action tables and action selectors
 *
 *
 *  The other type of class are action mutually exclusive tables.  These tables are not
 *  mutually exclusive in the fact that all of the tables can possibly run, but in that
 *  it is known that only one of these tables actions which is not a noop will possibly
 *  run.  Of the above benefits, benefits 2-5 apply.  However, the placement is not affected
 */

class TablesMutuallyExclusive : public MauInspector {
    std::map<const IR::MAU::Table *, int>    table_ids;
    std::map<const IR::MAU::Table *, bitvec> table_succ;
    SymBitMatrix                        mutex;
    SymBitMatrix                        action_mutex;
    bool preorder(const IR::MAU::Table *t) override {
        assert(!table_ids.count(t));
        table_ids.emplace(t, table_ids.size());
        return true; }
    void postorder(const IR::MAU::Table *tbl) override;
    void postorder(const IR::BFN::Pipe *pipe) override;
    profile_t init_apply(const IR::Node *root) override {
        profile_t rv = MauInspector::init_apply(root);
        table_ids.clear();
        table_succ.clear();
        mutex.clear();
        return rv; }
 public:
    bool operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
        return mutex(table_ids.at(a), table_ids.at(b)); }
    bool action(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
        return action_mutex(table_ids.at(a), table_ids.at(b)); }
};

class SharedIndirectAttachedAnalysis : public MauInspector {
    std::map<const IR::MAU::BackendAttached *,
             safe_vector<const IR::MAU::Table *>> backend_users;
    const TablesMutuallyExclusive &mutex;

    profile_t init_apply(const IR::Node *root) override {
        profile_t rv = MauInspector::init_apply(root);
        backend_users.clear();
        return rv;
    }
    bool preorder(const IR::MAU::BackendAttached *ba) override;
    bool preorder(const IR::MAU::Action *) override;
 public:
    safe_vector<const IR::MAU::Table *>
    all_shared_tables(const IR::MAU::BackendAttached *ba) const {
        safe_vector<const IR::MAU::Table *> empty;
        if (ba == nullptr || backend_users.count(ba) == 0)
            return empty;
        return backend_users.at(ba);
    }
    explicit SharedIndirectAttachedAnalysis(const TablesMutuallyExclusive &m) : mutex(m) {}
};
#endif /* BF_P4C_MAU_TABLE_MUTEX_H_ */
