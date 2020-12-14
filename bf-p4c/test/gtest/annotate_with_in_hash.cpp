/*
 * This test tests whether the @in_hash annotation is applied correctly
 * in the BFN::AnnotateWithInHash pass.
 */

#include "bf-p4c/midend/annotate_with_in_hash.h"

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/arch/arch.h"
#include "bf-p4c/bf-p4c-options.h"

namespace Test {

namespace {

auto defs = R"(
    header vlan_tag_h { bit<3> pcp; bit<1> cfi; bit<12> vid; bit<16> ether_type;}
    struct headers_t { vlan_tag_h vlan;}
    struct local_metadata_t { bit<6> index;})";

#define RUN_CHECK(pass, input, expected) do { \
    auto blk = TestCode(TestCode::Hdr::Tofino1arch, \
        TestCode::tofino_shell(), \
        {defs, TestCode::empty_state(), input, TestCode::empty_appy()}, \
        TestCode::tofino_shell_control_marker(), \
        {"-T", "annotate_with_in_hash:2"}); \
    blk.flags(Match::TrimWhiteSpace); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend)); \
    EXPECT_TRUE(blk.apply_pass(pass)); \
    auto res = blk.match(expected); \
    EXPECT_TRUE(res.success) << "    @ expected[" << res.count<< "], char pos=" << res.pos << "\n" \
                             << "    '" << expected[res.count] << "'\n" \
                             << "    '" << blk.extract_code(res.pos) << "'\n"; \
    } while (0)

Visitor *setup_passes() {
    auto refMap = new P4::ReferenceMap;
    auto typeMap = new P4::TypeMap;
    auto typeChecking = new BFN::TypeChecking(refMap, typeMap);
    return new PassManager {
        typeChecking,
        new BFN::ArchTranslation(refMap, typeMap, BackendOptions()),
        new BFN::AnnotateWithInHash(refMap, typeMap, typeChecking)
    };
}

}  // namespace

TEST(AnnotateWithInHash, actionKeyNoParam) {
    auto input = R"(
        action actionKeyNoParam() {
            ig_md.index = 3w0 ++ hdr.vlan.pcp + ig_md.index;
        }
        table tableKeyNoParam {
            key = { hdr.vlan.pcp : exact; }
            actions = { actionKeyNoParam; }
        }
        apply {
            tableKeyNoParam.apply();
        })";
    Match::CheckList expected {
        "@noWarn(\"unused\") @name(\".NoAction\") action NoAction_`(\\d+)`() { }",
        "@name(\"ingress_control.actionKeyNoParam\") action actionKeyNoParam() {",
            "@in_hash { ig_md.index = 3w0 ++ hdr.vlan.pcp + ig_md.index; }",
        "}",
        "@name(\"ingress_control.tableKeyNoParam\") table tableKeyNoParam_`(\\d+)` {",
            "key = {",
                "hdr.vlan.pcp: exact @name(\"hdr.vlan.pcp\") ;",
            "}",
            "actions = {",
                "actionKeyNoParam(); @defaultonly NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "tableKeyNoParam_`\\2`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

}  // namespace Test
