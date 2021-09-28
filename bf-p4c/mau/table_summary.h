#ifndef BF_P4C_MAU_TABLE_SUMMARY_H_
#define BF_P4C_MAU_TABLE_SUMMARY_H_

#include <iostream>
#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/device.h"

namespace Logging {
class FileLog;
};

struct PHVTrigger {
    struct failure : public Backtrack::trigger {
        ordered_map<cstring, ordered_set<int>> tableAlloc;
        ordered_map<cstring, ordered_set<int>> internalTableAlloc;
        bool metaInitDisable;
        bool ignorePackConflicts;
        bool firstRoundFit;
        explicit failure(
                ordered_map<cstring, ordered_set<int>> tables,
                ordered_map<cstring, ordered_set<int>> internalTables,
                bool fit,
                bool pack = false,
                bool meta = false)
            : trigger(OTHER), tableAlloc(tables), internalTableAlloc(internalTables),
              metaInitDisable(meta), ignorePackConflicts(pack), firstRoundFit(fit) { }
    };
};

struct NoContainerConflictTrigger {
    struct failure : public Backtrack::trigger {
        bool ignoreContainerConflicts = false;
        explicit failure(bool ig) : trigger(OTHER), ignoreContainerConflicts(ig) {}
    };
};

/************************
 * Table Placement/PHV allocation backtracktracking and retries
 *
 * There are various possible reasons that PHV allocation and/or Table Placement can fail
 * in a way that requires backtracking to redo things and try alternatives to get a working
 * allocation and placement.  We track this with a 'state' in the TableSummary object which
 * tracks what we've tried so far, and will throw an appropriate Backtrack::trigger exception
 * to try something else.
 *
 * If the first attempt at PHV allocation and table placement succeeds, great! we're done.
 * If not, we redo table placement ignoring container conflicts.  After that, we'll redo
 * PHV allocation with flags based on whether the first round fit, the redo fit, and possibly
 * without metadata init.
 *
 * If that redo worked, we're good; otherwise we redo table placement ignoring container
 * conflicts (again) and then redo PHA allocation a third time.
 *
 * Final Placement is a special state we get into after table placement succeeded but needed
 * to allocate more PHV, which requires rerunning PHV then rerunning table placement.
 *
 *  INITIAL ---> NOCC_TRY1 ---> REDO_PHV1 ---> NOCC_TRY2 ---> REDO_PHV2 --> FAILURE
 *    |                             /                             |            ^
 *    \-----------> SUCCESS <------+------------------------------/            |
 *                                  \                                          |
 *                                   FINAL_PLACEMENT---------------------------+
 *
 *
 * In the alternative PHV allocation, AKA table placement first allocation, the workflow is
 * different.
 *
 *  ALT_INITIAL --->  ALT_FINALIZE_TABLE--->  SUCCESS
 *      \                     \
 *    FAILURE               FAILURE
 *
 ************************/

class TableSummary: public MauInspector {
 public:
    static constexpr int NUM_LOGICAL_TABLES_PER_STAGE = 16;
    enum state_t {
        INITIAL,
        NOCC_TRY1,
        REDO_PHV1,
        NOCC_TRY2,
        REDO_PHV2,
        FINAL_PLACEMENT,
        FAILURE,
        SUCCESS,
        ALT_INITIAL,
        ALT_FINALIZE_TABLE,
    };

 private:
    static constexpr int CRITICAL_PATH_THRESHOLD = 2;
    int numInvoked = 0;
    /// true if the first round of table placement resulted in less than Device::numStages() stages.
    bool firstRoundFit = false;
    Logging::FileLog *tsLog = nullptr;
    state_t state = INITIAL;

    /// The total number of stages allocated by Table Placement
    int maxStage;
    int max_stages[3];
    /// Booleans indicating whether traversal over ingress and egress pipes has happened
    bool ingressDone;
    bool egressDone;
    /// Flag if we've found a placement problem that will require retrying.  Strings are
    // error messages to output if we can't backtrack, stored in an ordered_map to suppress
    // duplicates.  Flag is true if the error should be output as an error and false if it
    // should just be a warning
    ordered_map<cstring, bool> tablePlacementErrors;
    /// flag to prevent any further backtracking after a final RedoTablePlacment.
    bool no_errors_before_summary = true;

    int pipe_id;
    const DependencyGraph& deps;

    /// Map of table name to stage: sent with the backtracking exception to communicate table
    /// placement constraints to PHV allocation
    ordered_map<cstring, ordered_set<int>> tableAlloc;
    /// Map of internal table name to stage: sent with the backtracking exception to communicate
    /// table placement constraints to PHV allocation. This mapping table have a better granularity
    /// to properly map the stage of a match table using various internal construct.
    ordered_map<cstring, ordered_set<int>> internalTableAlloc;
    /// Map of table name to the name of the gateway merged with it
    ordered_map<cstring, cstring> mergedGateways;
    /// Map of table pointers to the names used for communicating table placement information
    ordered_map<cstring, cstring> tableNames;

    std::map<int, const IR::MAU::Table *>    order;
    std::map<int, std::unique_ptr<IXBar>>    ixbar;
    std::map<int, std::unique_ptr<Memories>> memory;
    std::map<int, ActionDataBus>             action_data_bus;
    std::map<int, InstructionMemory>         imems;

    /// Sum of all resources being used for all stages on last pass
    StageUseEstimate allStages;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Table* t) override;
    void postorder(const IR::BFN::Pipe* pipe) override;
    void end_apply() override;

    /// Prints the stage wise table placement.
    void printTablePlacement();

 public:
    explicit TableSummary(int pipe_id, const DependencyGraph& dg);

    /// @returns the P4 name for tables with an external name (non-gateways). @returns the
    /// compiler-generated name otherwise.
    static cstring getTableName(const IR::MAU::Table* tbl);

    /// @return the set of stages to which table @t has been allocated. optional internal flag
    /// can be used to retrieve the information from the internalTableAlloc map.
    const ordered_set<int> stages(const IR::MAU::Table* tbl, bool internal = false) const;

    /// @returns the maximum number of stages used by the program.
    int maxStages() const { return maxStage; }
    int maxStages(gress_t gress) const { return max_stages[gress]; }

    const ordered_map<cstring, ordered_set<int>>& getTableAlloc(void) const { return tableAlloc; }

    // only called by TablePlacement
    void addPlacementError(cstring msg) { tablePlacementErrors[msg] = true; }
    void addPlacementWarnError(cstring msg) { tablePlacementErrors[msg] |= false; }
    void clearPlacementErrors() { tablePlacementErrors.clear(); }
    int placementErrorCount() { return tablePlacementErrors.size(); }
    /// set state to FINAL_PLACEMENT, or ALT_FINALIZE_TABLE if alt-phv-alloc is enabled.
    void FinalizePlacement();
    void resetPlacement() { state = INITIAL; }
    state_t getActualState() const { return state; }
    void setAllStagesResources(const StageUseEstimate use) { allStages = use; }
    StageUseEstimate getAllStagesResources() const { return allStages; }

    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* BF_P4C_MAU_TABLE_SUMMARY_H_ */
