#ifndef _mau_resource_h_
#define _mau_resource_h_

#include "ir/ir.h"
#include "input_xbar.h"
#include "memories.h"

struct StageUse {
    enum {
	MAX_STAGES = 12,
	MAX_LOGICAL_IDS = 16,
	MAX_SRAMS = 80,
	MAX_TCAMS = 24,
	MAX_MAPRAMS = 48,
	MAX_IXBAR_BYTES = 128,
	MAX_TERNARY_GROUPS = 16,
    };
};

struct TableResourceAlloc {
    IXBar::Use				match_ixbar, gateway_ixbar;
    map<cstring, Memories::Use>		memuse;
    TableResourceAlloc *clone_rename(const char *ext) const {
        TableResourceAlloc *rv = new TableResourceAlloc;
        rv->match_ixbar = match_ixbar;
        rv->gateway_ixbar = gateway_ixbar;
        for (auto &use : memuse)
            rv->memuse.emplace(use.first + ext, use.second);
        return rv; }
};

#endif /* _mau_resource_h_ */
