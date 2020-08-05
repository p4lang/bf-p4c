#ifndef BF_ASM_MASK_COUNTER_H_
#define BF_ASM_MASK_COUNTER_H_

#include <limits.h>
#include "bitvec.h"

class MaskCounter {
    unsigned    mask, val;
    bool        oflo;
 public:
    explicit MaskCounter(unsigned m) : mask(m), val(0), oflo(false) {}
    explicit operator bool() const { return !oflo; }
    operator unsigned() const { return val; }
    bool operator==(const MaskCounter &a) const {
        return val == a.val && oflo == a.oflo; }
    MaskCounter &operator++() {
        val = ((val | ~mask) + 1) & mask;
        if (val == 0) oflo = true;
        return *this; }
    MaskCounter operator++(int) {
        MaskCounter tmp(*this); ++*this; return tmp; }
    MaskCounter &operator--() {
        val = (val - 1) & mask;
        if (val == mask) oflo = true;
        return *this; }
    MaskCounter operator--(int) {
        MaskCounter tmp(*this); --*this; return tmp; }
    MaskCounter &clear() { val = 0; oflo = false; return *this; }
    MaskCounter &overflow(bool v = true) { oflo = v; return *this; }
};

#endif /* BF_ASM_MASK_COUNTER_H_ */
