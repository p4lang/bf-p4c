#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_LOWER_FLATROCK_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_LOWER_FLATROCK_H_

#ifdef HAVE_FLATROCK

#include "helpers.h"

namespace Parde::Lowered {

/**
 * @brief All information from a parser state needed to create corresponding analyzer rules.
 */
struct AnalyzerRuleInfo {
    struct Header {
        cstring name; /**< header name */
        int width;    /**< header width in bytes */
        int offset;   /**< header offset from current pointer in bytes */
    };

    struct Transition {
        struct NextMatchInfo {
            int offset; /**< offset of the match value from current pointer in bytes */
            int size;   /**< size of the match value in bits */
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
                LOG3("  next w" << i << " offset (in bytes): " << match.offset
                                << ", size (in bits): " << match.size);
                ++i;
            }
            LOG3("  next state: " << (next_state ? next_state->name : "-") << std::endl
                                  << "  ptr shift: " << shift);
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

constexpr auto BITS_IN_BYTE = 8;

class ComputeFlatrockParserIR : public ParserInspector {
    typedef std::tuple<PHV::Size, unsigned int /* container index */,
                       unsigned int /* byte index inside container */>
        PovFlagsContainerInfo;

    /// Information about PHV allocation of the fields.
    const PhvInfo& phv;
    /// Information about definitions and uses of fields.
    const FieldDefUse& defuse;

    /// The name of ingress intrinsic metadata structure.
    cstring igMetaName;
    /// Ingress intrinsic metadata has been extracted.
    bool igMetaExtracted;
    /// The names of headers extracted in a given state.
    std::map<const IR::BFN::ParserState*, std::set<cstring>> headers;
    /**
     * @brief Maps byte of PHV container containing $valid field to a POV flags byte.
     *
     * @note Currently the same PHV allocation is used for both ingress and egress,
     *       so we have only one map.
     *       If there will be a different PHV allocation for ingress and egress in the future,
     *       this has to be changed to have a specific map for ingress and egress.
     */
    std::map<const PovFlagsContainerInfo, unsigned int> pov_flags_byte;
    /**
     * @brief Container slices (bytes) assigned to POV flags bytes collected during the pass.
     *
     * These refs need to be updated during the tree traversal because the debug info messages
     * are added gradually and IR::Vector keeps pointers to constant objects so they can not
     * be updated there.
     */
    std::vector<std::pair<IR::BFN::ContainerRef*, ordered_set<cstring>>> pov_flags;
    /// Populated at the end of the pass from pov_flags.
    IR::Vector<IR::BFN::ContainerRef> pov_flags_refs;

    profile_t init_apply(const IR::Node* node) override {
        igMetaExtracted = false;
        headers.clear();
        pov_flags_byte.clear();
        pov_flags.clear();
        pov_flags_refs.clear();
        rules_info.clear();
        extracts_info.clear();
        return Inspector::init_apply(node);
    }

    /**
     * @brief Allocates the mapping between a POV field and a byte in POV flags vector.
     *
     * This method checks, if there already is a mapping between the container byte
     * in which the field is allocated and a byte in POV flags vector.
     * This happens if any POV field which is allocated in the same container byte
     * has already been processed.
     * If not, an unused byte from POV flags vector is assigned to the given container
     * byte in which the field is allocated.
     *
     * @param alloc PHV allocation of the given field.
     * @param field_name Name of the field for which a POV flag byte is allocated
     *        (header validity bit ($valid)).
     * @return The byte in POV flags vector that will be extracted to the byte of PHV
     *         container where the field is allocated.
     */
    unsigned int allocate_pov_flags(const PHV::AllocSlice& alloc, const cstring field_name) {
        auto container_ref = new IR::BFN::ContainerRef(alloc.container());
        int lo = alloc.container_slice().loByte() * BITS_IN_BYTE;
        int hi = lo + (BITS_IN_BYTE - 1);
        le_bitrange slice_range{lo, hi};
        container_ref->range = slice_range.toOrder<Endian::Network>(alloc.container().size());

        PovFlagsContainerInfo container_info{alloc.container().type().size(),
                                             alloc.container().index(),
                                             alloc.container_slice().loByte()};
        unsigned int value;
        cstring debug_info = debugInfoFor(field_name, alloc);

        if (pov_flags_byte.find(container_info) != pov_flags_byte.end()) {
            value = pov_flags_byte[container_info];
            pov_flags[value].second.emplace(debug_info);
            LOG3("POV flags byte for container slice: " << container_ref << " is: " << value);
        } else {
            if (pov_flags_byte.size() == Flatrock::PARSER_FLAGS_WIDTH) {
                // TODO try to add some source info to this error message
                ::error(ErrorType::ERR_UNSUPPORTED,
                        "Compiler could not allocate resources for all headers "
                        "used in the program");
            }
            value = pov_flags_byte.size();
            pov_flags_byte.emplace(container_info, pov_flags_byte.size());
            pov_flags.push_back(std::make_pair(container_ref, ordered_set<cstring>{debug_info}));
            LOG3("Allocated POV flags byte " << value << " for container slice: " << container_ref);
        }
        return value;
    }

    /**
     * @brief This function allocates and assigns POV flag byte with index 0 to a dummy field
     *        to work around a problem with clearing POV flags bit 0.
     *
     * FIXME
     * When a modify_flag0|1 action, see:
     * https://wiki.ith.intel.com/pages/viewpage.action?pageId=1767708926#Parser-Modify_Flag
     * sets POV flags bit with index 0, then this bit is cleared in the next stage unless both
     * modify_flag0 and modify_flag1 actions are used in the used rules in the next stages.
     * If POV flags byte 0 is used for a container byte which uses this bit with index 0, then
     * the value of this bit set in analyzer is overwritten in following stages.
     * This workaround assigns the POV flags byte with index 0 to otherwise unused PHV byte
     * allocated for field ingress_intrinsic_metadata_for_tm.$zero.
     *
     * @param pipe Pipe IR node.
     */
    void add_zero_pov_flag_byte(const IR::BFN::Pipe* pipe) {
        auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
        BUG_CHECK(tmMeta, "Could not find ingress_intrinsic_metadata_for_tm");
        const cstring zeroFieldName = tmMeta->name + ".$zero";
        const auto* phv_field = phv.field(zeroFieldName);
        CHECK_NULL(phv_field);
        const auto allocs = phv_field->get_alloc();
        BUG_CHECK(allocs.size() == 1, "Unexpected number of allocations (%1%) for field %2%",
                  allocs.size(), zeroFieldName);
        const auto& alloc = allocs.front();
        BUG_CHECK(alloc.container().size() == BITS_IN_BYTE,
                  "Unexpected size %1% of container for field %2% with allocation: %3%",
                  alloc.container().size(), zeroFieldName, alloc);

        unsigned int id = allocate_pov_flags(alloc, phv_field->name);
        LOG3("Allocated POV flag byte: " << id << " for: " << alloc);
    }

    /**
     * @brief Adds information about packet/other PHE source extract.
     *
     * @param gress Gress (ingress or egress) where the value is extraced.
     * @param alloc Info about PHV allocation of the field to which the value is extracted.
     * @param comment Comment with debug info about the extract.
     * @param hdr_name Name of the header of the field to which the value is extracted.
     * @param match Match of the extract.
     * @param value_info Value of the extract (for packet or other PHE source.).
     */
    void add_extract(const gress_t gress, const PHV::AllocSlice& alloc, const cstring comment,
                     const Flatrock::ParserExtractMatch match,
                     Flatrock::ParserExtractValue::ValueInfo value_info) {
        Flatrock::ParserExtractContainer container{alloc.container().type().size(),
                                                   alloc.container().index()};
        Flatrock::ParserExtractValue new_extract_value{value_info, comment};

        if (auto it = extracts_info[gress].find(container); it != extracts_info[gress].end()) {
            auto& match_extract_map = it->second;
            if (auto it2 = match_extract_map.find(match); it2 == match_extract_map.end()) {
                match_extract_map.emplace(match, new_extract_value);
                LOG3("Adding new " << gress << " extract:" << std::endl
                                   << "  " << container << ":" << std::endl
                                   << "  - " << match << ": " << new_extract_value);
            } else {
                auto& extract_value = it2->second;
                extract_value.add_value(value_info, alloc);
                extract_value.add_comment(comment);
                LOG3(gress << " extract updated:" << std::endl
                           << "  " << container << ":" << std::endl
                           << "  - " << match << ": " << extract_value);
            }
        } else {
            ordered_map<Flatrock::ParserExtractMatch, Flatrock::ParserExtractValue>
                match_extract_map;
            match_extract_map.emplace(match, new_extract_value);
            extracts_info[gress].emplace(container, match_extract_map);
            LOG3("Adding new " << gress << " extract:" << std::endl
                               << "  " << container << ":" << std::endl
                               << "  - " << match << ": " << new_extract_value);
        }
    }

    bool preorder(const IR::BFN::Pipe* pipe) override {
        auto* igMeta = getMetadataType(pipe, "ingress_intrinsic_metadata");
        BUG_CHECK(igMeta, "Could not find ingress_intrinsic_metadata");
        igMetaName = igMeta->name;
        add_zero_pov_flag_byte(pipe);
        return true;
    }

    bool preorder(const IR::BFN::ParserZeroInit* zero) override {
        return preorder(new IR::BFN::Extract(zero->field, new IR::BFN::ConstantRVal(0)));
    }

    int get_hdr_bit_width(const IR::Expression* expr) {
        auto* member = expr->to<IR::Member>();
        if (member == nullptr)
            if (const auto* slice = expr->to<IR::Slice>()) member = slice->e0->to<IR::Member>();
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
        if (hdr_name == igMetaName) igMetaExtracted = true;

        LOG5("lval->field: " << lval->field);
        LOG5("phv_field: " << phv_field);
        for (const auto& a : allocs) {
            LOG5("alloc: " << a);
        }

        bool used_in_ingress = false;
        bool used_in_egress = false;

        for (const auto& u : defuse.getAllUses(phv_field->id)) {
            if (u.first->thread() == INGRESS) used_in_ingress = true;
            if (u.first->thread() == EGRESS) used_in_egress = true;
        }

        if (allocs.size() > 0) {
            const auto& alloc = allocs.front();

            cstring comment =
                debugInfoFor(extract, alloc,
                             extract->source->is<IR::BFN::InputBufferRVal>()
                                 ? extract->source->to<IR::BFN::InputBufferRVal>()->range
                                 : nw_bitrange{},
                             true);

            Flatrock::ParserExtractMatch match{nullptr};

            const auto* valid_field = phv.field(hdr_name + ".$valid");
            if (valid_field) {
                LOG3("Found valid field: " << valid_field);

                const auto vf_allocs =
                    phv.get_alloc(valid_field, nullptr, PHV::AllocContext::PARSER);
                if (vf_allocs.empty()) {
                    // FIXME
                    // This should not happen but currently it happens for example
                    // if ig_intr_md fields are used in control block but
                    // validity of ig_intr_md is not checked in the program and
                    // ig_intr_md.$valid does not have a PHV allocation.
                    // In this case we just do not match on the $valid field.
                    LOG1("Could not find the alloc slice for " << valid_field);
                } else {
                    match.header_valid_field = valid_field;
                }
            } else {
                LOG1("Field " << hdr_name << ".$valid not found");
            }

            if (const auto* pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                size_t hdr_bit_width = get_hdr_bit_width(lval->field);
                BUG_CHECK(hdr_bit_width % BITS_IN_BYTE == 0,
                          "Header %1% is not byte-aligned (%2% bits) during parser lowering",
                          hdr_name, hdr_bit_width);
                int after_field_bits = phv_field->offset;
                int field_offset_in_bits =
                    hdr_bit_width - after_field_bits - (alloc.field_slice().hi + 1);
                LOG5("field_offset_in_bits: " << field_offset_in_bits);
                BUG_CHECK(pkt_rval->range.lo >= field_offset_in_bits,
                          "Offset of extract (%1%) source in input buffer (%2%)"
                          " is lower than offset of destination field (%3%)",
                          extract, pkt_rval->range.lo, field_offset_in_bits);
                int hdr_offset_in_bits = pkt_rval->range.lo - field_offset_in_bits;
                BUG_CHECK(hdr_offset_in_bits % BITS_IN_BYTE == 0,
                          "Offset of header %1% is not byte-aligned (%2% bits)"
                          " during parser lowering",
                          hdr_name, hdr_offset_in_bits);
                int container_offset_in_bits =
                    field_offset_in_bits -
                    (alloc.container().size() - (alloc.container_slice().hi + 1));
                LOG5("container_offset_in_bits: " << container_offset_in_bits);
                BUG_CHECK(container_offset_in_bits >= 0, "Invalid container allocation");
                BUG_CHECK(container_offset_in_bits % BITS_IN_BYTE == 0,
                          "Invalid position of slice in container");
                int container_offset_in_bytes = container_offset_in_bits / BITS_IN_BYTE;
                LOG5("container_offset_in_bytes: " << container_offset_in_bytes);
                const auto* state = findContext<IR::BFN::ParserState>();
                CHECK_NULL(state);
                if (headers[state].count(hdr_name) == 0) {
                    int push_hdr_width = hdr_bit_width / BITS_IN_BYTE;
                    headers[state].insert(hdr_name);
                    LOG3("Collecting state["
                         << state->name << "] push_hdr: " << hdr_name
                         << ", width (in bytes): " << push_hdr_width
                         << ", offset (in bytes): " << (hdr_offset_in_bits / BITS_IN_BYTE));
                    rules_info[state].push_hdr.push_back(
                        {hdr_name, push_hdr_width, hdr_offset_in_bits / BITS_IN_BYTE});
                }
                Flatrock::ParserExtractValue::ValueInfo value_info{
                    Flatrock::ParserExtractValue::HeaderInfo{
                        hdr_name, static_cast<unsigned int>(container_offset_in_bytes)}};
                if (used_in_ingress) add_extract(INGRESS, alloc, comment, match, value_info);
                if (used_in_egress) add_extract(EGRESS, alloc, comment, match, value_info);
            } else if (const auto* const_rval = extract->source->to<IR::BFN::ConstantRVal>()) {
                le_bitrange slice = alloc.container_slice();
                auto subtype = Flatrock::ExtractSubtype::Constant;
                unsigned int value = const_rval->constant->asUnsigned();
                // Check that the value doesn't overflow
                const auto max_slice_value = (1ULL << alloc.container_slice().size()) - 1;
                BUG_CHECK(value <= max_slice_value,
                          "Value %1% too big for the container slice %2%%3% %4%", value,
                          alloc.container().type().size(), alloc.container().index(),
                          alloc.container_slice());

                if (auto member = lval->field->to<IR::Member>()) {
                    if (member->member.name == "$valid") {
                        BUG_CHECK(alloc.container_slice().size() == 1,
                                  "Unexpected $valid flag size");
                        unsigned int bit_index = alloc.container_slice().lo % BITS_IN_BYTE;
                        slice.lo = alloc.container_slice().loByte() * BITS_IN_BYTE;
                        slice.hi = slice.lo + (BITS_IN_BYTE - 1);
                        subtype = Flatrock::ExtractSubtype::PovFlags;
                        // Assign a byte from POV flags vector to a PHV container byte
                        // which holds the value of the $valid field.
                        value = allocate_pov_flags(alloc, lval->field->toString());
                        int pov_flag_index = value * BITS_IN_BYTE + bit_index;
                        const le_bitrange pov_flags_range{pov_flag_index, pov_flag_index};
                        comment = debugInfoFor(extract, alloc, pov_flags_range, "flags");
                        match.header_valid_field = nullptr;
                    }
                }

                Flatrock::ParserExtractValue::ValueInfo value_info{
                    Flatrock::ParserExtractValue::SliceInfoSet{
                        Flatrock::ParserExtractValue::SliceInfo{slice, subtype, value}}};
                if (used_in_ingress ||
                    (subtype == Flatrock::ExtractSubtype::PovFlags && used_in_egress))
                    add_extract(INGRESS, alloc, comment, match, value_info);
                if (used_in_egress) add_extract(EGRESS, alloc, comment, match, value_info);
            }
        };

        return true;
    }

    bool preorder(const IR::Flatrock::ExtractPayloadHeader* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        BUG_CHECK(state, "ExtractPayloadHeader: %1% out of state is invalid", extract);

        if (headers[state].count(extract->payload_pseudo_header_name) == 0) {
            headers[state].insert(extract->payload_pseudo_header_name);
            LOG3("Collecting state[" << state->name << "] payload pseudo header push_hdr: "
                                     << extract->payload_pseudo_header_name);
            rules_info[state].push_hdr.push_back({extract->payload_pseudo_header_name, 0, 0});
        }

        return true;
    }

    bool preorder(const IR::BFN::Transition* t) override {
        const auto* state = findContext<IR::BFN::ParserState>();
        CHECK_NULL(state);

        AnalyzerRuleInfo::Transition transition_info{};

        // TODO support IR::BFN::ParserPvsMatchValue
        const auto* match_value = t->value->to<IR::BFN::ParserConstMatchValue>();
        BUG_CHECK(match_value, "Unsupported type of match value: %1%", t->value);

        transition_info.match = match_value->value;
        transition_info.next_state = t->next;
        transition_info.shift = t->shift;

        /// \pre We assume that t->saves are already correctly assigned to
        /// W0, W1 by the AllocateParserMatchRegisters
        for (const auto* save : t->saves) {
            const auto* packet_source = save->source->to<IR::BFN::PacketRVal>();
            BUG_CHECK(packet_source, "Unsupported SaveToRegister source: %1%", save->source);

            int offset_in_bits = packet_source->range.lo;
            int size = packet_source->range.size();
            BUG_CHECK(offset_in_bits % BITS_IN_BYTE == 0,
                      "Unsupported offset of match value (in bits): %1%", offset_in_bits);
            BUG_CHECK(size <= 16, "Cannot match on %1%b value; maximum size is %2%b", size, 16);
            BUG_CHECK(transition_info.next_w.size() < 2,
                      "Only %1% 16-bit match values are supported, can not collect: %2%", 2, save);
            transition_info.next_w.push_back({offset_in_bits / BITS_IN_BYTE, size});
        }

        LOG3("Collecting state[" << state->name << "] transition["
                                 << rules_info[state].transitions.size() << "]");
        transition_info.log();

        rules_info[state].transitions.push_back(transition_info);

        return true;
    }

    bool preorder(const IR::BFN::ParserPrimitive* prim) override {
        // FIXME: Other parser primitives are currently not mapped to HW resources,
        // so we rather report it than ignore them.
        if (!findContext<IR::BFN::Transition>())
            BUG_CHECK(prim->is<IR::BFN::Extract>() || prim->is<IR::BFN::ParserZeroInit>() ||
                          prim->is<IR::Flatrock::ExtractPayloadHeader>(),
                      "IR::BFN::ParserPrimitive: %1% is currently not supported!", prim);
        return true;
    }

    bool preorder(const IR::BFN::ParserState* state) override {
        LOG4("[ComputeFlatrockParserIR] lowering state " << state->name << ": " << dbp(state)
                                                         << std::endl
                                                         << state);
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

        for (auto& [container_ref, debug_info_set] : pov_flags) {
            container_ref->debug.info.insert(container_ref->debug.info.begin(),
                                             debug_info_set.begin(), debug_info_set.end());
            pov_flags_refs.push_back(container_ref);
        }

        auto log = [this](gress_t gress) {
            if (extracts_info.count(gress) == 0) return;
            for (const auto& [container, extract] : extracts_info.at(gress)) {
                LOG3("  " << container << ":");
                for (const auto& [match, extract_value] : extract) {
                    LOG3("  - " << match << ": " << extract_value);
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
            LOG3("[ComputeFlatrockParserIR] POV flags:");
            int i = 0;
            for (auto containerRef : pov_flags_refs) {
                LOG3("  " << i++ << ": " << containerRef);
                for (auto debug_info : containerRef->debug.info)
                    LOG3("    comment=\"" << debug_info << "\"");
            }
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
     * @brief Information about extracts performed in parser needed to create corresponding
     *        PHV builder extracts.
     */
    std::map<gress_t,
             ordered_map<Flatrock::ParserExtractContainer,
                         ordered_map<Flatrock::ParserExtractMatch, Flatrock::ParserExtractValue>>>
        extracts_info;

    /**
     * @brief Get the pointer to the vector of container refs corresponding to
     *        the containers into which the POV flags bytes are extracted.
     *
     * The order in the vector is the order of byte in POV flags vector.
     */
    const IR::Vector<IR::BFN::ContainerRef>* get_pov_flags_refs() const { return &pov_flags_refs; }

    /**
     * @brief Get the POV flags byte index for specified PHV field allocation.
     *
     * @param alloc PHV allocation slice.
     * @return std::optional<unsigned int> POV flags byte index if POV flags byte
     *         is assigned to a PHV byte given by alloc slice.
     */
    std::optional<unsigned int> get_pov_flags_byte(const PHV::AllocSlice& alloc) const {
        PovFlagsContainerInfo container_info{alloc.container().type().size(),
                                             alloc.container().index(),
                                             alloc.container_slice().loByte()};
        auto it = pov_flags_byte.find(container_info);
        if (it != pov_flags_byte.end()) {
            return it->second;
        } else {
            // FIXME
            // Ideally this should be a BUG, but currently this case may happen when
            // a $valid field of a header is not used and thus it is optimized out
            // and there is no IR::BFN::Extract for that $valid field, but the header
            // is still pushed to hdr_ptrs list so we try to set a flag for the $valid
            // field and call this function.
            // When the logic for generating modify_flag actions will be changed so that
            // the modify_flag actions are generated based on the extracts and not for
            // each pushed header, this will be removed anyway.
            LOG1("Unknown POV flags byte for PHV field allocation: " << alloc);
            return std::nullopt;
        }
    }

    ComputeFlatrockParserIR(const PhvInfo& phv, const FieldDefUse& defuse)
        : phv(phv), defuse(defuse) {}
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
    typedef std::array<std::pair<ordered_set<::Flatrock::PovSelectKey>,
                                 std::vector<IR::Flatrock::PhvBuilderExtract*>>,
                       PARSER_PHV_BUILDER_GROUP_PHES_TOTAL>
        ExtractArray;
    typedef IR::Vector<IR::Flatrock::PhvBuilderGroup> PhvBuilder;
    typedef ordered_set<const PHV::Field*> MatchFieldSet;
    /**
     * @brief Each element in the array represents set of fields which need to be included
     *        in the selected POV bytes for the PHV builder group with the index equal
     *        to the index of the element in the array.
     */
    typedef std::array<MatchFieldSet, PARSER_PHV_BUILDER_GROUP_PHES_TOTAL> PovSelectMatchFieldArray;
    /**
     * @brief Each element in the set (which is an element of the array) represents match value
     *        for one extract in the PHV builder group given by the index in the array.
     */
    typedef std::array<ordered_set<MatchFieldSet>, PARSER_PHV_BUILDER_GROUP_PHES_TOTAL>
        ExtractMatchFieldArray;
    typedef std::pair<Flatrock::ParserExtractContainer, Flatrock::ParserExtractValue> ParserExtract;

    mutable cstring initial_state_name;

    /**
     * @brief Creates a modify_flag action for a specified header.
     *
     * FIXME
     * Currently we use a modify_flag action to set a $valid field for each
     * header we are pushing to hdr_ptrs list.
     * This approach does not work if there is a header which is not pushed
     * to the hdr_ptrs list (f.e. when all header fields are extracted from
     * constants or anything else than packet) or if there is an explicit
     * invalidation of a header (which may happen in case setInvalid() is
     * called in the source program or when a subparser with out headers is
     * used).
     *
     * @param hdr_name Name of a header for which we create a modify_flag action.
     * @return std::optional<::Flatrock::ModifyFlag> modify_flag action.
     */
    std::optional<::Flatrock::ModifyFlag> create_modify_flag(const cstring hdr_name) const {
        if (hdr_name == payloadHeaderName) return std::nullopt;

        ::Flatrock::ModifyFlag modify_flag{};
        modify_flag.imm = true;

        const PHV::Field* valid_field = nullptr;
        for (const auto& kv : phv.get_all_fields()) {
            if (kv.second.pov && hdr_name == kv.second.header()) {
                valid_field = &kv.second;
            }
        }

        if (!valid_field) {
            BUG("Could not find $valid field for header %1%", hdr_name);
        } else {
            auto allocs = phv.get_alloc(valid_field, nullptr, PHV::AllocContext::PARSER);
            if (allocs.empty()) {
                // FIXME
                // This case may also happen when $valid field of a header is not
                // used and thus optimized out.
                // This is just temporary until the logic for generating modify_flag
                // actions is changed to generate those actions based on the extracts
                // and not for each pushed header.
                LOG1("Could not find the alloc slice for " << valid_field);
                return std::nullopt;
            }
            PHV::AllocSlice alloc = allocs.front();
            unsigned int bit_index = alloc.container_slice().lo % BITS_IN_BYTE;
            auto byte_index = computed.get_pov_flags_byte(alloc);
            if (!byte_index) return std::nullopt;
            modify_flag.shift = (*byte_index) * BITS_IN_BYTE + bit_index;
        }

        return modify_flag;
    }

    /**
     * @brief Get the analyzer stage with given index.
     *
     * @param stage_id Index of analyzer stage to get.
     * @param analyzer_stages Vector of analyzer stages.
     * @return IR::Flatrock::AnalyzerStage* Either a newly created analyzer stage or
     *         an existing analyzer stage already stored in the vector.
     */
    IR::Flatrock::AnalyzerStage* get_analyzer_stage(
        unsigned int stage_id, std::vector<IR::Flatrock::AnalyzerStage*>& analyzer_stages) const {
        // FIXME when stages and rules allocation is optimized, this should
        // be converted to a proper error message
        BUG_CHECK(stage_id < ::Flatrock::PARSER_ANALYZER_STAGES,
                  "Maximum number of analyzer stages (%1%) exceeded",
                  ::Flatrock::PARSER_ANALYZER_STAGES);

        IR::Flatrock::AnalyzerStage* analyzer_stage;
        if (stage_id >= analyzer_stages.size()) {
            analyzer_stage = new IR::Flatrock::AnalyzerStage(stage_id);
            analyzer_stages.push_back(analyzer_stage);
            LOG3("Added AnalyzerStage: " << stage_id);
        } else {
            analyzer_stage = analyzer_stages[stage_id];
        }
        return analyzer_stage;
    }

    /**
     * @brief Sets values for push_hdr_id and modify_flag actions.
     *
     * @param push_hdr_id push_hdr_id action to set.
     * @param modify_flag modify_flag action to set.
     * @param analyzer_stage Current analyzer stage.
     * @param hdr_id Header ID of pushed header.
     * @param state_info Information about currently processed state.
     * @return unsigned int Rule ID of rule in which we push the header.
     */
    unsigned int prepare_push_hdr(std::optional<::Flatrock::PushHdrId>& push_hdr_id,
                                  std::optional<::Flatrock::ModifyFlag>& modify_flag,
                                  IR::Flatrock::AnalyzerStage* analyzer_stage, unsigned int hdr_id,
                                  AnalyzerRuleInfo& state_info) const {
        unsigned int rule_id = analyzer_stage->rules.size();
        // This is a bug, this should not happen as state splitting should take care of this
        BUG_CHECK(rule_id < ::Flatrock::PARSER_ANALYZER_STAGE_RULES,
                  "Maximum number of analyzer rules (%1%) in stage %2% exceeded",
                  ::Flatrock::PARSER_ANALYZER_STAGE_RULES, analyzer_stage->stage);

        if (hdr_id < state_info.push_hdr.size()) {
            const auto hdr_id_map =
                parserHeaderSeqs.header_ids.find({INGRESS, state_info.push_hdr[hdr_id].name});
            BUG_CHECK(hdr_id_map != parserHeaderSeqs.header_ids.end(),
                      "Could not find hdr_id for ingress header: %1%",
                      state_info.push_hdr[hdr_id].name);
            push_hdr_id =
                ::Flatrock::PushHdrId{static_cast<uint8_t>(hdr_id_map->second),
                                      static_cast<uint8_t>(state_info.push_hdr[hdr_id].offset)};
            // update the valid bit in POV flags
            modify_flag = create_modify_flag(state_info.push_hdr[hdr_id].name);
        }
        return rule_id;
    }

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
            const match_t state_match{~0ULL & ~(state_id & 0xffULL),
                                      ~0xffULL | state_id};
            // Store mapping into the parser state map
            lowered_parser->states[state_name] = state_match;
            if (initial_state_name.isNullOrEmpty()) initial_state_name = state_name;

            LOG5("state: " << dbp(state) << std::endl << state);
            LOG5("state_name: " << state_name);
            LOG5("state_match: " << state_match);
            LOG5("state_path_len: " << state_path_len);

            BUG_CHECK(computed.rules_info.count(state) > 0, "Missing information about state: %1%",
                      state);

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
            for (;
                 hdr_id + (state_info.transitions.size() > 0 ? 1 : 0) < state_info.push_hdr.size();
                 ++hdr_id, ++stage_id) {
                // For each header extraction, there is a separate stage
                // Create rule only with push_hdr_id
                analyzer_stage = get_analyzer_stage(stage_id, analyzer_stages);
                std::optional<::Flatrock::PushHdrId> push_hdr_id{std::nullopt};
                std::optional<::Flatrock::ModifyFlag> modify_flag{std::nullopt};
                unsigned int rule_id =
                    prepare_push_hdr(push_hdr_id, modify_flag, analyzer_stage, hdr_id, state_info);

                std::optional<cstring> next_state_name{std::nullopt};
                if (state_info.transitions.size() > 0) next_state_name = state_name;

                auto* analyzer_rule = new IR::Flatrock::AnalyzerRule(
                    /* id */ rule_id,
                    /* next_state */ std::nullopt,
                    /* next_state_name */ next_state_name,
                    /* next_w0_offset */ std::nullopt,
                    /* next_w1_offset */ std::nullopt,
                    /* next_w2_offset */ std::nullopt);
                analyzer_rule->push_hdr_id = push_hdr_id;
                analyzer_rule->match_state = state_match;
                analyzer_rule->modify_flag0 = modify_flag;
                analyzer_rule->next_alu0_instruction =
                    Flatrock::alu0_instruction(Flatrock::alu0_instruction::OPCODE_NOOP);
                analyzer_rule->next_alu1_instruction =
                    Flatrock::alu1_instruction(Flatrock::alu1_instruction::OPCODE_NOOP);
                analyzer_stage->rules.push_back(analyzer_rule);
                LOG3("AnalyzerStage[" << analyzer_stage->stage << "] added " << analyzer_rule);
            }

            if (state_info.transitions.size() > 0) {
                analyzer_stage = get_analyzer_stage(stage_id, analyzer_stages);
            }

            for (const auto& transition : state_info.transitions) {
                std::optional<::Flatrock::PushHdrId> push_hdr_id{std::nullopt};
                std::optional<::Flatrock::ModifyFlag> modify_flag{std::nullopt};
                unsigned int rule_id =
                    prepare_push_hdr(push_hdr_id, modify_flag, analyzer_stage, hdr_id, state_info);

                cstring next_state_name = sanitizeName(transition.next_state->name);

                std::optional<int> next_w0_offset{std::nullopt};
                std::optional<int> next_w1_offset{std::nullopt};
                std::optional<int> next_w2_offset{std::nullopt};

                if (transition.next_w.size() > 0) next_w0_offset = transition.next_w[0].offset;
                if (transition.next_w.size() > 1) next_w1_offset = transition.next_w[1].offset;
                BUG_CHECK(transition.next_w.size() <= 2,
                          "Only 2 next_w offsets are supported for matching!");

                auto* analyzer_rule = new IR::Flatrock::AnalyzerRule(
                    /* id */ rule_id,
                    /* next_state */ std::nullopt,
                    /* next_state_name */ next_state_name,
                    /* next_w0_offset */ next_w0_offset,
                    /* next_w1_offset */ next_w1_offset,
                    /* next_w2_offset */ next_w2_offset);
                analyzer_rule->push_hdr_id = push_hdr_id;
                analyzer_rule->match_state = state_match;
                analyzer_rule->modify_flag0 = modify_flag;
                // Look into selects to determine the order of selects, or rather the match
                // registers in the match value
                // This needs to be done because the P4 order of the select fields
                // (match value follows the P4 order) might not be the same as their order
                // within the packet (match registers follow the packet order)
                bool w0_match_set = false;
                bool w1_match_set = false;
                // Store the order of pointers to corresponding match_wX values in a vector
                std::vector<match_t*> match_reg_vals;
                for (auto select : state->selects) {
                    if (auto saved = select->source->to<IR::BFN::SavedRVal>()) {
                        for (auto rs : saved->reg_slices) {
                            if (rs.first.name == "W0" && !w0_match_set) {
                                w0_match_set = true;
                                match_reg_vals.push_back(&(analyzer_rule->match_w0));
                            } else if (rs.first.name == "W1" && !w1_match_set) {
                                w1_match_set = true;
                                match_reg_vals.push_back(&(analyzer_rule->match_w1));
                            }
                        }
                    }
                }
                BUG_CHECK(match_reg_vals.size() <= 2, "More than 2 match registers encountered!");
                // Split the actual match value
                match_t match_val = transition.match;
                match_t match_vals[2] = {match_val, match_val};
                // If both are used, the first one matches the top 16 bits (= second 16b chunk)
                if (match_reg_vals.size() > 1) {
                    match_vals[0] = {match_val.word0 >> ::Flatrock::PARSER_W_WIDTH * 8,
                                     match_val.word1 >> ::Flatrock::PARSER_W_WIDTH * 8};
                }
                match_vals[0].setwidth(::Flatrock::PARSER_W_WIDTH * 8);
                match_vals[1].setwidth(::Flatrock::PARSER_W_WIDTH * 8);
                // Fill the match values based on the order stored previously
                for (unsigned i = 0; i < match_reg_vals.size(); i++)
                    *(match_reg_vals[i]) = match_vals[i];
                analyzer_rule->next_alu0_instruction =
                    Flatrock::alu0_instruction(Flatrock::alu0_instruction::OPCODE_0,
                                               std::vector<int>{/* add */ transition.shift});
                analyzer_rule->next_alu1_instruction =
                    Flatrock::alu1_instruction(Flatrock::alu1_instruction::OPCODE_NOOP);
                analyzer_stage->rules.push_back(analyzer_rule);
                LOG3("AnalyzerStage[" << analyzer_stage->stage << "] added " << analyzer_rule);
            }

            if (hdr_id > max_stage_inc) max_stage_inc = hdr_id;
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
            if (std::all_of(
                    stage->rules.begin(), stage->rules.end(),
                    [&](const IR::Flatrock::AnalyzerRule* r) { return r->match_state == match; })) {
                auto it = std::find_if(lowered_parser->states.begin(), lowered_parser->states.end(),
                                       [&](const std::pair<const cstring, match_t>& kv) {
                                           return kv.second == match;
                                       });
                if (it != lowered_parser->states.end()) stage->name = it->first;
            }
        }

        lowered_parser->analyzer.insert(lowered_parser->analyzer.begin(), analyzer_stages.begin(),
                                        analyzer_stages.end());
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

    /**
     * @brief Packs the info about PHV container into the structure suitable for creating
     *        PHV builder extracts.
     */
    PheInfo get_phe_info(const Flatrock::ParserExtractContainer& extract_container) const {
        size_t phe_sources = 0;
        size_t base_group_index = 0;  /// index within PHE8/16/32 groups
        std::stringstream container_name;

        if (extract_container.size == PHV::Size::b8) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES;
            base_group_index = 0;
        } else if (extract_container.size == PHV::Size::b16) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES;
            base_group_index = Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_NUM;
        } else if (extract_container.size == PHV::Size::b32) {
            phe_sources = Flatrock::PARSER_PHV_BUILDER_PACKET_PHE32_SOURCES;
            base_group_index = Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_NUM +
                               Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_NUM;
        } else {
            BUG("Invalid container size in PHV builder extractor");
        }

        container_name << extract_container;

        const auto sub_group_offset =
            extract_container.index / phe_sources / Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES;
        const auto group_index = base_group_index + sub_group_offset;

        return PheInfo{container_name.str(), group_index, phe_sources};
    }

    /**
     * @brief Fills array of POV select fields.
     *
     * @param pov_select_match_fields Array of POV select fields to fill.
     * @param phv_builder_extracts Array of extracts for PHV builder groups which contains
     *        also POV select keys which are also filled by this method.
     * @param gress Gress (ingress or egress) for which we generate the extracts.
     */
    void prepare_pov_select(PovSelectMatchFieldArray& pov_select_match_fields,
            ExtractArray& phv_builder_extracts, const gress_t gress) const {
        for (const auto& [container, match_extract_map] : computed.extracts_info.at(gress)) {
            for (const auto& [match, extract_value] : match_extract_map) {
                if (match.is_match_all()) continue;

                const auto phe_info = get_phe_info(container);
                auto& pov_select_set = phv_builder_extracts[phe_info.phv_builder_group_index].first;
                const auto allocs =
                    phv.get_alloc(match.header_valid_field, nullptr, PHV::AllocContext::PARSER);
                BUG_CHECK(!allocs.empty(), "Could not find the alloc slice for %1%",
                          match.header_valid_field);
                const auto& alloc = allocs.front();
                auto byte_index = computed.get_pov_flags_byte(alloc);
                if (!byte_index) {
                    // FIXME
                    // Replace this with the following BUG_CHECK when this is fixed for
                    // ig_intr_md.$valid:
                    // BUG_CHECK(byte_index, "POV flag byte not allocated for alloc %1%", alloc);
                    continue;
                }
                ::Flatrock::PovSelectKey key{::Flatrock::PovSelectKey::FLAGS,
                                             static_cast<uint8_t>(*byte_index)};
                pov_select_set.emplace(key);
                pov_select_match_fields[phe_info.phv_builder_group_index].emplace(
                    match.header_valid_field);
            }
        }
        if (LOGGING(3)) {
            LOG3(gress << " PHV builder group POV select match fields:");
            unsigned int i = 0;
            for (const auto& field_set : pov_select_match_fields) {
                std::stringstream ss;
                ss << "  " << i++ << ":" << std::endl;
                for (const auto* field : field_set) {
                    ss << "    " << *field << std::endl;
                }
                LOG3(ss);
            }
        }
    }

    /**
     * @brief Fills array of extract match fields.
     *
     * @param extract_match_fields Array of extract match fields to fill.
     * @param pov_select_match_fields Array of POV select fields which is used to collect
     *        extract match fields.
     * @param gress Gress (ingress or egress) for which we generate the extracts.
     */
    void prepare_extract_match(ExtractMatchFieldArray& extract_match_fields,
                               const PovSelectMatchFieldArray& pov_select_match_fields,
                               const gress_t gress) const {
        unsigned i = 0;
        for (const auto& field_set : pov_select_match_fields) {
            for (const auto& seq : parserHeaderSeqs.sequences.at(INGRESS)) {
                ordered_set<const PHV::Field*> match_set;
                std::for_each(field_set.begin(), field_set.end(), [&](const PHV::Field* f) {
                    if (seq.find(f->header()) != seq.end()) match_set.emplace(f);
                });
                if (!match_set.empty()) extract_match_fields[i].emplace(match_set);
            }
            i++;
        }

        if (LOGGING(3)) {
            LOG3(gress << " PHV builder group extract matches:");
            i = 0;
            for (const auto& match_vec : extract_match_fields) {
                std::stringstream ss;
                ss << "  " << i++ << ":" << std::endl;
                int j = 0;
                for (const auto& field_set : match_vec) {
                    ss << "    " << j++ << ":" << std::endl;
                    for (const auto* field : field_set) {
                        ss << "      " << *field << std::endl;
                    }
                          }
                LOG3(ss);
            }
        }
    }

    /**
     * @brief Finds existing or constructs new PHV builder extract based on given info.
     *
     * @param extract_id Id of extract in the PHV builder group.
     * @param phv_builder_extracts Array of extracts for PHV builder groups.
     * @param container Info about PHV container corresponding to the extract.
     * @param phv_builder_group_index Id of the PHV builder group.
     * @param pov_select_match_field_set Set of fields that need to be included in selected
     *        POV bytes for PHV builder group given by phv_builder_group_index.
     * @param extract_match_field_set Set of fields that represent match value of the PHV
     *        builder extract given by extract_id.
     * @return IR::Flatrock::PhvBuilderExtract* IR node representing PHV builder extract.
     */
    IR::Flatrock::PhvBuilderExtract* get_phv_builder_extract(const unsigned int extract_id,
            ExtractArray& phv_builder_extracts,
            const Flatrock::ParserExtractContainer& container,
            const size_t phv_builder_group_index, const MatchFieldSet& pov_select_match_field_set,
            const MatchFieldSet& extract_match_field_set) const {
        // Get vector of extracts for a given PHV builder group
        auto& phv_builder_extract_vec =
                phv_builder_extracts[phv_builder_group_index].second;
        if (extract_id < phv_builder_extract_vec.size())
            return phv_builder_extract_vec[extract_id];
        else {
            IR::Flatrock::PhvBuilderExtract* phv_builder_extract =
                    new IR::Flatrock::PhvBuilderExtract(container.size);
            phv_builder_extract->index = extract_id;
            // Compute phv_builder_extract->match from pov_select_match_field_set
            // and extract_match_field_set.
            // The principle:
            // For each field in pov_select_match_field_set, set the corresponding
            // bit position in phv_builder_extract->match:
            // - 1 if the field is present in extract_match_field_set
            // - 0 if the field is not present in extract_match_field_set
            // Set * for other bits.
            // The bit position needs to be calculated based on the bit index of the fields
            // inside a POV flags byte and position of the byte in
            // phv_builder_extracts[phv_builder_group_index].first set.

            // Set all bits to don't care
            phv_builder_extract->match.setwidth(
                ::Flatrock::PARSER_POV_SELECT_NUM * BITS_IN_BYTE);
            // Check all POV bits used in the PHE extraction group
            for (const auto &match_field : pov_select_match_field_set) {
                const auto allocs = phv.get_alloc(match_field, nullptr,
                    PHV::AllocContext::PARSER);
                BUG_CHECK(!allocs.empty(), "Could not find the alloc slice for %1%", match_field);
                const auto& alloc = allocs.front();
                // Construct POV match key byte the POV bit lies in
                auto byte_index = computed.get_pov_flags_byte(alloc);
                BUG_CHECK(byte_index, "POV flag byte not allocated for alloc %1%", alloc);
                ::Flatrock::PovSelectKey key{::Flatrock::PovSelectKey::FLAGS,
                    static_cast<uint8_t>(*byte_index)};
                // Find the position in the POV match key
                const auto &pov_select_key =
                    phv_builder_extracts[phv_builder_group_index].first;
                int pov_start_bit = 0;
                for (const auto &pov_select : pov_select_key) {
                    if (pov_select == key)
                        break;
                    pov_start_bit += BITS_IN_BYTE;
                }
                // POV bit position in the POV match key
                auto bit_pos = pov_start_bit + alloc.container_slice().lo % BITS_IN_BYTE;
                // Set corresponding bit of the POV match key
                if (extract_match_field_set.find(match_field) != extract_match_field_set.end()) {
                    phv_builder_extract->match.word0 ^= 1ULL << bit_pos;
                } else {
                    phv_builder_extract->match.word1 ^= 1ULL << bit_pos;
                }
            }
            phv_builder_extract_vec.push_back(phv_builder_extract);
            return phv_builder_extract;
        }
    }

    /**
     * @brief Adds extract as a PHE source to PHV builder extract.
     *
     * @param phv_builder_extract PHV builder extract to which a PHE source is added.
     * @param container Info about PHV container corresponding to the extract.
     * @param extract_value Info about extract value.
     */
    void add_extract_source(IR::Flatrock::PhvBuilderExtract* phv_builder_extract,
                            const Flatrock::ParserExtractContainer& container,
                            const Flatrock::ParserExtractValue& extract_value) const {
        const auto phe_info = get_phe_info(container);
        /**
         * Each PHV builder group extract specifies a pair of PHE sources.
         * Each PHE source specifies:
         * - 4 PHE8 sources or
         * - 2 PHE16 sources or
         * - 1 PHE32 source
         * Values for each PHE source (4xPHE8 / 2xPHE16 / 1xPHE32) in the pair are
         * stored in one element of 'source' array
         */
        const auto phe_source_index = (container.index / phe_info.phe_sources) %
                                      Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES;

        if (phv_builder_extract->source[phe_source_index].type != Flatrock::ExtractType::None) {
            BUG_CHECK(phv_builder_extract->source[phe_source_index].type == extract_value.type,
                      "Values of different types allocated into the same PHE "
                      "source of PHV builder group %1% %2%",
                      phe_info.phv_builder_group_index, phv_builder_extract);
        }

        phv_builder_extract->source[phe_source_index].type = extract_value.type;
        phv_builder_extract->source[phe_source_index].debug.info.insert(
            phv_builder_extract->source[phe_source_index].debug.info.end(),
            extract_value.comments.begin(), extract_value.comments.end());

        if (extract_value.type == Flatrock::ExtractType::Packet) {
            if (phv_builder_extract->source[phe_source_index].hdr_name) {
                BUG_CHECK(*phv_builder_extract->source[phe_source_index].hdr_name ==
                    extract_value.get_header_name(),
                    "Values from different headers %1% and %2% allocated into the same "
                    "PHE source of PHV builder group %3% %4%",
                    *phv_builder_extract->source[phe_source_index].hdr_name,
                    extract_value.get_header_name(), phe_info.phv_builder_group_index,
                    phv_builder_extract);
            }
            phv_builder_extract->source[phe_source_index].hdr_name =
                extract_value.get_header_name();
            phv_builder_extract->source[phe_source_index].values.push_back(
                {phe_info.container_name, static_cast<int>(extract_value.get_source_offset()),
                 Flatrock::ExtractSubtype::None});
        } else if (extract_value.type == Flatrock::ExtractType::Other) {
            unsigned int constant = 0;
            for (const auto& slice : extract_value.get_slices()) {
                if (slice.subtype == Flatrock::ExtractSubtype::Constant) {
                    constant |= slice.value << slice.slice.lo;
                }
            }
            for (int i = 0; i < Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES; ++i) {
                int lo = i * BITS_IN_BYTE;
                int hi = lo + (BITS_IN_BYTE - 1);
                const auto suffix =
                    (phe_info.phe_sources == Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES)
                        ? ""
                        : '(' + std::to_string(lo) + ".." + std::to_string(hi) + ')';
                for (const auto& slice : extract_value.get_slices()) {
                    if (slice.slice.loByte() <= i && i <= slice.slice.hiByte()) {
                        int value;
                        if (slice.subtype == Flatrock::ExtractSubtype::Constant) {
                            unsigned int bit_offset = i * BITS_IN_BYTE;
                            unsigned int mask = ((1U << BITS_IN_BYTE) - 1) << bit_offset;
                            value = static_cast<int>((constant & mask) >> bit_offset);
                        } else if (slice.subtype == Flatrock::ExtractSubtype::PovFlags) {
                            value = static_cast<int>(slice.value);
                        } else {
                            std::stringstream ss;
                            ss << slice.subtype;
                            BUG("Extract subtype %1% is currently not supported", ss.str());
                        }
                        phv_builder_extract->source[phe_source_index].values.push_back(
                            {phe_info.container_name + suffix, value, slice.subtype});
                        break;
                    }
                }
            }
        } else {
            BUG("Missing extract type!");
        }
        LOG3("Update PHV builder group " << phe_info.phv_builder_group_index << " "
                                         << phv_builder_extract);
    }

    /**
     * @brief Creates PHV builder extract IR nodes for extracts with match-all match pattern.
     *
     * Some extracts (f.e. extracts from POV) need to be added to each extract regardless
     * the match pattern.
     * They are collected in a vector and then added to each created extract in corresponding
     * PHV builder group.
     * They also need to be added to an extract with match-all match pattern (which should not
     * exist before calling this method).
     *
     * @param phv_builder_extracts Array of extracts for PHV builder groups.
     * @param gress Gress (ingress or egress) for which we generate the extracts.
     * @param parser_extracts Vector of extracts with match-all match pattern.
     */
    void create_match_all_extracts(ExtractArray& phv_builder_extracts, const gress_t gress,
            const std::vector<ParserExtract>& parser_extracts) const {
        auto log_phv_builder_extracts = [&phv_builder_extracts]() {
            if (LOGGING(4)) {
                unsigned int i = 0;
                for (auto& [pov_select_set, extracts] : phv_builder_extracts) {
                    std::stringstream ss;
                    ss << i << ":" << std::endl;
                    ss << " pov_select:" << std::endl;
                    for (const auto& pov_select : pov_select_set) {
                        ss << " - " << pov_select << std::endl;
                    }
                    ss << " extracts:" << std::endl;
                    for (const auto& extract : extracts) {
                        ss << " - " << extract << std::endl;
                    }
                    LOG4(ss);
                    i++;
                }
            }
        };

        LOG4(gress << " PHV builder groups:");
        log_phv_builder_extracts();

        for (const auto& [container, extract_value] : parser_extracts) {
            const auto phe_info = get_phe_info(container);
            auto& phv_builder_extract_vec =
                    phv_builder_extracts[phe_info.phv_builder_group_index].second;
            const match_t match_all = match_t::dont_care(
                    ::Flatrock::PARSER_POV_SELECT_NUM * BITS_IN_BYTE);
            bool match_all_found = false;

            for (auto& phv_builder_extract : phv_builder_extract_vec) {
                if (phv_builder_extract->match == match_all)
                    match_all_found = true;
                add_extract_source(phv_builder_extract, container, extract_value);
            }

            if (match_all_found == false) {
                auto phv_builder_extract = new IR::Flatrock::PhvBuilderExtract(container.size);
                phv_builder_extract->index = phv_builder_extract_vec.size();
                add_extract_source(phv_builder_extract, container, extract_value);
                phv_builder_extract_vec.push_back(phv_builder_extract);
            }
        }

        LOG4(gress << " PHV builder groups with POV extracts:");
        log_phv_builder_extracts();
    }

    /**
     * @brief Converts the collected information about extracts to the new lowered IR nodes
     *        representing PHV builder extracts.
     */
    ExtractArray make_builder_extracts(const gress_t gress) const {
        ExtractArray phv_builder_extracts{};
        std::vector<ParserExtract> match_all_extracts;
        if (computed.extracts_info.count(gress) != 0) {
            PovSelectMatchFieldArray pov_select_match_fields{};
            ExtractMatchFieldArray extract_match_fields{};

            prepare_pov_select(pov_select_match_fields, phv_builder_extracts, gress);
            prepare_extract_match(extract_match_fields, pov_select_match_fields, gress);

            for (const auto& [container, match_extract_map] : computed.extracts_info.at(gress)) {
                for (const auto& [match, extract_value] : match_extract_map) {
                    if (match.is_match_all()) {
                        match_all_extracts.push_back(std::make_pair(container, extract_value));
                        continue;
                    }
                    const auto phe_info = get_phe_info(container);
                    unsigned int extract_id = 0;
                    bool source_added = false;
                    for (const auto& extract_match_field_set :
                            extract_match_fields[phe_info.phv_builder_group_index]) {
                        IR::Flatrock::PhvBuilderExtract* phv_builder_extract =
                                get_phv_builder_extract(extract_id++, phv_builder_extracts,
                                container, phe_info.phv_builder_group_index,
                                pov_select_match_fields[phe_info.phv_builder_group_index],
                                extract_match_field_set);

                        if (extract_match_field_set.find(match.header_valid_field) ==
                                extract_match_field_set.end())
                            continue;

                        add_extract_source(phv_builder_extract, container, extract_value);
                        source_added = true;
                    }

                    if (source_added == false) {
                        match_all_extracts.push_back(std::make_pair(container, extract_value));
                        // FIXME
                        // When extract value is not added to any extract, it means there is
                        // something wrong in the overall logic.
                        // Currently it can happen for ig_intr_md fields when there is no extract
                        // for ig_intr_md.$valid field (if the extract is optimized out when
                        // $valid field is not used in the program).
                        // Replace this with the BUG_CHECK when this is fixed for ig_intr_md.$valid
                    }
                }
            }
        }
        create_match_all_extracts(phv_builder_extracts, gress, match_all_extracts);
        return phv_builder_extracts;
    }

    /**
     * @brief Sorts PHV builder group extracts.
     *
     * Extracts in one PHV builder group need to be ordered based on the match value
     * from the most generic to the most specific match value.
     *
     * FIXME
     * Currently we only reverse the order of extracts as the extract with match-all
     * pattern is originally added to the end, but ideally all extracts should be sorted.
     *
     * @param extracts Vector of extracts to sort.
     * @return std::vector<IR::Flatrock::PhvBuilderExtract*> Sorted vector of extracts.
     */
    std::vector<IR::Flatrock::PhvBuilderExtract*> sort_extracts(
            const std::vector<IR::Flatrock::PhvBuilderExtract*>& extracts) const {
        std::vector<IR::Flatrock::PhvBuilderExtract*> result{};

        unsigned int id = 0;
        for (auto rit = extracts.rbegin(); rit != extracts.rend(); ++rit, ++id) {
            (*rit)->index = id;
            result.push_back(*rit);
        }

        return result;
    }

    void build_phv_builder(PhvBuilder& phv_builder, gress_t gress) const {
        const auto extracts = make_builder_extracts(gress);
        int id = 0;
        for (const auto& [pov_select_set, extract_vec] : extracts) {
            if (extract_vec.size() > 0) {
                auto* phv_builder_group = new IR::Flatrock::PhvBuilderGroup(id);
                for (const auto& pov_select : pov_select_set)
                    phv_builder_group->pov_select.push_back(pov_select);
                auto sorted_extracts = sort_extracts(extract_vec);
                phv_builder_group->extracts.insert(phv_builder_group->extracts.begin(),
                                                   sorted_extracts.begin(), sorted_extracts.end());
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
            /* initial_state */ std::nullopt,
            /* initial_state_name */ initial_state_name,
            /* initial_flags */ std::nullopt,
            /* initial_ptr */ 0,  // Extraction of ingress intrinsic metadata is always expected
            /* initial_w0_offset */ std::nullopt,
            /* initial_w1_offset */ std::nullopt,
            /* initial_w2_offset */ std::nullopt);
        // Bytes 15 and 14 of port metadata contain logical pipe ID and logical port number
        // in the following format:
        // {5'h0, logical pipe ID (4b), port number (7b), port_md_tbl(14B)}
        // If this changes, update the description of port_metadata in SYNTAX.yaml
        default_profile->metadata_select.push_back(
            Flatrock::metadata_select(Flatrock::metadata_select::PORT_METADATA, {/* index */ 15}));
        default_profile->metadata_select.push_back(
            Flatrock::metadata_select(Flatrock::metadata_select::PORT_METADATA, {/* index */ 14}));
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

    void make_profiles(IR::Flatrock::Parser* lowered_parser) const {
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
        auto* pseudo_parser = new IR::Flatrock::PseudoParser;
        // POVs are placed at the end of the bridge metadata
        // See https://wiki.ith.intel.com/pages/viewpage.action?
        //     pageId=1581874739#FrameProcessingPipeline(FPP)-POVFormat
        // The values need to be in sync with the code in assembler
        // that stores POVs into the remaining bridge metadata.
        // See Deparser::write_config(Target::Flatrock::deparser_regs &).
        pseudo_parser->pov_state_pos =
            Flatrock::PARSER_BRIDGE_MD_WIDTH - Flatrock::PARSER_PKT_STATE_WIDTH;
        pseudo_parser->pov_flags_pos = Flatrock::PARSER_BRIDGE_MD_WIDTH -
                                       Flatrock::PARSER_PKT_STATE_WIDTH -
                                       Flatrock::PARSER_FLAGS_WIDTH;
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
                                     const ParserHeaderSequences& phs, const CollectParserInfo& pi)
        : phv(phv), computed(computed), parserHeaderSeqs(phs), parser_info(pi) {}
};

}  // namespace Parde::Lowered

std::ostream& operator<<(std::ostream& os, const Flatrock::ParserExtractMatch& m) {
    if (m.header_valid_field)
        os << *m.header_valid_field;
    else
        os << "nullptr";
    return os;
}

#endif  // HAVE_FLATROCK

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_LOWER_FLATROCK_H_ */
