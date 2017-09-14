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

#ifndef EXTENSIONS_BF_P4C_PHV_FIELD_ALIGNMENT_H_
#define EXTENSIONS_BF_P4C_PHV_FIELD_ALIGNMENT_H_

#include <iosfwd>
#include "bf-p4c/ir/bitrange.h"

/// A helper type that represents the alignment of a field (or more generally,
/// of some object which is stored in a PHV container).
struct FieldAlignment {
    // Construct a FieldAlignment that satisfies the alignment requirement
    // implied by the provided on-the-wire layout. Usually this layout is the
    // range of bits operated on by an extract or emit for the field.
    explicit FieldAlignment(nw_bitrange bitLayout);

    bool operator==(const FieldAlignment& other) const;
    bool operator!=(const FieldAlignment& other) const;

    /// The alignment of the first bit of the field in network order (i.e., the
    /// MSB) specified as a network order bit index mod 8.
    unsigned network;

    /// The alignment of the first bit of the field in little endian order
    /// (i.e., the LSB) specified as a little endian order bit index mod 8.
    unsigned littleEndian;
};

std::ostream& operator<<(std::ostream&, const FieldAlignment&);

#endif /* EXTENSIONS_BF_P4C_PHV_FIELD_ALIGNMENT_H_ */
