#include <sstream>
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

Visitor::profile_t FindExpressionsForFields::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    fieldNameToExpressionsMap.clear();
    return rv;
}

bool FindExpressionsForFields::preorder(const IR::HeaderOrMetadata* h) {
    LOG5("Header: " << h->name);
    LOG5("Header type: " << h->type);
    cstring hName = h->name;
    // Ignore compiler generated metadata because the user is not going to apply a pragma on those.
    if (hName.startsWith("ingress::compiler_generated_meta") ||
        hName.startsWith("egress::compiler_generated_meta"))
        return true;
    for (auto f : h->type->fields) {
        cstring name = h->name + "." + f->name;
        // Ignore compiler generated metadata fields that belong to different headers.
        if (name.endsWith("$always_deparse") || name.endsWith("^bridged_metadata_indicator"))
            continue;
        IR::Member* mem = gen_fieldref(h, f->name);
        if (!mem) continue;
        fieldNameToExpressionsMap[name] = mem;
        LOG5("  Added field: " << name << ", " << mem);
    }
    return true;
}

Visitor::profile_t ReplaceAllAliases::init_apply(const IR::Node* root) {
    if (LOGGING(1)) {
        LOG1("    All aliasing fields: ");
        for (auto &kv : pragmaAlias.getAliasMap()) {
            std::stringstream ss;
            if (kv.second.range)
                ss << "[" << kv.second.range->hi << ":" << kv.second.range->lo << "]";
            LOG1("      " << kv.first << " -> " << kv.second.field << ss.str()); } }
    return Transform::init_apply(root);
}

IR::Node* ReplaceAllAliases::preorder(IR::Expression* expr) {
    auto* f = phv.field(expr);
    if (!f) {
        LOG4("    Field not found for expression: " << expr);
        return expr; }

    // Determine alias source fields
    auto& aliasMap = pragmaAlias.getAliasMap();
    if (!aliasMap.count(f->name)) {
        LOG4("    Field " << f->name << " not part of any aliasing.");
        return expr; }
    auto* ixbarread = expr->to<IR::MAU::TableKey>();
    if (ixbarread) {
        LOG4("    Expression " << expr << " is an input xbar read.");
        return expr; }

    // replacementField is the alias destination field
    auto destInfo = aliasMap.at(f->name);
    const PHV::Field* replacementField = phv.field(destInfo.field);
    BUG_CHECK(fieldExpressions.count(replacementField->name),
            "Expression not found %1%", replacementField->name);

    // replacementExpression is the expression corresponding to the alias destination field
    const IR::Member* replacementMember = fieldExpressions.at(replacementField->name);
    auto* newMember = new IR::BFN::AliasMember(replacementMember, expr);

    auto* sl = expr->to<IR::Slice>();
    if (sl) {
        if (f->size == replacementField->size) {
            IR::Slice* newSlice = new IR::Slice(newMember, sl->getH(), sl->getL());
            LOG2("    Replaced: " << expr << " -> " << newSlice);
            return newSlice;
        } else {
            IR::Slice* destSlice = new IR::Slice(replacementMember, sl->getH(), sl->getL());
            auto* newAliasSlice = new IR::BFN::AliasSlice(destSlice, sl);
            LOG2("    Replaced: " << expr << " -> " << newAliasSlice);
            return newAliasSlice;
        }
    } else {
        if (f->size == replacementField->size) {
            LOG2("    Replaced: " << expr << " -> " << newMember);
            return newMember;
        } else {
            IR::Slice* destSlice = new IR::Slice(replacementMember, f->size - 1, 0);
            auto* newAliasSlice = new IR::BFN::AliasSlice(destSlice, expr);
            LOG2("    Replaced: " << expr << " -> " << newAliasSlice);
            return newAliasSlice;
        }
    }
}

inline cstring AddValidityBitSets::getFieldValidityName(cstring origName) {
    return origName + ".$valid";
}

Visitor::profile_t AddValidityBitSets::init_apply(const IR::Node* root) {
    aliasedFields.clear();
    actionToPOVMap.clear();
    for (auto& kv : pragmaAlias.getAliasMap()) {
        const cstring validFieldName = getFieldValidityName(kv.first);
        const PHV::Field* field = phv.field(validFieldName);
        if (!field) continue;
        aliasedFields[phv.field(kv.second.field)].insert(field);
        LOG1("\tAliased field " << kv.second.field << " has a validity bit from "
             << kv.first << " (" << field->name << ")");
    }
    return Transform::init_apply(root);
}

IR::Node* AddValidityBitSets::preorder(IR::MAU::Instruction* inst) {
    if (inst->operands.size() == 0) return inst;
    const PHV::Field* f = phv.field(inst->operands.at(0));
    if (!aliasedFields.count(f)) return inst;
    auto* action = findContext<IR::MAU::Action>();
    if (!action) return inst;
    for (const auto* pov : aliasedFields.at(f))
        actionToPOVMap[action->name].insert(pov);
    return inst;
}

IR::Node* AddValidityBitSets::postorder(IR::MAU::Action* action) {
    if (!actionToPOVMap.count(action->name)) return action;
    for (const auto* f : actionToPOVMap.at(action->name)) {
        auto* pov = phv.getTempVar(f);
        if (!pov) {
            LOG3("\t  Could not find POV corresponding to " << f->name);
            continue;
        }
        auto* oneExpr = new IR::Constant(new IR::Type_Bits(pov->type->width_bits(), false), 1);
        auto* prim = new IR::MAU::Instruction("set", { pov, oneExpr });
        LOG1("\t  Add to action " << action->name << " : " << prim);
        action->action.push_back(prim);
    }
    return action;
}

const IR::Annotation* ReplicatePragmas::getRelevantAnnotation(const IR::Annotation* anno) const {
    // Ignore pa_alias and pa_no_init pragmas. Just because the programmer wants to reduce the live
    // range for the alias source does not mean the same applies to alias destination.
    if (anno->name.name == "pa_alias" || anno->name.name == "pa_no_init")
        return nullptr;
    auto& exprs = anno->expr;
    auto gress = exprs[0]->to<IR::StringLiteral>();
    if (!gress) return nullptr;
    if (!PHV::Pragmas::gressValid("pa_pragmas", gress->value, true)) return nullptr;
    auto& aliasMap = pragmaAlias.getAliasMap();
    auto* newAnnotation = anno->clone();
    bool returnNewAnnotation = false;
    for (unsigned i = 1; i < exprs.size(); i++) {
        auto field_ir = exprs[i]->to<IR::StringLiteral>();
        if (!field_ir) continue;
        auto field_name = gress->value + "::" + field_ir->value;
        auto field = phv_i.field(field_name);
        if (!field) continue;
        if (!aliasMap.count(field->name)) continue;
        auto newFieldName = aliasMap.at(field->name).field;
        auto* postGressString = newFieldName.find("::");
        cstring postGressName(postGressString + 2);
        const IR::StringLiteral* replacementFieldName = new IR::StringLiteral(postGressName);
        newAnnotation->expr[i] = replacementFieldName;
        returnNewAnnotation = true;
    }
    if (returnNewAnnotation)
        return newAnnotation;
    else
        return nullptr;
}

bool ReplicatePragmas::preorder(IR::BFN::Pipe* pipe) {
    if (pragmaAlias.getAliasMap().size() == 0) return true;
    auto global_pragmas = pipe->global_pragmas;
    std::vector<const IR::Annotation*> aliasRelatedAnnotations;
    for (const auto* annotation : global_pragmas) {
        const auto* newAnnotation = getRelevantAnnotation(annotation);
        if (newAnnotation == nullptr) continue;
        aliasRelatedAnnotations.push_back(newAnnotation);
        LOG1("\t  New annotation required: " << newAnnotation);
    }
    for (const auto* annotation : aliasRelatedAnnotations)
        pipe->global_pragmas.push_back(annotation);
    return true;
}
