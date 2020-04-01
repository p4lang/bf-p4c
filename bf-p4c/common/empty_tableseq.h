#ifndef BF_P4C_COMMON_EMPTY_TABLESEQ_H_
#define BF_P4C_COMMON_EMPTY_TABLESEQ_H_

#include "bf-p4c/mau/mau_visitor.h"

/// Adds empty table sequences to implicit fall-through paths in the program. For example, when
/// an 'if' statement has no 'else', this adds an empty table sequence to the 'else' branch.
class AddEmptyTableSeqs : public MauModifier {
    void postorder(IR::BFN::Pipe* pipe) override;
    void postorder(IR::MAU::Table* tbl) override;

 public:
    AddEmptyTableSeqs() {}
};

#endif /* BF_P4C_COMMON_EMPTY_TABLESEQ_H_ */
