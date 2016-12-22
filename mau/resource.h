#ifndef _TOFINO_MAU_RESOURCE_H_
#define _TOFINO_MAU_RESOURCE_H_

#include "ir/ir.h"
#include "input_xbar.h"
#include "memories.h"

struct TableResourceAlloc {
    IXBar::Use                          match_ixbar, gateway_ixbar, selector_ixbar;
    map<cstring, Memories::Use>         memuse;
    TableResourceAlloc *clone_rename(const char *ext, const cstring name) const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        rv->selector_ixbar = selector_ixbar;
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
        return rv; }
    void clear() {
        match_ixbar.clear();
        gateway_ixbar.clear();
        memuse.clear(); }
    void toJSON(JSONGenerator &json) const { json << "null"; }
    static TableResourceAlloc *fromJSON(JSONLoader &) { return nullptr; }
};

#endif /* _TOFINO_MAU_RESOURCE_H_ */
