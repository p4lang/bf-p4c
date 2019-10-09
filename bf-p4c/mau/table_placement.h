#ifndef BF_P4C_MAU_TABLE_PLACEMENT_H_
#define BF_P4C_MAU_TABLE_PLACEMENT_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/ordered_set.h"
#include "bf-p4c/mau/dynamic_dep_metrics.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/backend.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;
class LayoutChoices;
class SharedIndirectAttachedAnalysis;

class TablePlacement : public MauTransform, public Backtrack {
 public:
    TablePlacement(const BFN_Options &, const DependencyGraph *, const TablesMutuallyExclusive &,
                   PhvInfo &, const LayoutChoices &, const SharedIndirectAttachedAnalysis &,
                   SplitAttachedInfo &, TableSummary &);
    struct GroupPlace;
    struct Placed;
    typedef std::map<const IR::MAU::AttachedMemory *, int>      attached_entries_t;

    struct RedoTablePlacement : public Backtrack::trigger {
        RedoTablePlacement() : Backtrack::trigger(OK) {}
    };
    static bool can_duplicate(const IR::MAU::AttachedMemory *);

 protected:
    typedef enum {
        CALC_STAGE,
        PROV_STAGE,
        NEED_MORE,
        SHARED_TABLES,
        PRIORITY,
        DOWNWARD_PROP_DSC,
        LOCAL_DSC,
        LOCAL_DS,
        LOCAL_TD,
        DOWNWARD_DOM_FRONTIER,
        DOWNWARD_TD,
        NEXT_TABLE_OPEN,
        CDS_PLACEABLE,
        CDS_PLACE_COUNT,
        AVERAGE_CDS_CHAIN,
        DEFAULT
    } choice_t;

 private:
    // Note that this is for the DynamicDepMetrics, and refers to their match portion being
    // fully placed.  In order to truly successfully split tables, some information is necessary to
    // capture the potential dependencies removed or added by moving the stateful operation to a
    // later stage
    ordered_set<const IR::MAU::Table *> placed_tables_for_dep_analysis;

    // Names of all tables that have been placed so far in the TablePlacement pass. Note that this
    // is a global set of tables.
    ordered_set<cstring> placed_table_names;

    // Find potential tables to merge into a gateway
    using GatewayMergeChoices = ordered_map<const IR::MAU::Table *, cstring>;
    GatewayMergeChoices gateway_merge_choices(const IR::MAU::Table *table);

    struct TableInfo;
    void log_choice(const Placed *t, const Placed *best, choice_t choice);
    CalculateNextTableProp ntp;
    ControlPathwaysToTable con_paths;
    friend std::ostream &operator<<(std::ostream &out, choice_t choice);
    std::map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    struct TableSeqInfo;
    std::map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
    std::map<const IR::MAU::AttachedMemory *, std::set<const IR::MAU::Table *>> attached_to;
    std::array<bool, 3> table_in_gress = { { false, false, false } };
    std::array<IR::MAU::Table *, 2> starter_pistol = { { nullptr, nullptr } };
    class SetupInfo;
    const BFN_Options &options;
    const DependencyGraph* deps;
    const TablesMutuallyExclusive &mutex;
    PhvInfo &phv;
    const LayoutChoices &lc;
    const SharedIndirectAttachedAnalysis &siaa;
    DynamicDependencyMetrics ddm;
    bool ignoreContainerConflicts = false;
    bool alloc_done = false;
    cstring error_message;
    SplitAttachedInfo &att_info;
    struct RewriteForSplitAttached;

    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &) override;
    IR::Node *preorder(IR::BFN::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *postorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *preorder(IR::MAU::BackendAttached *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const Placed *placed,
        int stage_table = -1, IR::MAU::Table **last = nullptr);
    IR::Vector<IR::MAU::Table> *break_up_dleft(IR::MAU::Table *tbl, const Placed *placed,
        int stage_table = -1);
    void setup_detached_gateway(IR::MAU::Table *tbl, const Placed *placed);
    const Placed *placement;

    /// @returns true if all the metadata initialization induced dependencies for table @t are
    /// satisfied, i.e. all the tables that must be placed before table t (due to ordering imposed
    /// by the live range shrinking pass) have been placed. @returns false otherwise.
    bool are_metadata_deps_satisfied(const IR::MAU::Table* t) const;

    bool is_better(const Placed *a, const Placed *b, choice_t& choice);
    safe_vector<Placed *> try_place_table(const IR::MAU::Table *t, const Placed *done,
                                          const StageUseEstimate &current,
                                          GatewayMergeChoices &gmc);
    Placed *try_place_table(Placed *rv, const StageUseEstimate &current);
    bool try_alloc_all(Placed *next, std::vector<Placed *> whole_stage, const char *what,
                       bool no_memory = false);
    bool try_alloc_ixbar(Placed *next);
    bool try_alloc_format(Placed *next, bool gw_linked);
    bool try_alloc_mem(Placed *next, std::vector<Placed *> whole_stage);
    bool try_alloc_adb(Placed *next);
    bool try_alloc_imem(Placed *next);
    bool pick_layout_option(Placed *next, bool estimate_set);
    bool shrink_estimate(Placed *next, int &srams_left, int &tcams_left, int min_entries);
    bool can_place_with_partly_placed(const IR::MAU::Table *tbl,
        const ordered_set<const IR::MAU::Table *> &partly_placed, const Placed *placed);
    bool initial_stage_and_entries(Placed *rv, int &furthest_stage);
    IR::MAU::Table *create_starter_table(gress_t gress);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const Placed *pl);
    const Placed *add_starter_pistols(const Placed *done, safe_vector<const Placed *> &trial,
        const StageUseEstimate &current);
    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;

    void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *res, int entries);

    TableSummary &summary;
    template <class... Args> void error(Args... args) {
        auto &ctxt = BaseCompileContext::get();
        summary.addPlacementError(ctxt.errorReporter().format_message(args...)); }
    int errorCount() const { return ::errorCount() + summary.placementErrorCount(); }
};

#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
