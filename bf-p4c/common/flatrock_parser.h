#ifndef BF_P4C_COMMON_FLATROCK_PARSER_H_
#define BF_P4C_COMMON_FLATROCK_PARSER_H_

#include <vector>

/**
 * @file flatrock_parser.h
 *
 * @warning The corresponding .cpp file is linked only with the compiler, not the assembler.
 * Thus, the constructors defined in the .cpp can be used only in the compiler.
 */

/**
 * @namespace Flatrock
 * @brief The namespace encapsulating Flatrock-specific constants and data structures
 */
namespace Flatrock {

enum constants {
    PARSER_PORT_METADATA_WIDTH = 15,  ///< Byte width of per-port metadata
    PARSER_PORT_METADATA_ITEMS = 40,  ///< Fpp_params.pm: N_PORT
    PARSER_PROFILES = 16,  ///< Fpp_params.pm: N_PHV_TCAM_DEPTH
    PARSER_STATE_WIDTH = 10,  ///< 8 + 2 bytes
    PARSER_FLAGS_WIDTH = 8,
    PARSER_PTR_MAX = 255,
    PARSER_W_OFFSET_MAX = 255,
    PARSER_PROFILE_PKTLEN_MAX = 63,
    PARSER_PROFILE_SEGLEN_MAX = 63,
    PARSER_PROFILE_PORT_BIT_WIDTH = 6,  ///< 8bit port_info = {2'b0, logic_port#(6b)}
    PARSER_ANALYZER_STAGES = 48,
};

/**
 * The structure representing instruction for %Flatrock parser ALU0 operating
 * with the packet pointer.
 *
 * It is used both in backend IR and in assembler.
 */
struct alu0_instruction {
    enum opcode_enum { INVALID = 99, OPCODE_NOOP = 10, OPCODE_0 = 0, OPCODE_1 = 1,
        OPCODE_2 = 2, OPCODE_3 = 3, OPCODE_4 = 4, OPCODE_5 = 5, OPCODE_6 = 6 } opcode = INVALID;
    union {
        struct {} opcode_0_noop;  // ptr += 0

        struct {
            int add_imm8s;
        } opcode_0_1;
        // opcode 0: ptr += imm8s
        // opcode 1: ptr += w2[7:0] + imm8s

        struct {
            int state_msb;
            int state_lsb;
        } opcode_2_3;
        // opcode 2: ptr += state[MSB:LSB], MSB&LSB -> 2/4/8/16-bit state sub-field
        // opcode 3: ptr += (state[MSB:LSB] << 2), MSB&LSB -> 2/4/8/16-bit state sub-field

        struct {
            int mask_imm8u;
            int shift_imm2u;
            int add_imm2u;
        } opcode_4_5_6;
        // opcode 4: ptr += ((w2[7:0] & imm8u) << imm2u) + (imm2u << 2)
        // opcode 5: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        // opcode 6: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //           if ((w2[7:0] & imm8u) >> imm2u) != 0,
        //           then + 4 - ((w2[7:0] & imm8u) >> imm2u)
    };

    alu0_instruction() : opcode(INVALID) {}
    alu0_instruction(opcode_enum opcode, std::vector<int> ops);
};

/**
 * The structure representing instruction for %Flatrock parser ALU1 operating
 * with the analyzer state.
 *
 * It is used both in backend IR and in assembler.
 */
struct alu1_instruction {
    enum opcode_enum { INVALID = 99, OPCODE_NOOP = 10, OPCODE_0 = 0, OPCODE_1 = 1, OPCODE_2 = 2,
        OPCODE_3 = 3, OPCODE_4 = 4, OPCODE_5 = 5, OPCODE_6 = 6, OPCODE_7 = 7} opcode = INVALID;
    union {
        struct {
            int state_msb;
            int state_lsb;
            int shift_imm4u;
        } opcode_0_1;
        // opcode 0: state[MSB:LSB] >>= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        // opcode 1: state[MSB:LSB] <<= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field

        struct {
            int state_msb;
            int state_lsb;
            int add_set_imm8s;
        } opcode_2_3;
        // opcode 2: state[MSB:LSB] += imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
        // opocde 3: state[MSB:LSB] = imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field

        struct {
            int state_msb;
            int state_lsb;
            int mask_mode;
            int mask_imm4u;
            int shift_dir;
            int shift_imm2u;
            int add_imm2u;
        } opcode_4_5_6_7;
        // opcode 4:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
        // opcode 5:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
        // opcode 6:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        // opcode 7:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        // MSB&LSB -> 8-bit state sub-field
    };

    alu1_instruction() : opcode(INVALID) {}
    alu1_instruction(opcode_enum opcode, std::vector<int> ops);
};

/**
 * The structure representing a byte of the Flatrock MD32 metadata.
 *
 * It is used both in backend IR and in assembler.
 */
struct metadata_select {
    enum type_enum { INVALID, CONSTANT, LOGICAL_PORT_NUMBER, PORT_METADATA,
        INBAND_METADATA, TIMESTAMP, COUNTER } type = INVALID;
    union {
        struct {
            int value;
        } constant;

        struct {} logical_port_number;

        struct {
            int index;
        } port_metadata;

        struct {
            int index;
        } inband_metadata;

        struct {
            int index;
        } timestamp;

        struct {
            int index;
        } counter;
    };

    metadata_select() : type(INVALID) {}
    explicit metadata_select(type_enum type, std::vector<int> ops = {});
};

}  /* namespace Flatrock */

#endif  /* BF_P4C_COMMON_FLATROCK_PARSER_H_ */
