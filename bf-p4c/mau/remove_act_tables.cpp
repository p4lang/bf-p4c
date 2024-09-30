#include "remove_act_tables.h"

bool AnalyzeActionTables::preorder(P4::IR::P4Control* control) {
    return false;
}

bool AnalyzeActionTables::preorder(const P4::IR::MAU::Table* t) {
    return false;
}

bool AnalyzeActionTables::preorder(P4::IR::P4Action* action) {
    return false;
}

const P4::IR::Node *DoRemoveActionTables::postorder(const P4::IR::MAU::Table* t) {
    return t;
}
