#ifndef TOFINO_COMMON_REMAP_INTRIN_H_
#define TOFINO_COMMON_REMAP_INTRIN_H_

#include "ir/ir.h"

class RemapIntrinsics : public Modifier {
    bool preorder(IR::Member *) override;
};

#endif /* TOFINO_COMMON_REMAP_INTRIN_H_ */
