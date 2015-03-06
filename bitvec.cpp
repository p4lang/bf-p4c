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

