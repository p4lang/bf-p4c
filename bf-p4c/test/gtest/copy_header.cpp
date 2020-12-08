#include "bf-p4c/midend/copy_header.h"

#include "bf-p4c/midend/type_checker.h"
#include "frontends/p4/simplifyParsers.h"
#include "bf-p4c/midend/elim_cast.h"

#include "bf_gtest_helpers.h"
#include "gtest/gtest.h"

namespace Test {

namespace {

auto defs = R"(
    struct local_metadata_t {}
    header Hdr {
        bit<8> data;
    }
    struct headers_t {
        Hdr h;
        Hdr unused;
    }
    parser Indirect1(packet_in packet, out headers_t hdr) {
        state start {
            packet.extract(hdr.h);
            transition accept;
        }
    }
    parser Indirect2(packet_in packet, out headers_t hdr) {
        Indirect1() indirect1;
        state start {
            indirect1.apply(packet, hdr);
            transition accept;
        }
    })";

auto depaser = "apply{packet.emit(hdr);}";

// We need to first `SimplifyParsers` viz collapse the states into a single state{} block.
// Then we apply the CopyHeaders, which will not add redundant $valid assignments.
// The single $valid=0 assignments will then be correctly handled by the back-end.
#define RUN_TEST(parser, output) \
    do { \
    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(), \
                   {defs, parser, TestCode::empty_appy(), depaser}, \
                   TestCode::tofino_shell_parser_marker()); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend)); \
    P4::ReferenceMap refMap; \
    refMap.setIsV1(true); \
    P4::TypeMap typeMap; \
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap, true); \
    EXPECT_TRUE(blk.apply_pass(typeChecking)); \
    EXPECT_TRUE(blk.apply_pass(new P4::SimplifyParsers(&refMap))); \
    EXPECT_TRUE(blk.apply_pass(new BFN::CopyHeaders(&refMap, &typeMap, typeChecking))); \
    auto res = blk.match(output); \
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count \
                             << "\n    '" << blk.extract_code() << "'\n"; \
    } while (0)

}  // namespace

TEST(CopyHeaders, IgnoreUnusedHeaderInline) {
    auto parser = R"(
        state start {
            packet.extract(hdr.h);
            transition accept;
        })";
    Match::CheckList output {
        "state start {",
            "packet.extract<Hdr>(hdr.h);",
            "transition accept;",
        "}"
    };
    RUN_TEST(parser, output);
}

TEST(CopyHeaders, IgnoreUnusedHeaderIndirect1) {
    auto parser = R"(
        Indirect1() indirect;
        state start {
            indirect.apply(packet, hdr);
            transition accept;
        })";
    Match::CheckList output {
        "state start {",
            "hdr.h.$valid = 1w0;",
            "hdr.unused.$valid = 1w0;",
            "packet.extract<Hdr>(hdr.h);",
            "transition accept;",
        "}"
    };
    RUN_TEST(parser, output);
}

TEST(CopyHeaders, IgnoreUnusedHeaderIndirect2) {
    auto parser = R"(
        Indirect2() indirect;
        state start {
            indirect.apply(packet, hdr);
            transition accept;
        })";
    Match::CheckList output {
        "state start {",
            "hdr.h.$valid = 1w0;",
            "hdr.unused.$valid = 1w0;",
            "packet.extract<Hdr>(hdr.h);",
            "transition accept;",
        "}"
    };
    RUN_TEST(parser, output);
}

TEST(CopyHeaders, Lower$valid) {
    auto defs = R"(
        match_kind {exact}    // We will use TofinoMin, so pull in a couple of extras.
        action NoAction() {}
        header H { bit<1> field; bool boolean;}
        struct headers_t { H[2] h; }
        struct local_metadata_t {} )";

    auto input = R"(
        action act() {}
        table tbl {
            key = {
                hdr.h[0].field: exact;
                hdr.h[1].boolean: exact;
                hdr.h[0].isValid(): exact;
            }
            actions = {
                act;
            }
            const entries = {
                (1, true, true): act();  // isValid setting will be changed to bit<1>.
                (_, true, _):    act();  // isValid setting will remain 'default'.
                (0, _, false):   act();  // other fields remain the same.
            }
        }
        apply {
            if (false == hdr.h[0].isValid()) {  // Maintain bool type.
                hdr.h[0].isValid();     // Noop removed.
                hdr.h[0].setInvalid();
                hdr.h[0].setInvalid();
                tbl.apply();
                hdr.h[0].setInvalid();  // replaceValidMethod() will remove all but one.
            }
            if (1w1 == (bit<1>)hdr.h[0].isValid()) {  // Maintain cast type.
                hdr.h[0].setInvalid();
                hdr.h[0].setValid();    // replaceValidMethod() will keep this toggling.
                hdr.h[0].setInvalid();
            }
        })";
    Match::CheckList expected {
        "action NoAction_0() { }",
        "action act() { }",
        "table tbl_0 {",
            "key = {",
                "hdr.h[0].field : exact ;",
                "hdr.h[1].boolean: exact ;",
                "hdr.h[0].$valid : exact ;",
            "}",
            "actions = {",
                "act();",
                "NoAction_0();",
            "}",
            "const entries = {",
                "(1w1, true, 1w1) : act();",
                "(default, true, default) : act();",
                "(1w0, default, 1w0) : act();",
            "}",
            "default_action = NoAction_0();",
        "}",
        "apply {",
            "if (false == (hdr.h[0].$valid == 1w1)) {",
                "hdr.h[0].$valid = 1w0;",
                "tbl_0.apply();",
            "}",
            "if (1w1 == (bit<1>)hdr.h[0].$valid) {",
                "hdr.h[0].$valid = 1w0;",
                "hdr.h[0].$valid = 1w1;",
                "hdr.h[0].$valid = 1w0;",
            "}",
        "}",
    };

    auto blk = TestCode(TestCode::Hdr::TofinoMin, TestCode::tofino_shell(),
                        {defs, TestCode::empty_state(), input, TestCode::empty_appy()},
                        TestCode::tofino_shell_control_marker());
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations);
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend));
    P4::ReferenceMap refMap;
    refMap.setIsV1(true);
    P4::TypeMap typeMap;
    auto typeChecking = new BFN::TypeChecking(&refMap, &typeMap, true);
    EXPECT_TRUE(blk.apply_pass(typeChecking));
    EXPECT_TRUE(blk.apply_pass(new BFN::ElimCasts(&refMap, &typeMap)));
    EXPECT_TRUE(blk.apply_pass(new P4::SimplifyParsers(&refMap)));
    EXPECT_TRUE(blk.apply_pass(new BFN::CopyHeaders(&refMap, &typeMap, typeChecking)));
    auto res = blk.match(expected);
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count
                             << "\n    '" << blk.extract_code(res.pos) << "'\n";
}


}  // namespace Test