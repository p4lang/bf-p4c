#ifndef _TOFINO_MAU_TABLE_PLACEMENT_H_
#define _TOFINO_MAU_TABLE_PLACEMENT_H_

#include "mau_visitor.h"
#include "lib/ordered_set.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;

class TablePlacement : public MauTransform, public Backtrack {
 public:
    TablePlacement(const DependencyGraph* d, const TablesMutuallyExclusive &m, const PhvInfo &p);
    struct GroupPlace;
    struct Placed;

 private:
    struct TableInfo;
    map<const IR::MAU::Table *, struct TableInfo> tblInfo;
    struct TableSeqInfo;
    map<const IR::MAU::TableSeq *, struct TableSeqInfo> seqInfo;
    class SetupInfo;
    const DependencyGraph* deps;
    const TablesMutuallyExclusive &mutex;
    const PhvInfo &phv;
    bool alloc_done = false;
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &) override {
        /* always back up to TableLayout -- don't catch here */
        return false;  /* trig.is<IXBar::failure>() && !alloc_done; */ }
    IR::Node *preorder(IR::Tofino::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    IR::Node *postorder(IR::Tofino::Pipe *pipe) override;
    const Placed *placement;
    bool is_better(const Placed *a, const Placed *b);
    Placed *try_place_table(const IR::MAU::Table *t, const Placed *done,
                            const StageUseEstimate &current);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const Placed *pl);
    std::multimap<cstring, const Placed *> table_placed;
    std::multimap<cstring, const Placed *>::const_iterator find_placed(cstring name) const;
};

#endif /* _TOFINO_MAU_TABLE_PLACEMENT_H_ */
