#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/common/check_uninitialized_read.h"

namespace Test {

class CheckUninitializedReadTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createCheckUninitializedReadTestCase() {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H1
        {
            bit<8> f1;
        }
        header H2
        {
            bit<8> f1;
            @padding bit<8> f2;
        }
        struct Headers { H1 h1; H2 h2;}
        struct Metadata { bit<8> f1; }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) {
            state start {
            packet.extract(headers.h1);
            transition accept;
            }
        }

        control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control ingress(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { 
                            if (sm.ingress_port == 1) {
                                headers.h2.setValid();
                            }
                                } }
        control egress(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) { apply { } }

        control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {packet.emit(headers);}
        }

        V1Switch(parse(), verifyChecksum(), ingress(), egress(),
                    computeChecksum(), deparse()) main;
    )");

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe) {
    PhvInfo phv;
    FieldDefUse defuse(phv);
    PHV::Pragmas pragmas(phv);
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        &defuse,
        &pragmas,
        new CheckUninitializedRead(defuse, phv, pragmas)
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(CheckUninitializedReadTest, Test) {
    auto test = createCheckUninitializedReadTestCase();
    ASSERT_TRUE(test);
    CheckUninitializedRead::unset_printed();
    testing::internal::CaptureStderr();
    runMockPasses(test->pipe);
    std::string output = testing::internal::GetCapturedStderr();

    auto res = output.find("warning: ingress::headers.h2.f1 is read in ingress deparser, but it is "
        "totally or partially uninitialized");
    ASSERT_TRUE(res != std::string::npos);

    res = output.find("warning: egress::headers.h2.f1 is read in egress deparser, but it is totally"
        " or partially uninitialized");
    ASSERT_TRUE(res != std::string::npos);

    // padding field should be ignored.
    res = output.find("warning: ingress::headers.h2.f2 is read in ingress deparser, but it is "
        "totally or partially uninitialized");
    ASSERT_TRUE(res == std::string::npos);

    res = output.find("warning: egress::headers.h2.f2 is read in egress deparser, but it is totally"
        " or partially uninitialized");
    ASSERT_TRUE(res == std::string::npos);

    // pov bit should always be initialized.
    res = output.find("warning: ingress::headers.h2.$valid is read in ingress deparser, but it is "
        "totally or partially uninitialized");
    ASSERT_TRUE(res == std::string::npos);

    res = output.find("warning: egress::headers.h2.$valid is read in egress deparser, but it is "
        "totally or partially uninitialized");
    ASSERT_TRUE(res == std::string::npos);
}
}  // namespace Test
