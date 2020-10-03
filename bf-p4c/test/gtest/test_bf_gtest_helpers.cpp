#include "bf_gtest_helpers.h"

#include "gtest/gtest.h"

#include "boost/algorithm/string/replace.hpp"
#include "frontends/p4/toP4/toP4.h"
#include "lib/sourceCodeBuilder.h"
#include "bf-p4c/midend/elim_cast.h"

namespace Test {

using namespace Match;  // To remove noise & reduce line lengths.

TEST(testBfGtestHelper, MatchTrimWhiteSpace) {
    EXPECT_EQ(trimWhiteSpace("").compare(""), 0);
    EXPECT_EQ(trimWhiteSpace("a b").compare("a b"), 0);
    EXPECT_EQ(trimWhiteSpace(" \n a \n b \n ").compare("a b"), 0);
}

TEST(testBfGtestHelper, MatchTrimAnnotations) {
    EXPECT_EQ(trimAnnotations("").compare(""), 0);
    EXPECT_EQ(trimAnnotations(" a @word b ").compare(" a  b "), 0);
    EXPECT_EQ(trimAnnotations(" a @func() b ").compare(" a  b "), 0);
    EXPECT_EQ(trimAnnotations(" a @func(\"string\") b ").compare(" a  b "), 0);
    EXPECT_EQ(trimAnnotations(" a @word b @func() c ").compare(" a  b  c "), 0);
    EXPECT_EQ(trimAnnotations(" a @func(p1,\np2\n) b ").compare(" a  b "), 0);
    EXPECT_EQ(trimAnnotations(" a @func(p1,\n@name\n) b ").compare(" a  b "), 0);

    // ********* We do not handle nested parentheses! **********
    EXPECT_EQ(trimAnnotations(" a @func( fx() ) b ").compare(" a  ) b "), 0);
}

TEST(testBfGtestHelper, MatchConvetToRegex) {
    EXPECT_EQ(convet_to_regex("").compare(""), 0);
    EXPECT_EQ(convet_to_regex("a b").compare("a b"), 0);
    EXPECT_EQ(convet_to_regex("a `b` c").compare("a b c"), 0);
    EXPECT_EQ(convet_to_regex("^$.|?*+(){[\\").compare(R"(\^\$\.\|\?\*\+\(\)\{\[\\)"), 0);
    EXPECT_EQ(convet_to_regex("`^$.|?*+(){[\\`").compare("^$.|?*+(){[\\"), 0);  // Don't convert.
}

TEST(testBfGtestHelper, MatchMatchBasic) {
    EXPECT_EQ(match_basic("", ""), 0U);
    EXPECT_EQ(match_basic("", "expression"), 0U);
    EXPECT_EQ(match_basic("expression", "expression"), 10U);
    EXPECT_EQ(match_basic("exp", "expression"), 3U);
    EXPECT_EQ(match_basic("ress", "expression", 3), 3U + 4U);
    EXPECT_EQ(match_basic("ress", "expression", 3, 3+4), 3U + 4U);
    EXPECT_EQ(match_basic("ress", "expression", 3, 99), 3U + 4U);
    EXPECT_EQ(match_basic("ress", "expression", 3, std::string::npos), 3U + 4U);
    EXPECT_EQ(match_basic("a \n b", "a \n bcd"), 5U);

    EXPECT_EQ(match_basic("expression", ""), failed);
    EXPECT_EQ(match_basic("ress", "expre", 3), failed);
    EXPECT_EQ(match_basic("ress", "expression"), failed);
    EXPECT_EQ(match_basic("ress", "expression", 3, 4), failed);
    EXPECT_EQ(match_basic("ress", "expression", 3, 1), failed);  // Bad pos.
    EXPECT_EQ(match_basic("ress", "expression", 13), failed);  // Bad pos.
}

TEST(testBfGtestHelper, MatchMatch) {
    // Same as match_basic()
    EXPECT_EQ(match(CheckList{""}, ""), Result(true, 0, 1));
    EXPECT_EQ(match(CheckList{""}, "expression"), Result(true, 0, 1));
    EXPECT_EQ(match(CheckList{"expression"}, "expression"), Result(true, 10, 1));
    EXPECT_EQ(match(CheckList{"exp"}, "expression"), Result(true, 3, 1));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3), Result(true, 3+4, 1));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3, 3+4), Result(true, 3+4, 1));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3, 99), Result(true, 3+4, 1));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3, std::string::npos), Result(true, 3+4, 1));
    EXPECT_EQ(match(CheckList{"a \n b"}, "a \n bcd"), Result(true, 5, 1));

    EXPECT_FALSE(match(CheckList{"expression"}, "").success);
    EXPECT_EQ(match(CheckList{"expression"}, ""), Result(false, 0, 0) );
    EXPECT_EQ(match(CheckList{"ress"}, "expre", 3), Result(false, 3, 0));
    EXPECT_EQ(match(CheckList{"ress"}, "expression"), Result(false, 0, 0));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3, 4), Result(false, 3, 0));
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 3, 1), Result(false, failed, 0));  // Bad pos.
    EXPECT_EQ(match(CheckList{"ress"}, "expression", 13), Result(false, failed, 0));  // Bad pos.

    // Inline checking.
    EXPECT_TRUE(match(CheckList{""}, "").success);
    EXPECT_FALSE(match(CheckList{"expression"}, "").success);

    // And with regex.
    EXPECT_EQ(match(CheckList{"``"}, ""), Result(true, 0, 1));
    EXPECT_EQ(match(CheckList{"``"}, " "), Result(true, 0, 1));
    EXPECT_EQ(match(CheckList{"` `"}, " "), Result(true, 1, 1));
    EXPECT_EQ(match(CheckList{"` `"}, ""), Result(false, 0, 0));
    EXPECT_THROW(match(CheckList{"`"}, "stuff"), std::invalid_argument);
    EXPECT_THROW(match(CheckList{"` ` `"}, "stuff"), std::invalid_argument);

    EXPECT_EQ(match(CheckList{"\\x60"}, "`"), Result(true, 1, 1));
    EXPECT_EQ(match(CheckList{"`\\x60`"}, "`"), Result(true, 1, 1));

    EXPECT_EQ(match(CheckList{"The `(\\w+)` is `(\\d+)`"}, "The num is 42!"), Result(true, 13, 1));
    EXPECT_EQ(match(CheckList{"How `(\\w+)` you `\\1`"}, "How do you do???"), Result(true, 13, 1));
    EXPECT_EQ(match(CheckList{"How `(\\w+)` you `(\\1)`"}, "How do you do?"), Result(true, 13, 1));
    EXPECT_ANY_THROW(match(CheckList{"`(\\w+)` `\\2`"}, "Bad Bad back-reference!"));
    EXPECT_EQ(match(CheckList{"One `(\\w+)` 3"}, "One Two 3 Four"), Result(true, 9, 1));
    EXPECT_EQ(match(CheckList{"One `(\\w+)` 3"}, "One One Two 3 Four"), Result(false, 0, 0));

    // And with CheckList.
    EXPECT_EQ(match(CheckList{"hello", "world"}, "hello world!"), Result(false, 5, 1));
    EXPECT_EQ(match(CheckList{"hello", "world"}, "hello world!", 0, std::string::npos,
                        TrimWhiteSpace), Result(true, 11, 2));  // No space.
    EXPECT_EQ(match(CheckList{"hello ", "world"}, "hello world!", 0, std::string::npos,
                        TrimWhiteSpace), Result(true, 11, 2));  // Left space.
    EXPECT_EQ(match(CheckList{"hello", " world"}, "hello world!", 0, std::string::npos,
                        TrimWhiteSpace), Result(true, 11, 2));  // Right space.
    EXPECT_EQ(match(CheckList{"hello ", " world"}, "hello world!", 0, std::string::npos,
                        TrimWhiteSpace), Result(false, 6, 1));  // Two spaces!
    EXPECT_EQ(match(CheckList{"The", "`(\\w+)`", "is", "`(\\d+)`"}, "The num is 42!",
                    0, std::string::npos, TrimWhiteSpace), Result(true, 13, 4));
    // Back References across CheckList are fine.
    EXPECT_EQ(match(CheckList{"How", "`(\\w+)`", "you", "`\\1`"}, "How do you do???",
                    0, std::string::npos, TrimWhiteSpace), Result(true, 13, 4));
    EXPECT_EQ(match(CheckList{"`(\\w+)`", "`(\\w\\w)`", "cad", "`\\1`", "`\\2`"}, "abracadabra!",
                    0, std::string::npos, TrimWhiteSpace), Result(true, 11, 5));

    // Check for early miss-match & use 'pos' to skip over first word.
    auto res = match(CheckList{"One", "`(\\w+)`", "3"}, "One One Two 3 Four",
                     0, std::string::npos, TrimWhiteSpace);
    EXPECT_FALSE(res.success) << " pos=" << res.pos << " count=" << res.count << "'\n";
    res =      match(CheckList{"One", "`(\\w+)`", "3"}, "One One Two 3 Four",
                     3, std::string::npos, TrimWhiteSpace);
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count << "'\n";
}

namespace {
std::string Code = R"(
    control TestIngress<H, M>(inout H hdr, inout M meta);
    package TestPackage<H, M>(TestIngress<H, M> ig);
    %0%
    control testingress(inout Headers headers, inout Metadata meta) {
        %1%
    }
    TestPackage(testingress()) main;)";
std::string EmptyDefs = R"(struct Metadata{}; struct Headers{};)";
std::string EmptyAppy = R"(apply{})";
std::string Marker = "control testingress" + TestCode::any_to_brace();
}  // namespace

TEST(testBfGtestHelper, TestCode) {
    TestCode(P4Include::None, "");
    TestCode(P4Include::Tofino1arch, "");
    TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy});
    TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy}, Marker);

    testing::internal::CaptureStderr();
    EXPECT_THROW(TestCode(P4Include::Tofino1arch, Code, {EmptyDefs}), std::invalid_argument);
    auto stderr = testing::internal::GetCapturedStderr();
    EXPECT_NE(stderr.find("syntax error"), std::string::npos);

    testing::internal::CaptureStderr();
    EXPECT_THROW(TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, ""}), std::invalid_argument);
    stderr = testing::internal::GetCapturedStderr();
    EXPECT_NE(stderr.find("syntax error"), std::string::npos);

    testing::internal::CaptureStderr();
    EXPECT_THROW(TestCode(P4Include::Tofino1arch, Code, {"", EmptyAppy}), std::invalid_argument);
    stderr = testing::internal::GetCapturedStderr();
    EXPECT_NE(stderr.find("syntax error"), std::string::npos);

    testing::internal::CaptureStderr();
    EXPECT_THROW(TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy}, "bad"),
                 std::invalid_argument);
    stderr = testing::internal::GetCapturedStderr();
    EXPECT_EQ(stderr.length(), 0U);

    TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy, "There is no %3%"});
    // Multiple replacements tested below.
}

TEST(testBfGtestHelper, ControlBlockTestGetBlock) {
    auto blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, "\napply\n\n{\n\n}\n"}, Marker);
    // The default setting is  blk.flags(TrimWhiteSpace);
    EXPECT_EQ(blk.get_block().compare("apply { }"), 0);
    EXPECT_EQ(blk.get_block(6).compare("{ }"), 0);

    blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, "\n\napply\n\n{\n\n}\n\n"}, Marker);
    blk.flags(Raw);
    // This 'Raw' test is dependant upon the parser, hence is brittle.
    // EXPECT_EQ(blk.get_block().compare("   apply {\n    }"), 0);

    blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, "action a(){} apply{a();}"}, Marker);
    blk.flags(TrimWhiteSpace | TrimAnnotations);
    EXPECT_EQ(blk.get_block().compare("action a() { } apply { a(); }"), 0);

    std::string pkg = Code;
    boost::replace_all(pkg, R"(%1%)", R"(action a(){} %2% apply {%tmp% %tmp%})");
    boost::replace_all(pkg, R"(%0%)", R"(%1%)");
    boost::replace_all(pkg, R"(%tmp%)", R"(%0%)");
    // N.B. control block starts at %2%, also the order of defines is not important.
    blk = TestCode(P4Include::Tofino1arch, pkg, {R"(a();)", EmptyDefs, ""}, Marker);
    blk.flags(TrimWhiteSpace | TrimAnnotations);
    EXPECT_EQ(blk.get_block().compare("action a() { } apply { a(); a(); }"), 0) << blk;
}

TEST(testBfGtestHelper, ControlBlockTestApplyPassConst) {
    auto blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy});
    Util::SourceCodeBuilder builder;
    EXPECT_TRUE(blk.apply_pass(new P4::ToP4(builder, false)));
}

#if 0
TEST(testBfGtestHelper, ControlBlockTestApplyPassMutating) {
    // A similar test is run in the gtest 'ElimCast.EquLeft'.
    // It is here as an example & for debugging purposes.
    auto defs = R"(
        header H { bit<8> field1; bit<8> field2;}
        struct headers_t { H h; }
        struct local_metadata_t {} )";
    auto input = R"(
        action act() {}
        apply {
            if (hdr.h.field1 ++ hdr.h.field2 == 16w0x0102) {
                act();
            }
        })";
    CheckList expected {
        "action act() { }",
        "apply {",
            "if (hdr.h.field1 == 8w1 && hdr.h.field2 == 8w2) {",
                "act();",
            "}",
        "}"
    };
    auto blk = TestCode(P4Include::Tofino1arch, TestCode::tofino_shell(),
                        {defs, TestCode::empty_state(), input, TestCode::empty_appy()},
                        TestCode::tofino_shell_control_marker());
    blk.flags(TrimWhiteSpace | TrimAnnotations);
    EXPECT_TRUE(blk.apply_pass(new BFN::RewriteConcatToSlices()));
    auto res = blk.match(expected);
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count
                             << "\n    '" << blk.get_block(res.pos) << "'\n";
}
#endif

TEST(testBfGtestHelper, ControlBlockTestMatch) {
    auto blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy}, Marker);
    auto res = blk.match(CheckList{"apply", "{", "}"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count
                             << "\n    '" << blk.get_block() << "'\n";;
    // EXPECT_EQ(res.pos, 9U);   // Dependant upon parser.
    EXPECT_EQ(res.count, 3U);

    blk = TestCode(P4Include::Tofino1arch, Code, {EmptyDefs, EmptyAppy}, Marker);
    blk.flags(Raw);
    res = blk.match(CheckList{"`\\s*`apply`\\s*`{`\\s*`}`\\s*`"});
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count
                             << "\n    '" << blk.get_block() << "'\n";
    // EXPECT_EQ(res.pos, 16U);   // Dependant upon parser.
    EXPECT_EQ(res.count, 1U);
}

}  // namespace Test
