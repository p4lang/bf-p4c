#ifndef BF_P4C_COMMON_SLICE_H_
#define BF_P4C_COMMON_SLICE_H_

#include "ir/ir.h"
#include "lib/safe_vector.h"

/** @returns the lo and hi bits for a give expression
  */
std::pair<int, int> getSliceLoHi(const P4::IR::Expression* e);

/**
 *  MakeSlice -- slice an expression.
 *  Create a slice extracting the bits lo..hi from an expression.
 *  This may be an IR:Slice or not.  Any slices on slices or slices on
 *  constants are folded to the simplest form.  Slices that extract off
 *  the top of an expression (past the msb) are implicitly zero-extended
 *  Also strength-reduce slices on bitwise operations
 */
const P4::IR::Expression *MakeSlice(const P4::IR::Expression *e, int lo, int hi);
inline const P4::IR::Expression *MakeSlice(const P4::IR::Expression *e, le_bitrange slice) {
    return MakeSlice(e, slice.lo, slice.hi); }

/**
  * MakeSliceDestination -- slice an expression used as the destination in an instruction.  Creates
  * a slice extracting the bits lo..hi from an expression. This may be an IR:Slice or not.  Any
  * slices on slices or slices on constants are folded to the simplest form. Slices that extract
  * off the top of an expression (past the msb) are implicitly zero-extended. 
 */
const P4::IR::Expression *MakeSliceDestination(const P4::IR::Expression *e, int lo, int hi);

/**
  * MakeSliceSource -- slice an expression used as the destination in an instruction.  Creates a
  * slice extracting the bits lo..hi from an expression. This may be an IR:Slice or not.  Any slices
  * on slices or slices on constants are folded to the simplest form. Slices that extract off the
  * top of an expression (past the msb) are implicitly zero-extended. It also accounts for the case
  * where the destination used with this read is not aligned with the read.
 */
const P4::IR::Expression *MakeSliceSource(const P4::IR::Expression *read, int lo, int hi, const
        P4::IR::Expression* write);

/**
 *  Changes an P4::IR::Mask to a list of P4::IR::Slices.  The phv.field function cannot interpret
 *  P4::IR::Masks, as they can be non-contiguous, so this will convert that to a bunch of slices.
 */
safe_vector<const P4::IR::Expression *> convertMaskToSlices(const P4::IR::Mask *m);

/**
 * MakeWrappedSlice - slice an expression around a boundary
 * This is necessary if a source goes around the boundary in a deposit-field.  Currently
 * the only allowed Expression to be used in this expression is a MultiOperand
 */
const P4::IR::Expression *MakeWrappedSlice(const P4::IR::Expression *e, int lo, int hi, int wrap_size);

#endif /* BF_P4C_COMMON_SLICE_H_ */
