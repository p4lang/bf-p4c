#ifndef EXTENSIONS_BF_P4C_COMMON_CHECK_FOR_UNIMPLEMENTED_FEATURES_H_
#define EXTENSIONS_BF_P4C_COMMON_CHECK_FOR_UNIMPLEMENTED_FEATURES_H_

#include <boost/optional.hpp>
#include "ir/ir.h"

/** Check for the following unimplemented operations:
 *
 *  P4_16                                P4_14
 *  -----                                -----
 *  modify_field(x, (y ++ z) >> n)       funnel_shift_right(x, y, z, n)
 *  modify_field(x, (y ++ z) << n)       funnel_shift_left(x, y, z, n)
 *  modify_field(x, x & 85 | val & 170)  modify_field(x, val, 0xAA)
 */
class CheckOperations : public Inspector {
    // Helper that removes casts to make identifying unsupported operator
    // combinations easier.
    struct RemoveCasts : public Transform {
        IR::Node* preorder(IR::Cast* cast) override {
            return cast->expr->clone();
        }
    };

    /// @returns BOP in modify_field(x, BOP), if BOP is a binary operation
    /// expression.
    boost::optional<const IR::Operation_Binary*> getSrcBinop(const IR::Primitive* p) const;

    /// @returns true if @p is a P4_16 encoding of a P4_14 funnel shift
    /// operation, eg. modify_field(x, (y ++ z) >> n).
    bool isFunnelShift(const IR::Primitive* p) const;

    /// @returns true if @p is a P4_16 encoding of a P4_14 bitmasked modify_field
    /// operation, eg. modify_field(x, val, 0xAA).
    bool isModBitMask(const IR::Primitive* p) const;

    bool preorder(const IR::Primitive*) override;
};

class CheckForUnimplementedFeatures : public PassManager {
 public:
    CheckForUnimplementedFeatures() {
        addPasses({
            new CheckOperations(),
        });
    }
};

#endif  /* EXTENSIONS_BF_P4C_COMMON_CHECK_FOR_UNIMPLEMENTED_FEATURES_H_ */