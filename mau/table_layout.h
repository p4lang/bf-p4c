#ifndef _table_layout_h_
#define _table_layout_h_

#include "mau_visitor.h"

class TableLayout : public MauModifier, Backtrack {
    bool backtrack(trigger &) override;
    bool preorder(IR::MAU::Table *tbl) override;
};

#endif /* _table_layout_h_ */
