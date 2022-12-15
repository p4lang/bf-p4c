#include "helpers.h"

#include <utility>

#include <boost/range/adaptor/reversed.hpp>

namespace Parde::Lowered {

/// @return a version of the provided state name which is safe to use in the
/// generated assembly.
cstring sanitizeName(StringRef name) {
    // Drop any thread-specific prefix from the name.
    if (auto prefix = name.findstr("::")) name = name.after(prefix) += 2;
    return name;
}

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
                     bool includeContainerInfo) {
    std::stringstream info;

    auto fieldRef = lval->to<IR::BFN::FieldLVal>();
    if (!fieldRef) return info;

    // Describe the range of bits assigned to this field slice in the container.
    // (In some cases we break this down in more detail elsewhere, so we don't
    // need to repeat it.)
    if (includeContainerInfo) {
        const le_bitrange sourceBits = slice.container_slice();
        if (sourceBits.size() != ssize_t(slice.container().size())) info << sourceBits << ": ";
    }

    // Identify the P4 field that we're writing to.
    info << fieldRef->field->toString();

    // Although it's confusing given that e.g. input buffer ranges are printed
    // in network order, consistency with the rest of the output of the
    // assembler requires that we describe partial writes to a field in little
    // endian order.
    const le_bitrange destFieldBits = slice.field_slice();
    if (slice.field()->size != destFieldBits.size())
        info << "." << destFieldBits.lo << "-" << destFieldBits.hi;

    return cstring(info);
}

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
                     const nw_bitrange& bufferRange,
                     bool includeRangeInfo) {
    std::stringstream info;

    // Describe the value that's being written into the destination container.
    if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
        info << "value " << constantSource->constant << " -> " << slice.container() << " "
             << slice.container_slice() << ": ";
    } else if (extract->source->is<IR::BFN::PacketRVal>()) {
        // In the interest of brevity, don't print the range of bits being
        // extracted into the destination container if it matches the size of
        // the container exactly.
        // This behaviour can be overridden by explicit true value of
        // includeRangeInfo parameter in case we desire to print the range always.
        if (includeRangeInfo || slice.container().size() != size_t(bufferRange.size()))
            info << bufferRange << " -> " << slice.container() << " " << slice.container_slice()
                 << ": ";
    } else if (extract->source->is<IR::BFN::MetadataRVal>()) {
        info << "buffer mapped I/O: " << bufferRange << " -> " << slice.container() << " "
             << slice.container_slice() << ": ";
    }

    // Describe the field slice that we're writing to.
    info << debugInfoFor(extract->dest, slice, /* includeContainerInfo = */ false);

    return cstring(info);
}

/// Maps a POV bit field to a single bit within a container, represented as a
/// ContainerBitRef. Checks that the allocation for the POV bit field is sane.
const IR::BFN::ContainerBitRef* lowerSingleBit(const PhvInfo& phv,
                                               const IR::BFN::FieldLVal* fieldRef,
                                               const PHV::AllocContext* ctxt) {
    le_bitrange range;
    auto* field = phv.field(fieldRef->field, &range);

    std::vector<PHV::AllocSlice> slices;
    field->foreach_alloc(&range, ctxt, nullptr,
                         [&](const PHV::AllocSlice& alloc) { slices.push_back(alloc); });

    BUG_CHECK(!slices.empty(), "bit %1% didn't receive a PHV allocation", fieldRef->field);
    BUG_CHECK(slices.size() == 1,
              "bit %1% is somehow split across "
              "multiple containers?",
              fieldRef->field);

    auto container = new IR::BFN::ContainerRef(slices.back().container());
    auto containerRange = slices.back().container_slice();
    BUG_CHECK(containerRange.size() == 1, "bit %1% is multiple bits?", fieldRef->field);

    auto* bit = new IR::BFN::ContainerBitRef(container, containerRange.lo);
    LOG5("Mapping bit field " << fieldRef->field << " to " << bit);
    bit->debug.info.push_back(debugInfoFor(fieldRef, slices.back(),
                                           /* includeContainerInfo = */ false));
    return bit;
}

/// Maps a sequence of fields to a sequence of PHV containers. The sequence of
/// fields is treated as ordered and non-overlapping; the resulting container
/// sequence is the shortest one which maintains these properties.
std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot*>> lowerFields(
    const PhvInfo& phv, const ClotInfo& clotInfo, const IR::Vector<IR::BFN::FieldLVal>& fields,
    bool is_checksum) {
    IR::Vector<IR::BFN::ContainerRef> containers;
    std::vector<Clot*> clots;

    IR::BFN::ContainerRef* last = nullptr;
    // Perform a left fold over the field sequence and merge contiguous fields
    // which have been placed in the same container into a single container
    // reference.
    for (auto* fieldRef : fields) {
        auto field = phv.field(fieldRef->field);
        assoc::map<const PHV::FieldSlice*, Clot*, PHV::FieldSlice::Greater>* slice_clots = nullptr;
        if (clotInfo.is_readonly(field) && is_checksum) {
            slice_clots = clotInfo.slice_clots(field);
        } else {
            slice_clots = clotInfo.allocated_slices(field);
        }
        if (slice_clots) {
            for (auto entry : *slice_clots) {
                auto clot = entry.second;
                if (clots.empty() || clots.back() != clot) clots.push_back(clot);
            }

            if (clotInfo.fully_allocated(field) ||
                (clotInfo.is_readonly(field) && clotInfo.whole_field_clot(field)))
                continue;
        }

        // padding in digest list does not need phv allocation
        if (field->is_ignore_alloc()) continue;

        PHV::FieldUse use(PHV::FieldUse::READ);
        std::vector<PHV::AllocSlice> slices =
            phv.get_alloc(fieldRef->field, PHV::AllocContext::DEPARSER, &use);

        BUG_CHECK(!slices.empty(), "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        for (auto& slice : boost::adaptors::reverse(slices)) {
            BUG_CHECK(bool(slice.container()),
                      "Emitted field was allocated to "
                      "an invalid PHV container: %1%",
                      fieldRef->field);

            const nw_bitrange containerRange =
                slice.container_slice().toOrder<Endian::Network>(slice.container().size());

            if (last && last->container == slice.container()) {
                auto lastRange = *(last->range);
                if (lastRange.hi < containerRange.lo) {
                    LOG5(" - Merging in " << fieldRef->field);
                    last->debug.info.push_back(debugInfoFor(fieldRef, slice));
                    last->range = lastRange.unionWith(containerRange);
                    continue;
                }
            }

            LOG5("Deparser: lowering field " << fieldRef->field << " to " << slice.container());

            last = new IR::BFN::ContainerRef(slice.container());
            last->range = containerRange;
            last->debug.info.push_back(debugInfoFor(fieldRef, slice));
            containers.push_back(last);

            if (slice.field()->is_checksummed() && slice.field()->is_solitary()) {
                // Since the field has a solitary constraint, its is safe to
                // extend the range till the end of container
                last->range =
                    containerRange.unionWith(nw_bitrange(StartLen(0, slice.container().size())));
            }
        }
    }

    return {containers, clots};
}

/// Maps a field which cannot be split between multiple containers to a single
/// container, represented as a ContainerRef. Checks that the allocation for the
/// field is sane.
const IR::BFN::ContainerRef* lowerUnsplittableField(const PhvInfo& phv, const ClotInfo& clotInfo,
                                                    const IR::BFN::FieldLVal* fieldRef,
                                                    const char* unsplittableReason) {
    IR::Vector<IR::BFN::ContainerRef> containers;
    std::tie(containers, std::ignore) = lowerFields(phv, clotInfo, {fieldRef});
    BUG_CHECK(containers.size() == 1,
              "Field %1% must be placed in a single container because it's "
              "used in the deparser as a %2%, but it was sliced across %3% "
              "containers",
              fieldRef->field, unsplittableReason, containers.size());
    return containers.back();
}

}  // namespace Parde::Lowered
