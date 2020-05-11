#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <initializer_list>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/mau/add_always_run.h"
#include "bf-p4c/mau/table_flow_graph.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class AddAlwaysRunTest : public JBayBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createAddAlwaysRunTestCase(const std::string& parserSource) {
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

    auto result = TofinoPipeTestCase::createWithThreadLocalInstances(source);
    if (result) {
        // Apply MultipleApply to de-duplicate table nodes.
        result->pipe = result->pipe->apply(MultipleApply(BackendOptions(), boost::none, true));
    }

    return result;
}

}  // namespace

/// @returns a map for each gress from external table names to their unique IDs.
std::map<gress_t, std::map<cstring, UniqueId>>
getTables(boost::optional<TofinoPipeTestCase> test) {
    std::map<gress_t, std::map<cstring, UniqueId>> result;

    // Kludge: to avoid writing our own visitor, build a flow graph and get the tables from there.
    ordered_map<gress_t, FlowGraph> graphs;
    FindFlowGraphs ffg(graphs);
    test->pipe->apply(ffg);

    for (auto& gress_graph : graphs) {
        auto& graph = gress_graph.second;
        for (auto* table : graph.get_tables()) {
            result[table->gress][table->externalName()] = table->pp_unique_id();
        }
    }

    return result;
}

/// Common test functionality.
void runTest(
    boost::optional<TofinoPipeTestCase> test,
    ordered_map<gress_t, AddAlwaysRun::ConstraintMap> tablesToAdd
) {
    // Insert tables.
    AddAlwaysRun addAlwaysRun(tablesToAdd);
    auto* result = test->pipe->apply(addAlwaysRun);

    // Check that the result conforms to IR invariants.
    MultipleApply ma(BackendOptions());
    result->apply(ma);
    EXPECT_EQ(ma.num_mutex_errors(), 0UL);
    EXPECT_EQ(ma.num_topological_errors(), 0UL);

    // Build flow graphs for the result.
    ordered_map<gress_t, FlowGraph> graphs;
    FindFlowGraphs ffg(graphs);
    result->apply(ffg);

    // Build a map for each gress from unique IDs to tables.
    std::map<gress_t, std::map<UniqueId, const IR::MAU::Table*>> tables;
    for (auto& gress_graph : graphs) {
        auto& graph = gress_graph.second;

        for (auto* table : graph.get_tables()) {
            tables[table->gress][table->pp_unique_id()] = table;
        }
    }

    // Use the flow graphs to check that the result conforms to the insertion constraints and that
    // the tables we inserted are executed on all paths.
    for (auto& gress_constraintMap : tablesToAdd) {
        auto& gress = gress_constraintMap.first;
        auto& constraintMap = gress_constraintMap.second;

        auto& graph = graphs.at(gress);

        for (auto& table_constraints : constraintMap) {
            auto* table = table_constraints.first;
            auto& constraints = table_constraints.second;

            auto& tableIdsBefore = constraints.first;
            auto& tableIdsAfter = constraints.second;

            // Convert the inserted table into the corresponding Table object inhabiting the
            // result.
            table = tables[table->gress][table->pp_unique_id()];

            // Check tables that should come before the inserted table.
            for (auto& beforeId : tableIdsBefore) {
                auto* beforeTable = tables[table->gress][beforeId];
                ASSERT_TRUE(graph.can_reach(beforeTable, table));
            }

            // Check tables that should come after the inserted table.
            for (auto& afterId : tableIdsAfter) {
                auto* afterTable = tables[table->gress][afterId];
                ASSERT_TRUE(graph.can_reach(table, afterTable));
            }

            // Check that the table is executed on all paths. Do this by checking that the table
            // dominates the graph's sink node.
            ASSERT_TRUE(graph.is_always_reached(table));
        }
    }
}

/// Basic test case.
TEST_F(AddAlwaysRunTest, BasicControlFlow) {
    auto test = createAddAlwaysRunTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

    action act1_1() {}
    action act1_2() {}
    action act1_3() {}
    action act1_4() {}
    action act1_5() {}

    table t1 {
        key = {
            headers.h2.f2 : exact;
        }
        actions = {
            act1_1;
            act1_2;
            act1_3;
            act1_4;
            act1_5;
        }
        size = 8192;
    }

    action act2() {}

    table t2 {
        key = {
            headers.h2.b1 : exact;
        }
        actions  = {
            act2;
        }
        size = 8192;
    }

    action act3() {}

    table t3 {
        key = {
            headers.h2.f1 : exact;
        }
        actions = {
            act3;
        }
        size = 65536;
    }

    action act4() {}

    table t4 {
        key = {
            headers.h2.f1 : exact;
        }
        actions = {
            act4;
        }
        size = 65536;
    }

    action act5() {}

    table t5 {
        key = {
            headers.h2.f1 : exact;
        }
        actions = {
            act5;
        }
        size = 95536;
    }

apply {
    switch (t1.apply().action_run) {
    act1_1: { t2.apply(); t3.apply(); }
    act1_2: { t2.apply(); }
    act1_3: { t3.apply(); }
    act1_4: { t4.apply(); }
    }
    t5.apply();
}
    )"));
    ASSERT_TRUE(test);

    auto tables = getTables(test);

    // Create the table to be inserted and its constraints.
    auto* to_insert = new IR::MAU::Table("always_run", INGRESS);
    ordered_map<gress_t, AddAlwaysRun::ConstraintMap> tablesToAdd;
    tablesToAdd[INGRESS][to_insert].first.insert(tables.at(INGRESS).at("mau.t2"));
    tablesToAdd[INGRESS][to_insert].second.insert(tables.at(INGRESS).at("mau.t3"));

    runTest(test, tablesToAdd);
}

/*
    switch (t1.apply().action_run) {
    act1_1: { t2.apply(); t3.apply(); }
    act1_2: { t2.apply(); t4.apply(); }
    act1_3: { t3.apply(); t4.apply(); }
    }
    t5.apply();

        ------
      /        \
    t1 -> t2 -> t3 -> t5
            \   V    /
             -> t4 -

 */
}  // namespace Test
