#include "ixbar_expr.h"

bool AdjustIXBarExpression::preorder(IR::MAU::IXBarExpression *e) {
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto &ce : tbl->resources->salu_ixbar.meter_alu_hash.computed_expressions) {
        if (e->expr->equiv(*ce.second)) {
            e->bit = ce.first;
            return false; } }
    for (auto &hdu : tbl->resources->hash_dists) {
        if (e->equiv(*hdu.original_hd->field_list)) {
            // FIXME -- if we do this, the asm generation for the HashDist parent of this node
            // fails, as it uses pointer comparison on the IR::MAU::HashDist nodes, so will fail
            // if any pass after ixbar allocation changes them.  This IXBar expression is the
            // child of such a node, so updating it will violate that.  But since asm generation
            // only cares about the hash dist result (not the actual location in the ixbar hash),
            // we don't need to actually update the IXBarExpression.
#if 0
            e->bit = hdu.use.hash_dist_hash.bit_mask.ffs(0);
#endif
            return false; } }
    BUG("Can't find %s in the ixbar allocation for %s", e->expr, tbl);
    return false;
}

