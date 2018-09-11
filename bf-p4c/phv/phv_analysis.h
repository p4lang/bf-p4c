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
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/field_interference.h"
#include "bf-p4c/phv/analysis/meta_live_range.h"
#include "bf-p4c/phv/analysis/pack_conflicts.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/** This is the main PHV allocation pass manager.
  */
class PHV_AnalysisPass : public PassManager {
 private:
    /// Contains information about placement of tables by an earlier table allocation pass.
    MauBacktracker& table_alloc;
    /// Clustering information for fields.
    Clustering clustering;
    /// Parser critical path of both ingress/egress.
    CalcParserCriticalPath parser_critical_path;
    /// Critical clusters.
    CalcCriticalPathClusters critical_path_clusters;
    /// Mutual exclusion information for tables.
    TablesMutuallyExclusive table_mutex;
    /// Mutual exclusion information for actions.
    ActionMutuallyExclusive action_mutex;
    /// No pack conflicts generated from table allocation pass.
    PackConflicts pack_conflicts;
    /// Action induced packing constraints.
    ActionPhvConstraints action_constraints;
    /// PHV related pragma information.
    PHV::Pragmas pragmas;
    /// Metadata live range overlay potential information based on table dependency graph.
    MetadataLiveRange meta_live_range;
    /// Fields that are going to be deparsed to zero.
    ordered_set<const PHV::Field*> deparser_zero_fields;
    const BFN_Options &_options;
    Logging::FileLog *paLog = nullptr;

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

 public:
    PHV_AnalysisPass(
            const BFN_Options &options,
            PhvInfo &phv,
            PhvUse &uses,
            const ClotInfo &clot,
            FieldDefUse &defuse,
            DependencyGraph &deps,
            MauBacktracker& alloc);
};

#endif  /* BF_P4C_PHV_PHV_ANALYSIS_H_ */
