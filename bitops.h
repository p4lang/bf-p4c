#ifndef _bitops_h_
#define _bitops_h_

class MaskCounter {
    unsigned    mask, val;
    bool        oflo;
public:
    MaskCounter(unsigned m) : mask(m), val(0), oflo(false) {}
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

inline unsigned bitcount(unsigned v) {
    unsigned rv = 0;
    while (v) { v &= v-1; ++rv; }
    return rv; }

#endif /* _bitops_h_ */
