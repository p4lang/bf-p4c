#include "bf-p4c/arch/bridge_metadata.h"
#include "bridged_metadata_replacement.h"

Visitor::profile_t CollectBridgedFields::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    bridged_to_orig.clear();
    return rv;
}

void CollectBridgedFields::postorder(const IR::BFN::AliasMember* mem) {
    const auto* dest = phv.field(mem);
    const auto* src = phv.field(mem->source);
    if (!dest->is_flexible())
        return;
    if (bridged_to_orig.count(dest->name))
        return;

    bridged_to_orig[dest->name] = src->name;
    LOG3("bridged to orig " << dest->name << " " << src->name);
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

