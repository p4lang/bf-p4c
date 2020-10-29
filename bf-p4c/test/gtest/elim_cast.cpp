#include "bf-p4c/midend/elim_cast.h"

#include "gtest/gtest.h"
#include "bf_gtest_helpers.h"

namespace Test {

namespace {

auto defs = R"(
    header Hdr { bit<8> field1; bit<8> field2; bit<16> field3; bit<32> field4;}
    struct Headers { Hdr h; })";

#define RUN_CHECK(pass, input, expected) do { \
    auto blk = TestCode::TestControlBlock(defs, input); \
    blk.flags(Match::TrimWhiteSpace | Match::TrimAnnotations); \
    EXPECT_TRUE(blk.apply_pass(TestCode::Pass::FullFrontend)); \
    EXPECT_TRUE(blk.apply_pass(pass)); \
    auto res = blk.match(expected); \
    EXPECT_TRUE(res.success) << " pos=" << res.pos << " count=" << res.count \
                             << "\n    '" << blk.get_block() << "'\n"; \
    } while (0)

}  // namespace

////// Equ ///////////////////////////////////////////////////

TEST(ElimCast, EquNone) {
    auto input = R"(
        apply {
            if (headers.h.field1 == headers.h.field2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (headers.h.field1 == headers.h.field2) {",
                "headers.h.field4 = 32w0;",
            "}",
        "}"
    };

    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquLeft) {
    auto input = R"(
        apply {
            if (headers.h.field1 ++ headers.h.field2 == 16w0x0102) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (headers.h.field1 == 8w1 && headers.h.field2 == 8w2) {",
                "headers.h.field4 = 32w0;",
            "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquRight) {
    auto input = R"(
        apply {
            if (16w0x0102 == headers.h.field1 ++ headers.h.field2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 == headers.h.field1 && 8w2 == headers.h.field2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquLeftRightSymmetric) {
    auto input = R"(
        apply {
            if (8w1 ++ headers.h.field2 == headers.h.field1 ++ 8w2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 == headers.h.field1 && headers.h.field2 == 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquLeftRightAsymmetric) {
    auto input = R"(
        apply {
            if (16w0x0100 ++ headers.h.field2 == headers.h.field1 ++ 16w2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 == headers.h.field1 && 8w0 == 8w0 && headers.h.field2 == 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquSubExpression) {
    auto input = R"(
        apply {
            if ( (16w0x0303 & ((8w5 & headers.h.field1) ++ headers.h.field2))& 16w0x0202
                    == 16w0x0102 ) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w3 & (8w5 & headers.h.field1) & 8w2 == 8w1 && ",
                "8w3 & headers.h.field2 & 8w2 == 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, EquSubExpressionPlus) {
    auto input = R"(
        apply {
            if ( (16w0x0303 + ((8w5 & headers.h.field1) ++ headers.h.field2)) & 16w0x0202
                    == 16w0x0102 ) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply { {",
           "bit<16> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1`[15:8] = 8w5 & headers.h.field1;",
            "$concat_to_slice`\\1`[7:0] = headers.h.field2;",
            "if (16w0x303 + $concat_to_slice`\\1` & 16w0x202 == 16w0x102) {",
                "headers.h.field4 = 32w0;",
            " }",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

////// Neq ///////////////////////////////////////////////////

TEST(ElimCast, NeqNone) {
    auto input = R"(
        apply {
            if (headers.h.field1 != headers.h.field2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (headers.h.field1 != headers.h.field2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, NeqLeft) {
    auto input = R"(
        apply {
            if (headers.h.field1 ++ headers.h.field2 != 16w0x0102) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (headers.h.field1 != 8w1 || headers.h.field2 != 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, NeqRight) {
    auto input = R"(
        apply {
            if (16w0x0102 != headers.h.field1 ++ headers.h.field2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 != headers.h.field1 || 8w2 != headers.h.field2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, NeqLeftRightSymmetric) {
    auto input = R"(
        apply {
            if (8w1 ++ headers.h.field2 != headers.h.field1 ++ 8w2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 != headers.h.field1 || headers.h.field2 != 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, NeqLeftRightAsymmetric) {
    auto input = R"(
        apply {
            if (16w0x0100 ++ headers.h.field2 != headers.h.field1 ++ 16w2) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w1 != headers.h.field1 || 8w0 != 8w0 || headers.h.field2 != 8w2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, NeqSubExpression) {
    auto input = R"(
        apply {
            if ( (08w0 ++ headers.h.field1) != 16w3 & (8w0 ++ headers.h.field2) ) {
                headers.h.field4 = 32w0;
            }
        })";
    Match::CheckList expected {
        "apply {",
            "if (8w0 != 8w0 & 8w0 || headers.h.field1 != 8w3 & headers.h.field2) {",
                "headers.h.field4 = 32w0;",
             "}",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

////// AssignmentStatement /////////////////////////////////////////

TEST(ElimCast, AssignNone) {
    auto input = R"(
        apply {
            headers.h.field1 = headers.h.field2;
        })";
    Match::CheckList expected {
        "apply {",
            "headers.h.field1 = headers.h.field2;",
        "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignConcat) {
    auto input = R"(
        apply {
            headers.h.field3 = headers.h.field1 ++ headers.h.field2;
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = headers.h.field1;",
            "$concat_to_slice`\\2` = headers.h.field2;",
            "headers.h.field3[15:8] = $concat_to_slice`\\1`;",
            "headers.h.field3[7:0] = $concat_to_slice`\\2`;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignZeroExtSliceable) {
    auto input = R"(
        apply {
            headers.h.field3 = 16w3 & (8w0 ++ headers.h.field2);
        })";
    // No change...
    Match::CheckList expected = {
        "apply { {",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = 8w0 & 8w0;",
            "$concat_to_slice`\\2` = 8w3 & headers.h.field2;",
            "headers.h.field3[15:8] = $concat_to_slice`\\1`;",
            "headers.h.field3[7:0] = $concat_to_slice`\\2`;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignZeroExtNonSliceable) {
    auto input = R"(
        apply {
            headers.h.field3 = 16w3 + (8w0 ++ headers.h.field2);
        })";
    // No change.
    // Is this correct? It seems it is what is expected in the backend.
    Match::CheckList expected = {
        "apply {",
            "headers.h.field3 = 16w3 + (8w0 ++ headers.h.field2);",
      "}"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignMultiple) {
    auto input = R"(
        apply {
            headers.h.field3 = (headers.h.field1[7:4] ++ headers.h.field1[3:0]) ++
                               (headers.h.field2[7:4] ++ headers.h.field2[3:0]);
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = headers.h.field1[7:4];",
            "$concat_to_slice`\\2` = headers.h.field1[3:0];",
            "$concat_to_slice`\\3` = headers.h.field2[7:4];",
            "$concat_to_slice`\\4` = headers.h.field2[3:0];",
            "headers.h.field3[15:12] = $concat_to_slice`\\1`;",
            "headers.h.field3[11:8] = $concat_to_slice`\\2`;",
            "headers.h.field3[7:4] = $concat_to_slice`\\3`;",
            "headers.h.field3[3:0] = $concat_to_slice`\\4`;",
      "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignSubexpr) {
    auto input = R"(
        apply {
            headers.h.field3 =
                (16w0x0102 & (16w0x0304 | headers.h.field1 ++ (8w3 & (8w2 | headers.h.field2))));
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = 8w1 & (8w3 | headers.h.field1);",
            "$concat_to_slice`\\2` = 8w2 & (8w4 | 8w3 & (8w2 | headers.h.field2));",
            "headers.h.field3[15:8] = $concat_to_slice`\\1`;",
            "headers.h.field3[7:0] = $concat_to_slice`\\2`;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignSubexprPlus) {
    auto input = R"(
        apply {
            headers.h.field4 = 16w0 ++
                (16w0x0102 & (16w0x0304 | headers.h.field1 ++ (8w3 & (8w2 | headers.h.field2))));
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = 16w0;",
            "$concat_to_slice`\\2` = 8w1 & (8w3 | headers.h.field1);",
            "$concat_to_slice`\\3` = 8w2 & (8w4 | 8w3 & (8w2 | headers.h.field2));",
            "headers.h.field4[31:16] = $concat_to_slice`\\1`;",
            "headers.h.field4[15:8] = $concat_to_slice`\\2`;",
            "headers.h.field4[7:0] = $concat_to_slice`\\3`;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignSubexprNonLogical) {
    auto input = R"(
        apply {
            headers.h.field3 =
                ((headers.h.field1 ++ headers.h.field2) << 8 +
                (headers.h.field1 ++ headers.h.field2) >> headers.h.field3);
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1`[15:8] = headers.h.field1;",
            "$concat_to_slice`\\1`[7:0] = headers.h.field2;",
            "$concat_to_slice`\\2`[15:8] = headers.h.field1;",
            "$concat_to_slice`\\2`[7:0] = headers.h.field2;",
            "headers.h.field3 = $concat_to_slice`\\1` << 16w8 +",
                               "$concat_to_slice`\\2` >> headers.h.field3;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignSubexprNonLogicalPlus) {
    auto input = R"(
        apply {
            headers.h.field4 = 16w0 ++
                    ((headers.h.field1 ++ headers.h.field2) << 8 +
                    (headers.h.field1 ++ headers.h.field2) >> headers.h.field3);
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1`[15:8] = headers.h.field1;",
            "$concat_to_slice`\\1`[7:0] = headers.h.field2;",
            "$concat_to_slice`\\2`[15:8] = headers.h.field1;",
            "$concat_to_slice`\\2`[7:0] = headers.h.field2;",
             "{",
                "bit<16> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\3` = $concat_to_slice`\\1` << 16w8 +",
                                        "$concat_to_slice`\\2` >> headers.h.field3;",
                "{",
                    "bit<16> $concat_to_slice`(\\d+)`;",
                    "bit<16> $concat_to_slice`(\\d+)`;",
                    "$concat_to_slice`\\4` = 16w0;",
                    "$concat_to_slice`\\5` = $concat_to_slice`\\3`;",
                    "headers.h.field4[31:16] = $concat_to_slice`\\4`;",
                    "headers.h.field4[15:0] = $concat_to_slice`\\5`;",
                "}",
            "}",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignSwap) {
    auto input = R"(
        apply {
            headers.h.field3 = headers.h.field3[3:0] ++ headers.h.field3[7:4] ++
                           headers.h.field3[11:8] ++ headers.h.field3[15:12];
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "bit<4> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = headers.h.field3[3:0];",
            "$concat_to_slice`\\2` = headers.h.field3[7:4];",
            "$concat_to_slice`\\3` = headers.h.field3[11:8];",
            "$concat_to_slice`\\4` = headers.h.field3[15:12];",
            "headers.h.field3[15:12] = $concat_to_slice`\\1`;",
            "headers.h.field3[11:8] = $concat_to_slice`\\2`;",
            "headers.h.field3[7:4] = $concat_to_slice`\\3`;",
            "headers.h.field3[3:0] = $concat_to_slice`\\4`;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

TEST(ElimCast, AssignCast) {
    auto input = R"(
        apply {
            headers.h.field3 = (bit<16>)(8w3 & headers.h.field1);
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "bit<8> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = 8w0;",
            "$concat_to_slice`\\2` = 8w3 & headers.h.field1;",
            "headers.h.field3[15:8] = $concat_to_slice`\\1`;",
            "headers.h.field3[7:0] = $concat_to_slice`\\2`;",
        "} }"
    };
    auto pass = PassManager {
        new BFN::EliminateWidthCasts(),  // First add the concat.
        new BFN::RewriteConcatToSlices()
    };
    RUN_CHECK(&pass, input, expected);
}

TEST(ElimCast, AssignCastSubexpression) {
    auto input = R"(
        apply {
            headers.h.field3 = (bit<16>)(8w3 & headers.h.field1) &  // sliceable
                            ((bit<16>)(headers.h.field2)) << 4;     // nonsliceable
        })";
    // TODO How should this expression be sliced & diced?
    Match::CheckList expected = {
        "apply { {",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1` = 8w0 ++ headers.h.field2 << 4;",   // dice nonsliceable.
            "{",
                "bit<8> $concat_to_slice`(\\d+)`;",
                "bit<8> $concat_to_slice`(\\d+)`;",
                "$concat_to_slice`\\2` = 8w0 & $concat_to_slice`\\1`[15:8];",
                "$concat_to_slice`\\3` = 8w3 & headers.h.field1 & $concat_to_slice`\\1`[7:0];",
                "headers.h.field3[15:8] = $concat_to_slice`\\2`;",
                "headers.h.field3[7:0] = $concat_to_slice`\\3`;",
            "}",
        "} }"
    };
    auto pass = PassManager {
        new BFN::EliminateWidthCasts(),  // First add the concat.
        new BFN::RewriteConcatToSlices()
    };
    RUN_CHECK(&pass, input, expected);
}

TEST(ElimCast, AssignFunnelShift) {
    // We remove FunnelShift expressions.
    auto input = R"(
        apply {
            headers.h.field3 = (headers.h.field1 ++ headers.h.field2) << 8;
        })";
    Match::CheckList expected = {
        "apply { {",
            "bit<16> $concat_to_slice`(\\d+)`;",
            "$concat_to_slice`\\1`[15:8] = headers.h.field1;",
            "$concat_to_slice`\\1`[7:0] = headers.h.field2;",
            "headers.h.field3 = $concat_to_slice`\\1` << 8;",
        "} }"
    };
    RUN_CHECK(new BFN::RewriteConcatToSlices(), input, expected);
}

}  // namespace Test
