#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include <array>
#include <initializer_list>

#include "gtest/gtest.h"

#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"

#include "test/gtest/helpers.h"

namespace Test {

class TableDependencyGraphTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createTableDependencyGraphTestCase(const std::string& parserSource) {
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

control my_egress(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) { apply {} }

V1Switch(parse(), verifyChecksum(), mau(), my_egress(),
    computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%MAU%", parserSource);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv, FieldDefUse& defuse) {
    auto options = new BFN_Options();  // dummy options used in Pass
    PassManager quick_backend = {
        new MultipleApply,
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new InstructionSelection(*options, phv),
        new CollectPhvInfo(phv),
        &defuse,
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(TableDependencyGraphTest, GraphInjectedControl) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

    action a1(bit<8> val) {
        headers.h1.f6 = val;
    }

    action noop() { }

    table t1 {
        key = {
            headers.h1.f1: exact;
        }

        actions = {
            a1; noop;
        }
    }

    table t2 {
        key = {
            headers.h1.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    table t3 {
        key = {
            headers.h1.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    table t4 {
        key = {
            headers.h1.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    apply {
        switch (t1.apply().action_run) {
            a1 : {
                t4.apply();
            }
            default : {
                if (headers.h1.f2 == headers.h1.f1) {
                    t2.apply();
                    switch (t3.apply().action_run) {
                        noop : {
                            t4.apply();
                        }
                    }
                }
            }
        }
    }
    )"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    DependencyGraph dg;
    FieldDefUse defuse(phv);
    auto *find_dg = new FindDependencyGraph(phv, dg);

    test->pipe = runMockPasses(test->pipe, phv, defuse);
    test->pipe->apply(*find_dg);

    const IR::MAU::Table *t1, *t2, *t3, *t4;
    t1 = t2 = t3 = t4 = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "t1_0") {
            t1 = kv.first;
        } else if (kv.first->name == "t2_0") {
            t2 = kv.first;
        } else if (kv.first->name == "t3_0") {
            t3 = kv.first;
        } else if (kv.first->name == "t4_0") {
            t4 = kv.first;
        }
    }

    EXPECT_NE(t1, nullptr);
    EXPECT_NE(t2, nullptr);
    EXPECT_NE(t3, nullptr);
    EXPECT_NE(t4, nullptr);

    const int NUM_CHECKS_EXPECTED = 3;
    int num_checks = 0;

    DependencyGraph::Graph::edge_iterator edges, edges_end;
    for (boost::tie(edges, edges_end) = boost::edges(dg.g);
         edges != edges_end;
         ++edges) {
        const IR::MAU::Table *src = dg.get_vertex(boost::source(*edges, dg.g));
        const IR::MAU::Table *dst = dg.get_vertex(boost::target(*edges, dg.g));
        DependencyGraph::dependencies_t edge_type = dg.g[*edges];
        if (src == t2 && dst == t3) {
            num_checks++;
            EXPECT_EQ(dg.is_ctrl_edge(edge_type), true);
        }
        if (src == t3 && dst == t4) {
            num_checks++;
            EXPECT_EQ(dg.is_ctrl_edge(edge_type), true);
        }
        if (src == t2) {
            num_checks++;
            EXPECT_NE(dst, t4);
        }
    }
    EXPECT_EQ(num_checks, NUM_CHECKS_EXPECTED);
}

TEST_F(TableDependencyGraphTest, GraphEdgeAnnotations) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action setb1(bit<32> val, bit<8> port) {
        headers.h2.b1 = val;
    }

    action setb2(bit<32> val) {
        headers.h2.b2 = val;
    }

    action setf1(bit<32> val) {
        headers.h2.f1 = val;
    }

    action altsetf1(bit<32> val) {
        headers.h2.f1 = val;
    }

    action setf2(bit<32> val) {
        headers.h2.f2 = val;
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
        headers.h2.f10 =  val;
    }
    action noop() {

    }
    action setf12(bit<32> val) {
        headers.h2.f12 = val;
    }

    action usef12() {
        headers.h2.f10 = headers.h2.f12;
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
        actions = {
            setb1;
            noop;
        }
        size = 8192;
    }

    table t11 {
        key = {
            headers.h2.f11 : exact;
        }
        actions = {
            noop;
            setf12;
            setf1;
            altsetf1;
        }
    }

    table t12 {
        key = {
            headers.h2.f12 : exact;
        }
        actions = {
            noop;
            setf12;
            usef12;
            setf1;
            altsetf1;
        }
    }

    apply {
        if(t11.apply().hit) {
            t12.apply();
            if(t1.apply().hit) {
                t2.apply();
            }
        }
    }

            )"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    DependencyGraph dg;
    FieldDefUse defuse(phv);
    auto *find_dg = new FindDependencyGraph(phv, dg);

    test->pipe = runMockPasses(test->pipe, phv, defuse);
    test->pipe->apply(*find_dg);

    const IR::MAU::Table *t1, *t2, *t11, *t12;
    t1 = t2 = t11 = t12 = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "t1_0") {
            t1 = kv.first;
        } else if (kv.first->name == "t2_0") {
            t2 = kv.first;
        } else if (kv.first->name == "t11_0") {
            t11 = kv.first;
        } else if (kv.first->name == "t12_0") {
            t12 = kv.first;
        }
    }

    EXPECT_NE(t1, nullptr);
    EXPECT_NE(t2, nullptr);
    EXPECT_NE(t11, nullptr);
    EXPECT_NE(t12, nullptr);

    DependencyGraph::dump_viz(std::cout, dg);
    auto not_found = dg.get_data_dependency_info(t1, t2);
    EXPECT_EQ(not_found, boost::none);

    auto dep_info_opt = dg.get_data_dependency_info(t11, t12);
    EXPECT_NE(dep_info_opt, boost::none);
    auto dep_info = dep_info_opt.get();

    ordered_set<cstring> field_names;
    ordered_set<DependencyGraph::dependencies_t> dep_types;
    for (const auto& kv : dep_info) {
        field_names.insert(kv.first.first->name);
        if (kv.first.first->name == "ingress::headers.h2.f12") {
            dep_types.insert(kv.first.second);
        }
    }

    EXPECT_NE(field_names.count("ingress::headers.h2.f12"), UINT32_C(0));
    EXPECT_NE(field_names.count("ingress::headers.h2.f1"), UINT32_C(0));
    EXPECT_NE(dep_types.count(DependencyGraph::IXBAR_READ), UINT32_C(0));
    EXPECT_NE(dep_types.count(DependencyGraph::ACTION_READ), UINT32_C(0));
    EXPECT_NE(dep_types.count(DependencyGraph::OUTPUT), UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_ACTION),              UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_COND_TRUE),           UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_COND_FALSE),          UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_TABLE_HIT),           UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_TABLE_MISS),          UINT32_C(0));
    EXPECT_EQ(dep_types.count(DependencyGraph::CONTROL_DEFAULT_NEXT_TABLE),  UINT32_C(0));
    EXPECT_EQ(field_names.size(), UINT32_C(2));
    EXPECT_EQ(dep_info.size(), UINT32_C(4));

    for (const auto& kv : dep_info) {
        auto field = kv.first.first;
        auto dep_type = kv.first.second;
        auto upstream_actions = kv.second.first;
        auto downstream_actions = kv.second.second;
        ordered_set<cstring> up_names, down_names;
        for (auto action : upstream_actions)
            up_names.insert(action->externalName());
        for (auto action : downstream_actions)
            down_names.insert(action->externalName());
        if (field->name == "ingress::headers.h2.f12") {
            if (dep_type == DependencyGraph::IXBAR_READ) {
                EXPECT_NE(up_names.count("mau.setf12"), UINT32_C(0));
                EXPECT_EQ(down_names.size(), UINT32_C(0));
                EXPECT_EQ(up_names.size(), UINT32_C(1));
            } else if (dep_type == DependencyGraph::ACTION_READ) {
                EXPECT_NE(up_names.count("mau.setf12"), UINT32_C(0));
                EXPECT_NE(down_names.count("mau.usef12"), UINT32_C(0));
                EXPECT_EQ(up_names.size(), UINT32_C(1));
                EXPECT_EQ(down_names.size(), UINT32_C(1));
            } else if (dep_type == DependencyGraph::OUTPUT) {
                EXPECT_NE(up_names.count("mau.setf12"), UINT32_C(0));
                EXPECT_NE(down_names.count("mau.setf12"), UINT32_C(0));
                EXPECT_EQ(up_names.size(), UINT32_C(1));
                EXPECT_EQ(down_names.size(), UINT32_C(1));
            } else {
                EXPECT_EQ(true, false);
            }
        } else if (field->name == "ingress::headers.h2.f1") {
            if (dep_type == DependencyGraph::OUTPUT) {
                EXPECT_NE(up_names.count("mau.setf1"), UINT32_C(0));
                EXPECT_NE(down_names.count("mau.setf1"), UINT32_C(0));
                EXPECT_NE(up_names.count("mau.altsetf1"), UINT32_C(0));
                EXPECT_NE(down_names.count("mau.altsetf1"), UINT32_C(0));
                EXPECT_EQ(up_names.size(), UINT32_C(2));
                EXPECT_EQ(down_names.size(), UINT32_C(2));
            } else {
                EXPECT_EQ(true, false);
            }
        } else {
            EXPECT_EQ(true, false);
        }
    }
}


TEST_F(TableDependencyGraphTest, GraphLayeredControl) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action setb1(bit<32> val, bit<8> port) {
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
        headers.h2.f10 =  val;
    }
    action noop() {

    }
    action setf12(bit<32> val) {
        headers.h2.f12 = val;
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
        actions = {
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
        actions = {
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
            if(t1.apply().hit) {
                t2.apply();
            }
        }

        t3.apply();
        t4.apply();
        t5.apply();
        t6.apply();

        t7.apply();
        t8.apply();
        t9.apply();
        t10.apply();
    }

            )"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    DependencyGraph dg;
    FieldDefUse defuse(phv);
    auto *find_dg = new FindDependencyGraph(phv, dg);

    test->pipe = runMockPasses(test->pipe, phv, defuse);
    test->pipe->apply(*find_dg);

    const IR::MAU::Table *t1, *t2, *t3, *t4, *t5, *t6, *t7, *t8, *t9, *t10, *t11, *t12;
    t1 = t2 = t3 = t4 = t5 = t6 = t7 = t8 = t9 = t10 = t11 = t12 = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "t1_0") {
            t1 = kv.first;
        } else if (kv.first->name == "t2_0") {
            t2 = kv.first;
        } else if (kv.first->name == "t3_0") {
            t3 = kv.first;
        } else if (kv.first->name == "t4_0") {
            t4 = kv.first;
        } else if (kv.first->name == "t5_0") {
            t5 = kv.first;
        } else if (kv.first->name == "t6_0") {
            t6 = kv.first;
        } else if (kv.first->name == "t7_0") {
            t7 = kv.first;
        } else if (kv.first->name == "t8_0") {
            t8 = kv.first;
        } else if (kv.first->name == "t9_0") {
            t9 = kv.first;
        } else if (kv.first->name == "t10_0") {
            t10 = kv.first;
        } else if (kv.first->name == "t11_0") {
            t11 = kv.first;
        } else if (kv.first->name == "t12_0") {
            t12 = kv.first;
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

    EXPECT_EQ(dg.dependence_tail_size_control(t1), 4);
    EXPECT_EQ(dg.dependence_tail_size_control(t2), 4);
    EXPECT_EQ(dg.dependence_tail_size_control(t3), 0);
    EXPECT_EQ(dg.dependence_tail_size_control(t4), 0);
    EXPECT_EQ(dg.dependence_tail_size_control(t5), 0);
    EXPECT_EQ(dg.dependence_tail_size_control(t6), 0);
    EXPECT_EQ(dg.dependence_tail_size_control(t7), 3);
    EXPECT_EQ(dg.dependence_tail_size_control(t8), 2);
    EXPECT_EQ(dg.dependence_tail_size_control(t9), 1);
    EXPECT_EQ(dg.dependence_tail_size_control(t10), 0);
    EXPECT_EQ(dg.dependence_tail_size_control(t11), 4);
    EXPECT_EQ(dg.dependence_tail_size_control(t12), 0);

    EXPECT_EQ(dg.dependence_tail_size(t1), 0);
    EXPECT_EQ(dg.dependence_tail_size(t2), 4);
    EXPECT_EQ(dg.dependence_tail_size(t3), 0);
    EXPECT_EQ(dg.dependence_tail_size(t4), 0);
    EXPECT_EQ(dg.dependence_tail_size(t5), 0);
    EXPECT_EQ(dg.dependence_tail_size(t6), 0);
    EXPECT_EQ(dg.dependence_tail_size(t7), 3);
    EXPECT_EQ(dg.dependence_tail_size(t8), 2);
    EXPECT_EQ(dg.dependence_tail_size(t9), 1);
    EXPECT_EQ(dg.dependence_tail_size(t10), 0);
    EXPECT_EQ(dg.dependence_tail_size(t11), 1);
    EXPECT_EQ(dg.dependence_tail_size(t12), 0);
}

/*
Tests the following graph, where
tables on bottom are dependent on those on top:
Alpha beta gamma chain is independent from other chain

              A
            /   \
        ---B     C
       /  / \   / \
      /  X   Y X2 Y2
     Z1
     |
     Z2
     |
     Z3

Alpha -> Beta -> Gamma
*/

TEST_F(TableDependencyGraphTest, GraphMinStage) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action setb1(bit<32> val) { headers.h2.b1 = val; }
    action setf2(bit<32> val) { headers.h2.f2 = val; }
    action noop() { }

    table A {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table B {
        key = { headers.h2.f1 : exact; }
        actions = { setb1; }
    }

    table C {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table X {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table Y {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table X2 {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table Y2 {
        key = { headers.h2.f1: exact; }
        actions = { noop; }
    }

    table Z1 {
        key = { headers.h2.b1: exact; }
        actions = { setb1; }
    }

    table Z2 {
        key = { headers.h2.b1: exact; }
        actions = { setb1; }
    }

    table Z3 {
        key = { headers.h2.b1: exact; }
        actions = { setb1; }
    }

    table alpha {
        key = { headers.h2.f2: exact; }
        actions = { setf2; }
    }

    table beta {
        key = { headers.h2.f2: exact; }
        actions = { setf2; }
    }

    table gamma {
        key = { headers.h2.f2: exact; }
        actions = { setf2; }
    }

    table t2 {
        key = { headers.h2.f12: exact; }
        actions = { noop; }
    }

    apply {
        if (A.apply().hit) {
            if (B.apply().hit) {
                X.apply();
            }
            else {
                Y.apply();
            }
        }
        else {
            if (C.apply().hit) {
                X2.apply();
            }
            else {
                Y2.apply();
            }
        }
        Z1.apply();
        Z2.apply();
        Z3.apply();

        alpha.apply();
        if (beta.apply().hit) {
            t2.apply();
        }
        gamma.apply();
    }
)"));
    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *x, *y, *x2, *y2, *z1, *z2, *z3, *alpha, *beta, *gamma, *t2;
    a = b = c = x = y = x2 = y2 = z1 = z2 = z3 = alpha = beta = gamma = t2 = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "A_0") {
            a = kv.first;
        } else if (kv.first->name == "B_0") {
            b = kv.first;
        } else if (kv.first->name == "C_0") {
            c = kv.first;
        } else if (kv.first->name == "X_0") {
            x = kv.first;
        } else if (kv.first->name == "Y_0") {
            y = kv.first;
        } else if (kv.first->name == "X2_0") {
            x2 = kv.first;
        } else if (kv.first->name == "Y2_0") {
            y2 = kv.first;
        } else if (kv.first->name == "Z1_0") {
            z1 = kv.first;
        } else if (kv.first->name == "Z2_0") {
            z2 = kv.first;
        } else if (kv.first->name == "Z3_0") {
            z3 = kv.first;
        } else if (kv.first->name == "alpha_0") {
            alpha = kv.first;
        } else if (kv.first->name == "beta_0") {
            beta = kv.first;
        } else if (kv.first->name == "gamma_0") {
            gamma = kv.first;
        } else if (kv.first->name == "t2_0") {
            t2 = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(x, nullptr);
    EXPECT_NE(y, nullptr);
    EXPECT_NE(x2, nullptr);
    EXPECT_NE(y2, nullptr);
    EXPECT_NE(z1, nullptr);
    EXPECT_NE(z2, nullptr);
    EXPECT_NE(z3, nullptr);
    EXPECT_NE(alpha, nullptr);
    EXPECT_NE(beta, nullptr);
    EXPECT_NE(gamma, nullptr);
    EXPECT_NE(t2, nullptr);

    EXPECT_EQ(dg.stage_info[a].min_stage, 0);
    EXPECT_EQ(dg.stage_info[b].min_stage, 0);
    EXPECT_EQ(dg.stage_info[c].min_stage, 0);
    EXPECT_EQ(dg.stage_info[x].min_stage, 0);
    EXPECT_EQ(dg.stage_info[y].min_stage, 0);
    EXPECT_EQ(dg.stage_info[x2].min_stage, 0);
    EXPECT_EQ(dg.stage_info[y2].min_stage, 0);
    EXPECT_EQ(dg.stage_info[z1].min_stage, 1);
    EXPECT_EQ(dg.stage_info[z2].min_stage, 2);
    EXPECT_EQ(dg.stage_info[z3].min_stage, 3);
    EXPECT_EQ(dg.stage_info[alpha].min_stage, 0);
    EXPECT_EQ(dg.stage_info[beta].min_stage, 1);
    EXPECT_EQ(dg.stage_info[gamma].min_stage, 2);
    EXPECT_EQ(dg.stage_info[t2].min_stage, 1);
}


/**
 * The dependency graph is the following:
 *
 *     A                C
 *     |                |
 *     | Data           | Control
 *     |                |
 *     V     Anti       V
 *     B -------------> D
 *
 * Thus the min stage of D must be 1, as the min stage of B is 1, and the ANTI dependency
 * pushes the min stage of D forward.
 */
TEST_F(TableDependencyGraphTest, AntiGraph1) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
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

    action set_f6(bit<8> f6) {
        headers.h1.f6 = f6;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { set_f4; }
        key = { headers.h1.f2 : exact;
                headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f5; }
        key = { headers.h1.f1 : exact; }
    }

    table node_d {
        actions = { set_f3; }
        key = { headers.h1.f1 : exact;
                headers.h1.f6 : exact; }
    }

    apply {
        node_a.apply();
        node_b.apply();
        if (node_c.apply().hit) {
            node_d.apply();
        }
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 1);
}

/**
 * The dependency graph is the following:
 *
 *     A                C
 *     |                |
 *     | Data           | Control
 *     |                | Data
 *     V     Anti       V
 *     B -------------> D
 *
 * Thus the min stage of D must be 1, as the min stage of B is 1, and the ANTI dependency
 * pushes the min stage of D forward.
 */
TEST_F(TableDependencyGraphTest, DomFrontier1) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
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

    action set_f6(bit<8> f6) {
        headers.h1.f6 = f6;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { set_f4; }
        key = { headers.h1.f2 : exact;
                headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f5; }
        key = { headers.h1.f1 : exact; }
    }

    table node_d {
        actions = { set_f3; }
        key = { headers.h1.f1 : exact;
                headers.h1.f5 : exact;
                headers.h1.f6 : exact; }
    }

    apply {
        node_a.apply();
        node_b.apply();
        if (node_c.apply().hit) {
            node_d.apply();
        }
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 2);
    EXPECT_EQ(dg.stage_info.at(c).dep_stages_dom_frontier, 1);
}

/**
 * The dependency graph is the following:
 *
 *     A ---------------------
 *     | Data      |          |
 *     | Control   | Control  | Control
 *     |           |          | 
 *     V   Anti    V   Data   V
 *     B --------> C -------> D
 *
 * Thus the min stage of D must be 1, as the min stage of B is 1, and the ANTI dependency
 * pushes the min stage of D forward.
 */
TEST_F(TableDependencyGraphTest, DomFrontier2) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
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

    action set_f6(bit<8> f6) {
        headers.h1.f6 = f6;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { set_f4; }
        key = { headers.h1.f2 : exact;
                headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f3; }
        key = { headers.h1.f1 : exact;
                headers.h1.f5 : exact; }
    }

    table node_d {
        actions = { set_f6; }
        key = { headers.h1.f3 : exact;
                headers.h1.f5 : exact; }
    }

    apply {
        if (node_a.apply().hit) {
            node_b.apply();
            node_c.apply();
            node_d.apply();
        }
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 2);
    EXPECT_EQ(dg.stage_info.at(a).dep_stages_dom_frontier, 2);
}

/**
 * The dependency graph is the following:
 *
 *     A                C
 *     |                |
 *     | Anti           | Anti
 *     |                |
 *     V     Data       V
 *     B -------------> D
 *
 * Thus the min stage of D must be 1, as the min stage of B is 0, and the ANTI dependency
 * pushes the min stage of D forward.
 */
TEST_F(TableDependencyGraphTest, AntiGraph2) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    action set_f4(bit<8> f4) {
        headers.h1.f4 = f4;
    }

    action set_f5(bit<8> f5) {
        headers.h1.f5 = f5;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f5; }
        key = { headers.h1.f4 : exact; }
    }

    table node_d {
        actions = { set_f4; }
        key = { headers.h1.f1 : exact; }
    }

    apply {
        node_a.apply();
        node_b.apply();
        node_c.apply();
        node_d.apply();
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 0);
    EXPECT_EQ(dg.min_stage(c), 0);
    EXPECT_EQ(dg.min_stage(d), 1);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 0);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
 * The graph is following for this program:
 *
 *         CONTROL
 *    A ------------> B
 *    |      DATA
 *    |
 *    | ANTI
 *    |
 *    V
 *    C
 *    |
 *    | DATA
 *    |
 *    V
 *    D
 *
 * Due to the next table propagation limitations, the ANTI dependency forces C to be placed
 * after A, and thus B, which pushes C into stage 1.
 */
TEST_F(TableDependencyGraphTest, LogicalThruControl) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action noop() {}

    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    action set_f4(bit<8> f4) {
        headers.h1.f4 = f4;
    }

    action set_f5(bit<8> f5) {
        headers.h1.f5 = f5;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_b {
        actions = { noop; }
        key = { headers.h1.f2 : exact; }
    }

    table node_c {
        actions = { set_f1; set_f5; }
        key = { headers.h1.f3 : exact; }
    }

    table node_d {
        actions = { noop; }
        key = { headers.h1.f5 : exact; }
    }

    apply {
        if (node_a.apply().hit) {
            node_b.apply();
        }
        node_c.apply();
        node_d.apply();
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);


    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 2);

    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 2);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
 * The graph is following for this program:
 *
 *         CONTROL
 *    A ------------> B
 *          DATA      |
 *                    |
 *                    | DATA
 *                    |
 *        CONTROL     V
 *    C ------------> D
 *
 *
 * Through next table propagation, in Tofino (not Tofino2), an ANTI dependency exists between
 * table A and C, (which is captured by the TableSeqDeps information)
 */
TEST_F(TableDependencyGraphTest, LogicalThruControl2) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action noop() {}

    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
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
        actions = { set_f2; }
        key = { headers.h1.f1 : exact; }
    }

    table node_c {
        actions = { set_f4; }
        key = { headers.h1.f4 : exact; }
    }

    table node_d {
        actions = { set_f2; }
        key = { headers.h1.f5 : exact; }
    }

    apply {
        if (node_a.apply().hit) {
            node_b.apply();
        }

        if (node_c.apply().hit) {
            node_d.apply();
        }
    } )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);


    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 2);

    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 2);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 0);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
   This should test the following graph:
   A --> B --> D
         |     ^
         v     |
         C ----
         |
         v
         E
 */
TEST_F(TableDependencyGraphTest, GraphA) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
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
        actions = { set_f5; }
        key = { headers.h1.f1 : exact; }
    }

    apply {
        node_a.apply();
        node_b.apply();
        node_c.apply();
        node_d.apply();
        node_e.apply();
    }
)"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);


    // the  suffix means it's ingress
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        } else if (kv.first->name == "node_e_0") {
            e = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);
    EXPECT_NE(e, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 2);
    EXPECT_EQ(dg.min_stage(d), 3);
    EXPECT_EQ(dg.min_stage(e), 2);

    EXPECT_EQ(dg.dependence_tail_size(a), 3);
    EXPECT_EQ(dg.dependence_tail_size(b), 2);
    EXPECT_EQ(dg.dependence_tail_size(c), 1);
    EXPECT_EQ(dg.dependence_tail_size(d), 0);
    EXPECT_EQ(dg.dependence_tail_size(e), 0);

    EXPECT_EQ(dg.happens_phys_before(a, b), true);
    EXPECT_EQ(dg.happens_phys_before(a, c), true);
    EXPECT_EQ(dg.happens_phys_before(a, e), true);
    EXPECT_EQ(dg.happens_phys_before(a, d), true);

    EXPECT_EQ(dg.happens_phys_before(b, a), false);
    EXPECT_EQ(dg.happens_phys_before(b, c), true);
    EXPECT_EQ(dg.happens_phys_before(b, d), true);
    EXPECT_EQ(dg.happens_phys_before(b, e), true);

    EXPECT_EQ(dg.happens_phys_before(c, a), false);
    EXPECT_EQ(dg.happens_phys_before(c, b), false);
    EXPECT_EQ(dg.happens_phys_before(c, d), true);
    EXPECT_EQ(dg.happens_phys_before(c, e), false);

    EXPECT_EQ(dg.happens_phys_before(d, a), false);
    EXPECT_EQ(dg.happens_phys_before(d, b), false);
    EXPECT_EQ(dg.happens_phys_before(d, c), false);
    EXPECT_EQ(dg.happens_phys_before(d, e), false);

    EXPECT_EQ(dg.happens_phys_before(e, a), false);
    EXPECT_EQ(dg.happens_phys_before(e, b), false);
    EXPECT_EQ(dg.happens_phys_before(e, c), false);
    EXPECT_EQ(dg.happens_phys_before(e, e), false);
}

TEST_F(TableDependencyGraphTest, HitMissValidation) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    action set_f1_and_exit(bit<8> f1) {
        headers.h1.f1 = f1;
        exit;
    }

    table node_a {
        actions = { set_f2;
                    @defaultonly set_f1; }
        key = { headers.h1.f3 : exact; }
        const default_action = set_f1(0x0);
    }


    table node_b {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    apply {
        if (!node_a.apply().hit) {
            node_b.apply();
            node_c.apply();
        }
    }
    )"));

    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);


    // the  suffix means it's ingress
    const IR::MAU::Table *a, *b, *c;
    a = b = c = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 1);
    EXPECT_EQ(dg.min_stage(c), 0);
}


TEST_F(TableDependencyGraphTest, ExitTest) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    action set_f1_and_exit(bit<8> f1) {
        headers.h1.f1 = f1;
        exit;
    }

    table node_a {
        actions = { set_f2;
                    set_f1_and_exit; }
        key = { headers.h1.f3 : exact; }
    }


    table node_b {
        actions = { set_f1_and_exit; }
        key = { headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    table node_d {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    apply {
        node_a.apply();
        node_b.apply();
        node_c.apply();
        node_d.apply();
    }
    )"));

    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);


    // the  suffix means it's ingress
    const IR::MAU::Table *a, *b, *c, *d;
    a = b = c = d = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    EXPECT_EQ(dg.min_stage(a), 0);
    EXPECT_EQ(dg.min_stage(b), 0);
    EXPECT_EQ(dg.min_stage(c), 1);
    EXPECT_EQ(dg.min_stage(d), 0);
}

TEST_F(TableDependencyGraphTest, LogicalVsPhysicalTest) {
    auto test = createTableDependencyGraphTestCase(
            P4_SOURCE(P4Headers::NONE, R"(
            action set_f1(bit<8> f1) {
              headers.h1.f1 = f1;
            }

            action set_f2(bit<8> f2) {
              headers.h1.f2 = f2;
            }

            table node_a {
              actions = { set_f2; }
                key = { headers.h1.f3 : exact; }
            }

            table node_b {
              actions = { set_f1; }
                key = { headers.h1.f2 : exact; }
            }

            table node_c {
              actions = { set_f2; }
                key = { headers.h1.f3 : exact; }
            }

            table node_d {
              actions = { set_f1; }
                key = { headers.h1.f3 : exact; }
            }

            table node_e {
              actions = { set_f1; }
                key = { headers.h1.f1 : exact; headers.h1.f2 : exact; }
            }

            table node_f {
              actions = { set_f1; }
                key = { headers.h1.f3 : exact; }
            }

            table node_g {
              actions = { set_f2; }
                key = { headers.h1.f3 : exact; }
            }

            table node_h {
              actions = { set_f2; }
                key = { headers.h1.f2 : exact; }
            }

            apply {
              if (node_a.apply().hit) {
                node_b.apply();
                node_c.apply();
              } else {
                node_d.apply();
              }
              if (node_e.apply().hit) {
                if (!node_f.apply().hit) {
                  node_g.apply();
                }
              }
              node_h.apply();
            })"));

    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);

    const IR::MAU::Table *a, *b, *c, *d, *e, *f, *g, *h;
    a = b = c = d = e = f = g = h = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0")
            a = kv.first;
        else if (kv.first->name == "node_b_0")
            b = kv.first;
        else if (kv.first->name == "node_c_0")
            c = kv.first;
        else if (kv.first->name == "node_d_0")
            d = kv.first;
        else if (kv.first->name == "node_e_0")
            e = kv.first;
        else if (kv.first->name == "node_f_0")
            f = kv.first;
        else if (kv.first->name == "node_g_0")
            g = kv.first;
        else if (kv.first->name == "node_h_0")
            h = kv.first;
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);
    EXPECT_NE(e, nullptr);
    EXPECT_NE(f, nullptr);
    EXPECT_NE(g, nullptr);
    EXPECT_NE(h, nullptr);

    auto hpam = dg.happens_phys_after_map;
    auto hlam = dg.happens_logi_after_map;

    // Expected physical sets
    std::set<const IR::MAU::Table*> pd_a;
    std::set<const IR::MAU::Table*> pd_b {a};
    std::set<const IR::MAU::Table*> pd_c {a};
    std::set<const IR::MAU::Table*> pd_d;
    std::set<const IR::MAU::Table*> pd_e {a, b, c, d};
    std::set<const IR::MAU::Table*> pd_f {a, b, c, d, e};  // WAW on f1
    std::set<const IR::MAU::Table*> pd_g {a, c};  // WAW on f2
    std::set<const IR::MAU::Table*> pd_h {a, c, g};  // RAW/WAW on f2

    // Expected logical sets
    std::set<const IR::MAU::Table*> ld_a;
    std::set<const IR::MAU::Table*> ld_b {a};
    std::set<const IR::MAU::Table*> ld_c {a, b};
    std::set<const IR::MAU::Table*> ld_d {a};
    std::set<const IR::MAU::Table*> ld_e {a, b, c, d};
    std::set<const IR::MAU::Table*> ld_f {a, b, c, e, d};
    std::set<const IR::MAU::Table*> ld_g {a, b, c, d, e, f};
    std::set<const IR::MAU::Table*> ld_h {a, b, c, d, e, f, g};

    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>>
        physical_sets {{a, pd_a}, {b, pd_b}, {c, pd_c}, {d, pd_d}, {e, pd_e}, {f, pd_f},
                       {g, pd_g}, {h, pd_h}};
    std::map<const IR::MAU::Table*, std::set<const IR::MAU::Table*>>
        logical_sets {{a, ld_a}, {b, ld_b}, {c, ld_c}, {d, ld_d}, {e, ld_e}, {f, ld_f},
                      {g, ld_g}, {h, ld_h}};

    // Check physical dependence sets are correct
    for (auto it = physical_sets.begin(), end = physical_sets.end();
         it != end; ++it) {
        for (auto d : (*it).second) {
            EXPECT_TRUE(hpam[(*it).first].count(d));
        }
    }
    // Check logical dependence sets are correct
    for (auto it = logical_sets.begin(), end = logical_sets.end();
         it != end; ++it) {
        for (auto d : (*it).second) {
            EXPECT_TRUE(hlam[(*it).first].count(d));
        }
    }
}

/**
 * This is to verify the control pathways and next table pathways, which are eventually
 * added into the dependency graph for correct chain lengths
 *
 * There are pathways down from the table, i.e. the control dominating set, and the
 * tables that have control dependents
 */
TEST_F(TableDependencyGraphTest, ControlPathwayValidation) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    action set_f1(bit<8> f1) {
        headers.h1.f1 = f1;
    }

    action set_f2(bit<8> f2) {
        headers.h1.f2 = f2;
    }

    table node_a {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    table node_b {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_c {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_d {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    table node_e {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    table node_f {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_g {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_h {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_i {
        actions = { set_f1; }
        key = { headers.h1.f3 : exact; }
    }

    table node_j {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    table node_k {
        actions = { set_f2; }
        key = { headers.h1.f3 : exact; }
    }

    apply {
        if (node_a.apply().hit) {
            node_b.apply();
            node_c.apply();
        } else {
            node_d.apply();
        }

        if (node_e.apply().hit) {
            if (node_f.apply().hit) {
                node_g.apply();
            } else {
                if (node_h.apply().hit) {
                    node_i.apply();
                }
            }
            node_j.apply();
        }
        node_k.apply();
    })"));

    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    const IR::MAU::Table *a, *b, *c, *d, *e, *f, *g, *h, *i, *j, *k;
    a = b = c = d = e = f = g = h = i = j = nullptr;

    CalculateNextTableProp ntp;
    ControlPathwaysToTable ctrl_paths;
    test->pipe = test->pipe->apply(ntp);
    test->pipe = test->pipe->apply(ctrl_paths);

    a = ntp.get_table("node_a_0");
    b = ntp.get_table("node_b_0");
    c = ntp.get_table("node_c_0");
    d = ntp.get_table("node_d_0");
    e = ntp.get_table("node_e_0");
    f = ntp.get_table("node_f_0");
    g = ntp.get_table("node_g_0");
    h = ntp.get_table("node_h_0");
    i = ntp.get_table("node_i_0");
    j = ntp.get_table("node_j_0");
    k = ntp.get_table("node_k_0");

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);
    EXPECT_NE(e, nullptr);
    EXPECT_NE(f, nullptr);
    EXPECT_NE(g, nullptr);
    EXPECT_NE(h, nullptr);
    EXPECT_NE(i, nullptr);
    EXPECT_NE(j, nullptr);
    EXPECT_NE(k, nullptr);

    auto a_ntl = ntp.next_table_leaves.at(a);
    auto a_cds = ntp.control_dom_set.at(a);

    EXPECT_EQ(a_ntl.size(), 3);
    EXPECT_EQ(a_ntl.count(b), 1);
    EXPECT_EQ(a_ntl.count(c), 1);
    EXPECT_EQ(a_ntl.count(d), 1);
    EXPECT_EQ(a_cds.size(), 4);
    EXPECT_EQ(a_cds.count(a), 1);
    EXPECT_EQ(a_cds.count(b), 1);
    EXPECT_EQ(a_cds.count(c), 1);
    EXPECT_EQ(a_cds.count(d), 1);

    auto e_ntl = ntp.next_table_leaves.at(e);
    auto e_cds = ntp.control_dom_set.at(e);

    EXPECT_EQ(e_ntl.size(), 3);
    EXPECT_EQ(e_ntl.count(g), 1);
    EXPECT_EQ(e_ntl.count(i), 1);
    EXPECT_EQ(e_ntl.count(j), 1);
    EXPECT_EQ(e_cds.size(), 6);
    EXPECT_EQ(e_cds.count(e), 1);
    EXPECT_EQ(e_cds.count(f), 1);
    EXPECT_EQ(e_cds.count(g), 1);
    EXPECT_EQ(e_cds.count(h), 1);
    EXPECT_EQ(e_cds.count(i), 1);
    EXPECT_EQ(e_cds.count(j), 1);

    auto inj_1 = ctrl_paths.get_inject_points(c, g);
    EXPECT_EQ(inj_1.size(), 1);
    EXPECT_EQ(inj_1.at(0).first, a);
    EXPECT_EQ(inj_1.at(0).second, e);

    auto inj_2 = ctrl_paths.get_inject_points(g, j);
    EXPECT_EQ(inj_2.size(), 1);
    EXPECT_EQ(inj_2.at(0).first, f);
    EXPECT_EQ(inj_2.at(0).second, j);

    auto inj_3 = ctrl_paths.get_inject_points(d, k);
    EXPECT_EQ(inj_3.size(), 1);
    EXPECT_EQ(inj_3.at(0).first, a);
    EXPECT_EQ(inj_3.at(0).second, k);

    auto inj_4 = ctrl_paths.get_inject_points(f, i);
    EXPECT_EQ(inj_4.size(), 0);
    auto inj_5 = ctrl_paths.get_inject_points(g, i);
    EXPECT_EQ(inj_5.size(), 0);
}

/**
 * This tests the length of dependency chains induced by "exit". The dependency graph is the
 * following:
 *
 *           Anti*           Anti*           Data
 *     A ------------> B ------------> C ------------> D
 *                   exits                             ^
 *                     |                               |
 *                     +-------------------------------+
 *                                   Anti*
 *   * - induced by exit
 *
 * We expect the following chain lengths.
 *
 *   A: 1
 *   B: 1
 *   C: 1
 *   D: 0
 */
TEST_F(TableDependencyGraphTest, ExitGraph1) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
                action noop() { }

                table node_a {
                    actions = { noop; }
                    key = { headers.h1.f1 : exact; }
                }

                action do_exit() { exit; }

                table node_b {
                    actions = { do_exit; }
                    key = { headers.h1.f2 : exact; }
                }

                action set_f3(bit<8> v) { headers.h1.f3 = v; }

                table node_c {
                    actions = { set_f3; }
                    key = { headers.h1.f4 : exact; }
                }

                table node_d {
                    actions = { noop; }
                    key = { headers.h1.f3 : exact; }
                }

                apply {
                    node_a.apply();
                    node_b.apply();
                    node_c.apply();
                    node_d.apply();
                }
            )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d;
    a = b = c = d = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
 * This tests the length of dependency chains induced by "exit". The dependency graph is the
 * following:
 *
 *                           Data
 *     A               C ============> D
 *     |             exits   Anti*
 *     |               ^
 *     | Control       | Anti*
 *     v               |
 *     B --------------+
 *
 *   * - induced by exit
 *
 * We expect the following chain lengths.
 *
 *   A: 1
 *   B: 1
 *   C: 1
 *   D: 0
 */
TEST_F(TableDependencyGraphTest, ExitGraph2) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
                action noop() { }

                table node_a {
                    actions = { noop; }
                    key = { headers.h1.f1 : exact; }
                }

                table node_b {
                    actions = { noop; }
                    key = { headers.h1.f2 : exact; }
                }

                action do_exit() { exit; }
                action set_f3(bit<8> v) { headers.h1.f3 = v; }

                table node_c {
                    actions = { do_exit; set_f3; }
                    key = { headers.h1.f4 : exact; }
                }

                table node_d {
                    actions = { noop; }
                    key = { headers.h1.f3 : exact; }
                }

                apply {
                    if (node_a.apply().hit) {
                        node_b.apply();
                    }
                    node_c.apply();
                    node_d.apply();
                }
            )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d;
    a = b = c = d = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
 * This tests the length of dependency chains induced by "exit". The dependency graph is the
 * following:
 *
 *                Anti*          Data
 *         A   +---------> C ------------> E
 *         |   |           |               ^
 * Control |   |           | Control       | Anti*
 *         v   |           v               |
 *         B --+           D --------------+
 *                       exits
 *
 *   * - induced by exit
 *
 * We expect the following chain lengths.
 *
 *   A: 1
 *   B: 1
 *   C: 1
 *   D: 0
 *   E: 0
 */
TEST_F(TableDependencyGraphTest, ExitGraph3) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
                action noop() { }

                table node_a {
                    actions = { noop; }
                    key = { headers.h1.f1 : exact; }
                }

                table node_b {
                    actions = { noop; }
                    key = { headers.h1.f2 : exact; }
                }

                action set_f3(bit<8> v) { headers.h1.f3 = v; }

                table node_c {
                    actions = { set_f3; }
                    key = { headers.h1.f4 : exact; }
                }

                action do_exit() { exit; }

                table node_d {
                    actions = { do_exit; }
                    key = { headers.h1.f5 : exact; }
                }

                table node_e {
                    actions = { noop; }
                    key = {headers.h1.f3 : exact; }
                }

                apply {
                    if (node_a.apply().hit) {
                        node_b.apply();
                    }
                    if (node_c.apply().hit) {
                        node_d.apply();
                    }
                    node_e.apply();
                }
            )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e;
    a = b = c = d = e = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        } else if (kv.first->name == "node_e_0") {
            e = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);
    EXPECT_NE(e, nullptr);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(e), 0);
}

/**
 * This tests the length of dependency chains induced by "exit". The dependency graph is the
 * following:
 *
 *                           Data
 *     A               C ------------> D
 *     |               ^               ^
 *     |               |               |
 *     | Control       | Anti*         | Anti*
 *     v               |               |
 *     B ==============+---------------+
 *   exits
 *
 *   * - induced by exit
 *
 * We expect the following chain lengths.
 *
 *   A: 1
 *   B: 1
 *   C: 1
 *   D: 0
 */
TEST_F(TableDependencyGraphTest, ExitGraph4) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
                action noop() { }

                table node_a {
                    actions = { noop; }
                    key = { headers.h1.f1 : exact; }
                }

                action do_exit() { exit; }
                table node_b {
                    actions = { do_exit; }
                    key = { headers.h1.f2 : exact; }
                }

                action set_f3(bit<8> v) { headers.h1.f3 = v; }

                table node_c {
                    actions = { do_exit; set_f3; }
                    key = { headers.h1.f4 : exact; }
                }

                table node_d {
                    actions = { noop; }
                    key = { headers.h1.f3 : exact; }
                }

                apply {
                    if (node_a.apply().hit) {
                        node_b.apply();
                    }
                    node_c.apply();
                    node_d.apply();
                }
            )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d;
    a = b = c = d = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 0);
}

/**
 * This tests the length of dependency chains induced by "exit". The dependency graph is the
 * following:
 *                                             Data
 *       A               B               F ------------> G
 *                       ^
 *                      /|\
 *             Control / | \ Control
 *                    /  |  \
 *                   v   v   v
 *                  C    D    E
 *                exits     exits
 *
 * with the following anti-dependency edges induced:
 *
 *   A -> C    A -> D    A -> E
 *   C -> F    D -> F    E -> F
 *   C -> G    D -> G    E -> G
 *
 * We expect the following chain lengths.
 *
 *   A: 1
 *   B: 1
 *   C: 1
 *   D: 1
 *   E: 1
 *   F: 1
 *   G: 0
 */
TEST_F(TableDependencyGraphTest, ExitGraph5) {
    auto test = createTableDependencyGraphTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
                action noop() { }

                table node_a {
                    actions = { noop; }
                    key = { headers.h1.f1 : exact; }
                }

                action c() {}
                action d() {}
                action e() {}
                table node_b {
                    actions = { c; d; e; }
                    key = { headers.h1.f2 : exact; }
                }

                action do_exit() { exit; }
                table node_c {
                    actions = { do_exit; }
                    key = { headers.h1.f3 : exact; }
                }

                table node_d {
                    actions = { noop; }
                    key = { headers.h1.f4 : exact; }
                }

                table node_e {
                    actions = { do_exit; }
                    key = { headers.h1.f5 : exact; }
                }

                action set_f6(bit<8> v) { headers.h1.f6 = v; }
                table node_f {
                    actions = { set_f6; }
                    key = { headers.h2.f7 : exact; }
                }

                table node_g {
                    actions = { noop; }
                    key = { headers.h1.f6 : exact; }
                }

                apply {
                    node_a.apply();
                    switch (node_b.apply().action_run) {
                        c: { node_c.apply(); }
                        d: { node_d.apply(); }
                        e: { node_e.apply(); }
                    }
                    node_f.apply();
                    node_g.apply();
                }
            )"));

    ASSERT_TRUE(test);
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    DependencyGraph dg;

    test->pipe = runMockPasses(test->pipe, phv, defuse);

    auto *find_dg = new FindDependencyGraph(phv, dg);
    test->pipe->apply(*find_dg);
    const IR::MAU::Table *a, *b, *c, *d, *e, *f, *g;
    a = b = c = d = e = f = g = nullptr;
    for (const auto& kv : dg.stage_info) {
        if (kv.first->name == "node_a_0") {
            a = kv.first;
        } else if (kv.first->name == "node_b_0") {
            b = kv.first;
        } else if (kv.first->name == "node_c_0") {
            c = kv.first;
        } else if (kv.first->name == "node_d_0") {
            d = kv.first;
        } else if (kv.first->name == "node_e_0") {
            e = kv.first;
        } else if (kv.first->name == "node_f_0") {
            f = kv.first;
        } else if (kv.first->name == "node_g_0") {
            g = kv.first;
        }
    }

    EXPECT_NE(a, nullptr);
    EXPECT_NE(b, nullptr);
    EXPECT_NE(c, nullptr);
    EXPECT_NE(d, nullptr);
    EXPECT_NE(e, nullptr);
    EXPECT_NE(f, nullptr);
    EXPECT_NE(g, nullptr);

    // Chain the dependence through the ANTI dependence
    EXPECT_EQ(dg.dependence_tail_size_control_anti(a), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(b), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(c), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(d), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(e), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(f), 1);
    EXPECT_EQ(dg.dependence_tail_size_control_anti(g), 0);
}

}  // namespace Test
