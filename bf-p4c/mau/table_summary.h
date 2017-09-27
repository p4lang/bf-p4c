#ifndef BF_P4C_MAU_TABLE_SUMMARY_H_
#define BF_P4C_MAU_TABLE_SUMMARY_H_

#include <iostream>
#include <map>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"

class TableSummary: public MauInspector {
    std::map<int, const IR::MAU::Table *>    order;
    std::map<int, IXBar>                     ixbar;
    std::map<int, Memories>                  memory;
    std::map<int, ActionDataBus>             action_data_bus;
    profile_t init_apply(const IR::Node *root) override {
        auto rv = MauInspector::init_apply(root);
        order.clear();
        ixbar.clear();
        memory.clear();
        action_data_bus.clear();
        return rv; }
    void end_apply() override {
        if (Log::verbose())
            std::cout << *this; }
    bool preorder(const IR::MAU::Table *t) override {
        assert(order.count(t->logical_id) == 0);
        order[t->logical_id] = t;
        if (t->resources) {
            ixbar[t->stage()].update(t);
            memory[t->stage()].update(t->resources->memuse); }
            action_data_bus[t->stage()].update(t);
        return true; }
    friend std::ostream &operator<<(std::ostream &out, const TableSummary &ts);
};

#endif /* BF_P4C_MAU_TABLE_SUMMARY_H_ */
