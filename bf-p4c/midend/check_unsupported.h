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
 * \class CheckUnsupported
 * \ingroup midend
 * \brief Check for unsupported features in the backend compiler.
 */
class CheckUnsupported final : public Inspector {
    void postorder(const IR::P4Table *) override;

 public:
    explicit CheckUnsupported(P4::ReferenceMap *, P4::TypeMap*) {}
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_CHECK_UNSUPPORTED_H_ */
