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

    createSingleAsmParser();
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
}

}  // namespace
