#include "pack_conflicts.h"
#include "lib/log.h"

Visitor::profile_t PackConflicts::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    totalNumSet = 0;
    // Initialize the fieldNoPack matrix to allow all fields to be packed together
    for (auto& f1 : phv) {
        for (auto& f2 : phv) {
            // If the fields are no pack according to deparser constraints, then set that here.
            if (phv.isDeparserNoPack(&f1, &f2)) {
                fieldNoPack(f1.id, f2.id) = true;
                continue;
            }
            // For all other fields, default is false.
            fieldNoPack(f1.id, f2.id) = false;
        }
        // Same field must always be packable with itself.
        fieldNoPack(f1.id, f1.id) = false;
    }
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

bool PackConflicts::preorder(const IR::BFN::Digest* digest) {
    // The no-pack constraint on metadata fields used in learning digests is not applicable to JBay.
    if (Device::currentDevice() != Device::TOFINO) return true;
    // Currently we support only three digests: learning, mirror, and resubmit.
    if (digest->name != "learning" && digest->name != "mirror" && digest->name != "resubmit")
        return true;
    LOG3("    Determining constraints for " << digest->name << " digest.");
    SymBitMatrix digestPackOkay;
    ordered_set<const PHV::Field*> allDigestFields;
    // For fields that are not part of the same digest field lists, set the no-pack constraint.
    for (auto fieldList : digest->fieldLists) {
        for (auto flval1 : fieldList->sources) {
            const auto* f1 = phv.field(flval1->field);
            // Apply the constraint only to metadata fields.
            if (!f1->metadata && !f1->bridged) continue;
            allDigestFields.insert(f1);
            for (auto flval2 : fieldList->sources) {
                if (flval1 == flval2) continue;
                const auto* f2 = phv.field(flval2->field);
                // Apply the constraint only to metadata fields.
                if (!f2->metadata && !f2->bridged) continue;
                // Fields within the same digest field list. So, packing them together is okay.
                digestPackOkay(f1->id, f2->id) = true; } } }

    // Set no pack for fields not marked digest pack okay.
    for (const auto* digestField : allDigestFields) {
        for (const auto& f : phv) {
            if (digestField == &f) continue;
            if (digestPackOkay(digestField->id, f.id)) continue;
            if (f.padding || f.isCompilerGeneratedPaddingField()) continue;
            LOG3("\t  Setting no-pack for digest field " << digestField->name << " and "
                 "non-digest field " << f.name);
            fieldNoPack(digestField->id, f.id) = true; } }

    return true;
}

void PackConflicts::end_apply() {
    for (auto row1 : tableActions) {
        for (auto row2 : tableActions) {
            auto* t1 = row1.first;
            auto* t2 = row2.first;
            if (t1 == t2) continue;
            ordered_set<int> stage = bt.inSameStage(t1, t2);
            if (!stage.empty()) {
                LOG4("\tGenerate no pack conditions for table " << t1->name << " and table " <<
                        t2->name);
                generateNoPackConstraints(t1, t2);
            } else if (t1->get_provided_stage() == t2->get_provided_stage()
                       && t1->get_provided_stage() >= 0) {
                // Potentially should not be an issue, as this can get caught by backtracking
                // but if the program does not backtrack, then expected behavior might not
                // be the same
                LOG4("\tGenerate no pack conditions for table " << t1->name << " and table "
                      << t2->name << " due to stage pragmas");
                generateNoPackConstraints(t1, t2);
            }
        }
    }
    LOG3("Total packing conditions: " << totalNumSet);
    updateNumPackConstraints();
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

    if (!tableActions.count(t1)) {
        LOG6("\t\tNo actions in table " << t1);
        return; }
    if (!tableActions.count(t2)) {
        LOG6("\t\tNo actions in table " << t2);
        return; }
    for (auto act1 : tableActions.at(t1)) {
        for (auto act2 : tableActions.at(t2)) {
            if (amutex(act1, act2)) {
                LOG6("Actions " << act1->name << " and " << act2->name << " are mutually "
                        "exclusive.");
            } else {
                LOG6("\t  Non mutually exclusive actions " << act1->name << " and " << act2->name);
                fields1.insert(actionWrites[act1].begin(), actionWrites[act1].end());
                fields2.insert(actionWrites[act2].begin(), actionWrites[act2].end()); } } }

    LOG5("\tFor table: " << t1->name << ", number of fields written across actions: " <<
            fields1.size());
    LOG5("\tFor table: " << t2->name << ", number of fields written across actions: " <<
            fields2.size());

    for (auto f1 : fields1) {
        for (auto f2 : fields2) {
            if (f1 == f2) {
                // xxx(Deep): This should be taken care of by mutually_exclusive_actions
                LOG1("Dependency analysis may be wrong if " << f1->name << " is written by both "
                     "tables " << t1->name << " and " << t2->name);
            } else {
                ++numSet;
                fieldNoPack(f1->id, f2->id) = true;
                fieldNoPack(f2->id, f1->id) = true;
                LOG6("\t" << fieldNoPack(f1->id, f2->id) << " Setting no pack for " << f1->name <<
                     " (" << f1->id << ") and " << f2->name << " (" << f2->id << ")"); } } }

    LOG4("\tNumber of no pack conditions added for " << t1->name << " and " << t2->name << " : " <<
         (numSet / 2));
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

void PackConflicts::updateNumPackConstraints() {
    for (auto& f1 : phv) {
        size_t numPack = 0;
        for (auto& f2 : phv) {
            if (f1.id == f2.id) continue;
            if (fieldNoPack(f1.id, f2.id))
                numPack++; }
        f1.set_num_pack_conflicts(numPack); }
}

bool PackConflicts::writtenInSameStageDifferentTable(
        const IR::MAU::Table* t1,
        const IR::MAU::Table* t2) const {
    // Written in same stage and same table.
    if (t1 == t2) return false;
    // If no table placement from previous round, then ignore this.
    if (!bt.hasTablePlacement()) return false;
    ordered_set<int> stage = bt.inSameStage(t1, t2);
    std::stringstream ss;
    for (auto st : stage) ss << st << " ";
    if (!stage.empty())
        LOG3("\tTables " << t1->name << " and " << t2->name << " share common stages " <<
            ss.str());
    return !stage.empty();
}
