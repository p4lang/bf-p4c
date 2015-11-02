#ifndef _table_placement_h_
#define _table_placement_h_

struct DependencyGraph;
class TablesMutuallyExclusive;
struct StageUse;

class TablePlacement : public MauTransform {
public:
    TablePlacement(const DependencyGraph &d, const TablesMutuallyExclusive &m) : deps(d), mutex(m) {}
    struct GroupPlace;
    struct Placed;
private:
    const DependencyGraph &deps;
    const TablesMutuallyExclusive &mutex;
    IR::Node *preorder(IR::Tofino::Pipe *) override;
    IR::Node *preorder(IR::MAU::TableSeq *) override;
    IR::Node *preorder(IR::MAU::Table *) override;
    const Placed *placement;
    bool is_better(const Placed *a, const Placed *b);
    Placed *try_place_table(const IR::MAU::Table *t, const Placed *done, const StageUse &current);
    Placed *place_table(GroupPlace *grp, int idx, Placed *pl);
    std::multimap<cstring, const Placed *> table_placed;
};


#endif /* _table_placement_h_ */
