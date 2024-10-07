#include "remove_act_tables.h"

bool AnalyzeActionTables::preorder(IR::P4Control* control) {
    return false;
}

bool AnalyzeActionTables::preorder(const IR::MAU::Table* t) {
    return false;
}

bool AnalyzeActionTables::preorder(IR::P4Action* action) {
    return false;
}

const IR::Node *DoRemoveActionTables::postorder(const IR::MAU::Table* t) {
    return t;
}
