#ifndef BF_P4C_COMMON_MULTIPLE_APPLY_H_
#define BF_P4C_COMMON_MULTIPLE_APPLY_H_

#include <set>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/table_mutex.h"
#include "lib/ordered_set.h"
#include "lib/ordered_map.h"

class MultipleApply : public PassManager {
    // gtest requirements
    std::set<cstring> mutex_errors;
    std::set<cstring> distinct_errors;
    std::set<cstring> gateway_chain_errors;

    TablesMutuallyExclusive mutex;
    class MutuallyExclusiveApplies : public MauInspector {
        TablesMutuallyExclusive &mutex;
        std::set<cstring> &errors;
        ordered_map<const IR::P4Table *, ordered_set<const IR::MAU::Table *>> mutex_apply;
        void postorder(const IR::MAU::Table *) override;

     public:
        explicit MutuallyExclusiveApplies(TablesMutuallyExclusive &m, std::set<cstring> &e)
            : mutex(m), errors(e) {}
    };

    struct tail_info_t {
        size_t                  len = 0;        // length of the common tail
        const IR::MAU::TableSeq *other = 0;     // other seq with common tail
        const IR::MAU::TableSeq *tail = 0;      // tail chosen/created in MergeTails
    };
    typedef ordered_map<const IR::MAU::TableSeq *, tail_info_t> eq_tail_t;
    class EquivalentTableSequence : public MauInspector {
        eq_tail_t &equiv_tails;
        ordered_set<const IR::MAU::TableSeq *> unique_seqs;

        profile_t init_apply(const IR::Node *) override;
        void postorder(const IR::MAU::TableSeq *) override;
        bool equiv(const IR::MAU::Table *a, const IR::MAU::Table *b);
        bool equiv(const IR::MAU::TableSeq *a, const IR::MAU::TableSeq *b);
        size_t tail_equiv(const IR::MAU::TableSeq *a, const IR::MAU::TableSeq *b);
        bool equiv_gateway(const IR::Expression *a, const IR::Expression *b);

     public:
        explicit EquivalentTableSequence(eq_tail_t &et) : equiv_tails(et) {}
    };

    class MergeTails : public MauTransform {
        eq_tail_t               &equiv_tails;
        std::set<cstring>       names;

        const IR::BFN::Pipe *preorder(IR::BFN::Pipe *) override;
        const IR::BFN::Pipe *postorder(IR::BFN::Pipe *) override;
        const IR::MAU::TableSeq *postorder(IR::MAU::TableSeq *) override;
     public:
        explicit MergeTails(eq_tail_t &et) : equiv_tails(et) {}
    };

    class DistinctTables : public MauInspector {
        std::set<cstring> &errors;
        ordered_set<const IR::P4Table *> distinct_tables;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit DistinctTables(std::set<cstring> &e) : errors(e) {}
    };

    class UniqueGatewayChain : public MauInspector {
        std::set<cstring> &errors;
        ordered_map<const IR::P4Table *, safe_vector<const IR::MAU::Table *>> gateway_chains;
        bool preorder(const IR::MAU::Table *) override;

     public:
        explicit UniqueGatewayChain(std::set<cstring> &e) : errors(e) { visitDagOnce = false; }
    };

    eq_tail_t equiv_tails;

 public:
    bool mutex_error(cstring name) {
        return mutex_errors.find(name) != mutex_errors.end();
    }

    bool distinct_error(cstring name) {
        return distinct_errors.find(name) != distinct_errors.end();
    }

    bool gateway_chain_error(cstring name) {
        return gateway_chain_errors.find(name) != gateway_chain_errors.end();
    }

    MultipleApply();
};

/// The purpose of this set of passes is three-fold:
///
///   * The extract_maupipe code creates a separate Table object for each table call. This set of
///     passes de-duplicates these Table objects so that each table in the program is represented
///     by a single object.
///
///   * It checks the invariant that the conditional control flow that follows each table is the
///     same across all calls of that table. This rules out the following program, in which the
///     conditional behaviour on t2 depends on whether t1 hit or missed.
///
///       if (t1.apply().hit) {
///         switch (t2.apply().action_run) {
///           a1: { t3.apply(); }
///         }
///       } else {
///         switch (t2.apply().action_run) {
///           a1: { t4.apply(); }
///         }
///       }
///
///   * It checks the invariant that the tables have a topological order, as they appear in the
///     program text. This rules out the following program, in which t2 and t3 are applied in the
///     opposite order in two branches of the program.
///
///       switch (t1.apply().action_run) {
///         a1: { t2.apply(); t3.apply(); }
///         a2: { t3.apply(); t2.apply(); }
///       }
///
///     In principle, this invariant can be relaxed to say that the tables must form a DAG in the
///     program dependence graph; i.e., the above program would be admissible if there are no data
///     dependences between t2 and t3. This would require normalizing the order of tables, which we
///     don't currently do. For now, we do the simpler, more restrictive thing, and can do the more
///     relaxed thing in the future.
class MultipleApply2 : public PassManager {
    /// Gives the canonical Table object for each P4Table.
    ordered_map<const IR::P4Table *, const IR::MAU::Table *> canon_table;

    /// The set of tables that need to be de-duplicated.
    ordered_set<const IR::MAU::Table *> to_replace;

    /// Checks the invariant that the conditional control flow that follows each table is the same
    /// across all calls of that table. It also populates @canon_table for DeduplicateTables.
    class CheckStaticNextTable : public MauInspector {
        MultipleApply2 &self;
        void postorder(const IR::MAU::Table *) override;

     public:
        explicit CheckStaticNextTable(MultipleApply2 &s) : self(s) { }
    };

    /// De-duplicates Table objects using @canon_table.
    class DeduplicateTables : public MauTransform {
        MultipleApply2 &self;
        const IR::Node *preorder(IR::MAU::Table *) override;

     public:
        explicit DeduplicateTables(MultipleApply2 &s) : self(s) { }
    };

    /// Checks the invariant that tables have a topological order. This is done by using
    /// FindFlowGraph to build a control-flow graph for tables and checking that there are no
    /// cycles.
    ///
    /// This pass assumes that Table objects have been de-duplicated.
    class CheckTopologicalTables : public MauInspector {
    };

 public:
    // Allow disabling of topology checking for gtests.
    explicit MultipleApply2(bool check_topology = true);
};


#endif /* BF_P4C_COMMON_MULTIPLE_APPLY_H_ */
