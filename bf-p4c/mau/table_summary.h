#ifndef _TOFINO_MAU_TABLE_SUMMARY_H_
#define _TOFINO_MAU_TABLE_SUMMARY_H_

#include <iostream>
#include "mau_visitor.h"
#include "resource.h"

class TableSummary: public MauInspector {
    map<int, const IR::MAU::Table *>    order;
    map<int, IXBar>                     ixbar;
    map<int, Memories>                  memory;
    profile_t init_apply(const IR::Node *root) override {
        auto rv = MauInspector::init_apply(root);
        order.clear();
        ixbar.clear();
        memory.clear();
        return rv; }
    bool preorder(const IR::MAU::Table *t) override {
        assert(order.count(t->logical_id) == 0);
        order[t->logical_id] = t;
        if (t->resources) {
            ixbar[t->stage()].update(t);
            memory[t->stage()].update(t->resources->memuse); }
        return true; }
    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* _TOFINO_MAU_TABLE_SUMMARY_H_ */
