#ifndef BF_P4C_PHV_MAU_BACKTRACKER_H_
#define BF_P4C_PHV_MAU_BACKTRACKER_H_

#include "ir/ir.h"
#include "lib/ordered_map.h"
#include "bf-p4c/mau/table_summary.h"

/** When backtracking, this class contains members that save the generated table placement (without
  * container conflicts) for use by the second round of PHV allocation
  */
class MauBacktracker : public Inspector, Backtrack {
 private:
    static constexpr unsigned NUM_LOGICAL_TABLES_PER_STAGE = 16;
    /// To keep track of the number of times this pass has been invoked
    static int numInvoked;

    /// Store a map of table names to stage, used as reference by the second round of PHV allocation
    /// (after a backtrack exception has been thrown by TableSummary)
    ordered_map<cstring, int> tables;

    /// Store the number of stages required by table allocation
    int maxStage = -1;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply() override;

    /// This is the function that catches the backtracking exception from TableSummary. This should
    /// return true.
    bool backtrack(trigger &) override;

 public:
    /// @returns the stage number if tables @t1 and @t2 are placed in the same stage
    /// @returns -1 if tables are not in the same stage
    int inSameStage(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const;

    /// Prints the table allocation received by MauBacktracker by means of the backtrack trigger
    void printTableAlloc() const;

    /// @returns true if the MauBacktracker class has any information about table placement (found
    /// in the tables map
    bool hasTablePlacement() const;

    /// @returns that stage in which table @t was placed
    int stage(const IR::MAU::Table* t) const;

    /// @returns the number of stages in the table allocation
    int numStages() const;
};

#endif /* BF_P4C_PHV_MAU_BACKTRACKER_H_ */
