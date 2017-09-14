#ifndef BF_P4C_COMMON_COPY_HEADER_ELIMINATOR_H_
#define BF_P4C_COMMON_COPY_HEADER_ELIMINATOR_H_

#include "ir/ir.h"
class CopyHeaderEliminator : public Transform {
 public:
    const IR::Node *preorder(IR::Primitive *primitive) override;
};

#endif /* BF_P4C_COMMON_COPY_HEADER_ELIMINATOR_H_ */
