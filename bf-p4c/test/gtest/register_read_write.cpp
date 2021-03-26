/*
 * This test covers slicing, downcasting, and upcasting
 * of the output of the read method of a Register extern.
 */

#include "bf-p4c/midend/register_read_write.h"

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/typeMap.h"
#include "midend/actionSynthesis.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/elim_cast.h"
#include "bf-p4c/midend/action_synthesis_policy.h"

namespace Test {

namespace {

auto defs = R"(
    struct headers_t { }
    struct local_metadata_t { bit<5> result_5b; bit<16> result_16b; bit<32> result_32b; })";

#define RUN_CHECK(pass, input, expected) do { \
    auto blk = TestCode(TestCode::Hdr::Tofino1arch, \
        TestCode::tofino_shell(), \
        {defs, TestCode::empty_state(), input, TestCode::empty_appy()}, \
        TestCode::tofino_shell_control_marker()); \
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend)); \
    EXPECT_TRUE(blk.apply_pass(pass)); \
    auto res = blk.match(expected); \
    EXPECT_TRUE(res.success) << "    @ expected[" << res.count<< "], char pos=" << res.pos << "\n" \
                             << "    '" << expected[res.count] << "'\n" \
                             << "    '" << blk.extract_code(res.pos) << "'\n"; \
    } while (0)

/*
 * For downcasting and slicing of the result of the read method,
 * only the ArchTranslation and RegisterReadWrite passes are needed.
 * For upcasting of the result of the read method, in addition to the above mentioned passes,
 * the ElimCasts, MoveDeclarations, and SimplifyControlFlow passes are needed.
 * The SynthesizeActions pass is needed for reads/writes placed in an apply block
 * of a control block.
 */
Visitor *setup_passes() {
    auto refMap = new P4::ReferenceMap;
    auto typeMap = new P4::TypeMap;
    auto typeChecking = new BFN::TypeChecking(refMap, typeMap);
    return new PassManager {
        typeChecking,
        new BFN::ArchTranslation(refMap, typeMap, BackendOptions()),
        new BFN::ElimCasts(refMap, typeMap),
        new P4::MoveDeclarations(),
        new P4::SimplifyControlFlow(refMap, typeMap, typeChecking),
        new P4::SynthesizeActions(refMap, typeMap,
                new BFN::ActionSynthesisPolicy(new std::set<cstring>, refMap, typeMap),
                typeChecking),
        new BFN::RegisterReadWrite(refMap, typeMap, typeChecking)
    };
}

}  // namespace

TEST(RegisterReadWrite, ReadSlice) {
    auto input = R"(
        Register<bit<16>, PortId_t>(1024) reg_16b;
        action reg_16b_action() {
            ig_md.result_5b = reg_16b.read(ig_intr_md.ingress_port)[4:0];
        }
        apply {
            reg_16b_action();
        })";
    Match::CheckList expected {
        "Register<bit<16>, PortId_t>(32w1024) reg_16b_0;",
        "RegisterAction<bit<16>, PortId_t, bit<16>>(reg_16b_0)",
        "reg_16b_0_reg_16b_action = {",
            "void apply(inout bit<16> value, out bit<16> rv) {",
                "bit<16> in_value;",
                "in_value = value;",
                "rv = in_value;",
            "}",
        "};",
        "action reg_16b_action() {",
            "ig_md.result_5b = reg_16b_0_reg_16b_action.execute(ig_intr_md.ingress_port)[4:0];",
        "}",
        "apply {",
            "reg_16b_action();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(RegisterReadWrite, ReadDowncast) {
    auto input = R"(
        Register<bit<16>, PortId_t>(1024) reg_16b;
        action reg_16b_action() {
            ig_md.result_5b = (bit<5>)reg_16b.read(ig_intr_md.ingress_port);
        }
        apply {
            reg_16b_action();
        })";
    Match::CheckList expected {
        "Register<bit<16>, PortId_t>(32w1024) reg_16b_0;",
        "RegisterAction<bit<16>, PortId_t, bit<16>>(reg_16b_0)",
        "reg_16b_0_reg_16b_action = {",
            "void apply(inout bit<16> value, out bit<16> rv) {",
                "bit<16> in_value;",
                "in_value = value;",
                "rv = in_value;",
            "}",
        "};",
        "action reg_16b_action() {",
            "ig_md.result_5b = reg_16b_0_reg_16b_action.execute(ig_intr_md.ingress_port)[4:0];",
        "}",
        "apply {",
            "reg_16b_action();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(RegisterReadWrite, ReadUpcast) {
    auto input = R"(
        Register<bit<16>, PortId_t>(1024) reg_16b;
        action reg_16b_action() {
            ig_md.result_32b = (bit<32>)reg_16b.read(ig_intr_md.ingress_port);
        }
        apply {
            reg_16b_action();
        })";
    Match::CheckList expected {
        "bit<16> $concat_to_slice`(\\d+)`;",
        "bit<16> $concat_to_slice`(\\d+)`;",
        "Register<bit<16>, PortId_t>(32w1024) reg_16b_0;",
        "RegisterAction<bit<16>, PortId_t, bit<16>>(reg_16b_0)",
        "reg_16b_0_reg_16b_action = {",
            "void apply(inout bit<16> value, out bit<16> rv) {",
                "bit<16> in_value;",
                "in_value = value;",
                "rv = in_value;",
            "}",
        "};",
        "action reg_16b_action() {",
            "$concat_to_slice`\\1` = 16w0;",
            "$concat_to_slice`\\2` = reg_16b_0_reg_16b_action.execute(ig_intr_md.ingress_port);",
            "ig_md.result_32b[31:16] = $concat_to_slice`\\1`;",
            "ig_md.result_32b[15:0] = $concat_to_slice`\\2`;",
        "}",
        "apply {",
            "reg_16b_action();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(RegisterReadWrite, ApplyBlockWriteAfterRead) {
    auto input = R"(
        Register<bit<16>, PortId_t>(1024) reg_16b;
        apply {
            ig_md.result_16b = reg_16b.read(ig_intr_md.ingress_port);
            reg_16b.write(ig_intr_md.ingress_port, ig_tm_md.mcast_grp_a);
        })";
    Match::CheckList expected {
        "Register<bit<16>, PortId_t>(32w1024) reg_16b_0;",
        "RegisterAction<bit<16>, PortId_t, bit<16>>(reg_16b_0)",
        "reg_16b_0_`(.*)` = {",
            "void apply(inout bit<16> value, out bit<16> rv) {",
                "bit<16> in_value;",
                "in_value = value;",
                "rv = in_value;",
                "value = ig_tm_md.mcast_grp_a;",
            "}",
        "};",
        "action `\\1`() {",
            "ig_md.result_16b = reg_16b_0_`\\1`.execute(ig_intr_md.ingress_port);",
        "}",
        "apply {",
            "`\\1`();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

}  // namespace Test
