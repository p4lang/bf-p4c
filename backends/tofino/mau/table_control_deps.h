#ifndef BF_P4C_MAU_TABLE_CONTROL_DEPS_H_
#define BF_P4C_MAU_TABLE_CONTROL_DEPS_H_

#include "lib/ordered_map.h"
#include "backends/tofino/mau/mau_visitor.h"

/** Find control dependencies between tables in the presence of multiply applied tables
 * Table B is control dependent on table A if and only if A appears on all IR paths from
 * the root IR::BFN::Pipe to table B.  So we find the set of all tables on each path and
 * take the intersection of those sets
 * We also calculate the number of distinct dependent paths from each table here.
 */
class TableControlDeps : public MauTableInspector {
    struct info_t {  // info per table
        ordered_set<const IR::MAU::Table *>     parents = {};
        int                                     dependent_paths = 0;
    };
    ordered_map<const IR::MAU::Table *, info_t> info;

    profile_t init_apply(const IR::Node *root) override {
        info.clear();
        return MauTableInspector::init_apply(root); }
    ordered_set<const IR::MAU::Table *> parents();
    void postorder(const IR::MAU::Table *tbl) override;
    void revisit(const IR::MAU::Table *tbl) override;
    void postorder(const IR::MAU::TableSeq *) override { visitAgain(); }

 public:
    bool operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const;
    int paths(const IR::MAU::Table *) const;
};

#endif /* BF_P4C_MAU_TABLE_CONTROL_DEPS_H_ */
