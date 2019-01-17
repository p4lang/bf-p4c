#ifndef BF_P4C_COMMON_REWRITE_FLEXIBLE_STRUCT_H_
#define BF_P4C_COMMON_REWRITE_FLEXIBLE_STRUCT_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "bf-p4c/midend/type_checker.h"

namespace BFN {

/**
 * This pass rewrites struct type declaration with a @flexible
 * annotation to IR::Type_StructFlexible.
 *
 */
class DoRewriteFlexibleStruct : public Transform {
    P4::TypeMap* typeMap;

 public:
    explicit DoRewriteFlexibleStruct(P4::TypeMap* typeMap) : typeMap(typeMap) {}

    bool findFlexibleAnnotation(const IR::Type_StructLike* header);
    const IR::Node* preorder(IR::Type_Struct* st) override;
};


class RewriteFlexibleStruct : public PassManager {
 public:
    RewriteFlexibleStruct(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        addPasses({
            new DoRewriteFlexibleStruct(typeMap),
            new BFN::TypeChecking(refMap, typeMap, true),
        });
        setName("RewriteFlexibleStruct");
    }
};

}  // namespace BFN

#endif  /* BF_P4C_COMMON_REWRITE_FLEXIBLE_STRUCT_H_ */
