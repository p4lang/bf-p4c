#ifndef BF_P4C_MAU_TABLE_SUMMARY_H_
#define BF_P4C_MAU_TABLE_SUMMARY_H_

#include <iostream>
#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"

struct PHVTrigger {
    struct failure : public Backtrack::trigger {
        ordered_map<cstring, int> tableAlloc;
        explicit failure(ordered_map<cstring, int> tables)
            : trigger(OTHER), tableAlloc(tables) {}
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
    static constexpr int NUM_STAGES = 12;
    static int numInvoked;

    /// The total number of stages allocated by Table Placement
    int maxStage;
    /// Booleans indicating whether traversal over ingress and egress pipes has happened
    bool ingressDone;
    bool egressDone;

    /// Map of table name to stage: sent with the backtracking exception to communicate table
    /// placement constraints to PHV allocation
    ordered_map<cstring, int> tableAlloc;

    std::map<int, const IR::MAU::Table *>    order;
    std::map<int, IXBar>                     ixbar;
    std::map<int, Memories>                  memory;
    std::map<int, ActionDataBus>             action_data_bus;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Table* t) override;
    void postorder(const IR::BFN::Pipe* pipe) override;
    void end_apply() override;

    void printTablePlacement();
    void throwBacktrackException();

 public:
    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* BF_P4C_MAU_TABLE_SUMMARY_H_ */
