#include "bf-p4c/arch/bridge_metadata.h"
#include "bridged_metadata_replacement.h"

Visitor::profile_t CollectBridgedFields::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    orig_to_bridged.clear();
    bridged_to_orig.clear();
    bridged_to_external_name.clear();
    orig_to_bridged_name.clear();
    return rv;
}

void CollectBridgedFields::postorder(const IR::MAU::Instruction* inst) {
    if (inst->name == "set") {
        BUG_CHECK(inst->operands.size() == 2, "The number of set operands is not 2.");
        const auto* left = phv.field(inst->operands[0]);
        const auto* right = phv.field(inst->operands[1]);
        if (!left->bridged) return;

        LOG5("Found bridged field:" << left << " --> " << right);
        BUG_CHECK(bridged_to_orig.count(left->name) == 0, "Duplicated initialzation of bridged.");
        auto* leftMember = inst->operands[0]->to<IR::Member>();
        BUG_CHECK(leftMember, "Expected bridged field to be an IR::Member: %1%",
                  inst->operands[0]);

        bridged_to_orig[left->name] = right->name;
        orig_to_bridged[right->name] = leftMember;
        bridged_to_external_name[left->name] = right->externalName();
        orig_to_bridged_name[right->name] = left->name;
    }
}

void CollectBridgedFields::end_apply() {
    for (const auto& f : phv) {
        if (f.gress == EGRESS) continue;
        // Indicator does not need to be initialzed in mau.
        if (f.name.endsWith(BFN::BRIDGED_MD_INDICATOR)) continue;

        if (f.bridged && !bridged_to_orig.count(f.name)) {
            LOG5("Missing initialzation of bridged field: " << f);
        }
    }
}

IR::Node* ReplaceOriginalFieldWithBridged::postorder(IR::Expression* expr) {
    auto *f = phv.field(expr);
    if (!f) return expr;

    if (mapping.orig_to_bridged.count(f->name)) {
        auto* bridged = mapping.orig_to_bridged.at(f->name);
        if (auto* alias = expr->to<IR::BFN::AliasMember>()) {
            // Take care to preserve aliasing information, if present.
            LOG5("Replacing use of original expr " << expr << " with " << bridged);
            return new IR::BFN::AliasMember(bridged->clone(), alias->source);
        } else if (expr->is<IR::Member>()) {
            LOG5("Replacing use of original expr " << expr << " with " << bridged);
            return bridged->clone();
        } else {
            BUG("BridgedReplacement: unhandled expression type: %1%", expr);
            return expr; } }

    return expr;
}

IR::BFN::Extract* ReplaceOriginalFieldWithBridged::postorder(IR::BFN::Extract* extract) {
    if (extract->marshaled_from) {
        auto marshaled_from = *extract->marshaled_from;
        cstring full_name =
            cstring::to_cstring(marshaled_from.gress) + "::" + marshaled_from.field_name;
        if (mapping.orig_to_bridged_name.count(full_name)) {
            cstring new_name = mapping.orig_to_bridged_name.at(full_name);
            marshaled_from.field_name = cstring(new_name.findlast(':') + 1);
            LOG1("Replacing string-based field name info in extract: " <<
                 full_name << " with " << marshaled_from.field_name);
            auto* new_extract = extract->clone();
            new_extract->marshaled_from = marshaled_from;
            return new_extract;
        }
    }
    return extract;
}
