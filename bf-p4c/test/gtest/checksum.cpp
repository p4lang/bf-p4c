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

#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "tofino/common/header_stack.h"
#include "tofino/phv/phv_fields.h"
#include "tofino/phv/trivial_alloc.h"
#include "tofino/test/gtest/tofino_gtest_utils.h"

namespace Test {

namespace {

boost::optional<TofinoPipeTestCase>
createComputedChecksumTestCase(const std::string& computeChecksumSource,
                               const std::string& deparserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H { bit<8> field1; bit<16> field2; bit<16> checksum; bit<32> field3; }
        struct Headers { H h1; H h2; }
        struct Metadata { H h; }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                 inout standard_metadata_t sm) {
            state start {
                packet.extract(headers.h1);
                packet.extract(headers.h2);
                transition accept;
            }
        }

        control verifyChecksum(in Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                    inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) {
            Checksum16() checksum;
            apply {
%COMPUTE_CHECKSUM_SOURCE%
            }
        }

        control deparse(packet_out packet, in Headers headers) {
            apply {
%DEPARSER_SOURCE%
            }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%COMPUTE_CHECKSUM_SOURCE%", computeChecksumSource);
    boost::replace_first(source, "%DEPARSER_SOURCE%", deparserSource);

    return TofinoPipeTestCase::create(source);
}

void checkComputedChecksum(const IR::Tofino::Pipe* pipe,
                           const std::vector<cstring>& expected) {
    for (auto gress : { INGRESS, EGRESS }) {
        auto& actual = pipe->thread[gress].deparser->emits;

        for (size_t i = 0; i < expected.size(); ++i) {
            if (i >= actual.size()) {
                ADD_FAILURE() << "#" << i << " Missing: " << expected[i] << std::endl;
                continue;
            }

            if (expected[i] != cstring::to_cstring(actual[i]))
                ADD_FAILURE() << "#" << i << " Expected: " << expected[i] << std::endl
                              << "#" << i << " Actual: " << cstring::to_cstring(actual[i])
                              << std::endl;
        }

        for (auto i = expected.size(); i < actual.size(); ++i)
            ADD_FAILURE() << "#" << i << " Unexpected: " << expected[i] << std::endl;
    }
}

}  // namespace

TEST(TofinoComputedChecksum, SimpleWithIsValid) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        if (headers.h1.isValid()) {
            headers.h1.checksum = checksum.get({
                headers.h1.field1,
                headers.h1.field3
            });
        }
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid"
    });
}

TEST(TofinoComputedChecksum, SimpleWithoutIsValid) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid"
    });
}

TEST(TofinoComputedChecksum, DuplicateHeader) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h2.checksum = checksum.get({
            headers.h2.field1,
            headers.h2.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
        packet.emit(headers.h2);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit h1.checksum if h1.$valid",  // We didn't compute this one.
        "emit h1.field3 if h1.$valid",

        "emit h2.field1 if h2.$valid",
        "emit h2.field2 if h2.$valid",
        "emit checksum { h2.field1, h2.field3 } if h2.$valid",
        "emit h2.field3 if h2.$valid"
    });
}

TEST(TofinoComputedChecksum, DuplicateHeader2) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h2.checksum = checksum.get({
            headers.h2.field1,
            headers.h2.field3
        });
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
        packet.emit(headers.h2);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid",

        "emit h2.field1 if h2.$valid",
        "emit h2.field2 if h2.$valid",
        "emit checksum { h2.field1, h2.field3 } if h2.$valid",
        "emit h2.field3 if h2.$valid"
    });
}

TEST(TofinoComputedChecksum, NotEmitted) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h2.checksum = checksum.get({
            headers.h2.field1,
            headers.h2.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit h1.checksum if h1.$valid",
        "emit h1.field3 if h1.$valid"
    });
}

TEST(TofinoComputedChecksum, EmittedTwice) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid",

        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid",
    });
}

TEST(TofinoComputedChecksum, ChecksumFieldInChecksum) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.checksum,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit h1.field2 if h1.$valid",
        "emit checksum { h1.field1, h1.checksum, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid"
    });
}

TEST(TofinoComputedChecksum, MultipleChecksumsInOneHeader) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field2,
            headers.h1.field3
        });
        headers.h1.field2 = checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    ASSERT_TRUE(test);
    EXPECT_EQ(0u, ::ErrorReporter::instance.getDiagnosticCount());
    checkComputedChecksum(test->pipe, {
        "emit h1.field1 if h1.$valid",
        "emit checksum { h1.field1, h1.field3 } if h1.$valid",
        "emit checksum { h1.field2, h1.field3 } if h1.$valid",
        "emit h1.field3 if h1.$valid"
    });
}

TEST(TofinoComputedChecksum, ErrorEmptyChecksum) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({});
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorIsValidMismatch) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        if (headers.h2.isValid()) {
            headers.h1.checksum = checksum.get({
                headers.h1.field1,
                headers.h1.field3
            });
        }
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorDestFieldMismatch) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        if (headers.h1.isValid()) {
            headers.h2.checksum = checksum.get({
                headers.h1.field1,
                headers.h1.field3
            });
        }
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorSourceFieldMismatch) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        if (headers.h1.isValid()) {
            headers.h1.checksum = checksum.get({
                headers.h1.field1,
                headers.h2.field3
            });
        }
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorSourceFieldMismatchWithoutIsValid) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h2.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorDestFieldNot16Bit) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.field1 = (bit<8>)checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorUnexpectedStatement) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
        headers.h1.field2 = headers.h1.checksum;
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorUnexpectedCondition) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        if (headers.h1.field1 > 0) {
            headers.h1.checksum = checksum.get({
                headers.h1.field1,
                headers.h1.field3
            });
        }
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorUnexpectedSource) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        headers.h1.checksum = checksum.get({
            headers.h1.field1,
            headers.h1.field3 + 1
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

TEST(TofinoComputedChecksum, ErrorNoDestField) {
    auto test = createComputedChecksumTestCase(P4_SOURCE(P4Headers::NONE, R"(
        checksum.get({
            headers.h1.field1,
            headers.h1.field3
        });
    )"), P4_SOURCE(P4Headers::NONE, R"(
        packet.emit(headers.h1);
    )"));

    EXPECT_GT(::ErrorReporter::instance.getDiagnosticCount(), 0u);
}

}  // namespace Test
