#include "split_big_states.h"

#include <boost/range/adaptor/map.hpp>

#include <algorithm>
#include <array>
#include <deque>
#include <map>
#include <utility>
#include <vector>

#include "bf-p4c/common/machine_description.h"
#include "bf-p4c/phv/phv.h"

namespace {

/// A predicate which orders input buffer bit intervals by where their input
/// data ends. Empty intervals are ordered last.
static bool isIntervalEarlierInBuffer(nw_bitinterval a,
                                      nw_bitinterval b) {
    if (a.empty()) return false;
    if (b.empty()) return true;
    return a.hi != b.hi ? a.hi < b.hi
                        : a.lo < a.lo;
}

/// A predicate which extracts by where their input data ends. Extracts which
/// don't come from the buffer are ordered last - they're lowest priority, since
/// we can execute them at any time without delaying other extracts.
static bool isExtractEarlierInBuffer(const IR::BFN::Extract* a,
                                     const IR::BFN::Extract* b) {
    auto* aFromBuffer = a->to<IR::BFN::ExtractBuffer>();
    auto* bFromBuffer = b->to<IR::BFN::ExtractBuffer>();
    if (aFromBuffer && bFromBuffer)
        return isIntervalEarlierInBuffer(aFromBuffer->bitInterval(),
                                         bFromBuffer->bitInterval());
    return aFromBuffer;
}

/// A sequence of extract operations.
struct ExtractorSequence {
    /// The extract operations.
    std::vector<const IR::BFN::Extract*> extracts;

    /// The range of input buffer bits the extracts touch.
    nw_bitinterval bits;

    /// Add a new extract operation to the sequence.
    void add(const IR::BFN::Extract* extract) {
        extracts.push_back(extract);
        if (!extract->is<IR::BFN::ExtractBuffer>()) return;
        auto extractBuffer = extract->to<IR::BFN::ExtractBuffer>();
        bits = bits.unionWith(extractBuffer->bitInterval());
    }

    /// Shift all extracts in the sequence to the left by the given amount.
    void shift(int delta) {
        if (!bits.empty()) {
            bits.lo -= delta;
            bits.hi -= delta;
        }
        BUG_CHECK(bits.lo >= 0 && bits.hi >= 0, "Shifted interval too much?");
        std::transform(extracts.begin(), extracts.end(), extracts.begin(),
                       [&](const IR::BFN::Extract* extract) {
            if (!extract->is<IR::BFN::ExtractBuffer>()) return extract;
            auto clone = extract->to<IR::BFN::ExtractBuffer>()->clone();
            clone->bitOffset -= delta;
            BUG_CHECK(!clone->isShiftedOut(), "Shifted extract too much?");
            return clone->to<IR::BFN::Extract>();
        });
    }
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
    ExtractorAllocator(const PhvInfo& phv, cstring stateName, int byteDesiredShift)
        : phv(phv), stateName(stateName), byteDesiredShift(byteDesiredShift) {
        BUG_CHECK(byteDesiredShift >= 0,
                  "Splitting state %1% with negative shift", stateName);
    }

    /// Add a new parser primitive that will be included in the state.
    void add(const IR::BFN::ParserPrimitive* primitive) {
        auto* extract = primitive->to<IR::BFN::Extract>();
        if (!extract) {
            nonExtractPrimitives.push_back(primitive);
            return;
        }

        bitrange bits;
        auto dest = phv.field(extract->dest, &bits);
        if (!dest)
            BUG("State %1% extracts field %2% with no PHV allocation",
                stateName, extract->dest);

        auto container = dest->for_bit(bits.lo).container;
        if (!container)
            BUG("State %1% extracts field %2% into invalid PHV container %3%",
                stateName, extract->dest, container);

        extractionsByContainer[container].add(extract);
    }

    /// @return true if we haven't allocated everything yet.
    bool hasMore() const {
        return byteDesiredShift > 0 || hasMorePrimitives();
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
    std::pair<IR::Vector<IR::BFN::ParserPrimitive>, int> allocateOneState() {
        using namespace BFN::Description;
        std::array<std::deque<PHV::Container>,
                   ExtractorKinds.size()> extractorQueues;

        // Partition the remaining extractions by extractor size.
        for (auto container : extractionsByContainer | boost::adaptors::map_keys)
            extractorQueues[container.log2sz()].push_back(container);

        // Sort the extractions associated with each extractor size according to
        // their position in the input buffer.
        for (auto& queue : extractorQueues) {
            std::sort(queue.begin(), queue.end(),
                      [&](PHV::Container a, PHV::Container b) {
                return isIntervalEarlierInBuffer(extractionsByContainer[a].bits,
                                                 extractionsByContainer[b].bits);
            });
        }

        // Allocate. We have a limited number of extractions of each size per
        // state. We also ensure that we don't overflow the input buffer.
        LOG3("Allocating extracts for state " << stateName);
        std::vector<const IR::BFN::Extract*> allocatedExtractions;
        for (auto& queue : extractorQueues) {
            LOG3(" - Begin extractor queue");
            for (unsigned i = 0; i < ExtractorCount && !queue.empty(); ++i) {
                auto container = queue.front();
                queue.pop_front();
                if (extractionsByContainer[container].bits.hi >= BitInputBufferSize)
                    break;
                for (auto* extract : extractionsByContainer[container].extracts) {
                    LOG3("   - " << extract);
                    allocatedExtractions.push_back(extract);
                }
                extractionsByContainer.erase(container);
            }
        }
        std::sort(allocatedExtractions.begin(), allocatedExtractions.end(),
                  isExtractEarlierInBuffer);

        // Collect the extractions we allocated.
        IR::Vector<IR::BFN::ParserPrimitive> primitives;
        primitives.insert(primitives.end(), allocatedExtractions.begin(),
                                            allocatedExtractions.end());

        // Collect all non-extract primitives. (For now, at least, these are all
        // unsupported, so they obviously don't consume extraction bandwidth.)
        primitives.insert(primitives.end(), nonExtractPrimitives.begin(),
                                            nonExtractPrimitives.end());
        nonExtractPrimitives.clear();

        // Compute the actual shift for this state. If we allocated everything,
        // we use the desired shift. Otherwise, we want to shift enough to bring
        // the first remaining extraction to the beginning of the input buffer.
        int byteActualShift = byteDesiredShift;
        if (hasMorePrimitives()) {
            nw_bitinterval remainingBits;
            for (auto& seq : extractionsByContainer | boost::adaptors::map_values)
                remainingBits = remainingBits.unionWith(seq.bits);
            byteActualShift = std::min(byteDesiredShift, remainingBits.loByte());
        }

        BUG_CHECK(byteActualShift >= 0,
                  "Computed invalid shift %1% when splitting state %2%",
                  byteActualShift, stateName);
        byteDesiredShift -= byteActualShift;
        BUG_CHECK(byteDesiredShift >= 0,
                  "Computed shift %1% is too large when splitting state %2%",
                  byteActualShift, stateName);

        // Shift up all the remaining extractions.
        const int bitActualShift = byteActualShift * 8;
        for (auto& seq : extractionsByContainer | boost::adaptors::map_values)
            seq.shift(bitActualShift);

        BUG_CHECK(!primitives.empty() || byteActualShift > 0 || !hasMore(),
                  "Have more to allocate in state %1%, but couldn't take "
                  "any action?", stateName);

        LOG3("Created split state for " << stateName << " with shift "
              << byteActualShift << ":");
        for (auto prim : primitives)
            LOG3(" - " << prim);

        return std::make_pair(primitives, byteActualShift);
    }

 private:
    bool hasMorePrimitives() const {
        return !extractionsByContainer.empty() ||
               !nonExtractPrimitives.empty();
    }

    std::map<PHV::Container, ExtractorSequence> extractionsByContainer;
    std::vector<const IR::BFN::ParserPrimitive*> nonExtractPrimitives;
    const PhvInfo& phv;
    cstring stateName;
    int byteDesiredShift;
};

}  // namespace

bool SplitBigStates::preorder(IR::BFN::ParserMatch* match) {
    auto stateName = findContext<IR::BFN::ParserState>()->name;
    BUG_CHECK(match->shift, "Splitting a state %1% with an unknown shift",
              stateName);
    ExtractorAllocator allocator(phv, stateName, *match->shift);
    for (auto* prim : match->stmts)
        allocator.add(prim);

    // Allocate whatever we can fit into this match.
    std::tie(match->stmts, match->shift) = allocator.allocateOneState();

    // If there's still more, allocate as many followup states as we need.
    auto* finalState = match->next;
    auto* currentMatch = match;
    while (allocator.hasMore()) {
        auto newMatch =
          new IR::BFN::ParserMatch(match_t(), {}, finalState, match->except);
        std::tie(newMatch->stmts, newMatch->shift) = allocator.allocateOneState();
        auto name = names.newname(stateName + ".$split");
        currentMatch->next =
          new IR::BFN::ParserState(name, VisitingThread(this), {}, { newMatch });
        currentMatch->except = nullptr;
        currentMatch = newMatch;
    }

    return true;
}
