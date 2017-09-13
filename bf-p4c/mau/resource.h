#ifndef TOFINO_MAU_RESOURCE_H_
#define TOFINO_MAU_RESOURCE_H_

#include "ir/ir.h"
#include "input_xbar.h"
#include "memories.h"
#include "table_format.h"
#include "action_data_bus.h"


struct TableResourceAlloc {
    IXBar::Use                          match_ixbar, gateway_ixbar, selector_ixbar,
                                        salu_ixbar;
    vector<IXBar::HashDistUse>          hash_dists;
    TableFormat::Use                    table_format;
    map<cstring, Memories::Use>         memuse;
    ActionFormat::Use                   action_format;
    ActionDataBus::Use                  action_data_xbar;
    TableResourceAlloc *clone_rename(const char *ext, const cstring name) const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        rv->selector_ixbar = selector_ixbar;
        rv->table_format = table_format;
        rv->action_format = action_format;
        rv->hash_dists = hash_dists;
        rv->action_data_xbar = action_data_xbar;
        for (auto &use : memuse) {
            if (name == use.first) {
                rv->memuse.emplace(name + ext, use.second);
            } else {
                cstring back = use.first.findlast('$');
                if (back)
                    rv->memuse.emplace(name + ext + back, use.second);
                else
                    rv->memuse.emplace(use.first + ext, use.second);
            }
        }
        return rv; }
    TableResourceAlloc *clone_ixbar() const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        rv->selector_ixbar = selector_ixbar;
        rv->salu_ixbar = salu_ixbar;
        rv->table_format = table_format;
        rv->action_format = action_format;
        rv->hash_dists = hash_dists;
        rv->action_data_xbar = action_data_xbar;
        return rv; }
    void clear_ixbar() {
        match_ixbar.clear();
        gateway_ixbar.clear();
        selector_ixbar.clear();
        salu_ixbar.clear();
        hash_dists.clear();
    }
    void clear() {
        clear_ixbar();
        table_format.clear();
        memuse.clear();
        action_format.clear();
        action_data_xbar.clear();
    }
    void toJSON(JSONGenerator &json) const { json << "null"; }
    static TableResourceAlloc *fromJSON(JSONLoader &) { return nullptr; }
};

#endif /* TOFINO_MAU_RESOURCE_H_ */
