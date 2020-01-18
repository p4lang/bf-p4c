#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class TableMutexTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createTableMutexTestCase(const std::string &ingress_source) {
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
%INGRESS%
}

control egrs(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
    apply {
    }
}

control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control deparse(packet_out packet, in Headers headers) {
    apply { packet.emit(headers.h1); }
}

V1Switch(parse(), verifyChecksum(), igrs(), egrs(),
    computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%INGRESS%", ingress_source);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

}  // namespace

TEST_F(TableMutexTest, BasicMutex) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; }
    }

    apply {
        switch (t1.apply().action_run) {
            nop : { t2.apply(); }
            setf1 : { t3.apply(); }
        }
    }

    )"));
    ASSERT_TRUE(test);
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
}

TEST_F(TableMutexTest, TwoActionsSameNextTable) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; setf2; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; }
    }


    apply {
        switch (t1.apply().action_run) {
            nop : {
                t2.apply();
            }
            setf1 : {
                t2.apply();
            }
            setf2 : {
                t3.apply();
            }
        }
    }

    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
}

TEST_F(TableMutexTest, SharedNextTable) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; setf2; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; }
    }

    table t4 {
        key = { headers.h1.f4 : exact; }
        actions = { nop; }
    }


    apply {
        switch (t1.apply().action_run) {
            nop : {
                t2.apply();
            }
            setf1 : {
                t3.apply();
                t2.apply();
            }
            setf2 : {
                t4.apply();
            }
        }
    }

    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t4")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t4")));
    EXPECT_TRUE(mutex(names.at("igrs.t3"), names.at("igrs.t4")));
}

TEST_F(TableMutexTest, DifferingNextTableChains) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }
    action setf3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; setf2; setf3; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; }
    }

    table t4 {
        key = { headers.h1.f4 : exact; }
        actions = { nop; }
    }

    table t5 {
        key = { headers.h1.f5 : exact; }
        actions = { nop; }
    }


    apply {
        switch (t1.apply().action_run) {
            nop : {
                t2.apply();
            }
            setf1 : {
                t3.apply();
                t2.apply();
            }
            setf2 : {
                t4.apply();
            }
            setf3 : {
                t5.apply();
                t4.apply();
            }
        }
    }

    )"));
    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t4")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t5")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t4")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t5")));
    EXPECT_TRUE(mutex(names.at("igrs.t3"), names.at("igrs.t4")));
    EXPECT_TRUE(mutex(names.at("igrs.t3"), names.at("igrs.t5")));
    EXPECT_FALSE(mutex(names.at("igrs.t4"), names.at("igrs.t5")));
}



TEST_F(TableMutexTest, OneChainFromTwoActions) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }
    action setf3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; setf2; setf3; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; }
    }

    table t4 {
        key = { headers.h1.f4 : exact; }
        actions = { nop; }
    }

    apply {
        switch (t1.apply().action_run) {
            nop: setf1 : {
                t2.apply();
            }
            setf2 : {
                t3.apply();
                t2.apply();
            }
            setf3 : {
                t4.apply();
            }
        }
    }

    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t4")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t4")));
    EXPECT_TRUE(mutex(names.at("igrs.t3"), names.at("igrs.t4")));
}


TEST_F(TableMutexTest, MultiLevelNextTableChain) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop () {}
    action setf1(bit<8> p1) { headers.h1.f1 = p1; }
    action setf2() { headers.h1.f2 = headers.h1.f1; }
    action setf3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f2 : exact; }
        actions = { nop; setf1; setf2; setf3; }
    }

    table t2 {
        key = { headers.h1.f2 : exact; }
        actions = { setf1; }
    }

    table t3 {
        key = { headers.h1.f3 : exact; }
        actions = { setf2; setf3; }
    }


    apply {
        switch (t1.apply().action_run) {
            nop: {
                t2.apply();
            }
            setf1 : {
                switch (t3.apply().action_run) {
                    setf3 : {
                        t2.apply();
                    }
                }
            }
        }
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
}

TEST_F(TableMutexTest, Tofino2MultiApplyChain) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t0 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; a2; a3; }
    }

    table t1_0 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; a2; a3; }
    }

    table t1_1 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; a2; a3; }
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    table t5 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t6 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    apply {
        if (t0.apply().hit) {
            switch(t1_0.apply().action_run) {
                a1 : { t2.apply(); }
                a2 : { t3.apply(); }
                a3 : { t4.apply(); } 
            }
        } else {
            switch(t1_1.apply().action_run) {
                a1 : { t2.apply(); t3.apply(); }
                a2 : { t3.apply(); t4.apply(); }
                a3 : { t4.apply(); t5.apply(); }
            }
        }
        t6.apply();
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply2 ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t4")));
    EXPECT_TRUE(mutex(names.at("igrs.t2"), names.at("igrs.t5")));
    EXPECT_TRUE(mutex(names.at("igrs.t3"), names.at("igrs.t5")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex(names.at("igrs.t1_0"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex(names.at("igrs.t2"), names.at("igrs.t6")));
    EXPECT_FALSE(mutex(names.at("igrs.t5"), names.at("igrs.t6")));
}

TEST_F(TableMutexTest, ActionViaMissTest) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    apply {
        if (t1.apply().miss) {
            t2.apply();
            t3.apply();
        } 
        t4.apply();
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t4")));
}

TEST_F(TableMutexTest, ActionViaHitTest) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    apply {
        if (t1.apply().hit) {
        } else {
            t2.apply();
            t3.apply();
        } 
        t4.apply();
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t4")));
}

TEST_F(TableMutexTest, ActionViaMultiChain) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    apply {
        if (t1.apply().hit) {
            t3.apply();
        } else {
            t2.apply();
            t3.apply();
        }
        t4.apply();
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t4")));
}

TEST_F(TableMutexTest, ActionViaActionChain) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    apply {
        switch (t1.apply().action_run) {
            nop : { t2.apply(); t3.apply(); }
            default : { }
        } 
        t4.apply();
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t4")));
}

TEST_F(TableMutexTest, ActionViaActionChainDefault) {
    auto test = createTableMutexTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action nop() {}
    action a1() { headers.h1.f1 = headers.h1.f2; }
    action a2() { headers.h1.f2 = headers.h1.f1; }
    action a3() { headers.h1.f3 = headers.h1.f1; }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t2 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t3 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t4 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    table t5 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }

    table t6 {
        key = { headers.h1.f1 : exact; }
        actions = { @defaultonly nop; a1; a2; a3; }
        const default_action = nop;
    }

    table t7 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a1; }
    }

    table t8 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a2; }
    }

    table t9 {
        key = { headers.h1.f1 : exact; }
        actions = { nop; a3; }
    }


    apply {
        switch (t1.apply().action_run) {
            a1 : { t4.apply(); }
            a2 : { t4.apply(); }
            a3 : {}
            default : { t2.apply(); t3.apply(); }
        } 
        t5.apply();

        switch (t6.apply().action_run) {
            a1 : { t9.apply(); }
            a2 : { t9.apply(); }
            default : { t7.apply(); t8.apply(); }
        } 
        
    }
    )"));

    ASSERT_TRUE(test);
    MultipleApply ma;
    TablesMutuallyExclusive mutex;
    test->pipe = test->pipe->apply(ma);
    test->pipe = test->pipe->apply(mutex);
    auto &names = mutex.name_to_tables;

    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t2")));
    EXPECT_TRUE(mutex.action(names.at("igrs.t1"), names.at("igrs.t3")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t4")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t1"), names.at("igrs.t5")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t6"), names.at("igrs.t7")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t6"), names.at("igrs.t8")));
    EXPECT_FALSE(mutex.action(names.at("igrs.t6"), names.at("igrs.t9")));
}
}  // namespace Test
