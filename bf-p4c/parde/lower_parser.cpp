#include "bf-p4c/parde/lower_parser.h"

#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>

#include <algorithm>
#include <numeric>
#include <sstream>
#include <type_traits>
#include <utility>
#include <vector>

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/characterize_parser.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/split_parser_state.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"
#include "lib/stringref.h"

namespace {

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
 * @return a string containing debugging info describing the mapping between the
 * field, the container, and the constant or input buffer region read by the
 * `Extract`.
 */
cstring debugInfoFor(const IR::BFN::Extract* extract,
                     const PHV::AllocSlice& slice,
                     const nw_bitrange& bufferRange = nw_bitrange()) {
    std::stringstream info;

    // Describe the value that's being written into the destination container.
    if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
        info << "value " << constantSource->constant << " -> "
             << slice.container() << " " << slice.container_slice() << ": ";
    } else if (extract->source->is<IR::BFN::PacketRVal>()) {
        // In the interest of brevity, don't print the range of bits being
        // extracted into the destination container if it matches the size of
        // the container exactly.
        if (slice.container().size() != size_t(bufferRange.size()))
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
                  bufferRange.shiftedByBits(-containerRange.lo)
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

                auto* newExtract = new IR::BFN::LoweredExtractPhv(slice.container(), newSource);

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

        const IR::BFN::LoweredExtractPhv* prev = nullptr;

        for (auto* extract : extracts) {
            auto* bufferSource = extract->source->to<InputBufferRValType>();

            BUG_CHECK(bufferSource, "Unexpected non-buffer source");

            if (std::is_same<InputBufferRValType, IR::BFN::LoweredMetadataRVal>::value)
                BUG_CHECK(toHalfOpenRange(Device::pardeSpec().byteInputBufferMetadataRange())
                          .contains(bufferSource->byteInterval()),
                          "Extract from out of the input buffer range: %1%",
                          bufferSource->byteInterval());

            if (prev && extract->write_mode != prev->write_mode)
                BUG("Inconsistent parser write semantic on %1%", container);

            bufferRange = bufferSource->byteInterval().unionWith(bufferRange);

            prev = extract;
        }

        BUG_CHECK(!bufferRange.empty(), "Extracting zero bytes?");

        auto extractedSizeBits = bufferRange.toUnit<RangeUnit::Bit>().size();

        BUG_CHECK(size_t(extractedSizeBits) == container.size(),
            "PHV allocation is invalid for container %1%"
            " (number of extracted bits does not match container size).", container);

        // Create a single combined extract that implements all of the
        // component extracts. Each merged extract writes to an entire container.
        const auto* finalBufferValue =
          new InputBufferRValType(*toClosedRange(bufferRange));

        auto* mergedExtract = new IR::BFN::LoweredExtractPhv(container, finalBufferValue);

        mergedExtract->write_mode = extracts[0]->write_mode;

        for (auto* extract : extracts)
            mergedExtract->debug.mergeWith(extract->debug);

        return mergedExtract;
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
            auto* merged = mergeExtractsFor<IR::BFN::LoweredPacketRVal>(container, extracts);
            loweredExtracts.push_back(merged);
        }

        sortExtractPhvs(loweredExtracts);

        for (auto& item : extractFromBufferByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto* merged = mergeExtractsFor<IR::BFN::LoweredMetadataRVal>(container, extracts);
            loweredExtracts.push_back(merged);
        }

        for (auto& item : extractConstantByContainer) {
            auto container = item.first;
            auto& extracts = item.second;
            auto* merged = mergeExtractsForConstants(container, extracts);
            loweredExtracts.push_back(merged);
        }

        for (auto cx : clotExtracts) {
            auto clot = cx.first;
            auto first_slice = clot->all_slices().front();
            auto first_field = first_slice->field();

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

            auto rval = new IR::BFN::LoweredPacketRVal(byterange);
            auto extractClot = new IR::BFN::LoweredExtractClot(is_start, rval, *(cx.first));
            if (clotTagToCsumUnit[clot->gress].count(clot->tag)) {
                extractClot->dest.csum_unit = clotTagToCsumUnit[clot->gress][clot->tag];
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

    ordered_map<const Clot*, std::vector<const IR::BFN::ExtractClot*>> clotExtracts;
};

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

        if (auto* slice_clots = clotInfo.allocated_slices(field)) {
            for (auto entry : *slice_clots) {
                auto clot = entry.second;
                if (clots.empty() || clots.back() != *clot)
                    clots.push_back(*clot);
            }

            if (clotInfo.fully_allocated(field)) continue;
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
    ComputeLoweredParserIR(const PhvInfo& phv,
                           ClotInfo& clotInfo,
                           const AllocateParserChecksums& checksumAlloc) :
        phv(phv), clotInfo(clotInfo), checksumAlloc(checksumAlloc) {
        // Initialize the map from high-level parser states to low-level parser
        // states so that null, which represents the end of the parser program
        // in the high-level IR, is mapped to null, which conveniently enough
        // means the same thing in the lowered IR.
        loweredStates[nullptr] = nullptr;
    }

    std::map<const IR::BFN::ParserState*,
             const IR::BFN::LoweredParserState*> loweredStates;

    const IR::BFN::ContainerRef* igParserError = nullptr;
    const IR::BFN::ContainerRef* egParserError = nullptr;
    unsigned egressMetaOpt = 0;
    unsigned egressMetaSize = 0;  // in byte

 private:
    bool preorder(const IR::Type_Header* type) override {
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
            } else if (auto verify = c->to<IR::BFN::ChecksumVerify>()) {
                dest = verify->dest;
            } else if (auto get = c->to<IR::BFN::ChecksumResidualDeposit>()) {
                dest = get->dest;
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
            id, masked_ranges, swap, start, end, end_pos, type, mul2);
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

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier(phv, clotInfo);
        for (auto prim : state->statements) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract);
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
            } else {
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

            IR::Vector<IR::BFN::LoweredSave> saves;

            for (const auto* save : transition->saves) {
                auto range = save->source->range.toUnit<RangeUnit::Byte>();

                IR::BFN::LoweredInputBufferRVal* source = nullptr;

                if (save->source->is<IR::BFN::MetadataRVal>())
                    source = new IR::BFN::LoweredMetadataRVal(range);
                else if (save->source->is<IR::BFN::PacketRVal>())
                    source = new IR::BFN::LoweredPacketRVal(range);
                else
                    BUG("unexpected save source: %1%", save);

                saves.push_back(new IR::BFN::LoweredSave(save->dest, source));
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
    // Maps clot tag to checksum unit whose output will be deposited in that CLOT for each gress
    std::map<gress_t, std::map<unsigned, unsigned>> clotTagToCsumUnit;
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
        if (state && (state->name.startsWith("egress::$mirror_field_list_") ||
            state->name.startsWith("egress::__parse_ingress_mirror_header_") ||
            state->name.startsWith("egress::__parse_egress_mirror_header_"))) {
            totalBytes += 4;  // offset 4 bytes of CRC added by HW for mirrored packet
        }

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

        if (state->name.endsWith("$ctr_stall"))  // compiler generated stall
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

// After parser lowering, we have converted the parser IR from P4 semantic (action->match)
// to HW semantic (match->action), there may still be opportunities where we can merge states
// where we couldn't before lowering (without breaking the P4 semantic).
struct MergeLoweredParserStates : public ParserTransform {
    const CollectLoweredParserInfo& parser_info;

    explicit MergeLoweredParserStates(const CollectLoweredParserInfo& pi) : parser_info(pi) { }

    const IR::BFN::LoweredParserMatch*
    get_unconditional_match(const IR::BFN::LoweredParserState* state) {
        if (state->select->regs.empty() && state->select->counters.empty())
            return state->transitions[0];

        return nullptr;
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

    bool can_merge(const IR::BFN::LoweredParserMatch* a, const IR::BFN::LoweredParserMatch* b) {
        if (a->hdrLenIncFinalAmt && b->hdrLenIncFinalAmt)
            return false;

        if (a->priority && b->priority)
            return false;

        if (a->offsetInc && b->offsetInc)
            return false;

        if (!a->extracts.empty() || !a->saves.empty() ||
            !a->checksums.empty() || !a->counters.empty()) {
            return false;
        }

        if (int(a->shift + b->shift) > Device::pardeSpec().byteInputBufferSize())
            return false;

        RightShiftPacketRVal shifter(a->shift);

        for (auto e : b->extracts)
            e->apply(shifter);

        for (auto e : b->saves)
            e->apply(shifter);

        for (auto e : b->checksums)
            e->apply(shifter);

        for (auto e : b->counters)
            e->apply(shifter);

        if (shifter.oob)
            return false;

        return true;
    }

    void do_merge(IR::BFN::LoweredParserMatch* match,
                   const IR::BFN::LoweredParserMatch* next) {
        RightShiftPacketRVal shifter(match->shift);

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
            match->checksums.push_back(s->to<IR::BFN::LoweredParserChecksum>());
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
        auto state = findContext<IR::BFN::LoweredParserState>();

        if (match->next && !match->next->name.find("$") && !is_loopback_state(match->next->name)) {
            if (auto next = get_unconditional_match(match->next)) {
                if (can_merge(match, next)) {
                    LOG3("merge " << match->next->name << " with "
                            << state->name << " (" << match->value << ")");

                    do_merge(match, next);
                }
            }
        }

        return match;
    }
};

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerParserIR : public PassManager {
    LowerParserIR(const PhvInfo& phv, ClotInfo& clotInfo) {
        auto* allocateParserChecksums = new AllocateParserChecksums(phv, clotInfo);
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(phv, clotInfo,
                                            *allocateParserChecksums);

        auto* parser_info = new CollectParserInfo;
        auto* lower_parser_info = new CollectLoweredParserInfo;

        addPasses({
            LOGGING(4) ? new DumpParser("before_parser_lowering") : nullptr,
            new ResolveParserConstants(phv, clotInfo),
            new ParserCopyProp(phv),
            new SplitParserState(phv, clotInfo),
            new AllocateParserMatchRegisters(phv),
            LOGGING(4) ? new DumpParser("before_elim_empty_states") : nullptr,
            parser_info,
            new ElimEmptyState(*parser_info),
            allocateParserChecksums,
            LOGGING(4) ? new DumpParser("final_hlir_parser") : nullptr,
            computeLoweredParserIR,
            new ReplaceParserIR(*computeLoweredParserIR),
            LOGGING(4) ? new DumpParser("after_parser_lowering") : nullptr,
            lower_parser_info,
            new MergeLoweredParserStates(*lower_parser_info),
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

            // unsigned startByte = totalWidth / 8;
            unsigned startByte = 0;

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
            startByte = totalWidth / 8;
            totalWidth += slice->width();

            // Place the field slice in the packing format. The field name is
            // used in assembly generation; hence, we use its external name.
            packing->emplace_back(
                    slice->field()->externalName(), startByte,
                    slice->field_slice().hi % 8, slice->width(), slice->field_slice().lo);

            // Remember information about the container placement of the last slice
            // in network order (the first one in `slices`) so we can add any
            // necessary padding on the next pass around the loop.
            last = LastContainerInfo{ slice->container(), slice->container_slice().lo };
        }
    }

    return packing;
}

struct RewriteEmitClot : public DeparserModifier {
    RewriteEmitClot(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    bool preorder(IR::BFN::Deparser* deparser) override {
        // Replace Emits covered in a CLOT with EmitClot

        IR::Vector<IR::BFN::Emit> newEmits;

        // The next field slices we expect to see being emitted, represented as a stack. These are
        // field slices left over from the last emitted CLOT.
        std::vector<const PHV::FieldSlice*> expectedNextSlices;

        const PHV::FieldSlice* lastPhvPovBit = nullptr;
        const Clot* lastClot = nullptr;

        for (auto emit : deparser->emits) {
            auto irPovBit = emit->povBit;

            le_bitrange slice;
            auto phvPovBitField = phv.field(irPovBit->field, &slice);

            BUG_CHECK(phvPovBitField, "No PHV field for %1%", irPovBit);
            PHV::FieldSlice* phvPovBit = new PHV::FieldSlice(phvPovBitField, slice);

            const IR::Expression* source = nullptr;

            if (auto ef = emit->to<IR::BFN::EmitField>()) {
                source = ef->source->field;
            } else if (auto ec = emit->to<IR::BFN::EmitChecksum>()) {
                source = ec->dest->field;
            } else if (auto cc = emit->to<IR::BFN::EmitConstant>()) {
                newEmits.pushBackOrAppend(cc);

                // we disallow CLOTs from being overwritten by deparser constants
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
                // The current slice being emitted had better line up with the next expected slice,
                // and the expected POV bit had better match.
                auto nextSlice = expectedNextSlices.back();

                BUG_CHECK(nextSlice->field() == field,
                          "Emitted field %1% does not match expected slice %2% in CLOT %3%",
                          field->name, nextSlice->shortString(), lastClot->tag);
                BUG_CHECK(nextSlice->range().hi == nextFieldBit,
                          "Emitted slice %1% does not line up with expected slice %2% in CLOT %3%",
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString(),
                          nextSlice->shortString(),
                          lastClot->tag);
                BUG_CHECK(*phvPovBit == *lastPhvPovBit,
                          "POV bit %1% for emit of %2% does not match expected POV bit %3% for "
                          "CLOT %4%",
                          phvPovBit->shortString(),
                          field->name,
                          lastPhvPovBit->shortString(),
                          lastClot->tag);

                nextFieldBit = nextSlice->range().lo - 1;
                expectedNextSlices.pop_back();
            }

            // If we've covered all bits in the current field, move on to the next emit.
            if (nextFieldBit == -1) continue;

            // We haven't covered all bits in the current field yet. The next bit in the field must
            // be in a new CLOT, if it is covered by a CLOT at all. There had better not be any
            // slices left over from the last emitted CLOT.
            BUG_CHECK(expectedNextSlices.empty(),
                "Emitted slice %1% does not match expected slice %2% in CLOT %3%",
                PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString(),
                expectedNextSlices.back()->shortString(),
                lastClot->tag);

            if (sliceClots->empty()) {
                // None of this field should have come from CLOTs.
                BUG_CHECK(nextFieldBit == field->size - 1,
                          "Field %1% has no slices allocated to CLOTs, but %2% somehow came from "
                          "CLOT %3%",
                          field->name,
                          PHV::FieldSlice(field,
                                          StartLen(nextFieldBit + 1,
                                                   field->size - nextFieldBit)).shortString(),
                          lastClot->tag);

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
                    newEmits.pushBackOrAppend(sliceEmit);

                    nextFieldBit = slice->range().hi;
                }

                // Make sure the first slice in the CLOT lines up with the slice we're expecting.
                auto clotSlices = clot->all_slices();
                auto firstSlice = clotSlices.front();
                BUG_CHECK(firstSlice->field() == field,
                          "First field in CLOT %1% is %2%, but expected %3%",
                          clot->tag, firstSlice->field()->name, field->name);
                BUG_CHECK(firstSlice->range().hi == nextFieldBit,
                          "First slice %1% in CLOT %2% does not match expected slice %3%",
                          firstSlice->shortString(),
                          clot->tag,
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString());

                // Produce an emit for the CLOT.
                auto clotEmit = new IR::BFN::EmitClot(irPovBit);
                clotEmit->clot = clot;
                newEmits.pushBackOrAppend(clotEmit);
                lastPhvPovBit = phvPovBit;
                lastClot = clot;

                nextFieldBit = firstSlice->range().lo - 1;

                if (clotSlices.size() == 1) continue;

                // There are more slices in the CLOT. We had better be done with the current field.
                BUG_CHECK(nextFieldBit == -1,
                          "CLOT %1% is missing slice %2%",
                          clot->tag,
                          PHV::FieldSlice(field, StartLen(0, nextFieldBit + 1)).shortString());

                std::copy(clotSlices.rbegin(), --clotSlices.rend(),
                          std::back_inserter(expectedNextSlices));
            }

            if (nextFieldBit != -1) {
                BUG_CHECK(expectedNextSlices.empty(),
                          "CLOT %1% is missing slice %2%",
                          lastClot->tag,
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
            out << "CLOT " << lastClot->tag << " has extra field slices not covered by the "
                << "deparser before RewriteEmitClot: ";
            for (auto it = expectedNextSlices.rbegin(); it != expectedNextSlices.rend(); ++it) {
                if (it != expectedNextSlices.rbegin()) out << ", ";
                out << (*it)->shortString();
            }
            BUG("%s", out.str());
        }

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

/// Generate the lowered deparser IR by splitting references to fields in the
/// high-level deparser IR into references to containers.
struct ComputeLoweredDeparserIR : public DeparserInspector {
    ComputeLoweredDeparserIR(const PhvInfo& phv, const ClotInfo& clotInfo)
      : phv(phv), clotInfo(clotInfo), lastChecksumUnit(boost::none), lastSharedUnit(0) {
        igLoweredDeparser = new IR::BFN::LoweredDeparser(INGRESS);
        egLoweredDeparser = new IR::BFN::LoweredDeparser(EGRESS);
    }

    /// The lowered deparser IR generated by this pass.
    IR::BFN::LoweredDeparser* igLoweredDeparser;
    IR::BFN::LoweredDeparser* egLoweredDeparser;

 private:
    IR::Vector<IR::BFN::FieldLVal>
    removeDeparserZeroFields(IR::Vector<IR::BFN::FieldLVal> checksumFields) {
        // Fields which are deparser zero candidate are guaranteed to be zero
        // Removing such fields will not alter checksum.
        IR::Vector<IR::BFN::FieldLVal> newChecksumFields;
        for (auto cfield : checksumFields) {
            auto* phv_field = phv.field(cfield->field);
            if (!phv_field->is_deparser_zero_candidate()) {
                newChecksumFields.push_back(cfield);
            }
        }
        return newChecksumFields;
    }

    IR::BFN::ChecksumUnitConfig* lowerChecksum(const IR::BFN::EmitChecksum* emitChecksum,
                                               unsigned checksumUnit) {
        // Allocate a checksum unit and generate the configuration for it.
        if (checksumUnit >= Device::pardeSpec().numDeparserChecksumUnits()) {
            ::fatal_error("Number of deparser checksum updates exceeds the number of checksum"
            " engines available. Checksum engine not allocated for destination %1%",
            emitChecksum->dest);
        }
        auto* unitConfig = new IR::BFN::ChecksumUnitConfig(checksumUnit);
        auto containerToSwap = getChecksumPhvSwap(phv, emitChecksum);
        unitConfig->zeros_as_ones = emitChecksum->zeros_as_ones;
        IR::Vector<IR::BFN::ContainerRef> phvSources;
        std::vector<Clot> clotSources;

        if (Device::currentDevice() == Device::TOFINO) {
            IR::Vector<IR::BFN::FieldLVal> checksumFields;
            for (auto f : emitChecksum->sources) {
                checksumFields.push_back(f->field);
            }
            checksumFields = removeDeparserZeroFields(checksumFields);
            std::tie(phvSources, clotSources) = lowerFields(phv, clotInfo, checksumFields);
            for (auto* source : phvSources) {
                auto* input = new IR::BFN::ChecksumPhvInput(source);
                input->swap = containerToSwap[source->container];
                unitConfig->phvs.push_back(input);
            }
        } else if (Device::currentDevice() != Device::TOFINO) {
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
                std::tie(phvSources, clotSources) = lowerFields(phv, clotInfo, *group.first);
                auto povBit = lowerSingleBit(phv, group.second,
                                                  PHV::AllocContext::DEPARSER);
                for (auto* source : phvSources) {
                    auto* input = new IR::BFN::ChecksumPhvInput(source);
                    input->swap = containerToSwap[source->container];
                    input->povBit = povBit;
                    unitConfig->phvs.push_back(input);
                }
                for (auto source : clotSources) {
                    auto* input = new IR::BFN::ChecksumClotInput(source, povBit);
                    unitConfig->clots.push_back(input);
                }
                groupidx++;
            }
            unitConfig->povBit = lowerSingleBit(phv, emitChecksum->povBit,
                                           PHV::AllocContext::DEPARSER);
        }
        return unitConfig;
    }

    unsigned int getChecksumUnit() {
        if (lastChecksumUnit == boost::none) {
            lastChecksumUnit = 0;
        } else {
            (*lastChecksumUnit)++;
        }
        if (*lastChecksumUnit > 1 && Device::currentDevice() == Device::TOFINO) {
            return (*lastChecksumUnit + lastSharedUnit);
        }
        return *lastChecksumUnit;
    }

    bool preorder(const IR::BFN::Deparser* deparser) override {
        auto* loweredDeparser = deparser->gress == INGRESS ? igLoweredDeparser
                                                           : egLoweredDeparser;

        // Reset the next checksum unit if needed. On Tofino, each thread has
        // its own checksum units. On JBay they're shared, and their ids are
        // global, so on that device we don't reset the next checksum unit for
        // each deparser.
        if (Device::currentDevice() == Device::TOFINO) {
            if (lastChecksumUnit != boost::none && *lastChecksumUnit > 1) {
                lastSharedUnit = *lastChecksumUnit - 1;
            }
            lastChecksumUnit = boost::none;
       }

        struct LastSimpleEmitInfo {
            /// The `PHV::Field::id` of the POV bit for the last simple emit.
            int povFieldId;
            /// The actual range of bits (of size 1) corresponding to the POV
            /// bit for the last simple emit.
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
                        auto checksumUnit = getChecksumUnit();
                        cl->csum_field_to_csum_id[f] = checksumUnit;
                        auto unitConfig = lowerChecksum(emitChecksum, checksumUnit);
                        loweredDeparser->checksums.push_back(unitConfig);
                    }
                }

                continue;
            }

            // If this is a checksum emit primitive, lower it.
            if (auto* emitChecksum = group.back()->to<IR::BFN::EmitChecksum>()) {
                BUG_CHECK(group.size() == 1,
                          "Checksum primitives should be in a singleton group");
                auto checksumUnit = getChecksumUnit();
                auto unitConfig = lowerChecksum(emitChecksum, checksumUnit);
                loweredDeparser->checksums.push_back(unitConfig);

                // Generate the lowered checksum emit.
                auto* loweredPovBit = lowerSingleBit(phv,
                                                     emitChecksum->povBit,
                                                     PHV::AllocContext::DEPARSER);
                auto* loweredEmit =
                  new IR::BFN::LoweredEmitChecksum(loweredPovBit, checksumUnit);

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
            auto* loweredSource =
                lowerUnsplittableField(phv, clotInfo, param->source, "deparser parameter");
            auto* lowered = new IR::BFN::LoweredDeparserParameter(param->name,
                                                                  loweredSource);
            if (param->povBit)
                lowered->povBit = lowerSingleBit(phv,
                                                 param->povBit,
                                                 PHV::AllocContext::DEPARSER);
            loweredDeparser->params.push_back(lowered);
        }

        // Filter padding field out of digest field list
        auto filterPaddingField =
            [&](const IR::BFN::DigestFieldList* fl)->IR::BFN::DigestFieldList* {
            auto sources = new IR::Vector<IR::BFN::FieldLVal>();
            for (auto src : fl->sources) {
                /// do not emit padding field in digest field list.
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
                std::vector<Clot> clotSources;

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
    boost::optional<unsigned>lastChecksumUnit;
    unsigned lastSharedUnit;
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
            rewriteEmitClot,
            computeLoweredDeparserIR,
            new ReplaceDeparserIR(computeLoweredDeparserIR->igLoweredDeparser,
                                  computeLoweredDeparserIR->egLoweredDeparser)
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
                if (extract->write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE)
                    clear_on_write[extract->dest->container].insert(orig);
                else
                    bitwise_or[extract->dest->container].insert(orig);
            }
        }

        for (auto csum : match->checksums) {
            if (csum->csum_err)
                bitwise_or[csum->csum_err->container->container].insert(orig);
        }

        return true;
    }

    bool preorder(IR::BFN::LoweredParser*) override {
        bitwise_or = clear_on_write = {};
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

    std::set<PHV::Container>
    detect_multi_writes(const IR::BFN::LoweredParser* parser,
            const std::map<PHV::Container, std::set<const IR::BFN::LoweredParserMatch*>>& writes,
            const char* which) {
        std::set<PHV::Container> results;

        for (auto w : writes) {
            if (has_non_mutex_writes(parser, w.second)) {
                results.insert(w.first);
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
                            results.insert(w.first);
                            results.insert(other);
                            LOG4("mark " << w.first << " and " << other << " as "
                                         << which << " (even-and-odd pair)");
                        }
                    }
                }
            }
        }

        return results;
    }

    void postorder(IR::BFN::LoweredParser* parser) override {
        auto orig = getOriginal<IR::BFN::LoweredParser>();

        auto bitwise_or_containers = detect_multi_writes(orig, bitwise_or, "bitwise-or");

        auto clear_on_write_containers =
            detect_multi_writes(orig, clear_on_write, "clear-on-write");

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

LowerParser::LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse) :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    auto pragma_no_init = new PragmaNoInit(phv);
    auto compute_init_valid =
        new ComputeInitZeroContainers(phv, defuse, pragma_no_init->getFields());
    auto parser_info = new CollectLoweredParserInfo;

    addPasses({
        pragma_no_init,
        new LowerParserIR(phv, clot),
        new LowerDeparserIR(phv, clot),
        new WarnTernaryMatchFields(phv),
        Device::currentDevice() == Device::TOFINO ? compute_init_valid : nullptr,
        parser_info,
        new ComputeMultiWriteContainers(phv, *parser_info),
        new ComputeBufferRequirements,
        new CharacterizeParser
    });
}
