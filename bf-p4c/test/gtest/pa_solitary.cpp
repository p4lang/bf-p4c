#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_solitary.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class PaSolitaryPragmaTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createPaSolitaryPragmaTestCase(const std::string& pragmas) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        %PRAGMAS%
        header H1
        {
            bit<8> f1;
            bit<3> f2;
            bit<5> f3;
        }
        header H2
        {
            bit<3> f1;
            bit<5> f2;
        }
        struct Headers { H1 h1; H2 h2; }
        struct Metadata {
            bit<8> f1;
            bit<3> f2;
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
                                   PragmaSolitary& pa_solitary) {
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        &pa_solitary
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(PaSolitaryPragmaTest, Basic) {
    auto test = createPaSolitaryPragmaTestCase(
            P4_SOURCE(P4Headers::NONE,
                      R"(
                         @pa_solitary("ingress", "h1.f1")
                         @pa_solitary("ingress", "h1.f2")
                         @pa_solitary("ingress", "h2.f1")
                         )"));
    ASSERT_TRUE(test);

    PhvInfo phv;
    PragmaSolitary pa_solitary(phv);
    runMockPasses(test->pipe, phv, pa_solitary);

    auto* h1_f1 = phv.field("ingress::h1.f1");
    auto* h1_f2 = phv.field("ingress::h1.f2");
    auto* h2_f1 = phv.field("ingress::h2.f1");

    EXPECT_EQ(h1_f1->is_solitary(), true);
    EXPECT_EQ(h1_f2->is_solitary(), false);  // skip if not container-sized header field
    EXPECT_EQ(h2_f1->is_solitary(), true);   // not skip if not deparsed
}

}  // namespace Test
