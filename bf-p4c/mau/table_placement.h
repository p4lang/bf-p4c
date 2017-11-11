#ifndef BF_P4C_MAU_TABLE_PLACEMENT_H_
#define BF_P4C_MAU_TABLE_PLACEMENT_H_

#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/ordered_set.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;
class LayoutChoices;

class TablePlacement : public MauTransform, public Backtrack {
 public:
    TablePlacement(const DependencyGraph* d, const TablesMutuallyExclusive &m, const PhvInfo &p,
                   const LayoutChoices &l, bool fp);
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
    bool forced_placement = false;
    bool alloc_done = false;
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &) override {
        /* always back up to TableLayout -- don't catch here */
        return false;  /* trig.is<IXBar::failure>() && !alloc_done; */ }
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *);
    IR::Node *preorder(IR::BFN::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Expression *preorder(IR::MAU::HashDist *) override;
    IR::Node *postorder(IR::BFN::Pipe *pipe) override;
    IR::MAU::Table *break_up_atcam(IR::MAU::Table *tbl, const Placed *placed,
                                   cstring suffix = "", IR::MAU::Table **last = nullptr);
    const Placed *placement;
    bool is_better(const Placed *a, const Placed *b);
    Placed *try_place_table(const IR::MAU::Table *t, const Placed *done,
                            const StageUseEstimate &current);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const Placed *pl);
    int get_provided_stage(const IR::MAU::Table *tbl);
    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;
};

#endif /* BF_P4C_MAU_TABLE_PLACEMENT_H_ */
