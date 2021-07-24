#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/mau/finalize_mau_pred_deps_power.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/mau_alloc.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/decaf.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/utils/live_range_report.h"

class FieldDefUse;
struct CollectPhvLoggingInfo;

namespace BFN {

class Backend : public PassManager {
    BFN_Options options;
    ClotInfo clot;
    PhvInfo phv;
    PhvUse uses;
    DependencyGraph deps;
    FieldDefUse defuse;
    TablesMutuallyExclusive mutex;
    DeparserCopyOpt decaf;
    /// Class that represents the backtracking point from table placement to PHV allocation.
    MauBacktracker mau_backtracker;
    TableSummary table_summary;
    TableAllocPass table_alloc;
    // Primitives Json Node, is populated before instruction adjustment and
    // passed to AsmOutput to output primitive json file
    Util::JsonObject primNode;
    // Dependency Flow Graph Json, is a collection of graphs populated when
    // passed as a parameter to FindDependencyGraph pass. By default graphs are
    // generated once before and once after table placement.
    Util::JsonObject jsonGraph;

    LogFlexiblePacking *flexibleLogging;
    CollectPhvLoggingInfo *phvLoggingInfo;
    DynamicNextTable nextTblProp;
    MauPower::FinalizeMauPredDepsPower* power_and_mpr;
    LiveRangeReport *liveRangeReport;

 protected:
    profile_t init_apply(const IR::Node *root) override {
        BFNContext::get().setBackendOptions(&options);
        PhvInfo::resetDarkSpillARA();
        return PassManager::init_apply(root); }

    void end_apply() override { BFNContext::get().clearBackendOptions(); }

 public:
    explicit Backend(const BFN_Options& options, int pipe_id);

    BFN_Options &get_options() { return options; }

    const PhvInfo       &get_phv()     const { return phv; }
    const ClotInfo      &get_clot()    const { return clot; }
    const FieldDefUse   &get_defuse()  const { return defuse; }
    const MauPower::FinalizeMauPredDepsPower* get_power_and_mpr() const { return power_and_mpr; }
    const NextTable *get_nxt_tbl() const { return &nextTblProp; }
    const TableSummary &get_tbl_summary() const { return table_summary; }
    const LiveRangeReport *get_live_range_report() const { return liveRangeReport; }
    const Util::JsonObject &get_prim_json() const { return primNode; }
    const Util::JsonObject &get_json_graph() const { return jsonGraph; }
    const LogRepackedHeaders *get_flexible_logging() const {
        return flexibleLogging->get_flexible_logging(); }
    const CollectPhvLoggingInfo *get_phv_logging() const { return phvLoggingInfo; }
    const ordered_map<cstring, ordered_set<int>>& get_table_alloc() const {
        return table_summary.getTableAlloc();
    }
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
