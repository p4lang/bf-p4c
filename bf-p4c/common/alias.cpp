#include "bf-p4c/common/alias.h"
#include <sstream>

Visitor::profile_t FindExpressionsForFields::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    exprFields.clear();
    fieldExpressions.clear();
    for (auto kv : pragmaAlias.getAliasMap())
        exprFields.insert(phv.field(kv.second.field));
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
        for (auto &kv : pragmaAlias.getAliasMap()) {
            std::stringstream ss;
            if (kv.second.range)
                ss << "[" << kv.second.range->hi << ":" << kv.second.range->lo << "]";
            LOG1("      " << kv.first << " -> " << kv.second.field << ss.str()); } }
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
    auto* ixbarread = expr->to<IR::MAU::InputXBarRead>();
    if (ixbarread) {
        LOG4("    Expression " << expr << " is an input xbar read.");
        return expr; }

    // replacementField is the alias destination field
    auto destInfo = aliasMap.at(f->name);
    const PHV::Field* replacementField = phv.field(destInfo.field);
    BUG_CHECK(fieldExpressions.count(replacementField), "Expression not found");

    // replacementExpression is the expression corresponding to the alias destination field
    const IR::Expression* replacementExpression = fieldExpressions.at(replacementField);
    auto* replacementMember = replacementExpression->to<IR::Member>();
    BUG_CHECK(replacementMember, "Replacement member not found for expression %s",
            replacementMember);
    auto* newMember = new IR::BFN::AliasMember(replacementMember, expr);

    auto* sl = expr->to<IR::Slice>();
    if (sl) {
        IR::Slice* newSlice = new IR::Slice(newMember, sl->getH(), sl->getL());
        LOG2("    Replaced: " << expr << " -> " << newSlice);
        return newSlice;
    } else {
        LOG2("    Replaced: " << expr << " -> " << newMember);
        return newMember; }
}
