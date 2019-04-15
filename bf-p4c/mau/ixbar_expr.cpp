#include "ixbar_expr.h"
#include "resource.h"

bool AdjustIXBarExpression::preorder(IR::MAU::IXBarExpression *e) {
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto &ce : tbl->resources->salu_ixbar.meter_alu_hash.computed_expressions) {
        if (e->expr->equiv(*ce.second)) {
            e->bit = ce.first;
            return false; } }
     if (findContext<IR::MAU::HashDist>())
         return false;
    BUG("Can't find %s in the ixbar allocation for %s", e->expr, tbl);
    return false;
}

