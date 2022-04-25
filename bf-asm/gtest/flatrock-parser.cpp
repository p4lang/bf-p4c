#include "gtest/gtest.h"
#include "flatrock/parser.h"
#include "flatrock/hdr.h"

namespace {

TEST(flatrock_parser, section_hdr) {
    const char* parser_str = R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    md32: 0
    ethernet: 1
    ipv4: 2
    ipv6: 3
    tcp: 4
    udp: 5
  seq:
    0: [ 1, 2, 4 ]  # ethernet, ipv4, tcp
    1: [ ethernet, ipv4, udp ]
  seq_pos: 2
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
  len_pos: 4
  off_pos: 6
)PARSER_CFG";

    options.target = NO_TARGET;
    Hdr::test_clear();

    asm_parse_string(parser_str);

    // hdr > map
    EXPECT_EQ(Hdr::id(0, "md32"), 0);
    EXPECT_EQ(Hdr::id(0, "ethernet"), 1);
    EXPECT_EQ(Hdr::id(0, "ipv4"), 2);
    EXPECT_EQ(Hdr::id(0, "ipv6"), 3);
    EXPECT_EQ(Hdr::id(0, "tcp"), 4);
    EXPECT_EQ(Hdr::id(0, "udp"), 5);
    // hdr > seq
      // seq 0
    EXPECT_EQ(Hdr::hdr.seq.at(0).at(0), 1);  // ethernet
    EXPECT_EQ(Hdr::hdr.seq.at(0).at(1), 2);  // ipv4
    EXPECT_EQ(Hdr::hdr.seq.at(0).at(2), 4);  // tcp
      // seq 1
    EXPECT_EQ(Hdr::hdr.seq.at(1).at(0), 1);  // ethernet
    EXPECT_EQ(Hdr::hdr.seq.at(1).at(1), 2);  // ipv4
    EXPECT_EQ(Hdr::hdr.seq.at(1).at(2), 5);  // udp
    // hdr > seq_pos
    EXPECT_EQ(Hdr::hdr.seq_pos, 2);
    // hdr > len
      // IPv4
    EXPECT_EQ(Hdr::hdr.len.at(2).base_len, 20);
    EXPECT_EQ(Hdr::hdr.len.at(2).num_comp_bits, 4);
    EXPECT_EQ(Hdr::hdr.len.at(2).scale, 2);
      // IPv6
    EXPECT_EQ(Hdr::hdr.len.at(3).base_len, 40);
    EXPECT_EQ(Hdr::hdr.len.at(3).num_comp_bits, 7);
    EXPECT_EQ(Hdr::hdr.len.at(3).scale, 3);
    // hdr > len_pos
    EXPECT_EQ(Hdr::hdr.len_pos, 4);
    // hdr > off_pos
    EXPECT_EQ(Hdr::hdr.off_pos, 6);

    delete ::asm_parser;
    ::asm_parser = nullptr;
}

TEST(flatrock_parser, section_parser_ingress) {
    const char* parser_str = R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    parse_ethernet: 0x********_******01
    parse_ipv4: 0x********_******02
  port_metadata:
    0: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    1: [255]
  profile 1:
    match_port: *
    match_inband_metadata: 0x**ffff00_********
    initial_state: parse_ethernet
    initial_flags: 0x0011223344556677
    initial_ptr: 12
    initial_w0_offset: 0
    initial_w1_offset: 1
    initial_w2_offset: 2
    initial_alu0_instruction: { opcode: 0, add: -3 }
    initial_alu1_instruction: { opcode: 0, msb: 15, lsb: 8, shift: 7 }
    metadata_select: [1, logical_port_number, port_metadata 1, inband_metadata 2, timestamp 3, counter 4]
)PARSER_CFG";

    options.target = NO_TARGET;
    Hdr::test_clear();

    asm_parse_string(parser_str);
    auto *asm_parser = dynamic_cast<FlatrockAsmParser *>(::asm_parser);

    // parser ingress > port_metadata
      // 0
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[0], 0);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[1], 1);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[2], 2);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[3], 3);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[4], 4);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[5], 5);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[6], 6);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[7], 7);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[8], 8);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[9], 9);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[10], 10);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[11], 11);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[12], 12);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[13], 13);
    EXPECT_EQ(asm_parser->parser.port_metadata[0].data[14], 14);
      // 1
    EXPECT_EQ(asm_parser->parser.port_metadata[1].data[0], 255);
    // parser ingress > profile 0
      // 8bit port_info = {2'b0, logic_port#(6b)}
    EXPECT_EQ(asm_parser->parser.profiles[1].match.port.word0 & 0x3f, 0x3f);
    EXPECT_EQ(asm_parser->parser.profiles[1].match.port.word1 & 0x3f, 0x3f);
    EXPECT_EQ(asm_parser->parser.profiles[1].match.inband_metadata.word0, 0xff0000ffffffffffULL);
    EXPECT_EQ(asm_parser->parser.profiles[1].match.inband_metadata.word1, 0xffffff00ffffffffULL);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[0], 0x01);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[1], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[2], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[3], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[4], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[5], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[6], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[7], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[8], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_state[9], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[0], 0x77);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[1], 0x66);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[2], 0x55);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[3], 0x44);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[4], 0x33);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[5], 0x22);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[6], 0x11);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_flags[7], 0x00);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_ptr, 12);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_w0_offset, 0);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_w1_offset, 1);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_w2_offset, 2);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu0_instruction.opcode,
        FlatrockParser::alu0_instruction::OPCODE_0);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu0_instruction.opcode_0_1.add_imm8s, -3);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode,
        FlatrockParser::alu1_instruction::OPCODE_0);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.state_msb, 15);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.state_lsb, 8);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.shift_imm4u, 7);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[0].type,
        FlatrockParser::metadata_select::CONSTANT);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[0].constant.value, 1);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[1].type,
        FlatrockParser::metadata_select::LOGICAL_PORT_NUMBER);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[2].type,
        FlatrockParser::metadata_select::PORT_METADATA);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[2].port_metadata.index, 1);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[3].type,
        FlatrockParser::metadata_select::INBAND_METADATA);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[3].inband_metadata.index, 2);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[4].type,
        FlatrockParser::metadata_select::TIMESTAMP);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[4].timestamp.index, 3);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[5].type,
        FlatrockParser::metadata_select::COUNTER);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[5].counter.index, 4);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[6].type,
        FlatrockParser::metadata_select::INVALID);

    delete ::asm_parser;
    ::asm_parser = nullptr;
}

TEST(flatrock_parser, section_parser_egress) {
    const char* parser_str = R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    md32: 0
    ethernet: 1
    ipv4: 2
    ipv6: 3
    tcp: 4
    udp: 5
  seq:
    0: [ 1, 2, 4 ]  # ethernet, ipv4, tcp
    1: [ ethernet, ipv4, udp ]
  seq_pos: 2
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
  len_pos: 4
  off_pos: 6
parser egress:
  pov_flags_pos: 10
  pov_state_pos: 20
)PARSER_CFG";

    options.target = NO_TARGET;
    Hdr::test_clear();

    asm_parse_string(parser_str);
    auto *asm_parser = dynamic_cast<FlatrockAsmParser *>(::asm_parser);

    // hdr > seq_pos
    EXPECT_EQ(Hdr::hdr.seq_pos, 2);
    // hdr > len_pos
    EXPECT_EQ(Hdr::hdr.len_pos, 4);
    // hdr > off_pos
    EXPECT_EQ(Hdr::hdr.off_pos, 6);
    // parser egress > pov_flags_pos
    EXPECT_EQ(asm_parser->pseudo_parser.pov_flags_pos, 10);
    // parser egress > pov_state_pos
    EXPECT_EQ(asm_parser->pseudo_parser.pov_state_pos, 20);

    delete ::asm_parser;
    ::asm_parser = nullptr;
}

}  // namespace
