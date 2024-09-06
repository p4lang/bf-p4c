
#ifndef BF_P4C_ARCH_ADD_T2NA_META_H_
#define BF_P4C_ARCH_ADD_T2NA_META_H_

#include "ir/ir.h"

namespace BFN {

// Check T2NA metadata and add missing
class AddT2naMeta final : public Modifier {
 public:
    AddT2naMeta() { setName("AddT2naMeta"); }

    // Check T2NA metadata structures and headers and add missing fields
    void postorder(IR::Type_StructLike* typeStructLike) override;
};

}  // namespace BFN

#endif  /* BF_P4C_ARCH_ADD_T2NA_META_H_ */
