#ifndef _table_summary_h_
#define _table_summary_h_

#include "mau_visitor.h"
#include "resource.h"
#include <iostream>

class TableSummary: public MauInspector {
    map<int, const IR::MAU::Table *>    order;
    map<int, IXBar>                     ixbar;
    map<int, Memories>                  memory;
    bool preorder(const IR::MAU::Table *t) override {
        assert(order.count(t->logical_id) == 0);
        order[t->logical_id] = t;
        if (t->resources) {
            ixbar[t->logical_id/16].update(t->resources->match_ixbar);
            ixbar[t->logical_id/16].update(t->resources->gateway_ixbar);
            memory[t->logical_id/16].update(t->resources->memuse); }
        return true; }
    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
public:
};

#endif /* _table_summary_h_ */
