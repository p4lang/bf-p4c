#ifndef EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_
#define EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_

#include "mau_visitor.h"
#include "lib/dyn_vector.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/table_layout.h"

/* This pass determines next table propagation in tofino2. It minimizes the use of long branches
 * whenever possible by "pushing down" next table propagation to tables in the table sequence and
 * using global_exec/local_exec instead. This pass must be run after modifications to table graph
 * are done, otherwise its data will be invalidated.
 */
class NextTableProp : public PassManager {
 public:
    // Different kinds of next table propagation
    enum next_t {LOCAL_EXEC, GLOBAL_EXEC, LONG_BRANCH};

    // Container for long branch information
    struct LBInfo {
        // The stage from which the LB originates
        int              first_stage = -1;
        // The range that the long_branch is active on
        bitvec           rng;
        int              tag = -1;
    };

    // Container for table IDs, as well as how the next table will be propagated to it
    struct NextTable {
        NextTable(const IR::MAU::Table* t, next_t ty);
        // ID of this table
        const UniqueId         id;
        // The type of propagation
        const next_t           type;
        // The stage that this table is placed in
        const int              stage;
        // Long branch information (if it's needed)
        LBInfo                 lb;

        bool operator==(const NextTable& other) const {
            return (id == other.id && type == other.type && stage == other.stage);
        }
        bool operator<(const NextTable& other) const {
            return id < other.id;
        }
    };

    // Map from tables->condition (tseq names)->sets of tables that need to occur next
    using next_map_t =
        std::map<UniqueId, std::unordered_map<cstring, std::set<NextTable>>>;
    next_map_t props;

    NextTableProp();

 private:
    // Gets the unique id for a table, depending on whether the table is placed or not
    static inline UniqueId get_uid(const IR::MAU::Table*);

    // Map from stage to number of tables in it
    std::map<int, int> stage_cap;
    // Map from stage to tables
    std::map<int, Memories> mems;
    // Map from stage to max logical ID
    std::map<int, int> stage_id;

    // Collect stage to table information to facilitate conversion of LBs to GE
    class EmptyIds : public MauInspector {
        NextTableProp& self;
        profile_t init_apply(const IR::Node* root) override {
            self.stage_cap.clear();
            self.mems.clear();
            self.stage_id.clear();
            return MauInspector::init_apply(root);
        }
        bool preorder(const IR::MAU::Table*) override;
     public:
        explicit EmptyIds(NextTableProp& ntp) : self(ntp) {}
    };


    // Map from table sequences to dumb tables to add to sequence
    std::map<const IR::MAU::TableSeq*, std::vector<IR::MAU::Table*>> dumb_tbls;
    // Set of tables to make set always_run to true
    std::set<UniqueId> al_runs;

    // Allocates long branches, finds where new tables are necessary
    class NextTableAlloc : public MauInspector {
     private:
        // Parent PassManager
        NextTableProp& self;

        // Holds information for propagating a single table sequence
        struct NTInfo;

        // Propagate tables for this table
        bool preorder(const IR::MAU::Table*) override;
        // Adds a table and corresponding table sequence to props map
        void add_table_seq(const IR::MAU::Table*, std::pair<cstring, const IR::MAU::TableSeq*>);
        // Calculates and adds local (same stage) propagation
        void local_prop(NTInfo& nti);
        // Adds useful dumb tables
        void find_dummies(NTInfo& nti);
        // Calculates cross stage propagation
        void cross_prop(NTInfo& nti);
        // Map from stage to dumb tables that need memory allocation
        std::map<int, std::vector<IR::MAU::Table*>> stage_dumbs;

        /* For long_branch allocation: track usage of tags x stages so far.  In theory two uses
         * could overlap by a single stage (the last stage, where the tag is terminated, is the
         * stage where another sets it for a different use), but ONLY if the uses are in the samre
         * thread.  For timing reasons, we can't do this if one use is ingress and the other egress.
         * For now, we don't even try */
        dyn_vector<bitvec>                  stage_use;
        /* track usage of stages x tags */
        // dyn_vector<dyn_vector<LBInfo*>>      use;
        // Allocates a long_branch according to global use of lb tags
        void alloc_lb(NextTable* nt, int first_stage);
        // Merges a long branch with an existing one
        void merge_lb(NextTable* prev, NextTable* nt);

        // Setup and clear
        profile_t init_apply(const IR::Node *root) override {
            self.props.clear();
            return MauInspector::init_apply(root);
        }

        // Allocates resources for dumb tables and pretty prints
        void end_apply() override;
        // Capture information for pretty printing long branches (tag # -> src stage # -> src,dest)
        std::map<int, std::map<int, std::pair<const IR::MAU::Table*, const IR::MAU::Table*>>> lb_pp;
        // Log that captures pretty printing info
        std::stringstream log;
        void pretty_print();

     public:
        explicit NextTableAlloc(NextTableProp& ntp) : self(ntp) {}
    };

    class AddDumbTables : public MauTransform {
     private:
        NextTableProp& self;
        // Add specified tables to table sequences
        IR::Node* preorder(IR::MAU::TableSeq*) override;
        // Add always_run tags
        IR::Node* preorder(IR::MAU::Table*) override;
     public:
        explicit AddDumbTables(NextTableProp& ntp) : self(ntp) {}
    };
};

#endif /* EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_ */
