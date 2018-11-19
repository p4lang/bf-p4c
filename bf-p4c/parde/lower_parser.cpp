#include "bf-p4c/parde/lower_parser.h"

#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>

#include <algorithm>
#include <numeric>
#include <sstream>
#include <type_traits>
#include <utility>
#include <vector>

#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/characterize_parser.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/stringref.h"

namespace {

using alloc_slice = PHV::Field::alloc_slice;

/**
 * Construct debugging debugging information describing a slice of a field.
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
cstring debugInfoFor(const IR::BFN::ParserLVal* lval,
                     const alloc_slice& slice,
                     bool includeContainerInfo = true) {
    std::stringstream info;

    auto fieldRef = lval->to<IR::BFN::FieldLVal>();
    if (!fieldRef) return info;

    // Describe the range of bits assigned to this field slice in the container.
    // (In some cases we break this down in more detail elsewhere, so we don't
    // need to repeat it.)
    if (includeContainerInfo) {
        const le_bitrange sourceBits = slice.container_bits();
        if (sourceBits.size() != ssize_t(slice.container.size()))
            info << sourceBits << ": ";
    }

    // Identify the P4 field that we're writing to.
    info << fieldRef->field->toString();

    // Although it's confusing given that e.g. input buffer ranges are printed
    // in network order, consistency with the rest of the output of the
    // assembler requires that we describe partial writes to a field in little
    // endian order.
    const le_bitrange destFieldBits = slice.field_bits();
    if (slice.field->size != destFieldBits.size())
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
 * @return a string containing debugging info describing the mapping between the
 * field, the container, and the constant or input buffer region read by the
 * `Extract`.
 */
cstring debugInfoFor(const IR::BFN::Extract* extract,
                     const alloc_slice& slice,
                     const nw_bitrange& bufferRange = nw_bitrange()) {
    std::stringstream info;

    // Describe the value that's being written into the destination container.
    if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
        info << "value " << constantSource->constant << " -> "
             << slice.container << " " << slice.container_bits() << ": ";
    } else if (extract->source->is<IR::BFN::PacketRVal>()) {
        // In the interest of brevity, don't print the range of bits being
        // extracted into the destination container if it matches the size of
        // the container exactly.
        if (slice.container.size() != size_t(bufferRange.size()))
            info << bufferRange << " -> " << slice.container << " "
                 << slice.container_bits() << ": ";
    } else if (extract->source->is<IR::BFN::MetadataRVal>()) {
        info << "buffer mapped I/O: " << bufferRange << " -> "
             << slice.container << " " << slice.container_bits() << ": ";
    }

    // Describe the field slice that we're writing to.
    info << debugInfoFor(extract->dest, slice, /* includeContainerInfo = */ false);

    return cstring(info);
}

/// @return a string containing debugging info describing what a Select
/// primitive is matching against.
cstring debugInfoFor(const IR::BFN::Select* select, nw_byterange source) {
    std::stringstream info;

    info << "match " << source << ": ";
    if (select->p4Source)
        info << select->p4Source->toString();
    else
        info << "(buffer)";

    return cstring(info);
}

/// A predicate which orders input packet bit intervals by where they end.
/// Empty intervals are ordered last.
static bool isIntervalEarlierInPacket(nw_byteinterval a,
                                      nw_byteinterval b) {
    if (a.empty()) return false;
    if (b.empty()) return true;
    return a.hi != b.hi ? a.hi < b.hi
                        : a.lo < b.lo;
}

/// A predicate which orders extracts by where their input data ends. Extracts
/// which don't come from the input packet are ordered last - they're lowest
/// priority, since we can execute them at any time without delaying other
/// extracts.
static bool isExtractPhvEarlierInPacket(const IR::BFN::LoweredExtractPhv* a,
                                        const IR::BFN::LoweredExtractPhv* b) {
    auto* aFromPacket = a->source->to<IR::BFN::LoweredPacketRVal>();
    auto* bFromPacket = b->source->to<IR::BFN::LoweredPacketRVal>();
    if (aFromPacket && bFromPacket)
        return isIntervalEarlierInPacket(aFromPacket->byteInterval(),
                                         bFromPacket->byteInterval());
    return aFromPacket;
}

static bool isExtractClotEarlierInPacket(const IR::BFN::LoweredExtractClot* a,
                                         const IR::BFN::LoweredExtractClot* b) {
    auto* aFromPacket = a->source->to<IR::BFN::LoweredPacketRVal>();
    auto* bFromPacket = b->source->to<IR::BFN::LoweredPacketRVal>();
    if (aFromPacket && bFromPacket)
        return isIntervalEarlierInPacket(aFromPacket->byteInterval(),
                                         bFromPacket->byteInterval());
    return aFromPacket;
}

/// Helper class that splits extract operations into multiple smaller extracts,
/// such that each extract writes to exactly one PHV container.
struct ExtractSimplifier {
    const PhvInfo& phv;
    const ClotInfo& clot;

    ExtractSimplifier(const PhvInfo& phv, const ClotInfo& clot) : phv(phv), clot(clot) { }

    using ExtractSequence = std::vector<const IR::BFN::LoweredExtractPhv*>;

    /// Add a new extract operation to the sequence.
    void add(const IR::BFN::Extract* extract) {
        LOG4("[ExtractSimplifier] adding: " << extract);

        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        auto checksum_lval = extract->dest->to<IR::BFN::ChecksumLVal>();

        const PHV::Field *field = nullptr;
        if (lval) field = phv.field(lval->field);
        else if (checksum_lval) field = phv.field(checksum_lval->field);

        if (field) {
            if (auto c = clot.clot(field)) {
                if (auto* rval = extract->source->to<IR::BFN::PacketRVal>())
                    clotRVals[c].push_back(rval);
                if (!c->is_phv_field(field))
                    return;
            }
        }

        if (!lval) return;

        std::vector<alloc_slice> slices = phv.get_alloc(lval->field);
        if (slices.empty()) {
            BUG("Parser extract didn't receive a PHV allocation: %1%", extract);
            return;
        }

        for (const auto& slice : slices)
            BUG_CHECK(bool(slice.container),
                      "Parser extracts into invalid PHV container: %1%", extract);

        if (auto* bufferSource = extract->source->to<IR::BFN::InputBufferRVal>()) {
            for (const auto& slice : slices) {
                // Shift the slice to its proper place in the input buffer.
                auto bitOffset = bufferSource->range().lo;
                const nw_bitrange bufferRange = slice.field_bits()
                  .toOrder<Endian::Network>(lval->size())
                  .shiftedByBits(bitOffset);

                // Expand the buffer slice so that it will write to the entire
                // destination container, with this slice in the proper place.
                // If the slice didn't fit the container exactly, this will
                // write to more bits than were included in the slice, but if
                // PHV allocation did its job then those bit are either unused,
                // or are occupied by other extracts that we'll merge with this
                // one.
                const nw_bitrange containerRange =
                  slice.container_bits().toOrder<Endian::Network>(slice.container.size());
                const nw_bitrange finalBufferRange =
                  bufferRange.shiftedByBits(-containerRange.lo)
                             .resizedToBits(slice.container.size());

                LOG4(" - Mapping input buffer field slice " << bufferRange
                      << " into " << slice.container << " " << containerRange
                      << ". Final buffer range: " << finalBufferRange);

                // At this point, we should have a byte aligned range that can
                // be implemented as an extraction operation by the hardware.
                BUG_CHECK(finalBufferRange.isLoAligned() &&
                          finalBufferRange.isHiAligned(),
                          "Extract field slice %1% into %2% %3% resulted in "
                          "non-byte-aligned buffer range %4% for: %5%",
                          bufferRange, slice.container, containerRange,
                          finalBufferRange, extract);
                BUG_CHECK(finalBufferRange.lo >= 0,
                          "Extract field slice %1% into %2% %3% resulted in "
                          "buffer range %4% with a negative offset: %5%",
                          bufferRange, slice.container, containerRange,
                          finalBufferRange, extract);
                const auto byteFinalBufferRange =
                  finalBufferRange.toUnit<RangeUnit::Byte>();

                // Generate the lowered extract.
                const IR::BFN::LoweredParserRVal* newSource;
                if (bufferSource->is<IR::BFN::PacketRVal>())
                    newSource = new IR::BFN::LoweredPacketRVal(byteFinalBufferRange);
                else
                    newSource = new IR::BFN::LoweredMetadataRVal(byteFinalBufferRange);

                auto* newExtract = new IR::BFN::LoweredExtractPhv(slice.container, newSource);
                newExtract->debug.info.push_back(debugInfoFor(extract, slice,
                                                              bufferRange));

                if (bufferSource->is<IR::BFN::PacketRVal>())
                    extractFromPacketByContainer[slice.container].push_back(newExtract);
                else
                    extractFromBufferByContainer[slice.container].push_back(newExtract);
            }
        } else if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
            for (auto& slice : boost::adaptors::reverse(slices)) {
                // Large constant may be extracted across multiple containers, therefore we
                // need to slice the containt into multiple slices and align each slice
                // within each container.

                auto constSlice = *(constantSource->constant) >> slice.field_bits().lo;
                constSlice = constSlice & IR::Constant::GetMask(slice.width);

                // Place those bits at their offset within the container.
                constSlice = constSlice << slice.container_bits().lo;

                LOG4("  Placing constant slice " << constSlice << " into " << slice.container);

                BUG_CHECK(constSlice.fitsUint(), "Constant slice larger than 32-bit?");

                // Create an extract that writes just those bits.
                auto* newSource =
                  new IR::BFN::LoweredConstantRVal(constSlice.asUnsigned());
                auto* newExtract =
                  new IR::BFN::LoweredExtractPhv(slice.container, newSource);

                newExtract->debug.info.push_back(debugInfoFor(extract, slice));
                extractConstantByContainer[slice.container].push_back(newExtract);
            }
        } else {
            BUG("Unexpected parser primitive (most likely something that should "
                "have been eliminated by an earlier pass): %1%", extract);
        }
    }

    template <typename InputBufferRValType>
    static const IR::BFN::LoweredExtractPhv*
    mergeExtractsFor(PHV::Container container, const ExtractSequence& extracts) {
        BUG_CHECK(!extracts.empty(), "Trying merge an empty sequence of extracts?");
        if (extracts.size() == 1)
            return extracts[0];

        // Merge the input buffer range for every extract that writes to
        // this container. They should all be the same, but if they aren't
        // we want to know about it.
        nw_byteinterval bufferRange;
        for (auto* extract : extracts) {
            auto* bufferSource = extract->source->to<InputBufferRValType>();
            BUG_CHECK(bufferSource, "Unexpected non-buffer source");

            if (std::is_same<InputBufferRValType, IR::BFN::LoweredMetadataRVal>::value)
                BUG_CHECK(toHalfOpenRange(Device::pardeSpec().byteMappedInputBufferRange())
                            .contains(bufferSource->byteInterval()),
                          "Buffer mapped I/O range is outside of the mapped input "
                          "buffer range: %1%", bufferSource->byteInterval());

            bufferRange = bufferSource->byteInterval().unionWith(bufferRange);
        }

        BUG_CHECK(!bufferRange.empty(), "Extracting zero bytes?");
        const size_t extractedSizeBits =
          bufferRange.toUnit<RangeUnit::Bit>().size();
        BUG_CHECK(extractedSizeBits == container.size(),
                  "Extracted range %1% with size %2% doesn't match "
                  "destination container %3% with size %4%; was the PHV "
                  "allocation misaligned or inconsistent?", bufferRange,
                  extractedSizeBits, container, container.size());

        // Create a single combined extract that implements all of the
        // component extracts. Because `add()` expands each extract
        // operation so that it writes to an entire container, if PHV
        // allocation did its job all of these extracts should read the same
        // bytes of the input buffer - they're in some sense "the same".
        // We only need to merge their debug info.
        const auto* finalBufferValue =
          new InputBufferRValType(*toClosedRange(bufferRange));
        auto* mergedExtract = new IR::BFN::LoweredExtractPhv(container, finalBufferValue);
        for (auto* extract : extracts)
            mergedExtract->debug.mergeWith(extract->debug);

        return mergedExtract;
    }

    /// Convert the sequence of Extract operations that have been passed to
    /// `add()` so far into a sequence of LoweredExtract operations. Extracts
    /// that write to the same container are merged together.
    IR::Vector<IR::BFN::LoweredParserPrimitive> lowerExtracts() {
        IR::Vector<IR::BFN::LoweredParserPrimitive> loweredExtracts;

        for (auto& item : extractFromPacketByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto* merged = mergeExtractsFor<IR::BFN::LoweredPacketRVal>(container, extracts);
            loweredExtracts.push_back(merged);
        }

        for (auto& item : extractFromBufferByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto* merged = mergeExtractsFor<IR::BFN::LoweredMetadataRVal>(container, extracts);
            loweredExtracts.push_back(merged);
        }

        for (auto& item : extractConstantByContainer) {
            auto container = item.first;
            auto& extracts = item.second;

            BUG_CHECK(!extracts.empty(), "Trying merge an empty sequence of extracts?");
            if (extracts.size() == 1) {
                loweredExtracts.push_back(extracts[0]);
                continue;
            }

            // Merge all of the constant extracts for this container into a
            // single operation. Because `add()` expands each constant write to
            // operate over the entire container, all we need to do is OR the
            // constants together.
            auto* mergedValue = new IR::BFN::LoweredConstantRVal(0);
            auto* mergedExtract = new IR::BFN::LoweredExtractPhv(container, mergedValue);
            for (auto* extract : extracts) {
                auto* constantSource =
                  extract->source->to<IR::BFN::LoweredConstantRVal>();
                BUG_CHECK(constantSource, "Unexpected non-constant source");
                mergedValue->constant |= constantSource->constant;
                mergedExtract->debug.mergeWith(extract->debug);
            }

            loweredExtracts.push_back(mergedExtract);
        }

        for (auto cx : clotRVals) {
            nw_bitinterval bitInterval;

            for (auto rval : cx.second)
                bitInterval = bitInterval.unionWith(rval->interval());

            nw_bitrange bitrange = *toClosedRange(bitInterval);
            nw_byterange byterange = bitrange.toUnit<RangeUnit::Byte>();

            auto rval = new IR::BFN::LoweredPacketRVal(byterange);
            auto extractClot = new IR::BFN::LoweredExtractClot(*(cx.first), rval);
            loweredExtracts.push_back(extractClot);
        }

        return loweredExtracts;
    }

    /// The sequence of extract operations to be simplified. They're organized
    /// by container so that multiple extracts to the same container can be
    /// merged.
    std::map<PHV::Container, ExtractSequence> extractFromPacketByContainer;
    std::map<PHV::Container, ExtractSequence> extractFromBufferByContainer;
    std::map<PHV::Container, ExtractSequence> extractConstantByContainer;

    std::map<const Clot*, std::vector<const IR::BFN::PacketRVal*>> clotRVals;
};

using LoweredParserIRStates = std::map<const IR::BFN::ParserState*,
                                       const IR::BFN::LoweredParserState*>;

/// Maps a sequence of fields to a sequence of PHV containers. The sequence of
/// fields is treated as ordered and non-overlapping; the resulting container
/// sequence is the shortest one which maintains these properties.
std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot> >
lowerFields(const PhvInfo& phv, const ClotInfo& clotInfo,
            const IR::Vector<IR::BFN::FieldLVal>& fields) {
    IR::Vector<IR::BFN::ContainerRef> containers;
    std::vector<Clot> clots;

    IR::BFN::ContainerRef* last = nullptr;
    // Perform a left fold over the field sequence and merge contiguous fields
    // which have been placed in the same container into a single container
    // reference.
    for (auto* fieldRef : fields) {
        auto field = phv.field(fieldRef->field);

        if (auto* clot = clotInfo.allocated(field)) {
            if (clots.empty() || clots.back().tag != clot->tag)
                clots.push_back(*clot);
            continue;
        }

        std::vector<alloc_slice> slices = phv.get_alloc(fieldRef->field);

        BUG_CHECK(!slices.empty(),
                  "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        // FIXME(zma) seth somehow thought it was a brilliant idea to
        // flip the bit order and then walk the list backward. I'd say it's
        // deliberate obfuscation. More than that, the side effect of such
        // bit flipping is that wherever the bit range is consumed downstream,
        // the bit range needs to be flipped back to its correct order.
        for (auto& slice : boost::adaptors::reverse(slices)) {
            BUG_CHECK(bool(slice.container), "Emitted field was allocated to "
                      "an invalid PHV container: %1%", fieldRef->field);

            const nw_bitrange containerRange = slice.container_bits()
                .toOrder<Endian::Network>(slice.container.size());

            if (last && last->container == slice.container) {
                auto lastRange = *(last->range);
                    if (lastRange.hi < containerRange.lo) {
                    LOG5(" - Merging in " << fieldRef->field);
                    last->debug.info.push_back(debugInfoFor(fieldRef, slice));
                    last->range = lastRange.unionWith(containerRange);
                    continue;
                }
            }

            LOG5("Deparser: lowering field " << fieldRef->field
                  << " to " << slice.container);

            last = new IR::BFN::ContainerRef(slice.container);
            last->range = containerRange;
            last->debug.info.push_back(debugInfoFor(fieldRef, slice));
            containers.push_back(last);

            // Deparser checksum engine exposes input entries as 16-bit.
            // PHV container entry needs a swap if the field's 2-byte alignment
            // in the container is not same as the alignment in the packet layout
            // i.e. off by 1 byte. For example, this could happen if "ipv4.ttl" is
            // allocated to a 8-bit container.

            // XXX(zma) it's unclear whether to get field's 2-byte alignment
            // from the packet layout or the field list layout. The field list
            // layout is lost in translation from v1 to tna ...

            bool isResidualChecksum = false;

            std::string f_name(field->name.c_str());
            if (f_name.find("compiler_generated_meta") != std::string::npos
             && f_name.find("residual_checksum_") != std::string::npos)
                isResidualChecksum = true;

            if (!isResidualChecksum &&
                slice.container_bits().hi % 16 !=
                (field->offset + slice.field_bits().hi) % 16)
                last->swap = (1 << slice.container_bits().hi/16U) |
                             (1 << slice.container_bits().lo/16U);
        }
    }

    return {containers, clots};
}

/// Maps a POV bit field to a single bit within a container, represented as a
/// ContainerBitRef. Checks that the allocation for the POV bit field is sane.
const IR::BFN::ContainerBitRef*
lowerPovBit(const PhvInfo& phv, const IR::BFN::FieldLVal* fieldRef) {
    le_bitrange range;
    auto* field = phv.field(fieldRef->field, &range);

    std::vector<alloc_slice> slices;
    field->foreach_alloc(&range, [&](const PHV::Field::alloc_slice& alloc) {
        slices.push_back(alloc);
    });

    BUG_CHECK(!slices.empty(), "POV bit %1% didn't receive a PHV allocation",
              fieldRef->field);
    BUG_CHECK(slices.size() == 1, "POV bit %1% is somehow split across "
              "multiple containers?", fieldRef->field);

    auto container = new IR::BFN::ContainerRef(slices.back().container);
    auto containerRange = slices.back().container_bits();
    BUG_CHECK(containerRange.size() == 1, "POV bit %1% is multiple bits?",
              fieldRef->field);

    auto* povBit = new IR::BFN::ContainerBitRef(container, containerRange.lo);
    LOG5("Mapping POV bit field " << fieldRef->field << " to " << povBit);
    povBit->debug.info.push_back(debugInfoFor(fieldRef, slices.back(),
                                              /* includeContainerInfo = */ false));
    return povBit;
}

/// Maps a field which cannot be split between multiple containers to a single
/// container, represented as a ContainerRef. Checks that the allocation for the
/// field is sane.
const IR::BFN::ContainerRef*
lowerUnsplittableField(const PhvInfo& phv,
                       const ClotInfo& clotInfo,
                       const IR::BFN::FieldLVal* fieldRef,
                       const char* unsplittableReason) {
    IR::Vector<IR::BFN::ContainerRef> containers;
    std::tie(containers, std::ignore) = lowerFields(phv, clotInfo, { fieldRef });
    BUG_CHECK(containers.size() == 1,
              "Field %1% must be placed in a single container because it's "
              "used in the deparser as a %2%, but it was sliced across %3% "
              "containers", fieldRef->field, unsplittableReason,
              containers.size());
    return containers.back();
}

/// Combine the high-level parser IR and the results of PHV allocation to
/// produce a low-level, target-specific representation of the parser program.
/// Note that the new IR is just constructed here; ReplaceParserIR is what
/// actually replaces the high-level IR with the lowered version.
struct ComputeLoweredParserIR : public ParserInspector {
    explicit ComputeLoweredParserIR(const PhvInfo& phv, ClotInfo& clotInfo,
               const AllocateParserChecksumUnits& checksumAlloc) :
        phv(phv), clotInfo(clotInfo), checksumAlloc(checksumAlloc) {
        // Initialize the map from high-level parser states to low-level parser
        // states so that null, which represents the end of the parser program
        // in the high-level IR, is mapped to null, which conveniently enough
        // means the same thing in the lowered IR.
        loweredStates[nullptr] = nullptr;
    }

    LoweredParserIRStates loweredStates;
    const IR::BFN::ContainerRef* igParserError = nullptr;
    const IR::BFN::ContainerRef* egParserError = nullptr;

 private:
    /// @return a version of the provided state name which is safe to use in the
    /// generated assembly.
    cstring sanitizeName(StringRef name) {
        // Drop any thread-specific prefix from the name.
        if (auto prefix = name.findstr("::"))
            name = name.after(prefix) += 2;
        return name;
    }

    IR::Vector<IR::BFN::LoweredParserChecksum>
    lowerParserChecksums(const IR::BFN::Parser* parser,
                         const IR::BFN::ParserState* state,
                         const std::vector<const IR::BFN::ParserChecksumPrimitive*>& checksums) {
        IR::Vector<IR::BFN::LoweredParserChecksum> loweredChecksums;

        std::map<unsigned,
                 std::vector<const IR::BFN::ParserChecksumPrimitive*>> csum_id_to_prims;

        for (auto prim : checksums) {
            unsigned id = checksumAlloc.declToChecksumId.at(parser).at(prim->declName);
            csum_id_to_prims[id].push_back(prim);
        }

        for (auto& kv : csum_id_to_prims)
           loweredChecksums.push_back(lowerParserChecksum(parser, state, kv.first, kv.second));

        return loweredChecksums;
    }

    /// Create lowered HW checksum primitives that can be consumed by the assembler.
    /// Get the checksum unit allocation from checksumAlloc and destination container
    /// from PHV allocation.
    IR::BFN::LoweredParserChecksum*
    lowerParserChecksum(const IR::BFN::Parser* parser,
                        const IR::BFN::ParserState* state,
                        unsigned id,
                        std::vector<const IR::BFN::ParserChecksumPrimitive*>& checksums) {
        auto last = checksums.back();
        cstring declName = last->declName;

        bool start = false;
        if (checksumAlloc.declToStartStates.at(parser).at(declName).count(state))
            start = true;

        bool end = false;
        if (checksumAlloc.declToEndStates.at(parser).at(declName).count(state))
            end = true;

        auto type = IR::BFN::ChecksumMode::VERIFY;
        if (last->is<IR::BFN::ChecksumSubtract>() || last->is<IR::BFN::ChecksumGet>())
            type = IR::BFN::ChecksumMode::RESIDUAL;

        const IR::BFN::FieldLVal* dest = nullptr;
        std::vector<nw_byterange> masked_ranges;

        for (auto c : checksums) {
            if (auto add = c->to<IR::BFN::ChecksumAdd>()) {
                if (auto v = add->source->to<IR::BFN::PacketRVal>())
                    masked_ranges.push_back(v->range().toUnit<RangeUnit::Byte>());
            } else if (auto sub = c->to<IR::BFN::ChecksumSubtract>()) {
                if (auto v = sub->source->to<IR::BFN::PacketRVal>())
                    masked_ranges.push_back(v->range().toUnit<RangeUnit::Byte>());
            } else if (auto verify = c->to<IR::BFN::ChecksumVerify>()) {
                dest = verify->dest;
            } else if (auto get = c->to<IR::BFN::ChecksumGet>()) {
                dest = get->dest;
            }
        }

        auto csum = new IR::BFN::LoweredParserChecksum(
            id, masked_ranges, 0x0, start, end, type);

        std::vector<alloc_slice> slices;
        if (dest) {
            slices = phv.get_alloc(dest->field);
            BUG_CHECK(slices.size() == 1, "checksum error %1% is somehow allocated to "
               "multiple containers?", dest->field);
        }

        if (type == IR::BFN::ChecksumMode::VERIFY && dest) {
            if (auto sl = dest->field->to<IR::Slice>()) {
                BUG_CHECK(sl->getL() == sl->getH(), "checksum error must write to single bit");
                csum->csum_err = new IR::BFN::ContainerBitRef(
                                     new IR::BFN::ContainerRef(slices.back().container),
                                     (unsigned)sl->getL());
            } else {
                csum->csum_err = lowerPovBit(phv, dest);
            }
        } else if (type == IR::BFN::ChecksumMode::RESIDUAL && dest) {
            csum->phv_dest = new IR::BFN::ContainerRef(slices.back().container);
        }

        return csum;
    }

    void postorder(const IR::BFN::ParserState* state) override {
        LOG4("[ComputeLoweredParserIR] lowering state " << state->name);
        BUG_CHECK(loweredStates.find(state) == loweredStates.end(),
                  "Revisiting state %1%, but we already lowered it?",
                  state->name);

        auto* loweredState =
          new IR::BFN::LoweredParserState(sanitizeName(state->name), state->gress);

        // Report the original state name in the debug info, and merge in any
        // debug information it had.
        loweredState->debug.info.push_back("from state " + state->name);
        loweredState->debug.mergeWith(state->debug);

        std::vector<const IR::BFN::ParserChecksumPrimitive*> checksums;
        const IR::BFN::ParserPrioritySet* priority = nullptr;

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier(phv, clotInfo);
        forAllMatching<IR::BFN::ParserPrimitive>(&state->statements,
                      [&](const IR::BFN::ParserPrimitive* prim) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract);
            } else if (auto* csum = prim->to<IR::BFN::ParserChecksumPrimitive>()) {
                checksums.push_back(csum);
            } else if (auto* prio = prim->to<IR::BFN::ParserPrioritySet>()) {
                priority = prio;
            } else {
                // Report other kinds of parser primitives, which we currently can't
                // handle, in the debug info.
                loweredState->debug.info.push_back("unhandled: " +
                                               cstring::to_cstring(prim));
            }
        });

        auto loweredStatements = simplifier.lowerExtracts();

        auto parser = findContext<IR::BFN::Parser>();
        auto loweredChecksums = lowerParserChecksums(parser, state, checksums);

        // populate container range in clot info

        for (auto stmt : loweredStatements) {
            if (auto extract = stmt->to<IR::BFN::LoweredExtractPhv>()) {
                if (auto* source = extract->source->to<IR::BFN::LoweredInputBufferRVal>()) {
                    auto bytes = source->extractedBytes();
                    auto container = extract->dest->container;
                    clotInfo.container_range()[state->name][container] = bytes;
                }
            }
        }

        /// Convert multiple select into one.
        auto* loweredSelect = new IR::BFN::LoweredSelect();
        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            // Load match register from previous result.
            BUG_CHECK(select->reg_slices.size() > 0, "Match register not allocated.");
            for (auto rs : select->reg_slices)
                loweredSelect->regs.insert(rs.first);

            if (auto* bufferSource = select->source->to<IR::BFN::InputBufferRVal>()) {
                const auto bufferRange =
                    bufferSource->range().toUnit<RangeUnit::Byte>();
                loweredSelect->debug.info.push_back(debugInfoFor(select, bufferRange)); }
            return;
        });
        loweredState->select = loweredSelect;

        for (auto* transition : state->transitions) {
            BUG_CHECK(transition->shift, "State %1% has unset shift?", state->name);
            BUG_CHECK(*transition->shift >= 0, "State %1% has negative shift %2%?",
                                               state->name, *transition->shift);
            BUG_CHECK(loweredStates.find(transition->next) != loweredStates.end(),
                      "Didn't already lower state %1%?",
                      transition->next ? transition->next->name : cstring("(null)"));
            IR::Vector<IR::BFN::LoweredSave> saves;
            for (const auto* save : transition->saves) {
                saves.push_back(
                    new IR::BFN::LoweredSave(
                            save->dest,
                            save->source->range().toUnit<RangeUnit::Byte>()));
            }
            IR::BFN::LoweredMatchValue* match_value = nullptr;
            if (auto* const_value = transition->value->to<IR::BFN::ParserConstMatchValue>()) {
                match_value = new IR::BFN::LoweredConstMatchValue(const_value->value);
            } else if (auto* pvs = transition->value->to<IR::BFN::ParserPvsMatchValue>()) {
                match_value =
                    new IR::BFN::LoweredPvsMatchValue(pvs->name, pvs->size, pvs->mapping);
            } else {
                BUG("Unknown match value %1%", transition->value);
            }
            auto* loweredMatch = new IR::BFN::LoweredParserMatch(
                    match_value,
                    *transition->shift,
                    loweredStatements,
                    saves,
                    loweredChecksums,
                    priority,
                    loweredStates[transition->next]);
            loweredState->transitions.push_back(loweredMatch);
        }

        // Now that we've constructed a lowered version of this state, save it
        // so that we can link its predecessors to it. (Which, transitively,
        // will eventually stitch the entire graph of lowered states together.)
        loweredStates[state] = loweredState;
    }

    const PhvInfo& phv;
    ClotInfo& clotInfo;
    const AllocateParserChecksumUnits& checksumAlloc;
};

/// Replace the high-level parser IR version of each parser's root node with its
/// lowered version. This has the effect of replacing the entire parse graph.
struct ReplaceParserIR : public Transform {
    explicit ReplaceParserIR(const ComputeLoweredParserIR& computed)
      : computed(computed) { }

 private:
    const IR::BFN::LoweredParser*
    preorder(IR::BFN::Parser* parser) override {
        BUG_CHECK(computed.loweredStates.find(parser->start) != computed.loweredStates.end(),
                  "Didn't lower the start state?");
        prune();

        auto* loweredParser =
          new IR::BFN::LoweredParser(parser->gress, computed.loweredStates.at(parser->start));

        // Record the amount of metadata which is prepended to the packet; this
        // is used to compensate so that e.g. counters record only bytes which
        // are part of the "real" packet. On egress, it may vary according to
        // the EPB configuration, which is determined by which fields are used
        // in the program.
        // XXX(seth): We just use a default EPB configuration for now.
        if (parser->gress == INGRESS) {
            loweredParser->prePacketDataLengthBytes =
              Device::pardeSpec().byteTotalIngressMetadataSize();
        } else {
            const auto epbConfig = Device::pardeSpec().defaultEPBConfig();
            loweredParser->epbConfig = epbConfig;
            loweredParser->prePacketDataLengthBytes =
              Device::pardeSpec().byteEgressMetadataSize(epbConfig);
        }

        if (parser->gress == INGRESS && computed.igParserError)
            loweredParser->parserError = computed.igParserError;
        else if (parser->gress == EGRESS && computed.egParserError)
            loweredParser->parserError = computed.egParserError;

        return loweredParser;
    }

    const ComputeLoweredParserIR& computed;
};

class ResolveParserConstants : public ParserTransform {
    const PhvInfo& phv;
    const ClotInfo& clotInfo;

    IR::BFN::ConstantRVal* preorder(IR::BFN::TotalContainerSize* tcs) override {
        IR::Vector<IR::BFN::ContainerRef> containers;
        std::vector<Clot> clots;

        std::tie(containers, clots) = lowerFields(phv, clotInfo, tcs->fields);

        BUG_CHECK(clots.empty(), "Fields allocated to CLOT?");

        std::map<PHV::Container, std::set<unsigned>> containerBytes;

        for (auto cr : containers) {
            unsigned loByte = 0, hiByte = cr->container.size() / 8;

            if (cr->range) {
                auto range = *(cr->range);
                loByte = range.lo / 8;
                hiByte = range.hi / 8;
            }

            for (unsigned i = loByte; i <= hiByte; i++) {
                containerBytes[cr->container].insert(i);
            }
        }

        unsigned totalBytes = 0;

        for (auto cb : containerBytes)
            totalBytes += cb.second.size();

        auto state = findContext<IR::BFN::ParserState>();
        if (state && state->name.startsWith("$mirror_field_list_")) {
            totalBytes += 4;  // offset 4 bytes of CRC added by HW for mirrored packet
        }

        auto rv = new IR::BFN::ConstantRVal(totalBytes);
        return rv;
    }

 public:
    ResolveParserConstants(const PhvInfo& phv, const ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) { }
};

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerParserIR : public PassManager {
    explicit LowerParserIR(const PhvInfo& phv, ClotInfo& clotInfo) {
        auto* checksumAllocation = new AllocateParserChecksumUnits;
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(phv, clotInfo,
                                                                  *checksumAllocation);
        addPasses({
            LOGGING(3) ? new DumpParser("before_parser_lowering") : nullptr,
            checksumAllocation,
            new ResolveParserConstants(phv, clotInfo),
            computeLoweredParserIR,
            new ReplaceParserIR(*computeLoweredParserIR),
            LOGGING(3) ? new DumpParser("after_parser_lowering") : nullptr
        });
    }
};

/// Given a sequence of fields, construct a packing format describing how the
/// fields will be laid out once they're lowered to containers.
/// XXX(seth): If this were a permanent thing, it'd probably be better to
/// integrate it into `lowerFields()` and put a bit more care into it, but we
/// know that we're going to move this functionality to `extract_maupipe()`
/// pretty soon when we switch to the TNA-style learning extern. This is just a
/// short term hack to let us survive until then.
const BFN::FieldPacking*
computeControlPlaneFormat(const PhvInfo& phv,
                          const IR::Vector<IR::BFN::FieldLVal>& fields) {
    struct LastContainerInfo {
        /// The container into which the last field was placed.
        PHV::Container container;
        /// The number of unused bits which remain on the LSB side of the
        /// container after the last field was placed.
        int remainingBitsInContainer;
    };

    boost::optional<LastContainerInfo> last;
    auto* packing = new BFN::FieldPacking;


    // Walk over the field sequence in network order and construct a
    // FieldPacking that reflects its structure, with padding added where
    // necessary to reflect gaps between the fields.
    for (auto* fieldRef : fields) {
        std::vector<alloc_slice> slices = phv.get_alloc(fieldRef->field);

        BUG_CHECK(!slices.empty(),
                  "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        // Confusingly, the first slice in network order is the *last* one in
        // `slices` because `foreach_alloc()` (and hence `get_alloc()`)
        // enumerates the slices in increasing order of their little endian
        // offset, which means that in terms of network order it walks the
        // slices backwards.
        auto& firstSlice = slices.back();
        const nw_bitrange firstContainerRange = firstSlice.container_bits()
          .toOrder<Endian::Network>(firstSlice.container.size());

        // If we switched containers (or if this is the very first field),
        // appending padding equivalent to the bits at the end of the previous
        // container and the beginning of the new container that aren't
        // occupied.
        if (last && last->container != firstSlice.container) {
            packing->appendPadding(last->remainingBitsInContainer);
            packing->appendPadding(firstContainerRange.lo);
        } else if (!last) {
            packing->appendPadding(firstContainerRange.lo);
        }

        // Place the entire field at once. We're assuming it was allocated
        // contiguously, obviously; ValidateAllocation will have complained if
        // it wasn't.  The field name is used in assembly generation; hence,
        // we use its external name.
        packing->appendField(fieldRef->field, firstSlice.field->externalName(),
                             firstSlice.field->size);

        // Remember information about the container placement of the last slice
        // in network order (the first one in `slices`) so we can add any
        // necessary padding on the next pass around the loop.
        auto& lastSlice = slices.front();
        last = LastContainerInfo{lastSlice.container,
                                 lastSlice.container_bits().lo};
    }

    return packing;
}

struct RewriteEmitClot : public DeparserModifier {
    RewriteEmitClot(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    bool preorder(IR::BFN::Deparser* deparser) override {
        // replace Emits covered in a CLOT with EmitClot

        IR::Vector<IR::BFN::Emit> newEmits;

        Clot* last = nullptr;

        for (auto emit : deparser->emits) {
           auto povBit = emit->povBit;

           const IR::Expression* source = nullptr;

           if (auto ef = emit->to<IR::BFN::EmitField>())
               source = ef->source->field;
           else if (auto ec = emit->to<IR::BFN::EmitChecksum>())
               source = ec->dest->field;

           BUG_CHECK(source, "No emit source?");

           auto field = phv.field(source);

           if (auto c = clotInfo.clot(field)) {
               if (auto emit_csum = emit->to<IR::BFN::EmitChecksum>())
                   clotInfo.clot_to_emit_checksum()[c] = emit_csum;

               if (c != last) {
                   auto clotEmit = new IR::BFN::EmitClot(povBit);
                   clotEmit->clot = c;
                   newEmits.pushBackOrAppend(clotEmit);
               }

               last = const_cast<Clot*>(c);

               continue;
           }

           newEmits.pushBackOrAppend(emit);
        }

        deparser->emits = newEmits;
        return false;
    }

    const PhvInfo& phv;
    ClotInfo& clotInfo;
};

struct AllocateParserClotChecksums : public PassManager {
    struct CollectClotChecksumFields : public DeparserInspector {
        CollectClotChecksumFields(const PhvInfo& phv, const ClotInfo& clotInfo) :
            phv(phv), clotInfo(clotInfo) {}

        bool preorder(const IR::BFN::Deparser* deparser) override {
            // look for clot fields in deparser checksums

            for (auto emit : deparser->emits) {
                if (auto csum = emit->to<IR::BFN::EmitChecksum>()) {
                    for (auto source : csum->sources) {
                        auto field = phv.field(source->field);
                        if (auto* clot = clotInfo.allocated(field)) {
                            clot_checksum_fields[clot].push_back(field);
                        }
                    }
                }
            }

            return false;
        }

        std::map<const Clot*, std::vector<const PHV::Field*>> clot_checksum_fields;

        const PhvInfo& phv;
        const ClotInfo& clotInfo;
    };

    struct InsertParserClotChecksums : public ParserModifier {
        struct GetCurrentChecksumId : public ParserInspector {
            unsigned current_id = 0;

            bool preorder(const IR::BFN::LoweredParserChecksum* csum) override {
                current_id = std::max(current_id, csum->unit_id);
                return false;
            }
        };

        explicit InsertParserClotChecksums(const PhvInfo& phv,
            const std::map<const Clot*, std::vector<const PHV::Field*>>& fields) :
                phv(phv), clot_checksum_fields(fields) { }

        std::vector<nw_byterange>
        generateByteMask(const std::vector<const PHV::Field*>& clot_csum_fields,
                         const IR::BFN::LoweredExtractClot* ec) {
            std::vector<nw_byterange> ranges;
            unsigned clot_start_byte = ec->dest.start;

            for (auto f : clot_csum_fields) {
                unsigned offset = ec->dest.offset(f);
                int sz = (f->size + 7) / 8;
                ranges.emplace_back(StartLen(clot_start_byte + offset, sz));
            }

            return ranges;
        }

        IR::BFN::LoweredParserChecksum*
        createClotChecksum(unsigned id,
                           const std::vector<nw_byterange>& mask,
                           const Clot& clot) {
            auto csum = new IR::BFN::LoweredParserChecksum(
                    id, mask, 0x0, true, true, IR::BFN::ChecksumMode::CLOT);
            csum->clot_dest = clot;
            return csum;
        }

        bool preorder(IR::BFN::LoweredParser* p) override {
            GetCurrentChecksumId gid;
            p->apply(gid);
            curr_id = std::max(0x2u, gid.current_id);  // clot can only use checksum engine 2-4
            return true;
        }

        bool preorder(IR::BFN::LoweredParserState*) override {
            allocated_in_state = 0;
            return true;
        }

        void postorder(IR::BFN::LoweredParserState*) override {
            curr_id += allocated_in_state;
            allocated_in_state = 0;
        }

        bool preorder(IR::BFN::LoweredParserMatch* match) override {
            unsigned id = curr_id;
            unsigned allocated = 0;
            for (auto p : match->statements) {
                if (auto ec = p->to<IR::BFN::LoweredExtractClot>()) {
                    for (auto c : clot_checksum_fields) {
                        if (c.first->tag == ec->dest.tag) {
                            auto mask = generateByteMask(c.second, ec);
                            auto* csum = createClotChecksum(id, mask, ec->dest);
                            match->checksums.push_back(csum);
                            allocated++;
                        }
                    }
                }
            }
            allocated_in_state = std::max(allocated_in_state, allocated);
            return true;
        }

        unsigned curr_id = 2;
        unsigned allocated_in_state = 0;

        const PhvInfo& phv;
        const std::map<const Clot*, std::vector<const PHV::Field*>>& clot_checksum_fields;
    };

    AllocateParserClotChecksums(const PhvInfo& phv, const ClotInfo& clot) {
        auto* collectClotChecksumFields = new CollectClotChecksumFields(phv, clot);
        addPasses({
            collectClotChecksumFields,
            new InsertParserClotChecksums(phv, collectClotChecksumFields->clot_checksum_fields)
        });
    }
};

/// Generate the lowered deparser IR by splitting references to fields in the
/// high-level deparser IR into references to containers.
struct ComputeLoweredDeparserIR : public DeparserInspector {
    ComputeLoweredDeparserIR(const PhvInfo& phv, const ClotInfo& clotInfo)
      : phv(phv), clotInfo(clotInfo), nextChecksumUnit(0) {
        igLoweredDeparser = new IR::BFN::LoweredDeparser(INGRESS);
        egLoweredDeparser = new IR::BFN::LoweredDeparser(EGRESS);
    }

    /// The lowered deparser IR generated by this pass.
    IR::BFN::LoweredDeparser* igLoweredDeparser;
    IR::BFN::LoweredDeparser* egLoweredDeparser;

 private:
    IR::BFN::ChecksumUnitConfig*
    lowerChecksum(const IR::BFN::EmitChecksum* emitChecksum) {
        // Allocate a checksum unit and generate the configuration for it.
        auto* unitConfig = new IR::BFN::ChecksumUnitConfig(nextChecksumUnit);

        IR::Vector<IR::BFN::ContainerRef> phvSources;
        std::vector<Clot> clotSources;

        std::tie(phvSources, clotSources) =
            lowerFields(phv, clotInfo, emitChecksum->sources);

        auto* loweredPovBit = lowerPovBit(phv, emitChecksum->povBit);

        for (auto* source : phvSources) {
            auto* input = new IR::BFN::ChecksumPhvInput(source);
#if HAVE_JBAY
            if (Device::currentDevice() == Device::JBAY)
                input->povBit = loweredPovBit;
#endif
            unitConfig->phvs.push_back(input);
        }
#if HAVE_JBAY
        for (auto source : clotSources) {
            auto* input = new IR::BFN::ChecksumClotInput(source, loweredPovBit);
            unitConfig->clots.push_back(input);
        }
#endif
        return unitConfig;
    }

    bool preorder(const IR::BFN::Deparser* deparser) override {
        auto* loweredDeparser = deparser->gress == INGRESS ? igLoweredDeparser
                                                           : egLoweredDeparser;

        // Reset the next checksum unit if needed. On Tofino, each thread has
        // its own checksum units. On JBay they're shared, and their ids are
        // global, so on that device we don't reset the next checksum unit for
        // each deparser.
        if (Device::currentDevice() == Device::TOFINO)
            nextChecksumUnit = 0;

        struct LastSimpleEmitInfo {
            /// The `PHV::Field::id` of the POV bit for the last simple emit.
            int povFieldId;
            /// The actual range of bits (of size 1) corresponding to the POV
            /// bit for the last simple emit.
            le_bitrange povFieldBits;
        };

        boost::optional<LastSimpleEmitInfo> lastSimpleEmit;
        std::vector<std::vector<const IR::BFN::DeparserPrimitive*>> groupedEmits;

        // The deparser contains a sequence of emit-like primitives which we'd
        // like to lower to operate on containers. Each container may contain
        // several fields, so a number of emit primitives at the field level may
        // boil down to a single emit of a container. We need to be sure,
        // however, that we don't merge together emits for fields which are
        // controlled by different POV bits or are part of different CLOTs;
        // such fields are independent entities and we can't introduce a
        // dependency between them. For that reason, we start out by grouping
        // emit-like primitives by POV bit and CLOT tag.
        LOG5("Grouping deparser primitives:");
        for (auto* prim : deparser->emits) {
            // Some complex emit primitives exist which can't be merged with
            // other primitives. We place this kind of primitive in a group by
            // itself. (At this point, EmitChecksum is the only thing in this
            // category, but one can imagine that future hardware may introduce
            // others.)
            if (!prim->is<IR::BFN::EmitField>()) {
                if (prim->is<IR::BFN::EmitChecksum>()) {
                    LOG5(" - Placing complex emit in its own group: " << prim);
                    groupedEmits.emplace_back(1, prim);
#if HAVE_JBAY
                } else if (prim->is<IR::BFN::EmitClot>()) {
                    groupedEmits.emplace_back(1, prim);
#endif
                } else {
                    BUG("Found a complex emit of an unexpected type: %1%", prim);
                }

                lastSimpleEmit = boost::none;
                continue;
            }


            // Gather the POV bit and CLOT tag associated with this emit.
            auto* emit = prim->to<IR::BFN::EmitField>();
            auto* field = phv.field(emit->source->field);
            BUG_CHECK(field, "No allocation for emitted field: %1%", emit);
            le_bitrange povFieldBits;
            auto* povField = phv.field(emit->povBit->field, &povFieldBits);
            BUG_CHECK(povField, "No allocation for POV bit: %1%", emit);

            // Compare the POV bit and CLOT tag with the previous emit and
            // decide whether to place this emit in the same group or to start a
            // new group.
            if (!lastSimpleEmit || groupedEmits.empty()) {
                LOG5(" - Starting new emit group: " << emit);
                groupedEmits.emplace_back(1, emit);
            } else if (lastSimpleEmit->povFieldId == povField->id &&
                       lastSimpleEmit->povFieldBits == povFieldBits) {
                LOG5(" - Adding emit to group: " << emit);
                groupedEmits.back().push_back(emit);
            } else {
                LOG5(" - Starting new emit group: " << emit);
                groupedEmits.emplace_back(1, emit);
            }

            lastSimpleEmit = LastSimpleEmitInfo{povField->id, povFieldBits};
        }

        // Now we've partitioned the emit primitives into groups which can be
        // lowered independently. Walk over the groups and lower each one.
        for (auto& group : groupedEmits) {
            BUG_CHECK(!group.empty(), "Generated an empty emit group?");

            if (auto* emitClot = group.back()->to<IR::BFN::EmitClot>()) {
                auto* loweredEmitClot = new IR::BFN::LoweredEmitClot(emitClot);
                loweredDeparser->emits.push_back(loweredEmitClot);

                auto cl = emitClot->clot;
                if (clotInfo.clot_to_emit_checksum().count(cl)) {
                    // this emit checksum is part of a clot
                    auto emitChecksum = clotInfo.clot_to_emit_checksum().at(cl);
                    auto f = phv.field(emitChecksum->dest->field);
                    cl->csum_field_to_csum_id[f] = nextChecksumUnit;

                    auto unitConfig = lowerChecksum(emitChecksum);
                    loweredDeparser->checksums.push_back(unitConfig);

                    nextChecksumUnit++;
                }

                continue;
            }

            // If this is a checksum emit primitive, lower it.
            if (auto* emitChecksum = group.back()->to<IR::BFN::EmitChecksum>()) {
                BUG_CHECK(group.size() == 1,
                          "Checksum primitives should be in a singleton group");

                auto unitConfig = lowerChecksum(emitChecksum);
                loweredDeparser->checksums.push_back(unitConfig);

                // Generate the lowered checksum emit.
                auto* loweredPovBit = lowerPovBit(phv, emitChecksum->povBit);

                auto* loweredEmit =
                  new IR::BFN::LoweredEmitChecksum(loweredPovBit, nextChecksumUnit);

                loweredDeparser->emits.push_back(loweredEmit);

                nextChecksumUnit++;

                continue;
            }

            // This is a group of simple emit primitives. Pull out a
            // representative; all emits in the group will have the same POV bit
            // and CLOT tag.
            auto* emit = group.back()->to<IR::BFN::EmitField>();
            BUG_CHECK(emit, "Unexpected deparser primitive: %1%", group.back());

            // Gather the source fields for all of the emits.
            IR::Vector<IR::BFN::FieldLVal> sources;
            for (auto* memberEmit : group)
                sources.push_back(memberEmit->to<IR::BFN::EmitField>()->source);

            // Lower the source fields to containers and generate the new,
            // lowered emit primitives.
            IR::Vector<IR::BFN::ContainerRef> emitSources;
            std::tie(emitSources, std::ignore) = lowerFields(phv, clotInfo, sources);
            auto* loweredPovBit = lowerPovBit(phv, emit->povBit);
            for (auto* source : emitSources) {
                auto* loweredEmit = new IR::BFN::LoweredEmitPhv(loweredPovBit, source);
                loweredDeparser->emits.push_back(loweredEmit);
            }
        }

        // Lower deparser parameters from fields to containers.
        for (auto* param : deparser->params) {
            auto* loweredSource =
                lowerUnsplittableField(phv, clotInfo, param->source, "deparser parameter");
            auto* lowered = new IR::BFN::LoweredDeparserParameter(param->name,
                                                                  loweredSource);
            if (param->povBit)
                lowered->povBit = lowerPovBit(phv, param->povBit);
            loweredDeparser->params.push_back(lowered);
        }

        // Lower digests from fields to containers.
        for (auto& item : deparser->digests) {
            auto* digest = item.second;
            auto* loweredSelector =
                lowerUnsplittableField(phv, clotInfo, digest->selector, "digest selector");
            auto* lowered =
              new IR::BFN::LoweredDigest(digest->name, loweredSelector);

              if (digest->povBit)
                  lowered->povBit = lowerPovBit(phv, digest->povBit);

            // Each field list, when lowered, becomes a digest table entry.
            // Learning field lists are used to generate the format for learn
            // quanta, which are exposed to the control plane, so they have a
            // bit more metadata than other kinds of digests.
            for (auto fieldList : digest->fieldLists) {
                IR::Vector<IR::BFN::ContainerRef> phvSources;
                std::vector<Clot> clotSources;

                std::tie(phvSources, clotSources) =
                    lowerFields(phv, clotInfo, fieldList->sources);

                BUG_CHECK(clotSources.empty(), "digest data cannot be sourced from CLOT");

                IR::BFN::DigestTableEntry* entry = nullptr;

                if (digest->name == "learning") {
                    auto* controlPlaneFormat =
                      computeControlPlaneFormat(phv, fieldList->sources);
                    entry = new IR::BFN::LearningTableEntry(fieldList->idx,
                                                            phvSources,
                                                            fieldList->controlPlaneName,
                                                            controlPlaneFormat);
                } else {
                    entry = new IR::BFN::DigestTableEntry(fieldList->idx, phvSources);
                }
                lowered->entries.push_back(entry);
            }

            loweredDeparser->digests.push_back(lowered);
        }

        return false;
    }

    const PhvInfo& phv;
    const ClotInfo& clotInfo;
    unsigned nextChecksumUnit;
};

/// Replace the high-level deparser IR version of each deparser with the lowered
/// version generated by ComputeLoweredDeparserIR.
struct ReplaceDeparserIR : public DeparserTransform {
    ReplaceDeparserIR(const IR::BFN::LoweredDeparser* igLoweredDeparser,
                      const IR::BFN::LoweredDeparser* egLoweredDeparser)
      : igLoweredDeparser(igLoweredDeparser),
        egLoweredDeparser(egLoweredDeparser) { }

 private:
    const IR::BFN::LoweredDeparser*
    preorder(IR::BFN::Deparser* deparser) override {
        prune();
        return deparser->gress == INGRESS ? igLoweredDeparser : egLoweredDeparser;
    }

    const IR::BFN::LoweredDeparser* igLoweredDeparser;
    const IR::BFN::LoweredDeparser* egLoweredDeparser;
};

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerDeparserIR : public PassManager {
    LowerDeparserIR(const PhvInfo& phv, ClotInfo& clot) {
        auto* rewriteEmitClot = new RewriteEmitClot(phv, clot);
        auto* computeLoweredDeparserIR = new ComputeLoweredDeparserIR(phv, clot);
        addPasses({
            new AllocateParserClotChecksums(phv, clot),
            rewriteEmitClot,
            computeLoweredDeparserIR,
            new ReplaceDeparserIR(computeLoweredDeparserIR->igLoweredDeparser,
                                  computeLoweredDeparserIR->egLoweredDeparser)
        });
    }
};

// Utils for splitting states.

/// Shift all input packet extracts in the sequence to the left by the given
/// amount. Works for both ExtractPhv and ExtractClot
/// The coordinate system:
/// [0............31]
/// left..........right
template<class T>
T*
leftShiftExtract(T* primitive, int byteDelta) {
    const IR::BFN::LoweredPacketRVal* bufferSource =
        primitive->source->template to<typename IR::BFN::LoweredPacketRVal>();

    // Do not need to shift it's not packetRval
    if (!bufferSource) return primitive;

    auto shiftedRange = bufferSource->range.shiftedByBytes(-byteDelta);
    BUG_CHECK(shiftedRange.lo >= 0, "Shifting extract to negative position.");
    auto* clone = primitive->clone();
    clone->source = new IR::BFN::LoweredPacketRVal(shiftedRange);
    return clone;
}

/// Shift all input packet extracts in the sequence to the left by the given
/// amount.
const IR::BFN::LoweredSave*
leftShiftSave(const IR::BFN::LoweredSave* save, int byteDelta) {
    auto* bufferSource = save->source;
    auto shiftedRange = bufferSource->range.shiftedByBytes(-byteDelta);
    BUG_CHECK(shiftedRange.lo >= 0, "Shifting save to negative position.");
    auto* clone = save->clone();
    clone->source = new IR::BFN::LoweredPacketRVal(shiftedRange);
    return clone;
}



/// Allocate sequences of parser primitives to one or more states while
/// satisfying hardware constraints on the number of extractors available in a
/// state.
/// The idea is that, ExtractorAllocator will try to allocate extractor as much
/// as possible for each state, and it will includes saves in that state as long as
/// it is inside the input buffer. However, if the saves is trying to save something
/// more than the input buffer size, and we can not shift input buffer more, those
/// saves will be left for next state. This class will not do something like pulling extracts
/// from next state, those should be done by state merging.
class ExtractorAllocator {
 public:
    /** A group of primitives that needs to be executed when match happens.
     * Used by the allocator to split a big state.
     */
    struct MatchPrimitives {
        MatchPrimitives() { }
        MatchPrimitives(const IR::Vector<IR::BFN::LoweredParserPrimitive>& ext,
                        const IR::Vector<IR::BFN::LoweredParserChecksum>& chk,
                        const IR::Vector<IR::BFN::LoweredSave>& sa,
                        int sft)
            : extracts(ext), checksums(chk), saves(sa), shift(sft) { }

        IR::Vector<IR::BFN::LoweredParserPrimitive> extracts;
        IR::Vector<IR::BFN::LoweredParserChecksum> checksums;
        IR::Vector<IR::BFN::LoweredSave> saves;
        int shift;
    };

    /**
     * Create a new extractor allocator.
     *
     * @param stateName  The name of the parser state we're allocating for.
     * @param match      The match expression to split.
     *
     */
    ExtractorAllocator(cstring stateName, const IR::BFN::LoweredParserMatch* m)
        : stateName(stateName), shift_required(m->shift),
          match(m), shifted(0), current_input_buffer() {
        for (auto* stmt : match->statements)
            if (auto* e = stmt->to<IR::BFN::LoweredExtractPhv>())
                extractPhvs.push_back(e);
            else if (auto* e = stmt->to<IR::BFN::LoweredExtractClot>())
                extractClots.push_back(e);
            else
                ::warning("Splitting State ignores unsupported primitive: %1%", stmt);

        // adding checksums.
        for (auto* prim : match->checksums) {
            if (auto* cks = prim->to<IR::BFN::LoweredParserChecksum>()) {
                checksums.push_back(cks);
            }
        }

        // adding saves
        for (auto* save : match->saves)
            saves.push_back(save);

        // Sort the extract primitives by position in the input packet.
        std::sort(extractPhvs.begin(), extractPhvs.end(), isExtractPhvEarlierInPacket);
        std::sort(extractClots.begin(), extractClots.end(), isExtractClotEarlierInPacket);
    }

    /// @return true if we haven't allocated everything yet.
    bool hasMore() const {
        if (!extractPhvs.empty() || !extractClots.empty()) {
            return true;
        } else if (shift_required - shifted > 0) {
            return true;
        } else if (!saves.empty() && !hasOutOfBufferSaves()) {
            return true;
        } else {
            return false;
        }
    }

    /// @return ture if we have saves that must be done in the next state.
    bool hasOutOfBufferSaves() const {
        for (const auto& save : saves) {
            if (save->source->range.hiByte() > Device::pardeSpec().byteInputBufferSize() - 1)
                return true;
        }
        return false;
    }

    /// @return all remaining saves.
    const std::vector<const IR::BFN::LoweredSave*>& getRemainingSaves() const {
        return saves; }

    /// @return the number of extractors that is needed to set @p value.
    /// TODO(yumin): Tail..Head case is not considered here.
    size_t extractConstModel(uint32_t value, uint32_t n_set_range) {
        size_t n_needed = 0;
        while (value) {
            if (value & 1) {
                n_needed++;
                value >>= n_set_range;
            } else {
                value >>= 1; } }
        return n_needed;
    }

    /** @return the minimal extractor needed to extrat this value by using @p sz extractor.
     *  Extracting constant to phv is different from extracting from input buffer.
     *    For 8-bit extractor, we can set any bit.
     *    For 16-bit extractor, we can set any consequent 4 bits, using 4 bits as shifting.
     *    For 32-bit extractor, we can set any consequent 3 bits, using 5 bits as shifting.
     */
    size_t extractConstBy(uint32_t value, PHV::Size sz) {
        if (sz == PHV::Size::b8) {
            return extractConstModel(value, 8);
        } else if (sz == PHV::Size::b16) {
            return extractConstModel(value, 4);
        } else if (sz == PHV::Size::b32) {
            return extractConstModel(value, 3);
        } else {
            BUG("unexpected container size: %1%", sz);
            return 0;
        }
    }

    std::pair<size_t, unsigned>
    calcConstantExtractorUses(uint32_t value, size_t container_size) {
        for (const auto sz : { PHV::Size::b32, PHV::Size::b16, PHV::Size::b8}) {
            // can not use larger extractor on smaller container;
            if (container_size < size_t(sz)) {
                continue; }

            size_t n = extractConstBy(value, sz);
            if (container_size == size_t(sz) && n > 1) {
                continue;
            } else {
                if (n > container_size / unsigned(sz)) {
                    continue; }
                return {size_t(sz), container_size / unsigned(sz)}; }
        }
        BUG("Impossible constant value write in parser: %1%", value);
    }

    struct SplitExtractResult {
        // Splitted out Primitives
        IR::Vector<IR::BFN::LoweredParserPrimitive>     allocatedExtracts;
        // Rest Primitives;
        std::vector<const IR::BFN::LoweredExtractPhv*>  remainingPhvExtracts;
        std::vector<const IR::BFN::LoweredExtractClot*> remainingClotExtracts;
        // Useful statics of result.
        nw_byteinterval remainingBytes;
        nw_byteinterval extractedInterval;
    };

    struct SplitChecksumResult {
        IR::Vector<IR::BFN::LoweredParserChecksum>          allocatedChecksums;
        std::vector<const IR::BFN::LoweredParserChecksum*>  remainingChecksums;
    };

    struct SplitSaveResult {
        IR::Vector<IR::BFN::LoweredSave>                allocatedSaves;
        std::vector<const IR::BFN::LoweredSave*>        remainingSaves;
    };

    /// Allocate saves as long as the source of save is inside the input buffer.
    /// Note that input buffer required bytes are calculated by assembler, so
    /// it does not matter even if save source is not inside the extracted bytes.
    /// Also, save source does not need to update neither remainingBytes nor
    /// extractedBytes, it does not affect actual shift byte.
    SplitSaveResult allocSaves(const std::vector<const IR::BFN::LoweredSave*>& saves) {
        SplitSaveResult rst;
        for (auto* save : saves) {
            const auto& source = save->source->byteInterval();
            if (source.hiByte() > Device::pardeSpec().byteInputBufferSize() - 1)
                rst.remainingSaves.push_back(save);
            else
                rst.allocatedSaves.push_back(save);
        }
        return rst;
    }

    /// Split out a set of primitives that can be done in one state, limited by
    /// bandwidth and buffer size. Remaining extracts are returned as
    /// well, along with the interval of remaining bytes and interval extracted
    /// bytes. Side-effect free.
    SplitExtractResult splitOneByBandwidth(
            const std::vector<const IR::BFN::LoweredExtractPhv*>& extractPhvs,
            const std::vector<const IR::BFN::LoweredExtractClot*>& extractClots,
            const IR::Vector<IR::BFN::LoweredParserChecksum>& checksums) {
        SplitExtractResult rst;
        auto& pardeSpec = Device::pardeSpec();
        int inputBufferLastByte = pardeSpec.byteInputBufferSize() - 1;
        // Allocate a limited number of extractions of each size per
        // state. We also ensure that we don't overflow the input buffer.

        std::map<size_t, unsigned> allocatedExtractorsBySize;

        // reserve extractor for checksum verification.
        for (auto* cks : checksums) {
            if (cks->type == IR::BFN::ChecksumMode::VERIFY && cks->csum_err) {
                auto extractor_size = cks->csum_err->container->container.size();
                BUG_CHECK(extractor_size != 32,
                  "Checksum verification cannot write to 32-bit container");
#if HAVE_JBAY
                if (Device::currentDevice() == Device::JBAY)
                    extractor_size = 16;  // JBay has one size, 16-bit extractors
#endif  // HAVE_JBAY
                allocatedExtractorsBySize[extractor_size]++;
            }
        }

        for (auto* extract : extractPhvs) {
            if (!extract->dest)
                continue;

            nw_byteinterval byteInterval;
            size_t extractor_size = 0;
            unsigned n_extractor_used = 1;
            if (auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>()) {
                extractor_size = extract->dest->container.size();
                n_extractor_used = 1;
                byteInterval = source->byteInterval();
            } else if (extract->source->is<IR::BFN::LoweredMetadataRVal>()) {
                extractor_size = extract->dest->container.size();
                n_extractor_used = 1;
            } else if (auto* cons = extract->source->to<IR::BFN::LoweredConstantRVal>()) {
                int container_size = extract->dest->container.size();
                int value = cons->constant;
                std::tie(extractor_size, n_extractor_used) =
                    calcConstantExtractorUses(value, container_size);
            } else {
                BUG("Extract to unknown source: %1%", extract);
            }

#if HAVE_JBAY
            if (Device::currentDevice() == Device::JBAY) {
                if (extractor_size == 32)
                    n_extractor_used++;
                extractor_size = 16;  // JBay has one size, 16-bit extractors
                // TODO(zma) we could pack two 8-bit extract into a single 16-bit extract
            }
#endif  // HAVE_JBAY

            bool extractorsAvail = true;
            if (n_extractor_used &&
                allocatedExtractorsBySize[extractor_size] + n_extractor_used >
                pardeSpec.extractorSpec().at(extractor_size)) {
                extractorsAvail = false; }

            if (!extractorsAvail || byteInterval.hiByte() > inputBufferLastByte) {
                rst.remainingPhvExtracts.push_back(extract);
                rst.remainingBytes = rst.remainingBytes.unionWith(byteInterval);
                continue;
            }
            rst.extractedInterval |= byteInterval;

            allocatedExtractorsBySize[extract->dest->container.size()] += n_extractor_used;
            rst.allocatedExtracts.push_back(extract);
        }

#if HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            for (auto* extract : extractClots) {
                const auto byteInterval = extract->source->is<IR::BFN::LoweredPacketRVal>()
                    ? extract->source->to<IR::BFN::LoweredPacketRVal>()->byteInterval()
                    : nw_byteinterval();

                if (byteInterval.loByte() > inputBufferLastByte &&
                    byteInterval.hiByte() > inputBufferLastByte) {
                    rst.remainingClotExtracts.push_back(extract);
                    rst.remainingBytes = rst.remainingBytes.unionWith(byteInterval);
                    continue;
                }

                if (byteInterval.hiByte() > inputBufferLastByte) {
                    nw_byteinterval remain(pardeSpec.byteInputBufferSize(), byteInterval.hi);
                    auto rval = new IR::BFN::LoweredPacketRVal(*toClosedRange(remain));
                    rst.remainingPhvExtracts.push_back(new IR::BFN::LoweredExtractPhv(rval));
                    rst.remainingBytes = rst.remainingBytes.unionWith(remain);
                }

                rst.extractedInterval |= byteInterval;
                rst.allocatedExtracts.push_back(extract);
            }
        }
#endif  // HAVE_JBAY
        return rst;
    }

    /// Return checksums that can be done in this state.
    /// As long as all masked ranges are within input buffer, this checksum
    /// can be done in this state. We need this because we need to reserve extractors
    /// for those checksums.
    SplitChecksumResult
    allocCanBeDoneChecksums(
            const std::vector<const IR::BFN::LoweredParserChecksum*>& checksums) {
        SplitChecksumResult rst;
        for (const auto* cks : checksums) {
            bool can_be_done = std::all_of(cks->masked_ranges.begin(), cks->masked_ranges.end(),
                [&] (const nw_byterange& r) {
                    return r.hiByte() <= Device::pardeSpec().byteInputBufferSize() - 1;
                });
            if (can_be_done) {
                rst.allocatedChecksums.push_back(cks);
            } else {
                rst.remainingChecksums.push_back(cks);
            }
        }
        return rst;
    }

    /// return two checksum primitives that is generated from splitting @p cks.
    /// The first one is the former part checksum unit, and the second part is the latter.
    /// XXX(yumin): the second part is already left shifted by @p shifted.
    static
    std::pair<const IR::BFN::LoweredParserChecksum*, const IR::BFN::LoweredParserChecksum*>
    splitChecksumAt(const IR::BFN::LoweredParserChecksum* cks, int shifted) {
        // shifted - 1 is the last byte allocated to the split state.
        int lastByte = shifted - 1;
        std::vector<nw_byterange> prev;
        std::vector<nw_byterange> post;
        for (const auto& range : cks->masked_ranges) {
            if (range.hiByte() <= lastByte) {
                prev.push_back(range);
            } else if (range.loByte() <= lastByte && range.hiByte() > lastByte) {
                prev.emplace_back(FromTo(range.loByte(), lastByte));
                post.emplace_back(FromTo(lastByte + 1, range.hiByte()));
            } else {
                post.emplace_back(range);
            }
        }

        // left shift all post range by shifted bytes.
        for (auto& r : post) {
            r = nw_byterange(FromTo(r.loByte() - shifted, r.hiByte() - shifted)); }

        auto* prev_cks = cks->clone();
        auto* post_cks = cks->clone();

        prev_cks->masked_ranges = prev;
        post_cks->masked_ranges = post;

        if (prev.empty())
            return {nullptr, post_cks};
        if (post.empty())
            return {prev_cks, nullptr};

        // if even/odd order changed, mark swap.
        if (shifted % 2 == 1) {
            post_cks->swap = (!cks->swap); }

        // start in first checksum.
        if (cks->start) {
            prev_cks->start = true;
            post_cks->start = false;
        }

        // end in the second checksum.
        if (cks->end) {
            prev_cks->end = false;
            post_cks->end = true;
        }

        return {prev_cks, post_cks};
    }

    /// Return checksum primitives that needs to be done if we decide to shift
    /// out @p shifted bytes in this state. Checksums will be splitted, and the
    /// remaining checksums are already left shifted by @p shifted bytes.
    SplitChecksumResult
    allocPartialChecksums(
            const std::vector<const IR::BFN::LoweredParserChecksum*>& checksums,
            int shifted) {
        SplitChecksumResult rst;
        for (const auto& cks : checksums) {
            auto splitted_cks = splitChecksumAt(cks, shifted);
            if (splitted_cks.first) {
                rst.allocatedChecksums.push_back(splitted_cks.first); }
            if (splitted_cks.second) {
                rst.remainingChecksums.push_back(splitted_cks.second); }
        }
        return rst;
    }


    /**
     * Allocate as many parser primitives as will fit into a single state,
     * respecting hardware limits.
     *
     * Keep calling this until hasMore() returns false.
     * After that, you should call getRemainingSaves() if there is, and
     * push them down to the next state to generate a data extractor state.
     *
     * @return a pair containing (1) the parser primitives that were allocated,
     * and (2) the shift that the new state should have.
     */
    MatchPrimitives allocateOneState() {
        auto checksum_rst_done = allocCanBeDoneChecksums(checksums);
        auto extract_rst = splitOneByBandwidth(extractPhvs, extractClots,
                                               checksum_rst_done.allocatedChecksums);
        auto save_rst = allocSaves(saves);

        // If there is no more extract, calculate the actual shift for this state.
        // If remaining save falls into 32 byte range, then it's fine. If it does not
        // We need a new state for it.
        current_input_buffer |= extract_rst.extractedInterval;
        int byteActualShift = 0;
        if (extract_rst.remainingPhvExtracts.empty()) {
            byteActualShift = std::min(shift_required - shifted,
                                       Device::pardeSpec().byteInputBufferSize());
        } else {
            // If no more remaining extractions, just shift out the whole input buffer,
            // otherwise, shift until the first byte of the remaining is at head.
            byteActualShift = extract_rst.remainingBytes.empty()
                ? current_input_buffer.hiByte() + 1
                : std::min(extract_rst.remainingBytes.loByte(),
                           Device::pardeSpec().byteInputBufferSize());
        }

        if (byteActualShift > shift_required)
            byteActualShift = shift_required;

        BUG_CHECK(byteActualShift >= 0,
                  "Computed invalid shift %1% when splitting state %2%",
                  byteActualShift, stateName);

        LOG4("Created split state for " << stateName << " with shift "
             << byteActualShift << ":");

        // For checksums that can not be done in this state, split them.
        auto checksum_rst_partial = allocPartialChecksums(
                checksum_rst_done.remainingChecksums, byteActualShift);

        // Merge checksums allocation results.
        SplitChecksumResult checksum_rst;
        checksum_rst.allocatedChecksums.append(checksum_rst_done.allocatedChecksums);
        checksum_rst.allocatedChecksums.append(checksum_rst_partial.allocatedChecksums);
        checksum_rst.remainingChecksums = checksum_rst_partial.remainingChecksums;

        // Shift up all the remaining extractions.
        extractPhvs.clear();
        for (auto* extract : extract_rst.remainingPhvExtracts)
            extractPhvs.push_back(leftShiftExtract(extract, byteActualShift));

        extractClots.clear();
        for (auto* extract : extract_rst.remainingClotExtracts)
            extractClots.push_back(leftShiftExtract(extract, byteActualShift));

        saves.clear();
        for (auto* save : save_rst.remainingSaves)
            saves.push_back(leftShiftSave(save, byteActualShift));

        // remaining checksums are already left shifted by allocPartialChecksums,
        // so it do not need left shift here.
        checksums.clear();
        for (auto* cks : checksum_rst.remainingChecksums)
            checksums.push_back(cks);

        current_input_buffer = nw_byteinterval(
                StartLen(0, current_input_buffer.hiByte() + 1 - byteActualShift));

        shifted += byteActualShift;
        return MatchPrimitives(extract_rst.allocatedExtracts,
                               checksum_rst.allocatedChecksums,
                               save_rst.allocatedSaves,
                               byteActualShift);
    }

 private:
    cstring stateName;
    const int shift_required;
    const IR::BFN::LoweredParserMatch* match;
    int shifted;
    std::vector<const IR::BFN::LoweredExtractPhv*> extractPhvs;
    std::vector<const IR::BFN::LoweredExtractClot*> extractClots;
    std::vector<const IR::BFN::LoweredParserChecksum*> checksums;
    std::vector<const IR::BFN::LoweredSave*> saves;
    nw_byteinterval current_input_buffer;
};

/// Split states into smaller states which can be executed in a single cycle by
/// the hardware.
class SplitBigStates : public ParserModifier {
 private:
    profile_t init_apply(const IR::Node* root) override {
        forAllMatching<IR::BFN::LoweredParserState>(root,
                      [&](const IR::BFN::LoweredParserState* state) {
            stateNames.insert(state->name);
        });

        return ParserModifier::init_apply(root);
    }

    /// return the buffer size of first state if all branch need to be splitted.
    /// Only in a rare case that only part of matches need to split, which is
    /// caused by that they have late-in-buffer save that has to be done in a new state.
    boost::optional<int> needSplitState(const IR::BFN::LoweredParserState* state) {
        bool allNeedSplitState = true;
        int firstStateShift = (std::numeric_limits<int>::max)();
        for (const auto* match : state->transitions) {
            ExtractorAllocator allocator(state->name, match);
            auto rst = allocator.allocateOneState();
            firstStateShift = std::min(rst.shift, firstStateShift);
            if (!allocator.hasMore()) {
                allNeedSplitState = false; }
        }
        if (allNeedSplitState) {
            return firstStateShift;
        } else {
            return boost::none;
        }
    }

    /// return the index in the input buffer that primitives are common, if null, then
    /// all are in common.
    unsigned
    calcEarliestConflict(const IR::BFN::LoweredParserState* state) {
        using IndexRegister = std::pair<unsigned, MatchRegister>;
        using SavedSet      = std::set<const IR::BFN::LoweredParserMatch*>;
        std::map<IndexRegister, SavedSet> save_map;

        unsigned earliest_conflict = (std::numeric_limits<unsigned>::max)();
        // Since we assume all extractions are the same, we just need to check saves.
        for (const auto* match : state->transitions) {
            for (const auto* save : match->saves) {
                auto range = save->source->extractedBytes();
                for (int i = range.loByte(); i <= range.hiByte(); ++i) {
                    save_map[std::make_pair(i, save->dest)].insert(match);
                } } }

        // Find the first location that not all matches save to the same register.
        for (const auto& kv : save_map) {
            if (kv.second.size() != state->transitions.size()) {
                earliest_conflict = std::min(earliest_conflict, kv.first.first);
            } }

        // Also the first shift, though they are likely to be the same.
        // This will catch the case when these is no save at all.
        for (const auto* match : state->transitions) {
            earliest_conflict = std::min(earliest_conflict, match->shift); }

        // Also the first save that might overwrite the match register used in this stage.
        for (const auto* match : state->transitions) {
            for (const auto* save : match->saves) {
                if (state->select->regs.count(save->dest)) {
                    auto range = save->source->extractedBytes();
                    BUG_CHECK(range.loByte() >= 0,
                              "negative range shoule be eliminated before, %1%", save);
                    earliest_conflict = std::min(earliest_conflict, unsigned(range.loByte()));
                }
            }
        }

        return earliest_conflict;
    }

    void
    addTailStatePrimitives(IR::BFN::LoweredParserState* tailState, int until) {
        IR::Vector<IR::BFN::LoweredParserMatch> matches;
        const auto& used_regs = tailState->select->regs;
        for (const auto* match : tailState->transitions) {
            std::vector<ExtractorAllocator::MatchPrimitives> tailStatePrimitives;
            std::vector<const IR::BFN::LoweredSave*> common_state_allocated_saves;
            int shifted = 0;  // shifted before tail state.

            // collect tail state primitives
            ExtractorAllocator allocator(tailState->name + "$SplitTailState", match);
            while (allocator.hasMore()) {
                auto rst = allocator.allocateOneState();
                // should be in the tail state.
                if (!allocator.hasMore() || shifted + rst.shift > until) {
                    if (shifted) {
                        tailStatePrimitives.push_back(rst);
                    } else {
                        shifted += rst.shift;
                    }
                } else {
                    // because allocateOneState will try to allocate saves as long as
                    // it is possible to be reached in the input buffer, saves might be
                    // allocated to previous common state but ignored by
                    // addCommonStatePrimitives because it is illegal to do in the common state
                    // due to out of input buffer or override match reg. So we need to carry
                    // them to the tail state.
                    for (const auto* save : rst.saves) {
                        auto* original_save = leftShiftSave(save, -shifted);
                        if (original_save->source->range.hiByte() >= until
                            || used_regs.count(save->dest)) {
                            common_state_allocated_saves.push_back(original_save); }
                    }
                    shifted += rst.shift;
                }
            }

            // create new match
            auto* truncatedMatch = match->clone();
            truncatedMatch->statements.clear();
            truncatedMatch->saves.clear();
            truncatedMatch->shift = match->shift - shifted;

            // add saves that were allocated to common state but should be in tail.
            for (auto* save : common_state_allocated_saves) {
                truncatedMatch->saves.push_back(leftShiftSave(save, shifted)); }

            // allocate checksums.
            truncatedMatch->checksums.clear();
            for (const auto* cks : match->checksums) {
                auto splitted_cks = ExtractorAllocator::splitChecksumAt(cks, shifted);
                if (splitted_cks.second) {
                    LOG4("Allocate checksum to tail state: " << splitted_cks.second);
                    truncatedMatch->checksums.push_back(splitted_cks.second);
                }
            }

            // add primitives to new match
            int accumulatedShift = 0;  // shifted in the tailed tail while crush it into one.
            for (const auto& primitives : tailStatePrimitives) {
                for (auto* prim : primitives.extracts) {
                    if (auto* extractPhv = prim->to<IR::BFN::LoweredExtractPhv>()) {
                        truncatedMatch->statements.push_back(
                                leftShiftExtract(extractPhv, -accumulatedShift));
                    } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                        truncatedMatch->statements.push_back(
                                leftShiftExtract(extractClot, -accumulatedShift));
                    } else {
                        BUG("unknown primitive when create tail state: %1%", prim);
                    }
                }
                for (auto* save : primitives.saves) {
                    truncatedMatch->saves.push_back(
                            leftShiftSave(save, -accumulatedShift)); }
                accumulatedShift += primitives.shift;
            }
            matches.push_back(truncatedMatch);
        }
        tailState->transitions = matches;
    }

    /// Set primitives in @p common, as its the only match of the common state.
    void
    addCommonStatePrimitives(IR::BFN::LoweredParserMatch* common,
                             const IR::BFN::LoweredParserState* sampleState,
                             int until) {
        const IR::BFN::LoweredParserMatch* sampleMatch = *(sampleState->transitions.begin());
        ExtractorAllocator allocator(sampleState->name + "$SplitCommonState", sampleMatch);
        const auto& used_reg = sampleState->select->regs;
        int shifted = 0;
        while (allocator.hasMore()) {
            auto rst = allocator.allocateOneState();
            // The tail primitives
            if (!allocator.hasMore() || rst.shift + shifted > until) {
                // if we break the while loop when 'shifted' is still zero, the input buffer
                // will not be shifted, and as a result, we ends up with an infinite loop
                // when splitting the big state to smaller state. This corner case happens
                // when compiling brig-747.p4
                if (!shifted) {
                    // Add primitives to common
                    for (auto* prim : rst.extracts) {
                        if (auto* extractPhv = prim->to<IR::BFN::LoweredExtractPhv>()) {
                            common->statements.push_back(
                                    leftShiftExtract(extractPhv, -shifted));
                        } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                            common->statements.push_back(
                                    leftShiftExtract(extractClot, -shifted));
                        } else {
                            BUG("unknown primitive when create common state: %1%", prim);
                        }
                    }
                    for (auto* save : rst.saves) {
                        // as long as this save is part of common part, and the dest
                        // of this save will not override match register that will be
                        // used in the tail select state.
                        if (save->source->range.hiByte() + shifted < until
                            && !used_reg.count(save->dest)) {
                            common->saves.push_back(leftShiftSave(save, -shifted));
                        }
                    }
                    shifted += rst.shift;
                }
                break;
            }

            // Add primitives to common
            for (auto* prim : rst.extracts) {
                if (auto* extractPhv = prim->to<IR::BFN::LoweredExtractPhv>()) {
                    common->statements.push_back(
                            leftShiftExtract(extractPhv, -shifted));
                } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                    common->statements.push_back(
                            leftShiftExtract(extractClot, -shifted));
                } else {
                    BUG("unknown primitive when create common state: %1%", prim);
                }
            }
            for (auto* save : rst.saves) {
                // as long as this save is part of common part, and the dest of this save
                // will not override match register that will be used in the tail select state.
                if (save->source->range.hiByte() + shifted < until
                    && !used_reg.count(save->dest)) {
                    common->saves.push_back(leftShiftSave(save, -shifted));
                }
            }
            shifted += rst.shift;
        }

        // allocate checksums.
        common->checksums.clear();
        for (const auto* cks : sampleMatch->checksums) {
            auto splitted_cks = ExtractorAllocator::splitChecksumAt(cks, shifted);
            if (splitted_cks.first) {
                LOG4("Alloc checksum to common state: " << splitted_cks.first);
                common->checksums.push_back(splitted_cks.first);
            }
        }

        common->shift = shifted;
    }

    /// Split out common primitives to a common state and return this state.
    /// Splitted primitives will be removed from original state and shift are adjusted.
    /// @return a state with common primitives and its next state is the truncated original
    /// state.
    IR::BFN::LoweredParserState*
    splitOutCommonState(IR::BFN::LoweredParserState* state,
                        const std::vector<const IR::BFN::LoweredSave*>& extra_saves,
                        int common_until) {
        auto state_name =
            cstring::make_unique(stateNames, state->name + ".$common");
        stateNames.insert(state_name);
        auto* common_state =
            new IR::BFN::LoweredParserState(state_name, state->gress);
        auto* only_match =
            new IR::BFN::LoweredParserMatch(match_t(), 0, state);
        common_state->transitions.push_back(only_match);

        // Add extra saves to this match.
        for (auto* save : extra_saves) {
            LOG5("Adding leftover saves:" << save);
            only_match->saves.push_back(save); }

        // save common part to the only match.
        addCommonStatePrimitives(only_match, state, common_until);
        LOG5("Default Match Of Common State: " << only_match);

        // add primitives to tail state part.
        addTailStatePrimitives(state, common_until);
        LOG5("Truncated Tail State: " << state);

        return common_state;
    }

    IR::BFN::LoweredParserState*
    createCommonPrimitiveState(const IR::BFN::LoweredParserState* state,
                               const std::vector<const IR::BFN::LoweredSave*>& extra_saves) {
        // If this state does not need to split, and there is no extra saves, do not
        // generate a common primitive state for it, because that would increase the number
        // of states.
        auto needSplit = needSplitState(state);
        int common_until = calcEarliestConflict(state);
        LOG5("Primitives are common until: " << common_until);

        if (extra_saves.empty()) {
            if (!needSplit) {
                LOG1("Does not have extra saves nor need to split: " << state->name);
                return state->clone();
            } else if (*needSplit > common_until) {
                // If there are different saves between matches in the first
                // splitted state, then, we can not create any common state.
                // TODO(yumin): we can create a smaller common state to hold
                // primitives before common_until, by using the splitOneByBandwidth
                // with input buffer size limited to common_until.
                LOG1("Cannot create common state: " << state->name);
                return state->clone();
            }
        }

        // Spliting state will not work efficiently if the the pre-sliced common state has
        // too many extracts that some of them can be done in the last branching state,
        // So we leave those primitives that can be done in he last state to the last state.
        return splitOutCommonState(state->clone(), extra_saves, common_until);
    }

    /// Add common state when needed. Then preorder on match will be executed on new state.
    bool preorder(IR::BFN::LoweredParserState* state) override {
        std::vector<const IR::BFN::LoweredSave*> extra_saves(leftover_saves[state->name]);
        auto* common_primitive_state =
            createCommonPrimitiveState(state, extra_saves);
        leftover_saves[state->name].clear();
        *state = *common_primitive_state;
        return true;
    }

    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        if (added.count(match))
            return true;
        auto* state = findContext<IR::BFN::LoweredParserState>();

        ExtractorAllocator allocator(state->name, match);

        // Allocate whatever we can fit into this match.
        auto primitives_a = allocator.allocateOneState();
        match->statements = primitives_a.extracts;
        match->checksums  = primitives_a.checksums;
        match->saves      = primitives_a.saves;
        match->shift      = primitives_a.shift;

        // If there's still more, allocate as many followup states as we need.
        auto* finalState = match->next;
        auto* currentMatch = match;
        while (allocator.hasMore()) {
            // Create a new split state.
            auto newName = cstring::make_unique(stateNames, state->name + ".$split");
            stateNames.insert(newName);
            auto* newState =
              new IR::BFN::LoweredParserState(newName, state->gress);
            newState->debug = state->debug;
            currentMatch->next = newState;

            LOG3("Created new split state " << newState->name);

            // Create a new match node and place as many primitives in it as we can.
            auto primitives = allocator.allocateOneState();
            auto* newMatch =
              new IR::BFN::LoweredParserMatch(match_t(), 0, finalState);

            newMatch->statements = primitives.extracts;
            newMatch->checksums  = primitives.checksums;
            newMatch->saves      = primitives.saves;
            newMatch->shift      = primitives.shift;
            newState->transitions.push_back(newMatch);

            // If there's more, we'll append the next state to the new match node.
            currentMatch = newMatch;
            added.insert(newMatch);
        }

        // If there is out-of-buffer saves, leave them to the next state.
        if (allocator.hasOutOfBufferSaves()) {
            for (const auto* save : allocator.getRemainingSaves()) {
                LOG1("Found Remaining Saves:" << save <<
                     " must be done before " << finalState->name
                     << " from state: " << state->name); }
            BUG_CHECK(leftover_saves[finalState->name].size() == 0,
                      "Select on field from different parent branches is not supported.");
            leftover_saves[finalState->name] = allocator.getRemainingSaves();
        }

        return true;
    }

    std::set<cstring> stateNames;
    std::set<IR::BFN::LoweredParserMatch*> added;
    std::map<cstring, std::vector<const IR::BFN::LoweredSave*>> leftover_saves;
};

/// Locate all containers that are written more than once by the parser (and
/// hence need the "multiwrite" bit set).
/// Must run after ComputeInitZeroContainers, because those containers probably
/// need to be on the multi_write list, if packed with other field wrote in parser.
class ComputeMultiwriteContainers : public ParserModifier {
    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        for (auto* stmt : match->statements)
            if (auto* extract = stmt->to<IR::BFN::LoweredExtractPhv>())
                if (extract->dest)
                    writes[extract->dest->container]++;
        return true;
    }

    void postorder(IR::BFN::LoweredParser* parser) override {
        // Init Zero fields set container valid it 1, so if where is any write,
        // the container should be set as multi_write.
        for (auto& c : parser->initZeroContainers) {
            writes[c->container]++; }

        // Mark any container that's written more than once as multiwrite. (At
        // this point, we assume that earlier passes have verified that the
        // program is correct, so multiple writes must be intentional.)
        for (auto item : writes) {
            auto container = item.first;
            auto writeCount = item.second;
            if (writeCount > 1)
                parser->multiwriteContainers.push_back(new IR::BFN::ContainerRef(container));
        }

        // Reset our data structure; each parser must be considered separately.
        writes = { };
    }

    std::map<PHV::Container, unsigned> writes;
};

// If a container that participates in ternary match is invalid, model(HW)
// uses the last valid value in that container to perform the match.
// To help user avoid matching on stale value in container, we issue warning
// message so that user doesn't fall through this trapdoor.
class WarnTernaryMatchFields : public MauInspector {
    const PhvInfo& phv;
    ordered_map<const IR::MAU::Table*, ordered_set<const PHV::Field*>> ternary_match_fields;

 public:
    explicit WarnTernaryMatchFields(const PhvInfo& phv) : phv(phv) { }

    bool preorder(const IR::MAU::Table* tbl) override {
        if (!tbl->layout.ternary)
            return false;

        auto& ixbar_use = tbl->resources->match_ixbar;

        for (auto& b : ixbar_use.use) {
            for (auto &fi : b.field_bytes) {
                auto f = phv.field(fi.field);
                ternary_match_fields[tbl].insert(f);
            }
        }

        // TODO(zma) check if user has already included the header validity bits
        // and if ternary match table is predicated by a header validty gateway
        // table so that we don't spew too many spurious warnings.

        return false;
    }

    void end_apply() override {
        for (auto &tf : ternary_match_fields) {
            for (auto f : tf.second) {
                if (!f->is_invalidate_from_arch()) continue;

                std::stringstream ss;

                ss << "Matching on " << f->name << " in table " << tf.first->name << " (implemented"
                   << " with ternary resources) before it has been assigned can result in "
                   << "non-deterministic lookup behavior."
                   << "\nConsider including in the match key an additional metadata"
                   << " field that indicates whether the field has been assigned.";

                ::warning("%1%", ss.str());
            }
        }
    }
};

/// Compute containers that have fields relying on parser zero initialization.
class ComputeInitZeroContainers : public ParserModifier {
    void postorder(IR::BFN::LoweredParser* parser) override {
        ordered_set<PHV::Container> zero_init_containers;
        ordered_set<PHV::Container> intrinsic_invalidate_containers;

        for (const auto& f : phv) {
            if (f.gress != parser->gress) continue;

            // POV bits are treated as metadata
            if (f.pov || f.metadata) {
                f.foreach_alloc([&] (const PHV::Field::alloc_slice& alloc) {
                    bool hasHeaderField = false;

                    for (auto fc : phv.fields_in_container(alloc.container)) {
                        if (!fc->metadata && !fc->pov) {
                            hasHeaderField = true;
                            break;
                        }
                    }

                    if (!hasHeaderField)
                        zero_init_containers.insert(alloc.container);
                });
            }

            if (f.is_invalidate_from_arch()) {
                // Track the allocated containers for fields that are invalidate_from_arch
                f.foreach_alloc([&] (const PHV::Field::alloc_slice& alloc) {
                    intrinsic_invalidate_containers.insert(alloc.container);
                    LOG3(alloc.container << " contains intrinsic invalidate fields");
                });
                continue;
            }

            // XXX(yumin): fields that reads $valid should not be initialized.
            if (f.read_container_valid_bit()) continue;

            if (defuse.hasUninitializedRead(f.id)) {
                // If pa_no_init specified, then the field does not have to rely on parser zero
                // initialization.
                if (no_init_fields.count(&f)) continue;
                f.foreach_alloc([&] (const PHV::Field::alloc_slice& alloc) {
                    zero_init_containers.insert(alloc.container);
                });
            }
        }

        for (auto& c : zero_init_containers) {
            // Containers for intrinsic invalidate_from_arch metadata should be left
            // uninitialized, therefore skip zero-initialization
            if (!intrinsic_invalidate_containers.count(c)) {
                parser->initZeroContainers.push_back(new IR::BFN::ContainerRef(c));
                LOG3("parser init " << c);
            }
        }

        // Also initialize the container validity bits for the zero-ed containers (as part of
        // deparsed zero optimization) to 1.
        for (auto& c : phv.getZeroContainers(parser->gress)) {
            if (intrinsic_invalidate_containers.count(c))
                BUG("%1% used for both init-zero and intrinsic invalidate field?", c);

            parser->initZeroContainers.push_back(new IR::BFN::ContainerRef(c));
        }
    }

 public:
    ComputeInitZeroContainers(
            const PhvInfo& phv,
            const FieldDefUse& defuse,
            const ordered_set<const PHV::Field*>& no_init)
        : phv(phv), defuse(defuse), no_init_fields(no_init) {}

    const PhvInfo& phv;
    const FieldDefUse& defuse;
    const ordered_set<const PHV::Field*>& no_init_fields;
};

/// Compute the number of bytes which must be available for each parser match to
/// avoid a stall.
class ComputeBufferRequirements : public ParserModifier {
    void postorder(IR::BFN::LoweredParserMatch* match) override {
        // Determine the range of bytes in the input packet read if this match
        // is successful. Note that we ignore `LoweredBufferRVal`s and
        // `LoweredConstantRVal`s, since those do not originate in the input
        // packet.
        nw_byteinterval bytesRead;
        forAllMatching<IR::BFN::LoweredExtractPhv>(&match->statements,
                      [&] (const IR::BFN::LoweredExtractPhv* extract) {
            if (auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>()) {
                bytesRead = bytesRead.unionWith(source->byteInterval());
            }
        });

        forAllMatching<IR::BFN::LoweredSave>(&match->saves,
                      [&] (const IR::BFN::LoweredSave* save) {
            bytesRead = bytesRead.unionWith(save->source->byteInterval());
        });

        forAllMatching<IR::BFN::LoweredParserChecksum>(&match->checksums,
                      [&] (const IR::BFN::LoweredParserChecksum* cks) {
            for (const auto& r : cks->masked_ranges) {
                bytesRead = bytesRead.unionWith(toHalfOpenRange(r)); }
        });

        // We need to have buffered enough bytes to read the last byte in the
        // range. We also need to be sure to buffer at least as many bytes as we
        // plan to shift.
        match->bufferRequired = std::max(unsigned(bytesRead.hi), match->shift);

        const unsigned inputBufferSize = Device::pardeSpec().byteInputBufferSize();
        BUG_CHECK(*match->bufferRequired <= inputBufferSize,
                  "Match for state %1% requires %2% bytes to be buffered, which "
                  "is more than can fit in the %3% byte input buffer",
                  findContext<IR::BFN::LoweredParserState>()->name,
                  *match->bufferRequired, inputBufferSize);
    }
};

}  // namespace

LowerParser::LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse) :
    Logging::PassManager("parser", true /* append */) {
    auto* pragma_no_init = new PragmaNoInit(phv);
    addPasses({
        pragma_no_init,
        new LowerParserIR(phv, clot),
        new LowerDeparserIR(phv, clot),
        LOGGING(3) ? new DumpParser("before_split_big_states") : nullptr,
        new SplitBigStates,
        LOGGING(3) ? new DumpParser("after_split_big_states") : nullptr,
        new WarnTernaryMatchFields(phv),
        new ComputeInitZeroContainers(phv, defuse, pragma_no_init->getFields()),
        new ComputeMultiwriteContainers,  // Must run after ComputeInitZeroContainers.
        new ComputeBufferRequirements,
        LOGGING(1) ? new CharacterizeParser : nullptr
    });
}
