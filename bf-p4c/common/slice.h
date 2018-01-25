#ifndef BF_P4C_COMMON_SLICE_H_
#define BF_P4C_COMMON_SLICE_H_

#include "ir/ir.h"
#include "lib/safe_vector.h"

/** @returns the lo and hi bits for a give expression
  */
std::pair<int, int> getSliceLoHi(const IR::Expression* e);

/**
 *  MakeSlice -- slice an expression.
 *  Create a slice extracting the bits lo..hi from an expression.
 *  This may be an IR:Slice or not.  Any slices on slices or slices on
 *  constants are folded to the simplest form.  Slices that extract off
 *  the top of an expression (past the msb) are implicitly zero-extended
 */
const IR::Expression *MakeSlice(const IR::Expression *e, int lo, int hi);

/**
  * MakeSliceDestination -- slice an expression used as the destination in an instruction.  Creates
  * a slice extracting the bits lo..hi from an expression. This may be an IR:Slice or not.  Any
  * slices on slices or slices on constants are folded to the simplest form. Slices that extract
  * off the top of an expression (past the msb) are implicitly zero-extended. 
 */
const IR::Expression *MakeSliceDestination(const IR::Expression *e, int lo, int hi);

/**
  * MakeSliceSource -- slice an expression used as the destination in an instruction.  Creates a
  * slice extracting the bits lo..hi from an expression. This may be an IR:Slice or not.  Any slices
  * on slices or slices on constants are folded to the simplest form. Slices that extract off the
  * top of an expression (past the msb) are implicitly zero-extended. It also accounts for the case
  * where the destination used with this read is not aligned with the read.
 */
const IR::Expression *MakeSliceSource(const IR::Expression *read, int lo, int hi, const
        IR::Expression* write);

/**
 *  Changes an IR::Mask to a list of IR::Slices.  The phv.field function cannot interpret
 *  IR::Masks, as they can be non-contiguous, so this will convert that to a bunch of slices.
 */
safe_vector<const IR::Expression *> convertMaskToSlices(const IR::Mask *m);

#endif /* BF_P4C_COMMON_SLICE_H_ */
