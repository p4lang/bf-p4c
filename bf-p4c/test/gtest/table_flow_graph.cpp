#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <initializer_list>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class TableFlowGraphTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createTableFlowGraphTestCase(const std::string& parserSource) {
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

header H2
{
    bit<32> b1;
    bit<32> b2;
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
    bit<32> f9;
    bit<32> f10;
    bit<32> f11;
    bit<32> f12;
}

struct Headers { H1 h1; H2 h2;}
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
%MAU%
}

control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control deparse(packet_out packet, in Headers headers) {
    apply { packet.emit(headers.h1); }
}

V1Switch(parse(), verifyChecksum(), mau(), mau(),
    computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%MAU%", parserSource);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

}  // namespace

TEST_F(TableFlowGraphTest, BasicControlFlow) {
    auto test = createTableFlowGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

action setb1(bit<32> val) {
    headers.h2.b1 = val;
}

action setb2(bit<32> val) {
    headers.h2.b2 = val;
}

action setf1(bit<32> val) {
    headers.h2.f1 = val;
}

action setf2(bit<32> val) {
    headers.h2.f2 = val;
}

action setf3(bit<32> val) {
    headers.h2.f3 = val;
}

action setf4(bit<32> val) {
    headers.h2.f4 = val;
}

action setf5(bit<32> val) {
    headers.h2.f5 = val;
}

action setf6(bit<32> val) {
    headers.h2.f6 = val;
}

action setf7(bit<32> val) {
    headers.h2.f7 = val;
}

action setf8(bit<32> val) {
    headers.h2.f8 = val;
}

action setf9(bit<32> val) {
    headers.h2.f9 = val;
}

action setf10(bit<32> val) {
    headers.h2.f10 = val;
}

action setf12(bit<32> val) {
    headers.h2.f12 = val;
}

action noop() {

}

table t1 {
    key = {
        headers.h2.f2 : exact;
    }
    actions = {
        noop;
    }
    size = 8192;
}

table t2 {
    key = {
        headers.h2.b1 : exact;
    }
    actions  = {
        setb1;
        noop;
    }
    size = 8192;
}

table t7 {
    key = {
        headers.h2.b1 : exact;
    }
    actions = {
        setb1;
    }
}

table t8 {
    key = {
        headers.h2.f2 : exact;
    }
    actions = {
        setb1;
    }
}

table t9 {
    key = {
        headers.h2.f2 : exact;
    }
    actions = {
        setb1;
    }
}

table t10 {
    key = {
        headers.h2.f2 : exact;
    }
    actions = {
        setb1;
    }
}

table t3 {
    key = {
        headers.h2.f1 : exact;
    }
    actions = {
        setf7;
    }
    size = 65536;
}

table t4 {
    key = {
        headers.h2.f1 : exact;
    }
    actions = {
        setf8;
    }
    size = 65536;
}

table t5 {
    key = {
        headers.h2.f1 : exact;
    }
    actions = {
        setf9;
    }
    size = 95536;
}

table t6 {
    key = {
        headers.h2.f1 : exact;
    }
    actions  ={
        setf10;
    }
    size = 95536;
}

table t11 {
    key = {
        headers.h2.f11 : exact;
    }
    actions = {
        noop;
        setf12;
    }
}

table t12 {
    key = {
        headers.h2.f12 : exact;
    }
    actions = {
        noop;
    }
}


apply {
    if(t11.apply().hit) {
        t12.apply();
        if (t1.apply().hit) {
            t2.apply();
        }
        t3.apply();
        if (t4.apply().hit) {
            t5.apply();
        }
        else {
            t6.apply();
        }
        t7.apply();
    }

    t8.apply();
    t9.apply();
    t10.apply();
}
    )"));
    ASSERT_TRUE(test);

    FlowGraph fg;
    auto *find_fg_ingress = new FindFlowGraph(fg);

    test->pipe->thread[INGRESS].mau->apply(*find_fg_ingress);

    const IR::MAU::Table *t1, *t2, *t3, *t4, *t5, *t6, *t7, *t8, *t9, *t10, *t11, *t12;
    t1 = t2 = t3 = t4 = t5 = t6 = t7 = t8 = t9 = t10 = t11 = t12 = nullptr;
    typename FlowGraph::Graph::vertex_iterator v, v_end;
    for (boost::tie(v, v_end) = boost::vertices(fg.g); v != v_end; ++v) {
        if (*v == fg.v_sink)
            continue;
        const IR::MAU::Table *found_table = fg.get_vertex(*v);
        if (found_table->name == "t1_0") {
            t1 = found_table;
        } else if (found_table->name == "t2_0") {
            t2 = found_table;
        } else if (found_table->name == "t3_0") {
            t3 = found_table;
        } else if (found_table->name == "t4_0") {
            t4 = found_table;
        } else if (found_table->name == "t5_0") {
            t5 = found_table;
        } else if (found_table->name == "t6_0") {
            t6 = found_table;
        } else if (found_table->name == "t7_0") {
            t7 = found_table;
        } else if (found_table->name == "t8_0") {
            t8 = found_table;
        } else if (found_table->name == "t9_0") {
            t9 = found_table;
        } else if (found_table->name == "t10_0") {
            t10 = found_table;
        } else if (found_table->name == "t11_0") {
            t11 = found_table;
        } else if (found_table->name == "t12_0") {
            t12 = found_table;
        }
    }

    EXPECT_NE(t1, nullptr);
    EXPECT_NE(t2, nullptr);
    EXPECT_NE(t3, nullptr);
    EXPECT_NE(t4, nullptr);
    EXPECT_NE(t5, nullptr);
    EXPECT_NE(t6, nullptr);
    EXPECT_NE(t7, nullptr);
    EXPECT_NE(t8, nullptr);
    EXPECT_NE(t9, nullptr);
    EXPECT_NE(t10, nullptr);
    EXPECT_NE(t11, nullptr);
    EXPECT_NE(t12, nullptr);

    const int NUM_CHECKS_EXPECTED = 12;
    int num_checks = 0;

    FlowGraph::Graph::edge_iterator edges, edges_end;
    std::map<const IR::MAU::Table*, ordered_set<const IR::MAU::Table*>> stored_edges;
    for (boost::tie(edges, edges_end) = boost::edges(fg.g); edges != edges_end; ++edges) {
        const IR::MAU::Table *src = fg.get_vertex(boost::source(*edges, fg.g));
        const IR::MAU::Table *dst = fg.get_vertex(boost::target(*edges, fg.g));
        stored_edges[src].insert(dst);
    }
    for (auto& kv : stored_edges) {
        auto src = kv.first;
        auto dst_options = kv.second;
        if (src == t11) {
            EXPECT_NE(dst_options.count(t12), UINT32_C(0));
            EXPECT_NE(dst_options.count(t8), UINT32_C(0));
            num_checks++;
        } else if (src == t12) {
            EXPECT_NE(dst_options.count(t1), UINT32_C(0));
            num_checks++;
        } else if (src == t1) {
            EXPECT_NE(dst_options.count(t2), UINT32_C(0));
            EXPECT_NE(dst_options.count(t3), UINT32_C(0));
            num_checks++;
        } else if (src == t2) {
            EXPECT_NE(dst_options.count(t3), UINT32_C(0));
            num_checks++;
        } else if (src == t3) {
            EXPECT_NE(dst_options.count(t4), UINT32_C(0));
            num_checks++;
        } else if (src == t4) {
            EXPECT_NE(dst_options.count(t5), UINT32_C(0));
            EXPECT_NE(dst_options.count(t6), UINT32_C(0));
            num_checks++;
        } else if (src == t5) {
            EXPECT_NE(dst_options.count(t7), UINT32_C(0));
            num_checks++;
        } else if (src == t6) {
            EXPECT_NE(dst_options.count(t7), UINT32_C(0));
            num_checks++;
        } else if (src == t7) {
            EXPECT_NE(dst_options.count(t8), UINT32_C(0));
            num_checks++;
        } else if (src == t8) {
            EXPECT_NE(dst_options.count(t9), UINT32_C(0));
            num_checks++;
        } else if (src == t9) {
            EXPECT_NE(dst_options.count(t10), UINT32_C(0));
            num_checks++;
        } else if (src == t10) {
            EXPECT_NE(dst_options.count(nullptr), UINT32_C(0));
            num_checks++;
        } else if (src == nullptr) {
            num_checks++;
        }
    }
    EXPECT_EQ(num_checks, NUM_CHECKS_EXPECTED);

    EXPECT_EQ(fg.can_reach(t10, t11), false);
    EXPECT_EQ(fg.can_reach(t10, nullptr), true);
    EXPECT_EQ(fg.can_reach(nullptr, t10), false);
    EXPECT_EQ(fg.can_reach(t6, t5), false);
    EXPECT_EQ(fg.can_reach(t5, t6), false);
    EXPECT_EQ(fg.can_reach(t7, t7), true);
    EXPECT_EQ(fg.can_reach(t3, t7), true);
}
}  // namespace Test
