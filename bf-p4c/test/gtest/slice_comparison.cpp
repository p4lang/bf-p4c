
#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

namespace Test {

namespace {

auto defs = R"(
    match_kind {exact}
    header H { bit<4> pad1; bit<4> pri1; bit<4> pad2; bit<4> pri2; }
    struct headers_t { H h; }
    struct local_metadata_t {} )";

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

TEST(SliceComparison, SliceComparison1) {
    auto input = R"(
            apply {
                bit<4> pri = hdr.h.pri1;
                bit<4> pri2 = hdr.h.pri2;
                if(pri[3:3] != pri2[3:3] && pri & 8 == 8) {
                    hdr.h.pri1 = hdr.h.pri2;
                }
            }
        )";

    Match::CheckList expected {
        "`.*`",
        "gateway`.*`:",
        "`.*`",
        "match: { 3: hdr.h.pri1(3), 11: hdr.h.pri1(3) }",
        "xor: { 3: hdr.h.pri2(3) }",
        "0b1*******1:",
        "run_table: true",
    };
    RUN_CHECK(input, expected);
}

TEST(SliceComparison, SliceComparison2) {
    auto input = R"(
            apply {
                bit<4> pri = hdr.h.pri1;
                bit<4> pri2 = hdr.h.pri2;
                if(pri[3:3] != pri2[3:3] && pri2 & 8 == 8) {
                    hdr.h.pri1 = hdr.h.pri2;
                }
            }
        )";

    Match::CheckList expected {
        "`.*`",
        "gateway`.*`:",
        "`.*`",
        "match: { 3: hdr.h.pri1(3), 11: hdr.h.pri2(3) }",
        "xor: { 3: hdr.h.pri2(3) }",
        "0b1*******1:",
        "run_table: true",
    };
    RUN_CHECK(input, expected);
}

}  // namespace Test
