#ifndef _DEPOSITFIELD_H_
#define _DEPOSITFIELD_H_

#include <stdint.h>

namespace DepositField {

struct RotateConstant {
    unsigned rotate;
    int32_t value;
};

RotateConstant discoverRotation(int32_t val, int containerSize,
                                int32_t tooLarge, int32_t tooSmall);

}  // namespace DepositField

#endif /* _DEPOSITFIELD_H_ */
