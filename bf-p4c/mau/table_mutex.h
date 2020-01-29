#ifndef BF_P4C_MAU_TABLE_MUTEX_H_
#define BF_P4C_MAU_TABLE_MUTEX_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/action_mutex.h"
#include "lib/ordered_map.h"
#include "lib/safe_vector.h"
#include "lib/symbitmatrix.h"

class IgnoreTableDeps : public MauInspector {
    using TablePair = std::pair<const IR::MAU::Table *, const IR::MAU::Table *>;


    ordered_map<const IR::MAU::Table *, ordered_set<const IR::MAU::Table *>> ignore_dep_map;

    std::map<cstring, const IR::MAU::Table *> internal_name_to_table;
    std::map<cstring, const IR::MAU::Table *> external_name_to_table;
    ordered_map<const IR::MAU::Table *, std::set<cstring>> table_to_pragmas;

    profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        ignore_dep_map.clear();
        internal_name_to_table.clear();
        external_name_to_table.clear();
        table_to_pragmas.clear();
        return rv;
    }

    bool preorder(const IR::MAU::Table *) override;
    void end_apply() override;


 public:
    IgnoreTableDeps() {}
    bool ignore_deps(const IR::MAU::Table *t1, const IR::MAU::Table *t2) const;
    safe_vector<TablePair> pairwise_deps_to_ignore() const;
};

/** Provides an analysis for determining whether tables are mutually exclusive.
 *
 *  In order for tables to be considered mutually exclusive, the following premise can be
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
    ordered_map<const IR::MAU::Table *, int>    table_ids;
    std::map<int, const IR::MAU::Table *>       rev_table_ids;

 public:
    // public for gtests
    std::map<cstring, const IR::MAU::Table *> name_to_tables;

 private:
    /// This is the reflexive, transitive closure of the relation in which each table T is related
    /// to all tables appearing in T's next-tables map. Each table is mapped to all of its related
    /// tables, represented by a bitvec keyed on table IDs.
    ordered_map<const IR::MAU::Table *, bitvec> table_succ;

    /// The computed non-mutual-exclusion relation. This is a matrix keyed on table IDs. A value of
    /// 1 indicates that the corresponding tables are not mutually exclusive in the program's
    /// control flow. A value of 0 indicates mutual exclusion.
    SymBitMatrix                                non_mutex;

    /// The computed table-action mutual-exclusion relation. This is a matrix keyed on table IDs. A
    /// value of 1 indicates that at most one of the corresponding tables will execute a non-no-op
    /// action.
    SymBitMatrix                                action_mutex;

    void postorder(const IR::MAU::Table *tbl) override;
    void postorder(const IR::MAU::TableSeq *seq) override;
    bool miss_mutex_action_chain(const IR::MAU::Table *tbl, const IR::MAU::Action *default_act,
        cstring &name);

    profile_t init_apply(const IR::Node *root) override {
        profile_t rv = MauInspector::init_apply(root);
        table_ids.clear();
        rev_table_ids.clear();
        non_mutex.clear();
        action_mutex.clear();
        name_to_tables.clear();

        // Populate auxiliary data structures.
        forAllMatching<IR::MAU::Table>(root, [this](const IR::MAU::Table *t) {
            assert(!table_ids.count(t));
            rev_table_ids.emplace(table_ids.size(), t);
            table_ids.emplace(t, table_ids.size());
            name_to_tables.emplace(t->externalName(), t); });
        return rv;
    }

 public:
    bool operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
    bool action(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
};

class SharedIndirectAttachedAnalysis : public MauInspector {
    ordered_map<const IR::MAU::AttachedMemory *,
                safe_vector<const IR::MAU::Table *>> backend_users;
    ordered_map<const IR::MAU::Table *,
          ordered_set<const IR::MAU::Table *>> table_sharing_attached;
    const TablesMutuallyExclusive &mutex;
    const IgnoreTableDeps &ignore;
    const ActionMutuallyExclusive &action_mutex;
    SymBitMatrix _mutex_through_ignore;

    std::map<const IR::MAU::Table *, int>    table_ids;
    std::map<int, const IR::MAU::Table *>    rev_table_ids;

    profile_t init_apply(const IR::Node *root) override {
        profile_t rv = MauInspector::init_apply(root);
        backend_users.clear();
        table_sharing_attached.clear();
        table_ids.clear();
        rev_table_ids.clear();
        _mutex_through_ignore.clear();
        forAllMatching<IR::MAU::Table>(root, [this](const IR::MAU::Table *t) {
            assert(!table_ids.count(t));
            rev_table_ids.emplace(table_ids.size(), t);
            table_ids.emplace(t, table_ids.size()); });
        return rv;
    }
    bool preorder(const IR::MAU::AttachedMemory *) override;
    bool check_attach_action_mutex(const IR::MAU::Table *a, const IR::MAU::Table *b,
                                   const IR::MAU::AttachedMemory *am);

 public:
    bool mutex_through_ignore(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
    // for gtest
    bool if_table_share_attach(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
    explicit SharedIndirectAttachedAnalysis(const TablesMutuallyExclusive &m,
         const IgnoreTableDeps &i, const ActionMutuallyExclusive &a) : mutex(m), ignore(i),
         action_mutex(a) {}
};
#endif /* BF_P4C_MAU_TABLE_MUTEX_H_ */
