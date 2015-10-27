#ifndef _table_mutex_h_
#define _table_mutex_h_

#include "ir/ir.h"
#include "lib/ltbitmatrix.h"

class TablesMutuallyExclusive : public Inspector {
    map<const IR::MAU::Table *, int>	table_ids;
    map<const IR::MAU::Table *, bitvec>	table_succ;
    LTBitMatrix				mutex;
    bool preorder(const IR::MAU::Table *t) override {
	assert(!table_ids.count(t));
	table_ids.emplace(t, table_ids.size());
	return true; }
    void postorder(const IR::MAU::Table *tbl) override;
    void postorder(const IR::MAU::Pipe *pipe) override;
    profile_t init_apply(const IR::Node *root) override {
	profile_t rv = Inspector::init_apply(root);
	table_ids.clear();
	table_succ.clear();
	mutex.clear();
	return rv; }
public:
    bool operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
	int a_id = table_ids.at(a);
	int b_id = table_ids.at(b);
	return a_id < b_id ? mutex(b_id, a_id) : mutex(a_id, b_id); }
};

#endif /* _table_mutex_h_ */
