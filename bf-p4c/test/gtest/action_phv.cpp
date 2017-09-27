#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "bf-p4c/mau/action_phv_constraints.h"
#include "bf-p4c/mau/instruction_selection.h"

namespace Test {

namespace {

boost::optional<TofinoPipeTestCase>
createActionTest(const std::string& ingressPipeline,
                 const std::string& egressPipeline) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H { bit<8> field1; bit<8> field2; bit<8> field3; bit<8> field4; }
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
        control ingress(inout Headers headers, inout Metadata meta,
                        inout standard_metadata_t sm) {
%INGRESS_PIPELINE%
        }

        control egress(inout Headers headers, inout Metadata meta,
                       inout standard_metadata_t sm) {
%EGRESS_PIPELINE%
        }

        control computeChecksum(inout Headers headers, inout Metadata meta) {
            apply { } }

        control deparse(packet_out packet, in Headers headers) {
            apply {
                packet.emit(headers.h1);
                packet.emit(headers.h2);
            }
        }

        V1Switch(parse(), verifyChecksum(), ingress(), egress(),
                 computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%INGRESS_PIPELINE%", ingressPipeline);
    boost::replace_first(source, "%EGRESS_PIPELINE%", egressPipeline);

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runInitialPassManager(const IR::BFN::Pipe* pipe, PhvInfo *phv) {
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(*phv),
        new DoInstructionSelection(*phv)
    };

    return pipe->apply(quick_backend);
}

}  // namespace

TEST(ActionPhv, IngressSingleTableSharedWrites) {
    auto test = createActionTest(P4_SOURCE(P4Headers::NONE, R"(
        action first(bit<8> param1, bit<8> param2) {
            headers.h1.field1 = param1;
            headers.h1.field2 = param2;
        }

        action second(bit<8> param1, bit<8> param2, bit<8> param3) {
            headers.h1.field1 = param1;
            headers.h1.field3 = param2;
            headers.h1.field4 = param3;
        }

        table test1 {
            key = { headers.h1.field1 : ternary; }
            actions = {
                first;
                second;
            }
        }

        apply {
            test1.apply();
        }

    )"), P4_SOURCE(P4Headers::NONE, R"(
        apply { }
    )"));

    ASSERT_TRUE(test);
    PhvInfo phv;
    auto *post_pm_pipe = runInitialPassManager(test->pipe, &phv);
    ActionPhvConstraints apc(phv);
    post_pm_pipe = post_pm_pipe->apply(apc);

    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h1.field2"));
    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h1.field3"));
    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h1.field4"));
    EXPECT_FALSE(apc.is_in_shared_writes("ingress::h1.field2", "ingress::h1.field4"));
}

TEST(ActionPhv, IngressMultipleTablesSharedWrites) {
    auto test = createActionTest(P4_SOURCE(P4Headers::NONE, R"(
        action first(bit<8> param1, bit<8> param2) {
            headers.h1.field1 = param1;
            headers.h1.field4 = param2;
        }

        action second(bit<8> param1, bit<8> param2, bit<8> param3) {
            headers.h1.field1 = param1;
            headers.h2.field3 = param2;
            headers.h2.field4 = param3;

        }

        action third(bit<8> param1, bit<8> param2, bit<8> param3) {
            headers.h1.field4 = param1;
            headers.h2.field2 = param2;
            headers.h2.field3 = param3;
        }

        table test1 {
            key = { headers.h1.field1 : ternary; }
            actions = {
                first;
            }
        }

        table test2 {
            key = { headers.h2.field1 : ternary; }
            actions = {
                second;
                third;
            }
        }

        apply {
            test1.apply();
            test2.apply();
        }

    )"), P4_SOURCE(P4Headers::NONE, R"(
        apply { }
    )"));

    ASSERT_TRUE(test);
    PhvInfo phv;
    auto *post_pm_pipe = runInitialPassManager(test->pipe, &phv);
    ActionPhvConstraints apc(phv);
    post_pm_pipe = post_pm_pipe->apply(apc);

    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h2.field3"));
    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h2.field4"));
    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field4", "ingress::h2.field2"));
    EXPECT_TRUE(apc.is_in_shared_writes("ingress::h1.field4", "ingress::h2.field3"));

    EXPECT_FALSE(apc.is_in_shared_writes("ingress::h1.field1", "ingress::h2.field2"));
    EXPECT_FALSE(apc.is_in_shared_writes("ingress::h1.field4", "ingress::h2.field4"));
}

TEST(ActionPhv, IngressMultipleTablesReads) {
    auto test = createActionTest(P4_SOURCE(P4Headers::NONE, R"(
        action first() {
            headers.h1.field1 = headers.h2.field1;
            headers.h1.field4 = headers.h2.field2;
        }

        action second() {
            headers.h1.field1 = headers.h2.field1;
            headers.h2.field3 = headers.h2.field4;
            headers.h2.field4 = headers.h2.field1;
        }

        action third(bit<8> param) {
            headers.h1.field4 = headers.h2.field4;
            headers.h2.field2 = headers.h1.field2;
            headers.h2.field3 = headers.h1.field2;
            headers.h1.field1 = param;
        }

        table test1 {
            key = { headers.h1.field1 : ternary; }
            actions = {
                first;
            }
        }

        table test2 {
            key = { headers.h2.field1 : ternary; }
            actions = {
                second;
                third;
            }
        }

        apply {
            test1.apply();
            test2.apply();
        }

    )"), P4_SOURCE(P4Headers::NONE, R"(
        apply { }
    )"));

    ASSERT_TRUE(test);
    PhvInfo phv;
    auto *post_pm_pipe = runInitialPassManager(test->pipe, &phv);
    ActionPhvConstraints apc(phv);
    post_pm_pipe = post_pm_pipe->apply(apc);

    EXPECT_TRUE(apc.is_in_read_to_writes("ingress::h2.field1", "ingress::h1.field1"));
    EXPECT_TRUE(apc.is_in_read_to_writes("ingress::h2.field1", "ingress::h2.field4"));
    EXPECT_TRUE(apc.is_in_read_to_writes("ingress::h2.field2", "ingress::h1.field4"));
    EXPECT_TRUE(apc.is_in_read_to_writes("ingress::h1.field2", "ingress::h2.field2"));
    EXPECT_TRUE(apc.is_in_read_to_writes("ingress::h1.field2", "ingress::h2.field3"));

    EXPECT_FALSE(apc.is_in_read_to_writes("ingress::h2.field1", "ingress::h2.field3"));
    EXPECT_FALSE(apc.is_in_read_to_writes("ingress::h2.field2", "ingress::h1.field1"));

    EXPECT_TRUE(apc.is_in_write_to_reads("ingress::h1.field1", "ingress::h2.field1"));
    EXPECT_TRUE(apc.is_in_write_to_reads("ingress::h1.field1", "ad_or_constant"));
    EXPECT_TRUE(apc.is_in_write_to_reads("ingress::h2.field3", "ingress::h2.field4"));
    EXPECT_TRUE(apc.is_in_write_to_reads("ingress::h2.field3", "ingress::h1.field2"));

    EXPECT_FALSE(apc.is_in_write_to_reads("ingress::h1.field1", "ingress::h1.field2"));
    EXPECT_FALSE(apc.is_in_write_to_reads("ingress::h2.field3", "ad_or_constant"));
}

}  // namespace Test
