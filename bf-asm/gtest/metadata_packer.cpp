#include "deparser.h"
#include "bfas.h"
#include "gtest/gtest.h"

namespace {

/** Reset all target information
 *
 * This function should be called when switching from one target to another
 * (e.g., Tofino to JBay) in tests to reset state.
 */
void resetTarget() {
    options.target = NO_TARGET;
    Phv::test_clear();
}

// FIXME: These tests are wrong. The code is currently assigning the deparser
// id to the b0_sel/b1_sel fields, but these should be from the POVs.
// Verify that the valid vector is correstly picked up
TEST(metadata_packer, valid_vec_1) {
    const char* deparser_str = R"MDP_CFG(
version:
  target: Tofino5
deparser ingress:
  dictionary: {}
  valid_vec: [B0(0..6), B1]
)MDP_CFG";

    resetTarget();

    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.vld_vec_ext.b1_sel, 0);
    EXPECT_EQ(regs.mdp.vld_vec_ext.b0_sel, 1);
    EXPECT_EQ(regs.mdp.vld_vec_ext.shift_amt, 0);
}

TEST(metadata_packer, valid_vec_2) {
    const char* deparser_str = R"MDP_CFG(
version:
  target: Tofino5
deparser ingress:
  dictionary: {}
  valid_vec: [B2, B3(1..7)]
)MDP_CFG";

    resetTarget();

    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.vld_vec_ext.b1_sel, 2);
    EXPECT_EQ(regs.mdp.vld_vec_ext.b0_sel, 3);
    EXPECT_EQ(regs.mdp.vld_vec_ext.shift_amt, 1);
}

/*
TEST(metadata_packer, valid_vec_3) {
    const char* deparser_str = R"MDP_CFG(
version:
  target: Tofino5
deparser ingress:
  dictionary: {}
  valid_vec: [H0(0..14)]
)MDP_CFG";

    resetTarget();

    asm_parse_string(deparser_str);

    Target::Flatrock::deparser_regs regs;
    Deparser* dprsr = dynamic_cast<Deparser*>(Section::test_get("deparser"));
    dprsr->write_config(regs);

    EXPECT_EQ(regs.mdp.vld_vec_ext.b1_sel, 128);
    EXPECT_EQ(regs.mdp.vld_vec_ext.b0_sel, 129);
    EXPECT_EQ(regs.mdp.vld_vec_ext.shift_amt, 0);
}
*/

}  // namespace

