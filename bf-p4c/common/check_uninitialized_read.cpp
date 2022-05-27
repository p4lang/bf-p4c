#include "check_uninitialized_read.h"

bool CheckUninitializedRead::printed = false;

bool CheckUninitializedRead::preorder(const IR::BFN::DeparserParameter* param) {
    pov_protected_fields.insert(phv.field(param->source->field));
    return false;
}

bool CheckUninitializedRead::preorder(const IR::BFN::Digest* digest) {
    pov_protected_fields.insert(phv.field(digest->selector->field));
    return false;
}

void CheckUninitializedRead::end_apply() {
    auto is_ignored_field = [&](const PHV::Field &field){
        if (field.pov) {
            // pov is always initialized.
            LOG3("Ignore pov bits: " << field);
            return true;
        } else if (field.is_padding()) {
            // padding fields that are generated by the compiler should be ignored.
            LOG3("Ignore padding field: " << field);
            return true;
        } else if (field.is_deparser_zero_candidate()) {
            LOG3("Ignore deparser zero field: " << field);
            return true;
        } else if (field.is_overlayable()) {
            LOG3("Ignore overlayable field: " << field);
            return true;
        } else if (!Device::hasMetadataPOV()) {
            // Only for tofino, if a field is invalidated by the arch, then this field is pov bit
            // protected and will not overlay with other fields. So no need to check it.
            if (field.is_invalidate_from_arch())
                return true;
            else
                return false;
        } else {
            // For all fields that are pov bit protected fields, no need to check it, since no write
            // means pov bit remains invalid.
            for (const auto &pov_protected_field : pov_protected_fields) {
                if (pov_protected_field->name == field.name) return true;
            }
            return false;
        }
    };

    if (printed) return;
    set_printed();
    for (const auto &kv : phv.get_all_fields()) {
        const auto &field = kv.second;
        LOG3("checking " << field);
        if (is_ignored_field(field)) continue;
        for (const auto &use : defuse.getAllUses(field.id)) {
            const auto &defs_of_use = defuse.getDefs(use);
            bool uninit = defs_of_use.empty();
            if (!uninit) {
                for (const auto &def : defs_of_use) {
                    if (def.second->is<ImplicitParserInit>() &&
                        (pragmas.pa_no_init().getFields().count(&field))) {
                        LOG3("Use: ("
                             << DBPrint::Brief << use.first << ", " << use.second
                             << ") has an ImplicitParserInit def but pa_no_init is on");
                        uninit = true;
                        break;
                    }
                }
            } else {
#if HAVE_FLATROCK
                // FIXME: flatrock egress intrinsic is always initialized.
                if (Device::currentDevice() == Device::FLATROCK) {
                    ::warning("Checking uninitialized read not implemented");
                    continue;
                }
#endif
                // metadata in INGRESS and non bridged metadata in EGRESS will have at least a
                // ImplicitParserInit def.
                BUG_CHECK(!field.metadata ||
                          (field.metadata && field.bridged && field.gress == EGRESS),
                          "metadata cannot reach here");
                LOG3("Use: (" << DBPrint::Brief << use.first << ", " << use.second <<
                    ") does not have defs");
            }
            if (uninit) {
                ::warning(
                    "%s is read in %s, but it is totally or partially uninitialized",
                    field.name,
                    use.first);
            }
        }
    }
}
