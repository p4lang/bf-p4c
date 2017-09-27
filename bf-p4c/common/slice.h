#ifndef BF_P4C_COMMON_SLICE_H_
#define BF_P4C_COMMON_SLICE_H_

#include "ir/ir.h"
#include "lib/safe_vector.h"

/**
 *  MakeSlice -- slice an expression.
 *  Create a slice extracting the bits lo..hi from an expression.
 *  This may be an IR:Slice or not.  Any slices on slices or slices on
 *  constants are folded to the simplest form.  Slices that extract off
 *  the top of an expression (past the msb) are implicitly zero-extended
 */
const IR::Expression *MakeSlice(const IR::Expression *e, int lo, int hi);

/**
 *  Changes an IR::Mask to a list of IR::Slices.  The phv.field function cannot interpret
 *  IR::Masks, as they can be non-contiguous, so this will convert that to a bunch of slices.
 */
safe_vector<const IR::Expression *> convertMaskToSlices(const IR::Mask *m);

#endif /* BF_P4C_COMMON_SLICE_H_ */
