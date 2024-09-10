#include "backends/tofino/mau/mau_spec.h"
#include "input_xbar.h"

int TofinoIXBarSpec::getExactOrdBase(int group) const {
    return group * Tofino::IXBar::EXACT_BYTES_PER_GROUP;
}

int TofinoIXBarSpec::getTernaryOrdBase(int group) const {
    return Tofino::IXBar::EXACT_GROUPS * Tofino::IXBar::EXACT_BYTES_PER_GROUP +
        (group / 2) * Tofino::IXBar::TERNARY_BYTES_PER_BIG_GROUP +
        (group % 2) * (Tofino::IXBar::TERNARY_BYTES_PER_GROUP + 1 /* mid byte */);
}
