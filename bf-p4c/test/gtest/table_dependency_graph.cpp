#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

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

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv, FieldDefUse& defuse) {
    PassManager quick_backend = {
        new MultipleApply,
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new InstructionSelection(phv),
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
            a1 : {
                t4.apply();
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
        } else if (kv.first->name == "t4_0.0") {
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
            EXPECT_EQ(edge_type, DependencyGraph::CONTROL);
        }
        if (src == t3 && dst == t4) {
            num_checks++;
            EXPECT_EQ(edge_type, DependencyGraph::CONTROL);
        }
        if (src == t2) {
            num_checks++;
            EXPECT_NE(dst, t4);
        }
    }
    EXPECT_EQ(num_checks, NUM_CHECKS_EXPECTED);
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


    // the _0 suffix means it's ingress
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

    EXPECT_EQ(dg.happens_before(a, b), true);
    EXPECT_EQ(dg.happens_before(a, c), true);
    EXPECT_EQ(dg.happens_before(a, e), true);
    EXPECT_EQ(dg.happens_before(a, d), true);

    EXPECT_EQ(dg.happens_before(b, a), false);
    EXPECT_EQ(dg.happens_before(b, c), true);
    EXPECT_EQ(dg.happens_before(b, d), true);
    EXPECT_EQ(dg.happens_before(b, e), true);

    EXPECT_EQ(dg.happens_before(c, a), false);
    EXPECT_EQ(dg.happens_before(c, b), false);
    EXPECT_EQ(dg.happens_before(c, d), true);
    EXPECT_EQ(dg.happens_before(c, e), false);

    EXPECT_EQ(dg.happens_before(d, a), false);
    EXPECT_EQ(dg.happens_before(d, b), false);
    EXPECT_EQ(dg.happens_before(d, c), false);
    EXPECT_EQ(dg.happens_before(d, e), false);

    EXPECT_EQ(dg.happens_before(e, a), false);
    EXPECT_EQ(dg.happens_before(e, b), false);
    EXPECT_EQ(dg.happens_before(e, c), false);
    EXPECT_EQ(dg.happens_before(e, e), false);
}
}  // namespace Test
