#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/parde/bridge_metadata.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class TofinoFieldAlignment : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createFieldAlignmentTestCase(const std::string& headerSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H {
%HEADER_SOURCE%
        }
        struct Headers { H h; }
        struct Metadata { }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
                packet.extract(headers.h);
                transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {
                packet.emit(headers.h);
            }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%HEADER_SOURCE%", headerSource);

    return TofinoPipeTestCase::create(source);
}

struct ExpectedAlignment {
    unsigned network;
    unsigned littleEndian;
};

/// A map from field names to expected alignment values. The expected alignment
/// is optional; if it's boost::none, then the field's alignment value must also
/// be boost::none - in other words, no particular alignment constraint should
/// have been inferred.
using ExpectedAlignmentMap = std::map<cstring, boost::optional<ExpectedAlignment>>;


/// Given a Tofino program, infer alignments for its fields and check that they
/// agree with the alignments we expect.
void checkFieldAlignment(const IR::BFN::Pipe* pipe,
                         const ExpectedAlignmentMap& expected) {
    PhvInfo phv;
    PassManager computeAlignment = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv)
    };
    pipe->apply(computeAlignment);

    for (auto& item : expected) {
        auto fieldName = item.first;
        auto expectedAlignment = item.second;
        SCOPED_TRACE(fieldName);

        auto* fieldInfo = phv.field(fieldName);
        ASSERT_TRUE(fieldInfo != nullptr);

        if (!expectedAlignment) {
            EXPECT_TRUE(!fieldInfo->alignment);
            continue;
        }

        ASSERT_TRUE(fieldInfo->alignment);
        EXPECT_EQ(expectedAlignment->network, fieldInfo->alignment->network);
        EXPECT_EQ(expectedAlignment->littleEndian,
                  fieldInfo->alignment->littleEndian);
    }
}

}  // namespace

TEST_F(TofinoFieldAlignment, ByteAlignedFields) {
    auto test = createFieldAlignmentTestCase(P4_SOURCE(P4Headers::NONE, R"(
        bit<8> field1;
        bit<16> field2;
        bit<32> field3;
        bit<64> field4;
        bit<8> field5;
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    checkFieldAlignment(test->pipe, {
        { "h.field1", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "h.field2", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "h.field3", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "h.field4", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "h.field5", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
    });
}

TEST_F(TofinoFieldAlignment, SmallUnalignedFields) {
    auto test = createFieldAlignmentTestCase(P4_SOURCE(P4Headers::NONE, R"(
        bit<1> field1;
        bit<3> field2;
        bit<4> field3;
        bit<5> field4;
        bit<5> field5;
        bit<6> field6;
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    checkFieldAlignment(test->pipe, {
        { "h.field1", ExpectedAlignment{/* network */ 0, /* little endian */ 7} },
        { "h.field2", ExpectedAlignment{/* network */ 1, /* little endian */ 4} },
        { "h.field3", ExpectedAlignment{/* network */ 4, /* little endian */ 0} },
        { "h.field4", ExpectedAlignment{/* network */ 0, /* little endian */ 3} },
        { "h.field5", ExpectedAlignment{/* network */ 5, /* little endian */ 6} },
        { "h.field6", ExpectedAlignment{/* network */ 2, /* little endian */ 0} },
    });
}

TEST_F(TofinoFieldAlignment, LargeUnalignedFields) {
    auto test = createFieldAlignmentTestCase(P4_SOURCE(P4Headers::NONE, R"(
        bit<7> field1;
        bit<9> field2;
        bit<17> field3;
        bit<36> field4;
        bit<11> field5;
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    checkFieldAlignment(test->pipe, {
        { "h.field1", ExpectedAlignment{/* network */ 0, /* little endian */ 1} },
        { "h.field2", ExpectedAlignment{/* network */ 7, /* little endian */ 0} },
        { "h.field3", ExpectedAlignment{/* network */ 0, /* little endian */ 7} },
        { "h.field4", ExpectedAlignment{/* network */ 1, /* little endian */ 3} },
        { "h.field5", ExpectedAlignment{/* network */ 5, /* little endian */ 0} },
    });
}

TEST_F(TofinoFieldAlignment, NonPardeFieldsDoNotForceAlignment) {
    auto test = TofinoPipeTestCase::create(P4_SOURCE(P4Headers::V1MODEL, R"(
        header H {
            bit<8> field;
        }
        struct Headers { H usedInParser; H usedOnlyInMAU; H unused; }
        struct Metadata { bit<8> metadataField; }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
                meta.metadataField = 1;
                packet.extract(headers.usedInParser);
                transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                    inout standard_metadata_t sm) {
            apply {
                headers.usedOnlyInMAU.field = 1;
                headers.usedInParser.field = headers.usedOnlyInMAU.field;
            }
        }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {
                packet.emit(headers.usedInParser);
            }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    checkFieldAlignment(test->pipe, {
        { "usedInParser.field", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "usedOnlyInMAU.field", boost::none },
        { "meta.metadataField", boost::none },
    });
}

TEST_F(TofinoFieldAlignment, BridgedMetadataRespectsAlignment) {
    auto test = TofinoPipeTestCase::create(P4_SOURCE(P4Headers::V1MODEL, R"(
        header H { bit<8> field; }
        struct Headers { H h; }
        struct Metadata { bit<8> metadataField; }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
                packet.advance(3);
                // This is really an extract of bits [3, 11) of the input buffer.
                meta.metadataField = packet.lookahead<bit<8>>();
                packet.advance(5);
                transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control ingress(inout Headers headers, inout Metadata meta,
                    inout standard_metadata_t sm) { apply { } }

        control egress(inout Headers headers, inout Metadata meta,
                    inout standard_metadata_t sm) {
            apply {
                headers.h.field = meta.metadataField;
            }
        }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {
                packet.emit(headers.h);
            }
        }

        V1Switch(parse(), verifyChecksum(), ingress(), egress(),
                 computeChecksum(), deparse()) main;
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    // We need to run enough of the backend to generate the bridged metadata
    // parser state.
    PhvInfo phv;
    FieldDefUse defuse(phv);
    PassManager addBridgedMetadataParserState = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        &defuse,
        new AddBridgedMetadata(phv, defuse)
    };
    auto* pipe = test->pipe->apply(addBridgedMetadataParserState);

    // Check that we computed the correct alignments.
    checkFieldAlignment(pipe, {
        { "h.field", ExpectedAlignment{/* network */ 0, /* little endian */ 0} },
        { "meta.metadataField", ExpectedAlignment{/* network */ 3, /* little endian */ 5} },
    });

    // If the generated bridged metadata parser state used the wrong alignment,
    // CollectPhvInfo() will report an error because it will detect inconsistent
    // alignments.
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());

    // Verify that the generated parser state contains an extract for
    // `meta.metadataField` with the correct alignment.
    bool foundBridgedMetadataState = false;
    forAllMatching<IR::BFN::ParserState>(pipe->thread[EGRESS].parser,
                  [&](const IR::BFN::ParserState* state) {
        if (state->name != "$bridge_metadata_extract") return;
        foundBridgedMetadataState = true;

        ASSERT_EQ(1u, state->statements.size());
        auto* extract = state->statements[0]->to<IR::BFN::Extract>();
        ASSERT_TRUE(extract != nullptr);
        EXPECT_EQ("meta.metadataField", extract->dest->field->toString());
        auto* bufferSource = extract->source->to<IR::BFN::PacketRVal>();
        ASSERT_TRUE(bufferSource != nullptr);
        EXPECT_EQ(3, bufferSource->extractedBits().lo % 8);
    });

    EXPECT_TRUE(foundBridgedMetadataState);
}

}  // namespace Test
