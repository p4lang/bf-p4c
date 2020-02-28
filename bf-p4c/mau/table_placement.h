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


class TablePlacement : public PassManager {
 public:
    typedef ordered_map<const IR::MAU::AttachedMemory *, int>      attached_entries_t;
    const BFN_Options &options;
    const DependencyGraph* deps;
    const TablesMutuallyExclusive &mutex;
    PhvInfo &phv;
    const LayoutChoices &lc;
    const SharedIndirectAttachedAnalysis &siaa;
    CalculateNextTableProp ntp;
    ControlPathwaysToTable con_paths;
    DynamicDependencyMetrics ddm;
    SplitAttachedInfo &att_info;
    TableSummary &summary;

    struct Placed;
    struct RewriteForSplitAttached;
    const TablePlacement::Placed *placement;

    struct TableInfo {
        int uid = -1;
        const IR::MAU::Table *table;
        ordered_set<const IR::MAU::TableSeq *> refs;
        bitvec      parents;    // Tables that invoke seqs containing this table
        bitvec      tables;     // this table and all tables control dependent on it
    };

    struct TableSeqInfo {
        bool root = false;
        int uid = -1;
        bitvec      parents;    // same as 'refs', as a bitvec
        bitvec      tables;     // the tables in the seqence and their control dependent children
        ordered_set<const IR::MAU::Table *> refs;  // parent tables of this seq
    };

    static int placement_round;
    static bool can_duplicate(const IR::MAU::AttachedMemory *);

    std::map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    std::map<cstring, struct TableInfo *> tblByName;
    std::map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
    std::map<const IR::MAU::AttachedMemory *, std::set<const IR::MAU::Table *>> attached_to;
    class SetupInfo;

    TablePlacement(const BFN_Options &, const DependencyGraph *, const TablesMutuallyExclusive &,
                   PhvInfo &, const LayoutChoices &, const SharedIndirectAttachedAnalysis &,
                   SplitAttachedInfo &, TableSummary &);

    struct RedoTablePlacement : public Backtrack::trigger {
        RedoTablePlacement() : Backtrack::trigger(OK) {}
    };

    using GatewayMergeChoices = ordered_map<const IR::MAU::Table *, cstring>;
    GatewayMergeChoices gateway_merge_choices(const IR::MAU::Table *table);

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
    bool backtrack(trigger &) override;

    // In both in class.  Remove
    std::array<bool, 3> table_in_gress = { { false, false, false } };
    cstring error_message;
    bool ignoreContainerConflicts = false;
    std::array<IR::MAU::Table *, 2> starter_pistol = { { nullptr, nullptr } };
    bool alloc_done = false;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply() override { placement_round++; };

    bool try_alloc_adb(Placed *next);
    bool try_alloc_imem(Placed *next);
    bool try_alloc_ixbar(Placed *next);
    bool try_alloc_format(Placed *next, bool gw_linked);
    bool try_alloc_mem(Placed *next, std::vector<Placed *> whole_stage);
    void setup_detached_gateway(IR::MAU::Table *tbl, const Placed *placed);
    bool pick_layout_option(Placed *next, bool estimate_set);
    bool shrink_estimate(Placed *next, int &srams_left, int &tcams_left, int min_entries);
    bool try_alloc_all(Placed *next, std::vector<Placed *> whole_stage, const char *what,
        bool no_memory = false);
    bool initial_stage_and_entries(TablePlacement::Placed *rv, int &furthest_stage);
    Placed *try_place_table(Placed *rv, const StageUseEstimate &current);
    safe_vector<Placed *> try_place_table(const IR::MAU::Table *t, const Placed *done,
        const StageUseEstimate &current, GatewayMergeChoices &gmc);

    void log_choice(const Placed *t, const Placed *best, choice_t choice);
    bool is_better(const Placed *a, const Placed *b, choice_t& choice);
    friend std::ostream &operator<<(std::ostream &out, choice_t choice);

    const Placed *add_starter_pistols(const Placed *done, safe_vector<const Placed *> &trial,
        const StageUseEstimate &current);

    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;
};


class DecidePlacement : public MauInspector {
    TablePlacement &self;

 public:
    struct GroupPlace;
    class Backfill;
    explicit DecidePlacement(TablePlacement &s) : self(s) {}

 private:
    void initForPipe(const IR::BFN::Pipe *, ordered_set<const GroupPlace *> &);
    bool preorder(const IR::BFN::Pipe *) override;
    /// @returns true if all the metadata initialization induced dependencies for table @t are
    /// satisfied, i.e. all the tables that must be placed before table t (due to ordering imposed
    /// by the live range shrinking pass) have been placed. @returns false otherwise.
    bool are_metadata_deps_satisfied(const TablePlacement::Placed *placed,
        const IR::MAU::Table* t) const;
    TablePlacement::Placed *try_backfill_table(const TablePlacement::Placed *done,
        const IR::MAU::Table *tbl, cstring before);
    bool can_place_with_partly_placed(const IR::MAU::Table *tbl,
        const ordered_set<const IR::MAU::Table *> &partly_placed,
        const TablePlacement::Placed *placed);
    bool gateway_thread_can_start(const IR::MAU::Table *, const TablePlacement::Placed *placed);
    IR::MAU::Table *create_starter_table(gress_t gress);
    const TablePlacement::Placed *place_table(ordered_set<const GroupPlace *>&work,
        const TablePlacement::Placed *pl);
    template <class... Args> void error(Args... args) {
        auto &ctxt = BaseCompileContext::get();
        self.summary.addPlacementError(ctxt.errorReporter().format_message(args...)); }
    int errorCount() const { return ::errorCount() + self.summary.placementErrorCount(); }
};

class TransformTables : public MauTransform {
    TablePlacement &self;

 public:
    explicit TransformTables(TablePlacement &s) : self(s) {}

 private:
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *postorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *preorder(IR::MAU::BackendAttached *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const TablePlacement::Placed *placed,
        int stage_table = -1, IR::MAU::Table **last = nullptr);
    IR::Vector<IR::MAU::Table> *break_up_dleft(IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed, int stage_table = -1);
    void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *res, int entries);
};

/*
class DoTablePlacement : public MauTransform {
    TablePlacement &self;

 public:
    explicit DoTablePlacement(TablePlacement &s) : self(s) {}
    struct GroupPlace;
    class Backfill;


 public:
    void initForPipe(const IR::BFN::Pipe *, ordered_set<const GroupPlace *> &);
    IR::Node *preorder(IR::BFN::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *postorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *preorder(IR::MAU::BackendAttached *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const TablePlacement::Placed *placed,
        int stage_table = -1, IR::MAU::Table **last = nullptr);
    IR::Vector<IR::MAU::Table> *break_up_dleft(IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed, int stage_table = -1);

    /// @returns true if all the metadata initialization induced dependencies for table @t are
    /// satisfied, i.e. all the tables that must be placed before table t (due to ordering imposed
    /// by the live range shrinking pass) have been placed. @returns false otherwise.
    bool are_metadata_deps_satisfied(const TablePlacement::Placed *placed,
        const IR::MAU::Table* t) const;

    TablePlacement::Placed *try_backfill_table(const TablePlacement::Placed *done,
        const IR::MAU::Table *tbl, cstring before);
    bool can_place_with_partly_placed(const IR::MAU::Table *tbl,
        const ordered_set<const IR::MAU::Table *> &partly_placed,
        const TablePlacement::Placed *placed);
    bool gateway_thread_can_start(const IR::MAU::Table *, const TablePlacement::Placed *placed);
    IR::MAU::Table *create_starter_table(gress_t gress);
    const TablePlacement::Placed *place_table(ordered_set<const GroupPlace *>&work,
        const TablePlacement::Placed *pl);

    void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *res, int entries);

    template <class... Args> void error(Args... args) {
        auto &ctxt = BaseCompileContext::get();
        self.summary.addPlacementError(ctxt.errorReporter().format_message(args...)); }
    int errorCount() const { return ::errorCount() + self.summary.placementErrorCount(); }
};
*/


#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
