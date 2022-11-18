#include <initializer_list>
#include "bf-asm/bfas.h"
#include "bf-asm/tables.h"
#include "gtest/gtest.h"
#include <boost/algorithm/string/replace.hpp>
#include "stage.h"
#include "bf-asm/flatrock/instruction.h"
#include "top_level.h"

namespace Flatrock {

struct Operand;
struct PhvWrite;
struct DepositField;
struct Noop;

void set_top_level() {
    new TopLevelRegs<Target::Flatrock::register_type>;
}

void resetTarget() {
    options.target = NO_TARGET;
    TopLevel::all = nullptr;
    set_top_level();
    dynamic_cast<AsmStage*>(Section::test_get("stage"))->reset();
    Phv::test_clear();
}

// Helper class to generate test code
// Be careful with the identation of the %0, yaml is sensitive to it.
class TestCode {
  std::string code = R"(
version:
  target: Tofino5
phv ingress:
  FB0 : B0
  FB1 : B1
  FB2 : B2
  FB3 : B3
  FB4 : B4
  FB5 : B5
  FB6 : B6
  FB7 : B7
  FB8 : B8
  FB9 : B9
  FB10 : B10
  FH0 : H0
  FH1 : H1
  FH2 : H2
  FH3 : H3
  FH4 : H4
  FH5 : H5
  FH6 : H6
  FH7 : H7
  FH8 : H8
phv egress:
deparser ingress:
  zero: B0
deparser egress:
  zero: B0  # deparser requires at least one container to be zero
stage 0 ingress:
  hash_action tbl_common_t5na_test22 0:
    always_run: true
    p4: { name: tbl_common_t5na_test22, hidden: true }
    input_xbar:
      %0%
    gateway:
      name: tbl_common_t5na_test22-gateway
      row: 0
      0x0:  END
      miss:  END
      condition:
        true:  END
        false:  END
    next: []
    instruction: tbl_common_t5na_test22($DEFAULT, $DEFAULT)
    actions:
      common_t5na_test22(0, 1):
      - hit_allowed: { allowed: true }
      - default_action: { allowed: true, is_constant: true }
      - handle: 0x20000001
      - next_table: 0
      %1%
    default_action: common_t5na_test22
)";

 public:
    TestCode() {}
    std::string getCode(const std::initializer_list<const char *>& arguments) {
      int i = 0;
      for (auto insert : arguments) {
          std::ostringstream oss;
          oss << '%' << i++ << '%';
          boost::replace_all(code, oss.str(), insert);
      }
      return code;
    }
};

Target::Flatrock::mau_regs runTest(const std::initializer_list<const char *>& input) {
  resetTarget();
  TestCode code;
  asm_parse_string(code.getCode(input).c_str());
  Section::process_all();

  Target::Flatrock::mau_regs regs;
  auto& stages = AsmStage::stages(INGRESS);
  stages[0].write_regs(regs, false);
  for (auto table : stages[0].tables) {
      table->write_regs(regs); }

  return regs;
}

/// dummy test to ensure the static variables from flatrock/instruction.cpp are
/// initialized in gtestasm
TEST(vliw, linker_workaround) {
    // auto* t = new FakeTable("foo");
    // auto* a = new Table::Actions::Action("bar", 0);
    Flatrock::Noop noop("noop", FLATROCK);
    // dummy call to ensure something in flatrock/instruction.cpp is called, so
    // linker links to it.
    noop.alias("foo");
}

//  General characteristics of FTR instructions:
//
//  1. VLIW ALU only inputs one operand from the action data mux, using the home
//  PHE as the other operand when one is required.
//
//  2. VLIW ALU: set, deposit_field, bitmasked_set, andc, or, load_const.
//
//  3. EALU: two operands, one from xcmp xbar, the other from adb, EALU results
//  are written to adb connected to PHV write.

// Test for VLIW ALU set instruction on 8b container For the 8b ALU's, a set
// instruction is a bitmasked_set with the bitmask configured to modify all
// bits.  A setz instruction is implemented as a set using an immediate constant
// 0.  Only the 8b ALU's support bitmasked_set
TEST(vliw, set_8b) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - set B0, 0x0  # implemented as bitmasked_set with minimum constant 0
      - set B1, 0xFF # implemented as bitmasked_set with maximum constant 255
      - set B8, A0   # implemented as bitmasked_set with operand from adb slot 0 : group 0, byte 0
      - set B9, A1   # implemented as bitmasked_set with operand from adb slot 1 : group 0, byte 1
      - set B10, A2  # implemented as bitmasked_set with operand from adb slot 2 : group 0, byte 2
      - set B11, A3  # implemented as bitmasked_set with operand from adb slot 3 : group 0, byte 3
      - set B12, A4  # implemented as bitmasked_set with operand from adb slot 4 : group 0, byte 4
      - set B13, A5  # implemented as bitmasked_set with operand from adb slot 5 : group 0, byte 5
      - set B14, A6  # implemented as bitmasked_set with operand from adb slot 6 : group 0, byte 6
      - set B15, A7  # implemented as bitmasked_set with operand from adb slot 7 : group 0, byte 7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[0].phvwr_imem8[0], 0xA0100);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[1].phvwr_imem8[0], 0xA01FF);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[8].phvwr_imem8[0], 0xA0000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[9].phvwr_imem8[0], 0xA0001);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[10].phvwr_imem8[0], 0xA0002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[11].phvwr_imem8[0], 0xA0003);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[12].phvwr_imem8[0], 0xA0004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[13].phvwr_imem8[0], 0xA0005);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[14].phvwr_imem8[0], 0xA0006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[15].phvwr_imem8[0], 0xA0007);
}

// Test for VLIW ALU set instruction on 16b container
TEST(vliw, set_16b) {
  auto input = {
    R"(
      xcmp byte: {  0: H0, 16: H1,
                    32: H2, 48: H3,
                    64: H4, 80: H5,
                    96: H6, 112: H7 }
    )",
    R"(
      - set H0, 0x0  # set with constant 0
      - set H1, 15   # set with maximum immediate 15
      - set H2, -16  # set with minimum immediate -16
      - set H8, A0   # set with operand from adb slot 0 : group 0, byte 0,1
      - set H9, A2   # set with operand from adb slot 2 : group 0, byte 2,3
      - set H10, A4  # set with operand from adb slot 4 : group 0, byte 4,5
      - set H11, A6  # set with operand from adb slot 6 : group 0, byte 6,7
      - set H12, A8  # set with operand from adb slot 8 : group 0, byte 8,9
      - set H13, A10  # set with operand from adb slot 10 : group 0, byte 10,11
      - set H14, A12  # set with operand from adb slot 12 : group 0, byte 12,13
      - set H15, A14  # set with operand from adb slot 14 : group 0, byte 14,15
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[0].phvwr_imem16[0], 0x88020);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[1].phvwr_imem16[0], 0x8802f);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[2].phvwr_imem16[0], 0x88030);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[8].phvwr_imem16[0], 0x88000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[9].phvwr_imem16[0], 0x88002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[10].phvwr_imem16[0], 0x88004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[11].phvwr_imem16[0], 0x88006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[12].phvwr_imem16[0], 0x88008);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[13].phvwr_imem16[0], 0x8800a);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[14].phvwr_imem16[0], 0x8800c);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[15].phvwr_imem16[0], 0x8800e);
}

// Test for VLIW ALU set instruction on 32b container
TEST(vliw, set_32b) {
  auto input = {
    R"(
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - set W0, 0x0  # set with minimum constant 0
      - set W1, 7    # set with maximum constant 7
      - set W2, -8   # set with minimum constant -8
      - set W4, A16   # set with operand from adb slot 16 : group 1, byte 0,1,2,3
      - set W5, A20   # set with operand from adb slot 20 : group 1, byte 4,5,6,7
      - set W6, A24   # set with operand from adb slot 24 : group 1, byte 8,9,10,11
      - set W7, A28   # set with operand from adb slot 28 : group 1, byte 12,13,14,15
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[0].phvwr_imem32[0], 0x220010);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[1].phvwr_imem32[0], 0x220017);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[2].phvwr_imem32[0], 0x220018);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[4].phvwr_imem32[0], 0x220010);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[5].phvwr_imem32[0], 0x220014);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[6].phvwr_imem32[0], 0x220018);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[7].phvwr_imem32[0], 0x22001c);
}

// Test for VLIW ALU deposit_field instruction on 8b container.
TEST(vliw, deposit_field_8b) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - deposit-field B0(0..3), 0x0  # deposit_field with constant 0 to bits 0..3
      - deposit-field B1(4..7), 0xF  # deposit_field with constant 15 to bits 4..7
      # badb
      - deposit-field B8(2..6), A0(3..7)   # deposit_field with operand from adb slot 0 [3..7] to B8 [2..6]
      - deposit-field B9(1..5), A1(0..4)   # deposit_field with operand from adb slot 1 [0..4] to B9 [1..5]
      - deposit-field B10(0..0), A2(1..1)  # deposit_field with operand from adb slot 2 [1..1] to B10 [0..0]
      - deposit-field B11(0..7), A3(0..7)  # deposit_field with operand from adb slot 3 [0..7] to B11 [0..7]
      - deposit-field B12(0..1), A4(1..0)  # high bits is less than low bits, home operand B12 is unchanged
      - deposit-field B13, A5(7..0)  # high bits is less than low bits, home operand B13 is unchanged
      - deposit-field B14, A6  # deposit_field with operand from adb slot 6 [0..7] to B14 [0..7]
      # wadb
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[0].phvwr_imem8[0], 0xd8100);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[1].phvwr_imem8[0], 0xfc90f);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[8].phvwr_imem8[0], 0xf2c00);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[9].phvwr_imem8[0], 0xe9e01);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[10].phvwr_imem8[0], 0xc0002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[11].phvwr_imem8[0], 0xf8003);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[12].phvwr_imem8[0], 0xc8004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[13].phvwr_imem8[0], 0xf8005);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[14].phvwr_imem8[0], 0xf8006);
}

// Test for VLIW ALU deposit_field instruction on 16b container.
TEST(vliw, deposit_field_16b) {
  auto input = {
    R"(
      xcmp byte: {  0: H0, 16: H1,
                    32: H2, 48: H3,
                    64: H4, 80: H5,
                    96: H6, 112: H7 }
    )",
    R"(
      - deposit-field H0(0..3), 0x0  # deposit_field with constant 0 to bits 0..3
      - deposit-field H1(4..7), 0xF  # deposit_field with constant 15 to bits 4..7
      # badb
      - deposit-field H8(2..6), A0(3..7)   # deposit_field with operand from adb slot 0 [3..7] to H8 [2..6]
      - deposit-field H9(1..5), A2(0..4)   # deposit_field with operand from adb slot 2 [0..4] to H9 [1..5]
      - deposit-field H10(0..0), A4(1..1)  # deposit_field with operand from adb slot 4 [1..1] to H10 [0..0]
      - deposit-field H11(0..7), A6(0..7)  # deposit_field with operand from adb slot 6 [0..7] to H11 [0..7]
      - deposit-field H12(0..1), A8(1..0)  # high bits is less than low bits, home operand H12 is unchanged
      - deposit-field H13, A10(7..0)  # high bits is less than low bits, home operand H13 is unchanged
      - deposit-field H14, A12  # deposit_field with operand from adb slot 12 [0..7] to H14 [0..7]
      # wadb
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[0].phvwr_imem16[0], 0xcc020);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[1].phvwr_imem16[0], 0xdd32f);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[8].phvwr_imem16[0], 0xd8b80);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[9].phvwr_imem16[0], 0xd47c2);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[10].phvwr_imem16[0], 0xc0004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[11].phvwr_imem16[0], 0xdc006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[12].phvwr_imem16[0], 0xc4008);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[13].phvwr_imem16[0], 0xfc00a);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[14].phvwr_imem16[0], 0xfc00c);
}

// Test for VLIW ALU deposit_field instruction on 32b container.
TEST(vliw, deposit_field_32b) {
  auto input = {
    R"(
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - deposit-field W0, 0x0  # deposit_field with constant 0 to bits 0..3
      - deposit-field W1, 0xF  # deposit_field with constant 15 to bits 4..7
      # badb
      - deposit-field W8, A0(3..7)   # deposit_field with operand from adb slot 0 [3..7] to W8 [2..6]
      - deposit-field W9, A4(0..4)   # deposit_field with operand from adb slot 4 [0..4] to W9 [1..5]
      - deposit-field W10, A8(1..1)  # deposit_field with operand from adb slot 8 [1..1] to W10 [0..0]
      - deposit-field W11, A12(0..7)  # deposit_field with operand from adb slot 12 [0..7] to W11 [0..7]
      - deposit-field W12, A16(1..0)  # high bits is less than low bits, home operand W12 is unchanged
      - deposit-field W13, A20(7..0)  # high bits is less than low bits, home operand W13 is unchanged
      - deposit-field W14, A24  # deposit_field with operand from adb slot 24 [0..7] to W14 [0..7]
      # wadb
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[0].phvwr_imem32[0], 0x3f8010);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[1].phvwr_imem32[0], 0x3f801f);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[8].phvwr_imem32[0], 0x3f8000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[9].phvwr_imem32[0], 0x3f8004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[10].phvwr_imem32[0], 0x3f8008);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[11].phvwr_imem32[0], 0x3f800c);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[12].phvwr_imem32[0], 0x3f8010);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[13].phvwr_imem32[0], 0x3f8014);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[14].phvwr_imem32[0], 0x3f8018);
}

// Test for VLIW ALU bitmasked_set instruction.
// only available on 8b container
TEST(vliw, bitmasked_set) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - bitmasked-set B0, 0xFF, 0x0  # minimum constant 0
      - bitmasked-set B1, 0xFF, 0xFF # maximum constant 255
      - bitmasked-set B8, A0, 0xFF   # operand from adb slot 0 : group 0, byte 0
      - bitmasked-set B9, A1, 0xFF   # operand from adb slot 1 : group 0, byte 1
      - bitmasked-set B10, A2, 0xFF  # operand from adb slot 2 : group 0, byte 2
      - bitmasked-set B11, A3, 0xFF  # operand from adb slot 3 : group 0, byte 3
      - bitmasked-set B12, A4, 0xFF  # operand from adb slot 4 : group 0, byte 4
      - bitmasked-set B13, A5, 0xFF  # operand from adb slot 5 : group 0, byte 5
      - bitmasked-set B14, A6, 0xFF  # operand from adb slot 6 : group 0, byte 6
      - bitmasked-set B15, A7, 0xFF  # operand from adb slot 7 : group 0, byte 7
      - bitmasked-set B2, A8,  0x0F  # operand from adb slot 8 : group 0, byte 8, mask 0x0F
      - bitmasked-set B3, A9,  0xF0  # operand from adb slot 9 : group 0, byte 9, mask 0xF0
      - bitmasked-set B4, A10, 0x11  # operand from adb slot 10 : group 0, byte 10, disjoint mask 0x11
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[0].phvwr_imem8[0], 0xbffff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[1].phvwr_imem8[0], 0xa01ff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[2].phvwr_imem8[0], 0xbe008);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[3].phvwr_imem8[0], 0xa1e09);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[4].phvwr_imem8[0], 0xbdc0a);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[8].phvwr_imem8[0], 0xa0000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[9].phvwr_imem8[0], 0xa0001);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[10].phvwr_imem8[0], 0xa0002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[11].phvwr_imem8[0], 0xa0003);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[12].phvwr_imem8[0], 0xa0004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[13].phvwr_imem8[0], 0xa0005);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[14].phvwr_imem8[0], 0xa0006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[15].phvwr_imem8[0], 0xa0007);
}

// Test for VLIW ALU andc instruction.
TEST(vliw, andc) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - andc B0, 0x0  # minimum constant 0
      - andc B1, 0xFF # maximum constant 255
      - andc B8, A0   # operand from adb slot 0 : group 0, byte 0
      - andc B9, A1   # operand from adb slot 1 : group 0, byte 1
      - andc B10, A2  # operand from adb slot 2 : group 0, byte 2
      - andc B11, A3  # operand from adb slot 3 : group 0, byte 3
      - andc B12, A4  # operand from adb slot 4 : group 0, byte 4
      - andc B13, A5  # operand from adb slot 5 : group 0, byte 5
      - andc B14, A6  # operand from adb slot 6 : group 0, byte 6
      - andc B15, A7  # operand from adb slot 7 : group 0, byte 7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[0].phvwr_imem8[0], 0x90100);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[1].phvwr_imem8[0], 0x901ff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[8].phvwr_imem8[0], 0x90000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[9].phvwr_imem8[0], 0x90001);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[10].phvwr_imem8[0], 0x90002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[11].phvwr_imem8[0], 0x90003);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[12].phvwr_imem8[0], 0x90004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[13].phvwr_imem8[0], 0x90005);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[14].phvwr_imem8[0], 0x90006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[15].phvwr_imem8[0], 0x90007);
}

// Test for VLIW ALU or instruction.
TEST(vliw, or) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - or B0, 0x0  # minimum constant 0
      - or B1, 0xFF # maximum constant 255
      - or B8, A0   # operand from adb slot 0 : group 0, byte 0
      - or B9, A1   # operand from adb slot 1 : group 0, byte 1
      - or B10, A2  # operand from adb slot 2 : group 0, byte 2
      - or B11, A3  # operand from adb slot 3 : group 0, byte 3
      - or B12, A4  # operand from adb slot 4 : group 0, byte 4
      - or B13, A5  # operand from adb slot 5 : group 0, byte 5
      - or B14, A6  # operand from adb slot 6 : group 0, byte 6
      - or B15, A7  # operand from adb slot 7 : group 0, byte 7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[0].phvwr_imem8[0], 0x98100);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[1].phvwr_imem8[0], 0x981ff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[8].phvwr_imem8[0], 0x98000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[9].phvwr_imem8[0], 0x98001);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[10].phvwr_imem8[0], 0x98002);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[11].phvwr_imem8[0], 0x98003);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[12].phvwr_imem8[0], 0x98004);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[13].phvwr_imem8[0], 0x98005);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[14].phvwr_imem8[0], 0x98006);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem8[15].phvwr_imem8[0], 0x98007);
}

// Test for VLIW ALU load_const instruction on 16b container
TEST(vliw, load_const_16b) {
  auto input = {
    R"(
      xcmp byte: {  0: H0, 16: H1,
                    32: H2, 48: H3,
                    64: H4, 80: H5,
                    96: H6, 112: H7 }
    )",
    R"(
      - load-const H0, 0x0  # load-const with constant 0
      - load-const H1, 15   # load-const with immediate 15
      - load-const H2, -16  # load-const with immediate -16
      - load-const H3, 0xFFFF # load-const with constant 0xFFFF
      - load-const H4, 0x8000 # load-const with constant 0x8000
      - load-const H5, 0xEFFF # load-const with constant 0xEFFF
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[0].phvwr_imem16[0], 0xa0000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[1].phvwr_imem16[0], 0xa000f);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[2].phvwr_imem16[0], 0xafff0);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[3].phvwr_imem16[0], 0xaffff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[4].phvwr_imem16[0], 0xa8000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem16[5].phvwr_imem16[0], 0xaefff);
}

// Test for VLIW ALU load_const instruction on 32b container
TEST(vliw, load_const_32b) {
  auto input = {
    R"(
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - load-const W0, 0x0  # load-const with constant 0
      - load-const W1, 7    # load-const with constant 7
      - load-const W2, -8   # load-const with constant -8
      - load-const W3, 0x3FFFF # load-const with constant 0x3FFFF
      - load-const W4, 0x1FFFF # load-const with constant 0x1FFFF
      - load-const W5, 0x10000 # load-const with constant 0x10000
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[0].phvwr_imem32[0], 0x280000);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[1].phvwr_imem32[0], 0x280007);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[2].phvwr_imem32[0], 0x2ffff8);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[3].phvwr_imem32[0], 0x2bffff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[4].phvwr_imem32[0], 0x29ffff);
  EXPECT_EQ(regs.ppu_phvwr.imem.imem32[5].phvwr_imem32[0], 0x290000);
}

// Test for EALU arithmetic instruction.
TEST(ealu, arith_8b) {
  auto input = {
      R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
      R"(
      # 8b arithmetic operation operand 2 is mapped to a fixed slot in operandFIFO
      - add A0, 0x0, B0  # add constant and phv
      - add A1, B0, 0x0  # add phv and constant
      - addc A2, A5, B8   # add adb to phv
      - addc A3, B9, A6   # add phv to adb
      #- saddu B10, A2  # operand from adb slot 2 : group 0, byte 2
      #- sadds B11, A3  # operand from adb slot 3 : group 0, byte 3
      #- ssubu B12, A4  # operand from adb slot 4 : group 0, byte 4
      #- minu B13, A5  # operand from adb slot 5 : group 0, byte 5
      #- maxu B14, A6  # operand from adb slot 6 : group 0, byte 6
      #- mins B15, A7  # operand from adb slot 7 : group 0, byte 7
      #- maxs B16, A8  # operand from adb slot 7 : group 0, byte 7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x91f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x91f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0x95f0a0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0x95f0c0);
}

// Test for EALU add / addc instruction.
TEST(ealu, add_addc_32b) {
  auto input = {
    R"(
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - addc A16, W9, A0   # When an odd 32b ALU is executing an ADDC/SUBC instruction,
      - add  A20, W8, A4  # the corresponding even 32b ALU should be executing an ADD/SUB instruction.
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x1015f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x1011f080);
}

TEST(ealu, arith_unsigned) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - add A0, B0, A0
      - sub A1, B1, A1
      - saddu A2, B2, A2
      - ssubu A3, B3, A3
      - minu A4, H0, A8
      - maxu A6, H1, A10
      - minu A16, W0, 0xF
      - maxu A20, W1, 0x7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x91f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x99f020);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0x81f040);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0x85f060);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x209f100);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x20df140);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x1009f1e0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x100df0e0);
}

TEST(ealu, arith_signed) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - sadds A0, B2, A2
      - ssubs A1, B3, A3
      - mins A4, H0, A8
      - maxs A6, H1, A10
      - mins A16, W0, 0xF
      - maxs A20, W1, 0x7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x83f040);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x87f060);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x20bf100);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x20ff140);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x100bf1e0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x100ff0e0);
}

TEST(ealu, compare_unsigned) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - gtequ A0, B2, A2
      - ltu A1, B3, A3
      - lequ A4, H0, A8
      - gtu A6, H1, A10
      - eq A16, W0, 0xF
      - neq A20, W1, 0x7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x897040);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x8d7060);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x2017100);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x2057140);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x101171e0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x101570e0);
}

TEST(ealu, compare_signed) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
      xcmp word: {  0: W0,
                    32: W1,
                    64: W2,
                    96: W3 }
    )",
    R"(
      - gteqs A0, B2, A2
      - lts A1, B3, A3
      - lteqs A4, H0, A8
      - gts A6, H1, A10
      - eq A16, W0, 0xF
      - eq64 A20, W1, 0x7
      #- neq A16, W2, 0x7
      #- neq64 A20, W3, 0x7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x8b7040);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x8f7060);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x2077140);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x101171e0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x101370e0);
}

// Test for EALU logical instruction.
TEST(ealu, logical) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - setz A0           # Action Data Byte 0 = 0x0
      - nor A1, B0, A0    # Action Data Byte 1 = ~(B0 | A0)
      - andca A2, B0, A0  # Action Data Byte 2 = ~A0 & B0
      - nota A3, A0       # Action Data Byte 3 = ~A0
      - andcb A4, B0, A0  # Action Data Byte 4 = ~B0 & A0
      #- notb A5, B0       # Action Data Byte 5 = ~B0
      - xor A6, B0, A0    # Action Data Byte 6 = B0 ^ A0
      #- nand A7, B0, A0   # Action Data Byte 7 = ~(B0 & A0)
      #- and A8, B0, A0    # Action Data Byte 8 = B0 & A0
      #- xnor A9, B0, A0   # Action Data Byte 9 = ~(B0 ^ A0)
      #- setb A10, B0      # Action Data Byte 10 = B0
      #- orca A11, B0, A0  # Action Data Byte 11 = ~A0 | B0
      #- seta A12, A0      # Action Data Byte 12 = A0
      #- orcb A13, B0, A0  # Action Data Byte 13 = ~B0 | A0
      #- or A14, B0, A0    # Action Data Byte 14 = B0 | A0
      #- sethi A15         # Action Data Byte 15 = 0x1
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x80f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x82f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0x88f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0x86f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x204f000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x20cf000);
}

// Test for EALU shift instruction.
TEST(ealu, shift) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - shl A0, B0, 1              # Action Data Byte 0 = B0 << 1
      - shru A1, B0, 1             # Action Data Byte 1 = B0 >> 1
      - shrs A2, B0, 1             # Action Data Byte 2 = B0 >> 1
      - funnel-shift A3, B0, B1, 1 # Action Data Byte 3 = B0 << 1 | B1 >> 7
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0xcc0000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0xd40000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0xdc0000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0xc40001);
}

// Test for EALU load_const instruction.
TEST(ealu, load_const) {
  auto input = {
    R"(
      xcmp byte: {  0: H0, 16: H1,
                    32: H2, 48: H3,
                    64: H4, 80: H5,
                    96: H6, 112: H7 }
    )",
    R"(
      - load-const A0, 0x0  # load-const with constant 0
      - load-const A1, 15   # load-const with immediate 15
      - load-const A2, -16  # load-const with immediate -16
      - load-const A3, 0xFFFF # load-const with constant 0xFFFF
      - load-const A4, 0x8000 # load-const with constant 0x8000
      - load-const A6, 0xEFFF # load-const with constant 0xEFFF
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x804000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x80400f);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0x8040f0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0x8040ff);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x2104000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x21d47ff);
}

// Test for EALU set instruction.
TEST(ealu, set) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - set A0, 0x0  # implemented as bitmasked_set with minimum constant 0
      - set A1, 0xFF # implemented as bitmasked_set with maximum constant 255
      - set A2, B10 # implemented as bitmasked_set with operand from adb slot 2 : group 0, byte 2
      - set A3, B11 # implemented as bitmasked_set with operand from adb slot 3 : group 0, byte 3
      #- set A4, B12 # implemented as bitmasked_set with operand from adb slot 4 : group 0, byte 4
      #- set A5, B13 # implemented as bitmasked_set with operand from adb slot 5 : group 0, byte 5
      #- set A6, B14 # implemented as bitmasked_set with operand from adb slot 6 : group 0, byte 6
      #- set A7, B15 # implemented as bitmasked_set with operand from adb slot 7 : group 0, byte 7
    )"};

  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0x803000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0x803fe0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0x803140);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0x803160);
}

// Test for EALU bitmasked_set instruction.
TEST(ealu, bitmasked_set) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - bitmasked-set A0, A0, B0, 0x0  # minimum constant 0
      - bitmasked-set A1, A1, B1, 0xFF # maximum constant 255
      - bitmasked-set A2, A2, B2, 0x01  # map to ealu
      - bitmasked-set A3, A3, B3, 0x02  # map to ealu
      # - bitmasked-set B2, A0, B4       # map to phvwr
      # - bitmasked-set B3, A1, B5       # map to phvwr
      # - bitmasked-set B4, A2, B6       # map to phvwr
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0xe00000);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0xa7f820);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[2].ealu_imem8[0], 0xa00840);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[3].ealu_imem8[0], 0xe01060);
}

// Test for EALU deposit_field instruction.
TEST(ealu, deposit_field) {
  auto input = {
    R"(
      xcmp byte: {  0: B0, 8: B1, 16: B2, 24: B3,
                    32: B4, 40: B5, 48: B6, 56: B7,
                    64: B8, 72: B9, 80: B10, 88: B11,
                    96: B12, 104: B13, 112: B14, 120: B15 }
    )",
    R"(
      - deposit-field A0, 0x0, B2
      - deposit-field A1, 0xF, B3
      # badb
      - deposit-field A4, A8(3..7), H2
      - deposit-field A6, A10(3..7), H3
      - deposit-field A16, A24(7..0), W0
      - deposit-field A20, A28, W1
      # wadb
    )"};
  auto regs = runTest(input);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[0].ealu_imem8[0], 0xcff800);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem8[1].ealu_imem8[0], 0xcff9e0);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[0].ealu_imem16[0], 0x3dff900);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem16[1].ealu_imem16[0], 0x3dff940);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[0].ealu_imem32[0], 0x17fffb00);
  EXPECT_EQ(regs.ppu_phvwr.imem.eaimem32[1].ealu_imem32[0], 0x17fffb80);
}

/* Test for EALU advanced features: chained operation */
TEST(ealu, chained_operations) {
}

/* Test for EALU advanced features: priority set */
TEST(ealu, priority_set) {
}

}  // namespace FLATROCK
