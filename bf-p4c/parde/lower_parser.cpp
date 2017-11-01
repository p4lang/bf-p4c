#include "bf-p4c/parde/lower_parser.h"

#include <boost/optional/optional_io.hpp>
#include <boost/range/adaptor/reversed.hpp>

#include <numeric>
#include <sstream>
#include <utility>
#include <vector>

#include "bf-p4c/common/debug_info.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/stringref.h"

namespace {

using alloc_slice = PHV::Field::alloc_slice;

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
    } else if (extract->source->is<IR::BFN::BufferRVal>()) {
        // In the interest of brevity, don't print the range of bits being
        // extracted into the destination container if it matches the size of
        // the container exactly.
        if (slice.container.size() != size_t(bufferRange.size()))
            info << bufferRange << " -> " << slice.container << " "
                 << slice.container_bits() << ": ";
    }

    // Identify the P4 field that we're writing to.
    info << extract->dest->field->toString();

    // Although it's confusing given that the input buffer ranges we print above
    // are in network order, consistency with the rest of the output of the
    // assembler requires that we describe partial writes to a field in little
    // endian order.
    const le_bitrange destFieldBits = slice.field_bits();
    if (slice.field->size != destFieldBits.size())
        info << "." << destFieldBits.lo << "-" << destFieldBits.hi;

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

/// A predicate which orders input buffer bit intervals by where their input
/// data ends. Empty intervals are ordered last.
static bool isIntervalEarlierInBuffer(nw_byteinterval a,
                                      nw_byteinterval b) {
    if (a.empty()) return false;
    if (b.empty()) return true;
    return a.hi != b.hi ? a.hi < b.hi
                        : a.lo < a.lo;
}

/// A predicate which orders extracts by where their input data ends. Extracts
/// which don't come from the buffer are ordered last - they're lowest priority,
/// since we can execute them at any time without delaying other extracts.
static bool isExtractEarlierInBuffer(const IR::BFN::LoweredExtract* a,
                                     const IR::BFN::LoweredExtract* b) {
    auto* aFromBuffer = a->source->to<IR::BFN::LoweredBufferRVal>();
    auto* bFromBuffer = b->source->to<IR::BFN::LoweredBufferRVal>();
    if (aFromBuffer && bFromBuffer)
        return isIntervalEarlierInBuffer(aFromBuffer->byteInterval(),
                                         bFromBuffer->byteInterval());
    return aFromBuffer;
}

/**
 * Locate the PHV allocation for an expression.
 *
 * @param phvBackedStorage  An expression that evaluates to a reference to some
 *                          location in the PHV.
 * @param phv  The results of PHV allocation.
 *
 * @return the bits of the location that the expression references (generally
 * the location is a field, and the expression may only refer to part of it if
 * it's e.g. a Slice expression) and the PHV allocation slices for those bits.
 */
static std::pair<bitrange, std::vector<alloc_slice>>
computeSlices(const IR::Expression* phvBackedStorage, const PhvInfo& phv) {
    CHECK_NULL(phvBackedStorage);
    std::vector<alloc_slice> slices;
    bitrange bits;
    auto* field = phv.field(phvBackedStorage, &bits);
    if (!field) return std::make_pair(bits, slices);
    field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice& alloc) {
        slices.push_back(alloc);
    });
    return std::make_pair(bits, slices);
}

/// Helper class that splits extract operations into multiple smaller extracts,
/// such that each extract writes to exactly one PHV container.
struct ExtractSimplifier {
    /// Add a new extract operation to the sequence.
    void add(const IR::BFN::Extract* extract, const PhvInfo& phv) {
        LOG4("[ExtractSimplifier] adding: " << extract);

        std::vector<alloc_slice> slices;
        std::tie(std::ignore, slices) = computeSlices(extract->dest->field, phv);
        if (slices.empty()) {
            BUG("Parser extract didn't receive a PHV allocation: %1%", extract);
            return;
        }

        for (const auto& slice : slices)
            BUG_CHECK(bool(slice.container),
                      "Parser extracts into invalid PHV container: %1%", extract);

        if (auto* bufferSource = extract->source->to<IR::BFN::BufferRVal>()) {
            for (const auto& slice : slices) {
                // Shift the slice to its proper place in the input buffer.
                auto bitOffset = bufferSource->extractedBits().lo;
                const nw_bitrange bufferRange = slice.field_bits()
                  .toOrder<Endian::Network>(extract->dest->field->type->width_bits())
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

                // Generate the lowered extract.
                auto* newSource =
                  new IR::BFN::LoweredBufferRVal(finalBufferRange.toUnit<RangeUnit::Byte>());
                auto* newExtract =
                  new IR::BFN::LoweredExtract(slice.container, newSource);
                newExtract->debug.info.push_back(debugInfoFor(extract, slice, bufferRange));
                extractBufferByContainer[slice.container].push_back(newExtract);
            }
            return;
        }

        if (auto* constantSource = extract->source->to<IR::BFN::ConstantRVal>()) {
            for (const auto& slice : slices) {
                // We need to generate a mask from this slice that will pull out
                // the relevant bits of the constant value. Because we're
                // applying the mask at compile time, we need to transform this
                // slice into host endian order. We'll also treat it as a
                // half-open range to simplify the math.
                host_bitinterval sliceBits = toHalfOpenRange(slice.field_bits())
                  .toOrder<Endian::Host>(slice.field->size);

                // Construct a mask with all 1's in [0, slice.hi).
                const unsigned long hiMask = (1 << sliceBits.hi) - 1;
                // Construct a mask with all 1's in [slice.lo, ∞).
                const unsigned long loMask = (~0ul) << sliceBits.lo;
                // Construct a mask with all 1's in [slice.lo, slice.hi).
                const unsigned long mask = hiMask & loMask;

                // Pull out the bits of the value that belong to this slice.
                auto maskedValue = constantSource->constant->asInt() & mask;

                // Place those bits at their offset within the container.
                maskedValue <<= slice.container_bits()
                  .toOrder<Endian::Host>(slice.container.size()).lo;

                LOG4(" - Placing slice " << sliceBits << " (mask " << mask
                      << ") into " << slice.container << ". Final value: "
                      << maskedValue);

                // Create an extract that writes just those bits.
                // XXX(seth): This is necessary, but not sufficient, because we
                // actually can't write the full width of the larger PHV
                // containers in a single extract. We'll need to fix that up
                // elsewhere.
                auto* newSource =
                  new IR::BFN::LoweredConstantRVal(maskedValue);
                auto* newExtract =
                  new IR::BFN::LoweredExtract(slice.container, newSource);
                newExtract->debug.info.push_back(debugInfoFor(extract, slice));
                extractConstantByContainer[slice.container].push_back(newExtract);
            }
            return;
        }

        BUG("Unexpected parser primitive (most likely something that should "
            "have been eliminated by an earlier pass): %1%", extract);
    }

    /// Convert the sequence of Extract operations that have been passed to
    /// `add()` so far into a sequence of LoweredExtract operations. Extracts
    /// that write to the same container are merged together.
    IR::Vector<IR::BFN::LoweredExtract> lowerExtracts() {
        IR::Vector<IR::BFN::LoweredExtract> loweredExtracts;

        for (auto& item : extractBufferByContainer) {
            auto container = item.first;
            auto& extracts = item.second;

            BUG_CHECK(!extracts.empty(), "Map entry with no extracts?");
            if (extracts.size() == 1) {
                loweredExtracts.push_back(extracts[0]);
                continue;
            }

            // Merge the input buffer range for every extract that writes to
            // this container. They should all be the same, but if they aren't
            // we want to know about it.
            nw_byteinterval bufferRange;
            for (auto* extract : extracts) {
                auto* bufferSource =
                  extract->source->to<IR::BFN::LoweredBufferRVal>();
                BUG_CHECK(bufferSource, "Unexpected non-buffer source");
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
            const auto finalBufferValue =
              new IR::BFN::LoweredBufferRVal(*toClosedRange(bufferRange));
            auto* mergedExtract = new IR::BFN::LoweredExtract(container, finalBufferValue);
            for (auto* extract : extracts)
                mergedExtract->debug.mergeWith(extract->debug);

            loweredExtracts.push_back(mergedExtract);
        }

        for (auto& item : extractConstantByContainer) {
            auto container = item.first;
            auto& extracts = item.second;

            BUG_CHECK(!extracts.empty(), "Map entry with no extracts?");
            if (extracts.size() == 1) {
                loweredExtracts.push_back(extracts[0]);
                continue;
            }

            // Merge all of the constant extracts for this container into a
            // single operation. Because `add()` expands each constant write to
            // operate over the entire container, all we need to do is OR the
            // constants together.
            auto* mergedValue = new IR::BFN::LoweredConstantRVal(0);
            auto* mergedExtract = new IR::BFN::LoweredExtract(container, mergedValue);
            for (auto* extract : extracts) {
                auto* constantSource =
                  extract->source->to<IR::BFN::LoweredConstantRVal>();
                BUG_CHECK(constantSource, "Unexpected non-constant source");
                mergedValue->constant |= constantSource->constant;
                mergedExtract->debug.mergeWith(extract->debug);
            }

            loweredExtracts.push_back(mergedExtract);
        }

        return loweredExtracts;
    }

    using ExtractSequence = std::vector<const IR::BFN::LoweredExtract*>;

    /// The sequence of extract operations to be simplified. They're organized
    /// by container so that multiple extracts to the same container can be
    /// merged.
    std::map<PHV::Container, ExtractSequence> extractBufferByContainer;
    std::map<PHV::Container, ExtractSequence> extractConstantByContainer;
};

using LoweredParserIRStates = std::map<const IR::BFN::ParserState*,
                                       const IR::BFN::LoweredParserState*>;

/// Combine the high-level parser IR and the results of PHV allocation to
/// produce a low-level, target-specific representation of the parser program.
/// Note that the new IR is just constructed here; ReplaceParserIR is what
/// actually replaces the high-level IR with the lowered version.
struct ComputeLoweredParserIR : public ParserInspector {
    explicit ComputeLoweredParserIR(const PhvInfo& phv) : phv(phv) {
        // Initialize the map from high-level parser states to low-level parser
        // states so that null, which represents the end of the parser program
        // in the high-level IR, is mapped to null, which conveniently enough
        // means the same thing in the lowered IR.
        loweredStates[nullptr] = nullptr;
    }

    LoweredParserIRStates loweredStates;

 private:
    /// @return a version of the provided state name which is safe to use in the
    /// generated assembly.
    cstring sanitizeName(StringRef name) {
        // Drop any thread-specific prefix from the name.
        if (auto prefix = name.findstr("::"))
            name = name.after(prefix) += 2;
        return name;
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

        // Collect all the extract operations; we'll lower them as a group so we
        // can merge extracts that write to the same PHV containers.
        ExtractSimplifier simplifier;
        forAllMatching<IR::BFN::ParserPrimitive>(&state->statements,
                      [&](const IR::BFN::ParserPrimitive* prim) {
            if (auto* extract = prim->to<IR::BFN::Extract>()) {
                simplifier.add(extract, phv);
                return;
            }

            // Report other kinds of parser primitives, which we currently can't
            // handle, in the debug info.
            loweredState->debug.info.push_back("unhandled: " +
                                               cstring::to_cstring(prim));
        });
        auto loweredStatements = simplifier.lowerExtracts();

        forAllMatching<IR::BFN::Select>(&state->selects,
                      [&](const IR::BFN::Select* select) {
            if (auto* bufferSource = select->source->to<IR::BFN::BufferRVal>()) {
                const auto bufferRange =
                  bufferSource->extractedBits().toUnit<RangeUnit::Byte>();
                auto* loweredSelect = new IR::BFN::LoweredSelect(bufferRange);
                loweredSelect->debug.info.push_back(debugInfoFor(select, bufferRange));
                loweredState->select.push_back(loweredSelect);
                return;
            }

            // This Select isn't matching on the input buffer; if we haven't
            // been able to eliminate it by this point, it's a construction we
            // can't handle. Report it in the debug info.
            loweredState->debug.info.push_back("unhandled: " +
                                               cstring::to_cstring(select));
        });

        for (auto* transition : state->transitions) {
            BUG_CHECK(transition->shift, "State %1% has unset shift?", state->name);
            BUG_CHECK(*transition->shift >= 0, "State %1% has negative shift %2%?",
                                               state->name, *transition->shift);
            BUG_CHECK(loweredStates.find(transition->next) != loweredStates.end(),
                      "Didn't already lower state %1%?",
                      transition->next ? transition->next->name : cstring("(null)"));

            auto* loweredMatch =
              new IR::BFN::LoweredParserMatch(transition->value, *transition->shift,
                                              loweredStatements,
                                              loweredStates[transition->next]);
            loweredState->match.push_back(loweredMatch);
        }

        // Now that we've constructed a lowered version of this state, save it
        // so that we can link its predecessors to it. (Which, transitively,
        // will eventually stitch the entire graph of lowered states together.)
        loweredStates[state] = loweredState;
    }

    const PhvInfo& phv;
};

/// Replace the high-level parser IR version of each parser's root node with its
/// lowered version. This has the effect of replacing the entire parse graph.
struct ReplaceParserIR : public ParserTransform {
    explicit ReplaceParserIR(const LoweredParserIRStates& loweredStates)
      : loweredStates(loweredStates) { }

 private:
    const IR::BFN::LoweredParser*
    preorder(IR::BFN::Parser* parser) override {
        BUG_CHECK(loweredStates.find(parser->start) != loweredStates.end(),
                  "Didn't lower the start state?");
        prune();

        auto* loweredParser =
          new IR::BFN::LoweredParser(parser->gress, loweredStates.at(parser->start));

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

        return loweredParser;
    }

    const LoweredParserIRStates& loweredStates;
};

/// Generate a lowered version of the parser IR in this program and swap it in
/// for the existing representation.
struct LowerParserIR : public PassManager {
    explicit LowerParserIR(const PhvInfo& phv) {
        auto* computeLoweredParserIR = new ComputeLoweredParserIR(phv);
        addPasses({
            computeLoweredParserIR,
            new ReplaceParserIR(computeLoweredParserIR->loweredStates)
        });
    }
};

/// Split deparser primitives as needed so that each deparser primitive operates
/// on only one PHV container.
struct LowerDeparserIR : public DeparserTransform {
    explicit LowerDeparserIR(const PhvInfo& phv) : phv(phv) { }

 private:
    const IR::Node* splitExpression(const IR::Expression* expr,
                                    const bitrange& exprBits,
                                    const std::vector<bitrange>& slices) {
        if (slices.empty()) return expr;
        if (slices.size() == 1 && slices[0] == exprBits) {
            LOG3("SplitPhvUse: no need to split: " << expr);
            return expr;
        }

        auto rv = new IR::Vector<IR::Expression>();
        for (auto slice : boost::adaptors::reverse(slices)) {
            auto clone = MakeSlice(expr->clone(), slice.lo, slice.hi);
            LOG3("splitExpression: creating slice " << clone);
            rv->push_back(clone);
        }
        return rv;
    }

    const IR::Node* splitEmit(const IR::BFN::Emit* emit,
                              const bitrange& emitBits,
                              const std::vector<alloc_slice>& slices) {
        if (slices.empty()) {
            BUG("Deparser emits field which didn't receive a PHV allocation: %1%", emit);
            return emit;
        }
        if (slices.size() == 1 && slices[0].field_bits() == emitBits) {
            LOG3("SplitPhvUse: no need to split: " << emit);
            return emit;
        }

        auto rv = new IR::Vector<IR::BFN::DeparserPrimitive>();
        for (auto slice : boost::adaptors::reverse(slices)) {
            auto* clone = emit->clone();
            le_bitrange sliceBits = slice.field_bits();
            clone->source = MakeSlice(emit->source, sliceBits.lo, sliceBits.hi);
            LOG3("splitEmit: creating slice " << clone);
            rv->push_back(clone);
        }
        return rv;
    }

    const IR::Node* postorder(IR::BFN::Emit* emit) override {
        prune();
        bitrange bits;
        std::vector<alloc_slice> slices;
        std::tie(bits, slices) = computeSlices(emit->source, phv);
        return splitEmit(emit, bits, slices);
    }

    const IR::Node* preorder(IR::BFN::EmitChecksum* emit) override {
        prune();

        // A checksum uses a list of fields as input, and we need to split each
        // field individually.
        IR::Vector<IR::Expression> sources;
        for (auto* source : emit->sources) {
            bitrange bits;
            auto* field = phv.field(source, &bits);
            if (!field) {
                sources.push_back(source);
                continue;
            }

            std::vector<bitrange> slices;
            field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice& alloc) {
                slices.push_back(alloc.field_bits());
            });

            sources.pushBackOrAppend(splitExpression(source, bits, slices));
        }

        emit->sources = sources;
        return emit;
    }

    const PhvInfo& phv;
};

/// Allocate sequences of parser primitives to one or more states while
/// satisfying hardware constraints on the number of extractors available in a
/// state.
class ExtractorAllocator {
 public:
    /**
     * Create a new extractor allocator.
     *
     * @param phv  PHV allocation information.
     * @param stateName  The name of the parser state we're allocating for.
     * @param byteDesiredShift  The total number of bytes we want to shift in
     *                          this state. Needs to be provided separately
     *                          because we may shift over data that doesn't get
     *                          extracted.
     */
    ExtractorAllocator(cstring stateName, const IR::BFN::LoweredParserMatch* match)
        : stateName(stateName), byteDesiredShift(match->shift) {
        BUG_CHECK(byteDesiredShift >= 0,
                  "Splitting state %1% with negative shift", stateName);

        for (auto* extract : match->statements)
            extracts.push_back(extract);

        // Sort the extract primitives by position in the input buffer.
        std::sort(extracts.begin(), extracts.end(), isExtractEarlierInBuffer);
    }

    /// @return true if we haven't allocated everything yet.
    bool hasMore() const {
        return byteDesiredShift > 0 || !extracts.empty();
    }

    /**
     * Allocate as many parser primitives as will fit into a single state,
     * respecting hardware limits.
     *
     * Keep calling this until hasMore() returns false.
     *
     * @return a pair containing (1) the parser primitives that were allocated,
     * and (2) the shift that the new state should have.
     */
    std::pair<IR::Vector<IR::BFN::LoweredExtract>, int> allocateOneState() {
        auto& pardeSpec = Device::pardeSpec();

        // Allocate. We have a limited number of extractions of each size per
        // state. We also ensure that we don't overflow the input buffer.
        LOG3("Allocating extracts for state " << stateName);

        IR::Vector<IR::BFN::LoweredExtract> allocatedExtractions;
        std::vector<const IR::BFN::LoweredExtract*> remainingExtractions;
        nw_byteinterval remainingBytes;

        if (Device::currentDevice() == "Tofino") {
            std::map<size_t, unsigned> allocatedExtractorsBySize;

            for (auto* extract : extracts) {
                const auto containerSize = extract->dest->container.size();
                const auto byteInterval = extract->source->is<IR::BFN::LoweredBufferRVal>()
                                        ? extract->source->to<IR::BFN::LoweredBufferRVal>()
                                                 ->byteInterval()
                                        : nw_byteinterval();
                if (allocatedExtractorsBySize[containerSize] ==
                    pardeSpec.extractorSpec().at(containerSize) ||
                      byteInterval.hi >= pardeSpec.byteInputBufferSize()) {
                    remainingExtractions.push_back(extract);
                    remainingBytes = remainingBytes.unionWith(byteInterval);
                    continue;
                }
                allocatedExtractorsBySize[containerSize]++;
                allocatedExtractions.push_back(extract);
            }
        } else if (Device::currentDevice() == "JBay") {
            // JBay has one size, 16-bit extractors
            unsigned allocatedExtractors = 0;
            unsigned totalExtractors = pardeSpec.extractorSpec().at(16);

            for (auto* extract : extracts) {
                const auto containerSize = extract->dest->container.size();
                const auto byteInterval = extract->source->is<IR::BFN::LoweredBufferRVal>()
                                        ? extract->source->to<IR::BFN::LoweredBufferRVal>()
                                                 ->byteInterval()
                                        : nw_byteinterval();

                if (allocatedExtractors == totalExtractors ||
                    byteInterval.hi >= pardeSpec.byteInputBufferSize()) {
                    remainingExtractions.push_back(extract);
                    remainingBytes = remainingBytes.unionWith(byteInterval);
                    continue;
                }

                switch (containerSize) {
                    case 8:  allocatedExtractors++;  break;
                    case 16: allocatedExtractors++;  break;
                    case 32: allocatedExtractors+=2; break;
                    default: BUG("Unknown container size");
                }
                // XXX(zma) we could pack two 8-bit extract into a single exact
                // if the two containers are an even-odd pair.

                allocatedExtractions.push_back(extract);
            }
        }

        // Compute the actual shift for this state. If we allocated everything,
        // we use the desired shift. Otherwise, we want to shift enough to bring
        // the first remaining extraction to the beginning of the input buffer.
        const int byteActualShift = remainingBytes.empty()
                                  ? byteDesiredShift
                                  : std::min(byteDesiredShift, remainingBytes.loByte());

        BUG_CHECK(byteActualShift >= 0,
                  "Computed invalid shift %1% when splitting state %2%",
                  byteActualShift, stateName);
        byteDesiredShift -= byteActualShift;
        BUG_CHECK(byteDesiredShift >= 0,
                  "Computed shift %1% is too large when splitting state %2%",
                  byteActualShift, stateName);

        // Shift up all the remaining extractions.
        extracts.clear();
        for (auto* extract : remainingExtractions)
            extracts.push_back(shiftExtract(extract, byteActualShift));

        BUG_CHECK(!allocatedExtractions.empty() || byteActualShift > 0 || !hasMore(),
                  "Have more to allocate in state %1%, but couldn't take "
                  "any action?", stateName);

        LOG3("Created split state for " << stateName << " with shift "
              << byteActualShift << ":");
        for (auto* extract : allocatedExtractions)
            LOG3(" - " << extract);

        return std::make_pair(allocatedExtractions, byteActualShift);
    }

 private:
    /// Shift all extracts in the sequence to the left by the given amount.
    const IR::BFN::LoweredExtract*
    shiftExtract(const IR::BFN::LoweredExtract* extract, int byteDelta) {
        auto* bufferSource = extract->source->to<IR::BFN::LoweredBufferRVal>();
        if (!bufferSource) return extract;
        const auto shiftedRange = bufferSource->range.shiftedByBytes(-byteDelta);
        BUG_CHECK(shiftedRange.lo >= 0, "Shifted extract too much?");
        auto* clone = extract->clone();
        clone->source = new IR::BFN::LoweredBufferRVal(shiftedRange);
        return clone;
    }

    std::vector<const IR::BFN::LoweredExtract*> extracts;
    cstring stateName;
    int byteDesiredShift;
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

    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        auto* state = findContext<IR::BFN::LoweredParserState>();
        ExtractorAllocator allocator(state->name, match);

        // Allocate whatever we can fit into this match.
        std::tie(match->statements, match->shift) = allocator.allocateOneState();

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

            // Create a new match node and place as many primitives in it as we can.
            auto* newMatch =
              new IR::BFN::LoweredParserMatch(match_t(), 0, finalState);
            std::tie(newMatch->statements, newMatch->shift) = allocator.allocateOneState();
            newState->match.push_back(newMatch);

            // If there's more, we'll append the next state to the new match node.
            currentMatch = newMatch;
        }

        return true;
    }

    std::set<cstring> stateNames;
};

/// Locate all containers that are written more than once by the parser (and
/// hence need the "multiwrite" bit set).
class ComputeMultiwriteContainers : public ParserModifier {
    bool preorder(IR::BFN::LoweredParserMatch* match) override {
        for (auto* extract : match->statements)
            writes[extract->dest->container]++;
        return true;
    }

    void postorder(IR::BFN::LoweredParser* parser) override {
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

}  // namespace

LowerParser::LowerParser(const PhvInfo& phv) {
    addPasses({
        new LowerParserIR(phv),
        new LowerDeparserIR(phv),
        new SplitBigStates,
        new ComputeMultiwriteContainers
    });
}
