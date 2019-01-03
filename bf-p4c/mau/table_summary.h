#ifndef BF_P4C_MAU_TABLE_SUMMARY_H_
#define BF_P4C_MAU_TABLE_SUMMARY_H_

#include <iostream>
#include <map>
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/device.h"

struct PHVTrigger {
    struct failure : public Backtrack::trigger {
        ordered_map<cstring, ordered_set<int>> tableAlloc;
        bool metaInitDisable;
        explicit failure(ordered_map<cstring, ordered_set<int>> tables, bool meta)
            : trigger(OTHER), tableAlloc(tables), metaInitDisable(meta) {
        }
    };
};

struct NoContainerConflictTrigger {
    struct failure : public Backtrack::trigger {
        bool ignoreContainerConflicts = false;
        explicit failure(bool ig) : trigger(OTHER), ignoreContainerConflicts(ig) {}
    };
};

class TableSummary: public MauInspector {
    static constexpr int NUM_LOGICAL_TABLES_PER_STAGE = 16;
    static int numInvoked[4];
    Logging::FileLog *tsLog = nullptr;

    /// The total number of stages allocated by Table Placement
    int maxStage;
    /// Booleans indicating whether traversal over ingress and egress pipes has happened
    bool ingressDone;
    bool egressDone;
    /// Flag if we've found a placement problem that will require retrying
    bool placementFailure;

    int pipe_id;

    /// Map of table name to stage: sent with the backtracking exception to communicate table
    /// placement constraints to PHV allocation
    ordered_map<cstring, ordered_set<int>> tableAlloc;
    /// Map of table name to the name of the gateway merged with it
    ordered_map<cstring, cstring> mergedGateways;
    /// Map of table pointers to the names used for communicating table placement information
    ordered_map<cstring, cstring> tableNames;

    std::map<int, const IR::MAU::Table *>    order;
    std::map<int, IXBar>                     ixbar;
    std::map<int, Memories>                  memory;
    std::map<int, ActionDataBus>             action_data_bus;
    std::map<int, InstructionMemory>         imems;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Table* t) override;
    void postorder(const IR::BFN::Pipe* pipe) override;
    void end_apply() override;

    /// Prints the stage wise table placement.
    void printTablePlacement();
    /// Throws the appropriate backtracking exception if table placement is not successful.
    void throwBacktrackException();

 public:
    explicit TableSummary(int pipe_id) : pipe_id(pipe_id) {}
    /// @returns the P4 name for tables with an external name (non-gateways). @returns the
    /// compiler-generated name otherwise.
    static cstring getTableName(const IR::MAU::Table* tbl);

    /// @return the set of stages to which table @t has been allocated.
    const ordered_set<int> stages(const IR::MAU::Table* tbl) const;

    /// @returns the maximum number of stages used by the program.
    int maxStages() const { return maxStage; }

    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* BF_P4C_MAU_TABLE_SUMMARY_H_ */
