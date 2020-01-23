#ifndef EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_
#define EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"

/**
 * Collect a mapping between bridged field to original field
 * to be used in bridge packing pass.
 *
 * XXX(hanw): the information collected here is available
 * in the @alias annotation, and currently only available in
 * ingress. We should consider if we can do the same for egress.
 */
class CollectBridgedFields : public Inspector {
 private:
    const PhvInfo& phv;

    bool preorder(const IR::BFN::Unit* unit) override {
        if (unit->thread() == EGRESS)
            return false;
        return true;
    }

    profile_t init_apply(const IR::Node* root) override;
    void postorder(const IR::BFN::AliasMember* mem) override;
    void end_apply() override;

 public:
    explicit CollectBridgedFields(const PhvInfo& phv) : phv(phv) { }

    /// Key: Bridged Field name, Value: Original field name.
    ordered_map<cstring, cstring> bridged_to_orig;
};

#endif /* EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_ */
