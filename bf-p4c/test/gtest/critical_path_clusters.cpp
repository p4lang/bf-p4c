#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/analysis/critical_path_clusters.h"
#include "bf-p4c/phv/analysis/mutex_overlay.h"
#include "bf-p4c/phv/analysis/pack_conflicts.h"
#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class CriticalPathClustersTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createCriticalPathClustersTestCase(const std::string& ingressPipeline,
                                   const std::string& egressPipeline) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
header Eth { bit<8> nxt; }
header H1 { bit<8> f1; bit<32> f2; }
header H2 { bit<64> f1; bit<64> f2; bit<64> f3; }
struct Headers { Eth eth; H1 h1; H2 h2; }
struct Metadata { bit<8> f1; H2 f2; }

parser parse(packet_in packet, out Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
    state start {
        packet.extract(headers.eth);
        transition select(headers.eth.nxt) {
            5 : parseH1;
            6 : parseH2;
            default: accept;
        }
    }

    state parseH1 {
        packet.extract(headers.h1);
        transition accept;
    }

    state parseH2 {
        packet.extract(headers.h2);
        transition accept;
    }
}

control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }
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
        packet.emit(headers.eth);
        packet.emit(headers.h1);
        packet.emit(headers.h2);
    }
}

V1Switch(parse(), verifyChecksum(), ingress(), egress(),
    computeChecksum(), deparse()) main;

    )");

    boost::replace_first(source, "%INGRESS_PIPELINE%", ingressPipeline);
    boost::replace_first(source, "%EGRESS_PIPELINE%", egressPipeline);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv,
                                   PhvUse& uses,
                                   FieldDefUse& defuse,
                                   Clustering& clustering,
                                   MauBacktracker& table_alloc,
                                   DependencyGraph& deps,
                                   PackConflicts& conflicts,
                                   MapTablesToActions& tableActionsMap,
                                   ActionPhvConstraints& actions,
                                   CalcParserCriticalPath& parser_critical_path,
                                   PragmaContainerSize& pragma) {
    PHV::Pragmas* pragmas = new PHV::Pragmas(phv);
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new DoInstructionSelection(phv),
        &defuse,
        new ElimUnused(phv, defuse),
        &table_alloc,
        &uses,
        pragmas,
        new MutexOverlay(phv, *pragmas),
        &parser_critical_path,
        new FindDependencyGraph(phv, deps),
        &defuse,
        &conflicts,
        &tableActionsMap,
        &actions,
        new PHV_Field_Operations(phv),
        &pragma,
        &clustering,
    };
    return pipe->apply(quick_backend);
}

std::vector<cstring> slices_to_names(const ordered_set<PHV::FieldSlice>& slices) {
    std::vector<cstring> rtn(slices.size());
    transform(slices.begin(), slices.end(), rtn.begin(),
              [] (const PHV::FieldSlice& slice) {
                  return slice.field()->name;
              });
    sort(rtn.begin(), rtn.end());
    return rtn;
}

bool resultHas(const std::set<PHV::SuperCluster *>& result,
               const std::vector<cstring>& field_names) {
    for (const auto& super_cluster : result) {
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* aligned_cluster : rotational_cluster->clusters()) {
                const auto& slices = aligned_cluster->slices();
                if (slices.size() == field_names.size()
                    && slices_to_names(slices) == field_names) {
                    return true; } } } }
    return false;
}

}  // namespace

TEST_F(CriticalPathClustersTest, DISABLED_Basic) {
    auto test = createCriticalPathClustersTestCase(P4_SOURCE(P4Headers::NONE, R"(
        action first(bit<8> param1, bit<32> param2) {
            headers.h1.f1 = param1;
            headers.h1.f2 = param2;
        }

        action second(bit<64> param1) {
            headers.h2.f3 = headers.h2.f1 & headers.h2.f2;
        }

        table test1 {
            key = { headers.h1.f1: ternary; }
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

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    PhvUse uses(phv);
    MauBacktracker table_alloc(phv.field_mutex());
    DependencyGraph deps;
    TablesMutuallyExclusive table_mutex;
    ActionMutuallyExclusive action_mutex;
    PackConflicts conflicts(phv, deps, table_mutex, table_alloc, action_mutex);
    MapTablesToActions tableActionsMap;
    ActionPhvConstraints actions(phv, uses, conflicts, tableActionsMap, deps);
    CalcParserCriticalPath parser_critical_path(phv);
    FieldDefUse defuse(phv);
    PragmaContainerSize pragma(phv);
    Clustering clustering(phv, uses, conflicts, pragma, actions);

    auto *post_pm_pipe = runMockPasses(test->pipe, phv, uses,
                                       defuse,
                                       clustering,
                                       table_alloc,
                                       deps, conflicts, tableActionsMap, actions,
                                       parser_critical_path, pragma);

    auto *cluster_cp = new CalcCriticalPathClusters(parser_critical_path);
    post_pm_pipe = post_pm_pipe->apply(*cluster_cp);
    std::set<PHV::SuperCluster *> result =
        cluster_cp->calc_critical_clusters(clustering.cluster_groups());

    EXPECT_EQ(resultHas(result, {"ingress::eth.nxt"}), true);
    EXPECT_EQ(resultHas(result, {"ingress::eth.$valid"}), true);
    EXPECT_EQ(resultHas(result, {"ingress::h2.f1",
                                 "ingress::h2.f2",
                                 "ingress::h2.f3"}), true);

    EXPECT_EQ(resultHas(result, {"ingress::h1.f1",
                                 "ingress::h1.f2"}), false);
}

}  // namespace Test
