#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class PaMutuallyExclusivePragmaTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createPaMutuallyExclusivePragmaTestCase() {
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

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv) {
    PHV::Pragmas* pragmas = new PHV::Pragmas(phv);
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        pragmas,
        new ParserOverlay(phv, *pragmas),
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(PaMutuallyExclusivePragmaTest, P4_16) {
    auto test = createPaMutuallyExclusivePragmaTestCase();
    ASSERT_TRUE(test);

    SymBitMatrix mutually_exclusive_field_ids;
    PhvInfo phv(mutually_exclusive_field_ids);

    runMockPasses(test->pipe, phv);
    EXPECT_EQ(mutually_exclusive_field_ids(phv.field("ingress::h1.f2")->id,
                                           phv.field("ingress::h2.f1")->id), false);

    EXPECT_EQ(mutually_exclusive_field_ids(phv.field("ingress::h1.f1")->id,
                                           phv.field("ingress::h2.f1")->id), true);
}

}  // namespace Test
