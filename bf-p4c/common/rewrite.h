#ifndef BF_P4C_COMMON_REWRITE_H_
#define BF_P4C_COMMON_REWRITE_H_

#include "ir/ir.h"

namespace P4 {
class BuiltInMethod;
class ExternMethod;
class ReferenceMap;
class TypeMap;
}  // namespace P4

struct RewriteForTofino : public Transform {
    RewriteForTofino(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : refMap(refMap), typeMap(typeMap) { }

 private:
    const IR::Expression* postorder(IR::MethodCallExpression* call) override;
    const IR::Expression* postorder(IR::Slice* slice) override;

    const IR::Expression* convertExternMethod(const IR::MethodCallExpression* call,
                                              const P4::ExternMethod* externMethod);

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

#endif /* BF_P4C_COMMON_REWRITE_H_ */
