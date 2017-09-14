#ifndef BF_P4C_COMMON_SLICE_H_
#define BF_P4C_COMMON_SLICE_H_

#include "ir/ir.h"

/**
 *  MakeSlice -- slice an expression.
 *  Create a slice extracting the bits lo..hi from an expression.
 *  This may be an IR:Slice or not.  Any slices on slices or slices on
 *  constants are folded to the simplest form.  Slices that extract off
 *  the top of an expression (past the msb) are implicitly zero-extended
 */
const IR::Expression *MakeSlice(const IR::Expression *e, int lo, int hi);

#endif /* BF_P4C_COMMON_SLICE_H_ */
