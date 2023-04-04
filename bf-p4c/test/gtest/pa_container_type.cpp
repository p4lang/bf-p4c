#include <optional>
#include <boost/algorithm/string/replace.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_container_type.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class PaContainerTypePragmaTest : public TofinoBackendTest {};

namespace {

std::optional<TofinoPipeTestCase>
createPaContainerTypePragmaTestCase(const std::string& pragmas) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        %PRAGMAS%
        header H1
        {
            bit<8> f1;
            bit<3> f2;
            bit<13> f3;
            bit<48> f4;
        }
        struct Headers { H1 h1; }
        struct Metadata {
            bit<8> f1;
            bit<3> f2;
        }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
            packet.extract(headers.h1);
            transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control mau(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {
            packet.emit(headers.h1);
            }
        }

        V1Switch(parse(), verifyChecksum(), mau(), mau(),
                 computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%PRAGMAS%", pragmas);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv,
                                   PragmaContainerType& pa_container_type) {
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        &pa_container_type
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(PaContainerTypePragmaTest, Basic) {
    auto test = createPaContainerTypePragmaTestCase(
            P4_SOURCE(P4Headers::NONE,
                      R"(
                         @pa_container_type("ingress", "h1.f3", "normal")
                         @pa_container_type("ingress", "h1.f4", "dark")
                         @pa_container_type("ingress", "h1.f2", "mocha")
                         )"));
    ASSERT_TRUE(test);

    PhvInfo phv;
    PragmaContainerType pa_container_type(phv);
    runMockPasses(test->pipe, phv, pa_container_type);

    auto* h1_f4 = phv.field("ingress::h1.f4");
    auto* h1_f3 = phv.field("ingress::h1.f3");
    auto* h1_f2 = phv.field("ingress::h1.f2");

    EXPECT_EQ(h1_f4->is_dark_candidate(), true);
    EXPECT_EQ(h1_f4->is_mocha_candidate(), false);
    EXPECT_EQ(h1_f3->is_dark_candidate(), false);
    EXPECT_EQ(h1_f3->is_mocha_candidate(), false);
    EXPECT_EQ(h1_f2->is_dark_candidate(), false);
    EXPECT_EQ(h1_f2->is_mocha_candidate(), true);

    EXPECT_EQ(pa_container_type.required_kind(h1_f4), PHV::Kind::dark);
    EXPECT_EQ(pa_container_type.required_kind(h1_f3), PHV::Kind::normal);
    EXPECT_EQ(pa_container_type.required_kind(h1_f2), PHV::Kind::mocha);
}
}  // namespace Test
