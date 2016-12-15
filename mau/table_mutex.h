#ifndef _TOFINO_MAU_TABLE_MUTEX_H_
#define _TOFINO_MAU_TABLE_MUTEX_H_

#include "mau_visitor.h"
#include "lib/symbitmatrix.h"

class TablesMutuallyExclusive : public MauInspector {
    map<const IR::MAU::Table *, int>    table_ids;
    map<const IR::MAU::Table *, bitvec> table_succ;
    SymBitMatrix                        mutex;
    bool preorder(const IR::MAU::Table *t) override {
        assert(!table_ids.count(t));
        table_ids.emplace(t, table_ids.size());
        return true; }
    void postorder(const IR::MAU::Table *tbl) override;
    void postorder(const IR::Tofino::Pipe *pipe) override;
    profile_t init_apply(const IR::Node *root) override {
        profile_t rv = MauInspector::init_apply(root);
        table_ids.clear();
        table_succ.clear();
        mutex.clear();
        return rv; }
 public:
    bool operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
        return mutex(table_ids.at(a), table_ids.at(b)); }
};

class DetermineActionProfileFaults : public MauInspector {
    map<const IR::ActionProfile *, vector<const IR::MAU::Table *>> ap_users;
    const TablesMutuallyExclusive &mutex;
    bool preorder(const IR::MAU::Table *t) override;
 public:
    DetermineActionProfileFaults(const TablesMutuallyExclusive &m) : mutex(m) {}
};
#endif /* _TOFINO_MAU_TABLE_MUTEX_H_ */
