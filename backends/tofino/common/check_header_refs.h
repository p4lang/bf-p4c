#ifndef BF_P4C_COMMON_CHECK_HEADER_REFS_H_
#define BF_P4C_COMMON_CHECK_HEADER_REFS_H_

#include "ir/ir.h"
#include "backends/tofino/common/utils.h"

/**
 * Once the CopyHeaderEliminator and HeaderPushPo passes have run, HeaderRef
 * objects should no longer exist in the IR as arguments, only as children of
 * Member nodes.  This pass checks and throws a BUG if this property does not
 * hold.
 */
class CheckForHeaders final : public Inspector {
    bool preorder(const IR::Member *) { return false; }
    bool preorder(const IR::HeaderRef *h) {
        if (h->toString() == "ghost::gh_intr_md") return false;
        BUG("Header present in IR not under Member: %s", h->toString());
    }
};

#endif /* BF_P4C_COMMON_CHECK_HEADER_REFS_H_ */
