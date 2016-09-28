#ifndef _TOFINO_MAU_RESOURCE_H_
#define _TOFINO_MAU_RESOURCE_H_

#include "ir/ir.h"
#include "input_xbar.h"
#include "memories.h"

struct TableResourceAlloc {
    IXBar::Use                          match_ixbar, gateway_ixbar;
    map<cstring, Memories::Use>         memuse;
    TableResourceAlloc *clone_rename(const char *ext) const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        for (auto &use : memuse)
            rv->memuse.emplace(use.first + ext, use.second);
        return rv; }
    void clear() {
        match_ixbar.clear();
        gateway_ixbar.clear();
        memuse.clear(); }
    void toJSON(JSONGenerator &json) const { json << "null"; }
    static TableResourceAlloc *fromJSON(JSONLoader &) { return nullptr; }
};

#endif /* _TOFINO_MAU_RESOURCE_H_ */
