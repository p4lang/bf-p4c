#include "bf-p4c/parde/lower_parser.h"

#include <algorithm>
#include <numeric>
#include <sstream>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/flatrock.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/characterize_parser.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/coalesce_learning.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/flatrock.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/split_parser_state.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"
#include "lib/stringref.h"

namespace {

/// @return a version of the provided state name which is safe to use in the
/// generated assembly.
cstring sanitizeName(StringRef name) {
    // Drop any thread-specific prefix from the name.
    if (auto prefix = name.findstr("::"))
        name = name.after(prefix) += 2;
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
cstring debugInfoFor(const IR::BFN::ParserLVal* lval,
                     const PHV::AllocSlice& slice,
                     bool includeContainerInfo = true) {
    std::stringstream info;

    auto fieldRef = lval->to<IR::BFN::FieldLVal>();
    if (!fieldRef) return info;

    // Describe the range of bits assigned to this field slice in the container.
    // (In some cases we break this down in more detail elsewhere, so we don't
    // need to repeat it.)
    if (includeContainerInfo) {
        const le_bitrange sourceBits = slice.container_slice();
        if (sourceBits.size() != ssize_t(slice.container().size()))
            info << sourceBits << ": ";
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
cstring debugInfoFor(const IR::BFN::Extract* extract,
                     const PHV::AllocSlice& slice,
                     const nw_bitrange& bufferRange = nw_bitrange(),
                     bool includeRangeInfo = false) {
    std::stringstream info;

    // Describe the value that's being written into the destination container.
    if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
        info << "value " << constantSource->constant << " -> "
             << slice.container() << " " << slice.container_slice() << ": ";
    } else if (extract->source->is<IR::BFN::PacketRVal>()) {
        // In the interest of brevity, don't print the range of bits being
        // extracted into the destination container if it matches the size of
        // the container exactly.
        // This behaviour can be overridden by explicit true value of
        // includeRangeInfo parameter in case we desire to print the range always.
        if (includeRangeInfo || slice.container().size() != size_t(bufferRange.size()))
            info << bufferRange << " -> " << slice.container() << " "
                 << slice.container_slice() << ": ";
    } else if (extract->source->is<IR::BFN::MetadataRVal>()) {
        info << "buffer mapped I/O: " << bufferRange << " -> "
             << slice.container() << " " << slice.container_slice() << ": ";
    }

    // Describe the field slice that we're writing to.
    info << debugInfoFor(extract->dest, slice, /* includeContainerInfo = */ false);

    return cstring(info);
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
        if (auto ec = extract->to<IR::BFN::ExtractClot>())
            add(ec);
        else if (auto ep = extract->to<IR::BFN::ExtractPhv>())
            add(ep);
        else
            BUG("Unexpected unclassified extract encountered while lowering parser IR: %1%",
                extract);
    }

    void add(const IR::BFN::ExtractClot* extract) {
        le_bitrange extracted_range;
        auto field = phv.field(extract->dest->field, &extracted_range);
        auto extracted_slice = new PHV::FieldSlice(field, extracted_range);

        // Populate clotExtracts with entries for the current extract.
        auto slice_clots = clot.slice_clots(extracted_slice);
        BUG_CHECK(slice_clots, "Parser extract didn't receive a CLOT allocation: %1%", extract);
        BUG_CHECK(slice_clots->size() == 1,
                  "Expected a single CLOT for a parser extract, but it was allocated across %1% "
                  "CLOTs: %2%",
                  slice_clots->size(), extract);

        auto entry = *slice_clots->begin();
        auto slice = entry.first;
        auto clot = entry.second;

        BUG_CHECK(slice->range().contains(extracted_range),
                  "Parser extract received an incomplete CLOT allocation: %1%",
                  extract);
        clotExtracts[clot].push_back(extract);
    }

    void add(const IR::BFN::ExtractPhv* extract) {
        PHV::FieldUse use(PHV::FieldUse::WRITE);
        std::vector<PHV::AllocSlice> slices = phv.get_alloc(extract->dest->field,
                PHV::AllocContext::PARSER, &use);
        if (slices.empty()) {
            BUG("Parser extract didn't receive a PHV allocation: %1%", extract);
            return;
        }

        // TODO(zma) we should have single slice at this point

        for (const auto& slice : slices)
            BUG_CHECK(bool(slice.container()),
                      "Parser extracts into invalid PHV container: %1%", extract);

        if (auto* bufferSource = extract->source->to<IR::BFN::InputBufferRVal>()) {
            for (const auto& slice : slices) {
                if (!slice.isUsedParser()) continue;
                // Shift the slice to its proper place in the input buffer.
                auto bufferRange = bufferSource->range;

                // Mask to round bit positions down to the nearest byte boundary
                const int byteMask = ~(8 - 1);

                // Expand the buffer slice so that it will write to the entire
                // destination container, with this slice in the proper place.
                // If the slice didn't fit the container exactly, this will
                // write to more bits than were included in the slice, but if
                // PHV allocation did its job then those bit are either unused,
                // or are occupied by other extracts that we'll merge with this
                // one.

                const nw_bitrange containerRange =
                  slice.container_slice().toOrder<Endian::Network>(slice.container().size());

                const nw_bitrange finalBufferRange =
                    Device::pardeSpec().parserAllExtractorsSupportSingleByte()
                        ? bufferRange.shiftedByBits(-(containerRange.lo % 8))
                              .resizedToBits(((containerRange.hi & byteMask) + 7) -
                                             (containerRange.lo & byteMask) + 1)
                        : bufferRange.shiftedByBits(-containerRange.lo)
                              .resizedToBits(slice.container().size());

                LOG4("mapping input buffer field slice " << bufferRange
                      << " into " << slice.container() << " " << containerRange
                      << " named " << extract->dest
                      << ". Final buffer range: " << finalBufferRange);

                const auto byteFinalBufferRange =
                  finalBufferRange.toUnit<RangeUnit::Byte>();

                // Generate the lowered extract.
                const IR::BFN::LoweredParserRVal* newSource;
                if (bufferSource->is<IR::BFN::PacketRVal>())
                    newSource = new IR::BFN::LoweredPacketRVal(byteFinalBufferRange);
                else
                    newSource = new IR::BFN::LoweredMetadataRVal(byteFinalBufferRange);

                auto containerRef = new IR::BFN::ContainerRef(slice.container());
                if (Device::pardeSpec().parserAllExtractorsSupportSingleByte()) {
                    nw_bitrange newRange;
                    newRange.lo = containerRange.lo & byteMask;
                    newRange.hi = (containerRange.hi & byteMask) + 7;
                    containerRef->range = newRange;
                }
                auto* newExtract = new IR::BFN::LoweredExtractPhv(newSource, containerRef);

                newExtract->write_mode = extract->write_mode;
                newExtract->debug.info.push_back(debugInfoFor(extract, slice,
                                                              bufferRange));

                if (bufferSource->is<IR::BFN::PacketRVal>())
                    extractFromPacketByContainer[slice.container()].push_back(newExtract);
                else
                    extractFromBufferByContainer[slice.container()].push_back(newExtract);
            }
        } else if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
            for (auto& slice : boost::adaptors::reverse(slices)) {
                // Large constant may be extracted across multiple containers, therefore we
                // need to slice the containt into multiple slices and align each slice
                // within each container.

                auto constSlice = *(constantSource->constant);
                constSlice = constSlice & IR::Constant::GetMask(slice.width());

                // Place those bits at their offset within the container.
                constSlice = constSlice << slice.container_slice().lo;

                BUG_CHECK(constSlice.fitsUint(), "Constant slice larger than 32-bit?");

                // Create an extract that writes just those bits.
                LOG4("extract " << constSlice << " into " << slice.container());

                auto* newSource =
                  new IR::BFN::LoweredConstantRVal(constSlice.asUnsigned());
                auto* newExtract =
                  new IR::BFN::LoweredExtractPhv(slice.container(), newSource);

                newExtract->write_mode = extract->write_mode;
                newExtract->debug.info.push_back(debugInfoFor(extract, slice));
                extractConstantByContainer[slice.container()].push_back(newExtract);
            }
        } else {
            BUG("Unexpected parser primitive (most likely something that should "
                "have been eliminated by an earlier pass): %1%", extract);
        }
    }

    /// Create a new merged extract from a sequence of extracts.
    /// The buffer range must have been identified already.
    /// All extracts should have the same write mode.
    ///
    /// @param container   The container to create the merged extract for
    /// @param extracts    The extracts to merge
    /// @param bufferRange The calculated range of buffer bytes to extract
    template <typename InputBufferRValType>
    static const IR::BFN::LoweredExtractPhv* createMergedExtract(PHV::Container container,
                                                                 const ExtractSequence& extracts,
                                                                 nw_byteinterval bufferRange) {
        // Create a single combined extract that implements all of the
        // component extracts. Each merged extract writes to an entire container.
        const auto* finalBufferValue = new InputBufferRValType(*toClosedRange(bufferRange));

        auto containerRef = new IR::BFN::ContainerRef(container);

        auto extractedSizeBits = bufferRange.toUnit<RangeUnit::Bit>().size();
        if (size_t(extractedSizeBits) != container.size()) {
            nw_bitrange newRange;
            newRange.lo = extracts[0]->dest->range->lo;
            newRange.hi = newRange.lo + extractedSizeBits - 1;
            containerRef->range = newRange;
        }

        auto* mergedExtract = new IR::BFN::LoweredExtractPhv(finalBufferValue, containerRef);

        mergedExtract->write_mode = extracts[0]->write_mode;

        for (auto* extract : extracts)
            mergedExtract->debug.mergeWith(extract->debug);

        return mergedExtract;
    }

    template <typename InputBufferRValType>
    static const ExtractSequence
    mergeExtractsFor(PHV::Container container, const ExtractSequence& extracts) {
        BUG_CHECK(!extracts.empty(), "Trying merge an empty sequence of extracts?");

        ExtractSequence rv;

        if (extracts.size() == 1) {
            rv.push_back(extracts[0]);
            return rv;
        }

        // Merge the input buffer range for every extract that writes to
        // this container. They should all be the same, but if they aren't
        // we want to know about it.
        nw_byteinterval bufferRange;
        std::map<int, std::map<int, ordered_set<const IR::BFN::LoweredExtractPhv*>>> extractDstSrcs;

        const IR::BFN::LoweredExtractPhv* prev = nullptr;

        for (auto* extract : extracts) {
            auto* bufferSource = extract->source->to<InputBufferRValType>();

            BUG_CHECK(bufferSource, "Unexpected non-buffer source");

            if (std::is_same<InputBufferRValType, IR::BFN::LoweredMetadataRVal>::value &&
                !Device::pardeSpec().parserAllExtractorsSupportSingleByte())
                BUG_CHECK(toHalfOpenRange(Device::pardeSpec().byteInputBufferMetadataRange())
                          .contains(bufferSource->byteInterval()),
                          "Extract from out of the input buffer range: %1%",
                          bufferSource->byteInterval());

            if (prev && extract->write_mode != prev->write_mode)
                BUG("Inconsistent parser write semantic on %1%", container);

            bufferRange = bufferSource->byteInterval().unionWith(bufferRange);
            unsigned int lo =
                extract->dest->range ? (unsigned int)(extract->dest->range->lo / 8) : 0;
            unsigned int hi = extract->dest->range ? (unsigned int)(extract->dest->range->hi / 8)
                                                   : (unsigned int)(container.size() / 8 - 1);
            for (unsigned int i = 0; i < hi - lo + 1; i++) {
                extractDstSrcs[lo + i][bufferSource->byteInterval().lo + i].emplace(extract);
            }

            prev = extract;
        }

        BUG_CHECK(!bufferRange.empty(), "Extracting zero bytes?");


        if (Device::pardeSpec().parserAllExtractorsSupportSingleByte()) {
            // The device supports single-byte extracts from all extractors, so merge byte extracts
            // where possible.
            while (extractDstSrcs.size()) {
                ExtractSequence currExtracts;
                std::set<const IR::BFN::LoweredExtractPhv*> currExtractsSet;
                int dest = extractDstSrcs.begin()->first;
                int src = extractDstSrcs.at(dest).begin()->first;

                nw_byteinterval newBufferRange(src, src);
                while (extractDstSrcs.count(dest) && extractDstSrcs.at(dest).count(src)) {
                    for (const auto* extract : extractDstSrcs.at(dest).at(src)) {
                        if (!currExtractsSet.count(extract)) {
                            currExtracts.push_back(extract);
                            currExtractsSet.emplace(extract);
                        }
                    }
                    newBufferRange.hi += 1;
                    extractDstSrcs.at(dest).erase(src);
                    if (!extractDstSrcs.at(dest).size()) extractDstSrcs.erase(dest);
                    dest += 1;
                    src += 1;
                }

                // Create a single combined extract that implements all of the
                // component extracts. Each merged extract writes to an entire container.
                rv.push_back(createMergedExtract<InputBufferRValType>(container, currExtracts,
                                                                      newBufferRange));
            }
        } else {
            // The device only supports full-container extractions. Veryfy that the extracts
            // consume the full container and merge.
            auto extractedSizeBits = bufferRange.toUnit<RangeUnit::Bit>().size();

            BUG_CHECK(size_t(extractedSizeBits) == container.size(),
                "PHV allocation is invalid for container %1%"
                " (number of extracted bits does not match container size).", container);

            // Create a single combined extract that implements all of the
            // component extracts. Each merged extract writes to an entire container.
            rv.push_back(
                createMergedExtract<InputBufferRValType>(container, extracts, bufferRange));
        }

        return rv;
    }

    void sortExtractPhvs(IR::Vector<IR::BFN::LoweredParserPrimitive>& loweredExtracts) {
        std::stable_sort(loweredExtracts.begin(), loweredExtracts.end(),
            [&] (const IR::BFN::LoweredParserPrimitive* a,
                 const IR::BFN::LoweredParserPrimitive* b) {
                auto ea = a->to<IR::BFN::LoweredExtractPhv>();
                auto eb = b->to<IR::BFN::LoweredExtractPhv>();

                if (ea && eb) {
                    auto va = ea->source->to<IR::BFN::LoweredPacketRVal>();
                    auto vb = eb->source->to<IR::BFN::LoweredPacketRVal>();

                    return (va && vb) ? (va->range < vb->range) : !!va;
                }

                return !!ea;
            });
    }

    const IR::BFN::LoweredExtractPhv*
    mergeExtractsForConstants(PHV::Container container, const ExtractSequence& extracts) {
        BUG_CHECK(!extracts.empty(), "Trying merge an empty sequence of extracts?");

        if (extracts.size() == 1)
            return extracts[0];

        // Merge all of the constant extracts for this container into a
        // single operation by ORing the constant sources together.
        auto* mergedValue = new IR::BFN::LoweredConstantRVal(0);
        auto* mergedExtract = new IR::BFN::LoweredExtractPhv(container, mergedValue);

        for (auto* extract : extracts) {
            auto* constantSource =
              extract->source->to<IR::BFN::LoweredConstantRVal>();

            BUG_CHECK(constantSource, "Unexpected non-constant source");

            mergedValue->constant |= constantSource->constant;
            mergedExtract->write_mode = extract->write_mode;
            mergedExtract->debug.mergeWith(extract->debug);
        }

        return mergedExtract;
    }

    /// Convert the sequence of Extract operations that have been passed to
    /// `add()` so far into a sequence of LoweredExtract operations. Extracts
    /// that write to the same container are merged together.
    IR::Vector<IR::BFN::LoweredParserPrimitive> lowerExtracts(
               std::map<gress_t, std::map<unsigned, unsigned>> clotTagToCsumUnit) {
        IR::Vector<IR::BFN::LoweredParserPrimitive> loweredExtracts;

        for (auto& item : extractFromPacketByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto& merged = mergeExtractsFor<IR::BFN::LoweredPacketRVal>(container, extracts);
            loweredExtracts.insert(loweredExtracts.end(), merged.begin(), merged.end());
        }

        sortExtractPhvs(loweredExtracts);

        for (auto& item : extractFromBufferByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto& merged = mergeExtractsFor<IR::BFN::LoweredMetadataRVal>(container, extracts);
            loweredExtracts.insert(loweredExtracts.end(), merged.begin(), merged.end());
        }

        for (auto& item : extractConstantByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto* merged = mergeExtractsForConstants(container, extracts);
            loweredExtracts.push_back(merged);
        }

        for (auto cx : clotExtracts) {
            auto* clot = cx.first;
            const auto* first_slice = clot->parser_state_to_slices().begin()->second.front();
            const auto* first_field = first_slice->field();

            bool is_start = false;
            nw_bitinterval bitInterval;

            for (auto extract : cx.second) {
                auto rval = extract->source->to<IR::BFN::PacketRVal>();
                bitInterval = bitInterval.unionWith(rval->interval());

                // Figure out if the current extract includes the first bit in the CLOT.
                if (is_start) continue;

                // Make sure we're extracting the first field.
                auto dest = phv.field(extract->dest->field);
                if (dest != first_field) continue;

                if (extract->dest->field->is<IR::Member>()) {
                    // Extracting the whole field.
                    is_start = true;
                    continue;
                }

                if (auto sl = extract->dest->field->to<IR::Slice>()) {
                    if (int(sl->getH()) == first_slice->range().hi) {
                        // Extracted slice includes the first bit of the slice.
                        is_start = true;
                        continue;
                    }
                }
            }

            nw_bitrange bitrange = *toClosedRange(bitInterval);
            nw_byterange byterange = bitrange.toUnit<RangeUnit::Byte>();

            auto* rval = new IR::BFN::LoweredPacketRVal(byterange);
            auto* extractClot = new IR::BFN::LoweredExtractClot(is_start, rval, clot);
            extractClot->higher_parser_state = cx.second.front()->original_state;
            if (clotTagToCsumUnit[clot->gress].count(clot->tag)) {
                clot->csum_unit = clotTagToCsumUnit[clot->gress][clot->tag];
            }
            loweredExtracts.push_back(extractClot);
        }

        return loweredExtracts;
    }

    /// The sequence of extract operations to be simplified. They're organized
    /// by container so that multiple extracts to the same container can be
    /// merged.
    ordered_map<PHV::Container, ExtractSequence> extractFromPacketByContainer;
    ordered_map<PHV::Container, ExtractSequence> extractFromBufferByContainer;
    ordered_map<PHV::Container, ExtractSequence> extractConstantByContainer;

    ordered_map<Clot*, std::vector<const IR::BFN::ExtractClot*>> clotExtracts;
};

/// Maps a sequence of fields to a sequence of PHV containers. The sequence of
/// fields is treated as ordered and non-overlapping; the resulting container
/// sequence is the shortest one which maintains these properties.
std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot*>>
lowerFields(const PhvInfo& phv, const ClotInfo& clotInfo,
            const IR::Vector<IR::BFN::FieldLVal>& fields,
            bool is_checksum = false) {
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
                if (clots.empty() || clots.back() != clot)
                    clots.push_back(clot);
            }

            if (clotInfo.fully_allocated(field) ||
                (clotInfo.is_readonly(field) && clotInfo.whole_field_clot(field))) continue;
        }

        // padding in digest list does not need phv allocation
        if (field->is_ignore_alloc())
            continue;

        PHV::FieldUse use(PHV::FieldUse::READ);
        std::vector<PHV::AllocSlice> slices = phv.get_alloc(fieldRef->field,
                PHV::AllocContext::DEPARSER, &use);

        BUG_CHECK(!slices.empty(),
                  "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        for (auto& slice : boost::adaptors::reverse(slices)) {
            BUG_CHECK(bool(slice.container()), "Emitted field was allocated to "
                      "an invalid PHV container: %1%", fieldRef->field);

            const nw_bitrange containerRange = slice.container_slice()
                .toOrder<Endian::Network>(slice.container().size());

            if (last && last->container == slice.container()) {
                auto lastRange = *(last->range);
                    if (lastRange.hi < containerRange.lo) {
                    LOG5(" - Merging in " << fieldRef->field);
                    last->debug.info.push_back(debugInfoFor(fieldRef, slice));
                    last->range = lastRange.unionWith(containerRange);
                    continue;
                }
            }

            LOG5("Deparser: lowering field " << fieldRef->field
                  << " to " << slice.container());

            last = new IR::BFN::ContainerRef(slice.container());
            last->range = containerRange;
            last->debug.info.push_back(debugInfoFor(fieldRef, slice));
            containers.push_back(last);

            if (slice.field()->is_checksummed() && slice.field()->is_solitary()) {
                // Since the field has a solitary constraint, its is safe to
                // extend the range till the end of container
                last->range = containerRange.unionWith(nw_bitrange(
                               StartLen(0, slice.container().size())));
            }
        }
    }

    return {containers, clots};
}
/// Maps a POV bit field to a single bit within a container, represented as a
/// ContainerBitRef. Checks that the allocation for the POV bit field is sane.
const IR::BFN::ContainerBitRef*
lowerSingleBit(const PhvInfo& phv,
               const IR::BFN::FieldLVal* fieldRef,
               const PHV::AllocContext* ctxt) {
    le_bitrange range;
    auto* field = phv.field(fieldRef->field, &range);

    std::vector<PHV::AllocSlice> slices;
    field->foreach_alloc(&range, ctxt, nullptr, [&](const PHV::AllocSlice& alloc) {
        slices.push_back(alloc);
    });

    BUG_CHECK(!slices.empty(), "bit %1% didn't receive a PHV allocation",
              fieldRef->field);
    BUG_CHECK(slices.size() == 1, "bit %1% is somehow split across "
              "multiple containers?", fieldRef->field);

    auto container = new IR::BFN::ContainerRef(slices.back().container());
    auto containerRange = slices.back().container_slice();
    BUG_CHECK(containerRange.size() == 1, "bit %1% is multiple bits?",
              fieldRef->field);

    auto* bit = new IR::BFN::ContainerBitRef(container, containerRange.lo);
    LOG5("Mapping bit field " << fieldRef->field << " to " << bit);
    bit->debug.info.push_back(debugInfoFor(fieldRef, slices.back(),
                              /* includeContainerInfo = */ false));
    return bit;
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
    ComputeLoweredParserIR(
        const PhvInfo& phv, ClotInfo& clotInfo, const AllocateParserChecksums& checksumAlloc,
        std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers)
        : phv(phv),
          clotInfo(clotInfo),
          checksumAlloc(checksumAlloc),
          origParserZeroInitContainers(origParserZeroInitContainers) {
        // Initialize the map from high-level parser states to low-level parser
        // states so that null, which represents the end of the parser program
        // in the high-level IR, is mapped to null, which conveniently enough
        // means the same thing in the lowered IR.
        loweredStates[nullptr] = nullptr;
    }

    std::map<const IR::BFN::ParserState*,
             const IR::BFN::LoweredParserState*> loweredStates;
    std::set<const IR::BFN::LoweredParserState*> dontMergeStates;

    const IR::BFN::ContainerRef* igParserError = nullptr;
    const IR::BFN::ContainerRef* egParserError = nullptr;
    unsigned egressMetaOpt = 0;
    unsigned egressMetaSize = 0;  // in byte

 private:
    profile_t init_apply(const IR::Node *node) override {
        dontMergeStates.clear();
        return Inspector::init_apply(node);
    }

    bool preorder(const IR::Type_Header* type) override {
        LOG1("ComputeLoweredParserIR preorder on Header : " << type);
        if (type->name == "egress_intrinsic_metadata_t") {
            static std::vector<std::pair<std::string, unsigned>> eg_intr_md = {
                {"enq_qdepth", 3},
                {"enq_congest_stat", 1},
                {"enq_tstamp", 4},
                {"deq_qdepth", 3},
                {"deq_congest_stat", 1},
                {"app_pool_congest_stat", 1},
                {"deq_timedelta", 4},
                {"egress_rid", 2},
                {"egress_rid_first", 1},
                {"egress_qid", 1},
                {"egress_cos", 1 },
                {"deflection_flag", 1},
                {"pkt_length", 2}
            };

            for (auto it = eg_intr_md.begin(); it != eg_intr_md.end(); it++) {
                for (auto f : type->fields) {
                    if (f->name == it->first) {
                        egressMetaOpt |= 1 << (it - eg_intr_md.begin());
                        egressMetaSize += it->second;
                        break;
                    }
                }
            }

            // Make sure the 2-byte egress port is included in this offset adjustment.
            egressMetaSize += 2;

            // JBay and later requires the egress intrinsic metadata to be padded to 4-byte aligned
            if (Device::currentDevice() != Device::TOFINO) {
                egressMetaSize = ((egressMetaSize + 3) / 4) * 4;
            }

            LOG2("meta_opt: " << egressMetaOpt);
            LOG2("meta_size: " << egressMetaSize);
        }

        return true;
    }

    IR::Vector<IR::BFN::LoweredParserChecksum>
    lowerParserChecksums(const IR::BFN::Parser* parser,
                         const IR::BFN::ParserState* state,
                         const std::vector<const IR::BFN::ParserChecksumPrimitive*>& checksums) {
        IR::Vector<IR::BFN::LoweredParserChecksum> loweredChecksums;
        ordered_map<cstring,
                 std::vector<const IR::BFN::ParserChecksumPrimitive*>> csum_to_prims;
        for (auto prim : checksums)
            csum_to_prims[prim->declName].push_back(prim);

        for (auto& kv : csum_to_prims) {
            auto csum = lowerParserChecksum(parser, state, kv.first, kv.second);

            bool hasEquiv = false;
            for (auto c : loweredChecksums) {
                if (c->equiv(*csum)) {
                    hasEquiv = true;
                    break;
                }
            }

            if (!hasEquiv)
                loweredChecksums.push_back(csum);
        }
        return loweredChecksums;
    }
    unsigned int rangeToInt(const IR::BFN::PacketRVal* range) {
        auto lo = range->range.loByte();
        auto hi = range->range.hiByte();
        unsigned num = 0;

        for (int byte = lo; byte <= hi; ++byte)
            num |= (1 << byte/2);

        return num;
    }

    /// Create lowered HW checksum primitives that can be consumed by the assembler.
    /// Get the checksum unit allocation from checksumAlloc and destination container
    /// from PHV allocation.
    IR::BFN::LoweredParserChecksum*
    lowerParserChecksum(const IR::BFN::Parser* parser,
                        const IR::BFN::ParserState* state,
                        cstring name,
                        std::vector<const IR::BFN::ParserChecksumPrimitive*>& checksums) {
        unsigned id = checksumAlloc.get_id(parser, name);
        bool start = checksumAlloc.is_start_state(parser, name, state);
        bool end = checksumAlloc.is_end_state(parser, name, state);
        auto type = checksumAlloc.get_type(parser, name);

        const IR::BFN::FieldLVal* dest = nullptr;
        unsigned swap = 0;
        unsigned mul2 = 0;
        // Will be used to compare bitranges for multiply by 2 in jbay
        std::set<nw_bitrange> mask_for_compare;
        std::set<nw_byterange> masked_ranges;
        IR::BFN::ParserWriteMode write_mode = IR::BFN::ParserWriteMode::SINGLE_WRITE;
        for (auto c : checksums) {
            if (auto add = c->to<IR::BFN::ChecksumAdd>()) {
                if (auto v = add->source->to<IR::BFN::PacketRVal>()) {
                    masked_ranges.insert(v->range.toUnit<RangeUnit::Byte>());
                    if (add->swap)
                        swap |= rangeToInt(v);
                }
            } else if (auto sub = c->to<IR::BFN::ChecksumSubtract>()) {
                if (auto v = sub->source->to<IR::BFN::PacketRVal>()) {
                    if (mask_for_compare.find(v->range) != mask_for_compare.end()) {
                        if (Device::currentDevice() != Device::TOFINO) {
                            mul2 |= rangeToInt(v);
                        }
                    } else {
                        masked_ranges.insert(v->range.toUnit<RangeUnit::Byte>());
                        mask_for_compare.insert(v->range);
                    }
                    if (sub->swap)
                        swap |= rangeToInt(v);
                }
            } else if (auto cwrite = c->to<IR::BFN::ParserChecksumWritePrimitive>()) {
                dest = cwrite->getWriteDest();
                write_mode = cwrite->getWriteMode();
            }
            // swap or mul_2 register is 17 bit long
            BUG_CHECK(swap <= ((1 << 17) - 1), "checksum swap byte is out of input buffer");
            BUG_CHECK(mul2 <= ((1 << 17) - 1), "checksum mul_2 byte is out of input buffer");
        }

        int end_pos = 0;
        if (end) {
            for (auto csum : checksums) {
                if (auto get = csum->to<IR::BFN::ChecksumResidualDeposit>())
                    end_pos = get->header_end_byte->range.toUnit<RangeUnit::Byte>().lo;
            }
        }

        auto csum = new IR::BFN::LoweredParserChecksum(
            id, masked_ranges, swap, start, end, end_pos, type, mul2, write_mode);
        std::vector<PHV::AllocSlice> slices;

        // FIXME(zma) this code could use some cleanup, what a mess ...
        if (dest) {
            auto f = phv.field(dest->field);
            PHV::FieldUse use(PHV::FieldUse::WRITE);
            slices = phv.get_alloc(f, nullptr, PHV::AllocContext::PARSER, &use);  // XXX(zma)
            BUG_CHECK(slices.size() == 1, "checksum error %1% is somehow allocated to "
               "multiple containers?", dest->field);
        }

        if (type == IR::BFN::ChecksumMode::VERIFY && dest) {
            if (auto sl = dest->field->to<IR::Slice>()) {
                BUG_CHECK(sl->getL() == sl->getH(), "checksum error must write to single bit");
                csum->csum_err = new IR::BFN::ContainerBitRef(
                                     new IR::BFN::ContainerRef(slices.back().container()),
                                     (unsigned)sl->getL());
            } else {
                csum->csum_err = lowerSingleBit(phv, dest, PHV::AllocContext::PARSER);
            }
        } else if (type == IR::BFN::ChecksumMode::RESIDUAL && dest) {
            csum->phv_dest = new IR::BFN::ContainerRef(slices.back().container());
        } else if (type == IR::BFN::ChecksumMode::CLOT && end) {
            auto last = checksums.back();
            auto deposit = last->to<IR::BFN::ChecksumDepositToClot>();
            BUG_CHECK(deposit, "clot checksum does not end with a deposit?");
            csum->clot_dest = *deposit->clot;
            clotTagToCsumUnit[state->gress][deposit->clot->tag] = csum->unit_id;
        }

        return csum;
    }

    struct CountStridedHeaderRefs : public Inspector {
        std::map<cstring, std::set<unsigned>> header_stack_to_indices;

        bool preorder(const IR::HeaderStackItemRef* hs) {
            auto stack = hs->base()->toString();
            auto index = hs->index()->to<IR::Constant>()->asUnsigned();
            header_stack_to_indices[stack].insert(index);
            return false;
        }
    };

    unsigned getOffsetIncAmt(const IR::BFN::ParserState* state) {
        CountStridedHeaderRefs count;
        state->statements.apply(count);

        // TODO move this check to midend
        if (count.header_stack_to_indices.size() > 1) {
            std::stringstream ss;
            for (auto& kv : count.header_stack_to_indices)
                ss << kv.first << " ";

            ::error("More than one header stack in parser state %1%: %2%", state->name, ss.str());
        }

        auto& indices = count.header_stack_to_indices.begin()->second;

        unsigned i = 0;

        for (auto idx : indices) {
            if (idx != i) {
                BUG("Illegal header stack references in parser state %1%. "
                     "Header stack indices must be contiguous.", state->name);
            }
            i++;
        }

        LOG4(state->name << " has offset_inc = " << indices.size());

        return indices.size();
    }

    void postorder(const IR::BFN::ParserState* state) override {
        LOG4("[ComputeLoweredParserIR] lowering state " << state->name);

        BUG_CHECK(!loweredStates.count(state),
                  "Parser state %1% already lowered?", state->name);

        auto* loweredState =
          new IR::BFN::LoweredParserState(sanitizeName(state->name), state->gress);

        std::vector<const IR::BFN::ParserChecksumPrimitive*> checksums;

        IR::Vector<IR::BFN::ParserCounterPrimitive> counters;

        const IR::BFN::ParserPrioritySet* priority = nullptr;
        const IR::BFN::HdrLenIncStop* stopper = nullptr;
        boost::optional<bool> partial_hdr_err_proc_extract =
                                                    boost::make_optional<bool>(false, bool());

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier(phv, clotInfo);
        for (auto prim : state->statements) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract);
                if (auto* pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                    // At this point, all possible conflicts with partial_hdr_err_proc
                    // must have been resolved by pass SplitGreedyParserStates that ran previously.
                    BUG_CHECK(!partial_hdr_err_proc_extract ||
                              *partial_hdr_err_proc_extract == pkt_rval->partial_hdr_err_proc,
                              "Parser state %1% has conflicting partial_hdr_err_proc",
                              state->name);
                    partial_hdr_err_proc_extract = pkt_rval->partial_hdr_err_proc;
                }
            } else if (auto* csum = prim->to<IR::BFN::ParserChecksumPrimitive>()) {
                checksums.push_back(csum);
            } else if (auto* cntr = prim->to<IR::BFN::ParserCounterPrimitive>()) {
                counters.push_back(cntr);
            } else if (auto* prio = prim->to<IR::BFN::ParserPrioritySet>()) {
                BUG_CHECK(!priority,
                          "more than one parser priority set in %1%?", state->name);
                priority = prio;
            } else if (auto* stop = prim->to<IR::BFN::HdrLenIncStop>()) {
                BUG_CHECK(!stopper,
                          "more than one hdr_len_inc_stop in %1%?", state->name);
                stopper = stop;
            } else if (auto* zeroInit = prim->to<IR::BFN::ParserZeroInit>()) {
                if (Device::currentDevice() == Device::TOFINO) {
                    auto ctxt = PHV::AllocContext::PARSER;
                    for (auto& alloc : phv.get_alloc(zeroInit->field->field, ctxt))
                        origParserZeroInitContainers[state->thread()].emplace(alloc.container());
                }
            } else if (!prim->is<IR::BFN::ParserZeroInit>()){
                P4C_UNIMPLEMENTED("unhandled parser primitive %1%", prim);
            }
        }

        auto parser = findContext<IR::BFN::Parser>();
        auto loweredChecksums = lowerParserChecksums(parser, state, checksums);

        auto loweredExtracts = simplifier.lowerExtracts(clotTagToCsumUnit);

        /// Convert multiple select into one.
        auto* loweredSelect = new IR::BFN::LoweredSelect();

        for (auto select : state->selects) {
            if (auto ctr = select->source->to<IR::BFN::ParserCounterRVal>())
                loweredSelect->counters.push_back(ctr);

            if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
                for (auto rs : saved->reg_slices)
                    loweredSelect->regs.insert(rs.first);
            }
        }

        loweredState->select = loweredSelect;

        for (auto* transition : state->transitions) {
            BUG_CHECK(int(transition->shift) <= Device::pardeSpec().byteInputBufferSize(),
                      "State %1% has shift %2% more than buffer size?",
                      state->name, transition->shift);
            BUG_CHECK(loweredStates.find(transition->next) != loweredStates.end(),
                      "Didn't already lower state %1%?",
                      transition->next ? transition->next->name : cstring("(null)"));

            boost::optional<bool> partial_hdr_err_proc_saves =
                                                    boost::make_optional<bool>(false, bool());
            IR::Vector<IR::BFN::LoweredSave> saves;

            for (const auto* save : transition->saves) {
                auto range = save->source->range.toUnit<RangeUnit::Byte>();

                IR::BFN::LoweredInputBufferRVal* source = nullptr;

                if (save->source->is<IR::BFN::MetadataRVal>())
                    source = new IR::BFN::LoweredMetadataRVal(range);
                else if (auto* sv = save->source->to<IR::BFN::PacketRVal>()) {
                    source = new IR::BFN::LoweredPacketRVal(range);
                    // At this point, all possible conflicts with partial_hdr_err_proc
                    // must have been resolved by pass SplitGreedyParserStates that ran previously.
                    BUG_CHECK(!partial_hdr_err_proc_saves ||
                              *partial_hdr_err_proc_saves == sv->partial_hdr_err_proc,
                              "Parser state %1% has conflicting partial_hdr_err_proc",
                              state->name);
                    partial_hdr_err_proc_saves = sv->partial_hdr_err_proc;
                } else
                    BUG("unexpected save source: %1%", save);

                saves.push_back(new IR::BFN::LoweredSave(save->dest, source));
            }

            // Final check for any possible conflicts with partial_hdr_err_proc
            // previously handled by SplitGreedyParserStates.
            BUG_CHECK(!partial_hdr_err_proc_saves || !partial_hdr_err_proc_extract ||
                      *partial_hdr_err_proc_saves == *partial_hdr_err_proc_extract,
                      "Parser state %1% has conflicting partial_hdr_err_proc",
                      state->name);

            // At this point, both partial_hdr_err_proc_extract and
            // partial_hdr_err_proc_saves are either set to boost::none
            // or set to something other than boost::none, but equal to
            // each other.
            // Set partialHdrErrProc accordingly.
            //
            bool partialHdrErrProc = false;
            if (partial_hdr_err_proc_extract) {
                partialHdrErrProc = *partial_hdr_err_proc_extract;
            } else if (partial_hdr_err_proc_saves) {
                partialHdrErrProc = *partial_hdr_err_proc_saves;
            }

            auto* loweredMatch = new IR::BFN::LoweredParserMatch(
                    transition->value,
                    transition->shift,
                    loweredExtracts,
                    saves,
                    transition->scratches,
                    loweredChecksums,
                    counters,
                    priority,
                    partialHdrErrProc,
                    loweredStates[transition->next]);

            if (state->stride)
                loweredMatch->offsetInc = getOffsetIncAmt(state);

            if (transition->loop)
                loweredMatch->loop = transition->loop;

            if (stopper) {
                auto last = stopper->source->range.toUnit<RangeUnit::Byte>();
                loweredMatch->hdrLenIncFinalAmt = last.hi ? last.hi + 1 : 0;
            }

            loweredState->transitions.push_back(loweredMatch);
        }

        // Now that we've constructed a lowered version of this state, save it
        // so that we can link its predecessors to it. (Which, transitively,
        // will eventually stitch the entire graph of lowered states together.)
        loweredStates[state] = loweredState;
        if (state->dontMerge) {
            dontMergeStates.insert(loweredState);
        }
    }

    void end_apply() override {
        for (const auto& f : phv) {
            auto ctxt = PHV::AllocContext::PARSER;
            if (f.name == "ingress::ig_intr_md_from_prsr.parser_err") {
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    BUG_CHECK(!igParserError, "parser error allocated to multiple containers?");
                    igParserError = new IR::BFN::ContainerRef(alloc.container());
                });
            } else if (f.name == "egress::eg_intr_md_from_prsr.parser_err") {
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    BUG_CHECK(!egParserError, "parser error allocated to multiple containers?");
                    egParserError = new IR::BFN::ContainerRef(alloc.container());
                });
            }
        }
    }

    const PhvInfo& phv;
    ClotInfo& clotInfo;
    const AllocateParserChecksums& checksumAlloc;
    std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers;
    // Maps clot tag to checksum unit whose output will be deposited in that CLOT for each gress
    std::map<gress_t, std::map<unsigned, unsigned>> clotTagToCsumUnit;
};

#ifdef HAVE_FLATROCK

/***
 * Intermediate representation of parser extractions.
 * Fed by ComputeFlatrockParserIR, consumed by ReplaceFlatrockParserIR.
 * @pre The slices stored in @a slices should not overlap.
 */
struct ParserExtract {
    Flatrock::ExtractType type;
    Flatrock::ExtractSubtype subtype;

    // size of the PHV container of this extraction
    PHV::Size size;
    // slices of the PHV container of this extraction; might not be the whole container if multiple
    // extractions are packed into one PHV container
    mutable std::vector<le_bitrange> slices;
    /**
     * @brief Container index (starting from 0 in each size category B/H/W)
     *
     * B0 -> 0
     * B1 -> 1
     * ...
     * H0 -> 0
     * H1 -> 1
     * ...
     * W0 -> 0
     * W1 -> 1
     */
    unsigned int index;

    cstring hdr;
    /// In case of a constant, @a offset stores the value of the constant at proper bit position.
    /// If more constants are mapped to a single container, their values are merged in @a offset.
    /// Marked mutable since the value is updated for constants when more are mapped to a single
    /// container.
    mutable int offset;

    /// Textual information about extracts
    mutable std::vector<cstring> comments;

    bool operator<(const ParserExtract& e) const {
        // header name does not affect ordering
        if (type == Flatrock::ExtractType::Packet)
            return std::tie(size, index, offset, type, subtype) <
                std::tie(e.size, e.index, e.offset, e.type, e.subtype);
        // don't match on offset because it stores the value of the constant
        return std::tie(size, index, type, subtype) <
            std::tie(e.size, e.index, e.type, e.subtype);
    }
};

/**
 * @brief All information from a parser state needed to create corresponding analyzer rules.
 */
struct AnalyzerRuleInfo {
    struct Header {
        cstring name;  /**< header name */
        int width;     /**< header width in bytes */
        int offset;    /**< header offset from current pointer in bytes */
    };

    struct Transition {
        struct NextMatchInfo {
            int offset;  /**< offset of the match value from current pointer in bytes */
            int size;    /**< size of the match value in bits */
        };

        /**
         * @brief Match value.
         */
        match_t match;
        /**
         * @brief State for the next stage.
         */
        const IR::BFN::ParserState* next_state;
        /**
         * @brief Offsets of w0, w1, w2 values.
         */
        std::vector<NextMatchInfo> next_w;
        /**
         * @brief Number of bytes to move the packet header pointer
         *        (used as immediate operand for ALU0 instruction).
         */
        int shift;

        void log(void) {
            LOG3("  match value: " << match);
            int i = 0;
            for (const auto& match : next_w) {
                LOG3("  next w" << i << " offset (in bytes): " << match.offset <<
                        ", size (in bits): " << match.size);
                ++i;
            }
            LOG3("  next state: " << (next_state ? next_state->name : "-") << std::endl <<
                    "  ptr shift: " << shift);
        }
    };

    /**
     * @brief Info about headers extracted in an associated state.
     */
    std::vector<Header> push_hdr;
    /**
     * @brief Info about transitions from a given state.
     */
    std::vector<Transition> transitions;
};

class ComputeFlatrockParserIR : public ParserInspector {
    typedef std::tuple<gress_t, PHV::Size, unsigned int /* index */, le_bitrange /* slice */>
        ExtractCommentInfo;

    const PhvInfo& phv;
    const FieldDefUse& defuse;

    cstring igMetaName;
    std::map<const IR::BFN::ParserState*, std::set<cstring>> headers;
    // Ingress intrinsic metadata has been extracted
    bool igMetaExtracted;

    profile_t init_apply(const IR::Node *node) override {
        headers.clear();
        rules_info.clear();
        extracts.clear();
        igMetaExtracted = false;
        return Inspector::init_apply(node);
    }

    bool preorder(const IR::BFN::Pipe* pipe) override {
        auto *igMeta = getMetadataType(pipe, "ingress_intrinsic_metadata");
        BUG_CHECK(igMeta, "Could not find ingress_intrinsic_metadata");
        igMetaName = igMeta->name;
        return true;
    }

    void add_extract(const gress_t gress, const PHV::AllocSlice& alloc,
            const ParserExtract& new_pe) {
        // TODO check if the layout of slices in the container is the same as the layout
        // of fields in the header in case of extract from packet
        // TODO check the container with fields extracted from packet if it does not
        // contain other types of slices
        BUG_CHECK(new_pe.slices.size() == 1, "New extract should have exactly 1 slice");
        auto pe = extracts[gress].find(new_pe);
        if (pe == extracts[gress].end()) {
            extracts[gress].insert(new_pe);
        } else {
            if (new_pe.type == Flatrock::ExtractType::Packet)
                BUG_CHECK(new_pe.hdr == pe->hdr,
                    "Fields from different headers (%1%, %2%)"
                    " are not supported in the same container: %3%",
                    new_pe.hdr, pe->hdr, alloc);
            pe->slices.push_back(new_pe.slices.front());
            pe->comments.push_back(new_pe.comments.front());
            // merge constants
            pe->offset |= new_pe.offset;
        }
    }

    bool preorder(const IR::BFN::ParserZeroInit* zero) override {
        return preorder(new IR::BFN::Extract(zero->field, new IR::BFN::ConstantRVal(0)));
    }

    ParserExtract extract_packet(const PHV::AllocSlice &alloc,
            const cstring hdr_name, int container_offset_in_bytes,
            const cstring comment) {
        ParserExtract e = {
            .type = Flatrock::ExtractType::Packet,
            .subtype = Flatrock::ExtractSubtype::None,
            .size = alloc.container().type().size(),
            .slices = std::vector<le_bitrange>{alloc.container_slice()},
            .index = alloc.container().index(),
            .hdr = hdr_name,
            .offset = container_offset_in_bytes,
            .comments = std::vector<cstring>{comment}
        };

        return e;
    }

    ParserExtract extract_constant(const PHV::AllocSlice &alloc,
            const IR::BFN::ConstantRVal *constant, const cstring hdr_name,
            const cstring comment, const Flatrock::ExtractSubtype subtype) {
        auto value = constant->constant->asUnsigned();
        // Check that the value doesn't overflow
        const auto max_slice_value = (1ULL << alloc.container_slice().size()) - 1;
        BUG_CHECK(value <= max_slice_value,
            "Value %1% too big for the constainer slice %2%%3% %4%", value,
            alloc.container().type().size(), alloc.container().index(), alloc.container_slice());

        ParserExtract e = {
            .type = Flatrock::ExtractType::Other,
            .subtype = subtype,
            .size = alloc.container().type().size(),
            .slices = std::vector<le_bitrange>{alloc.container_slice()},
            .index = alloc.container().index(),
            .hdr = hdr_name,
            // Store the value at proper bit position
            .offset = static_cast<int>(value << alloc.container_slice().lo),
            .comments = std::vector<cstring>{comment}
        };

        return e;
    }

    int get_hdr_bit_width(const IR::Expression *expr) {
        auto *member = expr->to<IR::Member>();
        if (member == nullptr)
            if (const auto *slice = expr->to<IR::Slice>())
                member = slice->e0->to<IR::Member>();
        CHECK_NULL(member);
        CHECK_NULL(member->expr);

        const auto hdr_ref = member->expr->to<IR::HeaderRef>();
        BUG_CHECK(hdr_ref, "Unsupported header expression: %1%", member->expr);
        CHECK_NULL(hdr_ref->baseRef());

        return hdr_ref->baseRef()->type->width_bits();
    }

    /**
     * The @p extract parameter can be a dummy not being a part of the IR tree.
     * @see preorder(const IR::BFN::ParserZeroInit* zero)
     */
    bool preorder(const IR::BFN::Extract* extract) override {
        // FIXME: Other extract sources are currently not mapped to HW resources,
        // so we rather report it than ignore them.
        BUG_CHECK(extract->source->is<IR::BFN::PacketRVal>() ||
                extract->source->is<IR::BFN::ConstantRVal>(),
                "Extract source: %1% is currently not supported!", extract->source);
        const auto* lval = extract->dest->to<IR::BFN::FieldLVal>();
        CHECK_NULL(lval);

        const auto allocs = phv.get_alloc(lval->field, PHV::AllocContext::PARSER);
        BUG_CHECK(allocs.size() <= 1, "Only one parser allocation allowed");
        const auto* phv_field = phv.field(lval->field);
        CHECK_NULL(phv_field);
        const cstring hdr_name = phv_field->header();
        BUG_CHECK(!hdr_name.isNullOrEmpty(), "Unspecified header name");
        if (hdr_name == igMetaName)
            igMetaExtracted = true;

        LOG5("lval->field: " << lval->field);
        LOG5("phv_field: " << phv_field);
        for (const auto &a : allocs) {
            LOG5("alloc: " << a);
        }

        bool used_in_ingress = false;
        bool used_in_egress = false;

        for (const auto& u : defuse.getAllUses(phv_field->id)) {
            if (u.first->thread() == INGRESS)
                used_in_ingress = true;
            if (u.first->thread() == EGRESS)
                used_in_egress = true;
        }

        if (allocs.size() > 0) {
            const auto& alloc = allocs.front();

            ParserExtract e;
            cstring comment = debugInfoFor(extract, alloc,
                    extract->source->is<IR::BFN::InputBufferRVal>() ?
                        extract->source->to<IR::BFN::InputBufferRVal>()->range :
                        nw_bitrange{},
                    true);

            if (const auto *pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                size_t hdr_bit_width = get_hdr_bit_width(lval->field);
                BUG_CHECK(hdr_bit_width % 8 == 0,
                        "Header %1% is not byte-aligned (%2% bits) during parser lowering",
                        hdr_name, hdr_bit_width);
                int after_field_bits = phv_field->offset;
                int field_offset_in_bits = hdr_bit_width - after_field_bits -
                    (alloc.field_slice().hi + 1);
                LOG5("field_offset_in_bits: " << field_offset_in_bits);
                BUG_CHECK(pkt_rval->range.lo >= field_offset_in_bits,
                        "Offset of extract (%1%) source in input buffer (%2%)"
                        " is lower than offset of destination field (%3%)",
                        extract, pkt_rval->range.lo, field_offset_in_bits);
                int hdr_offset_in_bits = pkt_rval->range.lo - field_offset_in_bits;
                BUG_CHECK(hdr_offset_in_bits % 8 == 0,
                        "Offset of header %1% is not byte-aligned (%2% bits)"
                        " during parser lowering",
                        hdr_name, hdr_offset_in_bits);
                int container_offset_in_bits = field_offset_in_bits -
                        (alloc.container().size() - (alloc.container_slice().hi + 1));
                LOG5("container_offset_in_bits: " << container_offset_in_bits);
                BUG_CHECK(container_offset_in_bits >= 0, "Invalid container allocation");
                BUG_CHECK(container_offset_in_bits % 8 == 0,
                        "Invalid position of slice in container");
                int container_offset_in_bytes = container_offset_in_bits / 8;
                LOG5("container_offset_in_bytes: " << container_offset_in_bytes);
                e = extract_packet(alloc, hdr_name, container_offset_in_bytes, comment);
                const auto *state = findContext<IR::BFN::ParserState>();
                CHECK_NULL(state);
                if (headers[state].count(hdr_name) == 0) {
                    int push_hdr_width = hdr_bit_width / 8;
                    headers[state].insert(hdr_name);
                    LOG3("Collecting state[" << state->name << "] push_hdr: " << hdr_name <<
                            ", width (in bytes): " << push_hdr_width <<
                            ", offset (in bytes): " << (hdr_offset_in_bits / 8));
                    rules_info[state].push_hdr.push_back({
                        hdr_name,
                        push_hdr_width,
                        hdr_offset_in_bits / 8
                    });
                }
            } else if (const auto* const_rval = extract->source->to<IR::BFN::ConstantRVal>()) {
                auto subtype = Flatrock::ExtractSubtype::Constant;
                if (auto member = extract->dest->to<IR::Member>()) {
                    if (member->member.name == "$valid") {
                        subtype = Flatrock::ExtractSubtype::PovFlags;
                    }
                }
                e = extract_constant(alloc, const_rval, hdr_name, comment, subtype);
            }

            // FIXME If a header field is modified in ingress and then used in egress,
            // extracting it again in egress would overwrite the changes from ingress.
            // The PHEs from ingress should be copied to egress instead.
            if (used_in_ingress)
                add_extract(INGRESS, alloc, e);
            if (used_in_egress)
                add_extract(EGRESS, alloc, e);
        };

        return true;
    }

    bool preorder(const IR::Flatrock::ExtractPayloadHeader* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        BUG_CHECK(state, "ExtractPayloadHeader: %1% out of state is invalid", extract);

        if (headers[state].count(extract->payload_pseudo_header_name) == 0) {
            headers[state].insert(extract->payload_pseudo_header_name);
            LOG3("Collecting state[" << state->name << "] payload pseudo header push_hdr: " <<
                    extract->payload_pseudo_header_name);
            rules_info[state].push_hdr.push_back(
                {extract->payload_pseudo_header_name, 0, 0});
        }

        return true;
    }

    bool preorder(const IR::BFN::Transition *t) override {
        const auto* state = findContext<IR::BFN::ParserState>();
        CHECK_NULL(state);

        AnalyzerRuleInfo::Transition transition_info{};

        // TODO support IR::BFN::ParserPvsMatchValue
        const auto* match_value = t->value->to<IR::BFN::ParserConstMatchValue>();
        BUG_CHECK(match_value, "Unsupported type of match value: %1%", t->value);

        transition_info.match = match_value->value;
        transition_info.next_state = t->next;
        transition_info.shift = t->shift;

        for (const auto* save : t->saves) {
            const auto* packet_source = save->source->to<IR::BFN::PacketRVal>();
            BUG_CHECK(packet_source, "Unsupported SaveToRegister source: %1%", save->source);

            int offset_in_bits = packet_source->range.lo;
            int size = packet_source->range.size();
            BUG_CHECK(offset_in_bits % 8 == 0, "Unsupported offset of match value (in bits): %1%",
                    offset_in_bits);
            BUG_CHECK(size <= 16, "Unsupported size of match value (in bits): %1%", size);

            BUG_CHECK(transition_info.next_w.size() == 0,
                    "Only 1 16-bit match value is currently supported, can not collect: %1%", save);
            transition_info.next_w.push_back({offset_in_bits / 8, size});
        }

        LOG3("Collecting state[" << state->name <<
                "] transition[" << rules_info[state].transitions.size() << "]");
        transition_info.log();

        rules_info[state].transitions.push_back(transition_info);

        return true;
    }

    bool preorder(const IR::BFN::ParserPrimitive *prim) override {
        // FIXME: Other parser primitives are currently not mapped to HW resources,
        // so we rather report it than ignore them.
        if (!findContext<IR::BFN::Transition>())
            BUG_CHECK(prim->is<IR::BFN::Extract>() ||
                prim->is<IR::BFN::ParserZeroInit>() ||
                prim->is<IR::Flatrock::ExtractPayloadHeader>(),
                "IR::BFN::ParserPrimitive: %1% is currently not supported!", prim);
        return true;
    }

    bool preorder(const IR::BFN::ParserState* state) override {
        LOG4("[ComputeFlatrockParserIR] lowering state " << state->name << ": " <<
                dbp(state) << std::endl << state);
        return true;
    }

    bool preorder(const IR::BFN::Parser* parser) override {
        LOG4("[ComputeFlatrockParserIR] lowering Flatrock parser " << parser->name);

        std::stringstream ss;
        ::dump(ss, parser);
        LOG4(ss.str());

        return true;
    }

    void end_apply() override {
        // We need to reverse the order because rules with lower index in Analyzer stage
        // have lower priority but the priority of transitions is the opposite.
        for (auto& kv : rules_info) {
            std::reverse(kv.second.transitions.begin(), kv.second.transitions.end());
        }

        auto log = [this](gress_t gress){
            if (extracts.count(gress) == 0) return;
            for (const auto& extract : extracts.at(gress)) {
                LOG3("  size=" << extract.size
                  << ", index=" << extract.index
                  << ", type=" << extract.type
                  << ", subtype=" << extract.subtype
                  << ", header=" << extract.hdr
                  << ", offset=" << extract.offset);
                unsigned int i = 0;
                for (const auto& slice : extract.slices) {
                    LOG3("    slice=" << slice);
                    if (i < extract.comments.size())
                        LOG3("      " << extract.comments[i]);
                    ++i;
                }
            }
        };

        if (LOGGING(3)) {
            LOG3("[ComputeFlatrockParserIR] parser extracts:");
            log(INGRESS);
            LOG3("[ComputeFlatrockParserIR] pseudo parser extracts:");
            log(EGRESS);
            LOG3("[ComputeFlatrockParserIR] ingress_intrinsic_metadata has "
                << (igMetaExtracted ? "" : "not ") << "been extracted");
        }

        // FIXME when ingress intrinsic metadata were not extracted or no field from ingress
        // intrinsic metadata is used, all the extracts of ingress intrinsic metadata header
        // are optimized out and we do not generate push hdr for ingress intrinsic metadata
        // which may be needed for correct function in model (model can fail with assert).
    }

 public:
    /**
     * @brief Mapping of parser states to the structures containing all information
     *        needed to create analyzer rules for the given parser states.
     */
    std::map<const IR::BFN::ParserState*, AnalyzerRuleInfo> rules_info;
    /**
     * @brief Information about extracts performed in parser needed to create
     *        corresponding PHV builder extracts.
     */
    std::map<gress_t, std::set<ParserExtract>> extracts;

    ComputeFlatrockParserIR(const PhvInfo& phv, const FieldDefUse& defuse) :
        phv(phv), defuse(defuse) {}
};

/**
 * @brief The pass that replaces an IR::BRN::Parser node with an IR::Flatrock::Parser node
 * @ingroup parde
 *
 * A default profile, which matches all packets, is created.
 * Initial packet and segment length are set to the amount of ingress metadata.
 * All other profile properties and all other parser subcomponents are left unconfigured.
 */
class ReplaceFlatrockParserIR : public ParserTransform {
    static constexpr size_t PARSER_PHV_BUILDER_GROUP_PHES_TOTAL =
        Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_NUM + Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_NUM +
        Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_NUM;
    typedef std::array<IR::Flatrock::PhvBuilderExtract*, PARSER_PHV_BUILDER_GROUP_PHES_TOTAL>
        ExtractArray;
    typedef IR::Vector<IR::Flatrock::PhvBuilderGroup> PhvBuilder;

    mutable cstring initial_state_name;

    void make_analyzer_rules(IR::Flatrock::Parser* lowered_parser,
            const IR::BFN::Parser* parser) const {
        auto graph = parser_info.graph(parser);
        // At this point parser graph has to be an unrolled DAG
        auto states = graph.topological_sort();

        std::vector<IR::Flatrock::AnalyzerStage*> analyzer_stages{};

        unsigned int state_id = 0;

        unsigned int base_stage_id = 0;
        // As a path length we consider the size of the vector of the states in the path,
        // which is 1 for a start state.
        unsigned int path_len = 1;

        unsigned int max_stage_inc = 0;

        for (const auto* state : states) {
            unsigned int state_path_len = graph.longest_path_states_to(state).size();
            cstring state_name = sanitizeName(state->name);
            // 0 -> 0x**************00, 1 -> 0x**************01, etc.
            const match_t state_match = {.word0 = ~0ULL & ~(state_id & 0xffULL),
                                         .word1 = ~0xffULL | state_id};
            // Store mapping into the parser state map
            lowered_parser->states[state_name] = state_match;
            if (initial_state_name.isNullOrEmpty())
                initial_state_name = state_name;

            LOG5("state: " << dbp(state) << std::endl << state);
            LOG5("state_name: " << state_name);
            LOG5("state_match: " << state_match);
            LOG5("state_path_len: " << state_path_len);

            BUG_CHECK(computed.rules_info.count(state) > 0,
                    "Missing information about state: %1%", state);

            if (state_path_len > path_len) {
                path_len = state_path_len;
                base_stage_id += max_stage_inc + 1;
                max_stage_inc = 0;
            }

            // TODO refactor the following to avoid code duplication

            IR::Flatrock::AnalyzerStage* analyzer_stage;
            auto state_info = computed.rules_info.at(state);
            unsigned int stage_id = base_stage_id;
            unsigned int hdr_id = 0;
            // If there no transitions for a given state (final state),
            // we create a stage (rule) for all headers (payload pseudo header
            // in case of final state).
            // If there are some transitions we use the last header in the rules
            // created for the transitions.
            for (; hdr_id + (state_info.transitions.size() > 0 ? 1 : 0) <
                    state_info.push_hdr.size(); ++hdr_id, ++stage_id) {
                // For each header extraction, there is a separate stage
                // Create rule only with push_hdr_id

                // FIXME when stages and rules allocation is optimized, this should
                // be converted to a proper error message
                BUG_CHECK(stage_id < ::Flatrock::PARSER_ANALYZER_STAGES,
                        "Maximum number of analyzer stages (%1%) exceeded",
                        ::Flatrock::PARSER_ANALYZER_STAGES);

                if (stage_id >= analyzer_stages.size()) {
                    analyzer_stage = new IR::Flatrock::AnalyzerStage(stage_id);
                    analyzer_stages.push_back(analyzer_stage);
                    LOG3("Added AnalyzerStage: " << stage_id);
                } else {
                    analyzer_stage = analyzer_stages[stage_id];
                }

                unsigned int rule_id = analyzer_stage->rules.size();

                // FIXME when stages and rules allocation is optimized, this should
                // be converted to a proper error message
                BUG_CHECK(rule_id < ::Flatrock::PARSER_ANALYZER_STAGE_RULES,
                        "Maximum number of analyzer rules (%1%) in stage %2% exceeded",
                        ::Flatrock::PARSER_ANALYZER_STAGE_RULES, stage_id);

                const auto hdr_id_map = parserHeaderSeqs.header_ids.find(
                        {INGRESS, state_info.push_hdr[hdr_id].name});
                BUG_CHECK(hdr_id_map != parserHeaderSeqs.header_ids.end(),
                        "Could not find hdr_id for ingress header: %1%",
                        state_info.push_hdr[hdr_id].name);

                boost::optional<cstring> next_state_name{boost::none};
                if (state_info.transitions.size() > 0)
                    next_state_name = state_name;

                auto* analyzer_rule = new IR::Flatrock::AnalyzerRule(
                    /* id */ rule_id,
                    /* next_state */ boost::none,
                    /* next_state_name */ next_state_name,
                    /* next_w0_offset */ boost::none,
                    /* next_w1_offset */ boost::none,
                    /* next_w2_offset */ boost::none);
                analyzer_rule->push_hdr_id = ::Flatrock::PushHdrId {
                    static_cast<uint8_t>(hdr_id_map->second),
                    static_cast<uint8_t>(state_info.push_hdr[hdr_id].offset)
                };

                analyzer_rule->match_state = state_match;
                analyzer_rule->next_alu0_instruction = Flatrock::alu0_instruction(
                    Flatrock::alu0_instruction::OPCODE_NOOP);
                analyzer_rule->next_alu1_instruction = Flatrock::alu1_instruction(
                    Flatrock::alu1_instruction::OPCODE_NOOP);
                analyzer_stage->rules.push_back(analyzer_rule);
                LOG3("AnalyzerStage[" << analyzer_stage->stage << "] added " << analyzer_rule);
            }

            if (state_info.transitions.size() > 0) {
                // FIXME when stages and rules allocation is optimized, this should
                // be converted to a proper error message
                BUG_CHECK(stage_id < ::Flatrock::PARSER_ANALYZER_STAGES,
                        "Maximum number of analyzer stages (%1%) exceeded",
                        ::Flatrock::PARSER_ANALYZER_STAGES);

                if (stage_id >= analyzer_stages.size()) {
                    analyzer_stage = new IR::Flatrock::AnalyzerStage(stage_id);
                    analyzer_stages.push_back(analyzer_stage);
                    LOG3("Added AnalyzerStage: " << stage_id);
                } else {
                    analyzer_stage = analyzer_stages[stage_id];
                }
            }

            for (const auto& transition : state_info.transitions) {
                unsigned int rule_id = analyzer_stage->rules.size();

                // FIXME when stages and rules allocation is optimized, this should
                // be converted to a proper error message
                BUG_CHECK(rule_id < ::Flatrock::PARSER_ANALYZER_STAGE_RULES,
                        "Maximum number of analyzer rules (%1%) in stage %2% exceeded",
                        ::Flatrock::PARSER_ANALYZER_STAGE_RULES, stage_id);

                boost::optional<::Flatrock::PushHdrId> push_hdr_id{boost::none};
                boost::optional<::Flatrock::ModifyFlag> modify_flag{boost::none};
                if (hdr_id < state_info.push_hdr.size()) {
                    const auto hdr_id_map = parserHeaderSeqs.header_ids.find(
                            {INGRESS, state_info.push_hdr[hdr_id].name});
                    BUG_CHECK(hdr_id_map != parserHeaderSeqs.header_ids.end(),
                            "Could not find hdr_id for ingress header: %1%",
                            state_info.push_hdr[hdr_id].name);
                    push_hdr_id = ::Flatrock::PushHdrId {
                        static_cast<uint8_t>(hdr_id_map->second),
                        static_cast<uint8_t>(state_info.push_hdr[hdr_id].offset)
                    };
                    modify_flag = ::Flatrock::ModifyFlag();
                    modify_flag->imm = true;

                    auto hdr_name = state_info.push_hdr[hdr_id].name;
                    const PHV::Field* valid_field = nullptr;
                    for (const auto& kv : phv.get_all_fields()) {
                        if (kv.second.pov && hdr_name == kv.second.header()) {
                            valid_field = &kv.second;
                        }
                    }

                    if (!valid_field) {
                        LOG1("Could not find $valid for " << hdr_name);
                    } else {
                        auto allocs = phv.get_alloc(valid_field);
                        BUG_CHECK(!allocs.empty(), "Could not find the alloc slice for $valid");
                        PHV::AllocSlice alloc_info = allocs.front();
                        // FIXME: needs to sync with preorder(const IR::BFN::Extract*),
                        //        see the todo there.
                        //        If the number of headers exceeds the width of a single container
                        //        then the pov_flags assignment must match PHV allocation.
                        modify_flag->shift = alloc_info.container_slice().lo;
                    }
                }

                cstring next_state_name = sanitizeName(transition.next_state->name);

                boost::optional<int> next_w0_offset{boost::none};
                boost::optional<int> next_w1_offset{boost::none};
                boost::optional<int> next_w2_offset{boost::none};

                if (transition.next_w.size() > 0)
                    next_w0_offset = transition.next_w[0].offset;
                BUG_CHECK(transition.next_w.size() <= 1,
                        "Only 1 next_w offset is currently supported!");

                auto* analyzer_rule = new IR::Flatrock::AnalyzerRule(
                    /* id */ rule_id,
                    /* next_state */ boost::none,
                    /* next_state_name */ next_state_name,
                    /* next_w0_offset */ next_w0_offset,
                    /* next_w1_offset */ next_w1_offset,
                    /* next_w2_offset */ next_w2_offset);
                analyzer_rule->push_hdr_id = push_hdr_id;
                analyzer_rule->match_state = state_match;
                analyzer_rule->match_w0 = transition.match;
                // update the valid bit in POV flags
                analyzer_rule->modify_flag0 = modify_flag;

                // TODO
                // Check if the width of transition.match is correct, if not
                // report error/bug.
                // Currently a BUG_CHECK in ComputeFlatrockParserIR pass enforces
                // that at most 16 bit wide match values can be processed.
                analyzer_rule->match_w0.setwidth(16);
                // TODO analyzer_rule->match_w1 when supporting more than
                // just one 16 bit match value
                analyzer_rule->next_alu0_instruction = Flatrock::alu0_instruction(
                        Flatrock::alu0_instruction::OPCODE_0,
                        std::vector<int>{/* add */ transition.shift});
                analyzer_rule->next_alu1_instruction = Flatrock::alu1_instruction(
                    Flatrock::alu1_instruction::OPCODE_NOOP);
                analyzer_stage->rules.push_back(analyzer_rule);
                LOG3("AnalyzerStage[" << analyzer_stage->stage << "] added " << analyzer_rule);
            }

            if (hdr_id > max_stage_inc)
                max_stage_inc = hdr_id;
            ++state_id;
        }

        /**
         * Check all rules in a stage if they have the same state.
         * If yes, that state can be used as a stage name.
         */
        for (auto* stage : analyzer_stages) {
            BUG_CHECK(stage->rules.size() > 0, "Unexpected AnalyzerStage without rules: %1%",
                    stage);
            const match_t& match = stage->rules.front()->match_state;
            if (std::all_of(stage->rules.begin(), stage->rules.end(),
                    [&](const IR::Flatrock::AnalyzerRule* r){return r->match_state == match;})) {
                auto it = std::find_if(lowered_parser->states.begin(), lowered_parser->states.end(),
                    [&](const std::pair<const cstring, match_t>& kv){return kv.second == match;});
                if (it != lowered_parser->states.end())
                    stage->name = it->first;
            }
        }

        lowered_parser->analyzer.insert(lowered_parser->analyzer.begin(),
            analyzer_stages.begin(), analyzer_stages.end());
    }

    struct PheInfo {
        /** Container name (B0, B1, ... , H0, H1, ... , W0, W1, ...) */
        std::string container_name;
        /** Index of the PHV builder group which the extract belongs to. */
        size_t phv_builder_group_index;
        /**
         * @brief Number of PHEs per one source in a pair.
         *
         * Each action RAM record specify a pair of PHE sources:
         * - 2x4 PHE8 sources or
         * - 2x2 PHE16 sources or
         * - 2x1 PHE32 sources
         *
         * This field is a number of PHEs per one source in a pair.
         * PHE8 sources - 4
         * PHE16 sources - 2
         * PHE32 sources - 1
         */
        size_t phe_sources;
    };

    PheInfo get_phe_info(const ParserExtract& extract) const {
        size_t phe_sources = 0;
        size_t base_group_index = 0;  // index within PHE8/16/32 groups
        std::string container_name;

        if (extract.size == PHV::Size::b8) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES;
            base_group_index = 0;
            container_name = "B";
        } else if (extract.size == PHV::Size::b16) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES;
            base_group_index = Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_NUM;
            container_name = "H";
        } else if (extract.size == PHV::Size::b32) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE32_SOURCES;
            base_group_index = Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_NUM +
                               Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_NUM;
            container_name = "W";
        } else {
            BUG("Invalid container size in PHV builder extractor");
        }

        const auto sub_group_offset =
            extract.index / phe_sources / Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES;
        const auto group_index = base_group_index + sub_group_offset;
        container_name += std::to_string(extract.index);

        return PheInfo{container_name, group_index, phe_sources};
    }

    void add_offsets(std::vector<Flatrock::ExtractInfo>& offsets, const std::string container_name,
                     const ParserExtract& extract) const {
        constexpr auto BITS_IN_BYTE = 8;
        const auto size = static_cast<int>(extract.size);

        // Large constants need to be split into 1-byte slices. Slice suffix is also added to 1-byte
        // constants placed in larger containers.
        if (extract.subtype == Flatrock::ExtractSubtype::Constant && size > BITS_IN_BYTE) {
            const auto constant = static_cast<unsigned int>(extract.offset);
            for (const auto &slice : extract.slices) {
                for (auto i_lo = slice.hi + 1 - BITS_IN_BYTE; i_lo >= slice.lo;
                        i_lo -= BITS_IN_BYTE) {
                    const auto offset = (constant >> i_lo) & 0xff;

                    const auto i_hi = i_lo + BITS_IN_BYTE - 1;
                    const auto suffix =
                        '(' + std::to_string(i_lo) + ".." + std::to_string(i_hi) + ')';

                    offsets.push_back(
                        {container_name + suffix, static_cast<int>(offset), extract.subtype});
                }
            }
        } else {
            offsets.push_back({container_name, extract.offset, extract.subtype});
        }
    }

    ExtractArray make_builder_extracts(gress_t gress) const {
        // Array of extracts with index 0 for all PHV builder groups
        // Index to this array is in fact PHV builder group index
        ExtractArray extracts {};
        if (computed.extracts.count(gress) == 0) return extracts;
        for (const auto& extract : computed.extracts.at(gress)) {
            const auto phe_info = get_phe_info(extract);

            // Get extract with index 0 for a given PHV builder group
            auto& phv_builder_extract = extracts[phe_info.phv_builder_group_index];
            if (phv_builder_extract == nullptr)
                phv_builder_extract = new IR::Flatrock::PhvBuilderExtract(extract.size);

            /**
             * Each PHV builder group extract specifies a pair of PHE sources.
             * Each PHE source specifies:
             * - 4 PHE8 sources or
             * - 2 PHE16 sources or
             * - 1 PHE32 source
             * Values for each PHE source (4xPHE8 / 2xPHE16 / 1xPHE32) in the pair are
             * stored in one element of 'source' array
             */
            phv_builder_extract->index = 0;
            const auto index = extract.index;
            const auto phe_sources = phe_info.phe_sources;
            const auto phe_source_index =
                    (index / phe_sources) % Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES;
            phv_builder_extract->source[phe_source_index].type = extract.type;
            phv_builder_extract->source[phe_source_index].hdr_name = extract.hdr;
            add_offsets(phv_builder_extract->source[phe_source_index].offsets,
                    phe_info.container_name, extract);
            phv_builder_extract->source[phe_source_index].debug.info.insert(
                    phv_builder_extract->source[phe_source_index].debug.info.end(),
                    extract.comments.begin(), extract.comments.end());
        }

        return extracts;
    }

    void build_phv_builder(PhvBuilder& phv_builder, gress_t gress) const {
        const auto extracts = make_builder_extracts(gress);
        int id = 0;
        for (const auto* extract : extracts) {
            if (extract != nullptr) {
                auto* phv_builder_group = new IR::Flatrock::PhvBuilderGroup(
                    /* id */ id, /* pov_select */ {});
                phv_builder_group->extracts.push_back(extract);
                phv_builder.push_back(phv_builder_group);
            }
            ++id;
        }
    }

    IR::Flatrock::Profile* get_default_profile(const cstring& initial_state_name) const {
        auto* default_profile = new IR::Flatrock::Profile(
            /* index */ 0,
            /* initial_pktlen */ 0,
            /* initial_seglen */ 0,
            /* initial_state */ boost::none,
            /* initial_state_name */ initial_state_name,
            /* initial_flags */ boost::none,
            /* initial_ptr */ 0,  // Extraction of ingress intrinsic metadata is always expected
            /* initial_w0_offset */ boost::none,
            /* initial_w1_offset */ boost::none,
            /* initial_w2_offset */ boost::none);
        // {is_pktgen(1bit),port_id(7bit),8'b0}
        default_profile->metadata_select.push_back(
            Flatrock::metadata_select(Flatrock::metadata_select::LOGICAL_PORT_NUMBER, {}));
        default_profile->metadata_select.push_back(
            Flatrock::metadata_select(Flatrock::metadata_select::PORT_METADATA, {/* index */ 0}));
        // timestamp
        for (int i = Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_BYTE_OFFSET;
             i < Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_BYTE_OFFSET +
                     Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_BYTE_WIDTH;
             i++) {
            default_profile->metadata_select.push_back(Flatrock::metadata_select(
                Flatrock::metadata_select::INBAND_METADATA, {/* index */ i}));
        }

        return default_profile;
    }

    void make_profiles(IR::Flatrock::Parser *lowered_parser) const {
        BUG_CHECK(!initial_state_name.isNullOrEmpty(),
                "Expecting at least 1 parser state, but no parser state is present");
        lowered_parser->profiles.push_back(get_default_profile(initial_state_name));
    }

    const IR::Flatrock::Parser* preorder(IR::BFN::Parser* parser) override {
        LOG4("[ReplaceFlatrockParserIR] lowering Flatrock parser " << parser->name);
        const auto* orig_parser = getOriginal<IR::BFN::Parser>();

        auto* lowered_parser = new IR::Flatrock::Parser;
        make_analyzer_rules(lowered_parser, orig_parser);
        build_phv_builder(lowered_parser->phv_builder, INGRESS);
        make_profiles(lowered_parser);

        return lowered_parser;
    }

    const IR::BFN::Pipe* postorder(IR::BFN::Pipe* pipe) override {
        BUG_CHECK(pipe->thread[EGRESS].parsers.size() == 0,
            "unexpected egress parser before lowering");

        // Create a pseudo parser
        auto *pseudo_parser = new IR::Flatrock::PseudoParser;
        build_phv_builder(pseudo_parser->phv_builder, EGRESS);
        pipe->thread[EGRESS].parsers.push_back(pseudo_parser);

        return pipe;
    }

    const PhvInfo& phv;
    const ComputeFlatrockParserIR& computed;
    const ParserHeaderSequences& parserHeaderSeqs;
    const CollectParserInfo& parser_info;

 public:
    explicit ReplaceFlatrockParserIR(const PhvInfo& phv, const ComputeFlatrockParserIR& computed,
            const ParserHeaderSequences& phs, const CollectParserInfo& pi) :
        phv(phv), computed(computed), parserHeaderSeqs(phs), parser_info(pi) {}
};

#endif  // HAVE_FLATROCK

/**
 * @brief The pass that replaces an IR::BRN::Parser node with an IR::BFN::LoweredParser node
 * @ingroup parde
 *
 * Replace the high-level parser IR version of each parser's root node with its
 * lowered version. This has the effect of replacing the entire parse graph.
 */
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
          new IR::BFN::LoweredParser(parser->gress, computed.loweredStates.at(parser->start),
                                     parser->phase0, parser->name, parser->portmap);

        if (parser->gress == INGRESS) {
            loweredParser->hdrLenAdj = Device::pardeSpec().byteTotalIngressMetadataSize();
        } else {
            loweredParser->metaOpt = computed.egressMetaOpt;
            loweredParser->hdrLenAdj = computed.egressMetaSize;
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
        std::vector<Clot*> clots;

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

        auto rv = new IR::BFN::ConstantRVal(totalBytes);
        return rv;
    }

 public:
    ResolveParserConstants(const PhvInfo& phv, const ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) { }
};

// If before parser lowering, a state is empty and has unconditional transition
// leaving the state, we can safely eliminate this state.
struct ElimEmptyState : public ParserTransform {
    const CollectParserInfo& parser_info;

    explicit ElimEmptyState(const CollectParserInfo& pi) : parser_info(pi) { }

    bool is_empty(const IR::BFN::ParserState* state) {
        if (!state->selects.empty())
            return false;

        if (!state->statements.empty())
            return false;

        for (auto t : state->transitions) {
            if (!t->saves.empty())
                return false;
        }

        if (state->name.find(".$ctr_stall"))  // compiler generated stall
            return false;

        if (state->name.endsWith("$hdr_len_stop_stall"))  // compiler generated stall
            return false;
        auto parser = findOrigCtxt<IR::BFN::Parser>();
        // do not merge loopback state for now, need to maitain loopback pointer TODO
        // p4-tests/p4_16/compile_only/p4c-2153.p4
        if (parser_info.graph(parser).is_loopback_state(state->name))
            return false;

        return true;
    }

    const IR::BFN::Transition*
    get_unconditional_transition(const IR::BFN::ParserState* state) {
        if (state->transitions.size() == 1) {
            auto t = state->transitions[0];
            if (auto match = t->value->to<IR::BFN::ParserConstMatchValue>()) {
                if (match->value == match_t()) {
                    return t;
                }
            }
        }

        return nullptr;
    }

    IR::Node* preorder(IR::BFN::Transition* transition) override {
        if (transition->next && is_empty(transition->next)) {
            if (auto next = get_unconditional_transition(transition->next)) {
                if (int(transition->shift + next->shift) <=
                    Device::pardeSpec().byteInputBufferSize()) {
                    LOG3("elim empty state " << transition->next->name);
                    transition->next = next->next;
                    transition->shift += next->shift;
                }
            }
        }

        return transition;
    }
};

/// Find all of the states that do a checksum deposit
/// but also does not extract/shift before doing it
/// (= the end_pos is negative) and also
/// all of the states from which we can get via 0 shift to
/// a state that does this negative checksum deposit
struct FindNegativeDeposits : public ParserInspector {
 public:
    std::set<cstring> states_to_shift;

    FindNegativeDeposits() { }

 private:
    // Find any csum deposit with negative transition and add it's parser state
    void postorder(const IR::BFN::ChecksumResidualDeposit* crd) override {
        auto ps = findContext<IR::BFN::ParserState>();
        if (!ps)
            return;
        if (crd->header_end_byte && crd->header_end_byte->range.lo < 0) {
            LOG5("FindNegativeDeposits: State "<< ps->name <<
                    " tagged to be updated as it does negative deposit.");
            states_to_shift.insert(ps->name);
        }
    }

    // Tag also all of the parser states with zero shift leading to an added state
    // (to find and include every state after the last extract)
    void postorder(const IR::BFN::Transition* t) override {
        if (t->shift != 0 || !t->next || !states_to_shift.count(t->next->name))
            return;
        auto ps = findContext<IR::BFN::ParserState>();
        if (!ps)
            return;
        LOG5("FindZeroShiftDeposits: State "<< ps->name <<
             " tagged to be updated since we can get to a negative deposit via 0 shift.");
        states_to_shift.insert(ps->name);
    }
};

/// Update the IR so that every checksum deposit can also
/// shift by at least one.
/// To do this for any state that does a negative deposit
/// we change the shift to 1 and decrease any shifts in the states
/// leading into this one.
struct RemoveNegativeDeposits : public ParserTransform {
    const FindNegativeDeposits& found;

    explicit RemoveNegativeDeposits(const FindNegativeDeposits& found) :
        found(found) { }

 private:
    // Update any transition leading to the tagged state to leave 1 byte
    IR::Node* preorder(IR::BFN::Transition* tr) {
        if (tr->shift == 0 || !tr->next || !found.states_to_shift.count(tr->next->name))
            return tr;
        auto new_tr = tr->clone();
        new_tr->shift = tr->shift - 1;
        auto ps = findContext<IR::BFN::ParserState>();
        LOG4("RemoveNegativeDeposits: Transition from " << (ps ? ps->name : "--unknown--") <<
             " to " << tr->next->name << " changed shift: " <<
             tr->shift << "->" << new_tr->shift);
        return new_tr;
    }

    // Shift PacketRVals in every state that was found by one byte
    // Also update transitions from this state that lead outside of the tagged path
    // to shift by one more byte (to get rid of the extra 1 byte left over)
    IR::Node* preorder(IR::BFN::ParserState* ps) {
        if (!found.states_to_shift.count(ps->name))
            return ps;
        const int shift_amt = -8;
        auto new_ps = ps->clone();
        LOG4("RemoveNegativeDeposits: Shifting every PacketRVal in state " << ps->name <<
             " by one byte.");
        new_ps->statements = *(new_ps->statements.apply(ShiftPacketRVal(shift_amt)));
        new_ps->selects = *(new_ps->selects.apply(ShiftPacketRVal(shift_amt)));
        IR::Vector<IR::BFN::Transition> new_transitions;
        for (auto tr : ps->transitions) {
            auto new_tr = tr->clone();
            // Decrease only shifts leading outside of the tagged path
            // Inside the tagged path (= shift of 0 to the actual csum state)
            // we want to propagate the single extra unshifted byte
            if (!tr->next || !found.states_to_shift.count(tr->next->name)) {
                new_tr->shift = tr->shift - shift_amt/8;
                LOG4("RemoveNegativeDeposits: Transition from " << ps->name << " to " <<
                     (tr->next ? tr->next->name : "--END--") <<
                     " changed: " << tr->shift << "->" << new_tr->shift);
            }
            new_tr->saves = *(new_tr->saves.apply(ShiftPacketRVal(shift_amt)));
            new_transitions.push_back(new_tr);
        }
        new_ps->transitions = new_transitions;
        return new_ps;
    }
};

// After parser lowering, we have converted the parser IR from P4 semantic (action->match)
// to HW semantic (match->action), there may still be opportunities where we can merge states
// where we couldn't before lowering (without breaking the P4 semantic).
struct MergeLoweredParserStates : public ParserTransform {
    const CollectLoweredParserInfo& parser_info;
    const ComputeLoweredParserIR& computed;
    ClotInfo &clot;
    PhvLogging::CollectDefUseInfo *defuseInfo;

    explicit MergeLoweredParserStates(const CollectLoweredParserInfo& pi,
                                      const ComputeLoweredParserIR& computed,
                                      ClotInfo &c,
                                      PhvLogging::CollectDefUseInfo *defuseInfo)
        : parser_info(pi), computed(computed), clot(c), defuseInfo(defuseInfo) { }

    // Compares all fields in two LoweredParserMatch objects
    // except for the match values.  Essentially returns if both
    // LoweredParserMatch do the same things when matching.
    //
    // Equivalent to IR::BFN::LoweredParserMatch::operator==(IR::BFN::LoweredParserMatch const & a)
    // but considering the loop fields and with the value fields masked off.
    bool
    compare_match_operations(const IR::BFN::LoweredParserMatch*a,
                             const IR::BFN::LoweredParserMatch*b) {
        return a->shift == b->shift &&
               a->hdrLenIncFinalAmt == b->hdrLenIncFinalAmt &&
               a->extracts == b->extracts &&
               a->saves == b->saves &&
               a->scratches == b->scratches &&
               a->checksums == b->checksums &&
               a->counters == b->counters &&
               a->priority == b->priority &&
               a->partialHdrErrProc == b->partialHdrErrProc &&
               a->bufferRequired == b->bufferRequired &&
               a->next == b->next &&
               a->offsetInc == b->offsetInc &&
               a->loop == b->loop;
    }

    const IR::BFN::LoweredParserMatch*
    get_unconditional_match(const IR::BFN::LoweredParserState* state) {
        if (state->transitions.size() == 0)
            return nullptr;

        if (state->select->regs.empty() && state->select->counters.empty())
            return state->transitions[0];

        // Detect if all transitions actually do the same thing and branch/loop to
        // the same state.  That represents another type of unconditional match.
        auto first_transition = state->transitions[0];
        for (auto &transition : state->transitions) {
            if (!compare_match_operations(first_transition, transition))
                return nullptr;
        }

        return state->transitions[0];
    }

    struct RightShiftPacketRVal : public Modifier {
        int byteDelta = 0;
        bool oob = false;
        explicit RightShiftPacketRVal(int byteDelta) : byteDelta(byteDelta) { }
        bool preorder(IR::BFN::LoweredPacketRVal* rval) override {
            rval->range = rval->range.shiftedByBytes(byteDelta);
            BUG_CHECK(rval->range.lo >= 0, "Shifting extract to negative position.");
            if (rval->range.hi >= Device::pardeSpec().byteInputBufferSize())
                oob = true;
            return true;
        }
    };

    // Checksum also needs the masks to be shifted
    struct RightShiftCsumMask : public Modifier {
        int byteDelta = 0;
        bool oob = false;
        bool swapMalform = false;

        explicit RightShiftCsumMask(int byteDelta) : byteDelta(byteDelta) { }

        bool preorder(IR::BFN::LoweredParserChecksum* csum) override {
            if (byteDelta == 0 || oob || swapMalform)
                return false;
            std::set<nw_byterange> new_masked_ranges;
            for (auto m : csum->masked_ranges) {
                nw_byterange new_m(m.lo, m.hi);
                new_m = m.shiftedByBytes(byteDelta);
                BUG_CHECK(new_m.lo >= 0, "Shifting csum mask to negative position.");
                if (new_m.hi >= Device::pardeSpec().byteInputBufferSize()) {
                    oob = true;
                    return false;
                }
                new_masked_ranges.insert(new_m);
            }
            csum->masked_ranges = new_masked_ranges;
            // We can only shift fullzero or fullones swap by odd number of bytes
            // Let's assume we have the following csum computation:
            // mask: [ 0, 1, 2..3, ...]
            // swap: 0b0...01
            // This essentially means that the actual computation should work with
            // the following order of the bytes:
            // 1 0 2 3
            // Now we shift is by 1 byte:
            // mask: [ 1, 2, 3..4, ...]
            // This gives us the following order of bytes that we need:
            // 2 1 3 4
            // This means that byte 2 needs to be taken as the top byte, but
            // also the byte 3 needs to be taken as the top byte, which is impossible.
            // swap: 0b1...101 uses the wrong position of byte 3
            // swap: 0b1...111 uses the wrong position of byte 2
            if ((byteDelta % 2) && csum->swap != 0 && csum->swap != ~(unsigned)0) {
                swapMalform = true;
                return false;
            }
            // Update swap vector (it needs to be shifted by half of byteDelta)
            csum->swap = csum->swap << byteDelta/2;
            // Additionally if we shifted by an odd ammount we need to negate the swap
            if (byteDelta % 2)
                csum->swap = ~csum->swap;
            if (csum->end) {
                BUG_CHECK(-byteDelta <= (int)csum->end_pos,
                          "Shifting csum end to negative position.");
                csum->end_pos += byteDelta;
                if (csum->end_pos >= (unsigned)Device::pardeSpec().byteInputBufferSize()) {
                    oob = true;
                    return false;
                }
            }
            return true;
        }
    };

    bool can_merge(const IR::BFN::LoweredParserMatch* a, const IR::BFN::LoweredParserMatch* b) {
        if (a->hdrLenIncFinalAmt || b->hdrLenIncFinalAmt)
            return false;

        if (computed.dontMergeStates.count(a->next) || computed.dontMergeStates.count(b->next))
            return false;

        if (a->priority && b->priority)
            return false;

        if (a->offsetInc && b->offsetInc)
            return false;

        if ((!a->extracts.empty() || !a->saves.empty() ||
             !a->checksums.empty() || !a->counters.empty()) &&
            (!b->extracts.empty() || !b->saves.empty() ||
             !b->checksums.empty() || !b->counters.empty()))
            return false;

        // Checking partialHdrErrProc in both parser match might be a bit
        // restrictive given that two states that both have extracts
        // and/or saves will not be merged (see check above), but it
        // prevents merging two match with incompatible partial header
        // settings.
        if (a->partialHdrErrProc != b->partialHdrErrProc)
            return false;

        if (int(a->shift + b->shift) > Device::pardeSpec().byteInputBufferSize())
            return false;

        RightShiftPacketRVal shifter(a->shift);
        RightShiftCsumMask csum_shifter(a->shift);

        for (auto e : b->extracts)
            e->apply(shifter);

        for (auto e : b->saves)
            e->apply(shifter);

        for (auto e : b->checksums) {
            e->apply(shifter);
            e->apply(csum_shifter);
        }

        for (auto e : b->counters)
            e->apply(shifter);

        if (shifter.oob || csum_shifter.oob || csum_shifter.swapMalform)
            return false;

        return true;
    }

    void do_merge(IR::BFN::LoweredParserMatch* match,
                  const IR::BFN::LoweredParserMatch* next) {
        RightShiftPacketRVal shifter(match->shift);
        RightShiftCsumMask csum_shifter(match->shift);

        for (auto e : next->extracts) {
            auto s = e->apply(shifter);
            match->extracts.push_back(s->to<IR::BFN::LoweredParserPrimitive>());
        }

        for (auto e : next->saves) {
            auto s = e->apply(shifter);
            match->saves.push_back(s->to<IR::BFN::LoweredSave>());
        }

        for (auto e : next->checksums) {
            auto s = e->apply(shifter);
            auto cs = s->apply(csum_shifter);
            match->checksums.push_back(cs->to<IR::BFN::LoweredParserChecksum>());
        }

        for (auto e : next->counters) {
            auto s = e->apply(shifter);
            match->counters.push_back(s->to<IR::BFN::ParserCounterPrimitive>());
        }

        match->loop = next->loop;
        match->next = next->next;
        match->shift += next->shift;

        if (!match->priority)
            match->priority = next->priority;

        match->partialHdrErrProc = next->partialHdrErrProc;

        if (!match->offsetInc)
            match->offsetInc = next->offsetInc;
    }

    // do not merge loopback state for now, need to maitain loopback pointer TODO
    // p4-tests/p4_16/compile_only/p4c-1601-neg.p4
    bool is_loopback_state(cstring state) {
        auto parser = findOrigCtxt<IR::BFN::LoweredParser>();
        if (parser_info.graph(parser).is_loopback_state(state))
            return true;

        return false;
    }

    IR::Node* preorder(IR::BFN::LoweredParserMatch* match) override {
        auto state = findOrigCtxt<IR::BFN::LoweredParserState>();
        if (computed.dontMergeStates.count(state)) {
            return match;
        }

        while (match->next) {
            // Attempt merging states if the next state is not loopback
            // and not a compiler-generated stall state.
            std::string next_name(match->next->name.c_str());
            if (!is_loopback_state(match->next->name) &&
                !((next_name.find("$") != std::string::npos) &&
                  (next_name.find("stall") != std::string::npos) &&
                  (next_name.find("$") < next_name.rfind("stall")))) {
                if (auto next = get_unconditional_match(match->next)) {
                    if (can_merge(match, next)) {
                        LOG3("merge " << match->next->name << " with "
                                << state->name << " (" << match->value << ")");

                        // Clot update must run first because do_merge changes match->next
                        if (Device::numClots() > 0 && BackendOptions().use_clot)
                            clot.merge_parser_states(state->thread(), state->name,
                                                     match->next->name);
                        if (defuseInfo)
                            defuseInfo->replace_parser_state_name(
                                createThreadName(match->next->thread(), match->next->name),
                                createThreadName(state->thread(), state->name));
                        do_merge(match, next);
                        continue;
                    }
                }
            }
            break;
        }
        return match;
    }
};

class InsertPayloadPseudoHeaderState : public ParserTransform {
    const IR::BFN::ParserState *payload_header_state;

    profile_t init_apply(const IR::Node *node) override {
        payload_header_state = new IR::BFN::ParserState(
            payloadHeaderStateName, INGRESS,
            IR::Vector<IR::BFN::ParserPrimitive>(
                {new IR::Flatrock::ExtractPayloadHeader(payloadHeaderName)}),
            IR::Vector<IR::BFN::Select>(),
            IR::Vector<IR::BFN::Transition>());
        return Transform::init_apply(node);
    }

    const IR::BFN::Transition* preorder(IR::BFN::Transition *t) override {
        if (t->next == nullptr) {
            t->next = payload_header_state;
            LOG3("Inserting transition to payload pseudo header state from state: " <<
                    findContext<IR::BFN::ParserState>());
        }
        return t;
    }
 public:
    InsertPayloadPseudoHeaderState() {}
};

/**
 * @brief This pass is used to ensure that there will be no conflicting partial_hdr_err_proc
 *        at the time the LoweredParserMatch is created.
 *
 * This pass makes sure that each parser state respects the following constraints:
 *
 *      1. A state includes only extract statements in which PacketRVal have same
 *         partial_hdr_err_proc;
 *
 *      2. When a state includes both extracts and transitions, the partial_hdr_err_proc
 *         from the extracts (which are all the same according to 1.) are the same
 *         as the PacketRVal in select() statements from the next states.
 *
 * Constraint 1 is pretty simple; since there is only a single partial_hdr_err_proc
 * in the LoweredParserMatch node, two extracts must have the same setting in order
 * not to conflict.
 *
 * Constraint 2 exists because load operations issued from select statements in next
 * states are typically moved up to the current state to prepare the data for the
 * match that will occur in the next state.  The field that is referenced in these
 * select statements must have the same partial_hdr_err_proc as the extracts in the
 * current state in order not to conflict.
 *
 * States that do not respect these constraints are split in states that do, starting
 * from the ones that are further down the tree and going upwards.  When a select is
 * moved from the current state to a new state, to reduce the number of states created,
 * extracts that are compatible with that select are moved also to that new state
 * as long as the original extract order is respected.  In other words, if the compatible
 * extracts are the last ones in the current state, before the select.
 *
 */
struct SplitGreedyParserStates : public Transform {
    SplitGreedyParserStates() {}

 private:
    /**
     * @brief Creates a greedy stall state based on partial_hdr_err_proc settings
     *        in the statements, selects and transitions.
     *
     * The state that is created comes after the state provided in input and is
     * garanteed to include partial_hdr_err_proc settings that are compatible
     * with each other.
     *
     * Checking that state has incompatible partial_hdr_err_proc settings
     * has to be done prior to calling this function.
     *
     */
    IR::BFN::ParserState* split_state(IR::BFN::ParserState* state, cstring new_state_name) {
        LOG4("  Greedy split for state " << state->name << " --> " << new_state_name);
        IR::Vector<IR::BFN::ParserPrimitive> first_statements;
        IR::Vector<IR::BFN::ParserPrimitive> last_statements;
        boost::optional<bool> last_statements_partial_proc = boost::none;
        int last_statements_shift_bits = 0;

        // Create "first" and "last" vectors and retrieve the last_statements_partial_proc
        // which will be used to decide how to split the state.
        //
        split_statements(state->statements, first_statements, last_statements,
                         last_statements_shift_bits, last_statements_partial_proc);

        // Check if transitions refer to states that all have compatible
        // partial_hdr_err_proc values.
        //
        boost::optional<bool> transitions_partial_proc = boost::none;
        auto transitions_verify = partial_hdr_err_proc_verify(nullptr, nullptr,
                                                              &state->transitions,
                                                              &transitions_partial_proc);

        IR::Vector<IR::BFN::ParserPrimitive> next_state_statements;
        IR::Vector<IR::BFN::ParserPrimitive> new_state_statements;
        int new_transitions_shift_bits = 0;

        if (!transitions_verify ||
            (last_statements_partial_proc && transitions_partial_proc &&
             *transitions_partial_proc!=*last_statements_partial_proc)) {
            // Here, either:
            //
            //  - the transition partial_hdr_err_proc values are incompatible with each other, or;
            //  - the transition partial_hdr_err_proc values are all compatible with each other,
            //    but incompatible with the last extract in the statements.
            //
            // In this case create a next state with only the select and the transitions.
            // Keep all statements in the new state that will replace the current state.
            //
            next_state_statements = IR::Vector<IR::BFN::ParserPrimitive>();
            new_state_statements = state->statements;
            new_transitions_shift_bits = state->transitions.at(0)->shift<<3;
        } else {
            // Here, all transitions are compatible with each other and they are compatible
            // with the last extract in the statements.
            //
            // Create a next state with the last statements, the select and the transitions.
            // Add the first statements to the new state that will replace the current state.
            //
            next_state_statements = last_statements;
            new_state_statements = first_statements;
            new_transitions_shift_bits = (state->transitions.at(0)->shift<<3) -
                                         last_statements_shift_bits;
        }

        // Create next_state guaranteed to have partial_hdr_err_proc compatible with
        // each other.
        //
        IR::BFN::ParserState* next_state = new IR::BFN::ParserState(new_state_name,
                                                            state->gress,
                                                            IR::Vector<IR::BFN::ParserPrimitive>(),
                                                            IR::Vector<IR::BFN::Select>(),
                                                            IR::Vector<IR::BFN::Transition>());

        // Add statements to next state, while adjusting range values
        // when required.
        for (auto& statement : next_state_statements) {
            if (auto* extract = statement->to<IR::BFN::Extract>()) {
                if (auto* pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                    LOG4("  Adjusting extract from [" << pkt_rval->range.lo << ".."
                            << pkt_rval->range.hi << "] to ["
                            << pkt_rval->range.lo-new_transitions_shift_bits
                            << ".." << pkt_rval->range.hi-new_transitions_shift_bits << "]");
                    nw_bitrange next_range(pkt_rval->range.lo-new_transitions_shift_bits,
                                           pkt_rval->range.hi-new_transitions_shift_bits);
                    auto next_pkt_rval = new IR::BFN::PacketRVal(next_range,
                                                            pkt_rval->partial_hdr_err_proc);
                    auto next_extract = new IR::BFN::Extract(extract->dest, next_pkt_rval);
                    next_state->statements.push_back(next_extract);
                } else
                    next_state->statements.push_back(statement);
            } else
                next_state->statements.push_back(statement);
        }

        // Add selects to next state and adjust ranges.
        for (auto select : state->selects) {
            if (auto* saved = select->source->to<IR::BFN::SavedRVal>()) {
                if (auto* pkt_rval = saved->source->to<IR::BFN::PacketRVal>()) {
                    LOG4("  Adjusting select from [" << pkt_rval->range.lo
                            << ".." << pkt_rval->range.hi << "] to ["
                            << pkt_rval->range.lo-new_transitions_shift_bits
                            << ".." << pkt_rval->range.hi-new_transitions_shift_bits << "]");
                    nw_bitrange next_range(pkt_rval->range.lo-new_transitions_shift_bits,
                                           pkt_rval->range.hi-new_transitions_shift_bits);
                    auto next_pkt_rval = new IR::BFN::PacketRVal(next_range,
                                                                 pkt_rval->partial_hdr_err_proc);
                    auto next_select = new IR::BFN::Select(new IR::BFN::SavedRVal(next_pkt_rval));
                    next_state->selects.push_back(next_select);
                } else {
                    next_state->selects.push_back(select);
                }
            } else
                next_state->selects.push_back(select);
        }

        // Add transitions to next state and adjust shifts.
        for (auto transition : state->transitions) {
            auto next_transition = new IR::BFN::Transition(transition->value,
                                                transition->shift-(new_transitions_shift_bits>>3),
                                                transition->next);
            next_state->transitions.push_back(next_transition);
        }

        // Create new_state that replaces state that is provided in input and that includes
        // the statements that were not moved to next_state.  The partial_hdr_err_proc
        // might not be all compatible at this point, if that's the case this is going
        // to be fixed on the next iteration.
        //
        IR::BFN::Transition* new_transition = new IR::BFN::Transition( match_t(),
                                                                    new_transitions_shift_bits>>3,
                                                                    next_state);
        IR::BFN::ParserState* new_state = new IR::BFN::ParserState(state->name, state->gress,
                                                new_state_statements, IR::Vector<IR::BFN::Select>(),
                                                IR::Vector<IR::BFN::Transition>(new_transition));
        return new_state;
    }

    /**
     * @brief Split statements from vector "in" such that the "last" vector
     *        contains only statements that have partial_hdr_err_proc settings
     *        that are the same with each other.  Does not modify the statements
     *        order.
     *
     * On return:
     *
     *      first: the statements from vector "in" which partial_hdr_err_proc are
     *             not compatible with the ones returned in vector "last".  This
     *             vector can include statements with conflicting partial_hdr_err_proc
     *             values.
     *
     *      last: the statements from vector "in" with partial_hdr_err_proc that are
     *            compatible with the last extract in the state.  All statements in
     *            this vector are no-conflicting with each other.
     *
     *      last_statements_shift_bit: total shift in bits of the statements included
     *                                 in vector "last".
     *
     *      last_statements_partial_proc: the setting of partial_hdr_err_proc of the statements
     *                                    included in vector "last".  Set to boost::none if
     *                                    no extract with partial_hdr_err_proc were found
     *                                    in vector "in".
     *
     */
    void split_statements(const IR::Vector<IR::BFN::ParserPrimitive> in,
                          IR::Vector<IR::BFN::ParserPrimitive> &first,
                          IR::Vector<IR::BFN::ParserPrimitive> &last,
                          int &last_statements_shift_bit,
                          boost::optional<bool> &last_statements_partial_proc) {
        boost::optional<bool> curr_partial_proc = boost::none;
        int curr_statements_shift_bit = 0;

        first.clear();
        last.clear();
        last_statements_shift_bit = 0;
        last_statements_partial_proc = boost::none;

        for (auto statement : in) {
            if (auto* extract = statement->to<IR::BFN::Extract>()) {
                // Look for change in partial_hdr_err_proc compared to the previous value.
                if (auto* pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                    bool extract_partial_hdr_proc = pkt_rval->partial_hdr_err_proc;
                    if (!curr_partial_proc || (extract_partial_hdr_proc != *curr_partial_proc)) {
                        first.append(last);
                        last.clear();
                        curr_statements_shift_bit = pkt_rval->range.lo;
                        curr_partial_proc = extract_partial_hdr_proc;
                    }
                    last_statements_shift_bit = pkt_rval->range.hi - curr_statements_shift_bit;
                }
            }
            last.push_back(statement);
        }
        last_statements_partial_proc = curr_partial_proc;

        if (last_statements_shift_bit) last_statements_shift_bit+=1;

        if (LOGGING(4)) {
            LOG4("  Greedy statements split");
            LOG4("    First: ");
            for (auto s : first) {
                LOG4("      " << s);
            }
            LOG4("    Last: ");
            for (auto s : last) {
                LOG4("      " << s);
            }
            LOG4("    Last primitive partial_hdr_err_proc is "
                    << (last_statements_partial_proc ?
                            std::to_string(*last_statements_partial_proc):"(nil)")
                    << " last statements shift in bits is " << last_statements_shift_bit);
        }
    }

    /**
     * @brief Checks that the partial_hdr_err_proc setting is the
     *        same for all vector content provided in input.  Skip
     *        check for vectors which pointer is set to nullptr.
     *
     * On return:
     *      false:   partial_hdr_err_proc are conflicting.
     *      true:    partial_hdr_err_proc are non-conflicting.
     *
     *      partial_proc_value:  when returned value is true (i.e. all partial_hdr_err_proc are
     *                           non-conflicting), contains the value of those
     *                           partial_hdr_err_proc.  Returns boost::none if none of the
     *                           statements contained any partial_hdr_err_proc field.
     *
     */
    bool partial_hdr_err_proc_verify(const IR::Vector<IR::BFN::ParserPrimitive> *statements,
                                     const IR::Vector<IR::BFN::Select> *selects,
                                     const IR::Vector<IR::BFN::Transition> *transitions,
                                     boost::optional<bool> *partial_proc_value = nullptr){
        boost::optional<bool> value = boost::none;
        if (partial_proc_value)
            *partial_proc_value = boost::none;

        if (statements) {
            for (auto statement : *statements) {
                if (auto* extract = statement->to<IR::BFN::Extract>())
                    if (auto* pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                        auto v = pkt_rval->partial_hdr_err_proc;
                        if (value && *value != v) return false;
                        value = v;
                    }
            }
        }

        if (selects) {
            for (auto select : *selects) {
                if (auto* saved = select->source->to<IR::BFN::SavedRVal>())
                    if (auto* pkt_rval = saved->source->to<IR::BFN::PacketRVal>()) {
                        auto v = pkt_rval->partial_hdr_err_proc;
                        if (value && *value != v ) return false;
                        value = v;
                    }
            }
        }

        if (transitions) {
            for (auto transition : *transitions){
                if (auto next_state = transition->next) {
                    boost::optional<bool> v = boost::none;
                    if (partial_hdr_err_proc_verify(nullptr, &next_state->selects, nullptr, &v)) {
                        if (v) {
                            if (value && *value != *v) return false;
                            value = *v;
                        }
                    } else
                        return false;
                }
            }
        }

        if (partial_proc_value)
            *partial_proc_value = value;

        return true;
    }

    /**
     * @brief Checks if the state's statement, selects and transitions
     *        include only non-conflicting partial_hdr_err_proc values.
     *
     */
    bool state_pkt_too_short_verify(const IR::BFN::ParserState* state,
                                    bool &select_args_incompatible) {
        select_args_incompatible = false;
        if (state->selects.size()) {
            // Look for incompatibility in select arguments.
            // This needs specific processing.
            //
            if (!partial_hdr_err_proc_verify(nullptr,
                                             &state->selects,
                                             nullptr)) {
                select_args_incompatible = true;
                LOG4("state_pkt_too_short_verify(" << state->name <<
                        "): incompatible select arguments");
                return false;
            }
        }

        if (!partial_hdr_err_proc_verify(&state->statements,
                                         nullptr,
                                         &state->transitions)) {
            LOG4("state_pkt_too_short_verify(" << state->name <<
                    "): incompatible statements and transitions");
            return false;
        }

        LOG4("state_pkt_too_short_verify(" << state->name <<"): ok");
        return true;
    }

    IR::BFN::ParserState* postorder(IR::BFN::ParserState* state) override {
        LOG4("SplitGreedyParserStates(" << state->name << ")");

        int cnt = 0;
        bool select_args_incompatible = false;

        while (!state_pkt_too_short_verify(state, select_args_incompatible)) {
            if (select_args_incompatible) {
                ::error(ErrorType::ERR_UNSUPPORTED,
                        "Mixing non-greedy and greedy extracted fields in select "
                        "statement is unsupported.");
            } else {
                cstring new_name = state->name + ".$greedy_" + cstring::to_cstring(cnt++);
                state = split_state(state, new_name);
            }
        }

        return state;
    }
};

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerParserIR : public PassManager {
    std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers;

    LowerParserIR(const PhvInfo& phv,
                  BFN_MAYBE_UNUSED const FieldDefUse& defuse,
                  ClotInfo& clotInfo,
                  BFN_MAYBE_UNUSED const ParserHeaderSequences& parserHeaderSeqs,
                  std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers,
                  PhvLogging::CollectDefUseInfo *defuseInfo)
        : origParserZeroInitContainers(origParserZeroInitContainers) {
        auto* allocateParserChecksums = new AllocateParserChecksums(phv, clotInfo);
        auto* parser_info = new CollectParserInfo;
        auto* lower_parser_info = new CollectLoweredParserInfo;
        auto* find_negative_deposits = new FindNegativeDeposits;
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(
            phv, clotInfo, *allocateParserChecksums, origParserZeroInitContainers);
#ifdef HAVE_FLATROCK
        auto* computeFlatrockParserIR = new ComputeFlatrockParserIR(phv, defuse);
#endif  // HAVE_FLATROCK
        auto* replaceLoweredParserIR = new ReplaceParserIR(*computeLoweredParserIR);
#ifdef HAVE_FLATROCK
        auto *replaceFlatrockParserIR = new ReplaceFlatrockParserIR(phv, *computeFlatrockParserIR,
                parserHeaderSeqs, *parser_info);
#endif  // HAVE_FLATROCK

        addPasses({
            LOGGING(4) ? new DumpParser("before_parser_lowering", false, true) : nullptr,
            new SplitGreedyParserStates(),
            LOGGING(4) ? new DumpParser("after_greedy_split", false, true) : nullptr,
            new ResolveParserConstants(phv, clotInfo),
            new ParserCopyProp(phv),
            new SplitParserState(phv, clotInfo),
            find_negative_deposits,
            new RemoveNegativeDeposits(*find_negative_deposits),
            new AllocateParserMatchRegisters(phv),
            LOGGING(4) ? new DumpParser("before_elim_empty_states") : nullptr,
            parser_info,
            new ElimEmptyState(*parser_info),
            allocateParserChecksums,
            LOGGING(4) ? new DumpParser("after_alloc_parser_csums") : nullptr,
            LOGGING(4) ? new DumpParser("final_hlir_parser") : nullptr,
#ifdef HAVE_FLATROCK
            Device::currentDevice() == Device::FLATROCK ?
            new InsertPayloadPseudoHeaderState() : nullptr,
            parser_info,
#endif
#ifdef HAVE_FLATROCK
            Device::currentDevice() == Device::FLATROCK ?
                static_cast<Visitor *>(computeFlatrockParserIR) :
#endif  // HAVE_FLATROCK
                static_cast<Visitor *>(computeLoweredParserIR),
#ifdef HAVE_FLATROCK
            Device::currentDevice() == Device::FLATROCK ?
                static_cast<Visitor *>(replaceFlatrockParserIR) :
#endif  // HAVE_FLATROCK
                static_cast<Visitor *>(replaceLoweredParserIR),
            LOGGING(4) ? new DumpParser("after_parser_lowering") : nullptr,
            lower_parser_info,
            new MergeLoweredParserStates(*lower_parser_info, *computeLoweredParserIR, clotInfo,
                defuseInfo),
            LOGGING(4) ? new DumpParser("final_llir_parser") : nullptr
        });
    }
};

/// Given a sequence of fields, construct a packing format describing how the
/// fields will be laid out once they're lowered to containers.
const safe_vector<IR::BFN::DigestField>*
computeControlPlaneFormat(const PhvInfo& phv,
                          const IR::Vector<IR::BFN::FieldLVal>& fields) {
    struct LastContainerInfo {
        /// The container into which the last field was placed.
        PHV::Container container;
        /// The number of unused bits which remain on the LSB side of the
        /// container after the last field was placed.
        int remainingBitsInContainer;
    };

    boost::optional<LastContainerInfo> last = boost::make_optional(false, LastContainerInfo());
    unsigned totalWidth = 0;
    auto *packing = new safe_vector<IR::BFN::DigestField>();

    // Walk over the field sequence in network order and construct a
    // FieldPacking that reflects its structure, with padding added where
    // necessary to reflect gaps between the fields.
    for (auto* fieldRef : fields) {
        LOG5("Computing digest packing for field : " << fieldRef);
        PHV::FieldUse use(PHV::FieldUse::READ);
        std::vector<PHV::AllocSlice> slices = phv.get_alloc(fieldRef->field,
                PHV::AllocContext::DEPARSER, &use);

        // padding in digest list does not need phv allocation
        auto field = phv.field(fieldRef->field);
        if (field->is_ignore_alloc())
            continue;

        BUG_CHECK(!slices.empty(),
                  "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        // Confusingly, the first slice in network order is the *last* one in
        // `slices` because `foreach_alloc()` (and hence `get_alloc()`)
        // enumerates the slices in increasing order of their little endian
        // offset, which means that in terms of network order it walks the
        // slices backwards.
        for (std::vector<PHV::AllocSlice>::reverse_iterator slice = slices.rbegin();
                slice != slices.rend(); slice++) {
            const nw_bitrange sliceContainerRange = slice->container_slice()
                        .toOrder<Endian::Network>(slice->container().size());

            unsigned packStartByte = 0;

            // If we switched containers (or if this is the very first field),
            // appending padding equivalent to the bits at the end of the previous
            // container and the beginning of the new container that aren't
            // occupied.
            if (last && last->container != slice->container()) {
                totalWidth += last->remainingBitsInContainer;
                totalWidth += sliceContainerRange.lo;
            } else if (!last) {
                totalWidth += sliceContainerRange.lo;
            }
            // The actual start byte on all packings are incremented by 1 during
            // assembly generation to factor in the select byte
            packStartByte = totalWidth / 8;
            totalWidth += slice->width();

            // Place the field slice in the packing format. The field name is
            // used in assembly generation; hence, we use its external name.
            auto packFieldName = slice->field()->externalName();
            // The pack start bit refers to the start bit within the container
            // in network order. This is the hi bit in byte of the container slice
            //  e.g.
            //  - W3(0..3)  # bit[3..0]: ingress::md.y2
            // The start bit in this example is bit 3
            auto packStartBit = slice->container_slice().hi % 8;
            auto packWidth = slice->width();
            auto packFieldStartBit = slice->field_slice().lo;
            packing->emplace_back(packFieldName, packStartByte, packStartBit,
                                                    packWidth, packFieldStartBit);
            LOG5("  Packing digest field slice : " << *slice
                    << " with startByte : " << packStartByte
                    << ", startBit: " << packStartBit << ", width: " << packWidth
                    << ", fields start bit (phv_offset) : " << packFieldStartBit);

            // Remember information about the container placement of the last slice
            // in network order (the first one in `slices`) so we can add any
            // necessary padding on the next pass around the loop.
            last = LastContainerInfo{ slice->container(), slice->container_slice().lo };
        }
    }

    return packing;
}

/**
 * \ingroup LowerDeparserIR
 *
 * \brief Replace Emits covered in a CLOT with EmitClot
 *
 * This pass visits the deparsers, and for each deparser, it walks through the emits and identifies
 * checksums/fields that are covered as part of a CLOT. Elements that are covered by a CLOT are
 * removed from the emit list and are replace by EmitClot objects.
 */
struct RewriteEmitClot : public DeparserModifier {
    RewriteEmitClot(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    bool preorder(IR::BFN::Deparser* deparser) override {
        // Replace Emits covered in a CLOT with EmitClot

        IR::Vector<IR::BFN::Emit> newEmits;

        // The next field slices we expect to see being emitted, represented as a vector of stacks.
        // Each stack represents the field slices in a CLOT, which can differ depending on which
        // parser state extracted the CLOT. For every emit, we try to pop an element from the top of
        // all the stacks if the slice being emitted matches the top element. As long as an emit
        // causes at least 1 stack to pop its top element, the contents of the CLOT is valid; else,
        // something went wrong. Once all stacks are empty, we are done emitting that CLOT.
        //
        // For example, given the following CLOT, where each uppercase letter represents a field
        // slice that belongs to 1 or more different headers:
        //
        // CLOT 0: {
        //     state_0: AB
        //     state_1: AXY
        //     state_2: ABCDEFG
        // }
        //
        // There are many different orders in which the deparser could emit each field slice. For
        // example: ABCDEFGXY, AXYBCDEFG, AXBYCDEFG, AXBCDEFG, AXBYCDEFG, ABXYCDEFG, etc. All these
        // combinations would lead to the 3 stacks being emptied.
        std::vector<std::stack<const PHV::FieldSlice*>> expectedNextSlices;
        const Clot* lastClot = nullptr;

        LOG4("[RewriteEmitClot] Rewriting EmitFields and EmitChecksums as EmitClots for "
             << deparser->gress);
        for (auto emit : deparser->emits) {
            LOG6("  Evaluating emit: " << emit);
            auto irPovBit = emit->povBit;

            // For each derived Emit class, assign the member that represents the field being
            // emitted to "source".
            const IR::Expression* source = nullptr;
            if (auto emitField = emit->to<IR::BFN::EmitField>()) {
                source = emitField->source->field;
            } else if (auto emitChecksum = emit->to<IR::BFN::EmitChecksum>()) {
                source = emitChecksum->dest->field;
            } else if (auto emitConstant = emit->to<IR::BFN::EmitConstant>()) {
                newEmits.pushBackOrAppend(emitConstant);

                // Disallow CLOTs from being overwritten by deparser constants
                BUG_CHECK(expectedNextSlices.empty(), "CLOT slices not re-written?");

                continue;
            }

            BUG_CHECK(source, "No emit source for %1%", emit);

            auto field = phv.field(source);
            auto sliceClots = clotInfo.slice_clots(field);

            // If we are emitting a checksum that overwrites a CLOT, register this fact with
            // ClotInfo.
            if (auto emitCsum = emit->to<IR::BFN::EmitChecksum>()) {
                if (auto fieldClot = clotInfo.whole_field_clot(field)) {
                    clotInfo.clot_to_emit_checksum()[fieldClot].push_back(emitCsum);
                } else {
                    BUG_CHECK(sliceClots->empty(),
                              "Checksum field %s was partially allocated to CLOTs, but this is not"
                              "allowed",
                              field->name);
                }
            }

            // Points to the next bit in `field` that we haven't yet accounted for. This is -1 if
            // we have accounted for all bits. NB: this is little-endian to correspond to the
            // little-endianness of field slices.
            int nextFieldBit = field->size - 1;

            // Handle any slices left over from the last emitted CLOT.
            if (!expectedNextSlices.empty()) {
                // The current slice being emitted had better line up with the next expected slice.
                const PHV::FieldSlice* nextSlice = nullptr;
                for (auto& stack : expectedNextSlices) {
                    if (stack.top()->field() != field) continue;

                    BUG_CHECK(!(nextSlice != nullptr && *nextSlice != *stack.top()),
                        "Expected next slice of field %1% in %2% is inconsistent: "
                        "%3% != %4%",
                        field->name,
                        *lastClot,
                        nextSlice->shortString(),
                        stack.top()->shortString());
                    nextSlice = stack.top();
                    stack.pop();
                }
                BUG_CHECK(nextSlice,
                    "Emitted field %1% does not match any slices expected next in %2%",
                    field->name,
                    *lastClot);
                BUG_CHECK(nextSlice->range().hi == nextFieldBit,
                    "Emitted slice %1% does not line up with expected slice %2% in %3%",
                    PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString(),
                    nextSlice->shortString(),
                    *lastClot);

                LOG6("    " << nextSlice->shortString()
                     << " is the next expected slice in " << *lastClot);
                LOG6("    It is covered by existing EmitClot: " << newEmits.back());

                nextFieldBit = nextSlice->range().lo - 1;
                // Erase empty stacks from vector of stacks.
                for (auto it = expectedNextSlices.begin(); it != expectedNextSlices.end(); ) {
                    if (!it->empty())
                        ++it;
                    else
                        it = expectedNextSlices.erase(it);
                }
            }

            // If we've covered all bits in the current field, move on to the next emit.
            if (nextFieldBit == -1) continue;

            // We haven't covered all bits in the current field yet. The next bit in the field must
            // be in a new CLOT, if it is covered by a CLOT at all. There had better not be any
            // slices left over from the last emitted CLOT.
            BUG_CHECK(expectedNextSlices.empty(),
                "Emitted slice %1% does not match any expected next slice in %2%",
                PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString(),
                *lastClot);

            if (sliceClots->empty()) {
                // None of this field should have come from CLOTs.
                BUG_CHECK(nextFieldBit == field->size - 1,
                          "Field %1% has no slices allocated to CLOTs, but %2% somehow came from "
                          "%3%",
                          field->name,
                          PHV::FieldSlice(field,
                                          StartLen(nextFieldBit + 1,
                                                   field->size - nextFieldBit)).shortString(),
                          *lastClot);

                newEmits.pushBackOrAppend(emit);
                continue;
            }

            for (auto entry : *sliceClots) {
                auto slice = entry.first;
                auto clot = entry.second;

                BUG_CHECK(nextFieldBit > -1,
                    "While processing emits for %1%, the entire field has been emitted, but "
                    "encountered an extra CLOT (tag %2%)",
                    field->name, clot->tag);

                // Ignore the CLOT if it starts before `nextFieldBit`. If this is working right,
                // we've emitted it already with a previous field.
                if (nextFieldBit < slice->range().hi) continue;

                if (slice->range().hi != nextFieldBit) {
                    // The next part of the field comes from PHVs. Produce an emit of the slice
                    // containing just that part.
                    auto irSlice = new IR::Slice(source, nextFieldBit, slice->range().hi + 1);
                    auto sliceEmit = new IR::BFN::EmitField(irSlice, irPovBit->field);
                    LOG6("    " << field->name << " is partially stored in PHV");
                    LOG4("  Created new EmitField: " << sliceEmit);
                    newEmits.pushBackOrAppend(sliceEmit);

                    nextFieldBit = slice->range().hi;
                }

                // Make sure the first slice in the CLOT lines up with the slice we're expecting.
                // Though the slices in a multiheader CLOT can differ depending on which parser
                // state it begins in, the first slice should always be the same across all states.
                auto clotSlices = clot->parser_state_to_slices();
                auto firstSlice = *clotSlices.begin()->second.begin();
                BUG_CHECK(firstSlice->field() == field,
                          "First field in %1% is %2%, but expected %3%",
                          *clot, firstSlice->field()->name, field->name);
                BUG_CHECK(firstSlice->range().hi == nextFieldBit,
                          "First slice %1% in %2% does not match expected slice %3%",
                          firstSlice->shortString(),
                          *clot,
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString());

                // Produce an emit for the CLOT.
                auto clotEmit = new IR::BFN::EmitClot(irPovBit);
                clotEmit->clot = clot;
                clot->pov_bit = irPovBit;
                newEmits.pushBackOrAppend(clotEmit);
                lastClot = clot;
                LOG6("    " << field->name << " is the first field in " << *clot);
                LOG4("  Created new EmitClot: " << clotEmit);

                nextFieldBit = firstSlice->range().lo - 1;

                if (std::all_of(clotSlices.begin(), clotSlices.end(),
                        [](std::pair<const cstring, std::vector<const PHV::FieldSlice*>> pair) {
                            return pair.second.size() == 1;
                        }))
                    continue;

                // There are more slices in the CLOT. We had better be done with the current field.
                BUG_CHECK(nextFieldBit == -1,
                          "%1% is missing slice %2%",
                          *clot,
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString());

                for (const auto& kv : clotSlices) {
                    // Don't add empty stacks to expectedNextSlices. A stack of size = 1 is
                    // considered empty since the element currently being processed will
                    // immediately be popped below.
                    if (kv.second.size() < 2) continue;

                    // Make a std::deque that is a reversed copy of
                    // clot->parser_state_to_slices().second.
                    std::deque<const PHV::FieldSlice*> deq;
                    std::copy(kv.second.rbegin(), kv.second.rend(), std::back_inserter(deq));
                    deq.pop_back();
                    // The std::deque is used to construct a std::stack where the first field
                    // slices in the CLOT are at the top.
                    expectedNextSlices.emplace_back(deq);
                }
            }

            if (nextFieldBit != -1) {
                BUG_CHECK(expectedNextSlices.empty(),
                          "%1% is missing slice %2%",
                          *lastClot,
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString());

                // The last few bits of the field comes from PHVs. Produce an emit of the slice
                // containing just those bits.
                auto irSlice = new IR::Slice(source, nextFieldBit, 0);
                auto sliceEmit = new IR::BFN::EmitField(irSlice, irPovBit->field);
                newEmits.pushBackOrAppend(sliceEmit);
            }
        }

        if (!expectedNextSlices.empty()) {
            std::stringstream out;
            out << *lastClot << " has extra field slices not covered by the "
                << "deparser before RewriteEmitClot: ";
            for (auto it = expectedNextSlices.rbegin(); it != expectedNextSlices.rend(); ++it) {
                if (it != expectedNextSlices.rbegin()) out << ", ";
                std::stack<const PHV::FieldSlice*>& stack = *it;
                while (!stack.empty()) {
                    out << stack.top()->shortString();
                    if (stack.size() > 1) out << ", ";
                    stack.pop();
                }
            }
            BUG("%s", out.str());
        }
        LOG4("Rewriting complete. Deparser emits for " << deparser->gress << " are now:");
        for (const auto* emit : newEmits)
            LOG4("  " << emit);

        deparser->emits = newEmits;
        return false;
    }

    const PhvInfo& phv;
    ClotInfo& clotInfo;
};

// Deparser checksum engine exposes input entries as 16-bit.
// PHV container entry needs a swap if the field's 2-byte alignment
// in the container is not same as the alignment in the packet layout
// i.e. off by 1 byte. For example, this could happen if "ipv4.ttl" is
// allocated to a 8-bit container.
std::map<PHV::Container, unsigned> getChecksumPhvSwap(const PhvInfo& phv,
                                                      const IR::BFN::EmitChecksum* emitChecksum) {
    std::map<PHV::Container, unsigned> containerToSwap;
    for (auto source : emitChecksum->sources) {
        auto* phv_field = phv.field(source->field->field);
        PHV::FieldUse use(PHV::FieldUse::READ);
        std::vector<PHV::AllocSlice> slices = phv.get_alloc(phv_field, nullptr,
                PHV::AllocContext::DEPARSER, &use);
        int offset = source->offset;
        for (auto& slice : boost::adaptors::reverse(slices)) {
            unsigned swap = 0;
            bool isResidualChecksum = false;
            std::string f_name(phv_field->name.c_str());
            if (f_name.find(BFN::COMPILER_META) != std::string::npos
             && f_name.find("residual_checksum_") != std::string::npos)
                isResidualChecksum = true;
            // If a field slice is on an even byte in the checksum operation field list
            // and even byte in the container and vice-versa then swap is true
            // Offset : offset of the field slice is offset of the field + difference between
            // field.hi and slice.hi
            if (!isResidualChecksum &&
                ((offset + phv_field->size - slice.field_slice().hi -1)/8) % 2 ==
                 (slice.container_slice().hi/8) % 2) {
                swap = (1 << slice.container_slice().hi/16U) |
                             (1 << slice.container_slice().lo/16U);
            }
            containerToSwap[slice.container()] |= swap;
        }
    }
    return containerToSwap;
}

/// \ingroup LowerDeparserIR
///
/// \brief Generates lowered deparser IR with container references.
///
/// Generate the lowered deparser IR by splitting references to fields in the
/// high-level deparser IR into references to containers.
struct ComputeLoweredDeparserIR : public DeparserInspector {
    ComputeLoweredDeparserIR(const PhvInfo& phv, const ClotInfo& clotInfo)
        : phv(phv), clotInfo(clotInfo), nextChecksumUnit(0), lastSharedUnit(0),
          nested_unit(0),
          normal_unit(4) {
        igLoweredDeparser = new IR::BFN::LoweredDeparser(INGRESS);
        egLoweredDeparser = new IR::BFN::LoweredDeparser(EGRESS);
    }

    /// The lowered deparser IR generated by this pass.
    IR::BFN::LoweredDeparser* igLoweredDeparser;
    IR::BFN::LoweredDeparser* egLoweredDeparser;
    // Contains checksum unit number for each checksum destination in each gress
    std::map<gress_t, std::map<const IR::BFN::EmitChecksum*, unsigned>> checksumInfo;

 private:
    /// \brief Remove guaranteed-zero fields from checksum calculations.
    ///
    /// Fields which are deparser zero candidates are guaranteed to be zero.
    /// Removing such fields from a checksum calculation will not alter the checksum.
    IR::Vector<IR::BFN::FieldLVal>
    removeDeparserZeroFields(IR::Vector<IR::BFN::FieldLVal> checksumFields) {
        IR::Vector<IR::BFN::FieldLVal> newChecksumFields;
        for (auto cfield : checksumFields) {
            auto* phv_field = phv.field(cfield->field);
            if (!phv_field->is_deparser_zero_candidate()) {
                newChecksumFields.push_back(cfield);
            }
        }
        return newChecksumFields;
    }

    /// Returns lowered partial phv and clot checksum
    std::pair<IR::BFN::PartialChecksumUnitConfig*, std::vector<IR::BFN::ChecksumClotInput*>>
    getPartialUnit(const IR::BFN::EmitChecksum* emitChecksum,
                   gress_t gress) {
        unsigned checksumUnit;
        // Find if the checksum is already allocated a checksum units
        if (checksumInfo.count(gress) && checksumInfo[gress].count(emitChecksum)) {
            checksumUnit = checksumInfo[gress][emitChecksum];
        } else {
            checksumUnit = getChecksumUnit(emitChecksum->nested_checksum.size() > 0);
        }
        if (checksumUnit >= Device::pardeSpec().numDeparserChecksumUnits()) {
            ::fatal_error("Number of deparser checksum updates exceeds the number of checksum"
            " engines available. Checksum engine not allocated for destination %1%",
            emitChecksum->dest);
        }
        LOG3("Assigning deparser partial checksum unit " << checksumUnit << " to "
             << emitChecksum->dest);
        auto* unitConfig = new IR::BFN::PartialChecksumUnitConfig(checksumUnit);
        auto containerToSwap = getChecksumPhvSwap(phv, emitChecksum);
        checksumInfo[gress][emitChecksum] = unitConfig->unit;
        IR::Vector<IR::BFN::ContainerRef> phvSources;
        std::vector<Clot*> clotSources;
        std::vector<IR::BFN::ChecksumClotInput*> clots;

        if (Device::currentDevice() == Device::TOFINO) {
            IR::Vector<IR::BFN::FieldLVal> checksumFields;
            for (auto f : emitChecksum->sources) {
                checksumFields.push_back(f->field);
            }
            checksumFields = removeDeparserZeroFields(checksumFields);
            std::tie(phvSources, clotSources) = lowerFields(phv, clotInfo, checksumFields, true);
            for (auto* source : phvSources) {
                auto* input = new IR::BFN::ChecksumPhvInput(source);
                input->swap = containerToSwap[source->container];
                unitConfig->phvs.push_back(input);
            }
        } else if (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
                || Device::currentDevice() == Device::CLOUDBREAK
#endif
        ) {
            std::vector<const IR::BFN::FieldLVal*> groupPov;
            ordered_map<IR::Vector<IR::BFN::FieldLVal>*, const IR::BFN::FieldLVal*> groups;
            const IR::BFN::FieldLVal* lastPov = nullptr;
            // Since the information about mapping of field to pov is lost after lowering
            // the fields due to container merging, we will lower the fields in groups.
            // Each group of fields will have same pov bit
            IR::Vector<IR::BFN::FieldLVal>* newGroup = nullptr;
            for (auto f : emitChecksum->sources) {
                if (lastPov && lastPov->equiv(*f->povBit)) {
                    newGroup->push_back(f->field);
                } else {
                    // Since a new group will be created, nothing will be added in old group.
                    // Adding it in a map with corresponding POV
                    if (newGroup) {
                        groups[newGroup] = lastPov;
                    }
                    newGroup = new IR::Vector<IR::BFN::FieldLVal>();
                    newGroup->push_back(f->field);
                    lastPov = f->povBit;
                }
            }
            if (newGroup)
                groups[newGroup] = lastPov;
            int groupidx = 0;
            for (auto& group : groups) {
                phvSources.clear();
                clotSources.clear();
                *group.first = removeDeparserZeroFields(*group.first);
                std::tie(phvSources, clotSources) = lowerFields(phv, clotInfo, *group.first, true);
                auto povBit = lowerSingleBit(phv, group.second,
                                                  PHV::AllocContext::DEPARSER);
                for (auto* source : phvSources) {
                    auto* input = new IR::BFN::ChecksumPhvInput(source);
                    input->swap = containerToSwap[source->container];
                    input->povBit = povBit;
                    unitConfig->phvs.push_back(input);
                }
                for (auto source : clotSources) {
                    if (clots.empty() || clots.back()->clot != source) {
                        auto povBit = lowerSingleBit(phv, source->pov_bit,
                                                     PHV::AllocContext::DEPARSER);
                        auto* input = new IR::BFN::ChecksumClotInput(source, povBit);
                        clots.push_back(input);
                    }
                }
                groupidx++;
            }
            unitConfig->povBit = lowerSingleBit(phv, emitChecksum->povBit,
                                           PHV::AllocContext::DEPARSER);
        }
        return {unitConfig, clots};
    }

    /// Lowers full checksum unit
    /// First lower @p emitChecksum then lower emitChecksum->nestedChecksum
    IR::BFN::FullChecksumUnitConfig* lowerChecksum(const IR::BFN::EmitChecksum* emitChecksum,
                                                   gress_t gress) {
        auto fullChecksumUnit = new IR::BFN::FullChecksumUnitConfig();
        IR::BFN::PartialChecksumUnitConfig* checksumUnit = nullptr;
        std::vector<IR::BFN::ChecksumClotInput*> clots;
        std::tie(checksumUnit, clots) = getPartialUnit(emitChecksum, gress);
        fullChecksumUnit->partialUnits.push_back(checksumUnit);
        for (auto clot : clots) {
            fullChecksumUnit->clots.push_back(clot);
        }
        fullChecksumUnit->unit = checksumUnit->unit;
        // Only for JbayB0 and Cloudbreak
        if (Device::pardeSpec().numDeparserInvertChecksumUnits()) {
            for (auto nestedCsum : emitChecksum->nested_checksum) {
                IR::BFN::PartialChecksumUnitConfig* nestedUnit = nullptr;
                std::vector<IR::BFN::ChecksumClotInput*> nestedClots;
                std::tie(nestedUnit, nestedClots) = getPartialUnit(nestedCsum, gress);
                // For more information about why inversion is needed
                // check ticket JBAY-2979
                nestedUnit->invert = true;
                fullChecksumUnit->partialUnits.push_back(nestedUnit);
                for (auto clot : nestedClots) {
                    clot->invert = true;
                    fullChecksumUnit->clots.push_back(clot);
                }
            }
        }
        fullChecksumUnit->zeros_as_ones = emitChecksum->zeros_as_ones;
        return fullChecksumUnit;
    }

    /// JBAYB0 can invert the output of partial checksum units and clots. But this feature
    /// exists only for full checksum unit 0 - 3. This inversion feature is needed for
    /// calculation of nested checksum. So for JBAYB0, checksum engine allocation for normal
    /// checksums (normal means not nested) starts from unit 4. If 4 - 7 engines are not free
    /// then any free engine from 0 - 3 will be allocated. For nested checksums, engine
    /// allocation starts from unit 0.
    ///
    /// For all other targets, checksum engine allocation starts from unit 0.
    unsigned int getChecksumUnit(bool nested) {
        if (Device::pardeSpec().numDeparserInvertChecksumUnits() == 4) {
            if (nested) {
                if (nested_unit == Device::pardeSpec().numDeparserInvertChecksumUnits()) {
                   ::error("Too many nested checksums");
                }
                return nested_unit++;
            } else {
                if (normal_unit < Device::pardeSpec().numDeparserChecksumUnits()) {
                    return normal_unit++;
                } else if (normal_unit == Device::pardeSpec().numDeparserChecksumUnits()
                       && nested_unit < Device::pardeSpec().numDeparserInvertChecksumUnits()) {
                    return nested_unit++;
                } else {
                    ::fatal_error("Number of deparser checksum updates exceeds the number of"
                                  "checksum engines available.");
                    return 0;
                }
            }
        } else {
            if (nextChecksumUnit > 1 && Device::currentDevice() == Device::TOFINO) {
                return (nextChecksumUnit++ + lastSharedUnit);
            }
            return nextChecksumUnit++;
        }
    }

    /// \brief Compute the lowered deparser IR
    ///
    /// Convers the field emits to container emits.
    bool preorder(const IR::BFN::Deparser* deparser) override {
        // Flatrock: metadata packer is output as a deparser
        auto* loweredDeparser = deparser->gress == INGRESS ? igLoweredDeparser
                                                           : egLoweredDeparser;

        // Reset the next checksum unit if needed. On Tofino, each thread has
        // its own checksum units. On JBay they're shared, and their ids are
        // global, so on that device we don't reset the next checksum unit for
        // each deparser.
        if (Device::currentDevice() == Device::TOFINO) {
            if (nextChecksumUnit > 2)
                lastSharedUnit = nextChecksumUnit - 2;
            nextChecksumUnit = 0;
        }

        struct LastSimpleEmitInfo {
            // The `PHV::Field::id` of the POV bit for the last simple emit.
            int povFieldId;
            // The actual range of bits (of size 1) corresponding to the POV
            // bit for the last simple emit.
            le_bitrange povFieldBits;
        };

        auto lastSimpleEmit = boost::make_optional(false, LastSimpleEmitInfo());
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
            if (!prim->is<IR::BFN::EmitField>()) {
                groupedEmits.emplace_back(1, prim);
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
                    auto emitChecksumVec = clotInfo.clot_to_emit_checksum().at(cl);
                    for (auto emitChecksum : emitChecksumVec) {
                        auto f = phv.field(emitChecksum->dest->field);
                        auto unitConfig = lowerChecksum(emitChecksum, deparser->gress);
                        cl->checksum_field_to_checksum_id[f] = unitConfig->unit;
                        loweredDeparser->checksums.push_back(unitConfig);
                    }
                }

                continue;
            }

            // If this is a checksum emit primitive, lower it.
            if (auto* emitChecksum = group.back()->to<IR::BFN::EmitChecksum>()) {
                BUG_CHECK(group.size() == 1,
                          "Checksum primitives should be in a singleton group");
                auto unitConfig = lowerChecksum(emitChecksum, deparser->gress);
                loweredDeparser->checksums.push_back(unitConfig);

                // Generate the lowered checksum emit.
                auto* loweredPovBit = lowerSingleBit(phv,
                                                     emitChecksum->povBit,
                                                     PHV::AllocContext::DEPARSER);
                auto* loweredEmit =
                  new IR::BFN::LoweredEmitChecksum(loweredPovBit, unitConfig->unit);

                loweredDeparser->emits.push_back(loweredEmit);


                continue;
            }

            if (auto* emitConstant = group.back()->to<IR::BFN::EmitConstant>()) {
                auto* loweredPovBit = lowerSingleBit(phv,
                                                     emitConstant->povBit,
                                                     PHV::AllocContext::DEPARSER);

                BUG_CHECK(emitConstant->constant->fitsUint(), "Emit constant too large");

                // TODO cut large constant into bytes

                auto value = emitConstant->constant->asUnsigned();

                BUG_CHECK(value >> 8 == 0, "Deparser constants must in bytes");

                auto* loweredEmit =
                  new IR::BFN::LoweredEmitConstant(loweredPovBit, value);

                loweredDeparser->emits.push_back(loweredEmit);

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
            auto* loweredPovBit = lowerSingleBit(phv,
                                                 emit->povBit,
                                                 PHV::AllocContext::DEPARSER);
            for (auto* source : emitSources) {
                auto* loweredEmit = new IR::BFN::LoweredEmitPhv(loweredPovBit, source);
                loweredDeparser->emits.push_back(loweredEmit);
            }
        }

        // Lower deparser parameters from fields to containers.
        for (auto* param : deparser->params) {
            bool skipPOV = false;
#if HAVE_FLATROCK
            // Skip Flatrock metadata packer valid_vec fields
            auto& mdp_vld_vec = Device::get().pardeSpec().mdpValidVecFieldsSet();
            if (Device::currentDevice() == Device::FLATROCK && deparser->gress == INGRESS) {
                bool found = mdp_vld_vec.count(std::string(param->name));
                if (!found) found = mdp_vld_vec.count(param->name + ".$valid");
                if (!found && param->source) {
                    if (const auto* mem = param->source->field->to<IR::Member>()) {
                        found = mdp_vld_vec.count(std::string(mem->member.name));
                    }
                }
                if (found) {
                    if (param->povBit) {
                        if (param->source)
                            skipPOV = true;
                        else
                            continue;
                    } else {
                        continue;
                    }
                }
            }
#endif  /* HAVE_FLATROCK */
            if (!param->source) continue;
            auto* loweredSource =
                lowerUnsplittableField(phv, clotInfo, param->source, "deparser parameter");
            auto* lowered = new IR::BFN::LoweredDeparserParameter(param->name, {loweredSource});
            if (param->povBit && !skipPOV)
                lowered->povBit = lowerSingleBit(phv,
                                                 param->povBit,
                                                 PHV::AllocContext::DEPARSER);
            loweredDeparser->params.push_back(lowered);
        }

#if HAVE_FLATROCK
        // Build the Flatrock MDP valid vector
        if (Device::currentDevice() == Device::FLATROCK && deparser->gress == INGRESS) {
            IR::Vector<IR::BFN::FieldLVal> mdp_vld_vec_fields;

            const auto* pipe = findContext<IR::BFN::Pipe>();
            auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
            if (!tmMeta) {
                ::warning("ig_intr_md_for_tm not defined in ingress control block");
            } else {
                for (auto fname : Device::get().pardeSpec().mdpValidVecFields()) {
                    const IR::Expression* exp = nullptr;
                    const PHV::Field* f = nullptr;
                    if (fname.rfind(".$valid") != std::string::npos)
                        f = phv.field(tmMeta->name + "." + fname);
                    else
                        f = phv.field(tmMeta->name + "." + fname + ".$valid");
                    if (f && phv.getTempVar(f)) exp = phv.getTempVar(f);
                    if (!exp) exp = gen_fieldref(tmMeta, fname);
                    mdp_vld_vec_fields.push_back(new IR::BFN::FieldLVal(exp));
                }
            }

            // Calculate the containers for the valid vector
            IR::Vector<IR::BFN::ContainerRef> containers;
            std::tie(containers, std::ignore) = lowerFields(phv, clotInfo, mdp_vld_vec_fields);
            loweredDeparser->params.push_back(
                new IR::BFN::LoweredDeparserParameter("valid_vec", containers));
        }
#endif /* HAVE_FLATROCK */

        // Filter padding field out of digest field list
        auto filterPaddingField =
            [&](const IR::BFN::DigestFieldList* fl)->IR::BFN::DigestFieldList* {
            auto sources = new IR::Vector<IR::BFN::FieldLVal>();
            for (auto src : fl->sources) {
                // do not emit padding field in digest field list.
                if (src->is<IR::Padding>())
                    continue;
                sources->push_back(src);
            }
            return new IR::BFN::DigestFieldList(fl->idx, *sources,
                    fl->type, fl->controlPlaneName);
        };

        // Lower digests from fields to containers.
        for (auto& item : deparser->digests) {
            auto* digest = item.second;

            auto* lowered =
              new IR::BFN::LoweredDigest(digest->name);

            if (digest->selector) {
                auto *loweredSelector =
                        lowerUnsplittableField(phv, clotInfo, digest->selector, "digest selector");
                lowered->selector = loweredSelector; }

            if (digest->povBit)
                lowered->povBit = lowerSingleBit(phv,
                                                 digest->povBit,
                                                 PHV::AllocContext::DEPARSER);

            // Each field list, when lowered, becomes a digest table entry.
            // Learning field lists are used to generate the format for learn
            // quanta, which are exposed to the control plane, so they have a
            // bit more metadata than other kinds of digests.
            for (auto fieldList : digest->fieldLists) {
                IR::Vector<IR::BFN::ContainerRef> phvSources;
                std::vector<Clot*> clotSources;

                LOG3("\temit fieldlist " << fieldList);
                // XXX(hanw): filter out padding fields inside the field list which
                // exist for alignment purpose, they should not be deparsed as it
                // would causes the same container to be emitted twice.
                auto fieldListNoPad = filterPaddingField(fieldList);

                std::tie(phvSources, clotSources) =
                    lowerFields(phv, clotInfo, fieldListNoPad->sources);

                BUG_CHECK(clotSources.empty(), "digest data cannot be sourced from CLOT");

                IR::BFN::DigestTableEntry* entry = nullptr;

                if (digest->name == "learning") {
                    auto* controlPlaneFormat =
                      computeControlPlaneFormat(phv, fieldListNoPad->sources);
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
    unsigned lastSharedUnit;
    unsigned nested_unit;
    unsigned normal_unit;
};

/// \ingroup LowerDeparserIR
///
/// \brief Replace deparser IR with lowered version.
///
/// Replace the high-level deparser IR version of each deparser with the lowered
/// version generated by ComputeLoweredDeparserIR.
struct ReplaceDeparserIR : public DeparserTransform {
    ReplaceDeparserIR(const IR::BFN::LoweredDeparser* igLoweredDeparser,
                      const IR::BFN::LoweredDeparser* egLoweredDeparser)
      : igLoweredDeparser(igLoweredDeparser),
        egLoweredDeparser(egLoweredDeparser) { }

 private:
    const IR::BFN::AbstractDeparser*
    preorder(IR::BFN::Deparser* deparser) override {
        prune();
#if HAVE_FLATROCK
        // if (Device::currentDevice() == Device::FLATROCK && deparser->gress == INGRESS) {
        //     // FLATROCK does not have a real ingress deparser
        //     return deparser; }
#endif
        // Flatrock: metadata packer is output as a deparser
        return deparser->gress == INGRESS ? igLoweredDeparser : egLoweredDeparser;
    }

    const IR::BFN::LoweredDeparser* igLoweredDeparser;
    const IR::BFN::LoweredDeparser* egLoweredDeparser;
};

/**
 * \defgroup LowerDeparserIR LowerDeparserIR
 * \ingroup LowerParser
 *
 * \brief Replace deparser IR with lowered version that references containers instead of fields.
 *
 * Generate a lowered version of the parser IR in this program and swap it in
 * in place of the existing representation.
 *
 * The pass does this by:
 *  1. Replacing field/checksum emits that are covered by CLOTs with EmitClot objects.
 *  2. Generating lowered version of the deparser and swapping them in.
 *  3. Coalescing the learning digest to remove consecutive uses of the same container.
 */
struct LowerDeparserIR : public PassManager {
    LowerDeparserIR(const PhvInfo& phv, ClotInfo& clot) {
        auto* rewriteEmitClot = new RewriteEmitClot(phv, clot);
        auto* computeLoweredDeparserIR = new ComputeLoweredDeparserIR(phv, clot);
        addPasses({
            rewriteEmitClot,
            computeLoweredDeparserIR,
            new ReplaceDeparserIR(computeLoweredDeparserIR->igLoweredDeparser,
                                  computeLoweredDeparserIR->egLoweredDeparser),
            new CoalesceLearning,
        });
    }
};

/// Collect all containers that are written more than once by the parser.
class ComputeMultiWriteContainers : public ParserModifier {
    const PhvInfo& phv;
    const CollectLoweredParserInfo& parser_info;

 public:
    ComputeMultiWriteContainers(const PhvInfo& ph,
                                const CollectLoweredParserInfo& pi)
        : phv(ph), parser_info(pi) { }

 private:
    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        auto orig = getOriginal<IR::BFN::LoweredParserMatch>();

        for (auto e : match->extracts) {
            if (auto extract = e->to<IR::BFN::LoweredExtractPhv>()) {
                if (extract->write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                    clear_on_write[extract->dest->container].insert(orig);
                } else {
                    // Two extraction in the same transition, container should be bitwise or
                    if (bitwise_or.count(extract->dest->container) &&
                        bitwise_or[extract->dest->container].count(orig)) {
                        bitwise_or_containers.insert(extract->dest->container);
                    }
                    bitwise_or[extract->dest->container].insert(orig);
                }
            }
        }

        for (auto csum : match->checksums) {
            PHV::Container container;
            if (csum->csum_err) {
                container = csum->csum_err->container->container;
            } else if (csum->phv_dest) {
                container = csum->phv_dest->container;
            }
            if (container) {
                if (csum->write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                    clear_on_write[container].insert(orig);
                } else if (csum->write_mode == IR::BFN::ParserWriteMode::BITWISE_OR) {
                    bitwise_or[container].insert(orig);
                }
            }
        }

        return true;
    }

    bool preorder(IR::BFN::LoweredParser*) override {
        bitwise_or = clear_on_write = {};
        clear_on_write_containers = bitwise_or_containers = {};
        return true;
    }

    bool has_non_mutex_writes(const IR::BFN::LoweredParser* parser,
            const std::set<const IR::BFN::LoweredParserMatch*>& matches) {
        for (auto i : matches) {
            for (auto j : matches) {
                if (i == j) continue;

                bool mutex = parser_info.graph(parser).is_mutex(i, j);
                if (!mutex)
                    return true;
            }
        }

        return false;
    }

    void detect_multi_writes(const IR::BFN::LoweredParser* parser,
            const std::map<PHV::Container, std::set<const IR::BFN::LoweredParserMatch*>>& writes,
            std::set<PHV::Container>& write_containers, const char* which) {
        for (auto w : writes) {
            if (has_non_mutex_writes(parser, w.second)) {
                write_containers.insert(w.first);
                LOG4("mark " << w.first << " as " << which);
            } else if (Device::currentDevice() != Device::TOFINO) {
                // In Jbay, even and odd pair of 8-bit containers share extractor in the parser.
                // So if both are used, we need to mark the extract as a multi write.
                if (w.first.is(PHV::Size::b8)) {
                    PHV::Container other(w.first.type(), w.first.index() ^ 1);
                    if (writes.count(other)) {
                        bool has_even_odd_pair = false;

                        for (auto x : writes.at(other)) {
                            for (auto y : w.second) {
                                if (x == y || !parser_info.graph(parser).is_mutex(x, y)) {
                                    has_even_odd_pair = true;
                                    break;
                                }
                            }
                        }

                        if (has_even_odd_pair) {
                            write_containers.insert(w.first);
                            write_containers.insert(other);
                            LOG4("mark " << w.first << " and " << other << " as "
                                         << which << " (even-and-odd pair)");
                        }
                    }
                }
            }
        }
    }

    void postorder(IR::BFN::LoweredParser* parser) override {
        auto orig = getOriginal<IR::BFN::LoweredParser>();

        detect_multi_writes(orig, bitwise_or, bitwise_or_containers, "bitwise-or");
        detect_multi_writes(orig, clear_on_write, clear_on_write_containers, "clear-on-write");

        for (const auto& f : phv) {
            if (f.gress != parser->gress) continue;

            if (f.name.endsWith("$stkvalid")) {
                auto ctxt = PHV::AllocContext::PARSER;
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    bitwise_or_containers.insert(alloc.container());
                });
            }
        }

        // validate
        for (auto c : bitwise_or_containers) {
            if (clear_on_write_containers.count(c))
                BUG("Container cannot be both clear-on-write and bitwise-or: %1%", c);
        }

        for (auto c : bitwise_or_containers)
            parser->bitwiseOrContainers.push_back(new IR::BFN::ContainerRef(c));

        for (auto c : clear_on_write_containers)
            parser->clearOnWriteContainers.push_back(new IR::BFN::ContainerRef(c));
    }

    std::map<PHV::Container,
             std::set<const IR::BFN::LoweredParserMatch*>> bitwise_or, clear_on_write;
    std::set<PHV::Container> bitwise_or_containers, clear_on_write_containers;
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

        for (auto& b : ixbar_use->use) {
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

/// Compute containers that have fields relying on parser zero initialization, these containers
/// will be marked as valid coming out of the parser (Tofino only). In Tofino2, all containers
/// are valid coming out of the parser.
class ComputeInitZeroContainers : public ParserModifier {
    void postorder(IR::BFN::LoweredParser* parser) override {
        ordered_set<PHV::Container> zero_init_containers;
        ordered_set<PHV::Container> intrinsic_invalidate_containers;

        auto ctxt = PHV::AllocContext::PARSER;
        for (const auto& f : phv) {
            if (f.gress != parser->gress) continue;

            // POV bits are treated as metadata
            if (f.pov || f.metadata) {
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    bool hasHeaderField = false;

                    for (auto fc : phv.fields_in_container(alloc.container())) {
                        if (!fc->metadata && !fc->pov) {
                            hasHeaderField = true;
                            break;
                        }
                    }

                    if (!hasHeaderField)
                        zero_init_containers.insert(alloc.container());
                });
            }

            if (f.is_invalidate_from_arch()) {
                // Track the allocated containers for fields that are invalidate_from_arch
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    intrinsic_invalidate_containers.insert(alloc.container());
                    LOG3(alloc.container() << " contains intrinsic invalidate fields");
                });
                continue;
            }

            if (defuse.hasUninitializedRead(f.id)) {
                // If pa_no_init specified, then the field does not have to rely on parser zero
                // initialization.
                if (no_init_fields.count(&f)) continue;
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::AllocSlice& alloc) {
                    zero_init_containers.insert(alloc.container());
                });
            }
        }

        if (origParserZeroInitContainers.count(parser->gress))
            for (auto& c : origParserZeroInitContainers.at(parser->gress))
                zero_init_containers.insert(c);

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
            const ordered_set<const PHV::Field*>& no_init,
            const std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers)
        : phv(phv), defuse(defuse), no_init_fields(no_init),
          origParserZeroInitContainers(origParserZeroInitContainers) {}

    const PhvInfo& phv;
    const FieldDefUse& defuse;
    const ordered_set<const PHV::Field*>& no_init_fields;
    const std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers;
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
        forAllMatching<IR::BFN::LoweredExtractPhv>(&match->extracts,
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

        auto state = findContext<IR::BFN::LoweredParserState>();

        const unsigned inputBufferSize = Device::pardeSpec().byteInputBufferSize();
        BUG_CHECK(*match->bufferRequired <= inputBufferSize,
                  "Parser state %1% requires %2% bytes to be buffered which "
                  "is greater than the size of the input buffer (%3% byte)",
                  state->name, *match->bufferRequired, inputBufferSize);
    }
};

}  // namespace

/**
 * \class LowerParser
 *
 * Sub-passes:
 *  - CharacterizeParser
 *  - CollectLoweredParserInfo
 *  - ComputeBufferRequirements
 *  - ComputeInitZeroContainers (Tofino 1 only)
 *  - ComputeMultiWriteContainers
 *  - LowerDeparserIR
 *  - LowerParserIR
 *  - PragmaNoInit
 *  - WarnTernaryMatchFields
 */
LowerParser::LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse,
        const ParserHeaderSequences &parserHeaderSeqs,
        PhvLogging::CollectDefUseInfo *defuseInfo) :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    auto pragma_no_init = new PragmaNoInit(phv);
    auto compute_init_valid = new ComputeInitZeroContainers(
        phv, defuse, pragma_no_init->getFields(), origParserZeroInitContainers);
    auto parser_info = new CollectLoweredParserInfo;

    addPasses({
        pragma_no_init,
        new LowerParserIR(phv, defuse, clot, parserHeaderSeqs, origParserZeroInitContainers,
            defuseInfo),
        new LowerDeparserIR(phv, clot),
        new WarnTernaryMatchFields(phv),
        Device::currentDevice() == Device::TOFINO ? compute_init_valid : nullptr,
        parser_info,
        new ComputeMultiWriteContainers(phv, *parser_info),
        new ComputeBufferRequirements,
#ifdef HAVE_FLATROCK
        // TODO CharacterizeParser not implemented for Flatrock yet
        Device::currentDevice() == Device::FLATROCK ? nullptr :
#endif  // HAVE_FLATROCK
        new CharacterizeParser
    });
}
