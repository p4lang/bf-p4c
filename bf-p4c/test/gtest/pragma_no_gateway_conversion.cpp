
#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

namespace Test {

namespace {

auto defs = R"(
    match_kind {ternary}
    header H { bit<16> f1; bit<16> f2; bit<16> f3;}
    struct headers_t { H h; }
    struct local_metadata_t {} )";

// We only need to run TableAllocPass (viz DecidePlacement & TransformTables)
// But we will run the FullBackend and verify the ASM generated.
#define RUN_CHECK(input, expected) do { \
    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(), \
                        {defs, TestCode::empty_state(), input, TestCode::empty_appy()}, \
                        TestCode::tofino_shell_control_marker()); \
    EXPECT_TRUE(blk.CreateBackend()); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend)); \
    auto res = blk.match(TestCode::CodeBlock::MauAsm, expected); \
    EXPECT_TRUE(res.success) << "    @ expected[" << res.count<< "], char pos=" << res.pos << "\n" \
                             << "    '" << expected[res.count] << "'\n" \
                             << "    '" << blk.extract_code(TestCode::CodeBlock::MauAsm, res.pos) \
                             << "'\n"; \
} while (0)

}  // namespace


// N.B. The placement runs faster when there is only one table.

TEST(PragmaNoGatewayConversion, WithoutPragma) {
    auto input = R"(
            action NoAction() {}
            action hit() {}
            // @pragma no_gateway_conversion
            table tbl {
                actions = {hit;}
                key = { hdr.h.f1 : ternary; }
                const entries = { (1 &&& 7) : hit(); }
                size = 512;
            }
            apply {
                tbl.apply();
            }
        )";

    Match::CheckList expected {
        "`.*`",
        "exact_match",
        "`.*`",
        "gateway:",
        "`.*`",
        "match: { 0: hdr.h.f1(0..7), 8: hdr.h.f1(8..15) }",
        "0b*************001: END",  // (1 &&& 7)
        "miss: run_table"
     };
    RUN_CHECK(input, expected);
}

TEST(PragmaNoGatewayConversion, WithPragma) {
    auto input = R"(
            action NoAction() {}
            action hit() {}
            @pragma no_gateway_conversion
            table tbl {
                actions = {hit;}
                key = { hdr.h.f1 : ternary; }
                const entries = { (1 &&& 7) : hit(); }
                size = 512;
            }
            apply {
                tbl.apply();
            }
        )";

    Match::CheckList expected {
        "`.*`",
        "ternary_match",
        "`.*`",
        "p4: { name: ingress_control.tbl, size: `\\d*` }",
        "`.*`",
        "match: - { group: `\\d*`, byte_config: `\\d*`, dirtcam: 0x`\\d*` }",
        "`.*`",
        "miss: END"
     };
    RUN_CHECK(input, expected);
}

}  // namespace Test
