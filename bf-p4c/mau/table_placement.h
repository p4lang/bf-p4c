#ifndef BF_P4C_MAU_TABLE_PLACEMENT_H_
#define BF_P4C_MAU_TABLE_PLACEMENT_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/ordered_set.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/upward_downward_prop.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;
class LayoutChoices;
class SharedIndirectAttachedAnalysis;

class TablePlacement : public MauTransform, public Backtrack {
 public:
    TablePlacement(const DependencyGraph* d, const TablesMutuallyExclusive &m, const PhvInfo &p,
                   const LayoutChoices &l, const SharedIndirectAttachedAnalysis &siaa, bool fp);
    struct GroupPlace;
    struct Placed;
    typedef std::map<const IR::MAU::AttachedMemory *, int>      attached_entries_t;

 protected:
    typedef enum {
        CALC_STAGE,
        PROV_STAGE,
        NEED_MORE,
        DOWNWARD_PROP_DSC,
        UPWARD_PROP_DSC,
        LOCAL_DSC,
        LOCAL_DS,
        LOCAL_TD,
        DEFAULT
    } choice_t;

 private:
    ordered_set<const IR::MAU::Table *> placed_tables;

    // Names of all tables that have been placed so far in the TablePlacement pass. Note that this
    // is a global set of tables.
    ordered_set<cstring> placed_table_names;

    struct TableInfo;
    UpwardDownwardPropagation *upward_downward_prop;
    void log_choice(const Placed *t, const Placed *best, choice_t choice);
    friend std::ostream &operator<<(std::ostream &out, choice_t choice);
    std::map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    struct TableSeqInfo;
    std::map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
    std::map<const IR::MAU::AttachedMemory *, std::set<const IR::MAU::Table *>> attached_to;
    std::array<bool, 3> table_in_gress = { { false, false, false } };
    std::array<IR::MAU::Table *, 2> starter_pistol = { { nullptr, nullptr } };
    class SetupInfo;
    const DependencyGraph* deps;
    const TablesMutuallyExclusive &mutex;
    const PhvInfo &phv;
    const LayoutChoices &lc;
    const SharedIndirectAttachedAnalysis &siaa;
    bool ignoreContainerConflicts = false;
    bool forced_placement = false;
    bool alloc_done = false;
    cstring error_message;
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &) override;
    IR::Node *preorder(IR::BFN::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *preorder(IR::MAU::BackendAttached *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const Placed *placed,
        int stage_table = -1, IR::MAU::Table **last = nullptr);
    IR::Vector<IR::MAU::Table> *break_up_dleft(IR::MAU::Table *tbl, const Placed *placed,
        int stage_table = -1);
    const Placed *placement;

    /// @returns true if all the metadata initialization induced dependencies for table @t are
    /// satisfied, i.e. all the tables that must be placed before table t (due to ordering imposed
    /// by the live range shrinking pass) have been placed. @returns false otherwise.
    bool are_metadata_deps_satisfied(const IR::MAU::Table* t) const;

    bool is_better(const Placed *a, const Placed *b, choice_t& choice);
    safe_vector<Placed *> try_place_table(const IR::MAU::Table *t, const Placed *done,
        const StageUseEstimate &current);
    Placed *try_place_table(Placed *rv, const IR::MAU::Table *t, const Placed *done,
        const StageUseEstimate &current);
    bool try_alloc_ixbar(Placed *next, const Placed *done, TableResourceAlloc *alloc);
    bool try_alloc_format(Placed *next, TableResourceAlloc *resources, bool gw_linked);
    bool try_alloc_mem(Placed *next, const Placed *done, TableResourceAlloc *resources,
        safe_vector<TableResourceAlloc *> &prev_resources);
    bool try_alloc_adb(Placed *next, const Placed *done, TableResourceAlloc *resources);
    bool try_alloc_imem(Placed *next, const Placed *done, TableResourceAlloc *resources);
    bool pick_layout_option(Placed *next, const Placed *done, TableResourceAlloc *resources);
    bool shrink_estimate(Placed *next, const Placed *done, TableResourceAlloc *resources,
                         int &srams_left, int &tcams_left, int min_entries);
    bool can_duplicate(const IR::MAU::AttachedMemory *);
    bool initial_stage_and_entries(Placed *rv, const Placed *done, int &set_entries,
        int &furthest_stage);
    IR::MAU::Table *create_starter_table(gress_t gress);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const Placed *pl);
    const Placed *add_starter_pistols(const Placed *done, safe_vector<const Placed *> &trial,
        const StageUseEstimate &current);
    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;
};

#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
