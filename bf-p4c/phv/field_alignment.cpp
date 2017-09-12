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

#include "tofino/phv/field_alignment.h"
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
