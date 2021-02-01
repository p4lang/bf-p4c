/*
 * This test tests whether the midend produces suitable output
 * for cast, slice, and concat statements used in the match key.
 * For this purpose, it fires the P4::SimplifyKeys and BFN::ElimCasts
 * passes.
 */

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/typeMap.h"
#include "midend/simplifyKey.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/simplify_key_policy.h"
#include "bf-p4c/midend/elim_cast.h"

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

namespace Test {

namespace {

auto defs = R"(
    match_kind {exact, ternary, lpm}
    @noWarn("unused") action NoAction() {}
    header Hdr { bit<8> field1; bit<8> field2; bit<16> field3; bit<32> field4;}
    struct Headers { Hdr h; })";

#define RUN_CHECK(pass, input, expected) do { \
    auto blk = TestCode::TestControlBlock(defs, input); \
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations); \
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
        new P4::SimplifyKey(refMap, typeMap,
            BFN::KeyIsSimple::getPolicy(*refMap, *typeMap), typeChecking),
        new BFN::ElimCasts(refMap, typeMap),
        new P4::ConstantFolding(refMap, typeMap, true, typeChecking)
    };
}

}  // namespace

TEST(SimplifyKeyElimCasts, KeyElementSlice) {
    auto input = R"(
        table dummy_table {
            key = {
                headers.h.field4[9:0]: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "headers.h.field4[9:0]: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "dummy_table_`\\2`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementNarrowingCast) {
    auto input = R"(
        table dummy_table {
            key = {
                (bit<12>)headers.h.field4: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<12> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "key_`\\2` = headers.h.field4[11:0];",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementWideningCast) {
    auto input = R"(
        table dummy_table {
            key = {
                (bit<63>)headers.h.field4: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<63> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "{",
                "bit<31> $concat_to_slice`(\\d+)`;",
                "bit<32> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\4` = 31w0;",
                "$concat_to_slice`\\5` = headers.h.field4;",
                "key_`\\2`[62:32] = $concat_to_slice`\\4`;",
                "key_`\\2`[31:0] = $concat_to_slice`\\5`;",
            "}",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementWideningCastSlice) {
    auto input = R"(
        table dummy_table {
            key = {
                ((bit<256>)headers.h.field4)[62:0]: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<63> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "{",
                "bit<31> $concat_to_slice`(\\d+)`;",
                "bit<32> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\4` = 31w0;",
                "$concat_to_slice`\\5` = headers.h.field4;",
                "key_`\\2`[62:32] = $concat_to_slice`\\4`;",
                "key_`\\2`[31:0] = $concat_to_slice`\\5`;",
            "}",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementWideningCastSliceNonzeroLsb) {
    auto input = R"(
        table dummy_table {
            key = {
                ((bit<256>)headers.h.field4)[62:15]: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<48> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "{",
                "bit<31> $concat_to_slice`(\\d+)`;",
                "bit<17> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\4` = 31w0;",
                "$concat_to_slice`\\5` = headers.h.field4[31:15];",
                "key_`\\2`[47:17] = $concat_to_slice`\\4`;",
                "key_`\\2`[16:0] = $concat_to_slice`\\5`;",
            "}",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementConcatConstantPathExpression) {
    auto input = R"(
        table dummy_table {
            key = {
                10w0 ++ headers.h.field4: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<42> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "{",
                "bit<10> $concat_to_slice`(\\d+)`;",
                "bit<32> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\4` = 10w0;",
                "$concat_to_slice`\\5` = headers.h.field4;",
                "key_`\\2`[41:32] = $concat_to_slice`\\4`;",
                "key_`\\2`[31:0] = $concat_to_slice`\\5`;",
            "}",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

TEST(SimplifyKeyElimCasts, KeyElementConcatPathExpressions) {
    auto input = R"(
        table dummy_table {
            key = {
                headers.h.field1 ++ headers.h.field4: exact @name("key");
            }
            actions = {
            }
        }
        apply {
            dummy_table.apply();
        })";
    Match::CheckList expected = {
        "action NoAction_`(\\d+)`() { }",
        "bit<40> key_`(\\d+)`;",
        "table dummy_table_`(\\d+)` {",
            "key = {",
                "key_`\\2`: exact ;",
            "}",
            "actions = {",
                "NoAction_`\\1`();",
            "}",
            "default_action = NoAction_`\\1`();",
        "}",
        "apply {",
            "{",
                "bit<8> $concat_to_slice`(\\d+)`;",
                "bit<32> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\4` = headers.h.field1;",
                "$concat_to_slice`\\5` = headers.h.field4;",
                "key_`\\2`[39:32] = $concat_to_slice`\\4`;",
                "key_`\\2`[31:0] = $concat_to_slice`\\5`;",
            "}",
            "dummy_table_`\\3`.apply();",
        "}"
    };
    RUN_CHECK(setup_passes(), input, expected);
}

}  // namespace Test
