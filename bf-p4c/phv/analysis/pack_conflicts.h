#ifndef BF_P4C_PHV_ANALYSIS_PACK_CONFLICTS_H_
#define BF_P4C_PHV_ANALYSIS_PACK_CONFLICTS_H_

#include "ir/ir.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"

/** This class is meant to gather information about what fields cannot be packed together because of
  * the constraint that two or more tables in the same stage must not invoke an action that writes
  * the same PHV container.
 */
class PackConflicts : public Inspector {
 private:
    const PhvInfo                   &phv;
    // const DependencyGraph           &dg;
    const TablesMutuallyExclusive   &mutex;
    const MauBacktracker            &bt;
    const ActionMutuallyExclusive   &amutex;

    /// Count for total number of no pack constraints induced by table placement
    size_t                  totalNumSet;

    /// fieldNoPack[i, j] is set to true if field f1 with id i cannot be packed with another field
    /// f2 with id j
    SymBitMatrix            fieldNoPack;

    /// Stores a set of all actions invoked from the key table
    ordered_map<const IR::MAU::Table*, ordered_set<const IR::MAU::Action*>> tableActions;
    /// Stores a set of all fields written in a particular action
    /// xxx(Deep): Change the field here to PHV::FieldSlice for more precise analysis
    ordered_map<const IR::MAU::Action*, ordered_set<const PHV::Field*>> actionWrites;

    profile_t init_apply(const IR::Node *root) override;

    /// Populate the tableActions and actionWrites maps
    bool preorder(const IR::MAU::Action *act) override;

    /// Populate noPack constraints related to learning digests.
    bool preorder(const IR::BFN::Digest* digest) override;

    /// Once the initial information is gathered, generate actual no pack constraints
    void end_apply() override;

    /// Populates fieldNoPack with no pack constraints for fields written by tables @t1 and @t2
    /// If tables are mutually exclusive, then do not generate any no pack constraints for fields
    /// written in actions invoked from those tables.
    /// If two actions are mutually exclusive, do not generate any no pack constraints for fields
    /// written in those actions.
    void generateNoPackConstraints(const IR::MAU::Table* t1, const IR::MAU::Table* t2);

    /// Update the PHV::Field object for every field with the number of fields with which it cannot
    /// be packed
    void updateNumPackConstraints();

 public:
    PackConflicts(const PhvInfo &p, const DependencyGraph &, const TablesMutuallyExclusive &m,
            const MauBacktracker &b, const ActionMutuallyExclusive &a) :
        phv(p), /* dg(d), */ mutex(m), bt(b), amutex(a) {}

    bool hasPackConflict(const PHV::Field* f1, const PHV::Field* f2) const;

    void printNoPackConflicts() const;

    unsigned size() const;
};

#endif  /* BF_P4C_PHV_ANALYSIS_PACK_CONFLICTS_H_ */
