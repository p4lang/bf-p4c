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
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
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
cstring debugInfoFor(const IR::BFN::FieldLVal* fieldRef,
                     const alloc_slice& slice,
                     bool includeContainerInfo = true) {
    std::stringstream info;

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
    } else if (extract->source->is<IR::BFN::BufferRVal>()) {
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

        std::vector<alloc_slice> slices = phv.get_alloc(extract->dest->field);

        auto field = phv.field(extract->dest->field);
        if (auto c = clot.clot(field)) {
            clotExtracts[c].push_back(extract);
            if (!c->is_phv_field(field))
                return;
        }

        if (slices.empty()) {
            BUG("Parser extract didn't receive a PHV allocation: %1%", extract);
            return;
        }

        for (const auto& slice : slices)
            BUG_CHECK(bool(slice.container),
                      "Parser extracts into invalid PHV container: %1%", extract);

        if (auto* bufferSource = extract->source->to<IR::BFN::BufferlikeRVal>()) {
            for (const auto& slice : slices) {
                // Shift the slice to its proper place in the input buffer.
                auto bitOffset = bufferSource->range().lo;
                const nw_bitrange bufferRange = slice.field_bits()
                  .toOrder<Endian::Network>(extract->dest->size())
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
                    newSource = new IR::BFN::LoweredBufferRVal(byteFinalBufferRange);

                auto* newExtract = new IR::BFN::LoweredExtractPhv(slice.container, newSource);
                newExtract->debug.info.push_back(debugInfoFor(extract, slice,
                                                              bufferRange));

                if (bufferSource->is<IR::BFN::PacketRVal>())
                    extractFromPacketByContainer[slice.container].push_back(newExtract);
                else
                    extractFromBufferByContainer[slice.container].push_back(newExtract);
            }
        } else if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
            for (const auto& slice : slices) {
                // We need to generate a mask from this slice that will pull out
                // the relevant bits of the constant value. Because we're
                // applying the mask at compile time, we need to transform this
                // slice into host endian order. We'll also treat it as a
                // half-open range to simplify the math.
                le_bitinterval sliceBits = toHalfOpenRange(slice.field_bits())
                  .toOrder<Endian::Little>(slice.field->size);

                // Construct a mask with all 1's in [0, slice.hi).
                const unsigned long hiMask = (1 << sliceBits.hi) - 1;
                // Construct a mask with all 1's in [slice.lo, ∞).
                const unsigned long loMask = (~0ul) << sliceBits.lo;
                // Construct a mask with all 1's in [slice.lo, slice.hi).
                const unsigned long mask = hiMask & loMask;

                // Pull out the bits of the value that belong to this slice.
                // XXX(yumin): It is safe here to convert int with mask to unsigned
                // here, and needed, because the following left shift might cause overflow.
                uint32_t maskedValue = constantSource->constant->asInt() & mask;

                // Place those bits at their offset within the container.
                maskedValue <<= slice.container_bits()
                  .toOrder<Endian::Little>(slice.container.size()).lo;

                LOG4(" - Placing slice " << sliceBits << " (mask " << mask
                      << ") into " << slice.container << ". Final value: "
                      << maskedValue);

                // Create an extract that writes just those bits.
                auto* newSource =
                  new IR::BFN::LoweredConstantRVal(maskedValue);
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

    template <typename BufferlikeRValType>
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
            auto* bufferSource = extract->source->to<BufferlikeRValType>();
            BUG_CHECK(bufferSource, "Unexpected non-buffer source");

            if (std::is_same<BufferlikeRValType, IR::BFN::LoweredBufferRVal>::value)
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
          new BufferlikeRValType(*toClosedRange(bufferRange));
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
            auto* merged = mergeExtractsFor<IR::BFN::LoweredBufferRVal>(container, extracts);
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
            nw_bitinterval bitInterval;

            for (auto extract : cx.second) {
                if (auto* bufferSource = extract->source->to<IR::BFN::PacketRVal>())
                    bitInterval = bitInterval.unionWith(bufferSource->interval());
                else
                    BUG("not sure if CLOT can extract constant");
            }

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

    std::map<const Clot*, std::vector<const IR::BFN::Extract*>> clotExtracts;
};

using LoweredParserIRStates = std::map<const IR::BFN::ParserState*,
                                       const IR::BFN::LoweredParserState*>;

std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot> >
lowerFields(const PhvInfo& phv, const ClotInfo& clotInfo,
            const IR::Vector<IR::BFN::FieldLVal>& fields);

const IR::BFN::ContainerRef*
lowerUnsplittableField(const PhvInfo& phv,
                       const ClotInfo& clotInfo,
                       const IR::BFN::FieldLVal* fieldRef,
                       const char* unsplittableReason);

/// Combine the high-level parser IR and the results of PHV allocation to
/// produce a low-level, target-specific representation of the parser program.
/// Note that the new IR is just constructed here; ReplaceParserIR is what
/// actually replaces the high-level IR with the lowered version.
struct ComputeLoweredParserIR : public ParserInspector {
    explicit ComputeLoweredParserIR(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {
        // Initialize the map from high-level parser states to low-level parser
        // states so that null, which represents the end of the parser program
        // in the high-level IR, is mapped to null, which conveniently enough
        // means the same thing in the lowered IR.
        loweredStates[nullptr] = nullptr;
    }

    LoweredParserIRStates loweredStates;
    const IR::BFN::ContainerRef* igParserError = nullptr;
    const IR::BFN::ContainerRef* egParserError = nullptr;

    int csum_id = 0;

 private:
    /// @return a version of the provided state name which is safe to use in the
    /// generated assembly.
    cstring sanitizeName(StringRef name) {
        // Drop any thread-specific prefix from the name.
        if (auto prefix = name.findstr("::"))
            name = name.after(prefix) += 2;
        return name;
    }

    void postorder(const IR::BFN::VerifyChecksum* verify) override {
        if (!verify->parserError)
            return;

        auto* loweredSource =
            lowerUnsplittableField(phv, clotInfo, verify->parserError, "parser error");

        auto parser = findContext<IR::BFN::Parser>();
        if (parser->gress == INGRESS)
            igParserError = loweredSource;
        else
            egParserError = loweredSource;
    }

    IR::Vector<IR::BFN::LoweredParserPrimitive>
    lowerParserChecksums(const std::vector<const IR::BFN::ParserPrimitive*>& checksums) {
        IR::Vector<IR::BFN::LoweredParserPrimitive> loweredChecksums;

        nw_byteinterval finalInterval;
        // bool end = false;

        for (auto c : checksums) {
            if (auto* add = c->to<IR::BFN::AddToChecksum>()) {
                if (auto* v = add->source->to<IR::BFN::PacketRVal>()) {
                    const auto byteInterval = v->interval().toUnit<RangeUnit::Byte>();
                    finalInterval = finalInterval.unionWith(byteInterval);
                    // FIXME(zma) holes?
                 }
            }
            // else if (c->is<IR::BFN::VerifyChecksum>()) {
            //     end = true;
            // }
        }

        if (!finalInterval.empty()) {
            auto parser = findContext<IR::BFN::Parser>();
            auto parserError = parser->gress == INGRESS ? igParserError : egParserError;
            if (parserError) {
                // TODO(zma) id/swap/start/end/type
                unsigned mask = (1 << finalInterval.hi) - 1;
                auto csum = new IR::BFN::LoweredParserChecksum(
                    csum_id++, mask, 0x0, true, true, /*type*/0);
                loweredChecksums.push_back(csum);
            }
        }

        return loweredChecksums;
    }

    bool preorder(const IR::BFN::Parser*) override {
        // TODO(zma) checksum resouce allocation
        // Five parser checksum units are available; 0,1 can be used for verificaion/residual,
        // 2,3,4 can be used for CLOT; Checksum verification steals extractors.

        csum_id = 0;
        return true;
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

        std::vector<const IR::BFN::ParserPrimitive*> checksums;

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier(phv, clotInfo);
        forAllMatching<IR::BFN::ParserPrimitive>(&state->statements,
                      [&](const IR::BFN::ParserPrimitive* prim) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract);
            } else if (auto* add = prim->to<IR::BFN::AddToChecksum>()) {
                checksums.push_back(add);
            } else if (auto* verify = prim->to<IR::BFN::VerifyChecksum>()) {
                checksums.push_back(verify);
            } else {
                // Report other kinds of parser primitives, which we currently can't
                // handle, in the debug info.
                loweredState->debug.info.push_back("unhandled: " +
                                               cstring::to_cstring(prim));
            }
        });

        auto loweredStatements = simplifier.lowerExtracts();

        auto loweredChecksums = lowerParserChecksums(checksums);

        // XXX(zma) populate container range in clot info

        for (auto stmt : loweredStatements) {
            if (auto extract = stmt->to<IR::BFN::LoweredExtractPhv>()) {
                if (auto* source = extract->source->to<IR::BFN::LoweredBufferlikeRVal>()) {
                    auto bytes = source->extractedBytes();
                    auto container = extract->dest->container;
                    clotInfo.container_range()[container] = bytes;
                }
            }
        }

        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            // Load match register from previous result.
            BUG_CHECK(select->reg.size() > 0, "Match register not allocated.");
            auto* loweredSelect =
                new IR::BFN::LoweredSelect(select->reg);
            if (auto* bufferSource = select->source->to<IR::BFN::BufferlikeRVal>()) {
                const auto bufferRange =
                    bufferSource->range().toUnit<RangeUnit::Byte>();
                loweredSelect->debug.info.push_back(debugInfoFor(select, bufferRange)); }
            loweredState->select.push_back(loweredSelect);
            return;
        });

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
            auto* loweredMatch =
                new IR::BFN::LoweredParserMatch(
                        transition->value,
                        *transition->shift,
                        loweredStatements,
                        saves,
                        loweredChecksums,
                        loweredStates[transition->next]);
            loweredState->match.push_back(loweredMatch);
        }

        // Now that we've constructed a lowered version of this state, save it
        // so that we can link its predecessors to it. (Which, transitively,
        // will eventually stitch the entire graph of lowered states together.)
        loweredStates[state] = loweredState;
    }

    const PhvInfo& phv;
    ClotInfo& clotInfo;
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

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerParserIR : public PassManager {
    explicit LowerParserIR(const PhvInfo& phv, ClotInfo& clotInfo) {
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(phv, clotInfo);
        addPasses({
            computeLoweredParserIR,
            new ReplaceParserIR(*computeLoweredParserIR)
        });
    }
};

/// Maps a sequence of fields to a sequence of PHV containers. The sequence of
/// fields is treated as ordered and non-overlapping; the resulting container
/// sequence is the shortest one which maintains these properties.
std::pair<IR::Vector<IR::BFN::ContainerRef>, std::vector<Clot> >
lowerFields(const PhvInfo& phv, const ClotInfo& clotInfo,
            const IR::Vector<IR::BFN::FieldLVal>& fields) {
    struct LastContainerInfo {
        /// The container into which the last field was placed.
        IR::BFN::ContainerRef* containerRef;
        /// The range in that container which we've already placed fields into.
        nw_bitrange containerRange;
    };

    boost::optional<LastContainerInfo> last;
    IR::Vector<IR::BFN::ContainerRef> containers;
    std::vector<Clot> clots;

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

        // Walk each slice of the field. We need to walk the slices in reverse
        // because `foreach_alloc()` (and hence `get_alloc()`) enumerates
        // the slices in increasing order of their little endian offset, which
        // means that in terms of network order it walks the slices backwards.
        for (auto& slice : boost::adaptors::reverse(slices)) {
            BUG_CHECK(bool(slice.container), "Emitted field was allocated to "
                      "an invalid PHV container: %1%", fieldRef->field);

            const nw_bitrange containerRange = slice.container_bits()
                .toOrder<Endian::Network>(slice.container.size());

            // If this slice was allocated to the same container as the previous
            // one and we're monotonically advancing through the container, then
            // we combine them into a single container reference. We check that
            // we're advancing to avoid getting tripped up by cases like this:
            //     packet.emit(h.header);
            //     packet.emit(h.header);
            // If `h.header` is small enough to fit in a single container and we
            // didn't check that we were monotonically advancing through it,
            // we'd end up merging those two emits and only emitting `h.header`
            // once, even though the intention is clearly to emit it twice.
            if (last && last->containerRef->container == slice.container &&
                        last->containerRange.hi < containerRange.lo) {
                LOG5(" - Merging in " << fieldRef->field);
                last->containerRef->debug.info.push_back(debugInfoFor(fieldRef, slice));
                last->containerRange = last->containerRange.unionWith(containerRange);
                continue;
            }

            LOG5("Deparser: lowering field " << fieldRef->field
                  << " to " << slice.container);
            last = LastContainerInfo{new IR::BFN::ContainerRef(slice.container),
                                     containerRange};
            last->containerRef->debug.info.push_back(debugInfoFor(fieldRef, slice));
            containers.push_back(last->containerRef);
        }
    }

    return {containers, clots};
}

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

/// Maps a POV bit field to a single bit within a container, represented as a
/// ContainerBitRef. Checks that the allocation for the POV bit field is sane.
const IR::BFN::ContainerBitRef*
lowerPovBit(const PhvInfo& phv, const IR::BFN::FieldLVal* fieldRef) {
    std::vector<alloc_slice> slices = phv.get_alloc(fieldRef->field);

    BUG_CHECK(!slices.empty(), "POV bit %1% didn't receive a PHV allocation",
              fieldRef->field);
    BUG_CHECK(slices.size() == 1, "POV bit %1% is somehow split across "
              "multiple containers?", fieldRef->field);

    auto container = new IR::BFN::ContainerRef(slices.back().container);
    auto containerRange = slices.back().container_bits();
    BUG_CHECK(containerRange.size() == 1, "POV bit %1% is multiple bits?",
              fieldRef->field);

    auto* povBit = new IR::BFN::ContainerBitRef(container, containerRange);
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

#if HAVE_JBAY
struct RewriteEmitClot : public DeparserTransform {
    RewriteEmitClot(const PhvInfo& phv, const ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    const IR::Node* preorder(IR::BFN::Deparser* deparser) override {
        // replace Emits covered in a CLOT with EmitClot

        IR::Vector<IR::BFN::DeparserPrimitive> newEmits;

        Clot* last = nullptr;
        for (auto e : deparser->emits) {
           if (auto emit = e->to<IR::BFN::Emit>()) {
               auto field = phv.field(emit->source->field);
               if (auto c = clotInfo.clot(field)) {
                   if (c != last) {
                       auto povBit = emit->povBit;
                       auto clotEmit = new IR::BFN::EmitClot(*c, povBit);
                       newEmits.pushBackOrAppend(clotEmit);
                   }
                   last = const_cast<Clot*>(c);
               } else {
                   newEmits.pushBackOrAppend(e);
               }
           } else {
               newEmits.pushBackOrAppend(e);
           }
        }

        auto* clone = deparser->clone();
        clone->emits = newEmits;

        return clone;
    }

    const PhvInfo& phv;
    const ClotInfo& clotInfo;
};

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

struct InsertClotChecksums : public ParserModifier {
    explicit InsertClotChecksums(const PhvInfo& phv,
        const std::map<const Clot*, std::vector<const PHV::Field*>>& fields) :
            phv(phv), clot_checksum_fields(fields) { }

    unsigned generateByteMask(const std::vector<const PHV::Field*>& clot_csum_fields,
                              const IR::BFN::LoweredExtractClot* ec) {
        unsigned csum_mask = 0;
        unsigned clot_start_byte = ec->dest.start;

        for (auto f : clot_csum_fields) {
            unsigned offset = ec->dest.offset(f);
            unsigned field_mask = (1 << (f->size + 7)/8) - 1;
            field_mask <<= clot_start_byte + offset;
            csum_mask |= field_mask;
        }

        return csum_mask;
    }

    IR::BFN::LoweredParserChecksum*
    createClotChecksum(unsigned id, unsigned mask, const Clot& clot) {
        // TODO(zma) id/swap/start/end/type
        auto csum = new IR::BFN::LoweredParserChecksum(id, mask, 0x0, true, true, /* type */2);
        csum->clot_dest = clot;
        return csum;
    }

    bool preorder(IR::BFN::LoweredParserState* state) override {
        allocated_in_state = 0;
        return true;
    }

    void postorder(IR::BFN::LoweredParserState* state) override {
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
                        unsigned mask = generateByteMask(c.second, ec);
                        auto* csum = createClotChecksum(id++, mask, ec->dest);
                        match->checksums.push_back(csum);
                        allocated++;
                    }
                }
            }
        }
        allocated_in_state = std::max(allocated_in_state, allocated);
        return true;
    }

    // TODO(zma) manage this ref count better
    unsigned curr_id = 2;
    unsigned allocated_in_state = 0;

    const PhvInfo& phv;
    const std::map<const Clot*, std::vector<const PHV::Field*>>& clot_checksum_fields;
};

struct AllocateClotChecksums : public PassManager {
    AllocateClotChecksums(const PhvInfo& phv, const ClotInfo& clot) {
        auto* collectClotChecksumFields = new CollectClotChecksumFields(phv, clot);
        addPasses({
            collectClotChecksumFields,
            new InsertClotChecksums(phv, collectClotChecksumFields->clot_checksum_fields)
        });
    }
};

#endif

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
    bool preorder(const IR::BFN::Deparser* deparser) override {
        auto* loweredDeparser = deparser->gress == INGRESS ? igLoweredDeparser
                                                           : egLoweredDeparser;

        // Reset the next checksum unit if needed. On Tofino, each thread has
        // its own checksum units. On JBay they're shared, and their ids are
        // global, so on that device we don't reset the next checksum unit for
        // each deparser.
#if HAVE_JBAY
        if (Device::currentDevice() != "JBay")
            nextChecksumUnit = 0;
#endif

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
            if (!prim->is<IR::BFN::Emit>()) {
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
            auto* emit = prim->to<IR::BFN::Emit>();
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
                continue;
            }

            // If this is a checksum emit primitive, lower it.
            if (auto* emitChecksum = group.back()->to<IR::BFN::EmitChecksum>()) {
                BUG_CHECK(group.size() == 1,
                          "Checksum primitives should be in a singleton group");

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
                    if (Device::currentDevice() == "JBay")
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
                loweredDeparser->checksums.push_back(unitConfig);

                // Generate the lowered checksum emit.
                auto* loweredEmit =
                  new IR::BFN::LoweredEmitChecksum(loweredPovBit, nextChecksumUnit);
                loweredDeparser->emits.push_back(loweredEmit);

                nextChecksumUnit++;
                continue;
            }

            // This is a group of simple emit primitives. Pull out a
            // representative; all emits in the group will have the same POV bit
            // and CLOT tag.
            auto* emit = group.back()->to<IR::BFN::Emit>();
            BUG_CHECK(emit, "Unexpected deparser primitive: %1%", group.back());

            // Gather the source fields for all of the emits.
            IR::Vector<IR::BFN::FieldLVal> sources;
            for (auto* memberEmit : group)
                sources.push_back(memberEmit->to<IR::BFN::Emit>()->source);

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
            for (auto* fieldList : digest->fieldLists) {
                IR::Vector<IR::BFN::ContainerRef> fieldListSources;
                std::tie(fieldListSources, std::ignore) =
                    lowerFields(phv, clotInfo, fieldList->sources);
                IR::BFN::DigestTableEntry* entry;
                if (digest->name == "learning") {
                    auto* controlPlaneFormat =
                      computeControlPlaneFormat(phv, fieldList->sources);
                    entry = new IR::BFN::LearningTableEntry(fieldListSources,
                                                            fieldList->controlPlaneName,
                                                            controlPlaneFormat);
                } else {
                    entry = new IR::BFN::DigestTableEntry(fieldListSources);
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
        auto* computeLoweredDeparserIR = new ComputeLoweredDeparserIR(phv, clot);
        addPasses({
#if HAVE_JBAY
            new RewriteEmitClot(phv, clot),
            new AllocateClotChecksums(phv, clot),
#endif
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

    const auto shiftedRange = bufferSource->range.shiftedByBytes(-byteDelta);
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
    const auto shiftedRange = bufferSource->range.shiftedByBytes(-byteDelta);
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
        MatchPrimitives(const IR::Vector<IR::BFN::LoweredParserPrimitive>& ext,
                        const IR::Vector<IR::BFN::LoweredSave>& sa, int sft)
            : extracts(ext), saves(sa), shift(sft) { }

        IR::Vector<IR::BFN::LoweredParserPrimitive> extracts;
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

        for (auto* save : match->saves)
            saves.push_back(save);

        // Sort the extract primitives by position in the input packet.
        std::sort(extractPhvs.begin(), extractPhvs.end(), isExtractPhvEarlierInPacket);
        std::sort(extractClots.begin(), extractClots.end(), isExtractClotEarlierInPacket);
    }

    /// @return true if we haven't allocated everything yet.
    bool hasMoreExtracts() const {
        if (!extractPhvs.empty() || !extractClots.empty()) {
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

    /**
     * Allocate as many parser primitives as will fit into a single state,
     * respecting hardware limits.
     *
     * Keep calling this until hasMoreExtracts() returns false.
     * After that, you should call hasMoreSaves() and getRemainingSaves() if there is, and
     * push them down to the next state to generate a data extractor state.
     *
     * @return a pair containing (1) the parser primitives that were allocated,
     * and (2) the shift that the new state should have.
     */
    MatchPrimitives allocateOneState() {
        auto& pardeSpec = Device::pardeSpec();

        // Allocate. We have a limited number of extractions of each size per
        // state. We also ensure that we don't overflow the input buffer.
        IR::Vector<IR::BFN::LoweredParserPrimitive>     allocatedExtracts;
        IR::Vector<IR::BFN::LoweredSave>                allocatedSaves;
        std::vector<const IR::BFN::LoweredExtractPhv*>  remainingPhvExtracts;
        std::vector<const IR::BFN::LoweredExtractClot*> remainingClotExtracts;
        std::vector<const IR::BFN::LoweredSave*>        remainingSaves;
        nw_byteinterval remainingBytes;
        nw_byteinterval extractedInterval;

        if (Device::currentDevice() == "Tofino") {
            std::map<size_t, unsigned> allocatedExtractorsBySize;
            for (auto* extract : extractPhvs) {
                nw_byteinterval byteInterval;
                size_t use_extractor = 0;
                unsigned n_extractor_used = 0;
                if (auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>()) {
                    use_extractor = extract->dest->container.size();
                    n_extractor_used = 1;
                    byteInterval = source->byteInterval();
                } else if (auto* cons = extract->source->to<IR::BFN::LoweredConstantRVal>()) {
                    int container_size = extract->dest->container.size();
                    int value = cons->constant;
                    std::tie(use_extractor, n_extractor_used) =
                        calcConstantExtractorUses(value, container_size);
                }

                bool extractorsAvail = true;
                if (n_extractor_used &&
                    allocatedExtractorsBySize[use_extractor] + n_extractor_used >
                    pardeSpec.extractorSpec().at(use_extractor)) {
                    extractorsAvail = false; }

                if (!extractorsAvail ||
                    byteInterval.hiByte() > pardeSpec.byteInputBufferSize() - 1) {
                    remainingPhvExtracts.push_back(extract);
                    remainingBytes = remainingBytes.unionWith(byteInterval);
                    continue;
                }
                extractedInterval |= byteInterval;
                if (extract->dest)
                    allocatedExtractorsBySize[extract->dest->container.size()]++;
                allocatedExtracts.push_back(extract);
            }

            // Allocate saves as long as the source of save is inside the input buffer.
            // Note that input buffer required bytes are calculated by assembler, so
            // it does not matter even if save source is not inside the extracted bytes.
            // Also, save source does not need to update neither remainingBytes nor
            // extractedBytes, it does not affect actual shift byte.
            for (auto* save : saves) {
                const auto& source = save->source->byteInterval();
                if (source.hiByte() > pardeSpec.byteInputBufferSize() - 1)
                    remainingSaves.push_back(save);
                else
                    allocatedSaves.push_back(save);
            }
#if HAVE_JBAY
        } else if (Device::currentDevice() == "JBay") {
            // JBay has one size, 16-bit extractors
            unsigned allocatedExtractors = 0;
            unsigned totalExtractors = pardeSpec.extractorSpec().at(16);

            bool extractorsAvail = true;
            for (auto* extract : extractPhvs) {
                if (extract->dest) {
                    if (allocatedExtractors == totalExtractors)
                        extractorsAvail = false;
                }

                const auto byteInterval = extract->source->is<IR::BFN::LoweredPacketRVal>()
                                        ? extract->source->to<IR::BFN::LoweredPacketRVal>()
                                                 ->byteInterval()
                                        : nw_byteinterval();

                if (!extractorsAvail ||
                    byteInterval.hiByte() > pardeSpec.byteInputBufferSize() - 1) {
                    remainingPhvExtracts.push_back(extract);
                    remainingBytes = remainingBytes.unionWith(byteInterval);
                    continue;
                }

                if (extract->dest) {
                    switch (extract->dest->container.size()) {
                        case 8:  allocatedExtractors++;  break;
                        case 16: allocatedExtractors++;  break;
                        case 32: allocatedExtractors+=2; break;
                        default: BUG("Unknown container size");
                    }
                }

                // XXX(zma) we could pack two 8-bit extract into a single exact
                // if the two containers are an even-odd pair.
                extractedInterval |= byteInterval;
                allocatedExtracts.push_back(extract);
            }

            for (auto* extract : extractClots) {
                const auto byteInterval = extract->source->is<IR::BFN::LoweredPacketRVal>()
                                        ? extract->source->to<IR::BFN::LoweredPacketRVal>()
                                                 ->byteInterval()
                                        : nw_byteinterval();

                if ((byteInterval.loByte() > pardeSpec.byteInputBufferSize() - 1) &&
                    (byteInterval.hiByte() > pardeSpec.byteInputBufferSize() - 1)) {
                    remainingClotExtracts.push_back(extract);
                    remainingBytes = remainingBytes.unionWith(byteInterval);
                    continue;
                }

                if (byteInterval.hiByte() > pardeSpec.byteInputBufferSize() - 1) {
                    nw_byteinterval remain(pardeSpec.byteInputBufferSize(), byteInterval.hi);
                    auto rval = new IR::BFN::LoweredPacketRVal(*toClosedRange(remain));
                    remainingPhvExtracts.push_back(new IR::BFN::LoweredExtractPhv(rval));
                    remainingBytes = remainingBytes.unionWith(remain);
                }

                extractedInterval |= byteInterval;
                allocatedExtracts.push_back(extract);
            }
            extractClots.clear();

            for (auto* save : saves) {
                const auto& source = save->source->byteInterval();
                if (source.hiByte() > pardeSpec.byteInputBufferSize() - 1)
                    remainingSaves.push_back(save);
                else
                    allocatedSaves.push_back(save);
            }
#endif  // HAVE_JBAY
        }

        // If there is no more extract, calculate the actual shift for this state.
        // If remaining save falls into 32 byte range, then it's fine. If it does not
        // We need a new state for it.
        current_input_buffer |= extractedInterval;
        int byteActualShift = 0;
        if (remainingPhvExtracts.empty()) {
            byteActualShift = shift_required - shifted;
        } else {
            // If no more remaining extractions, just shift out the whole input buffer,
            // otherwise, shift until the first byte of the remaining is at head.
            byteActualShift = remainingBytes.empty()
                ? current_input_buffer.hiByte() + 1
                : std::min(remainingBytes.loByte(), current_input_buffer.hiByte() + 1);
        }

        // TODO(yumin): currently, phv allocation might generate out-of-end allocation
        // that leads to extraction on metadata across the header boundary. Generally,
        // it is correct because of the masking. However, this is a constraint that phv
        // should respect in some day, because if there is not enough payload for this
        // extraction, it is wrong. But, it is a very rare case, so we are relaxing it here.
        if (byteActualShift > shift_required) {
            ::warning("Extraction over the header boundary happens, "
                      "please make sure packet have at least %1% bytes payload.",
                      byteActualShift - shift_required);
            byteActualShift = shift_required;
        }

        BUG_CHECK(byteActualShift >= 0,
                  "Computed invalid shift %1% when splitting state %2%",
                  byteActualShift, stateName);

        LOG4("Created split state for " << stateName << " with shift "
             << byteActualShift << ":");

        // Shift up all the remaining extractions.
        extractPhvs.clear();
        for (auto* extract : remainingPhvExtracts)
            extractPhvs.push_back(leftShiftExtract(extract, byteActualShift));

        extractClots.clear();
        for (auto* extract : remainingClotExtracts)
            extractClots.push_back(leftShiftExtract(extract, byteActualShift));

        saves.clear();
        for (auto* save : remainingSaves)
            saves.push_back(leftShiftSave(save, byteActualShift));

        current_input_buffer = nw_byteinterval(
                StartLen(0, current_input_buffer.hiByte() + 1 - byteActualShift));

        shifted += byteActualShift;
        return MatchPrimitives(allocatedExtracts, allocatedSaves, byteActualShift);
    }

 private:
    cstring stateName;
    const int shift_required;
    const IR::BFN::LoweredParserMatch* match;
    int shifted;
    std::vector<const IR::BFN::LoweredExtractPhv*> extractPhvs;
    std::vector<const IR::BFN::LoweredExtractClot*> extractClots;
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

    /// return true if all branch need to be splitted. Only in a rare case that only part of
    /// matches need to split, which is caused by that they have late-in-buffer save that
    /// has to be done in a new state.
    bool needSplitState(const IR::BFN::LoweredParserState* state) {
        bool allNeedSplitState = true;
        for (const auto* match : state->match) {
            ExtractorAllocator allocator(state->name, match);
            allocator.allocateOneState();
            if (!allocator.hasMoreExtracts()) {
                allNeedSplitState = false; }
        }
        return allNeedSplitState;
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
        for (const auto* match : state->match) {
            for (const auto* save : match->saves) {
                auto range = save->source->extractedBytes();
                for (int i = range.loByte(); i <= range.hiByte(); ++i) {
                    save_map[std::make_pair(i, save->dest)].insert(match);
                } } }

        // Find the first location that not all matches save to the same register.
        for (const auto& kv : save_map) {
            if (kv.second.size() != state->match.size()) {
                earliest_conflict = std::min(earliest_conflict, kv.first.first);
            } }

        // Also the first shift, though they are likely to be the same.
        // This will catch the case when these is no save at all.
        for (const auto* match : state->match) {
            earliest_conflict = std::min(earliest_conflict, match->shift); }

        // If the conflicting point is in the middle of other primitives, move
        // the conflicting point to lower position.
        for (const auto* match : state->match) {
            for (const auto* prim : match->statements) {
                auto range = operatingRange(prim);
                if (range && (*range).loByte() < earliest_conflict
                    && earliest_conflict <= (*range).hiByte()) {
                    earliest_conflict = (*range).loByte();
                }
            }
            // TODO(yumin): checksum.
        }

        return earliest_conflict;
    }

    /// return the closed range on the input buffer that this primitive needs.
    boost::optional<nw_byterange> operatingRange(const IR::BFN::LoweredParserPrimitive* prim) {
        if (auto* phv = prim->to<IR::BFN::LoweredExtractPhv>()) {
            if (auto* source = phv->source->to<IR::BFN::LoweredBufferlikeRVal>()) {
                return source->extractedBytes();
            } else {
                // For all other case, they do not need anything from input buffer.
                return boost::none;
            }
        } else if (auto* clot = prim->to<IR::BFN::LoweredExtractClot>()) {
            return clot->source->extractedBytes();
        } else if (auto* save = prim->to<IR::BFN::LoweredSave>()) {
            return save->source->extractedBytes();
        } else if (/* auto* check_sum = */prim->to<IR::BFN::LoweredParserChecksum>()) {
            // TODO(yumin): checksum.
            return boost::none;
        } else {
            BUG("Unknown primitives %1%", prim);
            return boost::none;
        }
    }

    /// return true is this primitive does not need anything later than @p until.
    bool validBefore(const IR::BFN::LoweredParserPrimitive* prim, int until) {
        auto range = operatingRange(prim);
        if (!range) return true;
        if ((*range).hiByte() < until) {
            return true;
        } else if ((*range).loByte() < until && until <= (*range).hiByte()) {
            BUG("Wrong earliest conflicting point calculation.");
            return false;
        } else {
            return false;
        }
    }

    /// Remove all primitives that are already moved to common state.
    IR::BFN::LoweredParserMatch*
    truncateMatchBefore(const IR::BFN::LoweredParserMatch* match, int until) {
        auto* new_match =
            new IR::BFN::LoweredParserMatch(match->value, match->shift - until, match->next);
        for (const auto* prim : match->statements) {
            if (!validBefore(prim, until)) {
                if (auto* phv = prim->to<IR::BFN::LoweredExtractPhv>()) {
                    new_match->statements.push_back(leftShiftExtract(phv, until));
                } else if (auto* clot = prim->to<IR::BFN::LoweredExtractClot>()) {
                    new_match->statements.push_back(leftShiftExtract(clot, until));
                } else {
                    BUG("Unsupported primitive: %1%", prim);
                }
            }
        }

        for (const auto* prim : match->saves) {
            if (!validBefore(prim, until)) {
                new_match->saves.push_back(leftShiftSave(prim, until)); } }

        // TODO(yumin): checksum.
        for (const auto* prim : match->checksums) {
            if (!validBefore(prim, until)) {
                new_match->checksums.push_back(prim); } }

        return new_match;
    }

    /// Add all common primitives to the target match.
    void addCommonPrimitives(IR::BFN::LoweredParserMatch* target,
                             const IR::BFN::LoweredParserMatch* source, int until) {
        for (auto* prim : source->statements) {
            if (validBefore(prim, until)) {
                target->statements.push_back(prim); } }

        for (auto* prim : source->saves) {
            if (validBefore(prim, until)) {
                target->saves.push_back(prim); } }

        // TODO(yumin): checksum.
        for (auto* prim : source->checksums) {
            if (validBefore(prim, until)) {
                target->checksums.push_back(prim); } }

        target->shift = until;
    }

    /// Split out common primitives to a common state and return this state.
    /// Splitted primitives will be removed from original state and shift are adjusted.
    IR::BFN::LoweredParserState*
    splitOutCommonState(IR::BFN::LoweredParserState* state, int until,
                        const std::vector<const IR::BFN::LoweredSave*>& extra_saves) {
        std::vector<const IR::BFN::LoweredParserPrimitive*> extracts;
        std::vector<const IR::BFN::LoweredSave*> saves(extra_saves.begin(), extra_saves.end());

        auto* common_state =
            new IR::BFN::LoweredParserState(state->name + ".$common", state->gress);
        auto* only_match =
            new IR::BFN::LoweredParserMatch(match_t(), 0, state);
        only_match->shift = until;
        common_state->match.push_back(only_match);

        // save common part to the only match.
        addCommonPrimitives(only_match, *(state->match.begin()), until);
        LOG5("Default Match Of Common State: " << only_match);

        // remove common part in all branches and adjust shift
        IR::Vector<IR::BFN::LoweredParserMatch> truncatedMatches;
        for (auto* match : state->match) {
            auto* truncated_match = truncateMatchBefore(match, until);
            LOG5("Truncated Match: " << truncated_match);
            truncatedMatches.push_back(truncated_match); }
        state->match = truncatedMatches;
        return common_state;
    }

    IR::BFN::LoweredParserState*
    createCommonPrimitiveState(const IR::BFN::LoweredParserState* state,
                               const std::vector<const IR::BFN::LoweredSave*>& extra_saves) {
        // If this state does not need to split, and there is no extra saves, do not
        // generate a common primitive state for it, because that would increase the number
        // of states.
        if (extra_saves.empty() && !needSplitState(state)) {
            LOG1("Does not have extra saves nor need to split:" << state->name);
            return state->clone(); }

        // Foreach match, the only difference it could have is the different saves.
        // So we find the first different save, and push every thing before into
        // the new common state;
        LOG5("Generating common state for: " << state->name);
        int common_until = calcEarliestConflict(state);
        LOG5("Common until: " << common_until);
        return splitOutCommonState(state->clone(), common_until, extra_saves);
    }

    /// Add common state when needed. Then preorder on match will be executed on new state.
    bool preorder(IR::BFN::LoweredParserState* state) override {
        std::vector<const IR::BFN::LoweredSave*> extra_saves(leftover_saves[state]);
        auto* common_primitive_state =
            createCommonPrimitiveState(state, extra_saves);
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
        match->saves      = primitives_a.saves;
        match->shift      = primitives_a.shift;

        // If there's still more, allocate as many followup states as we need.
        auto* finalState = match->next;
        auto* currentMatch = match;
        while (allocator.hasMoreExtracts()) {
            // Create a new split state.
            auto newName = cstring::make_unique(stateNames, state->name + ".$split");
            stateNames.insert(newName);
            auto* newState =
              new IR::BFN::LoweredParserState(newName, state->gress);
            newState->debug = state->debug;
            currentMatch->next = newState;

            // Create a new match node and place as many primitives in it as we can.
            auto primitives = allocator.allocateOneState();
            auto* newMatch =
              new IR::BFN::LoweredParserMatch(match_t(), 0, finalState);

            newMatch->statements = primitives.extracts;
            newMatch->saves      = primitives.saves;
            newMatch->shift      = primitives.shift;
            newState->match.push_back(newMatch);

            // If there's more, we'll append the next state to the new match node.
            currentMatch = newMatch;
            added.insert(newMatch);
        }

        // If there is out-of-buffer saves, leave them to the next state.
        if (allocator.hasOutOfBufferSaves()) {
            for (const auto* save : allocator.getRemainingSaves()) {
                LOG1("Found Remaining Saves:" << save <<
                     " must be done before " << finalState->name); }
            BUG_CHECK(leftover_saves[finalState].size() == 0,
                      "Select on field from different parent branches is not supported.");
            leftover_saves[finalState] = allocator.getRemainingSaves();
        }

        return true;
    }

    std::set<cstring> stateNames;
    std::set<IR::BFN::LoweredParserMatch*> added;
    std::map<const IR::BFN::LoweredParserState*,
             std::vector<const IR::BFN::LoweredSave*>> leftover_saves;
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

/// Compute containers that have fields relying on parser zero initialization. Those containers
/// $validity bits shoule be set to 1 by parser to avoid a TCAM match issue.
class ComputeInitZeroContainers : public ParserModifier {
    void postorder(IR::BFN::LoweredParser* parser) override {
        ordered_set<PHV::Container> zero_init_containers;
        for (const auto& f : phv) {
            // XXX(yumin): fields that reads $valid should not be initialized.
            if (f.read_container_valid_bit()) continue;
            if (f.gress != parser->gress) continue;

            if (defuse.hasUninitializedRead(f.id)) {
                f.foreach_alloc([&] (const PHV::Field::alloc_slice& alloc) {
                    zero_init_containers.insert(alloc.container);
                }); }
        }

        for (auto& c : zero_init_containers)
            parser->initZeroContainers.push_back(new IR::BFN::ContainerRef(c));
    }

 public:
    ComputeInitZeroContainers(const PhvInfo& phv, const FieldDefUse& defuse)
        : phv(phv), defuse(defuse) { }

    const PhvInfo& phv;
    const FieldDefUse& defuse;
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

        // We need to have buffered enough bytes to read the last byte in the
        // range. We also need to be sure to buffer at least as many bytes as we
        // plan to shift.
        match->bufferRequired = std::max(unsigned(bytesRead.hi), match->shift);
        match->bufferRequired = std::min(unsigned(*match->bufferRequired),
                                         unsigned(Device::pardeSpec().byteInputBufferSize()));
/*
        const unsigned inputBufferSize = Device::pardeSpec().byteInputBufferSize();
        BUG_CHECK(*match->bufferRequired <= inputBufferSize,
                  "Match for state %1% requires %2% bytes to be buffered, which "
                  "is more than can fit in the %3% byte input buffer",
                  findContext<IR::BFN::LoweredParserState>()->name,
                  *match->bufferRequired, inputBufferSize);
*/
    }
};

}  // namespace

LowerParser::LowerParser(const PhvInfo& phv, ClotInfo& clot, const FieldDefUse &defuse) {
    addPasses({
        new LowerParserIR(phv, clot),
        new LowerDeparserIR(phv, clot),
        new SplitBigStates,
        new ComputeInitZeroContainers(phv, defuse),
        new ComputeMultiwriteContainers,  // Must run after ComputeInitZeroContainers.
        new ComputeBufferRequirements,
    });
}
