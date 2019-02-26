#include <sstream>
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/ir_utils.h"

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
    auto* ixbarread = expr->to<IR::MAU::InputXBarRead>();
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
        IR::Slice* newSlice = new IR::Slice(newMember, sl->getH(), sl->getL());
        LOG2("    Replaced: " << expr << " -> " << newSlice);
        return newSlice;
    } else {
        LOG2("    Replaced: " << expr << " -> " << newMember);
        return newMember; }
}
