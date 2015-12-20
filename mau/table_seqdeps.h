#ifndef _table_seqdeps_h_
#define _table_seqdeps_h_

#include "mau_visitor.h"
#include "field_use.h"

class TableFindSeqDependencies : public MauModifier {
    FieldUse    uses;
    profile_t init_apply(const IR::Node *root) override;
    void postorder(IR::MAU::TableSeq *) override;
};

#endif /* _table_seqdeps_h_ */
