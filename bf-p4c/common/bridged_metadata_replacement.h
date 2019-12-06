#ifndef EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_
#define EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"

/** Collect all bridged field expression This pass collect all bridged fields
 * by postorder on instructions in the INGRESS pipeline, to find set
 * instructions look like `bridged.field_a = field_a`, that is inserted in the
 * midend.
 *
 * @pre This pass must be ran after Instruction selection because
 * MAU::Instruction are inserted to IR in that pass.
 *
 * @pre This pass must run after CollectNameAnnotations, because the
 * externalName of original field needs to be moved to bridged field, and the
 * mapping is saved here.
 *
 * XXX(hanw): The logic in this pass is incorrect if there are multiple
 * bridge headers, e.g.,
 * meta.f0 = 8w0;
 *
 * - hdr.bridge0.f0 = meta.f0;
 * - hdr.bridge1.f0 = meta.f0;
 *
 * if (hdr.bridge0.isValid())
 *   emit(hdr.bridge0)
 * if (hdr.bridge1.isValid())
 *   emit(hdr.bridge1)
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
    void postorder(const IR::MAU::Instruction* inst) override;
    void end_apply() override;

 public:
    explicit CollectBridgedFields(const PhvInfo& phv) : phv(phv) { }

    /// Key: Field name, Value: Corresponding member object.
    ordered_map<cstring, const IR::Member*> orig_to_bridged;
    /// Key: Bridged Field name, Value: Original field name.
    ordered_map<cstring, cstring> bridged_to_orig;
    /// Key: Bridged Field name, Value: External name of original field.
    ordered_map<cstring, cstring> bridged_to_external_name;
    /// Key: Original Field name, Value: Bridged field name.
    ordered_map<cstring, cstring> orig_to_bridged_name;
};

/// Replace original expression with bridged field's expression.
class ReplaceOriginalFieldWithBridged : public Transform {
 private:
    const PhvInfo& phv;
    const CollectBridgedFields& mapping;

    IR::Node* postorder(IR::Expression* expr) override;
    IR::BFN::Extract* postorder(IR::BFN::Extract* extract) override;

 public:
    ReplaceOriginalFieldWithBridged(const PhvInfo& phv, const CollectBridgedFields& mapping)
    : phv(phv), mapping(mapping) { }
};

/** This pass will also set the external name for bridged metadata.
 *
 * @warn running CollectPhvInfo after this pass will destroy the external name
 * mapping.
 */
class SetExternalNameForBridgedMetadata : public Inspector {
    PhvInfo& phv;
    const CollectBridgedFields& bridged_fields;

    void end_apply() {
        for (const auto& kv : bridged_fields.bridged_to_external_name) {
            auto* bridged = phv.field(kv.first);
            LOG1("Setting external name of bridged field " << bridged->name
                 << " to " << kv.second);
            bridged->setExternalName(kv.second);
        }
    }

 public:
    SetExternalNameForBridgedMetadata(PhvInfo& phv, const CollectBridgedFields& bridged_fields)
    : phv(phv), bridged_fields(bridged_fields) { }
};

#endif /* EXTENSIONS_BF_P4C_COMMON_BRIDGED_METADATA_REPLACEMENT_H_ */
