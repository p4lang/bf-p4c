#ifndef TOFINO_COMMON_COPY_HEADER_ELIMINATOR_H_
#define TOFINO_COMMON_COPY_HEADER_ELIMINATOR_H_

#include "ir/ir.h"
class CopyHeaderEliminator : public Transform {
 public:
    const IR::Node *preorder(IR::Primitive *primitive) override;
};

#endif /* TOFINO_COMMON_COPY_HEADER_ELIMINATOR_H_ */
