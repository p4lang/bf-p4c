#include "flatrock/hdr.h"
#include "flatrock/parser.h"
#include "gtest/gtest.h"

#include "register-matcher.h"

namespace BfAsm {

namespace Test {

namespace {

class AsmParserGuard {
 private:
    FlatrockAsmParser *parser;

    void cleanSingletons();

 public:
    AsmParserGuard();
    ~AsmParserGuard();

    /* -- avoid copying */
    AsmParserGuard &operator=(AsmParserGuard &&) = delete;

    FlatrockAsmParser *operator->() { return parser; }

    bool parseString(const char *bfa_string);
    const Target::Flatrock::parser_regs &generateConfig();
};

AsmParserGuard::AsmParserGuard() : parser(nullptr) { cleanSingletons(); }

AsmParserGuard::~AsmParserGuard() {
    cleanSingletons();

    parser = nullptr;
}

void AsmParserGuard::cleanSingletons() {
    if (::asm_parser != nullptr) {
        delete ::asm_parser;
        ::asm_parser = nullptr;
    }
    Hdr::test_clear();
    options.target = NO_TARGET;
    error_count = 0;
    warn_count = 0;
}

bool AsmParserGuard::parseString(const char *bfa_string) {
    if (asm_parse_string(bfa_string) == 0) {
        parser = dynamic_cast<FlatrockAsmParser *>(::asm_parser);
        return true;
    }
    return false;
}

const Target::Flatrock::parser_regs &AsmParserGuard::generateConfig() {
    json::map context_json;
    parser->output(context_json);
    return parser->get_cfg_registers();
}

TEST(flatrock_parser, section_hdr) {
    const char *parser_str = R"PARSER_CFG(
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

    AsmParserGuard parser;
    parser.parseString(parser_str);

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
}

TEST(flatrock_parser, section_parser_ingress) {
    const char *parser_str = R"PARSER_CFG(
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

    AsmParserGuard asm_parser;
    asm_parser.parseString(parser_str);

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
}

TEST(flatrock_parser, section_parser_egress) {
    const char *parser_str = R"PARSER_CFG(
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

    AsmParserGuard asm_parser;
    asm_parser.parseString(parser_str);

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
}

TEST(flatrock_parser, section_analyzer_stage_happy_paths) {
    {
        /* -- valid analyzer stage - all values are defaulted */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 78}
      next_alu1_instruction: {opcode: 1, lsb: 16, msb: 23, shift: 4}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* -- by default the rule matches everything */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wh, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "32xffffffff");

        /* -- next W offset must be zero and the extraction must be skipped */
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "");

        /* -- next state and mask must be all zero (zero mask means passing
         *    current value) */
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "");

        /* -- next ALU operations must be set */
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b11 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x10 | len: 2b10 | imm: 8x4");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        /* -- no header should be pushed (zero register) */
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id, "");
    }

    {
        /* -- valid analyzer stage - next state is 80-bits match mask */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0x********_ff****7c
      match_w0: 0x1234
      match_w1: 0xabcd
      next_state: {lo: 0x11**22**_33**44**, hi: 0xa**b}
      next_skip_extractions: true
      next_w0_offset: 0xab
      next_w1_offset: 0xcd
      next_w2_offset: 0xef
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 78}
      next_alu1_instruction: {opcode: 1, lsb: 16, msb: 23, shift: 4}
      push_hdr_id: {hdr: 0xaa, offset: 0x7c}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "~8xff | 16xffff | ~8x7c");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "8xff | 16xffff | 8x7c");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "32xffffffff");
        EXPECT_REGISTER(
            regs.prsr_mem.parser_key_w.key_w[0][0].key_wh,
            "w1: ~16xabcd | w0: ~16x1234");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "w1: 16xabcd | w0: 16x1234");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "8xab");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "8xcd");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "8xef");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "16xa00b");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "32x11002200");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "32x33004400");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "16xf00f");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "32xff00ff00");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "32xff00ff00");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b11 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x10 | len: 2b10 | imm: 8x4");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id,
                        "vld: 1x1 | hdr_id: 8xaa | off: 8x7c");
    }

    {
        /* -- valid analyzer stage - next state is 64-bits match mask */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0xff01107c
      match_w0: 0x8**8
      match_w1: 0x*4*6
      next_state: 0x**11**22_**33**44
      next_skip_extractions: false
      next_w0_offset: 0x55
      next_w1_offset: 0x66
      next_w2_offset: 0x77
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x12, offset: 0x10}
)PARSER_CFG"));
        const auto &regs(asm_parser.generateConfig());

        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "~32xff01107c");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "32xff01107c");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "32x00000000");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wh,
                        "w1: 4xff | ~4x4 | 4xff | ~4x6 | w0: ~4x8 | 8xff | ~4x8");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl,
                        "w1: 4xff | 4x4 | 4xff | 4x6 | w0: 4x8 | 8xff | 4x8");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "8x55");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "8x66");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "8x77");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "16x0");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "32x00110022");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "32x00330044");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "16x0000");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "32x00ff00ff");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "32x00ff00ff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id,
                        "vld: 1x1 | hdr_id: 8x12 | off: 8x10");
    }

    {
        /* -- valid analyzer stage - next_state is bigint */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0xffeeddcc_11223344
      match_w0: 0xfedc
      match_w1: 0x8765
      next_state: 0xfedc_11223344_55667788
      next_skip_extractions: true
      next_w0_offset: 0x00
      next_w1_offset: 0x02
      next_w2_offset: 0x04
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x12, offset: 0x10}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "~32x11223344");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "32x11223344");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "~32xffeeddcc");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "32xffeeddcc");
        EXPECT_REGISTER(
            regs.prsr_mem.parser_key_w.key_w[0][0].key_wh, "w1: ~16x8765 | w0: ~16xfedc");
        EXPECT_REGISTER(
            regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "w1: 16x8765 | w0: 16xfedc");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "8x00");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "8x02");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "8x04");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "16xfedc");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "32x11223344");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "32x55667788");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "16xffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "32xffffffff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id,
                        "vld: 1x1 | hdr_id: 8x12 | off: 8x10");
    }

    {
        /* -- valid analyzer stage - next_state is small int */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0xffeeddcc_11223344
      match_w0: 0xfedc
      match_w1: 0x8765
      next_state: 0x02
      next_skip_extractions: true
      next_w0_offset: 0x00
      next_w1_offset: 0x02
      next_w2_offset: 0x04
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x12, offset: 0x10}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "~32x11223344");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "32x11223344");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "~32xffeeddcc");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "32xffeeddcc");
        EXPECT_REGISTER(
            regs.prsr_mem.parser_key_w.key_w[0][0].key_wh, "w1: ~16x8765 | w0: ~16xfedc");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "w1: 16x8765 | w0: 16xfedc");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "8x00");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "8x02");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "8x04");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "16x0");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "32x0");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "32x2");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "16xffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "32xffffffff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id,
                        "vld: 1x1 | hdr_id: 8x12 | off: 8x10");
    }

    {
        /* -- valid analyzer stage - header and state resolving */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    ether: 0x28
    ipv4: 0x75
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  analyzer_stage 0 ethernet_hdr:
    rule 0:
      match_w0: 0xfedc
      match_w1: 0x8765
      next_state: ipv4_hdr
      next_skip_extractions: true
      next_w0_offset: 0x00
      next_w1_offset: 0x02
      next_w2_offset: 0x04
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: ether, offset: 0x2f}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "24xffffff | ~8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "24xffffff | 8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "~8xff | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "8xff | 24xffffff");
        EXPECT_REGISTER(
            regs.prsr_mem.parser_key_w.key_w[0][0].key_wh, "w1: ~16x8765 | w0: ~16xfedc");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "w1: 16x8765 | w0: 16xfedc");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "8x00");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "8x02");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "8x04");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "16x0000");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "32x7f000000");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "32x00000002");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "16x0000");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "32xff000000");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "32x000000ff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id,
                        "vld: 1x1 | hdr_id: 8x28 | off: 8x2f");
    }

    {
        /* -- valid analyzer stage - couple of rules, couple of stages */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  analyzer_stage 1 ethernet_hdr:
    rule 1:
      match_w0: 0xfedc
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
    rule 2:
      match_w1: 0x***4
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
  analyzer_stage 2:
    rule 0:
      match_state: ipv4_hdr
      match_w0: 0x1234
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
    rule 2:
      match_w1: 0x5678
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* -- stage 0, rule 0 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wh_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][0].key_wl_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][0].key_wl, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][0].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][0].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][0].next_op1_1, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][0].push_hdr_id, "");

        /* -- stage 0, rule 1 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][1].key_wh_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][1].key_wl_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][1].key_wh_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][1].key_wl_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][1].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][1].key_wl, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][1].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][1].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][1].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][1].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][1].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][1].next_op0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][1].next_op1_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][1].next_op1_1, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][1].push_hdr_id, "");

        /* -- stage 0, rule 2 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][2].key_wh_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][2].key_wl_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][2].key_wh_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[0][2].key_wl_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][2].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[0][2].key_wl, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][2].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][2].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][2].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[0][2].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[0][2].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][2].next_op0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][2].next_op1_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[0][2].next_op1_1, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[0][2].push_hdr_id, "");

        /* -- stage 1, rule 0 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][0].key_wh_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][0].key_wl_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][0].key_wh_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][0].key_wl_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][0].key_wl, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][0].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][0].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][0].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][0].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][0].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][0].next_op0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][0].next_op1_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][0].next_op1_1, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[1][0].push_hdr_id, "");

        /* -- stage 1, rule 1 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][1].key_wh_0, "24xffffff | ~8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][1].key_wl_0, "24xffffff | 8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][1].key_wh_1, "~8xff | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][1].key_wl_1, "8xff | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][1].key_wh, "16xffff | ~16xfedc");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][1].key_wl, "16xffff | 16xfedc");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][1].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][1].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][1].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][1].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][1].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][1].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][1].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][1].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[1][1].push_hdr_id, "");

        /* -- stage 1, rule 2 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][2].key_wh_0, "24xffffff | ~8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][2].key_wl_0, "24xffffff | 8x01");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][2].key_wh_1, "~8xff | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[1][2].key_wl_1, "8xff | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][2].key_wh, "12xfff | ~4x4 | 16xffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[1][2].key_wl, "12xfff | 4x4 | 16xffff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][2].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][2].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][2].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[1][2].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[1][2].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][2].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][2].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[1][2].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[1][2].push_hdr_id, "");

        /* -- stage 2, rule 0 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][0].key_wh_0, "24xffffff | ~8x02");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][0].key_wl_0, "24xffffff | 8x02");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][0].key_wh_1, "~8x7f | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][0].key_wl_1, "8x7f | 24xffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][0].key_wh, "16xffff | ~16x1234");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][0].key_wl, "16xffff | 16x1234");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][0].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][0].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][0].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][0].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][0].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][0].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][0].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][0].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[2][0].push_hdr_id, "");

        /* -- stage 2, rule 1 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][1].key_wh_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][1].key_wl_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][1].key_wh_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][1].key_wl_1, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][1].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][1].key_wl, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][1].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][1].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][1].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][1].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][1].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][1].next_op0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][1].next_op1_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][1].next_op1_1, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[2][1].push_hdr_id, "");

        /* -- stage 2, rule 2 */
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][2].key_wh_0, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][2].key_wl_0, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][2].key_wh_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_s.key_s[2][2].key_wl_1, "32xffffffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][2].key_wh, "~16x5678 | 16xffff");
        EXPECT_REGISTER(regs.prsr_mem.parser_key_w.key_w[2][2].key_wl, "16x5678 | 16xffff");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][2].exw_skip, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][2].next_w0_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][2].next_w1_offset, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_w.ana_w[2][2].next_w2_offset, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_val_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_val_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_val_31_0, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_mask_79_64, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_mask_63_32, "");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_s.ana_s[2][2].state_mask_31_0, "");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][2].next_op0,
                        "op: 3x3 | rsvd: 4x0 | len: 2b10 | off: 6b111111");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][2].next_op1_0,
                        "off: 6x0 | len: 2b01 | imm: 8x3");
        EXPECT_REGISTER(regs.prsr_mem.parser_ana_a.ana_a[2][2].next_op1_1, "op: 3x1");

        EXPECT_REGISTER(regs.prsr_mem.parser_ana_ext.ana_ext[2][2].push_hdr_id, "");
    }
}

TEST(flatrock_parser, section_analyzer_stage_errors) {
    {
        /* -- invalid name of the analyzer stage section (state != stage) */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_state 0:
)PARSER_CFG"));
    }

    {
        /* -- missing stage number */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- too many parameters */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0 foo 10:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- too high stage number */
        AsmParserGuard asm_parser;
        std::ostringstream oss;
        oss << R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage )PARSER_CFG";
        oss << Target::Flatrock::PARSER_ANALYZER_STAGES;
        oss << R"PARSER_CFG(:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG";
        ASSERT_FALSE(asm_parser.parseString(oss.str().c_str()));
    }

    {
        /* -- invalid directive inside the stage */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    invalid 0:
)PARSER_CFG"));
    }

    {
        /* -- missing rule ID */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- too many rule parameters */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0 foo:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- invalid rule attribute */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      invalid_attribute: foo
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- invalid state name in the stage directive */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
  analyzer_stage 0 wrong_state_name:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- invalid state name in the match_state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
  analyzer_stage 0:
    rule 0:
      match_state: another_wrong_state_name
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- invalid header name */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: wrong_header_name, offset: 0x10}
)PARSER_CFG"));
    }

    {
        /* -- limit of W0 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w0_offset: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of W0 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w0_offset: 256
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of W1 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w1_offset: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of W1 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w1_offset: 256
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of W2 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w2_offset: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of W2 offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    awesome_hdr: 0x58
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_w2_offset: 256
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0x1_00000000_00000000
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_state: 0x*_********_********
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W0 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w0: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W0 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w0: 0x10000
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W0 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w0: 0x*****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W1 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w1: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W1 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w1: 0x10000
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of the match W1 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w1: 0x*****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- missing ALU0 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- missing ALU1 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
)PARSER_CFG"));
    }

    {
        /* -- limit of the push_hdr_id.hdr */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: -1, offset: 0}
)PARSER_CFG"));
    }

    {
        /* -- limit of the push_hdr_id.hdr */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x100, offset: 0}
)PARSER_CFG"));
    }

    {
        /* -- limit of the push_hdr_id.offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x1, offset: -1}
)PARSER_CFG"));
    }

    {
        /* -- limit of the push_hdr_id.offset */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
      push_hdr_id: {hdr: 0x1, offset: 256}
)PARSER_CFG"));
    }

    {
        /* -- limit of next_state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_state: -1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of next_state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_state: 0x1_0000_00000000_00000000
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- limit of next_state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_state: {lo: 0x********_********, hi: 0x*****}
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- wrong next_skip_extraction */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      next_skip_extractions: 1
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }
}

}  // namespace

} /* -- namespace Test */

} /* -- namespace BfAsm */
