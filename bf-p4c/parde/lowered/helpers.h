#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_HELPERS_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_HELPERS_H_

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/stringref.h"

namespace Parde::Lowered {

/// @return a version of the provided state name which is safe to use in the
/// generated assembly.
cstring sanitizeName(StringRef name);

/**
 * Construct debugging information describing a slice of a field.
 *
 * @param fieldRef  A reference to a field.
 * @param slice  An `alloc_slice` mapping a range of bits in the field to a
 *               range of bits in a container.
 * @param includeContainerInfo  If true, the result will include information
 *                              about which bits in the container the field
 *                              slice was mapped to.
 * @return a string describing which bits in the field are included in the
 * slice, and describing the corresponding bits in the container.
 */
cstring debugInfoFor(const IR::BFN::ParserLVal* lval, const PHV::AllocSlice& slice,
                     bool includeContainerInfo = true);

/**
 * Construct a string describing how an `Extract` primitive was mapped to a
 * hardware extract operation.
 *
 * @param extract  The original `Extract` primitive, with a field as the
 *                 destination.
 * @param slice  An `alloc_slice` mapping a range of bits in the field to a
 *               range of bits in a container.
 * @param bufferRange  For extracts that read from the input buffer, an input
 *                     buffer range corresponding to the range of bits in the
 *                     `alloc_slice`.
 * @param includeRangeInfo  If true, the range of bits being extracted into
 *                          the destination container is printed even if it
 *                          matches the size of the container exactly.
 * @return a string containing debugging info describing the mapping between the
 * field, the container, and the constant or input buffer region read by the
 * `Extract`.
 */
cstring debugInfoFor(const IR::BFN::Extract* extract, const PHV::AllocSlice& slice,
                     const nw_bitrange& bufferRange = nw_bitrange(), bool includeRangeInfo = false);

/// Maps a POV bit field to a single bit within a container, represented as a
/// ContainerBitRef. Checks that the allocation for the POV bit field is sane.
const IR::BFN::ContainerBitRef* lowerSingleBit(const PhvInfo& phv,
                                               const IR::BFN::FieldLVal* fieldRef,
                                               const PHV::AllocContext* ctxt);

/// Maps a sequence of fields to a sequence of PHV containers. The sequence of
/// fields is treated as ordered and non-overlapping; the resulting container
/// sequence is the shortest one which maintains these properties.
std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot*>> lowerFields(
    const PhvInfo& phv, const ClotInfo& clotInfo, const IR::Vector<IR::BFN::FieldLVal>& fields,
    bool is_checksum = false);

/// Maps a field which cannot be split between multiple containers to a single
/// container, represented as a ContainerRef. Checks that the allocation for the
/// field is sane.
const IR::BFN::ContainerRef* lowerUnsplittableField(const PhvInfo& phv, const ClotInfo& clotInfo,
                                                    const IR::BFN::FieldLVal* fieldRef,
                                                    const char* unsplittableReason);
}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_HELPERS_H_ */
