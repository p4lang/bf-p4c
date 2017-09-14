#ifndef BF_P4C_COMMON_REMAP_INTRIN_H_
#define BF_P4C_COMMON_REMAP_INTRIN_H_

#include "ir/ir.h"

/// remap references to glass-specfic intrinsic metadata to standard metadata
class RemapIntrinsics : public Modifier {
    bool preorder(IR::Member *) override;
};

#endif /* BF_P4C_COMMON_REMAP_INTRIN_H_ */
