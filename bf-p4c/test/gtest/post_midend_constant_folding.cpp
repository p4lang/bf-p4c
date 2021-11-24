
#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

namespace Test {

namespace {

auto defs = R"(
    match_kind {exact}
    header H { bit<32> f1; }
    struct headers_t { H h; }
    struct local_metadata_t {} )";

// We only need to run TableAllocPass (viz DecidePlacement & TransformTables)
// But we will run the FullBackend and verify the ASM generated.
#define RUN_CHECK(input, expected) do { \
    auto blk = TestCode(TestCode::Hdr::Tofino1arch, TestCode::tofino_shell(), \
                        {defs, TestCode::empty_state(), input, TestCode::empty_appy()}, \
                        TestCode::tofino_shell_control_marker()); \
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations); \
    EXPECT_TRUE(blk.CreateBackend()); \
    auto res = blk.match(expected); \
    EXPECT_TRUE(res.success) << "    @ expected[" << res.count<< "], char pos=" << res.pos << "\n" \
                             << "    '" << expected[res.count] << "'\n" \
                             << "    '" << blk.extract_code(res.pos) << "'\n"; \
} while (0)

}  // namespace

TEST(PostMidendConstantFolding, SizeInBytesConstConst) {
    auto input = R"(
            apply {
                hdr.h.f1 = sizeInBytes(hdr.h.f1) + 10 + 20;
            }
        )";
    Match::CheckList expected {
        "action p4headers_tofino1l`(\\d+)`() {",
            "hdr.h.f1 = 32w34;",
        "}",
        "table tbl_p4headers_tofino1l`\\1` {",
            "actions = {",
                "p4headers_tofino1l`\\1`();",
            "}",
            "const default_action = p4headers_tofino1l`\\1`();",
        "}",
        "apply {",
            "tbl_p4headers_tofino1l`\\1`.apply();",
        "}"
    };
    RUN_CHECK(input, expected);
}

TEST(PostMidendConstantFolding, ConstSizeInBytesConst) {
    auto input = R"(
            apply {
                hdr.h.f1 = 10 + sizeInBytes(hdr.h.f1) + 20;
            }
        )";
    Match::CheckList expected {
        "action p4headers_tofino1l`(\\d+)`() {",
            "hdr.h.f1 = 32w34;",
        "}",
        "table tbl_p4headers_tofino1l`\\1` {",
            "actions = {",
                "p4headers_tofino1l`\\1`();",
            "}",
            "const default_action = p4headers_tofino1l`\\1`();",
        "}",
        "apply {",
            "tbl_p4headers_tofino1l`\\1`.apply();",
        "}"
    };
    RUN_CHECK(input, expected);
}

TEST(PostMidendConstantFolding, ConstConstSizeInBytes) {
    auto input = R"(
            apply {
                hdr.h.f1 = 10 + 20 + sizeInBytes(hdr.h.f1);
            }
        )";
    Match::CheckList expected {
        "action p4headers_tofino1l`(\\d+)`() {",
            "hdr.h.f1 = 32w34;",
        "}",
        "table tbl_p4headers_tofino1l`\\1` {",
            "actions = {",
                "p4headers_tofino1l`\\1`();",
            "}",
            "const default_action = p4headers_tofino1l`\\1`();",
        "}",
        "apply {",
            "tbl_p4headers_tofino1l`\\1`.apply();",
        "}"
    };
    RUN_CHECK(input, expected);
}

TEST(PostMidendConstantFolding, SizeInBytesConstConstExplicitParentheses) {
    auto input = R"(
            apply {
                hdr.h.f1 = (sizeInBytes(hdr.h.f1) + 10) + 20;
            }
        )";
    Match::CheckList expected {
        "action p4headers_tofino1l`(\\d+)`() {",
            "hdr.h.f1 = 32w34;",
        "}",
        "table tbl_p4headers_tofino1l`\\1` {",
            "actions = {",
                "p4headers_tofino1l`\\1`();",
            "}",
            "const default_action = p4headers_tofino1l`\\1`();",
        "}",
        "apply {",
            "tbl_p4headers_tofino1l`\\1`.apply();",
        "}"
    };
    RUN_CHECK(input, expected);
}

}  // namespace Test
