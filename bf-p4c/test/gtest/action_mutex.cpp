#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class ActionMutexTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createActionMutexTestCase(const std::string& parserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
header H1
{
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
    bit<8> f4;
    bit<8> f5;
    bit<8> f6;
}

struct Headers { H1 h1; }
struct Metadata { }

parser parse(packet_in packet, out Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
    state start {
        packet.extract(headers.h1);
        transition accept;
    }
}

control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control mau(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    action set_f3(bit<8> f3) {
        headers.h1.f3 = f3;
    }

    action set_f4(bit<8> f4) {
        headers.h1.f4 = f4;
    }

    action set_f5(bit<8> f5) {
        headers.h1.f5 = f5;
    }

    table node_a {
        actions = { set_f1; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { set_f1; set_f2; set_f3; set_f5; }
        key = { headers.h1.f1 : exact; }
    }

    table node_c {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_d {
        actions = { set_f2; set_f3; }
        key = { headers.h1.f1 : exact; }
    }

    table node_e {
        actions = { set_f4; }
        key = { headers.h1.f1 : exact; }
    }

    table node_f {
        actions = { set_f5; }
        key = { headers.h1.f1 : exact; }
    }

    apply {
%MAU%
    }
}

control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control deparse(packet_out packet, in Headers headers) {
    apply { packet.emit(headers.h1); }
}

V1Switch(parse(), verifyChecksum(), mau(), mau(),
    computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%MAU%", parserSource);

    auto& options = BFNContext::get().options();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}
}  // namespace

TEST_F(ActionMutexTest, Basic) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
        node_a.apply();
        if (headers.h1.f1 == 0) {
            node_b.apply();
        } else {
            switch (node_d.apply().action_run) {
                set_f2: {
                    if (headers.h1.f2 == 1) {
                        node_e.apply();
                    }
                }
                set_f3: {
                    if (node_f.apply().hit) {
                        node_c.apply();
                    }
                }
            }
        }
)"));
    ASSERT_TRUE(test);

    ActionMutuallyExclusive action_mutex;
    test->pipe->apply(action_mutex);

    auto& act = action_mutex.name_actions;

    // not mutex
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_b_0.mau.set_f1")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_b_0.mau.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_b_0.mau.set_f3")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_b_0.mau.set_f5")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_d_0.mau.set_f3")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_d_0.mau.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_f_0.mau.set_f5")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_c_0.mau.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_e_0.mau.set_f4")), false);

    // ingress, egress
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_a_1.mau.set_f1")), true);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_d_1.mau.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_a_0.mau.set_f1"), act.at("node_e_1.mau.set_f4")), true);

    // inside a table
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f1"), act.at("node_b_0.mau.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f2"), act.at("node_b_0.mau.set_f3")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f3"), act.at("node_b_0.mau.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_d_0.mau.set_f2"), act.at("node_d_0.mau.set_f3")), true);

    // between if and different depths
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f1"), act.at("node_d_0.mau.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f2"), act.at("node_e_0.mau.set_f4")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f3"), act.at("node_f_0.mau.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.mau.set_f5"), act.at("node_c_0.mau.set_f2")), true);

    // from switch action_run children
    EXPECT_EQ(action_mutex(act.at("node_d_0.mau.set_f2"), act.at("node_e_0.mau.set_f4")), false);
    EXPECT_EQ(action_mutex(act.at("node_d_0.mau.set_f2"), act.at("node_f_0.mau.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_d_0.mau.set_f3"), act.at("node_c_0.mau.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_d_0.mau.set_f3"), act.at("node_e_0.mau.set_f4")), true);

    // between switch action_run
    EXPECT_EQ(action_mutex(act.at("node_e_0.mau.set_f4"), act.at("node_f_0.mau.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_e_0.mau.set_f4"), act.at("node_c_0.mau.set_f2")), true);

    // from hit to children
    EXPECT_EQ(action_mutex(act.at("node_f_0.mau.set_f5"), act.at("node_c_0.mau.set_f2")), false);
}

}  // namespace Test
