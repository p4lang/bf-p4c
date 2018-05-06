#ifndef BF_P4C_MAU_TABLE_PLACEMENT_H_
#define BF_P4C_MAU_TABLE_PLACEMENT_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/ordered_set.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;
class LayoutChoices;

class TablePlacement : public MauTransform, public Backtrack {
 public:
    TablePlacement(const DependencyGraph* d, const TablesMutuallyExclusive &m, const PhvInfo &p,
                   const LayoutChoices &l, const SharedIndirectAttachedAnalysis &siaa, bool fp);
    struct GroupPlace;
    struct Placed;

 private:
    struct TableInfo;
    std::map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    struct TableSeqInfo;
    std::map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
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
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *);
    IR::Node *preorder(IR::BFN::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const Placed *placed,
                                   cstring suffix = "", IR::MAU::Table **last = nullptr);
    const Placed *placement;
    bool is_better(const Placed *a, const Placed *b);
    Placed *try_place_table(const IR::MAU::Table *t, const Placed *done,
                            const StageUseEstimate &current);
    bool try_alloc_ixbar(Placed *next, const Placed *done, TableResourceAlloc *alloc);
    bool try_alloc_format(Placed *next, TableResourceAlloc *resources, bool gw_linked);
    bool try_alloc_mem(Placed *next, const Placed *done, TableResourceAlloc *resources,
        safe_vector<TableResourceAlloc *> &prev_resources);
    bool try_alloc_adb(Placed *next, const Placed *done, TableResourceAlloc *resources);
    bool try_alloc_imem(Placed *next, const Placed *done, TableResourceAlloc *resources);
    bool pick_layout_option(Placed *next, const Placed *done, TableResourceAlloc *resources,
                            StageUseEstimate::StageAttached &shared_attached);
    bool shrink_estimate(Placed *next, const Placed *done, TableResourceAlloc *resources,
                         int &srams_left, int &tcams_left, int min_entries);
    bool initial_stage_and_entries(Placed *rv, const Placed *done, int &set_entries,
        int &furthest_stage);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const Placed *pl);
    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;
};

#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
