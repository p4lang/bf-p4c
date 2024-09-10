
#include <optional>
#include <regex>
#include <boost/algorithm/string/replace.hpp>
#include "gtest/gtest.h"

#include "backends/tofino/common/header_stack.h"
#include "backends/tofino/phv/analysis/mutex_overlay.h"
#include "backends/tofino/phv/phv_fields.h"
#include "backends/tofino/phv/pragma/pa_mutually_exclusive.h"
#include "backends/tofino/test/gtest/tofino_gtest_utils.h"
#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"

namespace Test {

auto CaptureStderr = ::testing::internal::CaptureStderr;
auto Stderr = ::testing::internal::GetCapturedStderr;

class PaMutuallyExclusivePragmaTest : public TofinoBackendTest {};

namespace {

std::optional<TofinoPipeTestCase> createPaMutuallyExclusivePragmaTestCase() {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        @pa_mutually_exclusive("ingress", "h1.f1", "h2.f1")
        header H1
        {
            bit<8> f1;
            bit<32> f2;
        }
        header H2
        {
            bit<64> f1;
        }
        struct Headers { H1 h1; H2 h2; }
        struct Metadata {
            bit<8> f1;
            H2 f2;
        }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
            packet.extract(headers.h1);
            packet.extract(headers.h2);
            transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply { }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    auto &options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

std::optional<TofinoPipeTestCase> createPaMutuallyExclusiveHeaderPragmaTestCase() {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        @pa_mutually_exclusive("ingress", "headers.h1", "h2")
        header H1
        {
            bit<8> f1;
            bit<32> f2;
        }
        header H2
        {
            bit<8> f1;
            bit<32> f2;
        }
        struct Headers { H1 h1; H2 h2; }
        struct Metadata {
            bit<8> f1;
            H2 f3;
        }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
            packet.extract(headers.h1);
            packet.extract(headers.h2);
            transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply { }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    auto &options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

std::optional<TofinoPipeTestCase> createPaMutuallyExclusivePragmaNoMatchingPhvFieldTestCase() {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        @pa_mutually_exclusive("ingress", "headersAAA.h1", "headers.h2")
        @pa_mutually_exclusive("ingress", "headers.h1", "headersBBB.h2")
        @pa_mutually_exclusive("ingress", "headers.h1CCC", "headers.h2")
        @pa_mutually_exclusive("ingress", "headers.h1", "headers.h2DDD")
        header H1
        {
            bit<8> f1;
            bit<32> f2;
        }
        header H2
        {
            bit<8> f1;
            bit<32> f2;
        }
        struct Headers { H1 h1; H2 h2; }
        struct Metadata {
            bit<8> f1;
            H2 f3;
        }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
            packet.extract(headers.h1);
            packet.extract(headers.h2);
            transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply { }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    auto &options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPassesPaMutuallyExclusivePragma(const IR::BFN::Pipe *pipe,
                                                            PhvInfo &phv) {
    PHV::Pragmas *pragmas = new PHV::Pragmas(phv);
    PhvUse *uses = new PhvUse(phv);
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        pragmas,
        uses,
        new MutexOverlay(phv, *pragmas, *uses),
    };
    return pipe->apply(quick_backend);
}

bool checkNoMatchingPhvField(const std::string &str, const std::string &field) {
    return std::regex_search(str,
                             std::regex("warning:\\s*\"" + field + "\":\\s*No matching PHV field"));
}

}  // namespace

TEST_F(PaMutuallyExclusivePragmaTest, P4_16) {
    std::string stderr;

    auto test = createPaMutuallyExclusivePragmaTestCase();
    ASSERT_TRUE(test);

    PhvInfo phv;

    CaptureStderr();
    runMockPassesPaMutuallyExclusivePragma(test->pipe, phv);
    stderr = Stderr();
    EXPECT_FALSE(checkNoMatchingPhvField(stderr, "h1.f1"));
    EXPECT_FALSE(checkNoMatchingPhvField(stderr, "h2.f1"));

    EXPECT_EQ(phv.field_mutex()(phv.field("ingress::h1.f2")->id, phv.field("ingress::h2.f1")->id),
              false);

    EXPECT_EQ(phv.field_mutex()(phv.field("ingress::h1.f1")->id, phv.field("ingress::h2.f1")->id),
              true);

    auto test2 = createPaMutuallyExclusiveHeaderPragmaTestCase();
    ASSERT_TRUE(test2);

    PhvInfo phv2;

    CaptureStderr();
    runMockPassesPaMutuallyExclusivePragma(test2->pipe, phv2);
    stderr = Stderr();
    EXPECT_FALSE(checkNoMatchingPhvField(stderr, "headers.h1"));
    EXPECT_FALSE(checkNoMatchingPhvField(stderr, "h2"));

    EXPECT_EQ(
        phv2.field_mutex()(phv2.field("ingress::h1.f2")->id, phv2.field("ingress::h2.f2")->id),
        true);

    EXPECT_EQ(
        phv2.field_mutex()(phv2.field("ingress::h1.f1")->id, phv2.field("ingress::h2.f1")->id),
        true);
}

TEST_F(PaMutuallyExclusivePragmaTest, P4_16_NoMatchingPhvField) {
    std::string stderr;

    auto test = createPaMutuallyExclusivePragmaNoMatchingPhvFieldTestCase();
    ASSERT_TRUE(test);

    PhvInfo phv;

    CaptureStderr();
    runMockPassesPaMutuallyExclusivePragma(test->pipe, phv);
    stderr = Stderr();
    EXPECT_TRUE(checkNoMatchingPhvField(stderr, "headersAAA.h1"));
    EXPECT_TRUE(checkNoMatchingPhvField(stderr, "headersBBB.h2"));
    EXPECT_TRUE(checkNoMatchingPhvField(stderr, "headers.h1CCC"));
    EXPECT_TRUE(checkNoMatchingPhvField(stderr, "headers.h2DDD"));
}

}  // namespace Test
