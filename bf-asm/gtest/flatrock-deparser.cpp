#ifdef HAVE_FLATROCK
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
    dprsr->process();
    dprsr->write_config(regs);

    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].hdr, 254);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].offset, 1);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].var_start, 2);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].var_len, 3);
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
    dprsr->process();
    dprsr->write_config(regs);

    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.key[0].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].hdr, 128);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].offset, 2);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].var_start, 4);
    EXPECT_EQ(regs.dprsr.dprsr_phvxb_rspec.pbo_cfg.data[0].var_len, 6);
}

TEST(deparser, tof5_remaining_bridge_md_vec) {
    const char* deparser_str = R"DEPARSER_CFG(
version:
  target: Tofino5
deparser ingress:
  remaining_bridge_metadata:
    pov_select: []
    config 1:
      match: *
      start: 18
      bytes: [ 3, 2, 1, B0, H0(0..7), H0(8..15), H1, W0(16..23) ]
)DEPARSER_CFG";

    // TODO check the return value
    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->process();
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[1].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[1].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].rem_brm_start, 18);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b0_phv_sel, 3);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b1_phv_sel, 2);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b2_phv_sel, 1);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b3_phv_sel, 0);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b4_phv_sel, 128);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b5_phv_sel, 129);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b6_phv_sel, 130);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b7_phv_sel, 131);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[1].b8_phv_sel, 194);
}

TEST(deparser, tof5_remaining_bridge_md_map) {
    const char* deparser_str = R"DEPARSER_CFG(
version:
  target: Tofino5
deparser ingress:
  remaining_bridge_metadata:
    pov_select: []
    config 2:
      match: *
      start: 18
      bytes: { 0: 3, 1: 2, 2: 1, 3: B0, 4: H0(0..7), 42: H0(8..15), 43: H1, 45: W0(16..23) }
)DEPARSER_CFG";

    // TODO check the return value
    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->process();
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[2].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[2].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].rem_brm_start, 18);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b0_phv_sel, 3);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b1_phv_sel, 2);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b2_phv_sel, 1);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b3_phv_sel, 0);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b4_phv_sel, 128);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b42_phv_sel, 129);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b43_phv_sel, 130);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b44_phv_sel, 131);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[2].b45_phv_sel, 194);
}

TEST(deparser, tof5_remaining_bridge_md_pov) {
    const char* deparser_str = R"DEPARSER_CFG(
version:
  target: Tofino5
deparser ingress:
  pov: [ H0, H1, W0 ]
  remaining_bridge_metadata:
    pov_select: []
    config 0:
      match: *
      start: 18
      bytes: []
)DEPARSER_CFG";

    // TODO check the return value
    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->process();
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.pov_ext.b0_src_iphv_num, 128);  // H0(0..7)
    EXPECT_EQ(regs.mdp.pov_ext.b1_src_iphv_num, 129);  // H0(8..15)
    EXPECT_EQ(regs.mdp.pov_ext.b2_src_iphv_num, 130);  // H1(0..7)
    EXPECT_EQ(regs.mdp.pov_ext.b3_src_iphv_num, 131);  // H1(8..15)
    EXPECT_EQ(regs.mdp.pov_ext.b4_src_iphv_num, 192);  // W0(0..7)
    EXPECT_EQ(regs.mdp.pov_ext.b5_src_iphv_num, 193);  // W0(8..15)
    EXPECT_EQ(regs.mdp.pov_ext.b6_src_iphv_num, 194);  // W0(16..23)
    EXPECT_EQ(regs.mdp.pov_ext.b7_src_iphv_num, 195);  // W0(24..31)

    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[0].key_wh, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp.br_meta_cfg_tcam.tcam[0].key_wl, 0xFFFFFFFF);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].rem_brm_start, 18);
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b30_phv_sel, 128);  // H0(0..7)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b31_phv_sel, 129);  // H0(8..15)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b32_phv_sel, 130);  // H1(0..7)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b33_phv_sel, 131);  // H1(8..15)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b34_phv_sel, 192);  // W0(0..7)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b35_phv_sel, 193);  // W0(8..15)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b36_phv_sel, 194);  // W0(16..23)
    EXPECT_EQ(regs.mdp_mem.rem_brm_ext_ram.rem_brm_ext[0].b37_phv_sel, 195);  // W0(24..31)
}

}  // namespace
#endif  // HAVE_FLATROCK
