#include "bf-p4c/common/alias.h"

Visitor::profile_t FindExpressionsForFields::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    exprFields.clear();
    auto& aliasMap = phv.getAliasMap();
    for (auto kv : aliasMap)
        exprFields.insert(phv.field(kv.second));
    return rv;
}

bool FindExpressionsForFields::preorder(const IR::Expression* expr) {
    auto* f = phv.field(expr);
    if (!f)
        return true;
    // If field is not an alias destination, ignore it.
    if (!exprFields.count(f))
        return true;
    if (fieldExpressions.count(f))
        return true;
    fieldExpressions[f] = expr;
    return true;
}

void FindExpressionsForFields::end_apply() {
    if (LOGGING(1)) {
        LOG1("    All aliasing fields: ");
        auto& aliasMap = phv.getAliasMap();
        for (auto kv : aliasMap)
            LOG1("      " << kv.first << " -> " << kv.second); }
}

IR::Node* ReplaceAllAliases::preorder(IR::Expression* expr) {
    auto* f = phv.field(expr);
    if (!f) {
        LOG4("    Field not found for expression: " << expr);
        return expr; }

    // Determine alias source fields
    auto& aliasMap = phv.getAliasMap();
    if (!aliasMap.count(f->name)) {
        LOG4("    Field " << f->name << " not part of any aliasing.");
        return expr; }
    auto* ixbarread = expr->to<IR::MAU::InputXBarRead>();
    if (ixbarread) {
        LOG4("    Expression " << expr << " is an input xbar read.");
        return expr; }

    // replacementField is the alias destination field
    const PHV::Field* replacementField = phv.field(aliasMap.at(f->name));
    BUG_CHECK(fieldExpressions.count(replacementField), "Expression not found");

    // replacementExpression is the expression corresponding to the alias destination field
    const IR::Expression* replacementExpression = fieldExpressions.at(replacementField);
    auto* replacementMember = replacementExpression->to<IR::Member>();
    BUG_CHECK(replacementMember, "Replacement member not found for expression %s",
            replacementMember);
    auto* aliasName = new IR::StringLiteral(IR::ID(f->name));
    auto* fieldAnnotations = new IR::Annotations({new IR::Annotation(IR::ID("alias"),
                {aliasName})});
    auto* newMember = new IR::BFN::AliasMember(replacementExpression->type, replacementMember->expr,
            replacementMember->member, fieldAnnotations);

    auto* sl = expr->to<IR::Slice>();
    if (sl) {
        IR::Slice* newSlice = new IR::Slice(newMember, sl->getH(), sl->getL());
        LOG2("    Replaced: " << expr << " -> " << newSlice);
        return newSlice;
    } else {
        LOG2("    Replaced: " << expr << " -> " << newMember);
        return newMember; }
}
