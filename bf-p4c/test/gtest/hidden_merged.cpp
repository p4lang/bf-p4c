
#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

namespace Test {

namespace {

auto defs = R"(
    match_kind {exact}
    header H { bit<16> f1; bit<16> f2; bit<16> f3;}
    struct headers_t { H h; }
    struct local_metadata_t {} )";

// We only need to run TableAllocPass (viz DecidePlacement & TransformTables)
// But we will run the FullBackend and verify the ASM generated.
#define RUN_CHECK(input, expected) do { \
    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(), \
                        {defs, TestCode::empty_state(), input, TestCode::empty_appy()}, \
                        TestCode::tofino_shell_control_marker(), \
                        {"--no-dead-code-elimination"}); \
    EXPECT_TRUE(blk.CreateBackend()); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullBackend)); \
    auto res = blk.match(TestCode::CodeBlock::MauAsm, expected); \
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count \
                             << "\n'" << blk.extract_code(TestCode::CodeBlock::MauAsm) << "'\n"; \
} while (0)

}  // namespace


// N.B. The placement runs faster when there is only one table.

TEST(HiddenMerged, DISABLED_HiddenMerged) {
    auto input = R"(
            action test_action() {
                hdr.h.f1 = 0;
            }
            @hidden table test_table {
                key = { hdr.h.f1 : exact; }
                actions = { test_action; }
                const default_action = test_action();
            }
            apply {
                if (hdr.h.f1 == 0x1) {
                    test_table.apply();
                }
            }
        )";

    Match::CheckList expected {
        "`.*`",
        "exact_match test_table_`\\d+``.*`:",
        "`.*`",
        "p4: { name: ingress_control.test_table,`.*`hidden: true }"
    };
    RUN_CHECK(input, expected);
}

}  // namespace Test
