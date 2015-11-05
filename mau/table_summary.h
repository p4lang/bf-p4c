#ifndef _table_summary_h_
#define _table_summary_h_

#include "mau_visitor.h"
#include <iostream>

class TableSummary: public MauInspector {
    map<int, const IR::MAU::Table *>	order;
    bool preorder(const IR::MAU::Table *t) override {
	assert(order.count(t->logical_id) == 0);
	order[t->logical_id] = t;
	return true; }
    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
public:
};

#endif /* _table_summary_h_ */
