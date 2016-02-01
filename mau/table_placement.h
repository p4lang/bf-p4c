#ifndef _TOFINO_MAU_TABLE_PLACEMENT_H_
#define _TOFINO_MAU_TABLE_PLACEMENT_H_

#include "mau_visitor.h"
#include "lib/ordered_set.h"

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUseEstimate;
class PhvInfo;

class TablePlacement : public MauTransform {
 public:
    TablePlacement(const DependencyGraph &d, const TablesMutuallyExclusive &m, const PhvInfo &p)
    : deps(d), mutex(m), phv(p) {}
    struct GroupPlace;
    struct Placed;
 private:
    map<cstring, unsigned>      table_uids;
    const DependencyGraph &deps;
    const TablesMutuallyExclusive &mutex;
    const PhvInfo &phv;
    IR::Node *preorder(IR::Tofino::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    const Placed *placement;
    bool is_better(const Placed *a, const Placed *b);
    Placed *try_place_table(const IR::MAU::Table *t, const Placed *done,
                            const StageUseEstimate &current);
    const Placed *place_table(ordered_set<const GroupPlace *>&work, const GroupPlace *grp,
                              const Placed *pl);
    std::multimap<cstring, const Placed *> table_placed;
};


#endif /* _TOFINO_MAU_TABLE_PLACEMENT_H_ */
