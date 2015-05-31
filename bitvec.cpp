#include "bitvec.h"
#include "hex.h"

std::ostream &operator<<(std::ostream &os, const bitvec &bv) {
    if (bv.size == 1) {
        os << hex(bv.data);
    } else {
        bool first = true;
        for (int i = bv.size; i >= 0; i--) {
            if (first) {
                if (!bv.ptr[i]) continue;
                os << hex(bv.ptr[i]);
                first = false;
            } else
                os << hex(bv.ptr[i], sizeof(bv.data)*2, '0'); }
        if (first)
            os << '0';
    }
    return os;
}

bitvec &bitvec::operator>>=(unsigned count) {
    if (size == 1) {
        if (count >= bits_per_unit)
            data = 0;
        else
            data >>= count;
        return *this; }
    int off = count / bits_per_unit;
    count %= bits_per_unit;
    for (unsigned i = 0; i < size; i++)
        if (i + off < size) {
            ptr[i] = ptr[i+off] >> count;
            if (count && i + off + 1 < size)
                ptr[i] |= ptr[i+off+1] << (bits_per_unit - count);
        } else
            ptr[i] = 0;
    while (size > 1 && !ptr[size-1]) size--;
    if (size == 1) {
        auto tmp = ptr[0];
        delete [] ptr;
        data = tmp; }
    return *this;
}

bitvec &bitvec::operator<<=(unsigned count) {
    unsigned needsize = (max().index() + count + bits_per_unit - 1)/bits_per_unit;
    if (needsize > size) expand(needsize);
    if (size == 1) {
        data <<= count;
        return *this; }
    int off = count / bits_per_unit;
    count %= bits_per_unit;
    for (int i = size-1; i >= 0; i--)
        if (i >= off) {
            ptr[i] = ptr[i-off] << count;
            if (count && i > off)
                ptr[i] |= ptr[i-off-1] >> (bits_per_unit - count);
        } else
            ptr[i] = 0;
    return *this;
}
