#include "bf-p4c/phv/privatization.h"
#include "bf-p4c/phv/validate_allocation.h"

Visitor::profile_t EnterPrivatizationPasses::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    if (!LOGGING(1)) return rv;
    LOG1("\t" << doNotPrivatize.size() << " fields must not be privatized.");
    for (auto f : doNotPrivatize)
        LOG1("\t  " << f);
    return rv;
}

bool EnterPrivatizationPasses::backtrack(trigger &trig) {
    if (trig.is<PrivatizationTrigger::failure>()) {
        auto t = dynamic_cast<PrivatizationTrigger::failure *>(&trig);
        LOG1("    Backtracking caught at Privatization");
        for (auto kv : t->doNotPrivatize)
            doNotPrivatize.insert(kv);
        return true; }
    return false;
}

Visitor::profile_t CollectFieldsForPrivatization::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    fieldsWritten.clear();
    fieldsRead.clear();
    tablesReadFields.clear();
    count = 0;
    size = 0;
    return rv;
}

bool CollectFieldsForPrivatization::preorder(const IR::MAU::Action* act) {
    auto *tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap fieldActionsMap;
    aa.set_field_actions_map(&fieldActionsMap);
    act->apply(aa);
    populateMembers(act, fieldActionsMap);
    return true;
}

void CollectFieldsForPrivatization::populateMembers(
        const IR::MAU::Action* act,
        const ActionAnalysis::FieldActionsMap& fieldActionsMap) {
    const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
    LOG5("\tAnalyzing action " << act->name << " in table " << tbl->name);
    for (auto& fieldAction : Values(fieldActionsMap)) {
        PHV::Field* write = phv.field(fieldAction.write.expr);
        BUG_CHECK(write, "Action does not have a write?");
        fieldsWritten[write->id] = true;
        for (auto& readSrc : fieldAction.reads) {
            if (readSrc.type == ActionAnalysis::ActionParam::PHV) {
                PHV::Field* read = phv.field(readSrc.expr);
                BUG_CHECK(read, "Read does not have associated PHV?");
                fieldsRead[read->id] = true;
                tablesReadFields[read].insert(tbl); } } }
}

void CollectFieldsForPrivatization::end_apply() {
    ordered_set<PHV::Field*> privatizationCandidates;
    for (auto kv : tablesReadFields) {
        PHV::Field* f = kv.first;
        if (doNotPrivatize.count(f->name)) {
            f->set_privatizable(false);
            continue; }
        if (!isPacketField(f)) continue;
        if (fieldsWritten[f->id]) continue;
        if (!readInEarlyStages(tablesReadFields[f])) continue;
        // TPHV privatized fields need to start at byte boundaries.
        // E.g. trafficClass in ipv4 starts at bit 4 and so, must start at bit 4 of a container.
        // This becomes an issue if trafficClass is to be allocated into its own TPHV.
        if (f->offset % 8 != 0) continue;
        // If header is not byte aligned, we have trouble satisfying the exact containers
        // requirement for the privatized field. So, ignore those fields.
        if (f->size % 8 != 0) continue;
        ++count;
        size += f->size;
        LOG1("\t  Read-only field: " << f);
        f->set_privatizable(true); }

    LOG1("\tNumber of read-only fields: " << count);
    LOG1("\tTotal number of read-only bits: " << size);
}

bool CollectFieldsForPrivatization::readInEarlyStages(
        const ordered_set<const IR::MAU::Table*>& tables) const {
    for (auto* t : tables) {
        if (dg.min_stage(t) > LAST_STAGE_FOR_PRIVATIZATION)
            return false; }
    return true;
}

Visitor::profile_t AddPrivatizedFieldUses::init_apply(const IR::Node* root) {
    profile_t rv = Transform::init_apply(root);
    inParser = false;
    return rv;
}

IR::Node* AddPrivatizedFieldUses::preorder(IR::BFN::ParserState* p) {
    LOG5("    Setting inParser to true for parser state: " << p->name);
    inParser = true;
    currentParserState = p;
    for (auto it = p->statements.begin(); it != p->statements.end(); ++it)
        LOG5("      " << *it);
    return p;
}

IR::Node* AddPrivatizedFieldUses::preorder(IR::BFN::Extract* e) {
    LOG5("    Extract: " << e);
    currentExtractSource = e->source;
    return e;
}

IR::Node* AddPrivatizedFieldUses::preorder(IR::Expression* expr) {
    if (!inParser) return expr;
    const PHV::Field* f = phv.field(expr);
    if (!f) return expr;
    if (!f->privatizable()) return expr;
    LOG5("      Parsing field " << f->name);
    boost::optional<cstring> shadowFieldName = f->getTPHVPrivateFieldName();
    if (!shadowFieldName)
        BUG("Name of TPHV version of privatizable field %1% not generated", f->name);
    auto* shadowField = new IR::TempVar(IR::Type::Bits::get(f->size), false, *shadowFieldName);
    deparsedFields[f] = shadowField;
    auto* shadowExtract = new IR::BFN::Extract(shadowField, currentExtractSource);
    listOfNewExtracts[currentParserState].insert(shadowExtract);
    LOG5("        Adding shadow extract: " << shadowExtract);
    return expr;
}

IR::Node* AddPrivatizedFieldUses::postorder(IR::BFN::Extract* e) {
    LOG5("    Postorder extract");
    return e;
}

IR::Node* AddPrivatizedFieldUses::postorder(IR::BFN::ParserState* p) {
    inParser = false;
    LOG5("    Setting inParser to false for parser state: " << p->name);
    if (!listOfNewExtracts.count(p)) return p;
    for (auto* e : listOfNewExtracts.at(p))
        p->statements.push_back(e);
    for (auto it = p->statements.begin(); it != p->statements.end(); ++it)
        LOG5("      " << *it);
    return p;
}

IR::Node* AddPrivatizedFieldUses::preorder(IR::BFN::EmitField* e) {
    LOG5("      Emit: " << e);
    const PHV::Field* source = phv.field(e->source->field);
    if (!source) return e;
    if (!source->privatizable()) return e;
    LOG5("        Deparsing field: " << source->name);
    if (!deparsedFields.count(source)) {
        LOG5("          Did not find " << source->name << " in deparsedFields");
        return e; }
    const IR::Expression* expr = deparsedFields.at(source)->to<IR::Expression>();
    IR::BFN::FieldLVal* dest = new IR::BFN::FieldLVal(expr);
    IR::BFN::EmitField* newEmit = new IR::BFN::EmitField(dest, e->povBit);
    LOG5("        New emit: " << newEmit);
    return newEmit;
}

Visitor::profile_t UndoPrivatization::init_apply(const IR::Node* root) {
    profile_t rv = Transform::init_apply(root);
    inParser = false;
    if (LOGGING(1)) {
    LOG1("    List of do not privatize fields: ");
    for (auto fname : doNotPrivatize)
        LOG1("\t  " << fname); }
    return rv;
}

IR::Node* UndoPrivatization::preorder(IR::BFN::ParserState* p) {
    LOG5("    Setting inParser to true for parser state: " << p->name);
    inParser = true;
    currentParserState = p;
    for (auto it = p->statements.begin(); it != p->statements.end(); ++it)
        LOG5("      " << *it);
    return p;
}

IR::Node* UndoPrivatization::preorder(IR::BFN::Extract* e) {
    LOG5("    Extract: " << e);
    currentExtract = e;
    return e;
}

IR::Node* UndoPrivatization::preorder(IR::Expression* expr) {
    if (!inParser) return expr;
    const PHV::Field* f = phv.field(expr);
    if (!f) return expr;
    // Remember expression objects corresponding to privatizable fields. To be used when rewriting
    // the emit statements.
    if (f->privatizable())
        fieldToExpressionMap[f] = expr;
    if (!f->privatized()) return expr;
    boost::optional<cstring> phvName = f->getPHVPrivateFieldName();
    if (!phvName)
        BUG("PHV version of privatized field %1% not found", f->name);
    if (!doNotPrivatize.count(*phvName)) return expr;
    listOfErasedExtracts.insert(currentParserState);
    return expr;
}

IR::Node* UndoPrivatization::postorder(IR::BFN::ParserState* p) {
    inParser = false;
    LOG5("    Setting inParser to false for parser state: " << p->name);
    if (!listOfErasedExtracts.count(p)) return p;
    IR::Vector<IR::BFN::ParserPrimitive> newStatements;
    for (auto stmt : p->statements) {
        auto* e = stmt->to<IR::BFN::Extract>();
        if (!e) continue;
        auto lval = e->to<IR::BFN::FieldLVal>();
        if (!lval) continue;
        const IR::Expression* expr = lval->field;
        PHV::Field* field = phv.field(expr);
        BUG_CHECK(field, "Field not found for %1%", expr);
        boost::optional<cstring> fieldname;
        if (field->privatized()) {
            fieldname = field->getPHVPrivateFieldName();
            if (!fieldname)
                BUG("PHV version of privatized field %1% not found", field->name);
            if (!doNotPrivatize.count(*fieldname)) {
                newStatements.push_back(stmt);
            } else {
                // Set the deparsed property for this field to false
                field->set_deparsed(false);
                field->set_exact_containers(false);
                field->clear_alloc(); }
        } else {
            newStatements.push_back(stmt); } }
    return new IR::BFN::ParserState(p->name, p->gress, newStatements, p->selects, p->transitions);
}

IR::Node* UndoPrivatization::preorder(IR::BFN::EmitField* e) {
    LOG5("      Emit: " << e);
    PHV::Field* source = phv.field(e->source->field);
    if (!source) return e;
    if (!source->privatized()) return e;
    LOG5("        Deparsing field: " << source->name);
    boost::optional<cstring> phvName = source->getPHVPrivateFieldName();
    if (!phvName)
        BUG("PHV version of privatized field %1% not found", source->name);
    PHV::Field* nonPrivatizedSource = phv.field(*phvName);
    BUG_CHECK(nonPrivatizedSource, "Did not find PHV version of privatized field %1%",
            source->name);
    if (!doNotPrivatize.count(nonPrivatizedSource->name)) {
        LOG5("          Emit for " << nonPrivatizedSource->name << " not in doNotPrivatize.");
        return e; }
    BUG_CHECK(fieldToExpressionMap.count(nonPrivatizedSource) > 0, "Expression corresponding to "
              "PHV copy of field %1% not found.", nonPrivatizedSource->name);
    IR::Expression* expr = fieldToExpressionMap.at(nonPrivatizedSource);
    IR::BFN::FieldLVal* dest = new IR::BFN::FieldLVal(expr);
    IR::BFN::EmitField* newEmit = new IR::BFN::EmitField(dest, e->povBit);
    LOG5("        New emit: " << newEmit);
    nonPrivatizedSource->set_privatizable(false);
    source->set_privatized(false);
    return newEmit;
}
