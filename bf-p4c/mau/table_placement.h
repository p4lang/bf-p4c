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
class FindPayloadCandidates;


class TablePlacement : public PassManager {
 public:
    const BFN_Options &options;
    DependencyGraph   &deps;
    const TablesMutuallyExclusive &mutex;
    PhvInfo &phv;
    LayoutChoices &lc;
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
    static bool can_split(const IR::MAU::AttachedMemory *);

    std::map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    std::map<cstring, struct TableInfo *> tblByName;
    std::map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
    std::map<const IR::MAU::AttachedMemory *, std::set<const IR::MAU::Table *>> attached_to;
    class SetupInfo;

    TablePlacement(const BFN_Options &, DependencyGraph &,
                   const TablesMutuallyExclusive &, PhvInfo &, LayoutChoices &,
                   const SharedIndirectAttachedAnalysis &, SplitAttachedInfo &, TableSummary &);

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

    template <class... Args> void error(Args... args) {
        auto &ctxt = BaseCompileContext::get();
        auto msg = ctxt.errorReporter().format_message(args...);
        LOG5("    defer error: " << msg);
        summary.addPlacementError(msg); }
    int errorCount() const { return ::errorCount() + summary.placementErrorCount(); }
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
    template <class... Args> void error(Args... args) { self.error(args...); }
    int errorCount() const { return self.errorCount(); }
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
    void merge_match_and_gateway(IR::MAU::Table *tbl, const TablePlacement::Placed *placed,
        IR::MAU::Table::Layout &gw_layout);
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const TablePlacement::Placed *placed,
        int stage_table = -1, IR::MAU::Table **last = nullptr);
    IR::Vector<IR::MAU::Table> *break_up_dleft(IR::MAU::Table *tbl,
        const TablePlacement::Placed *placed, int stage_table = -1);
    void table_set_resources(IR::MAU::Table *tbl, const TableResourceAlloc *res, int entries);
    template <class... Args> void error(Args... args) { self.error(args...); }
    int errorCount() const { return self.errorCount(); }
};



class MergeAlwaysRunActions : public PassManager {
    TablePlacement &self;

    using TableFieldSlices = std::map<IR::MAU::Table* , PHV::FieldSlice>;

    struct AlwaysRunKey {
        int stage;
        gress_t gress;

        bool operator<(const AlwaysRunKey &ark) const {
           if (stage != ark.stage)
               return stage < ark.stage;
           return gress < ark.gress;
        }

        AlwaysRunKey(int s, gress_t g) : stage(s), gress(g) {}
    };

    std::map<AlwaysRunKey, ordered_set<const IR::MAU::Table *>> ar_tables_per_stage;
    std::map<AlwaysRunKey, const IR::MAU::Table *> merge_per_stage;
    std::map<AlwaysRunKey, std::set<int>> merged_ar_minStages;
    std::map<const IR::MAU::Table*, std::set<PHV::FieldSlice>> written_fldSlice;
    std::map<const IR::MAU::Table*, std::set<PHV::FieldSlice>> read_fldSlice;

    // Keep the original start and end of AllocSlice liveranges that have
    // shifted due to table merging
    typedef std::map<const IR::MAU::Table*, int> premerge_table_stg_t;
    ordered_map<PHV::AllocSlice*, premerge_table_stg_t> premergeLRstart;
    ordered_map<PHV::AllocSlice*, premerge_table_stg_t> premergeLRend;

    bool mergedARAwitNewStage;

    profile_t init_apply(const IR::Node *node) override {
        auto rv = PassManager::init_apply(node);
        ar_tables_per_stage.clear();
        merge_per_stage.clear();
        merged_ar_minStages.clear();
        written_fldSlice.clear();
        read_fldSlice.clear();
        premergeLRstart.clear();
        premergeLRend.clear();
        mergedARAwitNewStage = false;

        // MinSTage status before updating slice liveranges and merged table minStage
        LOG7("MIN STAGE DEPARSER stage: " << self.phv.getDeparserStage());
        LOG7(PhvInfo::reportMinStages());
        LOG7("DG DEPARSER stage: " << (self.deps.max_min_stage + 1));
        LOG7(self.deps);

        return rv;
    }

    class Scan : public MauInspector {
        MergeAlwaysRunActions &self;
        bool preorder(const IR::MAU::Table *) override;
        bool preorder(const IR::Primitive *) override;
        void end_apply() override;

     public:
        explicit Scan(MergeAlwaysRunActions &s) : self(s) {}
    };

    class Update : public MauTransform {
        MergeAlwaysRunActions &self;
        const IR::MAU::Table *preorder(IR::MAU::Table *) override;
        void end_apply() override;

     public:
        explicit Update(MergeAlwaysRunActions &s) : self(s) {}
    };

    // After merging of ARA tables and updating the dependency graph
    // this class updates the minStage info of tables that have dependence
    // relationship to the merged tables that have changed stage. In
    // addition the liveranges of the affected allocated slices (AllocSlice)
    // are also updated.
    class UpdateAffectedTableMinStage : public MauInspector, public TofinoWriteContext {
        MergeAlwaysRunActions &self;
        // Map affected tables to pair of <old, new> minStages
        std::map<const IR::MAU::Table*, std::pair<int, int>> tableMinStageShifts;
        std::map<PHV::AllocSlice*, std::pair<int, int>> sliceLRshifts;
        std::map<PHV::AllocSlice*, std::pair<bool, bool>> sliceLRmodifies;

        bool preorder(const IR::MAU::Table *) override;
        bool preorder(const IR::Expression *) override;
        void end_apply() override;

     public:
        explicit UpdateAffectedTableMinStage(MergeAlwaysRunActions &s) : self(s) {}
    };

    const IR::MAU::Table *ar_replacement(int st, gress_t gress) {
        AlwaysRunKey ark(st, gress);
        if (ar_tables_per_stage.count(ark) == 0)
            BUG("MergeAlwaysRunActions cannot find stage of an always run table");
        auto set = ar_tables_per_stage.at(ark);
        return *(set.begin());
    }

    template <class... Args> void error(Args... args) { self.error(args...); }
    int errorCount() const { return self.errorCount(); }

 public:
        explicit MergeAlwaysRunActions(TablePlacement &s) : self(s) {
        addPasses({
            new Scan(*this),
            new Update(*this),
            new FindDependencyGraph(self.phv, self.deps),
            new UpdateAffectedTableMinStage(*this)
        });
    }
};

#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
