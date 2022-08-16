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
        ordered_map<cstring, std::pair<cstring, cstring>> mergedGateways;
        bool metaInitDisable;
        bool ignorePackConflicts;
        bool firstRoundFit;
        explicit failure(
                ordered_map<cstring, ordered_set<int>> tables,
                ordered_map<cstring, ordered_set<int>> internalTables,
                ordered_map<cstring, std::pair<cstring, cstring>> mergedGateways,
                bool fit,
                bool pack = false,
                bool meta = false)
            : trigger(OTHER), tableAlloc(tables), internalTableAlloc(internalTables),
              mergedGateways(mergedGateways), metaInitDisable(meta),
              ignorePackConflicts(pack), firstRoundFit(fit) { }
    };
};

struct RerunTablePlacementTrigger {
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
 *                  SUCCESS
 * ALT_INITIAL --------------------->  ALT_FINALIZE_TABLE_SAME_ORDER ------------> SUCCESS
 * (Trivial alloc)            ^   (with order suggested by previous round)
 * ( + Default TP)            |                          |
 *    |                       |                          |
 *    |                       |                      (FAILURE)
 * (FAILURE)              (SUCCESS)                      |
 *    |                       |                          V
 *    |                       |                   ALT_FINALIZE_TABLE --> SUCCESS / FAILURE
 *    .------------> ALT_RETRY_ENHANCED_TP        ( Default TP
 *                   (Default TP + backtracki      + backtracking
 *                     ( + resource-based)         + resource-based)
 *                            |
 *                            |
 *                            .--> FAILURE
 *
 ******************************************************************************************/

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
        ALT_RETRY_ENHANCED_TP,
        ALT_FINALIZE_TABLE_SAME_ORDER,
        ALT_FINALIZE_TABLE,
        FINAL,  // always keep as last state for bounds checking
    };

    // This struct represents a placed table and its relevant info as necessary
    // for future table placement / phv allocation rounds. It can / should be
    // extended to add more info as required
    // TBD: Some of the info overlaps with other maps which should be eventually
    // depecrated to use the consolidated struct below
    struct PlacedTable {
        cstring tableName;
        cstring internalTableName;
        cstring gatewayName;
        cstring gatewayMergeCond;
        int stage;
        unsigned logicalId;
        int entries;

        ordered_map<cstring, int> attached_entries;

        explicit PlacedTable(const IR::MAU::Table *t);
        void add(const IR::MAU::Table *t);
        cstring dumpStr();
    };

 private:
    static constexpr int CRITICAL_PATH_THRESHOLD = 2;
    int numInvoked = 0;
    /// true if the first round of table placement resulted in less than Device::numStages() stages.
    bool firstRoundFit = false;
    Logging::FileLog *tsLog = nullptr;
    state_t state = INITIAL;
    // Save the previous state in case we have to rollback to this one.
    state_t prev_state = INITIAL;

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
    const PhvInfo& phv;

    /// Map of table name to stage: sent with the backtracking exception to communicate table
    /// placement constraints to PHV allocation
    ordered_map<cstring, ordered_set<int>> tableAlloc;
    /// Map of internal table name to stage: sent with the backtracking exception to communicate
    /// table placement constraints to PHV allocation. This mapping table have a better granularity
    /// to properly map the stage of a match table using various internal construct.
    ordered_map<cstring, ordered_set<int>> internalTableAlloc;
    /// Map of table name to the name of the gateway and condition merged with it
    ordered_map<cstring, std::pair<cstring, cstring>> mergedGateways;
    /// Map of table names to the external names used for communicating table placement information
    ordered_map<cstring, cstring> tableNames;
    /// Map of table names to the internal names used for communicating table placement information
    ordered_map<cstring, cstring> tableINames;
    /// Map of table name to the IR pointer of the table
    static ordered_map<cstring, std::set<const IR::MAU::Table*>> tblName2IRptr;

    // Map of Global ID (Stage + Logical Id) -> Placed Table
    std::map<int, PlacedTable*> placedTables;

    // Map of Global ID -> Table
    std::map<int, const IR::MAU::Table *> order;
    // Map of Stage -> All Tables in stage
    std::map<int, std::set<const IR::MAU::Table *>> tables;
    // Map of Field Name -> Map of Field Slice -> Map of Stage -> No. of IXBar
    // Bytes
    // E.g.
    // { hdr.ipv4.dstAddr, {
    //      { (0:31), {   // For Slice 0..31
    //          { 1, 4 }, // Stage 1 has 4 bytes
    //          { 2, 4 }  // Stage 2 has 4 bytes
    //        }
    //      }, { (32:47), { // For Slice 32..47
    //          { 1, 2 },   // Stage 1 has 2 bytes
    //          { 2, 4 }    // Stage 2 has 4 bytes
    //         }
    //      }
    //   ...
    //  }
    std::map<cstring, std::map<le_bitrange, std::map<int, int>>> ixbarBytes;
    // For ixbar/memory/action_data_bus/imems:  Tofino 1/2/3 share the pipe between
    // ingress and egress, so every will be in the [0] element of these arrays.
    // Tofino 5 has independent pipes for ingress([0]) and egress([1])
    // Array of Map of Stage -> Input Xbar
    std::map<int, std::unique_ptr<IXBar>> ixbar[2];
    // Map of Stage -> Memories
    std::map<int, std::unique_ptr<Memories>> memory[2];
    // Map of Stage -> ActionDataBus
    std::map<int, std::unique_ptr<ActionDataBus>> action_data_bus[2];
    // Map of Stage -> InstructionMemory
    std::map<int, std::unique_ptr<InstructionMemory>> imems[2];
    // Map of Table Name -> logical id
    std::map<cstring, unsigned> logical_ids;

    /// Sum of all resources being used for all stages on last pass
    StageUseEstimate allStages;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Table* t) override;
    void postorder(const IR::BFN::Pipe* pipe) override;
    void end_apply() override;

    /// Prints the stage wise table placement.
    void printTablePlacement();

    /// Populates ixbarBytes data structure with no. of input xbar bytes used
    /// per field slice per stage
    /// Note; Funciton uses table pointers which can get obsolete outside the
    /// pass
    void generateIxbarBytesInfo();

 public:
    explicit TableSummary(int pipe_id, const DependencyGraph& dg, const PhvInfo &phv);

    /// @returns the compiler-generated internal name for tables. Other passes should
    /// use this name, instead of  externalName returned by getTableName(),
    /// to track tables.
    static cstring getTableIName(const IR::MAU::Table* tbl);

    /// @returns the P4 name for tables with an external name (non-gateways). @returns the
    /// compiler-generated name otherwise.
    static cstring getTableName(const IR::MAU::Table* tbl);

    /// Reset the the tblName2IRptr map
    static void clearTblName2IRptr() { TableSummary::tblName2IRptr.clear(); }

    /// @returns the IR pointer to the table named as @t_name
    static std::set<const IR::MAU::Table*> getTablePtr(const cstring t_name);

    /// Add table pointer into tblName2IRptr map
    static void addTablePtr(const IR::MAU::Table* ptr);

    /// @return the set of stages to which table @p t has been allocated. optional internal flag
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
    const ordered_map<cstring, bool> &getPlacementError() { return tablePlacementErrors; }
    void setPlacementError(const ordered_map<cstring, bool> &tpe) { tablePlacementErrors = tpe; }
    /// set state to INITIAL, or ALT_INITIAL if alt-phv-alloc is enabled.
    void resetPlacement();
    state_t getActualState() const { return state; }
    void setPrevState() { state = prev_state; }
    cstring getActualStateStr() const;
    void setAllStagesResources(const StageUseEstimate use) { allStages = use; }
    StageUseEstimate getAllStagesResources() const { return allStages; }

    std::map<int, PlacedTable*>& getPlacedTables() { return placedTables; }

    // Returns a map of stage and bytes used on ixbar in that stage
    // e.g. field f1 -
    // Stage 1     -> 2 bytes (Normal)
    // Stage 2 - 3 -> 1 byte  (Dark)
    // Stage 4     -> 3 byte  (Normal)
    // Map : {
    // --------------------------
    // Stage | No. of Ixbar Bytes
    // --------------------------
    //  1    |       2
    //  2    |       1
    //  3    |       1
    //  4    |       3
    // --------------------------
    // }
    std::map<int, int> findBytesOnIxbar(const PHV::FieldSlice &slice) const;
    cstring ixbarUsagesStr(const PhvInfo *phv = nullptr) const;
    void printPlacedTables() const;

    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* BF_P4C_MAU_TABLE_SUMMARY_H_ */
