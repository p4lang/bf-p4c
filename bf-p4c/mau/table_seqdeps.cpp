#include "ir/ir.h"
#include "table_seqdeps.h"
#include "lib/log.h"
#include "lib/ltbitmatrix.h"

Visitor::profile_t TableFindSeqDependencies::init_apply(const IR::Node *root) {
    auto rv = MauModifier::init_apply(root);
    root->apply(uses);
    LOG2(uses);
    return rv;
}

void TableFindSeqDependencies::postorder(IR::MAU::TableSeq *seq) {
    if (seq->tables.size() <= 1) return;
    int size = seq->tables.size();
    seq->deps.clear();
    for (int i = 0; i < size; i++) {
        bitvec writes = uses.tables_modify(seq->tables[i]);
        bitvec access = uses.tables_access(seq->tables[i]);
        bool earlyExit = seq->tables[i]->has_exit_recursive();
        for (int j = i+1; j < size; j++) {
            if (earlyExit || seq->tables[j]->has_exit_recursive() ||
                (writes & uses.tables_access(seq->tables[j])) ||
                (access & uses.tables_modify(seq->tables[j])))
                seq->deps(j, i) = true; } }
    for (int j = 1; j < size; j++)
        for (int i = j-1; i > 0; i--)
            if (seq->deps(j, i))
                seq->deps[j] |= seq->deps[i];
}
