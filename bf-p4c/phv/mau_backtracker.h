#ifndef BF_P4C_PHV_MAU_BACKTRACKER_H_
#define BF_P4C_PHV_MAU_BACKTRACKER_H_

#include "ir/ir.h"
#include "lib/ordered_map.h"
#include "bf-p4c/mau/table_summary.h"

/** When backtracking, this class contains members that save the generated table placement (without
  * container conflicts) for use by the second round of PHV allocation
  */
class MauBacktracker : public Backtrack {
 private:
    static constexpr unsigned NUM_LOGICAL_TABLES_PER_STAGE = 16;
    /// To keep track of the number of times this pass has been invoked
    static int numInvoked;

    /// Store a map of table names to stage, used as reference by the second round of PHV allocation
    /// (after a backtrack exception has been thrown by TableSummary)
    ordered_map<cstring, ordered_set<int>> tables;
    /// Map of table names to stage from a previous round without container conflicts.
    ordered_map<cstring, ordered_set<int>> prevRoundTables;

    /// Set of bridged fields that should be interpreted as no-pack, based on backtracking.
    ordered_set<cstring>    noPackFields;

    /// Store the number of stages required by table allocation
    int maxStage = -1;

    /// @true if metadata initialization must be disabled.
    bool metaInitDisable = false;

    /// @true if PHV allocation must be redone while ignoring pack conflicts.
    bool ignorePackConflicts = false;

    /// @true if PHV allocation and table placement both fit in round 1.
    bool firstRoundFit = false;

    const IR::Node *apply_visitor(const IR::Node *root, const char *) override;

    /// This is the function that catches the backtracking exception from TableSummary. This should
    /// return true.
    bool backtrack(trigger &) override;

    ordered_set<int> inSameStage(
            const IR::MAU::Table* t1,
            const IR::MAU::Table* t2,
            const ordered_map<cstring, ordered_set<int>>& tableMap) const;

 public:
    /// @returns the stage number(s) if tables @t1 and @t2 are placed in the same stage
    /// @returns an empty set if tables are not in the same stage
    ordered_set<int> inSameStage(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const;

    /// Prints the table allocation received by MauBacktracker by means of the backtrack trigger
    void printTableAlloc() const;

    /// @returns true if the MauBacktracker class has any information about table placement (found
    /// in the tables map
    bool hasTablePlacement() const;

    /// @returns the stages in which table @t was placed
    ordered_set<int> stage(const IR::MAU::Table* t) const;

    /// @returns metaInitDisable.
    bool disableMetadataInitialization() const { return metaInitDisable; }

    /// @returns firstRoundFit.
    bool didFirstRoundFit() const { return firstRoundFit; }

    /// @returns true if the associated field with @name is in the noPackFields set.
    bool isNoPackField(cstring name) const {
        return noPackFields.count(name);
    }

    bool happensBefore(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const;

    /// @returns the number of stages in the table allocation
    int numStages() const;

    /// Constructor takes mutually exclusive to be able to clear it before every PHV allocation pass
    MauBacktracker() {}
};

#endif /* BF_P4C_PHV_MAU_BACKTRACKER_H_ */