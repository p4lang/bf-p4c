#ifndef BF_P4C_PARDE_FLATROCK_H_
#define BF_P4C_PARDE_FLATROCK_H_

#include <iostream>
#include <set>
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include "bf-p4c/common/flatrock.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "lib/ordered_set.h"

/*
 * Output ALU0 instruction in the form e.g. { opcode: 2, msb: 5, lsb: 2 }.
 * See bf-asm/SYNTAX.yaml for the list of ALU0 instructions.
 */
inline std::ostream& print_params(std::ostream& out,
        const Flatrock::alu0_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        out << "{ opcode: noop }";
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
    case Flatrock::alu0_instruction::OPCODE_1:
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        out << ", add: " << instruction.opcode_0_1.add_imm8s << " }";
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
    case Flatrock::alu0_instruction::OPCODE_3:
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        out << ", msb: " << instruction.opcode_2_3.state_msb
            << ", lsb: " << instruction.opcode_2_3.state_lsb << " }";
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
    case Flatrock::alu0_instruction::OPCODE_5:
    case Flatrock::alu0_instruction::OPCODE_6:
    {
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        auto original_flags = out.flags();
        out << ", mask: 0x" << std::hex << instruction.opcode_4_5_6.mask_imm8u;
        out.flags(original_flags);
        out << ", shift: " << instruction.opcode_4_5_6.shift_imm2u
            << ", add: " << instruction.opcode_4_5_6.add_imm2u << " }";
        break;
    }
    default:
        BUG("Invalid ALU0 opcode");
    }
    return out;
}

/*
 * Output ALU0 instruction in the form e.g. ptr += state[5:2].
 * See bf-asm/SYNTAX.yaml for the list of ALU0 instructions.
 */
inline std::ostream& print_pretty(std::ostream& out,
        const Flatrock::alu0_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        out << "noop";
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
        out << "ptr += " << instruction.opcode_0_1.add_imm8s;
        break;
    case Flatrock::alu0_instruction::OPCODE_1:
        out << "ptr += w2[7:0] + " << instruction.opcode_0_1.add_imm8s;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        out << "ptr += state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "]";
        break;
    case Flatrock::alu0_instruction::OPCODE_3:
        out << "ptr += (state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") << "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_5:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_6:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        out << ", ";
        out << "if ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") != 0, then + 4 - ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ")";
        break;
    default:
        BUG("Invalid ALU0 opcode");
    }
    return out;
}

/*
 * Output ALU1 instruction in the form e.g.
 * { opcode: 4, msb: 9, lsb: 2, mask_mode: 0, mask: 0xa, shift_dir: 1, shift: 2, add: 3 }.
 * See bf-asm/SYNTAX.yaml for the list of ALU1 instructions.
 */
inline std::ostream& print_params(std::ostream& out,
        const Flatrock::alu1_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        out << "{ opcode: noop }";
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
        out << "{ opcode: 0, msb: " << instruction.opcode_0_1.state_msb
                       << ", lsb: " << instruction.opcode_0_1.state_lsb
                       << ", shift: " << instruction.opcode_0_1.shift_imm4u << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        out << "{ opcode: 1, msb: " << instruction.opcode_0_1.state_msb
                       << ", lsb: " << instruction.opcode_0_1.state_lsb
                       << ", shift: " << instruction.opcode_0_1.shift_imm4u << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        out << "{ opcode: 2, msb: " << instruction.opcode_2_3.state_msb
                       << ", lsb: " << instruction.opcode_2_3.state_lsb
                       << ", add: " << instruction.opcode_2_3.add_set_imm8s << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        out << "{ opcode: 3, msb: " << instruction.opcode_2_3.state_msb
                       << ", lsb: " << instruction.opcode_2_3.state_lsb
                       << ", value: " << instruction.opcode_2_3.add_set_imm8s << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
    {
        out << "{ opcode: " << static_cast<int>(instruction.opcode)
            << ", msb: " << instruction.opcode_4_5_6_7.state_msb
            << ", lsb: " << instruction.opcode_4_5_6_7.state_lsb
            << ", mask_mode: " << instruction.opcode_4_5_6_7.mask_mode;
        auto original_flags = out.flags();
        out << ", mask: 0x" << std::hex << instruction.opcode_4_5_6_7.mask_imm4u;
        out.flags(original_flags);
        out << ", shift_dir: " << instruction.opcode_4_5_6_7.shift_dir
            << ", shift: " << instruction.opcode_4_5_6_7.shift_imm2u
            << ", add: " << instruction.opcode_4_5_6_7.add_imm2u << " }";
        break;
    }
    default:
        BUG("Invalid ALU1 opcode");
    }
    return out;
}

/*
 * Output ALU1 instruction in the form e.g. state[9:2] += ((w2[7:0] & 0xcc) >> 2) + (3 << 2).
 * See bf-asm/SYNTAX.yaml for the list of ALU1 instructions.
 */
inline std::ostream& print_pretty(std::ostream& out,
        const Flatrock::alu1_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        out << "noop";
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
        out << "state["
            << instruction.opcode_0_1.state_msb << ":"
            << instruction.opcode_0_1.state_lsb << "] >>= "
            << instruction.opcode_0_1.shift_imm4u;
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        out << "state["
            << instruction.opcode_0_1.state_msb << ":"
            << instruction.opcode_0_1.state_lsb << "] <<= "
            << instruction.opcode_0_1.shift_imm4u;
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        out << "state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] += "
            << instruction.opcode_2_3.add_set_imm8s;
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        out << "state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] = "
            << instruction.opcode_2_3.add_set_imm8s;
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
    {
        out << "state["
            << instruction.opcode_4_5_6_7.state_msb << ":"
            << instruction.opcode_4_5_6_7.state_lsb << "]";
        switch (instruction.opcode) {
        case Flatrock::alu1_instruction::OPCODE_4:
        case Flatrock::alu1_instruction::OPCODE_6:
            out << " += ";
            break;
        case Flatrock::alu1_instruction::OPCODE_5:
        case Flatrock::alu1_instruction::OPCODE_7:
            out << " -= ";
            break;
        default:
            break;
        }
        std::stringstream cond;
        cond << "((w2[7:0] & ";
        int mask = 0;
        if (instruction.opcode_4_5_6_7.mask_mode) {
            // if mask_mode == 1, then the mask is a full bit mask on the lower bits;
            // upper bits are 0xF
            mask = 0xf | instruction.opcode_4_5_6_7.mask_imm4u;
        } else {
            // if mask_mode == 0, then each bit is a half-nibble mask
            for (int i = 0, shift = 1; i < 4; i++) {
                mask |= (instruction.opcode_4_5_6_7.mask_imm4u << i) & shift;
                shift <<= 1;
                mask |= (instruction.opcode_4_5_6_7.mask_imm4u << (i + 1)) & shift;
                shift <<= 1;
            }
        }
        cond.fill('0');
        cond << "0x" << std::setw(2) << std::hex << mask;
        cond << ")";
        cond << (instruction.opcode_4_5_6_7.shift_dir ? " >> " : " << ");
        cond << instruction.opcode_4_5_6_7.shift_imm2u << ")";
        out << cond;
        out <<" + ("
            << instruction.opcode_4_5_6_7.add_imm2u << " << 2)";
        switch (instruction.opcode) {
        case Flatrock::alu1_instruction::OPCODE_6:
        case Flatrock::alu1_instruction::OPCODE_7:
            out << "if (" << cond << ") != 0, then + 4 - " << cond;
        default:
            break;
        }
        break;
    }
    default:
        BUG("Invalid ALU1 opcode");
    }
    return out;
}

/*
 * Output single metadata selection item.
 */
inline std::ostream& operator<<(std::ostream& out, const Flatrock::metadata_select& select) {
    switch (select.type) {
    case Flatrock::metadata_select::CONSTANT:
        out << select.constant.value;
        break;
    case Flatrock::metadata_select::LOGICAL_PORT_NUMBER:
        out << "logical_port_number";
        break;
    case Flatrock::metadata_select::PORT_METADATA:
        out << "port_metadata " << select.port_metadata.index;
        break;
    case Flatrock::metadata_select::INBAND_METADATA:
        out << "inband_metadata " << select.inband_metadata.index;
        break;
    case Flatrock::metadata_select::TIMESTAMP:
        out << "timestamp " << select.timestamp.index;
        break;
    case Flatrock::metadata_select::COUNTER:
        out << "counter " << select.counter.index;
        break;
    default:
        BUG("Invalid metadata selection");
    }
    return out;
}

namespace Flatrock {

enum class ExtractType {
    None = 0,
    Packet,
    Other,
};

enum class ExtractSubtype {
    None = 0,
    Constant,
    PovFlags,
    PovState,
    ChecksumError,
    Udf0,
    Udf1,
    Udf2,
    Udf3,
    Ghost,
    Tm,
    Bridge,
};

/// Information about one POV select value.
struct PovSelectKey {
    enum {FLAGS = 0, STATE = 1} type = FLAGS;
    /// Extraction byte start position (valid value is in range <0,7>)
    uint8_t start = 0;
    bool operator==(const PovSelectKey &r) const {
        return std::tie(type, start) == std::tie(r.type, r.start);
    }
    bool operator<(const PovSelectKey& r) const {
        return std::tie(type, start) < std::tie(r.type, r.start);
    }
};

/// Information about value of one part of the PHE source.
struct ExtractInfo {
    /**
     * @brief String representation of the PHV container (or its slice).
     *
     * The whole container in case of packet PHE source or other PHE8 sources.
     * Container slice in case of other PHE16 or PHE32 sources.
     */
    cstring container;
    /**
     * @brief Value used for the extraction.
     *
     * In case of the packet PHE source, this is the offset of the data extracted
     * from the packet.
     * In case of the other PHE source, the semantics of the value depends on the
     * subtype.
     */
    int value;
    /**
     * @brief The subtype of the other PHE source.
     *
     * This is not used in case of the packet PHE source.
     */
    ExtractSubtype subtype;
};

/**
 * @brief Information about PHE source for PHV builder in Flatrock parser
 *        used by lowered IR::Flatrock::Parser node.
 */
struct PheSource {
    /// PHE source type (packet/other)
    ExtractType type = ExtractType::None;
    /**
     * @brief Values used for the extraction of the PHE source.
     *
     * Depending on the PHE source type, there are following values:
     * - packet PHE8 source - 4 offsets of data from the packet
     * - packet PHE16 source - 2 offsets of data from the packet
     * - packet PHE32 source - 1 offset of data from the packet
     * - other PHE8/PHE16/PHE32 sources - 4 values specified by the subtype
     */
    std::vector<ExtractInfo> values = {};
    /// Header name of the header used for packet PHE sources.
    boost::optional<cstring> hdr_name = boost::none;
    /// Comments with information about all extractions for this PHE source
    ::BFN::DebugInfo debug = {};
};

/// Information about PHV container used to index it in the map.
struct ParserExtractContainer {
    /// Size of the PHV container of the extract
    PHV::Size size;
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

    bool operator<(const ParserExtractContainer& r) const {
        return std::tie(size, index) < std::tie(r.size, r.index);
    }
};

/**
 * @brief Information about PHV builder extract match value used to index extract values
 *        in the map.
 */
struct ParserExtractMatch {
    /// Valid field of a header related to the extract.
    const PHV::Field* header_valid_field = nullptr;

    bool operator<(const ParserExtractMatch& r) const {
        return header_valid_field < r.header_valid_field;
    }

    /**
     * @brief Returns information whether the object represents match-all pattern or not.
     *
     * @return true If the object represents match-all pattern.
     * @return false If the object does not represent match-all pattern.
     */
    bool is_match_all(void) const {
        return header_valid_field == nullptr;
    }
};

/**
 * @brief Intermediate representation of values for parser extractions.
 *
 * Fed by ComputeFlatrockParserIR, consumed by ReplaceFlatrockParserIR.
 * @pre The slices stored in @a SliceInfoSet should not overlap.
 */
struct ParserExtractValue {
    /// Information needed for the packet PHE source.
    struct HeaderInfo {
        /// Header name for the packet PHE source.
        cstring name;
        /// Offset of the data from the packet.
        unsigned int offset;
    };

    /// Information needed for the other PHE source.
    struct SliceInfo {
        /// Slice in the PHV container.
        le_bitrange slice;
        /// Subtype of the part of the other PHE source in the given slice.
        ExtractSubtype subtype;
        /**
         * @brief The value for a part of the other PHE source.
         *
         * The semantics depends on the subtype:
         * - 'Constant': the value is a constant value that should be extracted into the given
         *   slice of the container.
         *   All the slices with 'Constant' subtype need to be accumulated and their values
         *   appropriately shifted to create 8-bit wide slices used for the other PHE sources.
         * - 'PovFlags': the value is an index of byte in POV flags that should be extracted
         *   into the given slice of the container.
         */
        unsigned int value;

        bool operator<(const SliceInfo& r) const {
            return std::tie(slice, subtype, value) < std::tie(r.slice, r.subtype, r.value);
        }
    };

    /**
     * @brief Slices of the PHV container of one PHE source extraction.
     *
     * Might not be the whole container if multiple extractions are packed
     * into one PHV container.
     */
    typedef std::set<SliceInfo> SliceInfoSet;

    /// Type for PHE source values
    typedef std::variant<HeaderInfo, SliceInfoSet> ValueInfo;

    /// PHE source type (packet/other)
    ExtractType type;
    /// Textual information about extracts used as comments in the resulting bfa file
    ordered_set<cstring> comments;

 private:
    /// Values for the PHE source (HeaderInfo for packet, SliceInfoSet for other source).
    ValueInfo source_value_info;

 public:
    ParserExtractValue() = delete;
    ParserExtractValue(const ValueInfo info, const cstring comment) :
            type{std::get_if<HeaderInfo>(&info) ? ExtractType::Packet : ExtractType::Other},
            comments{comment}, source_value_info{info} {}

    /**
     * @brief Adds one comment to the PHE source extract.
     *
     * @param c The comment to add.
     */
    void add_comment(const cstring c) {
        comments.emplace(c);
    }

    /**
     * @brief Performs checks and adds information about PHE source extract.
     *
     * @param value Information about packet or other PHE source.
     * @param alloc PHV allocation information about the field for which we add extract info.
     */
    void add_value(const ValueInfo& value, const PHV::AllocSlice& alloc) {
        if (const HeaderInfo* new_hdr = std::get_if<HeaderInfo>(&value)) {
            // Packet type
            // TODO check if the layout of slices in the container is the same as the layout
            // of fields in the header in case of extract from packet
            BUG_CHECK(Flatrock::ExtractType::Packet == type,
                    "Allocation of field: \"%1%\" can not be satisfied as it requires to use"
                    " extraction from packet and other source to the same container",
                    alloc);
            BUG_CHECK(new_hdr->name == get_header_name(),
                    "Fields from different headers (%1%, %2%)"
                    " are not supported in the same container: %3%",
                    new_hdr->name, get_header_name(), alloc);
            BUG_CHECK(new_hdr->offset == get_source_offset(),
                    "Field offset (%1%) differs from offset (%2%) of other field allocated"
                    " in the same container: %3%",
                    new_hdr->offset, get_source_offset(), alloc);
        } else if (const SliceInfoSet* new_slices = std::get_if<SliceInfoSet>(&value)) {
            // Other type
            BUG_CHECK(Flatrock::ExtractType::Other == type,
                    "Allocation of field: \"%1%\" can not be satisfied as it requires to use"
                    " extraction from packet and other source to the same container",
                    alloc);
            SliceInfoSet* slices = std::get_if<SliceInfoSet>(&source_value_info);
            CHECK_NULL(slices);
            slices->insert(new_slices->begin(), new_slices->end());
        } else {
            BUG("Unexpected extract type");
        }
    }

    /**
     * @brief Get the header name of packet PHE source extract.
     *
     * When used with other PHE source extract, reports a bug.
     *
     * @return const cstring& Header name.
     */
    const cstring& get_header_name(void) const {
        if (const HeaderInfo* hdr = std::get_if<HeaderInfo>(&source_value_info))
            return hdr->name;
        else
            BUG("Unexpectedly getting info about header from an other PHE source.");
    }

    /**
     * @brief Get the packet data offset of packet PHE source extract.
     *
     * When used with other PHE source extract, reports a bug.
     *
     * @return const unsigned& Offset.
     */
    const unsigned int& get_source_offset(void) const {
        if (const HeaderInfo* hdr = std::get_if<HeaderInfo>(&source_value_info))
            return hdr->offset;
        else
            BUG("Unexpectedly getting info about offset from an other PHE source.");
    }

    /**
     * @brief Get the slices of other PHE source extract.
     *
     * When used with packet PHE source extract, reports a bug.
     *
     * @return const SliceInfoSet& The set of slices.
     */
    const SliceInfoSet& get_slices(void) const {
        if (const SliceInfoSet* slices = std::get_if<SliceInfoSet>(&source_value_info))
            return *slices;
        else
            BUG("Unexpectedly getting info about slices from a packet PHE source.");
    }
};
}  // namespace Flatrock

inline std::ostream& operator<<(std::ostream& os, const Flatrock::ExtractType type) {
#define CASE(VAL)                    \
    case Flatrock::ExtractType::VAL: \
        return os << #VAL

    switch (type) {
        CASE(None);
        CASE(Packet);
        CASE(Other);
        default:
            BUG("Unexpected ExtractType");
    }

#undef CASE
}

inline std::ostream& operator<<(std::ostream& os, const Flatrock::ExtractSubtype subtype) {
#define CASE(VAL)                       \
    case Flatrock::ExtractSubtype::VAL: \
        return os << #VAL

    switch (subtype) {
        CASE(None);
        CASE(Constant);
        CASE(PovFlags);
        CASE(PovState);
        CASE(ChecksumError);
        CASE(Udf0);
        CASE(Udf1);
        CASE(Udf2);
        CASE(Udf3);
        CASE(Ghost);
        CASE(Tm);
        CASE(Bridge);

        default:
            BUG("Unexpected ExtractSubtype");
    }

#undef CASE
}

inline std::ostream& operator<<(std::ostream& os, const Flatrock::ParserExtractContainer& c) {
    return os << c.size << c.index;
}

std::ostream& operator<<(std::ostream& os, const Flatrock::ParserExtractMatch& m);

inline std::ostream& operator<<(std::ostream& os, const Flatrock::ParserExtractValue& v) {
    os << "type=" << v.type << std::endl;
    if (v.type == Flatrock::ExtractType::Packet) {
        os << "    header=" << v.get_header_name() << ", offset=" << v.get_source_offset() <<
                std::endl;
    } else if (v.type == Flatrock::ExtractType::Other) {
        for (const auto& s : v.get_slices()) {
            os << "    slice=" << s.slice <<
                    ", subtype=" << s.subtype <<
                    ", value=" << s.value << std::endl;
        }
    }
    for (const auto& c : v.comments) {
        os << "    comment=\"" << c << "\"" << std::endl;
    }
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const Flatrock::PovSelectKey& p) {
    if (p.type == Flatrock::PovSelectKey::FLAGS) {
        os << "flags ";
    } else {
        // p.type == Flatrock::PovSelectKey::STATE
        os << "state ";
    }
    return os << std::to_string(p.start);
}

#endif  /* BF_P4C_PARDE_FLATROCK_H_ */
