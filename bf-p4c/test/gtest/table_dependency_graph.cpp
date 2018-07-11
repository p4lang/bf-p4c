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
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new InstructionSelection(phv),
        new CollectPhvInfo(phv),
        &defuse,
    };
    return pipe->apply(quick_backend);
}

}  // namespace


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
