#include "bf-p4c/ir/bitrange.h"

#include <iostream>

namespace {

void writeRange(std::ostream& out, const char* prefix, int lo, int hi) {
    out << prefix << '[' << lo;
    if (hi != lo) out << ".." << hi;
    out << ']';
}

void writeInterval(std::ostream& out, const char* prefix, int lo, int hi) {
    out << prefix << '[' << lo;
    if (hi != lo) out << ".." << hi;
    out << ')';
}

}  // namespace

std::ostream&
operator<<(std::ostream& out, const bit_range<Endian::Network>& bits) {
    writeRange(out, "N", bits.lo, bits.hi);
    return out;
}

std::ostream&
operator<<(std::ostream& out, const bit_range<Endian::Little>& bits) {
    writeRange(out, "", bits.lo, bits.hi);
    return out;
}

std::ostream&
operator<<(std::ostream& out, const bit_interval<Endian::Network>& bits) {
    writeInterval(out, "N", bits.lo, bits.hi);
    return out;
}

std::ostream&
operator<<(std::ostream& out, const bit_interval<Endian::Little>& bits) {
    writeInterval(out, "", bits.lo, bits.hi);
    return out;
}
