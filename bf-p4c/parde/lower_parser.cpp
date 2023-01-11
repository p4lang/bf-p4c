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
#include "bf-p4c/parde/coalesce_learning.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/dump_parser.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/flatrock.h"
#include "bf-p4c/parde/parde_utils.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/split_parser_state.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/common/allocators.h"
#include "bf-p4c/parde/common/match_reducer.h"
#include "bf-p4c/parde/lowered/compute_lowered_parser_ir.h"
#include "bf-p4c/parde/lowered/helpers.h"
#include "bf-p4c/parde/lowered/hoist_common_match_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"
#include "lib/stringref.h"

namespace Parde::Lowered {

#ifdef HAVE_FLATROCK

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

constexpr auto BITS_IN_BYTE = 8;

class ComputeFlatrockParserIR : public ParserInspector {
    typedef std::tuple<PHV::Size, unsigned int /* container index */,
            unsigned int /* byte index inside container */> PovFlagsContainerInfo;

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

    profile_t init_apply(const IR::Node *node) override {
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
    unsigned int allocate_pov_flags(const PHV::AllocSlice& alloc,
            const cstring field_name) {
        auto container_ref = new IR::BFN::ContainerRef(alloc.container());
        int lo = alloc.container_slice().loByte() * BITS_IN_BYTE;
        int hi = lo + (BITS_IN_BYTE - 1);
        le_bitrange slice_range{lo, hi};
        container_ref->range = slice_range.toOrder<Endian::Network>(alloc.container().size());

        PovFlagsContainerInfo container_info{alloc.container().type().size(),
                alloc.container().index(), alloc.container_slice().loByte()};
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
    void add_extract(const gress_t gress, const PHV::AllocSlice& alloc,
            const cstring comment, const Flatrock::ParserExtractMatch match,
            Flatrock::ParserExtractValue::ValueInfo value_info) {
        Flatrock::ParserExtractContainer container{alloc.container().type().size(),
                alloc.container().index()};
        Flatrock::ParserExtractValue new_extract_value{value_info, comment};

        if (auto it = extracts_info[gress].find(container); it != extracts_info[gress].end()) {
            auto& match_extract_map = it->second;
            if (auto it2 = match_extract_map.find(match); it2 == match_extract_map.end()) {
                match_extract_map.emplace(match, new_extract_value);
                LOG3("Adding new " << gress << " extract:" << std::endl <<
                        "  " << container << ":" << std::endl <<
                        "  - " << match << ": " << new_extract_value);
            } else {
                auto& extract_value = it2->second;
                extract_value.add_value(value_info, alloc);
                extract_value.add_comment(comment);
                LOG3(gress << " extract updated:" << std::endl <<
                        "  " << container << ":" << std::endl <<
                        "  - " << match << ": " << extract_value);
            }
        } else {
            ordered_map<Flatrock::ParserExtractMatch, Flatrock::ParserExtractValue>
                    match_extract_map;
            match_extract_map.emplace(match, new_extract_value);
            extracts_info[gress].emplace(container, match_extract_map);
            LOG3("Adding new " << gress << " extract:" << std::endl <<
                    "  " << container << ":" << std::endl <<
                    "  - " << match << ": " << new_extract_value);
        }
    }

    bool preorder(const IR::BFN::Pipe* pipe) override {
        auto *igMeta = getMetadataType(pipe, "ingress_intrinsic_metadata");
        BUG_CHECK(igMeta, "Could not find ingress_intrinsic_metadata");
        igMetaName = igMeta->name;
        add_zero_pov_flag_byte(pipe);
        return true;
    }

    bool preorder(const IR::BFN::ParserZeroInit* zero) override {
        return preorder(new IR::BFN::Extract(zero->field, new IR::BFN::ConstantRVal(0)));
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

            cstring comment = debugInfoFor(extract, alloc,
                    extract->source->is<IR::BFN::InputBufferRVal>() ?
                        extract->source->to<IR::BFN::InputBufferRVal>()->range :
                        nw_bitrange{},
                    true);

            Flatrock::ParserExtractMatch match{nullptr};

            const auto* valid_field = phv.field(hdr_name + ".$valid");
            if (valid_field) {
                LOG3("Found valid field: " << valid_field);

                const auto vf_allocs = phv.get_alloc(valid_field, nullptr,
                        PHV::AllocContext::PARSER);
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

            if (const auto *pkt_rval = extract->source->to<IR::BFN::PacketRVal>()) {
                size_t hdr_bit_width = get_hdr_bit_width(lval->field);
                BUG_CHECK(hdr_bit_width % BITS_IN_BYTE == 0,
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
                BUG_CHECK(hdr_offset_in_bits % BITS_IN_BYTE == 0,
                        "Offset of header %1% is not byte-aligned (%2% bits)"
                        " during parser lowering",
                        hdr_name, hdr_offset_in_bits);
                int container_offset_in_bits = field_offset_in_bits -
                        (alloc.container().size() - (alloc.container_slice().hi + 1));
                LOG5("container_offset_in_bits: " << container_offset_in_bits);
                BUG_CHECK(container_offset_in_bits >= 0, "Invalid container allocation");
                BUG_CHECK(container_offset_in_bits % BITS_IN_BYTE == 0,
                        "Invalid position of slice in container");
                int container_offset_in_bytes = container_offset_in_bits / BITS_IN_BYTE;
                LOG5("container_offset_in_bytes: " << container_offset_in_bytes);
                const auto *state = findContext<IR::BFN::ParserState>();
                CHECK_NULL(state);
                if (headers[state].count(hdr_name) == 0) {
                    int push_hdr_width = hdr_bit_width / BITS_IN_BYTE;
                    headers[state].insert(hdr_name);
                    LOG3("Collecting state[" << state->name << "] push_hdr: " << hdr_name <<
                            ", width (in bytes): " << push_hdr_width <<
                            ", offset (in bytes): " << (hdr_offset_in_bits / BITS_IN_BYTE));
                    rules_info[state].push_hdr.push_back({
                        hdr_name,
                        push_hdr_width,
                        hdr_offset_in_bits / BITS_IN_BYTE
                    });
                }
                Flatrock::ParserExtractValue::ValueInfo value_info{
                    Flatrock::ParserExtractValue::HeaderInfo{hdr_name,
                        static_cast<unsigned int>(container_offset_in_bytes)}};
                if (used_in_ingress)
                    add_extract(INGRESS, alloc, comment, match, value_info);
                if (used_in_egress)
                    add_extract(EGRESS, alloc, comment, match, value_info);
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
                if (used_in_egress)
                    add_extract(EGRESS, alloc, comment, match, value_info);
            }
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

        /// \pre We assume that t->saves are already correctly assigned to
        /// W0, W1 by the AllocateParserMatchRegisters
        for (const auto* save : t->saves) {
            const auto* packet_source = save->source->to<IR::BFN::PacketRVal>();
            BUG_CHECK(packet_source, "Unsupported SaveToRegister source: %1%", save->source);

            int offset_in_bits = packet_source->range.lo;
            int size = packet_source->range.size();
            BUG_CHECK(offset_in_bits % BITS_IN_BYTE == 0,
                      "Unsupported offset of match value (in bits): %1%",
                      offset_in_bits);
            BUG_CHECK(size <= 16,
                      "Cannot match on %1%b value; maximum size is %2%b",
                      size, 16);
            BUG_CHECK(transition_info.next_w.size() < 2,
                      "Only %1% 16-bit match values are supported, can not collect: %2%",
                      2, save);
            transition_info.next_w.push_back({offset_in_bits / BITS_IN_BYTE, size});
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

        for (auto& [container_ref, debug_info_set] : pov_flags) {
            container_ref->debug.info.insert(container_ref->debug.info.begin(),
                    debug_info_set.begin(), debug_info_set.end());
            pov_flags_refs.push_back(container_ref);
        }

        auto log = [this](gress_t gress){
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
    std::map<gress_t, ordered_map<Flatrock::ParserExtractContainer,
            ordered_map<Flatrock::ParserExtractMatch,
                Flatrock::ParserExtractValue>>> extracts_info;

    /**
     * @brief Get the pointer to the vector of container refs corresponding to
     *        the containers into which the POV flags bytes are extracted.
     *
     * The order in the vector is the order of byte in POV flags vector.
     */
    const IR::Vector<IR::BFN::ContainerRef>* get_pov_flags_refs() const {
        return &pov_flags_refs;
    }

    /**
     * @brief Get the POV flags byte index for specified PHV field allocation.
     *
     * @param alloc PHV allocation slice.
     * @return boost::optional<unsigned int> POV flags byte index if POV flags byte
     *         is assigned to a PHV byte given by alloc slice.
     */
    boost::optional<unsigned int> get_pov_flags_byte(const PHV::AllocSlice& alloc) const {
        PovFlagsContainerInfo container_info{alloc.container().type().size(),
                alloc.container().index(), alloc.container_slice().loByte()};
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
            return boost::none;
        }
    }

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
    typedef std::array<std::pair<
            ordered_set<::Flatrock::PovSelectKey>,
            std::vector<IR::Flatrock::PhvBuilderExtract*>>, PARSER_PHV_BUILDER_GROUP_PHES_TOTAL>
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
    typedef std::pair<Flatrock::ParserExtractContainer, Flatrock::ParserExtractValue>
            ParserExtract;

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
     * @return boost::optional<::Flatrock::ModifyFlag> modify_flag action.
     */
    boost::optional<::Flatrock::ModifyFlag> create_modify_flag(const cstring hdr_name) const {
        if (hdr_name == payloadHeaderName)
            return boost::none;

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
                return boost::none;
            }
            PHV::AllocSlice alloc = allocs.front();
            unsigned int bit_index = alloc.container_slice().lo % BITS_IN_BYTE;
            auto byte_index = computed.get_pov_flags_byte(alloc);
            if (!byte_index)
                return boost::none;
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
    IR::Flatrock::AnalyzerStage* get_analyzer_stage(unsigned int stage_id,
            std::vector<IR::Flatrock::AnalyzerStage*>& analyzer_stages) const {
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
    unsigned int prepare_push_hdr(boost::optional<::Flatrock::PushHdrId>& push_hdr_id,
            boost::optional<::Flatrock::ModifyFlag>& modify_flag,
            IR::Flatrock::AnalyzerStage* analyzer_stage,
            unsigned int hdr_id, AnalyzerRuleInfo& state_info) const {
        unsigned int rule_id = analyzer_stage->rules.size();
        // This is a bug, this should not happen as state splitting should take care of this
        BUG_CHECK(rule_id < ::Flatrock::PARSER_ANALYZER_STAGE_RULES,
                "Maximum number of analyzer rules (%1%) in stage %2% exceeded",
                ::Flatrock::PARSER_ANALYZER_STAGE_RULES, analyzer_stage->stage);

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
                analyzer_stage = get_analyzer_stage(stage_id, analyzer_stages);
                boost::optional<::Flatrock::PushHdrId> push_hdr_id{boost::none};
                boost::optional<::Flatrock::ModifyFlag> modify_flag{boost::none};
                unsigned int rule_id = prepare_push_hdr(push_hdr_id, modify_flag,
                        analyzer_stage, hdr_id, state_info);

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
                analyzer_rule->push_hdr_id = push_hdr_id;
                analyzer_rule->match_state = state_match;
                analyzer_rule->modify_flag0 = modify_flag;
                analyzer_rule->next_alu0_instruction = Flatrock::alu0_instruction(
                    Flatrock::alu0_instruction::OPCODE_NOOP);
                analyzer_rule->next_alu1_instruction = Flatrock::alu1_instruction(
                    Flatrock::alu1_instruction::OPCODE_NOOP);
                analyzer_stage->rules.push_back(analyzer_rule);
                LOG3("AnalyzerStage[" << analyzer_stage->stage << "] added " << analyzer_rule);
            }

            if (state_info.transitions.size() > 0) {
                analyzer_stage = get_analyzer_stage(stage_id, analyzer_stages);
            }

            for (const auto& transition : state_info.transitions) {
                boost::optional<::Flatrock::PushHdrId> push_hdr_id{boost::none};
                boost::optional<::Flatrock::ModifyFlag> modify_flag{boost::none};
                unsigned int rule_id = prepare_push_hdr(push_hdr_id, modify_flag,
                        analyzer_stage, hdr_id, state_info);

                cstring next_state_name = sanitizeName(transition.next_state->name);

                boost::optional<int> next_w0_offset{boost::none};
                boost::optional<int> next_w1_offset{boost::none};
                boost::optional<int> next_w2_offset{boost::none};

                if (transition.next_w.size() > 0)
                    next_w0_offset = transition.next_w[0].offset;
                if (transition.next_w.size() > 1)
                    next_w1_offset = transition.next_w[1].offset;
                BUG_CHECK(transition.next_w.size() <= 2,
                          "Only 2 next_w offsets are supported for matching!");

                auto* analyzer_rule = new IR::Flatrock::AnalyzerRule(
                    /* id */ rule_id,
                    /* next_state */ boost::none,
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
                std::vector<match_t *> match_reg_vals;
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
                BUG_CHECK(match_reg_vals.size() <= 2,
                          "More than 2 match registers encountered!");
                // Split the actual match value
                match_t match_val = transition.match;
                match_t match_vals[2] = {
                    match_val,
                    match_val
                };
                // If both are used, the first one matches the top 16 bits (= second 16b chunk)
                if (match_reg_vals.size() > 1) {
                    match_vals[0] = { match_val.word0 >> ::Flatrock::PARSER_W_WIDTH*8,
                                      match_val.word1 >> ::Flatrock::PARSER_W_WIDTH*8 };
                }
                match_vals[0].setwidth(::Flatrock::PARSER_W_WIDTH*8);
                match_vals[1].setwidth(::Flatrock::PARSER_W_WIDTH*8);
                // Fill the match values based on the order stored previously
                for (unsigned i = 0; i < match_reg_vals.size(); i++)
                    *(match_reg_vals[i]) = match_vals[i];
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

        const auto sub_group_offset = extract_container.index / phe_sources /
                Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES;
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
                if (match.is_match_all())
                    continue;
                const auto phe_info = get_phe_info(container);
                auto& pov_select_set =
                        phv_builder_extracts[phe_info.phv_builder_group_index].first;
                const auto allocs = phv.get_alloc(
                        match.header_valid_field, nullptr, PHV::AllocContext::PARSER);
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
            const PovSelectMatchFieldArray& pov_select_match_fields, const gress_t gress) const {
        unsigned i = 0;
        for (const auto& field_set : pov_select_match_fields) {
            for (const auto& seq : parserHeaderSeqs.sequences.at(INGRESS)) {
                ordered_set<const PHV::Field*> match_set;
                std::for_each(field_set.begin(), field_set.end(),
                        [&](const PHV::Field* f){
                    if (seq.find(f->header()) != seq.end()) match_set.emplace(f);
                });
                if (!match_set.empty())
                    extract_match_fields[i].emplace(match_set);
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
                // FIXME uncomment this when PHV allocation is fixed to not break this constraint
                // P4C-5084
                /*
                BUG_CHECK(*phv_builder_extract->source[phe_source_index].hdr_name ==
                    extract_value.get_header_name(),
                    "Values from different headers %1% and %2% allocated into the same "
                    "PHE source of PHV builder group %3% %4%",
                    *phv_builder_extract->source[phe_source_index].hdr_name,
                    extract_value.get_header_name(), phe_info.phv_builder_group_index,
                    phv_builder_extract);
                */
            }
            phv_builder_extract->source[phe_source_index].hdr_name =
                    extract_value.get_header_name();
            phv_builder_extract->source[phe_source_index].values.push_back(
                    {phe_info.container_name,
                    static_cast<int>(extract_value.get_source_offset()),
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
                const auto suffix = (phe_info.phe_sources ==
                        Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES) ? "" :
                        '(' + std::to_string(lo) + ".." + std::to_string(hi) + ')';
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
                            BUG("Extract subtype %1% is currently not supported",
                                    ss.str());
                        }
                        phv_builder_extract->source[phe_source_index].values.
                                push_back({phe_info.container_name + suffix,
                                value, slice.subtype});
                        break;
                    }
                }
            }
        } else {
            BUG("Missing extract type!");
        }
        LOG3("Update PHV builder group " << phe_info.phv_builder_group_index <<
                " " << phv_builder_extract);
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
            /* initial_state */ boost::none,
            /* initial_state_name */ initial_state_name,
            /* initial_flags */ boost::none,
            /* initial_ptr */ 0,  // Extraction of ingress intrinsic metadata is always expected
            /* initial_w0_offset */ boost::none,
            /* initial_w1_offset */ boost::none,
            /* initial_w2_offset */ boost::none);
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
        // POVs are placed at the end of the bridge metadata
        // See https://wiki.ith.intel.com/pages/viewpage.action?
        //     pageId=1581874739#FrameProcessingPipeline(FPP)-POVFormat
        // The values need to be in sync with the code in assembler
        // that stores POVs into the remaining bridge metadata.
        // See Deparser::write_config(Target::Flatrock::deparser_regs &).
        pseudo_parser->pov_state_pos = Flatrock::PARSER_BRIDGE_MD_WIDTH
            - Flatrock::PARSER_PKT_STATE_WIDTH;
        pseudo_parser->pov_flags_pos = Flatrock::PARSER_BRIDGE_MD_WIDTH
            - Flatrock::PARSER_PKT_STATE_WIDTH - Flatrock::PARSER_FLAGS_WIDTH;
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
            // and not a compiler-generated counter stall state.
            std::string next_name(match->next->name.c_str());
            if (!is_loopback_state(match->next->name) &&
                !((next_name.find("$") != std::string::npos) &&
                  (next_name.find("ctr_stall") != std::string::npos) &&
                  (next_name.find("$") < next_name.rfind("ctr_stall")))) {
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
#ifdef HAVE_FLATROCK
    ComputeFlatrockParserIR* computeFlatrockParserIR = nullptr;

    const IR::Vector<IR::BFN::ContainerRef>* get_pov_flags_refs() const {
        CHECK_NULL(computeFlatrockParserIR);
        return computeFlatrockParserIR->get_pov_flags_refs();
    }
#endif

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
        computeFlatrockParserIR = new ComputeFlatrockParserIR(phv, defuse);
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
            new PassRepeated({
                lower_parser_info,
                new HoistCommonMatchOperations(*lower_parser_info,
                                               *computeLoweredParserIR,
                                               clotInfo),
                LOGGING(4) ? new DumpParser("after_hoisting") : nullptr,
                lower_parser_info,
                new MergeLoweredParserStates(*lower_parser_info,
                                             *computeLoweredParserIR,
                                             clotInfo,
                                             defuseInfo),
                LOGGING(4) ? new DumpParser("after_merging") : nullptr
            }),
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
    ComputeLoweredDeparserIR(const PhvInfo& phv, const ClotInfo& clotInfo
#ifdef HAVE_FLATROCK
        , const IR::Vector<IR::BFN::ContainerRef>* pov_flags_refs = nullptr
#endif
    )
        : phv(phv), clotInfo(clotInfo), nextChecksumUnit(0), lastSharedUnit(0),
          nested_unit(0),
          normal_unit(4)
#ifdef HAVE_FLATROCK
          , pov_flags_refs(pov_flags_refs)
#endif
            {
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

            // Calculate the containers for POV bits (states/flags)
            // TODO POV state bits containers to be added here
            CHECK_NULL(pov_flags_refs);
            if (pov_flags_refs->size() > 0)
                loweredDeparser->params.push_back(
                    new IR::BFN::LoweredDeparserParameter("pov", *pov_flags_refs));
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
#ifdef HAVE_FLATROCK
    const IR::Vector<IR::BFN::ContainerRef>* pov_flags_refs;
#endif
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
    LowerDeparserIR(const PhvInfo& phv, ClotInfo& clot
#ifdef HAVE_FLATROCK
            , const IR::Vector<IR::BFN::ContainerRef>* pov_flags_refs = nullptr
#endif
    ) {
        auto* rewriteEmitClot = new RewriteEmitClot(phv, clot);
        auto* computeLoweredDeparserIR = new ComputeLoweredDeparserIR(phv, clot
#ifdef HAVE_FLATROCK
            , pov_flags_refs
#endif
        );  // NOLINT(whitespace/parens)
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

}  // namespace Parde::Lowered

std::ostream& operator<<(std::ostream& os, const Flatrock::ParserExtractMatch& m) {
    if (m.header_valid_field)
        os << *m.header_valid_field;
    else
        os << "nullptr";
    return os;
}

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
    using namespace Parde::Lowered;

    auto pragma_no_init = new PragmaNoInit(phv);
    auto compute_init_valid = new ComputeInitZeroContainers(
        phv, defuse, pragma_no_init->getFields(), origParserZeroInitContainers);
    auto parser_info = new CollectLoweredParserInfo;
    auto lower_parser_ir = new LowerParserIR(phv, defuse, clot, parserHeaderSeqs,
            origParserZeroInitContainers, defuseInfo);

    addPasses({
        pragma_no_init,
        lower_parser_ir,
#ifdef HAVE_FLATROCK
        Device::currentDevice() == Device::FLATROCK ?
            new LowerDeparserIR(phv, clot, lower_parser_ir->get_pov_flags_refs()) :
#endif
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
