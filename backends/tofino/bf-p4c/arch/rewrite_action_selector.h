#ifndef BF_P4C_ARCH_REWRITE_ACTION_SELECTOR_H_
#define BF_P4C_ARCH_REWRITE_ACTION_SELECTOR_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"

namespace BFN {

/**
 * Rewrite legacy use case of TNA ActionSelector
 *
 * ActionSelector(size, hash, mode); to
 *
 * ActionProfile(size) ap;
 * ActionSelector(ap, hash, mode, group_size, num_groups);
 *
 * This class is only required to migrate to existing code to the new
 * ActionSelector constructor.
 */
class RewriteActionSelector : public Transform {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    RewriteActionSelector(P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
        : refMap(refMap), typeMap(typeMap) {}

    const IR::Node* postorder(IR::Declaration_Instance *inst) override;
    const IR::Node* postorder(IR::ConstructorCallExpression *cce) override;
    const IR::Node* postorder(IR::ExpressionValue *ev) override;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_REWRITE_ACTION_SELECTOR_H_ */
