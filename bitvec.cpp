#include "bitvec.h"
#include "hex.h"

std::ostream &operator<<(std::ostream &os, const bitvec &bv) {
    if (bv.size == 1) {
        os << hex(bv.data);
    } else {
        bool first = true;
        for (int i = bv.size-1; i >= 0; i--) {
            if (first) {
                if (!bv.ptr[i]) continue;
                os << hex(bv.ptr[i]);
                first = false;
            } else {
                os << hex(bv.ptr[i], sizeof(bv.data)*2, '0'); } }
        if (first)
            os << '0';
    }
    return os;
}

bitvec &bitvec::operator>>=(size_t count) {
    if (size == 1) {
        if (count >= bits_per_unit)
            data = 0;
        else
            data >>= count;
        return *this; }
    int off = count / bits_per_unit;
    count %= bits_per_unit;
    for (size_t i = 0; i < size; i++)
        if (i + off < size) {
            ptr[i] = ptr[i+off] >> count;
            if (count && i + off + 1 < size)
                ptr[i] |= ptr[i+off+1] << (bits_per_unit - count);
        } else {
            ptr[i] = 0; }
    while (size > 1 && !ptr[size-1]) size--;
    if (size == 1) {
        auto tmp = ptr[0];
        delete [] ptr;
        data = tmp; }
    return *this;
}

bitvec &bitvec::operator<<=(size_t count) {
    size_t needsize = (max().index() + count + bits_per_unit - 1)/bits_per_unit;
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
        } else {
            ptr[i] = 0; }
    return *this;
}

bitvec bitvec::getslice(size_t idx, size_t sz) const {
    if (idx >= size * bits_per_unit) return bitvec();
    if (idx + sz > size * bits_per_unit)
        sz = size * bits_per_unit - idx;
    if (size > 1) {
        bitvec rv;
        unsigned shift = idx % bits_per_unit;
        idx /= bits_per_unit;
        if (sz > bits_per_unit) {
            rv.expand((sz-1)/bits_per_unit + 1);
            for (size_t i = 0; i < rv.size; i++) {
                if (shift != 0 && i != 0)
                    rv.ptr[i-1] |= ptr[idx + 1] << (bits_per_unit - shift);
                rv.ptr[i] = ptr[idx] >> shift; }
            if ((sz %= bits_per_unit))
                rv.ptr[rv.size-1] &= ~(~(uintptr_t)1 << (sz-1));
        } else {
            rv.data = ptr[idx] >> shift;
            if (shift != 0 && idx + 1 < size)
                rv.data |= ptr[idx + 1] << (bits_per_unit - shift);
            rv.data &= ~(~(uintptr_t)1 << (sz-1)); }
        return rv;
    } else {
        return bitvec((data >> idx) & ~(~(uintptr_t)1 << (sz-1))); }
}

int bitvec::ffs(unsigned start) const {
    uintptr_t val = ~0ULL;
    unsigned idx = start / bits_per_unit;
    val <<= (start % bits_per_unit);
    if (size > 1) {
        while (idx < size && !(ptr[idx]&val)) {
            ++idx;
            val = ~0ULL; }
        if (idx < size)
            val &= ptr[idx];
    } else {
        val &= data; }
    if (!val || idx >= size) return -1;
    unsigned rv = idx * bits_per_unit;
    while ((val & 0xff) == 0) { rv += 8; val >>= 8; }
    while ((val & 1) == 0) { rv++; val >>= 1; }
    return rv;
}

unsigned bitvec::ffz(unsigned start) const {
    uintptr_t val = 0;
    unsigned idx = start / bits_per_unit;
    val = ~(~val << (start % bits_per_unit));
    if (size > 1) {
        while (idx < size && !~(ptr[idx]|val)) {
            ++idx;
            val = 0; }
        if (idx < size)
            val |= ptr[idx];
    } else if (idx) {
        return start;
    } else {
        val |= data; }
    unsigned rv = idx * bits_per_unit;
    while ((val & 0xff) == 0xff) { rv += 8; val >>= 8; }
    while (val & 1) { rv++; val >>= 1; }
    return rv;
}
