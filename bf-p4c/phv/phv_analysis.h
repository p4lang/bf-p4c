#ifndef BF_P4C_PHV_PHV_ANALYSIS_H_
#define BF_P4C_PHV_PHV_ANALYSIS_H_

#include "ir/ir.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/parser_critical_path.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "bf-p4c/phv/analysis/pack_conflicts.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

class ClotInfo;

class PHV_AnalysisPass : public PassManager {
 private:
    MauBacktracker& table_alloc;                         // contains information about placement of
                                                        // tables by an earlier table allocation
                                                        // pass
    Clustering clustering;
    CalcParserCriticalPath parser_critical_path;        // parser critical path of both
                                                        // ingress/egress

    CalcCriticalPathClusters critical_path_clusters;    // critical clusters
    TablesMutuallyExclusive table_mutex;                // Mutual exclusion information for tables
    ActionMutuallyExclusive action_mutex;               // Mutual exclusion information for actions
    PackConflicts pack_conflicts;                       // No pack conflicts generated from earlier
                                                        // table allocation pass
    ActionPhvConstraints action_constraints;            // Action induced constraints for packing
    PHV::Pragmas pragmas;
    ordered_set<const PHV::Field*> deparser_zero_fields;    // Fields that are going to be deparsed
                                                            // to zero
    const BFN_Options &_options;
    Logging::FileLog *paLog = nullptr;

 public:
    PHV_AnalysisPass(const BFN_Options &options, PhvInfo &phv, PhvUse &uses, const ClotInfo &clot,
                     FieldDefUse &defuse, DependencyGraph &deps, MauBacktracker& alloc);

    profile_t init_apply(const IR::Node *root) override {
        static unsigned int iteration = 0;
        if (_options.verbose) {
            cstring logName("phv_allocation_" + std::to_string(iteration++) + ".log");
            paLog = new Logging::FileLog(logName);
            std::clog << "PHV Allocation Pass seqNo: " << seqNo << std::endl;
        }
        return PassManager::init_apply(root);
    }
    void end_apply() override {
        if (paLog != nullptr) {
            delete paLog;
            paLog = nullptr;
        }
        PassManager::end_apply();
    }
};

#endif /* BF_P4C_PHV_PHV_ANALYSIS_H_ */
