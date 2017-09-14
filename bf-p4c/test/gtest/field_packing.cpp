/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "bf-p4c/parde/field_packing.h"

namespace BFN {

TEST(TofinoFieldPacking, Fields) {
    FieldPacking packing;
    EXPECT_FALSE(packing.containsFields());
    EXPECT_TRUE(packing.fields.empty());
    EXPECT_EQ(0u, packing.totalWidth);

    // Any expression can serve as a field.
    auto* field1 = new IR::Constant(0);

    // Test adding one field.
    packing.appendField(field1, 10);
    EXPECT_TRUE(packing.containsFields());
    EXPECT_EQ(1u, packing.fields.size());
    EXPECT_EQ(10u, packing.totalWidth);
    EXPECT_EQ(field1, packing.fields.back().field);
    EXPECT_EQ(cstring(), packing.fields.back().source);
    EXPECT_EQ(10u, packing.fields.back().width);
    EXPECT_FALSE(packing.fields.back().isPadding());

    // Test adding a second field.
    auto* field2 = new IR::Constant(0);
    packing.appendField(field2, "field2", 1);
    EXPECT_TRUE(packing.containsFields());
    EXPECT_EQ(2u, packing.fields.size());
    EXPECT_EQ(11u, packing.totalWidth);
    EXPECT_EQ(field2, packing.fields.back().field);
    EXPECT_EQ(cstring("field2"), packing.fields.back().source);
    EXPECT_EQ(1u, packing.fields.back().width);
    EXPECT_FALSE(packing.fields.back().isPadding());

    // Test clearing all fields.
    packing.clear();
    EXPECT_FALSE(packing.containsFields());
    EXPECT_TRUE(packing.fields.empty());
    EXPECT_EQ(0u, packing.totalWidth);
}

TEST(TofinoFieldPacking, Padding) {
    FieldPacking packing;
    EXPECT_FALSE(packing.containsFields());
    EXPECT_TRUE(packing.fields.empty());
    EXPECT_EQ(0u, packing.totalWidth);

    // Test adding a chunk of padding.
    packing.appendPadding(10);
    EXPECT_FALSE(packing.containsFields());
    EXPECT_EQ(1u, packing.fields.size());
    EXPECT_EQ(10u, packing.totalWidth);
    EXPECT_TRUE(packing.fields.back().field == nullptr);
    EXPECT_EQ(cstring(), packing.fields.back().source);
    EXPECT_EQ(10u, packing.fields.back().width);
    EXPECT_TRUE(packing.fields.back().isPadding());

    // Two contiguous chunks of padding should be merged.
    packing.appendPadding(1);
    EXPECT_FALSE(packing.containsFields());
    EXPECT_EQ(1u, packing.fields.size());
    EXPECT_EQ(11u, packing.totalWidth);
    EXPECT_TRUE(packing.fields.back().field == nullptr);
    EXPECT_EQ(cstring(), packing.fields.back().source);
    EXPECT_EQ(11u, packing.fields.back().width);
    EXPECT_TRUE(packing.fields.back().isPadding());

    // A field should not be merged with padding.
    auto* field = new IR::Constant(0);
    packing.appendField(field, 5);
    EXPECT_TRUE(packing.containsFields());
    EXPECT_EQ(2u, packing.fields.size());
    EXPECT_EQ(16u, packing.totalWidth);
    EXPECT_EQ(field, packing.fields.back().field);
    EXPECT_EQ(cstring(), packing.fields.back().source);
    EXPECT_EQ(5u, packing.fields.back().width);
    EXPECT_FALSE(packing.fields.back().isPadding());

    // Two non-contiguous chunks of padding should be not merged.
    packing.appendPadding(8);
    EXPECT_TRUE(packing.containsFields());
    EXPECT_EQ(3u, packing.fields.size());
    EXPECT_EQ(24u, packing.totalWidth);
    EXPECT_TRUE(packing.fields.back().field == nullptr);
    EXPECT_EQ(cstring(), packing.fields.back().source);
    EXPECT_EQ(8u, packing.fields.back().width);
    EXPECT_TRUE(packing.fields.back().isPadding());

    // Test clearing all fields and padding.
    packing.clear();
    EXPECT_FALSE(packing.containsFields());
    EXPECT_TRUE(packing.fields.empty());
    EXPECT_EQ(0u, packing.totalWidth);
}

TEST(TofinoFieldPacking, ZeroPadding) {
    // Adding zero padding should have no effect.
    FieldPacking packing;
    packing.appendPadding(0);
    EXPECT_FALSE(packing.containsFields());
    EXPECT_TRUE(packing.fields.empty());
    EXPECT_EQ(0u, packing.totalWidth);
}

TEST(TofinoFieldPacking, EmptyPackingAlignment) {
    // An empty FieldPacking should be aligned to any number of bits. (Ignoring
    // phase, at least.) padToAlignment() should have no effect.
    for (unsigned alignment : { 1, 8, 16, 32 }) {
        SCOPED_TRACE(alignment);
        FieldPacking packing;
        EXPECT_TRUE(packing.isAlignedTo(alignment));
        packing.padToAlignment(alignment);
        EXPECT_EQ(0u, packing.totalWidth);
    }

    // An empty FieldPacking *isn't* aligned if the phase is non-zero, so
    // padToAlignment() should introduce padding bits.
    for (unsigned phase : { 0, 1, 2, 3, 4, 5, 6, 7 }) {
        SCOPED_TRACE(phase);
        FieldPacking packing;

        if (phase == 0)
            EXPECT_TRUE(packing.isAlignedTo(8, phase));
        else
            EXPECT_FALSE(packing.isAlignedTo(8, phase));

        packing.padToAlignment(8, phase);
        EXPECT_EQ(phase, packing.totalWidth);
    }
}

static void checkAlignment(const FieldPacking& packing, unsigned preAlignmentWidth,
                           unsigned alignment, unsigned phase) {
    // Check that the alignment is correct.
    EXPECT_EQ(phase, packing.totalWidth % alignment);

    // Check that we didn't add an unreasonable amount of padding. (Note
    // that this expression would need to change if the field's width
    // were greater than `alignment`.)
    EXPECT_LE(packing.totalWidth, alignment + phase);

    // If the phase is greater than the field width, we should've been
    // able to satisfy it without wrapping around to the next aligned
    // "chunk".
    if (phase > preAlignmentWidth)
        EXPECT_LE(packing.totalWidth, alignment);
}

TEST(TofinoFieldPacking, FieldAlignment) {
    // Check that we can correctly align a FieldPacking with a field in it.
    auto* field = new IR::Constant(0);
    for (unsigned alignment : { 8, 16, 32 }) {
        SCOPED_TRACE(alignment);
        for (unsigned phase : { 0, 1, 2, 3, 4, 5, 6, 7 }) {
            SCOPED_TRACE(phase);
            FieldPacking packing;
            const unsigned fieldWidth = 3;
            packing.appendField(field, fieldWidth);

            if (packing.isAlignedTo(alignment, phase)) {
                packing.padToAlignment(alignment, phase);
                EXPECT_EQ(fieldWidth, packing.totalWidth);
                EXPECT_EQ(1u, packing.fields.size());
                continue;
            }

            packing.padToAlignment(alignment, phase);
            EXPECT_TRUE(packing.containsFields());
            EXPECT_EQ(2u, packing.fields.size());
            checkAlignment(packing, fieldWidth, alignment, phase);
        }
    }
}

TEST(TofinoFieldPacking, PaddingAlignment) {
    // Check that we can correctly align a FieldPacking with padding in it.
    for (unsigned alignment : { 8, 16, 32 }) {
        SCOPED_TRACE(alignment);
        for (unsigned phase : { 0, 1, 2, 3, 4, 5, 6, 7 }) {
            SCOPED_TRACE(phase);
            FieldPacking packing;
            const unsigned paddingWidth = 3;
            packing.appendPadding(paddingWidth);

            if (packing.isAlignedTo(alignment, phase)) {
                packing.padToAlignment(alignment, phase);
                EXPECT_FALSE(packing.containsFields());
                EXPECT_EQ(paddingWidth, packing.totalWidth);
                EXPECT_EQ(1u, packing.fields.size());
                continue;
            }

            packing.padToAlignment(alignment, phase);
            EXPECT_FALSE(packing.containsFields());
            EXPECT_EQ(1u, packing.fields.size());
            checkAlignment(packing, paddingWidth, alignment, phase);
        }
    }
}

TEST(TofinoFieldPacking, ZeroAlignment) {
    // It's not clearly defined what aligning to zero bytes means, so we should
    // reject it.
    FieldPacking packing;
    packing.appendField(new IR::Constant(0), 3);
    ASSERT_ANY_THROW(packing.padToAlignment(0));
    ASSERT_ANY_THROW(packing.isAlignedTo(0));
}

TEST(TofinoFieldPacking, LargePhase) {
    // There are multiple reasonable approaches to handling a phase larger than
    // the alignment, but the simplest conceptually is just to take the phase
    // modulo the alignment, so that's what we'll do.
    FieldPacking packing;
    packing.appendField(new IR::Constant(0), 3);
    ASSERT_NO_THROW(packing.padToAlignment(8, 15));
    EXPECT_EQ(7u, packing.totalWidth);
}

TEST(TofinoFieldPacking, CreateExtractionState) {
    // Define a packing.
    FieldPacking packing;
    packing.appendPadding(3);
    auto* field1 = new IR::Constant(0);
    packing.appendField(field1, 6);
    auto* field2 = new IR::Constant(0);
    packing.appendField(field2, 15);
    packing.appendPadding(9);
    auto* field3 = new IR::Constant(0);
    packing.appendField(field3, 8);
    packing.padToAlignment(8);

    // Create a parser state to extract fields according to that packing.
    auto gress = INGRESS;
    auto* finalState = new IR::BFN::ParserState("final", gress, { }, { });
    cstring extractionStateName = "extract";
    auto* extractionState =
      packing.createExtractionState(gress, extractionStateName, finalState);

    // Verify that all of the state metadata (its name, the next state, the
    // amount it shifts, etc.) is correct.
    ASSERT_TRUE(extractionState != nullptr);
    EXPECT_EQ(extractionStateName, extractionState->name);
    EXPECT_EQ(gress, extractionState->gress);
    EXPECT_EQ(0u, extractionState->select.size());
    ASSERT_EQ(1u, extractionState->match.size());
    EXPECT_EQ(finalState, extractionState->match[0]->next);
    EXPECT_TRUE(extractionState->match[0]->shift);
    EXPECT_EQ(static_cast<int>((packing.totalWidth / 8)), *extractionState->match[0]->shift);

    // Verify that the state reproduces the packing and has the structure we
    // expect. Note that padding isn't represented as a separate IR object; it's
    // implicit in the range of bits read by an ExtractBuffer.
    auto& extracts = extractionState->match[0]->stmts;
    ASSERT_EQ(3u, extracts.size());

    auto* field1Extract = extracts[0]->to<IR::BFN::ExtractBuffer>();
    ASSERT_TRUE(field1Extract != nullptr);
    ASSERT_TRUE(field1Extract->dest == field1);
    ASSERT_TRUE(field1Extract->extractedBits() == nw_bitrange(3, 8));

    auto* field2Extract = extracts[1]->to<IR::BFN::ExtractBuffer>();
    ASSERT_TRUE(field2Extract != nullptr);
    ASSERT_TRUE(field2Extract->dest == field2);
    ASSERT_TRUE(field2Extract->extractedBits() == nw_bitrange(9, 23));

    auto* field3Extract = extracts[2]->to<IR::BFN::ExtractBuffer>();
    ASSERT_TRUE(field3Extract != nullptr);
    ASSERT_TRUE(field3Extract->dest == field3);
    ASSERT_TRUE(field3Extract->extractedBits() == nw_bitrange(33, 40));
}

}  // namespace BFN
