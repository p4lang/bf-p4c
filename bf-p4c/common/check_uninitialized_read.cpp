#include "check_uninitialized_read.h"

void CheckUninitializedRead::end_apply() {
    for (const auto &kv : phv.get_all_fields()) {
        const auto &field = kv.second;
        for (const auto &use : defuse.getAllUses(field.id)) {
            const auto & defs_of_use = defuse.getDefs(use);
            bool uninit = defs_of_use.empty();
            if (!uninit) {
                for (const auto &def : defs_of_use) {
                    if (def.second->is<ImplicitParserInit>() &&
                        pragmas.pa_no_init().getFields().count(&field)) {
                        uninit = true;
                        break;
                    }
                }
            }
            if (uninit) {
                ::warning(
                    "%s is read in %s, however it is never or partially initialized",
                    field.name,
                    use.first);
            }
        }
    }
}
