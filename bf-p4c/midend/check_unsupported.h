#ifndef BF_P4C_MIDEND_CHECK_UNSUPPORTED_H_
#define BF_P4C_MIDEND_CHECK_UNSUPPORTED_H_

#include "ir/ir.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

namespace P4 {
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * Check for unsupported features in the backend compiler
 *
 * For now, varbit and extract variable bits.
 */
class CheckUnsupported final : public Inspector {
    P4::ReferenceMap * _refMap;
    P4::TypeMap *      _typeMap;

 private:
    bool preorder(const IR::Type_StructLike* header) override;
    bool preorder(const IR::MethodCallExpression* method) override;

 public:
    explicit CheckUnsupported(P4::ReferenceMap *refMap, P4::TypeMap* typeMap) :
        _refMap(refMap), _typeMap(typeMap) {}
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_CHECK_UNSUPPORTED_H_ */
