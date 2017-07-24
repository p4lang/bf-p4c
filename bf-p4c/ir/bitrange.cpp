/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/ir/bitrange.h"

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
