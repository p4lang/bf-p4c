#include "pack_conflicts.h"
#include "lib/log.h"

Visitor::profile_t PackConflicts::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    totalNumSet = 0;
    fieldNoPack.clear();
    // Initialize the fieldNoPack matrix to allow all fields to be packed together
    for (auto& f1 : phv) {
        for (auto& f2 : phv)
            fieldNoPack(f1.id, f2.id) = false; }
    tableActions.clear();
    actionWrites.clear();
    return rv;
}

bool PackConflicts::preorder(const IR::MAU::Action *act) {
    auto* tbl = findContext<IR::MAU::Table>();
    // Create a mapping of tables to all the actions it may invoke
    tableActions[tbl].insert(act);

    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap field_actions_map;
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);

    // Collect all the PHV fields written to by this action into the actionWrites map
    for (auto& field_action : Values(field_actions_map)) {
        auto* write = phv.field(field_action.write.expr);
        if (write == nullptr)
            BUG("Action does not have a write?");
        actionWrites[act].insert(write); }
    return true;
}

void PackConflicts::end_apply() {
    for (auto row1 : tableActions) {
        for (auto row2 : tableActions) {
            auto* t1 = row1.first;
            auto* t2 = row2.first;
            if (t1 == t2) continue;
            int stage = bt.inSameStage(t1, t2);
            if (stage != -1) {
                LOG4("\tGenerate no pack conditions for table " << t1->name << " and table " <<
                        t2->name << " in stage " << stage);
                generateNoPackConstraints(t1, t2); } } }
    LOG4("Total packing conditions: " << totalNumSet);
    if (LOGGING(5))
        printNoPackConflicts();
}

void PackConflicts::generateNoPackConstraints(const IR::MAU::Table* t1, const IR::MAU::Table* t2) {
    if (mutex(t1, t2)) {
        LOG6("\tTables " << t1->name << " and " << t2->name << " are mutually exclusive");
        return; }

    ordered_set<const PHV::Field*> fields1;
    ordered_set<const PHV::Field*> fields2;
    size_t numSet = 0;

    for (auto act : tableActions.at(t1))
        fields1.insert(actionWrites[act].begin(), actionWrites[act].end());
    for (auto act : tableActions.at(t2))
        fields2.insert(actionWrites[act].begin(), actionWrites[act].end());

    // xxx(Deep): To be pulled back in when action_mutex PR is in
    /*
    for (auto act1 : tableActions.at(t1)) {
        for (auto act2 : tableActions.at(t2)) {
            if (amutex(act1, act2)) {
                LOG6("Actions " << act1->name << " and " << act2->name << " are mutually "
                        "exclusive.");
            } else {
                LOG1("Non mutually exclusive actions " << act1->name << " and " << act2->name);
                fields1.insert(actionWrites[act1].begin(), actionWrites[act1].end());
                fields2.insert(actionWrites[act2].begin(), actionWrites[act2].end()); } } }
                */
    LOG5("\tFor table: " << t1->name << ", number of fields written across actions: " <<
            fields1.size());
    LOG5("\tFor table: " << t2->name << ", number of fields written across actions: " <<
            fields2.size());
    for (auto f1 : fields1) {
        for (auto f2 : fields2) {
            if (f1 == f2) {
                // xxx(Deep): This should be taken care of by mutually_exclusive_actions
                ::warning("Dependency Analysis may be wrong if %1% is written by both tables "
                        "%2% and %3%.", f1->name, t1->name, t2->name);
            } else {
                if (fieldNoPack(f1->id, f2->id) != true || fieldNoPack(f2->id, f1->id) != true)
                    ++numSet;
                fieldNoPack(f1->id, f2->id) = true;
                fieldNoPack(f2->id, f1->id) = true;
                LOG6(this << " " << " " << fieldNoPack(f1->id, f2->id) << " Setting no pack for " <<
                        f1->name << " (" << f1->id << ") and " << f2->name << " (" << f2->id <<
                        ")"); } } }

    LOG4("\tNumber of no pack conditions added: " << numSet);
    totalNumSet += numSet;
}

unsigned PackConflicts::size() const {
    return fieldNoPack.size();
}

bool PackConflicts::hasPackConflict(const PHV::Field* f1, const PHV::Field* f2) const {
    LOG6(this << " " << fieldNoPack(f1->id, f2->id) << " Checking for " << f1->name << " (" <<
            f1->id << ") and " << f2->name << " (" << f2->id << ")");
    return fieldNoPack(f1->id, f2->id);
}

void PackConflicts::printNoPackConflicts() const {
    LOG5("List of no pack constraints " << this << " " << &fieldNoPack);
    for (auto& f1 : phv) {
        for (auto& f2 : phv) {
            if (f1.id >= f2.id) continue;
            if (fieldNoPack(f1.id, f2.id))
                LOG5("\t" << f1.name << " (" << f1.id << "), " << f2.name << " (" << f2.id << ")");
        } }
    LOG5("End List of no pack constraints " << this << " " << &fieldNoPack);
}
