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
#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/allocate_parser_match_register.h"
#include "bf-p4c/parde/characterize_parser.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/split_parser_state.h"
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

/// Helper class that splits extract operations into multiple smaller extracts,
/// such that each extract writes to exactly one PHV container.
struct ExtractSimplifier {
    const PhvInfo& phv;
    const ClotInfo& clot;

    ExtractSimplifier(const PhvInfo& phv, const ClotInfo& clot) : phv(phv), clot(clot) { }

    using ExtractSequence = std::vector<const IR::BFN::LoweredExtractPhv*>;

    /// Add a new extract operation to the sequence.
    void add(const IR::BFN::Extract* extract) {
        LOG4("adding " << extract);

        auto field = phv.field(extract->dest->field);

        if (auto c = clot.clot(field)) {
            clotExtracts[c].push_back(extract);

            if (!c->is_phv_field(field))
                return;
        }

        std::vector<alloc_slice> slices = phv.get_alloc(extract->dest->field);
        if (slices.empty()) {
            BUG("Parser extract didn't receive a PHV allocation: %1%", extract);
            return;
        }

        // TODO(zma) we should have single slice at this point

        for (const auto& slice : slices)
            BUG_CHECK(bool(slice.container),
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
                  slice.container_bits().toOrder<Endian::Network>(slice.container.size());

                const nw_bitrange finalBufferRange =
                  bufferRange.shiftedByBits(-containerRange.lo)
                             .resizedToBits(slice.container.size());

                LOG4("mapping input buffer field slice " << bufferRange
                      << " into " << slice.container << " " << containerRange
                      << ". Final buffer range: " << finalBufferRange);

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

                auto constSlice = *(constantSource->constant);
                constSlice = constSlice & IR::Constant::GetMask(slice.width);

                // Place those bits at their offset within the container.
                constSlice = constSlice << slice.container_bits().lo;

                BUG_CHECK(constSlice.fitsUint(), "Constant slice larger than 32-bit?");

                // Create an extract that writes just those bits.
                if (constSlice.asUnsigned()) {
                    LOG4("  Placing constant slice " << constSlice << " into " << slice.container);

                    auto* newSource =
                      new IR::BFN::LoweredConstantRVal(constSlice.asUnsigned());
                    auto* newExtract =
                      new IR::BFN::LoweredExtractPhv(slice.container, newSource);

                    newExtract->debug.info.push_back(debugInfoFor(extract, slice));
                    extractConstantByContainer[slice.container].push_back(newExtract);
                }
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
                BUG_CHECK(toHalfOpenRange(Device::pardeSpec().byteInputBufferMetadataRange())
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

        for (auto cx : clotExtracts) {
            bool is_start = false;
            nw_bitinterval bitInterval;

            for (auto extract : cx.second) {
                auto rval = extract->source->to<IR::BFN::PacketRVal>();
                bitInterval = bitInterval.unionWith(rval->interval());

                auto dest = phv.field(extract->dest->field);
                if (cx.first->is_first_field_in_clot(dest)) {
                    if (extract->dest->field->is<IR::Member>()) {
                        is_start = true;
                    } else if (auto sl = extract->dest->field->to<IR::Slice>()) {
                        if (sl->getH() == dest->size - 1)  // first slice of field
                            is_start = true;
                    }
                }
            }

            nw_bitrange bitrange = *toClosedRange(bitInterval);
            nw_byterange byterange = bitrange.toUnit<RangeUnit::Byte>();

            auto rval = new IR::BFN::LoweredPacketRVal(byterange);
            auto extractClot = new IR::BFN::LoweredExtractClot(is_start, rval, *(cx.first));
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

    std::map<const Clot*, std::vector<const IR::BFN::Extract*>> clotExtracts;
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
            if (clots.empty() || clots.back() != *clot)
                clots.push_back(*clot);
            continue;
        }

        // padding in digest list does not need phv allocation
        if (field->is_ignore_alloc())
            continue;

        std::vector<alloc_slice> slices = phv.get_alloc(fieldRef->field);

        BUG_CHECK(!slices.empty(),
                  "Emitted field didn't receive a PHV allocation: %1%",
                  fieldRef->field);

        for (auto& slice : boost::adaptors::reverse(slices)) {
            if (!slice.isUsedDeparser()) continue;
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

            if (slice.field->is_checksummed() && slice.field->no_pack()) {
                // Since the field has a no-pack constraint, its is safe to
                // extend the range till the end of container
                last->range = containerRange.unionWith(nw_bitrange(
                               StartLen(0, slice.container.size())));
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

    std::vector<alloc_slice> slices;
    field->foreach_alloc(&range, ctxt, nullptr, [&](const PHV::Field::alloc_slice& alloc) {
        slices.push_back(alloc);
    });

    BUG_CHECK(!slices.empty(), "bit %1% didn't receive a PHV allocation",
              fieldRef->field);
    BUG_CHECK(slices.size() == 1, "bit %1% is somehow split across "
              "multiple containers?", fieldRef->field);

    auto container = new IR::BFN::ContainerRef(slices.back().container);
    auto containerRange = slices.back().container_bits();
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

    LoweredParserIRStates loweredStates;
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

            // JBay requires the egress intrinsic metadata to be padded to 4-byte aligned
            if (Device::currentDevice() == Device::JBAY) {
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

        std::map<cstring,
                 std::vector<const IR::BFN::ParserChecksumPrimitive*>> csum_to_prims;

        for (auto prim : checksums)
            csum_to_prims[prim->declName].push_back(prim);

        for (auto& kv : csum_to_prims) {
            auto csum = lowerParserChecksum(parser, state, kv.first, kv.second);
            loweredChecksums.push_back(csum);
        }

        return loweredChecksums;
    }

    int getHeaderEndPos(const IR::BFN::ChecksumSubtract* lastSubtract) {
        auto v = lastSubtract->source->to<IR::BFN::PacketRVal>();
        int lastBitSubtract = v->range.toUnit<RangeUnit::Bit>().hi;
        BUG_CHECK(lastBitSubtract % 8 == 7,
                "Fields in checksum subtract %1% are not byte-aligned", v);
        auto* headerRef = lastSubtract->field->expr->to<IR::ConcreteHeaderRef>();
        auto header = headerRef->baseRef();
        int endPos = 0;
        for (auto field :  header->type->fields) {
            if (field->name == lastSubtract->field->member) {
                endPos = lastBitSubtract;
            } else if (endPos > 0) {
                endPos += field->type->width_bits();
            }
        }
        return endPos/8;
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

        std::set<nw_byterange> masked_ranges;

        for (auto c : checksums) {
            if (auto add = c->to<IR::BFN::ChecksumAdd>()) {
                if (auto v = add->source->to<IR::BFN::PacketRVal>())
                    masked_ranges.insert(v->range.toUnit<RangeUnit::Byte>());
            } else if (auto sub = c->to<IR::BFN::ChecksumSubtract>()) {
                if (auto v = sub->source->to<IR::BFN::PacketRVal>())
                    masked_ranges.insert(v->range.toUnit<RangeUnit::Byte>());
            } else if (auto verify = c->to<IR::BFN::ChecksumVerify>()) {
                dest = verify->dest;
            } else if (auto get = c->to<IR::BFN::ChecksumGet>()) {
                dest = get->dest;
            }
        }

        auto last = checksums.back();

        int end_pos = 0;
        if (end) {
            if (last->is<IR::BFN::ChecksumGet>()) {
                auto last_subtract = checksums.rbegin()[1]->to<IR::BFN::ChecksumSubtract>();
                end_pos = getHeaderEndPos(last_subtract);
            }
        }

        auto csum = new IR::BFN::LoweredParserChecksum(
            id, masked_ranges, 0x0, start, end, end_pos, type);

        std::vector<alloc_slice> slices;

        // FIXME(zma) this code could use some cleanup, what a mess ...
        if (dest) {
            auto f = phv.field(dest->field);
            slices = phv.get_alloc(f, nullptr);  // XXX(zma)
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
                csum->csum_err = lowerSingleBit(phv, dest, PHV::AllocContext::PARSER);
            }
        } else if (type == IR::BFN::ChecksumMode::RESIDUAL && dest) {
            csum->phv_dest = new IR::BFN::ContainerRef(slices.back().container);
        } else if (type == IR::BFN::ChecksumMode::CLOT && end) {
            auto deposit = last->to<IR::BFN::ChecksumDepositToClot>();
            BUG_CHECK(deposit, "clot checksum does not end with a deposit?");
            csum->clot_dest = *deposit->clot;
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
        const IR::BFN::HdrLenIncStop* stopper = nullptr;

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier(phv, clotInfo);

        for (auto prim : state->statements) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract);
            } else if (auto* csum = prim->to<IR::BFN::ParserChecksumPrimitive>()) {
                checksums.push_back(csum);
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

        auto loweredExtracts = simplifier.lowerExtracts();

        auto parser = findContext<IR::BFN::Parser>();
        auto loweredChecksums = lowerParserChecksums(parser, state, checksums);

        /// Convert multiple select into one.
        auto* loweredSelect = new IR::BFN::LoweredSelect();
        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            // Load match register from previous result.
            for (auto rs : select->reg_slices)
                loweredSelect->regs.insert(rs.first);

            if (auto* bufferSource = select->source->to<IR::BFN::InputBufferRVal>()) {
                const auto bufferRange =
                    bufferSource->range.toUnit<RangeUnit::Byte>();
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
                            save->source->range.toUnit<RangeUnit::Byte>()));
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
                    loweredExtracts,
                    saves,
                    loweredChecksums,
                    priority,
                    loweredStates[transition->next]);

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

    const PhvInfo& phv;
    ClotInfo& clotInfo;
    const AllocateParserChecksums& checksumAlloc;
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

        // assume tna parser instance architecture name is
        // ingress_parser<n> and egress_parser<n>
        static std::vector<cstring> gressName = {"ingress", "egress", "ghost"};
        cstring parserName = gressName[parser->gress] + "_parser";
        auto pipe = findOrigCtxt<IR::BFN::Pipe>();
        auto parsers = pipe->thread[parser->gress].parsers;
        auto it = std::find_if(parsers.begin(), parsers.end(),
                [&parser](const IR::BFN::AbstractParser *p) -> bool {
            return p->to<IR::BFN::Parser>()->equiv(*parser->getNode()); });
        if (it != parsers.end() && parser->portmap.size() != 0 /* true if multiple parsers */) {
            parserName = parserName + cstring::to_cstring(it - parsers.begin()); }

        auto* loweredParser =
          new IR::BFN::LoweredParser(parser->gress, computed.loweredStates.at(parser->start),
                                     parser->phase0, parserName, parser->portmap);

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
        if (state && state->name.startsWith("egress::$mirror_field_list_")) {
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
    LowerParserIR(const PhvInfo& phv, ClotInfo& clotInfo) {
        auto* allocateParserChecksums = new AllocateParserChecksums(phv, clotInfo);
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(phv, clotInfo,
                                            *allocateParserChecksums);
        addPasses({
            LOGGING(4) ? new DumpParser("before_parser_lowering") : nullptr,
            new ResolveParserConstants(phv, clotInfo),
            new SplitParserState(phv, clotInfo),
            new AllocateParserMatchRegisters(phv),
            allocateParserChecksums,
            LOGGING(4) ? new DumpParser("final_hlir_parser") : nullptr,
            computeLoweredParserIR,
            new ReplaceParserIR(*computeLoweredParserIR),
            LOGGING(4) ? new DumpParser("after_parser_lowering") : nullptr
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

    boost::optional<LastContainerInfo> last = boost::make_optional(false, LastContainerInfo());
    auto* packing = new BFN::FieldPacking;

    // Walk over the field sequence in network order and construct a
    // FieldPacking that reflects its structure, with padding added where
    // necessary to reflect gaps between the fields.
    for (auto* fieldRef : fields) {
        std::vector<alloc_slice> slices = phv.get_alloc(fieldRef->field);

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
        // Replace Emits covered in a CLOT with EmitClot

        IR::Vector<IR::BFN::Emit> newEmits;

        // The next fields we expect to see being emitted, represented as a stack. These are fields
        // left over from the last emitted CLOT.
        std::vector<const PHV::Field*> expectedNextFields;

        const PHV::FieldSlice* lastPhvPovBit = nullptr;
        const Clot* lastClot = nullptr;

        for (auto emit : deparser->emits) {
            auto irPovBit = emit->povBit;
            le_bitrange slice;
            auto phvPovBitField = phv.field(irPovBit->field, &slice);
            BUG_CHECK(phvPovBitField, "No PHV field for %1%", irPovBit);
            PHV::FieldSlice* phvPovBit = new PHV::FieldSlice(phvPovBitField, slice);

            const IR::Expression* source = nullptr;

            if (auto ef = emit->to<IR::BFN::EmitField>())
                source = ef->source->field;
            else if (auto ec = emit->to<IR::BFN::EmitChecksum>())
                source = ec->dest->field;

            BUG_CHECK(source, "No emit source for %1%", emit);

            auto field = phv.field(source);
            auto clot = clotInfo.clot(field);
            auto emit_csum = emit->to<IR::BFN::EmitChecksum>();

            // If we are emitting a checksum that overwrites a CLOT, register this fact with
            // ClotInfo.
            if (clot && emit_csum) clotInfo.clot_to_emit_checksum()[clot] = emit_csum;

            if (expectedNextFields.empty()) {
                // No fields left over from the last emitted CLOT. If we are emitting a new CLOT,
                // replace the current emit with a CLOT emit.
                if (clot) {
                    auto clotEmit = new IR::BFN::EmitClot(irPovBit);
                    clotEmit->clot = clot;
                    emit = clotEmit;

                    auto clotFields = clot->all_fields();
                    std::copy(clotFields.rbegin(), --clotFields.rend(),
                              std::back_inserter(expectedNextFields));

                    lastPhvPovBit = phvPovBit;
                    lastClot = clot;
                }

                newEmits.pushBackOrAppend(emit);
                continue;
            }

            // We have fields left over from the last emitted CLOT. The current field and POV bit
            // had better match what we are expecting.
            BUG_CHECK(expectedNextFields.back() == field,
                      "Emitted field %1% does not match expected field %2% in CLOT %3%",
                      field->name, expectedNextFields.back()->name, lastClot->tag);
            BUG_CHECK(*phvPovBit == *lastPhvPovBit,
                      "POV bit %1% for emit of %2% does not match expected POV bit %3% for CLOT "
                      "%4%",
                      phvPovBit->shortString(),
                      field->name,
                      lastPhvPovBit->shortString(),
                      lastClot->tag);
            expectedNextFields.pop_back();
        }

        if (!expectedNextFields.empty()) {
            std::stringstream out;
            out << "CLOT " << lastClot->tag << " has extra fields not covered by the deparser "
                << "before RewriteEmitClot: ";
            for (auto it = expectedNextFields.rbegin(); it != expectedNextFields.rend(); ++it) {
                if (it != expectedNextFields.rbegin()) out << ", ";
                out << (*it)->name;
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
    for (auto &sourceToOffset : emitChecksum->source_index_to_offset) {
        auto* phv_field = phv.field(emitChecksum->sources[sourceToOffset.first]->field);
        std::vector<alloc_slice> slices = phv.get_alloc(phv_field);
        int offset = sourceToOffset.second;
        for (auto& slice : boost::adaptors::reverse(slices)) {
            unsigned swap = 0;
            bool isResidualChecksum = false;
            std::string f_name(phv_field->name.c_str());
            if (f_name.find("compiler_generated_meta") != std::string::npos
             && f_name.find("residual_checksum_") != std::string::npos)
                isResidualChecksum = true;

            if (!isResidualChecksum &&
                (offset/8) % 2 != (slice.container_bits().hi/8 + 1) % 2) {
                swap = (1 << slice.container_bits().hi/16U) |
                             (1 << slice.container_bits().lo/16U);
            }
            offset += slice.width;
            containerToSwap[slice.container] = swap;
        }
    }
    return containerToSwap;
}

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
    IR::BFN::ChecksumUnitConfig* lowerChecksum(const IR::BFN::EmitChecksum* emitChecksum) {
        // Allocate a checksum unit and generate the configuration for it.
        auto* unitConfig = new IR::BFN::ChecksumUnitConfig(nextChecksumUnit);

        IR::Vector<IR::BFN::ContainerRef> phvSources;
        std::vector<Clot> clotSources;

        std::tie(phvSources, clotSources) =
            lowerFields(phv, clotInfo, emitChecksum->sources);

        auto* loweredPovBit = lowerSingleBit(phv,
                                             emitChecksum->povBit,
                                             PHV::AllocContext::DEPARSER);
        auto containerToSwap = getChecksumPhvSwap(phv, emitChecksum);
        for (auto* source : phvSources) {
            auto* input = new IR::BFN::ChecksumPhvInput(source);
            input->swap = containerToSwap[source->container];
            if (Device::currentDevice() == Device::JBAY)
                input->povBit = loweredPovBit;
            unitConfig->phvs.push_back(input);
        }
        for (auto source : clotSources) {
            auto* input = new IR::BFN::ChecksumClotInput(source, loweredPovBit);
            unitConfig->clots.push_back(input);
        }
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
            // Some complex emit primitives exist which can't be merged with
            // other primitives. We place this kind of primitive in a group by
            // itself. (At this point, EmitChecksum is the only thing in this
            // category, but one can imagine that future hardware may introduce
            // others.)
            if (!prim->is<IR::BFN::EmitField>()) {
                if (prim->is<IR::BFN::EmitChecksum>()) {
                    LOG5(" - Placing complex emit in its own group: " << prim);
                    groupedEmits.emplace_back(1, prim);
                } else if (prim->is<IR::BFN::EmitClot>()) {
                    groupedEmits.emplace_back(1, prim);
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
                auto* loweredPovBit = lowerSingleBit(phv,
                                                     emitChecksum->povBit,
                                                     PHV::AllocContext::DEPARSER);

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

/// Locate all containers that are written more than once by the parser (and
/// hence need the "multiwrite" bit set).
/// Must run after ComputeInitZeroContainers, because those containers probably
/// need to be on the multi_write list, if packed with other field wrote in parser.
class ComputeMultiwriteContainers : public ParserModifier {
    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        for (auto* stmt : match->extracts)
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

        auto ctxt = PHV::AllocContext::PARSER;
        for (const auto& f : phv) {
            if (f.gress != parser->gress) continue;

            // POV bits are treated as metadata
            if (f.pov || f.metadata) {
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::Field::alloc_slice& alloc) {
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
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::Field::alloc_slice& alloc) {
                    intrinsic_invalidate_containers.insert(alloc.container);
                    LOG3(alloc.container << " contains intrinsic invalidate fields");
                });
                continue;
            }

            if (defuse.hasUninitializedRead(f.id)) {
                // If pa_no_init specified, then the field does not have to rely on parser zero
                // initialization.
                if (no_init_fields.count(&f)) continue;
                f.foreach_alloc(ctxt, nullptr, [&] (const PHV::Field::alloc_slice& alloc) {
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

        const unsigned inputBufferSize = Device::pardeSpec().byteInputBufferSize();
        BUG_CHECK(*match->bufferRequired <= inputBufferSize,
                  "Parser state %1% requires %2% bytes to be buffered which "
                  "is greater than the size of the input buffer (%3% byte)",
                  findContext<IR::BFN::LoweredParserState>()->name,
                  *match->bufferRequired, inputBufferSize);
    }
};

}  // namespace

LowerParser::LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse) :
    Logging::PassManager("parser", Logging::Mode::AUTO) {
    auto* pragma_no_init = new PragmaNoInit(phv);
    addPasses({
        pragma_no_init,
        new LowerParserIR(phv, clot),
        new LowerDeparserIR(phv, clot),
        new WarnTernaryMatchFields(phv),
        new ComputeInitZeroContainers(phv, defuse, pragma_no_init->getFields()),
        new ComputeMultiwriteContainers,  // Must run after ComputeInitZeroContainers.
        new ComputeBufferRequirements,
        new CharacterizeParser
    });
}
