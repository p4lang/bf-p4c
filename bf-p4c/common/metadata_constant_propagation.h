#ifndef EXTENSIONS_BF_P4C_COMMON_METADATA_CONSTANT_PROPAGATION_H_
#define EXTENSIONS_BF_P4C_COMMON_METADATA_CONSTANT_PROPAGATION_H_

#include "ir/ir.h"
#include "lib/log.h"
#include "bf-p4c/common/field_defuse.h"

/** @brief Replace the first reads of uninitialized metadata fields in actions
 * with zero.
 *
 * The P4_14 spec mandates that metadata fields be initialized to zero, and the
 * P4_16 spec states that reads before writes of metadata fields result in
 * undefined values.  Therefore, reads of metadata fields that always occur (on
 * every control flow path) before the first write can be replaced with a
 * static "0" value.
 *
 * It is not possible to specify a constant as a table key, so this pass only
 * transforms actions.
 *
 * @pre FieldDefUse
 */
class MetadataConstantPropagation : public Transform {
    // TODO: perhaps this transformation should be in the frontend?
    PhvInfo &phv;
    FieldDefUse &defuse;
    ordered_set<const IR::Expression *> first_reads;

    profile_t init_apply(const IR::Node *root) override;

    /// If @e is in @first_reads and is in an action, replace it with 0.
    IR::Node *preorder(IR::Expression *e) override;

 public:
    MetadataConstantPropagation(PhvInfo &phv, FieldDefUse &defuse)
    : phv(phv), defuse(defuse) { }
};

#endif /* EXTENSIONS_BF_P4C_COMMON_METADATA_CONSTANT_PROPAGATION_H_ */
