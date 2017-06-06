#include <assert.h>
#include "hex.h"

std::ostream &operator<<(std::ostream &os, const hexvec &h) {
    auto save = os.flags();
    char *p = (char *)h.data;
    for (size_t i = 0; i < h.len; i++, p += h.elsize) {
        os << (i ? ' ' : '[');
        uintmax_t val;
        switch(h.elsize) {
        case 1:
            val = *(unsigned char *)p;
            break;
        case 2:
            val = *(unsigned short *)p;
            break;
        case 4:
            if (sizeof(unsigned) == 4)
                val = *(unsigned *)p;
            else if (sizeof(unsigned long) == 4)
                val = *(unsigned long *)p;
            else
                assert(0);
            break;
        case 8:
            if (sizeof(unsigned long) == 8)
                val = *(unsigned long *)p;
            else if (sizeof(unsigned long long) == 8)
                val = *(unsigned long long *)p;
            else
                assert(0);
            break;
        default:
            val = *(uintmax_t *)p;
            val &= ~(~0ULL << 8*h.elsize); }
        os << std::hex << std::setw(h.width) << std::setfill(h.fill) << val; }
    os << ']';
    os.flags(save);
    return os;
}
