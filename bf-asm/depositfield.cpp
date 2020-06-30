
#include "depositfield.h"

namespace DepositField {

RotateConstant discoverRotation(int32_t val, int containerSize,
                                int32_t tooLarge, int32_t tooSmall) {
    int32_t containerMask = ~(UINT64_MAX << containerSize);
    int32_t signBit = 1U << (containerSize - 1);
    unsigned rotate = 0;
    for ( /*rotate*/; rotate < containerSize; ++rotate) {
        if (val > tooSmall && val < tooLarge)
            break;
        // Reverse the rotate-right to discover encoding.
        int32_t rotBit = (val >> (containerSize - 1)) & 1;
        val = ((val << 1) | rotBit) & containerMask;
        val |= (val & signBit)? ~containerMask : 0;
    }
    // If a solution has not been found, val is back to where it started.
    rotate %= containerSize;
    return RotateConstant{rotate, val};
}

}  // namespace DepositField
