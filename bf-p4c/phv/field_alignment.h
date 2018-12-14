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
    explicit FieldAlignment(le_bitrange bitLayout);

    bool operator==(const FieldAlignment& other) const;
    bool operator!=(const FieldAlignment& other) const;

    bool isByteAligned() const { return littleEndian == 0; }

    /// The alignment of the first bit of the field in network order (i.e., the
    /// MSB) specified as a network order bit index mod 8.
    unsigned network;

    /// The alignment of the first bit of the field in little endian order
    /// (i.e., the LSB) specified as a little endian order bit index mod 8.
    unsigned littleEndian;
};

std::ostream& operator<<(std::ostream&, const FieldAlignment&);

#endif /* EXTENSIONS_BF_P4C_PHV_FIELD_ALIGNMENT_H_ */
