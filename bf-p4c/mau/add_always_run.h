#ifndef BF_P4C_MAU_ADD_ALWAYS_RUN_H_
#define BF_P4C_MAU_ADD_ALWAYS_RUN_H_

#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/table_flow_graph.h"

/// Adds a set of Tables to the IR so that they are executed on all paths through the program. As
/// input, each inserted table comes with a set of constraints, specifying which pipeline units
/// (i.e., parser, table, or deparser) the inserted table must come before or after.
class AddAlwaysRun : public PassManager {
    friend class AddAlwaysRunTest;

 public:
    /// Expresses the constraints for inserting a table into the IR. The first element of the pair
    /// is the set of tables that must come before the inserted table; the second element
    /// identifies tables that must come after. Here, UniqueIds (as returned by
    /// IR::MAU::Table::pp_unique_id) are used to identify tables in the pipeline.
    using InsertionConstraints = std::pair<std::set<UniqueId>, std::set<UniqueId>>;

    /// Maps tables to their corresponding constraints for insertion into the IR.
    using ConstraintMap = ordered_map<const IR::MAU::Table*, InsertionConstraints>;

 private:
    /// The tables to be added for each gress, mapped to the tables' constraints.
    const ordered_map<gress_t, ConstraintMap>& allTablesToAdd;

    /// Holds the control-flow graph for each gress in which a table is to be added. Cleared and
    /// recomputed every time this pass manager is run.
    ordered_map<gress_t, FlowGraph> flowGraphs;

    /// Performs the actual insertion of tables into the IR.
    class AddTables : public MauTransform {
        AddAlwaysRun& self;

        /// A global ordering of the tables in each gress, including the tables being added. When
        /// tables are inserted into the IR, it is done so that all execution paths are consistent
        /// with this ordering. The ordering is represented as a map from each table to its
        /// position in the ordering. Only contains gresses that have tables being added.
        std::map<gress_t, ordered_map<const IR::MAU::Table*, unsigned>> globalOrderings;

        /// The list of remaining always-run tables to be added to the IR for the current gress
        /// being visited. This is sorted according to the order given by globalOrderings. Tables
        /// are popped off the front of this list as they are added to the IR.
        //
        // Invariant: this is empty at the start and end of each visit to each gress.
        std::list<const IR::MAU::Table*> tablesToAdd;

        /**
         * The table that will be executed after the current branch is done executing. For example,
         * in the following IR fragment, while the subtree rooted at t1 is visited, subsequentTable
         * will be t7; while the subtree rooted at t2 is visited, subsequentTable will be t3. This
         * is nullptr when there is no subsequent table (i.e., if control flow would exit to the
         * deparser).
         *
         *          [ t1  t7 ]
         *           /  \
         *    [t2  t3]  [t6]
         *    /  \
         * [t4]  [t5]
         */
        const IR::MAU::Table* subsequentTable;

        profile_t init_apply(const IR::Node* root) override;
        const IR::BFN::Pipe* preorder(IR::BFN::Pipe*) override;
        const IR::Node* preorder(IR::MAU::TableSeq*) override;
        const IR::Node* preorder(IR::MAU::Table*) override;

        AddTables* clone() const override;
        AddTables& flow_clone() override;
        void flow_merge(Visitor& v) override;

        /// Comparison for Tables according to globalOrderings. The result is less than 0 if t1
        /// comes before t2, equal to 0 if t1 is the same as t2, and greater than 0 otherwise.
        /// Think of this as returning something like "t1 - t2". Tables that are nullptr are
        /// considered to come after all other tables.
        int compare(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const;

        AddTables(const AddTables&) = default;
        AddTables(AddTables&&) = default;

     public:
        explicit AddTables(AddAlwaysRun& self) : self(self) {}
    };

 public:
    explicit AddAlwaysRun(const ordered_map<gress_t, ConstraintMap>& tablesToAdd);
};

#endif /* BF_P4C_MAU_ADD_ALWAYS_RUN_H_ */
