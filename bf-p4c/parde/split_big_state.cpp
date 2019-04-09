#include "split_big_state.h"
#include "device.h"

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
        for (auto* stmt : match->extracts)
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
    calcConstantExtractorUsesTofino(uint32_t value, size_t container_size) {
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

    unsigned
    calcConstantExtractorUsesJBay(uint32_t value, size_t container_size) {
        if (container_size == size_t(PHV::Size::b32))
            return bool(value & 0xffff) + bool(value >> 16);
        else
            return 1;
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
    SplitExtractResult splitOneByBandwidthTofino(
            const std::vector<const IR::BFN::LoweredExtractPhv*>& extractPhvs,
            const IR::Vector<IR::BFN::LoweredParserChecksum>& checksums) {
        SplitExtractResult rst;
        auto& pardeSpec = Device::pardeSpec();
        int inputBufferLastByte = pardeSpec.byteInputBufferSize() - 1;

        std::map<size_t, unsigned> allocatedExtractorsBySize;

        // reserve extractor for checksum verification.
        for (auto* cks : checksums) {
            if (cks->type == IR::BFN::ChecksumMode::VERIFY && cks->csum_err) {
                auto extractor_size = cks->csum_err->container->container.size();
                BUG_CHECK(extractor_size != 32,
                  "Checksum verification cannot write to 32-bit container");
                allocatedExtractorsBySize[extractor_size]++;
            }
        }

        for (auto* extract : extractPhvs) {
            nw_byteinterval byteInterval;
            size_t extractor_size = 0;
            unsigned n_extractor_used = 0;
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
                    calcConstantExtractorUsesTofino(value, container_size);
            } else {
                BUG("Extract to unknown source: %1%", extract);
            }

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

            allocatedExtractorsBySize[extractor_size] += n_extractor_used;
            rst.allocatedExtracts.push_back(extract);
        }

        return rst;
    }

    SplitExtractResult splitOneByBandwidthJBay(
            const std::vector<const IR::BFN::LoweredExtractPhv*>& extractPhvs,
            const std::vector<const IR::BFN::LoweredExtractClot*>& extractClots,
            const IR::Vector<IR::BFN::LoweredParserChecksum>& checksums) {
        SplitExtractResult rst;
        auto& pardeSpec = Device::pardeSpec();
        int inputBufferLastByte = pardeSpec.byteInputBufferSize() - 1;

        unsigned allocatedExtractors = 0;
        unsigned allocatedConstants = 0;

        // reserve extractor for checksum verification.
        for (auto* cks : checksums) {
            if (cks->type == IR::BFN::ChecksumMode::VERIFY && cks->csum_err) {
                auto extractor_size = cks->csum_err->container->container.size();
                BUG_CHECK(extractor_size != 32,
                  "Checksum verification cannot write to 32-bit container");
                allocatedExtractors++;
            }
        }

        for (auto* extract : extractPhvs) {
            if (!extract->dest)
                continue;

            nw_byteinterval byteInterval;
            unsigned n_extractor_used = 0;
            unsigned n_constant_used = 0;

            int container_size = extract->dest->container.size();

            if (auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>()) {
                n_extractor_used = container_size == 32 ? 2 : 1;
                byteInterval = source->byteInterval();
            } else if (extract->source->is<IR::BFN::LoweredMetadataRVal>()) {
                n_extractor_used = container_size == 32 ? 2 : 1;
            } else if (auto* cons = extract->source->to<IR::BFN::LoweredConstantRVal>()) {
                n_extractor_used =
                    calcConstantExtractorUsesJBay(cons->constant, container_size);
                n_constant_used = n_extractor_used;
            } else {
                BUG("Extract to unknown source: %1%", extract);
            }

            // all extractors are 16-bit
            bool extractorsAvail = (allocatedExtractors + n_extractor_used)
                <= pardeSpec.extractorSpec().at(16);

            // 2 constants available per state
            bool constantsAvail = (allocatedConstants + n_constant_used) <= 2;

            if (!extractorsAvail || !constantsAvail ||
                byteInterval.hiByte() > inputBufferLastByte) {
                rst.remainingPhvExtracts.push_back(extract);
                rst.remainingBytes = rst.remainingBytes.unionWith(byteInterval);
                continue;
            }
            rst.extractedInterval |= byteInterval;

            allocatedExtractors += n_extractor_used;
            allocatedConstants += n_constant_used;
            rst.allocatedExtracts.push_back(extract);
        }

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
            bool can_be_done_mask = std::all_of(cks->masked_ranges.begin(),
                                                        cks->masked_ranges.end(),
                [&] (const nw_byterange& r) {
                    return r.hiByte() <= Device::pardeSpec().byteInputBufferSize() - 1;
                });
            bool can_be_done_end_pos =
                  static_cast<int>(cks->end_pos) <= Device::pardeSpec().byteInputBufferSize() - 1;
            if (can_be_done_end_pos && can_be_done_mask) {
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
        std::set<nw_byterange> prev;
        std::set<nw_byterange> post;
        int prev_end_pos = 0;
        int post_end_pos = 0;
        for (const auto& range : cks->masked_ranges) {
            if (range.hiByte() <= lastByte) {
                prev.insert(range);
            } else if (range.loByte() <= lastByte && range.hiByte() > lastByte) {
                prev.insert(FromTo(range.loByte(), lastByte));
                post.insert(FromTo(lastByte + 1, range.hiByte()));
            } else {
                post.insert(range);
            }
        }
        if (static_cast<int>(cks->end_pos) <= lastByte) {
            prev_end_pos = cks->end_pos;
        } else {
            post_end_pos = cks->end_pos;
        }

        // left shift all post range by shifted bytes.
        std::set<nw_byterange> temp;
        for (auto& r : post)
            temp.insert(nw_byterange(FromTo(r.loByte() - shifted, r.hiByte() - shifted)));
        if (post_end_pos > 0)
            post_end_pos -= shifted;

        post = temp;

        auto* prev_cks = cks->clone();
        auto* post_cks = cks->clone();

        prev_cks->masked_ranges = prev;
        prev_cks->end_pos = prev_end_pos;
        post_cks->masked_ranges = post;
        post_cks->end_pos = post_end_pos;

        if (prev.empty())
            return {nullptr, post_cks};
        if (post.empty() && !post_end_pos)
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

        auto extract_rst = Device::currentDevice() == Device::TOFINO ?
                 splitOneByBandwidthTofino(extractPhvs,
                                           checksum_rst_done.allocatedChecksums) :
                 splitOneByBandwidthJBay(extractPhvs, extractClots,
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

ParserModifier::profile_t
SplitBigStates::init_apply(const IR::Node* root) {
    forAllMatching<IR::BFN::LoweredParserState>(root,
                  [&](const IR::BFN::LoweredParserState* state) {
        stateNames.insert(state->name);
    });

    return ParserModifier::init_apply(root);
}

boost::optional<int>
SplitBigStates::needSplitState(const IR::BFN::LoweredParserState* state) {
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

unsigned
SplitBigStates::calcEarliestConflict(const IR::BFN::LoweredParserState* state) {
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
SplitBigStates::addTailStatePrimitives(IR::BFN::LoweredParserState* tailState, int until) {
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
                break;
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
        truncatedMatch->extracts.clear();
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
                    truncatedMatch->extracts.push_back(
                            leftShiftExtract(extractPhv, -accumulatedShift));
                } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                    truncatedMatch->extracts.push_back(
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

void
SplitBigStates::addCommonStatePrimitives(IR::BFN::LoweredParserMatch* common,
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
                        common->extracts.push_back(
                                leftShiftExtract(extractPhv, -shifted));
                    } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                        common->extracts.push_back(
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
                common->extracts.push_back(
                        leftShiftExtract(extractPhv, -shifted));
            } else if (auto* extractClot = prim->to<IR::BFN::LoweredExtractClot>()) {
                common->extracts.push_back(
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

IR::BFN::LoweredParserState*
SplitBigStates::splitOutCommonState(IR::BFN::LoweredParserState* state,
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
SplitBigStates::createCommonPrimitiveState(const IR::BFN::LoweredParserState* state,
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

bool SplitBigStates::preorder(IR::BFN::LoweredParserState* state) {
    std::vector<const IR::BFN::LoweredSave*> extra_saves(leftover_saves[state->name]);
    auto* common_primitive_state =
        createCommonPrimitiveState(state, extra_saves);
    leftover_saves[state->name].clear();
    *state = *common_primitive_state;
    return true;
}

bool SplitBigStates::preorder(IR::BFN::LoweredParserMatch* match) {
    if (added.count(match))
        return true;
    auto* state = findContext<IR::BFN::LoweredParserState>();

    ExtractorAllocator allocator(state->name, match);

    // Allocate whatever we can fit into this match.
    auto primitives_a = allocator.allocateOneState();
    match->extracts   = primitives_a.extracts;
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

        newMatch->extracts   = primitives.extracts;
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
