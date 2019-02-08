#include "elim_cast.h"

namespace BFN {

const IR::Node* EliminateWidthCasts::preorder(IR::Cast* expression) {
    const IR::Type* srcType = expression->expr->type;
    const IR::Type* dstType = expression->destType;

    if (srcType->is<IR::Type_Bits>() && dstType->is<IR::Type_Bits>()) {
        if (srcType->to<IR::Type_Bits>()->isSigned != dstType->to<IR::Type_Bits>()->isSigned)
            return expression;

        if (srcType->width_bits() > dstType->width_bits()) {
            return new IR::Slice(expression->srcInfo,
                    expression->destType, expression->expr,
                    new IR::Constant(dstType->width_bits() - 1), new IR::Constant(0));
        } else if (srcType->width_bits() < dstType->width_bits()) {
            if (!srcType->to<IR::Type_Bits>()->isSigned) {
                auto ctype = IR::Type_Bits::get(dstType->width_bits() - srcType->width_bits());
                return new IR::Concat(new IR::Constant(ctype, 0), expression->expr);
            } else {
                return new IR::BFN::SignExtend(expression->srcInfo, expression->destType,
                        expression->expr);
            }
        }
    }
    // cast from InfInt to bit<w> type is already handled in frontend.
    return expression;
}

}  // namespace BFN
