#include "bf-p4c/phv/field_alignment.h"
#include <iostream>

FieldAlignment::FieldAlignment(nw_bitrange bitLayout)
    : network(bitLayout.lo % 8)
    , littleEndian(7 - bitLayout.hi % 8)
{ }

bool FieldAlignment::operator==(const FieldAlignment& other) const {
    return other.network == network && other.littleEndian == littleEndian;
}

bool FieldAlignment::operator!=(const FieldAlignment& other) const {
    return !(*this == other);
}

std::ostream& operator<<(std::ostream& out, const FieldAlignment& alignment) {
    out << "alignment { " << alignment.network << " nw, "
        << alignment.littleEndian << " le }";
    return out;
}
