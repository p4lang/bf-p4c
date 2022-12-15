#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_LOWERED_PARSER_IR_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_LOWERED_PARSER_IR_H_

#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/lowered/helpers.h"
#include "bf-p4c/parde/lowered/extract_simplifier.h"

namespace Parde::Lowered {

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

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_LOWERED_PARSER_IR_H_ */
