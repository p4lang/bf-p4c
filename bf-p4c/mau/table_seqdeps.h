#ifndef _TOFINO_MAU_TABLE_SEQDEPS_H_
#define _TOFINO_MAU_TABLE_SEQDEPS_H_

#include "mau_visitor.h"
#include "field_use.h"

class TableFindSeqDependencies : public MauModifier {
    FieldUse    uses;
    profile_t init_apply(const IR::Node *root) override;
    void postorder(IR::MAU::TableSeq *) override;
};

#endif /* _TOFINO_MAU_TABLE_SEQDEPS_H_ */
