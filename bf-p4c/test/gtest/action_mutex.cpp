#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class ActionMutexTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createActionMutexTestCase(const std::string& mau) {
    auto tables = P4_SOURCE(P4Headers::NONE, R"(
    action noop() {}

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
        actions = { set_f1; noop; }
        key = { headers.h1.f1 : exact; }
        const default_action = noop;
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

)");
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

control igrs(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
%TABLES%
    apply {
%INGRESS%
    }
}

control egrs(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
%TABLES%
    apply {
%EGRESS%
    }
}

control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control deparse(packet_out packet, in Headers headers) {
    apply { packet.emit(headers.h1); }
}

V1Switch(parse(), verifyChecksum(), igrs(), egrs(),
    computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%INGRESS%", mau);
    boost::replace_first(source, "%EGRESS%", mau);
    boost::replace_all(source, "%TABLES%", tables);

    auto& options = BackendOptions();
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

    // debugging
    // for (auto a : act) std::cerr << a.first << std::endl;

    // not mutex
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_b_0.igrs.set_f1")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_b_0.igrs.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_b_0.igrs.set_f3")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_b_0.igrs.set_f5")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_d_0.igrs.set_f3")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_d_0.igrs.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_f_0.igrs.set_f5")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_c_0.igrs.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_e_0.igrs.set_f4")), false);

    // ingress, egress
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_a_1.egrs.set_f1")), true);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_d_1.egrs.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_e_1.egrs.set_f4")), true);

    // inside a table
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_b_0.igrs.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_b_0.igrs.set_f3")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_b_0.igrs.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_d_0.igrs.set_f3")), true);

    // between if and different depths
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_d_0.igrs.set_f2")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_e_0.igrs.set_f4")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_f_0.igrs.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_b_0.igrs.set_f5"), act.at("node_c_0.igrs.set_f2")), true);

    // from switch action_run children
    EXPECT_EQ(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_e_0.igrs.set_f4")), false);
    EXPECT_EQ(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_f_0.igrs.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_d_0.igrs.set_f3"), act.at("node_c_0.igrs.set_f2")), false);
    EXPECT_EQ(action_mutex(act.at("node_d_0.igrs.set_f3"), act.at("node_e_0.igrs.set_f4")), true);

    // between switch action_run
    EXPECT_EQ(action_mutex(act.at("node_e_0.igrs.set_f4"), act.at("node_f_0.igrs.set_f5")), true);
    EXPECT_EQ(action_mutex(act.at("node_e_0.igrs.set_f4"), act.at("node_c_0.igrs.set_f2")), true);

    // from hit to children
    EXPECT_EQ(action_mutex(act.at("node_f_0.igrs.set_f5"), act.at("node_c_0.igrs.set_f2")), false);
}

TEST_F(ActionMutexTest, DefaultNext) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
            node_a.apply();
            switch (node_b.apply().action_run) {
                set_f1 : { node_c.apply(); }
                set_f2 : { node_d.apply(); }
                default : { node_e.apply(); node_f.apply(); }
            } )"));

    ASSERT_TRUE(test);
    ActionMutuallyExclusive action_mutex;
    test->pipe->apply(action_mutex);
    auto& act = action_mutex.name_actions;
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f5"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_e_0.igrs.set_f4")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_e_0.igrs.set_f4")));
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_e_0.igrs.set_f4")));
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f5"), act.at("node_e_0.igrs.set_f4")));
}

TEST_F(ActionMutexTest, MissingDefault) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
            node_a.apply();
            switch (node_b.apply().action_run) {
                set_f1 : { node_c.apply(); }
                set_f2 : { node_d.apply(); }
            }
            node_e.apply();
            node_f.apply(); )"));

    ASSERT_TRUE(test);
    ActionMutuallyExclusive action_mutex;
    test->pipe->apply(action_mutex);
    auto& act = action_mutex.name_actions;

    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_b_0.igrs.set_f5"), act.at("node_c_0.igrs.set_f2")));
}

TEST_F(ActionMutexTest, ConstDefaultAction) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
            if (!node_a.apply().hit) {
                node_c.apply();
            }
            node_b.apply();
            node_d.apply();
            node_e.apply();
            node_f.apply(); )"));

    ASSERT_TRUE(test);
    ActionMutuallyExclusive action_mutex;
    test->pipe->apply(action_mutex);
    auto& act = action_mutex.name_actions;
    EXPECT_FALSE(action_mutex(act.at("node_a_0.igrs.noop"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_TRUE(action_mutex(act.at("node_a_0.igrs.set_f1"), act.at("node_c_0.igrs.set_f2")));
}

TEST_F(ActionMutexTest, SingleDefaultPath) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
            node_a.apply();
            switch (node_b.apply().action_run) {
                default : { node_c.apply(); }
            }
            node_d.apply();
            node_e.apply();
            node_f.apply(); )"));

    ASSERT_TRUE(test);
    ActionMutuallyExclusive action_mutex;
    test->pipe->apply(action_mutex);
    auto& act = action_mutex.name_actions;
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f1"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f2"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f3"), act.at("node_c_0.igrs.set_f2")));
    EXPECT_FALSE(action_mutex(act.at("node_b_0.igrs.set_f5"), act.at("node_c_0.igrs.set_f2")));
}

TEST_F(ActionMutexTest, NextTableProperties) {
    auto test = createActionMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
            node_a.apply();
            switch (node_b.apply().action_run) {
                set_f1 : { node_c.apply(); node_e.apply(); }
                set_f2 : { node_d.apply(); node_e.apply(); }
                default : { node_f.apply(); }
            }
        )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    ActionMutuallyExclusive action_mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe->apply(action_mutex);
    auto& act = action_mutex.name_actions;
    EXPECT_FALSE(action_mutex(act.at("node_c_0.igrs.set_f2"), act.at("node_e_0.igrs.set_f4")));
    EXPECT_FALSE(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_e_0.igrs.set_f4")));
    EXPECT_TRUE(action_mutex(act.at("node_c_0.igrs.set_f2"), act.at("node_d_0.igrs.set_f3")));
    EXPECT_TRUE(action_mutex(act.at("node_c_0.igrs.set_f2"), act.at("node_f_0.igrs.set_f5")));
    EXPECT_TRUE(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_f_0.igrs.set_f5")));
    EXPECT_TRUE(action_mutex(act.at("node_d_0.igrs.set_f2"), act.at("node_f_0.igrs.set_f5")));
}


}  // namespace Test
