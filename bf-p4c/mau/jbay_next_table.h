#ifndef EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_
#define EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_

#include "mau_visitor.h"
#include "lib/dyn_vector.h"


/* This pass determines next table propagation in tofino2. It minimizes the use of long branches
 * whenever possible by "pushing down" next table propagation to tables in the table sequence and
 * using global_exec/local_exec instead. This pass must be run after modifications to table graph
 * are done, otherwise its data will be invalidated.
 */
class NextTableProp : public MauModifier {
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
        UniqueId         id;
        // The type of propagation
        next_t           type;
        // The stage that this table is placed in
        int              stage;
        // Long branch information (if it's needed)
        LBInfo           lb;

        bool operator==(const NextTable& other) const {
            return (id == other.id && type == other.type);
        }
        bool operator<(const NextTable& other) const {
            return id < other.id;
        }
    };

    // Map from tables->conditions->sets of tables that need to occur next
    using next_map_t =
        std::map<UniqueId, std::unordered_map<cstring, std::set<NextTable>>>;
    next_map_t props;

 private:
    // Adds a table and corresponding table sequence to props map
    void add_table_seq(const IR::MAU::Table* t, std::pair<cstring, const IR::MAU::TableSeq*> next);

    /* For long_branch allocation: track usage of tags x stages so far.  In theory two uses could
     * overlap by a single stage (the last stage, where the tag is terminated, is the stage where
     * another sets it for a different use), but ONLY if the uses are in the samre thread.  For
     * timing reasons, we can't do this if one use is ingress and the other egress.  For now, we
     * don't even try */
    dyn_vector<bitvec>                  stage_use;
    /* track usage of stages x tags */
    // dyn_vector<dyn_vector<LBInfo*>>      use;
    // Allocates a long_branch according to global use of lb tags
    void alloc(NextTable& nt, int first_stage);

    // build table x stage maps
    bool preorder(IR::MAU::Table*) override;

    // Setup and clear
    profile_t init_apply(const IR::Node *root) override {
        props.clear();
        return MauModifier::init_apply(root);
    }
};

#endif /* EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_ */
