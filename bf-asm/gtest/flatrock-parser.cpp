#include <boost/algorithm/string/replace.hpp>
#include "flatrock/hdr.h"
#include "flatrock/parser.h"
#include "bf-p4c/common/flatrock_parser.h"
#include "phv.h"
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

    FlatrockAsmParser *operator->() {
        assert(parser);
        return parser;
    }

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
    Phv::test_clear();
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
    assert(parser);
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
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
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
    // hdr > len
    // IPv4
    EXPECT_EQ(Hdr::hdr.len.at(2).base_len, 20);
    EXPECT_EQ(Hdr::hdr.len.at(2).num_comp_bits, 4);
    EXPECT_EQ(Hdr::hdr.len.at(2).scale, 2);
    // IPv6
    EXPECT_EQ(Hdr::hdr.len.at(3).base_len, 40);
    EXPECT_EQ(Hdr::hdr.len.at(3).num_comp_bits, 7);
    EXPECT_EQ(Hdr::hdr.len.at(3).scale, 3);
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
              Flatrock::alu0_instruction::OPCODE_0);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu0_instruction.opcode_0_1.
        add_imm8s, -3);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode,
              Flatrock::alu1_instruction::OPCODE_0);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.
        state_msb, 15);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.
        state_lsb, 8);
    EXPECT_EQ(asm_parser->parser.profiles[1].initial_alu1_instruction.opcode_0_1.
        shift_imm4u, 7);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[0].type,
              Flatrock::metadata_select::CONSTANT);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[0].constant.value, 1);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[1].type,
              Flatrock::metadata_select::LOGICAL_PORT_NUMBER);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[2].type,
              Flatrock::metadata_select::PORT_METADATA);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[2].port_metadata.index, 1);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[3].type,
              Flatrock::metadata_select::INBAND_METADATA);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[3].inband_metadata.index, 2);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[4].type,
              Flatrock::metadata_select::TIMESTAMP);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[4].timestamp.index, 3);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[5].type,
              Flatrock::metadata_select::COUNTER);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[5].counter.index, 4);
    EXPECT_EQ(asm_parser->parser.profiles[1].metadata_select[6].type,
              Flatrock::metadata_select::INVALID);
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
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
parser egress:
  pov_flags_pos: 10
  pov_state_pos: 20
)PARSER_CFG";

    AsmParserGuard asm_parser;
    asm_parser.parseString(parser_str);

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
      match_w0: 0x****
      match_w1: 0x****
      match_state: 0x****************
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 78}
      next_alu1_instruction: {opcode: 1, lsb: 16, msb: 23, shift: 4}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* -- match attributes must be set */
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
      match_w1: 0x****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
    rule 2:
      match_w0: 0x****
      match_w1: 0x***4
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
  analyzer_stage 2:
    rule 0:
      match_state: ipv4_hdr
      match_w0: 0x1234
      match_w1: 0x****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
    rule 2:
      match_state: 0x****************
      match_w0: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_w0: 0x****
      match_w1: 0x****
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
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_w0: 0x****
      match_w1: 0x****
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
      match_w0: 0x****
      match_w1: 0x****
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
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w1: 0x****
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
      match_state: 0x****************
      match_w1: 0x****
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
      match_state: 0x****************
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
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
      match_state: 0x****************
      match_w0: 0x****
      match_w1: 0x****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- missing match_w0 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w1: 0x****
      match_state: 0x**************00
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- missing match_w1 */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w0: 0x****
      match_state: 0x**************00
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }

    {
        /* -- missing match_state */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  analyzer_stage 0:
    rule 0:
      match_w0: 0x****
      match_w1: 0x****
      next_alu0_instruction: {opcode: 3, lsb: 63, msb: 70}
      next_alu1_instruction: {opcode: 1, lsb: 0, msb: 3, shift: 3}
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_valid) {
    {
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    pov_select: [ flags 7, state 7, flags 0, state 4 ]
    next_tbl_config:
      0xdeadb*ef: 9
      0xcafe: 42
  ghost_initial_predication_vector:
    pov_select: [ state 1, flags 2, flags 3, flags 4 ]
    next_tbl_config:
      0xa5df: 72
parser egress:
  initial_predication_vector:
    pov_select: [state 1, state 2, state 3, flags 7]
    next_tbl_config:
      0xface: 255
)PARSER_CFG"));

        const auto &regs = asm_parser.generateConfig();

        // INGRESS

        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].src  [0], "1x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].start[0], "3x7");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].src  [1], "1x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].start[1], "3x7");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].src  [2], "1x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].start[2], "3x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].src  [3], "1x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[32].start[3], "3x4");
        // 0xdeadb*ef: 9
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[0][0].key_wh, "~32xdeadb0ef");
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[0][0].key_wl,  "32xdeadbfef");
        EXPECT_REGISTER(regs.prsr.pred_info_ram[0].pred_info[0].next_tbl, "8x9");
        // 0xcafe: 42
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[0][1].key_wh, "~32x0000cafe");
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[0][1].key_wl,      "32xcafe");
        EXPECT_REGISTER(regs.prsr.pred_info_ram[0].pred_info[1].next_tbl, "8x2A");

        // GHOST

        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].src  [0], "1x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].start[0], "3x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].src  [1], "1x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].start[1], "3x2");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].src  [2], "1x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].start[2], "3x3");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].src  [3], "1x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[33].start[3], "3x4");
        // 0xa5df: 72
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[1][0].key_wh, "~32x0000a5df");
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[1][0].key_wl,      "32xa5df");
        EXPECT_REGISTER(regs.prsr.pred_info_ram[1].pred_info[0].next_tbl, "8x48");

        // EGRESS (pseudo parser)

        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].src  [0], "1x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].start[0], "3x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].src  [1], "1x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].start[1], "3x2");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].src  [2], "1x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].start[2], "3x3");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].src  [3], "1x0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[32].start[3], "3x7");
        // 0xface: 255
        EXPECT_REGISTER(regs.pprsr_mem.pred_vec_tcam.pred_tcam[0].key_wh, "~32x0000face");
        EXPECT_REGISTER(regs.pprsr_mem.pred_vec_tcam.pred_tcam[0].key_wl,      "32xface");
        EXPECT_REGISTER(regs.pprsr.pred_info_ram.pred_info[0].next_tbl, "8xff");
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_valid_pov_select_empty) {
    {
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  ghost_initial_predication_vector:
    pov_select: []
    next_tbl_config:
      *: 42
)PARSER_CFG"));
        const auto &regs = asm_parser.generateConfig();
        // 0xcafe: 42
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[1][0].key_wh, "~32x00000000");
        EXPECT_REGISTER(regs.prsr_mem.pred_vec_tcam.pred_tcam[1][0].key_wl, "~32x00000000");
        EXPECT_REGISTER(regs.prsr.pred_info_ram[1].pred_info[0].next_tbl, "8x2A");
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_too_many_pov_selects) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    pov_select: [ flags 7, state 7, flags 0, state 4, state 1 ]
    next_tbl_config:
      0xdeadb*ef: 9
      0xcafe: 42
  ghost_initial_predication_vector:
    pov_select: [ state 1, flags 2, flags 3, flags 4 ]
    next_tbl_config:
      0xa5df: 72
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_pov_select_missing) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    next_tbl_config:
      0xcafe: 42
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_all_keys_missing) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
  ghost_initial_predication_vector:
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_next_tbl_wrong_type) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    pov_select: [flags 1]
    next_tbl_config: [1, 2, 3, 4]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_match_constant_too_wide) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    pov_select: [state 3]
    next_tbl_config:
      0xd*adbeef1: 42
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_next_tbl_too_wide) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector:
    pov_select: [state 6]
    next_tbl_config:
      0xdeadbeef: 0xcafe
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_key_is_cmd) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  initial_predication_vector 1:
    pov_select: [state 6]
    next_tbl_config:
      0xdeadbeef: 42
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_ghost_key_is_cmd) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  states:
    ethernet_hdr: 0xff******_******01
    ipv4_hdr: 0x7f******_******02
  ghost_initial_predication_vector 1:
    pov_select: [state 6]
    next_tbl_config:
      0xdeadbeef: 42
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_ipv_error_pov_select_after_table_config) {
    {
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  ghost_initial_predication_vector:
    next_tbl_config:
      0xdeadbeef: 42
    pov_select: [state 6]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_valid) {
    {
        /* -- the simplest case (parser), only pov_select key is set,
         *    the rest is at defaults */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[0], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[1], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[2], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[3], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[0], "3x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[1], "3x2");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[2], "3x3");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[3], "3x4");
    }

    {
        /* -- the simplest case (pseudo parser), only pov_select key is set,
         *    the rest is at defaults */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[0], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[1], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[2], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[3], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[0], "3x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[1], "3x2");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[2], "3x3");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[3], "3x4");
    }

    {
        /* -- complex case:
         *    - both parser and pseudo parser
         *    - all types of PHV builder groups: PHE8 (0-15), PHE16 (16-23), PHE32(24-31)
         *    - other and packet8, packet16, packet32 PHE sources */
        AsmParserGuard asm_parser;
        ASSERT_TRUE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
    bar: 0x43
    baz: 0x44
    foobar: 0x45
    foobaz: 0x46
    efoo: 0x52
    ebar: 0x53
    ebaz: 0x54
    efoobar: 0x55
    efoobaz: 0x56
parser ingress:
  phv_builder_group 0:
    pov_select: [flags 0, state 5, flags 7, state 0]
    extract 1:
      source:
        - {B2: constant 0xab, B3: none, B0: pov_flags 5}
    extract 2:
      match: 0x01****23
  phv_builder_group 15:
    pov_select: [flags 1, state 2, state 3, flags 4]
    extract 1:
      match: 0x45**67**
      source:
        - {}
        - {B124: pov_state 2, B125: checksum_and_error, B127: ghost 5}
    extract 2:
      match: 0x89****ab
      source:
        - {B120: udf0 0, B121: udf1 1, B122: udf2 2, B123: udf3 3}
        - packet8 foo [B125 offset 0x11, B126 offset 0x12]
  phv_builder_group 16:
    pov_select: [state 1, flags 1, state 2, flags 2]
    extract 1:
      match: 0x123456**
      source:
        - {H0(8..15): pov_state 4, H1(0..7): constant 0x56, H0(0..7): udf1 3, H1(8..15): ghost 2}
        - packet16 bar [H3 msb_offset 0x33, H2 msb_offset 0x22 swap]
  phv_builder_group 24:
    pov_select: [flags 3, state 3, flags 4, state 4]
    extract 1:
      match: 0x**345678
      source:
        - packet32 baz W0 msb_offset 0x11
        - packet32 foobar W1 msb_offset 0x12 reverse
    extract 2:
      match: 0x**34**78
      source:
        - packet32 foobaz W0 msb_offset 0x13 reverse_16b_words
        - {W1(0..7): pov_flags 1, W1(8..15): constant 0x78, W1(16..23): udf3 5, W1(24..31): ghost 3}
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, flags 2, flags 3, state 4]
    extract 1:
      source:
        - {B0: constant 0xcd, B1: none, B2: pov_flags 1}
    extract 2:
      match: 0x******45
  phv_builder_group 15:
    pov_select: [state 0, flags 5, state 6, flags 7]
    extract 1:
      match: 0x**aa**bb
      source:
        - {B120: pov_state 3, B121: tm 0x11, B123: bridge 0x13}
        - packet8 efoo [B124 offset 0x24, B127 offset 0x27]
  phv_builder_group 16:
    pov_select: [flags 5, flags 6, flags 7, state 0]
    extract 1:
      match: 0xccdd****
      source:
        - {H0(0..7): tm 0x1a, H1(0..7): bridge 0x1b, H1(8..15): constant 0xde, H0(8..15): pov_state 2}
        - packet16 ebar [H2 msb_offset 0xab, H3 msb_offset 0xcd swap]
  phv_builder_group 24:
    pov_select: [state 7, state 6, state 5, flags 0]
    extract 1:
      match: 0x**abcdef
      source:
        - packet32 ebaz W0 msb_offset 0x8a reverse_16b_words
        - packet32 efoobar W1 msb_offset 0x9b
    extract 2:
      match: 0x5a****6b
      source:
        - packet32 efoobaz W0 msb_offset 0x2d reverse
        - {W1(0..7): pov_state 5, W1(8..15): bridge 0x12, W1(16..23): tm 0x15, W1(24..31): constant 0xfa}
)PARSER_CFG"));

        const auto &regs(asm_parser.generateConfig());

        /* ---- PARSER (ingress) ---- */

        /* -- PHV builder group 0 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[0], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[1], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[2], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].src[3], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[0], "3x0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[1], "3x5");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[2], "3x7");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[0].start[3], "3x0");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][0].type1_field[4], "");
        /* -- TCAM 1 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][1].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][1].key_wl, "");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0_field[4],
                "none: 2b00 | constant: 2b00 | none: 2b00 | pov_flags: 2b01");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0_field[3],
                "POV: 1b0 | reserved: 3b000 | flags: 1b0 | value: 3x5");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0_field[1],
                "8xab");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][1].type1_field[4], "");
        /* -- TCAM 2 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][2].key_wh, "~8x01 | 16xffff | ~8x23");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[0][2].key_wl,  "8x01 | 16xffff |  8x23");
        /* -- SRAM 2 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[0][2].type1_field[4], "");

        /* -- PHV builder group 15 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].src[0], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].src[1], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].src[2], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].src[3], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].start[0], "3x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].start[1], "3x2");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].start[2], "3x3");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[15].start[3], "3x4");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][1].key_wh,
                "~8x45 | 8xff | ~8x67 | 8xff");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][1].key_wl,
                 "8x45 | 8xff |  8x67 | 8xff");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1_field[4],
                "ghost: 2b11 | none: 2b00 | checksum_and_error: 2b01 | pov_state: 2b01");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1_field[3],
                "POV: 1b0 | reserved: 3b000 | state: 1b1 | value: 3x2");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1_field[2],
                "CSUM: 1b1 | reserved: 7b0000000");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][1].type1_field[0],
                "reserved: 5b00000 | value: 3x5");
        /* -- TCAM 2 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][2].key_wh, "~8x89 | 16xffff | ~8xab");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[15][2].key_wl,  "8x89 | 16xffff |  8xab");
        /* -- SRAM 2 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0_field[4],
                "udf3: 2b10 | udf2: 2b10 | udf1: 2b10 | udf0: 2b10");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0_field[3],
                "udf: 2b00 | reserved: 3b000 | value: 3x0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0_field[2],
                "udf: 2b01 | reserved: 3b000 | value: 3x1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0_field[1],
                "udf: 2b10 | reserved: 3b000 | value: 3x2");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type0_field[0],
                "udf: 2b11 | reserved: 3b000 | value: 3x3");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1_field[4],
                "8x42");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1_field[2],
                "8x11");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1_field[1],
                "8x12");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[15][2].type1_field[0], "");

        /* -- PHV builder group 16 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].src[0], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].src[1], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].src[2], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].src[3], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].start[0], "3x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].start[1], "3x1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].start[2], "3x2");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[16].start[3], "3x2");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[16][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[16][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[16][1].key_wh, "~24x123456 | 8xff");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[16][1].key_wl,  "24x123456 | 8xff");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0_field[4],
                "ghost: 2b11 | constant: 2b00 | pov_state: 2b01 | udf1: 2b10");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0_field[3],
                "udf: 2b01 | reserved: 3b000 | value: 3x3");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0_field[2],
                "POV: 1b0 | reserved: 3b000 | state: 1b1 | value: 3x4");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0_field[1],
                "8x56");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type0_field[0],
                "reserved: 5b00000 | value: 3x2");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1_field[4],
                "8x43");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1_field[3],
                "8x22");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1_field[2],
                "reserved: 7b0000000 | swap: 1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1_field[1],
                "8x33");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[16][1].type1_field[0],
                "reserved: 7b0000000 | swap: 1b0");

        /* -- PHV builder group 24 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].src[0], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].src[1], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].src[2], "1b0");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].src[3], "1b1");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].start[0], "3x3");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].start[1], "3x3");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].start[2], "3x4");
        EXPECT_REGISTER(regs.prsr.pov_keys_ext.pov_key_ext[24].start[3], "3x4");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][0].key_wh, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type0_field[4], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1, "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1_field[3], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][1].key_wh, "8xff | ~24x345678");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][1].key_wl, "8xff |  24x345678");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0_field[4],
                "8x44");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0_field[3],
                "8x11");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0_field[2], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1_field[4],
                "8x45");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1_field[3],
                "8x12");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1_field[2],
                "reserved: 6b000000 | reverse: 2b10");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][1].type1_field[0], "");
        /* -- TCAM 2 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][2].key_wh,
                "8xff | ~8x34 | 8xff | ~8x78");
        EXPECT_REGISTER(regs.prsr_mem.phv_tcam.phv_tcam[24][2].key_wl,
                "8xff |  8x34 | 8xff |  8x78");
        /* -- SRAM 2 is set */
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0, "1b0");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0_field[4],
                "8x46");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0_field[3],
                "8x13");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0_field[2],
                "reserved: 6b000000 | reverse_16b_words: 2b01");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0_field[1], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type0_field[0], "");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1, "1b1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1_field[4],
                "ghost: 2b11 | udf3: 2b10 | constant: 2b00 | pov_flags: 2b01");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1_field[3],
                "POV: 1b0 | reserved: 3b000 | flags: 1b0 | value: 3x1");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1_field[2],
                "8x78");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1_field[1],
                "udf: 2b11 | reserved: 3b000 | value: 3x5");
        EXPECT_REGISTER(regs.prsr_mem.phv_action_ram.iphv_action_mem16[24][2].type1_field[0],
                "reserved: 5b00000 | value: 3x3");


        /* ---- PSEUDO PARSER (egress) ---- */

        /* -- PHV builder group 0 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[0], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[1], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[2], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].src[3], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[0], "3x1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[1], "3x2");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[2], "3x3");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[0].start[3], "3x4");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][0].key_wh, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type0_field[4], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][0].type1_field[4], "");
        /* -- TCAM 1 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][1].key_wh, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][1].key_wl, "");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0, "1b1");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0_field[4],
                "none: 2b00 | pov_flags: 2b01 | none: 2b00 | constant: 2b00");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0_field[3],
                "8xcd");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0_field[1],
                "POV: 1b0 | reserved: 3b000 | flags: 1b0 | value: 3x1");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][1].type1_field[4], "");
        /* -- TCAM 2 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][2].key_wh, "24xffffff | ~8x45");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[0][2].key_wl, "24xffffff |  8x45");
        /* -- SRAM 2 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type0_field[4], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[0][2].type1_field[4], "");

        /* -- PHV builder group 15 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].src[0], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].src[1], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].src[2], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].src[3], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].start[0], "3x0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].start[1], "3x5");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].start[2], "3x6");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[15].start[3], "3x7");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[15][0].key_wh, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[15][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type0_field[4], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[15][1].key_wh,
                "8xff | ~8xaa | 8xff | ~8xbb");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[15][1].key_wl,
                "8xff |  8xaa | 8xff |  8xbb");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0, "1b1");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0_field[4],
                "bridge: 2b11 | none: 2b00 | tm: 2b10 | pov_state: 2b01");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0_field[3],
                "POV: 1b0 | reserved: 3b000 | state: 1b1 | value: 3x3");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0_field[2],
                "reserved: 3b000 | tm: 5x11");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type0_field[0],
                "reserved: 2b00 | bridge: 6x13");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1, "1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1_field[4],
                "8x52");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1_field[3],
                "8x24");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[15][1].type1_field[0],
                "8x27");

        /* -- PHV builder group 16 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].src[0], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].src[1], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].src[2], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].src[3], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].start[0], "3x5");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].start[1], "3x6");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].start[2], "3x7");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[16].start[3], "3x0");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[16][0].key_wh, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[16][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type0_field[4], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[16][1].key_wh, "~16xccdd | 16xffff");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[16][1].key_wl,  "16xccdd | 16xffff");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0, "1b1");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0_field[4],
                "constant: 2b00 | bridge: 2b11 | pov_state: 2b01 | tm: 2b10");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0_field[3],
                "reserved: 3b000 | tm: 5x1a");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0_field[2],
                "POV: 1b0 | reserved: 3b000 | state: 1b1 | value: 3x2");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0_field[1],
                "reserved: 2b00 | bridge: 6x1b");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type0_field[0],
                "8xde");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1, "1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1_field[4],
                "8x53");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1_field[3],
                "8xab");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1_field[2],
                "reserved: 7b0000000 | swap: 1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1_field[1],
                "8xcd");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[16][1].type1_field[0],
                "reserved: 7b0000000 | swap: 1b1");

        /* -- PHV builder group 24 */
        /* -- POV key bytes selection is set */
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].src[0], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].src[1], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].src[2], "1b1");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].src[3], "1b0");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].start[0], "3x7");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].start[1], "3x6");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].start[2], "3x5");
        EXPECT_REGISTER(regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[24].start[3], "3x0");
        /* -- TCAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][0].key_wh, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][0].key_wl, "");
        /* -- SRAM 0 not set, at defaults */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type0_field[4], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1, "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1_field[3], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][0].type1_field[4], "");
        /* -- TCAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][1].key_wh, "8xff | ~24xabcdef");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][1].key_wl, "8xff |  24xabcdef");
        /* -- SRAM 1 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0, "1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0_field[4],
                "8x54");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0_field[3],
                "8x8a");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0_field[2],
                "reserved: 6b000000 | reverse_16b_words: 2b01");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1, "1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1_field[4],
                "8x55");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1_field[3],
                "8x9b");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1_field[2], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][1].type1_field[0], "");
        /* -- TCAM 2 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][2].key_wh,
                "~8x5a | 16xffff | ~8x6b");
        EXPECT_REGISTER(regs.pprsr_mem.phv_tcam.phv_tcam[24][2].key_wl,
                 "8x5a | 16xffff |  8x6b");
        /* -- SRAM 2 is set */
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0, "1b0");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0_field[4],
                "8x56");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0_field[3],
                "8x2d");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0_field[2],
                "reserved: 6b000000 | reverse: 2b10");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0_field[1], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type0_field[0], "");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1, "1b1");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1_field[4],
                "constant: 2b00 | tm: 2b10 | bridge: 2b11 | pov_state: 2b01");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1_field[3],
                "POV: 1b0 | reserved: 3b000 | state: 1b1 | value: 3x5");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1_field[2],
                "reserved: 2b00 | bridge: 6x12");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1_field[1],
                "reserved: 3b000 | tm: 5x15");
        EXPECT_REGISTER(regs.pprsr_mem.phv_action_ram.ephv_action_mem16[24][2].type1_field[0],
                "8xfa");
    }
}

TEST(flatrock_parser, section_phv_builder_group_invalid) {
    {
        /* -- missing PHV builder group number */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group:
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- too many parameters */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 1 2:
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- PHV builder group number is too big */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 32:
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- redefinition of the same PHV builder group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3, state 4]
  phv_builder_group 31:
    pov_select: [state 0, state 1, state 2, state 3]
)PARSER_CFG"));
    }

    {
        /* -- value is not map */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31: 1
)PARSER_CFG"));
    }

    {
        /* -- invalid directive inside phv_builder_group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3, state 4]
    foo:
)PARSER_CFG"));
    }

    {
        /* -- invalid type of key used inside phv_builder_group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    5: 1
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_pov_select_invalid) {
    {
        /* -- use of pov_select with parameter */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select 1: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- use of pov_select with value other than vector */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: 1
)PARSER_CFG"));
    }

    {
        /* -- too many values for pov_select */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3, state 4, state 5]
)PARSER_CFG"));
    }

    {
        /* -- invalid type of value for pov_select */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, foo 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- out of range value (greater than allowed) for pov_select */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 8, state 4]
)PARSER_CFG"));
    }

    {
        /* -- out of range value (less than allowed) for pov_select */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state -1, state 3, state 4]
)PARSER_CFG"));
    }

    {
        /* -- missing mandatory pov_select */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
)PARSER_CFG"));
    }

    {
        /* -- pov_select used multiple times */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3, state 4]
    pov_select: [state 1, state 2, state 3, state 4]
)PARSER_CFG"));
    }

    {
      /* -- pov_select after extract */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 24:
    extract 1:
      match: 0x**345678
      source:
        - packet32 baz W0 msb_offset 0x11
        - packet32 foobar W1 msb_offset 0x12 reverse
    pov_select: [flags 3, state 3, flags 4, state 4]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_extract_invalid) {
    {
        /* -- missing extract index */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract:
      match: 0x******01
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- too many parameters for extract */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1 2:
      match: 0x******01
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- extract number out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 16:
      match: 0x******01
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- redefinition of the same extract */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {}
    extract 1:
      match: 0x******02
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- value for extract is not map */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1: 5
)PARSER_CFG"));
    }

    {
        /* -- invalid extract directive */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {}
      foo: 1
)PARSER_CFG"));
    }

    {
        /* -- invalid extract match constant type */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: foo
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- match constant references unused POV byte */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3]
    extract 1:
      match: 0xff******
)PARSER_CFG"));
    }

    {
        /* -- match constant references unused POV byte */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3]
    extract 1:
      match: 0x00******
)PARSER_CFG"));
    }

    {
        /* -- match constant references unused POV byte */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 31:
    pov_select: [state 1, state 2, state 3]
    extract 1:
      match: 0x*1234567
)PARSER_CFG"));
    }

    {
        /* -- invalid extract match constant width */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x********_******01
      source: 
        - {}
)PARSER_CFG"));
    }

    {
        /* -- invalid extract source type */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - packet
)PARSER_CFG"));
    }

    {
        /* -- number of extract source values exceeds allowed value */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {}
        - {}
        - {}
)PARSER_CFG"));
    }

    {
        /* -- invalid type of extract source value (constant) */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - 1
)PARSER_CFG"));
    }

    {
        /* -- invalid type of extract source value (string) */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - packet
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_other_phe_invalid) {
    {
        /* -- number of other values per PHE source exceeds the limit */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: none, B1: none, B2: none, B3: none, B4: none}
)PARSER_CFG"));
    }

    {
        /* -- invalid register name for other value of PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {A1: none}
)PARSER_CFG"));
    }

    {
        /* -- specified register does not match PHV builder group and PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B4: none}
)PARSER_CFG"));
    }

    {
        /* -- specified register slice is not correctly aligned */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {H0(1..8): none}
)PARSER_CFG"));
    }

    {
        /* -- same register can not be used multiple times */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: none, B0: constant 1}
)PARSER_CFG"));
    }

    {
        /* -- invalid other value type (neither operation nor string) */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: 1}
)PARSER_CFG"));
    }

    {
        /* -- invalid other value string (constant should be an operation) */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: constant}
)PARSER_CFG"));
    }

    {
        /* -- checksum_and_error is not valid in pseudo parser (egress) */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: checksum_and_error}
)PARSER_CFG"));
    }

    {
        /* -- too many arguments for other value with parameter */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: constant 1 2}
)PARSER_CFG"));
    }

    {
        /* -- invalid other value type */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: foo 1}
)PARSER_CFG"));
    }

    {
        /* -- invalid other value type */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: 1 constant}
)PARSER_CFG"));
    }

    {
        /* -- constant is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: constant 256}
)PARSER_CFG"));
    }

    {
        /* -- pov_flags is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: pov_flags 0x8}
)PARSER_CFG"));
    }

    {
        /* -- pov_state is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: pov_state 0x8}
)PARSER_CFG"));
    }

    {
        /* -- ghost is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: ghost 0x8}
)PARSER_CFG"));
    }

    {
        /* -- ghost is not valid in pseudo parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: ghost 0x7}
)PARSER_CFG"));
    }

    {
        /* -- udf0 is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf0 0x8}
)PARSER_CFG"));
    }

    {
        /* -- udf0 is not valid in pseudo parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf0 0x7}
)PARSER_CFG"));
    }

    {
        /* -- udf1 is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf1 0x8}
)PARSER_CFG"));
    }

    {
        /* -- udf1 is not valid in pseudo parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf1 0x7}
)PARSER_CFG"));
    }

    {
        /* -- udf2 is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf2 0x8}
)PARSER_CFG"));
    }

    {
        /* -- udf2 is not valid in pseudo parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf2 0x7}
)PARSER_CFG"));
    }

    {
        /* -- udf3 is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf3 0x8}
)PARSER_CFG"));
    }

    {
        /* -- udf3 is not valid in pseudo parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: udf3 0x7}
)PARSER_CFG"));
    }

    {
        /* -- tm is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: tm 0x20}
)PARSER_CFG"));
    }

    {
        /* -- tm is not valid in parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: tm 0x1f}
)PARSER_CFG"));
    }

    {
        /* -- bridge is out of range */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser egress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: bridge 0x40}
)PARSER_CFG"));
    }

    {
        /* -- bridge is not valid in parser */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - {B0: bridge 0x3f}
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_packet8_phe_invalid) {
    {
        /* -- missing argument for packet PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo
)PARSER_CFG"));
    }

    {
        /* -- invalid type of header for packet PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - packet8 {} [B0 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- specified unknown header for packet PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 bar [B0 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- specified out of range header index for packet PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 256 [B0 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- packet8 PHE source used in incorrect PHV builder group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source: 
        - packet8 foo [B0 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- invalid number of arguments for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0 offset 1] bar
)PARSER_CFG"));
    }

    {
        /* -- invalid type of argument for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo B0
)PARSER_CFG"));
    }

    {
        /* -- invalid number of values for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [ B0 offset 1, B1 offset 2, B2 offset 3, B3 offset 4, B4 offset 5 ]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0 offset]
)PARSER_CFG"));
    }

    {
        /* -- incorrect register for specified PHV builder group and packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B4 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- same register used multiple times for specified PHV builder group
         *    and packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0 offset 1, B0 offset 2]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0 offse 1]
)PARSER_CFG"));
    }

    {
        /* -- offset is out of range for packet8 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet8 foo [B0 offset 256]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_packet16_phe_invalid) {
    {
        /* -- packet16 PHE source used in incorrect PHV builder group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1]
)PARSER_CFG"));
    }

    {
        /* -- invalid number of arguments for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1] bar
)PARSER_CFG"));
    }

    {
        /* -- invalid type of argument for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo H0
)PARSER_CFG"));
    }

    {
        /* -- invalid number of values for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1, H1 msb_offset 2, H2 msb_offset3]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1 swap bar]
)PARSER_CFG"));
    }

    {
        /* -- incorrect register for specified PHV builder group and packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H2 msb_offset 1]
)PARSER_CFG"));
    }

    {
        /* -- same register used multiple times for specified PHV builder group
         *    and packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1, H0 msb_offset 2]
)PARSER_CFG"));
    }

    {
        /* -- register slice can not be used for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0(0..7) msb_offset 1]
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 offset 1]
)PARSER_CFG"));
    }

    {
        /* -- offset is out of range for packet16 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 256]
)PARSER_CFG"));
    }

    {
        /* -- incorrect value used instead of swap keyword */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1 1]
)PARSER_CFG"));
    }

    {
        /* -- incorrect value used instead of swap keyword */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 16:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet16 foo [H0 msb_offset 1 swa]
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_phv_builder_group_packet32_phe_invalid) {
    {
        /* -- packet32 PHE source used in incorrect PHV builder group */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 0:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 msb_offset 1
)PARSER_CFG"));
    }

    {
        /* -- invalid number of arguments for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 msb_offset 1 reverse bar
)PARSER_CFG"));
    }

    {
        /* -- incorrect register for specified PHV builder group and packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W1 msb_offset 1
)PARSER_CFG"));
    }

    {
        /* -- register slice can not be used for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0(0..15) msb_offset 1
)PARSER_CFG"));
    }

    {
        /* -- incorrect offset specification for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 offset 1
)PARSER_CFG"));
    }

    {
        /* -- offset is out of range for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 msb_offset 256
)PARSER_CFG"));
    }

    {
        /* -- invalid reverse specification for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 msb_offset 1 1
)PARSER_CFG"));
    }

    {
        /* -- invalid reverse specification for packet32 PHE source */
        AsmParserGuard asm_parser;
        EXPECT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    foo: 0x42
parser ingress:
  phv_builder_group 24:
    pov_select: [state 1, state 2, state 3, state 4]
    extract 1:
      match: 0x******01
      source:
        - packet32 foo W0 msb_offset 1 revers
)PARSER_CFG"));
    }
}

TEST(flatrock_parser, section_checksum_checker) {
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
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
parser ingress:
  checksum_checkers:
    mask 0: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    mask 2: 0x000000000000000000000000000000000000111100000000ffffffff
    mask 1: 0xdabcdcafe0011aabbccdd12345678abba4242acda11420401b3ac
    mask 3: 0x100000020000000000000000000000000000000000000000
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
        match_pov: 0xabcd***1
        mask_sel: 3
        hdr: ipv4
    unit 1:
      pov_select: [ state 7, flags 3, state 2 ]
      config 0:
        match_pov: 0x**1d**bc
        mask_sel: 1
        hdr: tcp
      config 1:
        match_pov: 0x****cd**
        mask_sel: 2
        hdr: 3
)PARSER_CFG";

  AsmParserGuard parser;
  parser.parseString(parser_str);

  const auto &regs = parser.generateConfig();

  // > mask 0
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[0], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[1], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[2], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[3], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[4], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[5], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[0].en32[6], "32xffffffff");

  // > mask 1
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[0], "32x0401b3ac");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[1], "32xacda1142");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[2], "32xabba4242");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[3], "32x12345678");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[4], "32xaabbccdd");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[5], "32xcafe0011");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[1].en32[6], "32x000dabcd");

  // > mask 2
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[0], "32xffffffff");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[1], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[2], "32x00001111");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[3], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[4], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[5], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[2].en32[6], "32x00000000");

  // > mask 3
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[0], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[1], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[2], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[3], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[4], "32x00000000");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[5], "32x10000002");
  EXPECT_REGISTER(regs.prsr.csum_mask.csum_mask[3].en32[6], "32x00000000");

  // > unit 0 > pov_select
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].src[0], "1b0");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].start[0], "3x0");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].src[1], "1b1");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].start[1], "3x1");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].src[2], "1b0");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].start[2], "3x7");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].src[3], "1b1");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[0].start[3], "3x2");

  // > unit 0 > config 0
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[0][0].key_wl, "32xabcdfff1");
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[0][0].key_wh, "~32xabcd0001");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[0].csum_chk[0].csum_mask_sel, "3x3");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[0].csum_chk[0].csum_hdr_id, "8x2");  // ipv4

  // > unit 1 > pov_select
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].src[0], "1b1");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].start[0], "3x7");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].src[1], "1b0");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].start[1], "3x3");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].src[2], "1b1");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].start[2], "3x2");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].src[3], "1b0");
  EXPECT_REGISTER(regs.prsr.csum_key_ext[1].start[3], "3x0");

  // > unit 1 > config 0
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[1][0].key_wl, "32xff1dffbc");
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[1][0].key_wh, "~32x001d00bc");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[1].csum_chk[0].csum_mask_sel, "3x1");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[1].csum_chk[0].csum_hdr_id, "8x4");  // tcp

  // > unit 1 > config 1
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[1][1].key_wl, "32xffffcdff");
  EXPECT_REGISTER(regs.prsr_mem.csum_chk_tcam.csum_tcam[1][1].key_wh, "~32x0000cd00");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[1].csum_chk[1].csum_mask_sel, "3x2");
  EXPECT_REGISTER(regs.prsr.csum_chk_ram[1].csum_chk[1].csum_hdr_id, "8x3");
}

TEST(flatrock_parser, section_checksum_checker_invalid_unit) {
    const char *code = R"PARSER_CFG(
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
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
parser ingress:
  checksum_checkers:
    mask 0: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    mask 2: 0x000000000000000000000000000000000000111100000000ffffffff
    mask 1: 0xdabcdcafe0011aabbccdd12345678abba4242acda11420401b3ac
    %UNIT%
    unit 1:
      pov_select: [ state 7, flags 3, state 2 ]
      config 0:
        match_pov: 0x**1d**bc
        mask_sel: 1
        hdr: tcp
      config 1:
        match_pov: 0x****cd**
        mask_sel: 2
        hdr: 3
)PARSER_CFG";

  std::string str;
  auto with_unit = [&str](const std::string& unit, std::string code) {
      str = code;
      boost::replace_all(str, "%UNIT%", unit);
      return str.c_str();
  };

  {
    /* -- unit index is not from range 0-1 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 5:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- unit index is not from range 0-1 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit -1:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- config index is not from range 0-15 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 16:
          match_pov: 0x**1dacbc
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- config index is not from range 0-15 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config -2:
          match_pov: 0x**1dacbc
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov references unused byte */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0xab1dac**
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov references unused byte */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0xab**ac2*
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov references unused byte */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ state 1, flags 7 ]
      config 0:
          match_pov: 0xab**a***
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov references unused byte */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ state 1 ]
      config 0:
          match_pov: 0x*b******
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov references unused byte */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: []
      config 0:
          match_pov: 0x*b******
          mask_sel: 1
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel references invalid mask */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x*b******
          mask_sel: 4
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel references invalid mask */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x*b******
          mask_sel: -1
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel references invalid mask */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 4
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel references invalid mask */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 3
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel references invalid mask */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: -1
          hdr: tcp
    )", code)));
  }

  {
    /* -- pov_select has too many elements */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2, flags 1 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov is too wide */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbcff
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- hdr specifies invalid header */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: aaa
    )", code)));
  }

  {
    /* -- hdr specifies invalid header */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: 255
    )", code)));
  }

  {
    /* -- hdr specifies invalid header */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: 1200
    )", code)));
  }

  {
    /* -- unit key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0 1:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- unit key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- unit key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit abc:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- config key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0 1:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- config key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config abc:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- config key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0 abc:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov 1: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- mask_sel key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel 1: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- hdr key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr 1: tcp
    )", code)));
  }

  {
    /* -- pov_select key has invalid parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select 1: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- pov_select value has invalid type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: flags 0
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: tcp
    )", code)));
  }

  {
    /* -- hdr value has invalid type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: 0
          hdr: 0x**42**
    )", code)));
  }

  {
    /* -- mask_sel value has invalid type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: 0x**1dacbc
          mask_sel: abc
          hdr: tcp
    )", code)));
  }

  {
    /* -- match_pov value has invalid type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_unit(R"(
    unit 0:
      pov_select: [ flags 0, state 1, flags 7, state 2 ]
      config 0:
          match_pov: hello
          mask_sel: 0
          hdr: tcp
    )", code)));
  }
}

TEST(flatrock_parser, section_checksum_checker_invalid_masks) {
    const char *code = R"PARSER_CFG(
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
  len:
    2: { base_len: 20, num_comp_bits: 4, scale: 2 }  # IPv4: 20B + N * 4B; N < 10
    ipv6: { base_len: 40, num_comp_bits: 7, scale: 3 }  # IPv6: 40B + N * 8B
parser ingress:
  checksum_checkers:
    %MASKS%
    unit 1:
      pov_select: [ state 7, flags 3, state 2 ]
      config 0:
        match_pov: 0x**1d**bc
        mask_sel: 0
        hdr: tcp
      config 1:
        match_pov: 0x****cd**
        mask_sel: 0
        hdr: 3
)PARSER_CFG";

  std::string str;
  auto with_masks = [&str](const std::string& unit, std::string code) {
      str = code;
      boost::replace_all(str, "%MASKS%", unit);
      return str.c_str();
  };

  {
    /* -- mask index is not from range 0-3 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask 4: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }

  {
    /* -- mask index is not from range 0-3 */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask -1: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }

  {
    /* -- mask is too wide */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask 1: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }

  {
    /* -- mask value has incorrect type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask 1: 0x**abc**
    )", code)));
  }

  {
    /* -- mask value has incorrect type */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask 1: hello
    )", code)));
  }

  {
    /* -- mask key has incorrect parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }

  {
    /* -- mask key has incorrect parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask 1 0: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }

  {
    /* -- mask key has incorrect parameters */
    AsmParserGuard parser;
    EXPECT_FALSE(parser.parseString(with_masks(R"(
    mask 0: 0xff
    mask abc: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    )", code)));
  }
}

TEST(flatrock_parser, section_profile_errors) {
    {
        /* -- missing match_port */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  profile 0:
    match_inband_metadata: 0x****************
)PARSER_CFG"));
    }

    {
        /* -- missing match_inband_metadata */
        AsmParserGuard asm_parser;
        ASSERT_FALSE(asm_parser.parseString(R"PARSER_CFG(
version:
  target: Tofino5
parser ingress:
  profile 0:
    match_port: 0o**
)PARSER_CFG"));
    }
}

}  // namespace

} /* -- namespace Test */

} /* -- namespace BfAsm */
