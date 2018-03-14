#include "bridged_metadata_replacement.h"

void CollectBridgedFields::postorder(const IR::MAU::Instruction* inst) {
    if (inst->name == "set") {
        BUG_CHECK(inst->operands.size() == 2, "The number of set operands is not 2.");
        const auto* left = phv.field(inst->operands[0]);
        const auto* right = phv.field(inst->operands[1]);
        if (!left->bridged) return;

        LOG5("Found bridged field:" << left << " --> " << right);
        BUG_CHECK(bridged_to_orig.count(left) == 0, "Duplicated initialzation of bridged.");
        bridged_to_orig[left] = right;
        orig_to_bridged[right] = inst->operands[0];
        bridged_to_external_name[left->name] = right->externalName();
    }
}

void CollectBridgedFields::end_apply() {
    for (const auto& f : phv) {
        if (f.gress == EGRESS) continue;
        // Indicator does not need to be initialzed in mau.
        if (f.name.endsWith("^bridged_metadata_indicator")) continue;

        if (f.bridged && !bridged_to_orig.count(phv.field(f.id))) {
            LOG5("Missing initialzation of bridged field: " << f);
        }
    }
}

IR::Node* ReplaceOriginalFieldWithBridged::postorder(IR::Expression* expr) {
    auto *f = phv.field(expr);
    if (!f) return expr;

    if (mapping.orig_to_bridged.count(f)) {
        auto* bridged = mapping.orig_to_bridged.at(f);
        if (expr->is<IR::Member>()) {
            LOG5("Replacing use of original expr " << expr << " with " << bridged);
            return bridged->clone();
        } else {
            BUG("BridgedReplacement: unhandled expression type: %1%", expr);
            return expr;
        }
    }
    return expr;
}
