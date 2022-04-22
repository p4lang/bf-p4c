#include "deparser.h"
#include "bfas.h"
#include "gtest/gtest.h"

namespace {

// TEST(deparser, tof5_packet_body_offset_*)
//
// Verify that Flatrock packet body offset values are correctly picked up.
TEST(deparser, tof5_packet_body_offset_1) {
    const char* deparser_str = R"DEPARSER_CFG(
version:
  target: Tofino5
deparser egress:
  dictionary: {}
  packet_body_offset:
    hdr: 254
    offset: 1
    var_off_pos: 2
    var_off_len: 3
)DEPARSER_CFG";

    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->write_config(regs);

    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].hdr, 254);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].offset, 1);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].var_start, 2);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].var_len, 3);
}

TEST(deparser, tof5_packet_body_offset_2) {
    const char* deparser_str = R"DEPARSER_CFG(
version:
  target: Tofino5
hdr:
  map:
    body: 128
deparser egress:
  dictionary: {}
  packet_body_offset:
    hdr: body
    offset: 2
    var_off_pos: 4
    var_off_len: 6
)DEPARSER_CFG";

    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->write_config(regs);

    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].hdr, 128);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].offset, 2);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].var_start, 4);
    EXPECT_EQ(regs.egress.dprsr_phvxb_rspec.pbo_cfg.data[0].var_len, 6);
}

}  // namespace

