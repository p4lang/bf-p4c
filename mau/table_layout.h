#ifndef _TOFINO_MAU_TABLE_LAYOUT_H_
#define _TOFINO_MAU_TABLE_LAYOUT_H_

#include "mau_visitor.h"

class TableLayout : public MauModifier, Backtrack {
    bool backtrack(trigger &) override;
    bool preorder(IR::MAU::Table *tbl) override;
};

#endif /* _TOFINO_MAU_TABLE_LAYOUT_H_ */
