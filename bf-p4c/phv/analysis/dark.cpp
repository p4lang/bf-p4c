#include "bf-p4c/phv/analysis/dark.h"
#include <queue>

Visitor::profile_t CollectNonDarkUses::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    nonDarkMauUses.clear();
    return rv;
}

bool CollectNonDarkUses::preorder(const IR::MAU::Action* act) {
    for (auto* prim : act->stateful) {
        for (auto* operand : prim->operands) {
            const PHV::Field* f = phv.field(operand);
            if (!f) continue;
            LOG5("    Input crossbar read, stateful primitive: " << f);
            nonDarkMauUses[f->id] = true; } }
    return true;
}

bool CollectNonDarkUses::preorder(const IR::MAU::Table* tbl) {
    LOG5("Table: " << tbl->name);
    for (auto kv : tbl->gateway_rows) {
        if (kv.first == nullptr) continue;
        LOG5("  Gateway row: " << kv.first);
        std::queue<const IR::Expression*> expressions;
        expressions.push(kv.first);
        while (!expressions.empty()) {
            const IR::Expression* expr = expressions.front();
            expressions.pop();
            if (auto* op = expr->to<IR::Operation_Binary>()) {
                LOG5("    Binary operation Expression: " << expr);
                if (op->left)
                    expressions.push(op->left);
                if (op->right)
                    expressions.push(op->right);
            } else {
                LOG5("    Non-binary operation expression: " << expr);
                const PHV::Field* field = phv.field(expr);
                if (field) {
                    LOG5("    Input crossbar read, field in gateway condition: " << field);
                    nonDarkMauUses[field->id] = true; } } } }
    return true;
}

bool CollectNonDarkUses::preorder(const IR::MAU::InputXBarRead* read) {
    const PHV::Field* f = phv.field(read->expr);
    if (!f) return true;
    nonDarkMauUses[f->id] = true;
    LOG5("    Input crossbar read: " << f);
    return true;
}

bool CollectNonDarkUses::preorder(const IR::MAU::Meter* mtr) {
    const PHV::Field* f = phv.field(mtr->result);
    if (f) {
        LOG5("    Meter result: " << f);
        nonDarkMauUses[f->id] = true; }
    f = phv.field(mtr->pre_color);
    if (f) {
        LOG5("    Meter pre color: " << f);
        nonDarkMauUses[f->id] = true; }
    f = phv.field(mtr->input);
    if (f) {
        LOG5("    Meter input: " << f);
        nonDarkMauUses[f->id] = true; }
    return true;
}

bool CollectNonDarkUses::preorder(const IR::MAU::HashDist* hd) {
    auto* listExpr = hd->field_list->to<IR::ListExpression>();
    if (listExpr) {
        for (auto e : listExpr->components) {
            const PHV::Field* f = phv.field(e);
            if (!f) continue;
            LOG5("    Input crossbar read in hash distribution: " << f);
            nonDarkMauUses[f->id] = true;
        }
    } else {
        const PHV::Field* f = phv.field(hd->field_list);
        if (!f) return true;
        LOG5("    Input crossbar read in hash distribution: " << f);
        nonDarkMauUses[f->id] = true;
    }
    return true;
}

bool CollectNonDarkUses::preorder(const IR::MAU::SaluAction* act) {
    for (const auto* prim : act->action) {
        for (const auto* operand : prim->operands) {
            const PHV::Field* f = phv.field(operand);
            if (!f) continue;
            nonDarkMauUses[f->id] = true;
            LOG5("    Stateful ALU Operand: " << f);
        }
    }
    return false;
}

bool CollectNonDarkUses::hasNonDarkUse(const PHV::Field* f) const {
    return nonDarkMauUses[f->id];
}

Visitor::profile_t MarkDarkCandidates::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    nonDarkMauUses.clear();
    darkCount = 0;
    darkSize = 0;
    return rv;
}

void MarkDarkCandidates::end_apply() {
    for (PHV::Field& f : phv) {
        std::stringstream ss;
        // Ignore dark analysis is field is not a mocha candidate.
        // Dark fields can go into mocha and so are definitely mocha candidates.
        // XXX(Deep): In the long run, we should move to using dark containers as a kind of spill
        // space, where fields can be temporarily written into dark from normal/mocha containers in
        // stages where they are not used. The following requirement is overly restrictive, once we
        // enable such spill-oriented allocation.
        if (!f.is_mocha_candidate()) continue;

        ss << "    Candidate field for dark: " << f << std::endl;

        // If the metadata field is used in the parser/deparser, then ignore it.
        // Note that the is_used_parde() function does returns false for a bunch of fields (such as
        // deparser parameters), which it considers to be used in the MAU instead. Until we resolve
        // this discrepancy by understanding how the rest of the compiler uses the results of
        // is_used_parde(), we need to add the second clause is_deparsed() below.
        if (uses.is_used_parde(&f) || uses.is_deparsed(&f)) {
            ss << "    ...field used in parde.";
            LOG5(ss.str());
            continue; }

        if (nonDarkUses.hasNonDarkUse(&f)) {
            ss << "    ...used for non-dark MAU operations.";
            LOG5(ss.str());
            continue; }

        if (f.bridged || f.alwaysPackable) {
            ss << "    ...encountered bridged/padding/phase0 field.";
            LOG5(ss.str());
            continue; }

        if (f.is_checksummed()) {
            ss << "    ...checksum field encountered.";
            LOG5(ss.str());
            continue; }

        if (f.is_digest()) {
            ss << "    ...digest field encountered.";
            LOG5(ss.str());
            continue; }

        f.set_dark_candidate(true);
        ++darkCount;
        darkSize += f.size;
        LOG1("    Dark candidate: " << f); }
    LOG1("    Number of dark candidate fields: " << darkCount);
    LOG1("    Total size of dark candidates  : " << darkSize << "b.");
}

Visitor::profile_t CollectDarkPrivatizationCandidates::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    fieldsWritten.clear();
    darkPrivCandidates = 0;
    darkPrivCandidatesSize = 0;
    return rv;
}

void CollectDarkPrivatizationCandidates::end_apply() {
    const ordered_map<const PHV::Field*, cstring> pragmaFields = pragma.getFields();
    for (PHV::Field& f : phv) {
        if (pragmaFields.count(&f)) {
            LOG5("    Field " << f << " has a container type pragma.");
            continue;
        }
        if (darkPrivCandidates > 48 || darkPrivCandidatesSize > 512) {
            LOG1("    Too many dark candidates created.");
            break;
        }
        std::stringstream ss;
        ss << "    Examining field: " << f << std::endl;
        if (f.is_dark_candidate()) {
            ss << "    ...already a dark candidate.";
            LOG5(ss.str());
            continue;
        }
        if (!f.is_mocha_candidate()) {
            ss << "    ...not a mocha candidate.";
            LOG5(ss.str());
            continue;
        }
        if (!f.metadata) {
            ss << "    ...non metadata field detected.";
            LOG5(ss.str());
            continue;
        }
        if (f.bridged || f.alwaysPackable) {
            ss << "    ...bridged field detected.";
            LOG5(ss.str());
            continue;
        }
        if (f.is_checksummed()) {
            ss << "    ...checksum field encountered.";
            LOG5(ss.str());
            continue;
        }
        if (f.is_digest()) {
            ss << "    ...digest field encountered.";
            LOG5(ss.str());
            continue;
        }
        if (f.deparsed_to_tm()) {
            ss << "    ...intrinsic metadata field enocuntered";
            LOG5(ss.str());
            continue;
        }
        if (nonDarkUses.hasNonDarkUse(&f)) {
            ss << "    ...involved in MAU operations not supported by dark containers.";
            LOG5(ss.str());
            continue;
        }
        if (fieldsWritten[f.id]) {
            ss << "    ...field is written in the MAU.";
            LOG5(ss.str());
            continue;
        }

        f.set_privatizable_dark(true);
        ++darkPrivCandidates;
        darkPrivCandidatesSize += f.size;
        LOG1("    Dark privatizable candidate: " << f);
    }
    LOG1("    Number of dark privatizable candidate fields: " << darkPrivCandidates);
    LOG1("    Total size of dark privatizable candidates  : " << darkPrivCandidatesSize);
}

Visitor::profile_t MapDarkFieldToExpr::init_apply(const IR::Node* root) {
    fieldExpressions.clear();
    return Inspector::init_apply(root);
}

bool MapDarkFieldToExpr::preorder(const IR::Expression* expr) {
    auto* f = phv.field(expr);
    if (!f) return true;
    if (!f->is_privatizable_dark()) return true;
    fieldExpressions[f] = expr;
    return true;
}

Visitor::profile_t AddDarkFieldUses::init_apply(const IR::Node* root) {
    darkFields.clear();
    inAction = false;
    return Transform::init_apply(root);
}

const IR::Node* AddDarkFieldUses::preorder(IR::MAU::Action* act) {
    inAction = true;
    currentAction = act;
    return act;
}

const IR::Node* AddDarkFieldUses::postorder(IR::MAU::Action* act) {
    currentAction = nullptr;
    inAction = false;
    return act;
}

const IR::Node* AddDarkFieldUses::preorder(IR::Expression* expr) {
    if (!inAction) return expr;
    const PHV::Field* f = phv.field(expr);
    if (!f) return expr;
    if (!f->is_privatizable_dark()) return expr;
    LOG2("  Action: " << currentAction->name);
    LOG2("    Handling field: " << f);
    auto* ct = expr->to<IR::Cast>();
    if (ct) {
        LOG3("      Expression " << ct << " is a cast.");
        prune();
        return expr;
    }
    cstring darkFieldName = f->name + PHV::Field::DARK_PRIVATIZE_SUFFIX;
    auto* darkField = new IR::TempVar(IR::Type::Bits::get(f->size), false, darkFieldName);
    darkFields[f] = darkField;
    LOG2("    Expression: " << expr);
    auto* sl = expr->to<IR::Slice>();
    if (sl) {
        LOG3("      Expression " << sl << " is a slice.");
        auto* newSlice = new IR::Slice(darkField, sl->getH(), sl->getL());
        prune();
        return newSlice;
    }
    LOG2("    New expression: " << darkField);
    prune();
    return darkField;
}

const IR::Expression* AddPrivatizedDarkTableInit::getExpression(const PHV::Field* field) const {
    BUG_CHECK(fieldExpressions.count(field), "Missing IR::Expression for %1%", field->name);
    return fieldExpressions.at(field);
}

const IR::MAU::Instruction* AddPrivatizedDarkTableInit::generateInitInstruction(
        const PHV::Field* rhs,
        const IR::TempVar* lhs) const {
    BUG_CHECK(rhs, "Field is nullptr in generateInitInstruction");
    const IR::Expression* rhsExpr = getExpression(rhs);
    const IR::Expression* lhsExpr = lhs->to<IR::Expression>();
    BUG_CHECK(lhsExpr, "No expression corresponding to TempVar %1%", lhs);
    auto* prim = new IR::MAU::Instruction("set", { lhsExpr, rhsExpr });
    return prim;
}

const IR::MAU::TableSeq*
AddPrivatizedDarkTableInit::addInit(const IR::MAU::TableSeq* seq, gress_t gress) {
    auto* action = new IR::MAU::Action("__init_dark__");
    action->default_allowed = action->init_default = true;
    for (auto kv : darkFields) {
        auto* origField = kv.first;
        if (origField->gress != gress) continue;
        auto* prim = generateInitInstruction(origField, kv.second);
        action->action.push_back(prim);
    }
    if (action->action.size() == 0) {
        LOG1("    No init table required as no privatized dark fields");
        return seq;
    }
    auto* table = new IR::MAU::Table("__init_dark_begin_" + cstring::to_cstring(gress), gress);
    table->actions[action->name] = action;
    auto p4Name = "__init_dark_begin_p4_" + cstring::to_cstring(gress);
    table->match_table = new IR::P4Table(p4Name.c_str(), new IR::TableProperties());
    auto* newTableSeq = new IR::MAU::TableSeq();
    newTableSeq->tables.push_back(table);
    for (const auto* tb : seq->tables)
        newTableSeq->tables.push_back(tb);
    LOG1("Adding init table to the beginning: ");
    LOG1(table);
    return newTableSeq;
}

const IR::BFN::Pipe* AddPrivatizedDarkTableInit::postorder(IR::BFN::Pipe* pipe) {
    pipe->thread[INGRESS].mau = addInit(pipe->thread[INGRESS].mau, INGRESS);
    pipe->thread[EGRESS].mau = addInit(pipe->thread[EGRESS].mau, EGRESS);
    return pipe;
}
