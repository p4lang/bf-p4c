#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <initializer_list>
#include <vector>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/phv/analysis/meta_live_range.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class MetadataLiveRangeTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createMetadataLiveRangeTestCase(const std::string& mauSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
header H1
{
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
    bit<8> f4;
}

struct Headers { H1 h1;}

struct Metadata {
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
    bit<8> f4;
}

parser parse(packet_in packet, out Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
    state start {
        packet.extract(headers.h1);
        transition accept;
    }
}

control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control ingress(inout Headers headers, inout Metadata meta,
    inout standard_metadata_t sm) {
%MAU%
}

control egress(inout Headers hdr, inout Metadata meta, inout standard_metadata_t standard_metadata) {
    apply { }
}

control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

control deparse(packet_out packet, in Headers headers) {
    apply { packet.emit(headers.h1); }
}

V1Switch(parse(), verifyChecksum(), ingress(), egress(), computeChecksum(), deparse()) main;
    )");

    boost::replace_first(source, "%MAU%", mauSource);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe* runMockPasses(
        const IR::BFN::Pipe* pipe,
        PhvInfo& phv,
        FieldDefUse& defuse,
        DependencyGraph& deps,
        PhvUse& uses,
        PHV::Pragmas& pragmas,
        MauBacktracker& entry,
        MetadataLiveRange& metaLiveRange) {
    auto options = new BFN_Options();  // dummy options used in Pass
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new InstructionSelection(*options, phv),
        &defuse,
        new ElimUnused(phv, defuse),
        new ElimUnusedHeaderStackInfo,
        new CollectPhvInfo(phv),
        &entry,
        &uses,
        &pragmas,
        new FindDependencyGraph(phv, deps),
        &defuse,
        &metaLiveRange
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(MetadataLiveRangeTest, BasicControlFlow) {
    auto test = createMetadataLiveRangeTestCase(
        P4_SOURCE(P4Headers::NONE, R"(

    action do1() {
        headers.h1.f1 = 6;
        headers.h1.f2 = 122;
        headers.h1.f3 = 4;
        headers.h1.f4 = 169;
    }

    action do2() {
        meta.f2 = 2;
        meta.f3 = 4;
    }

    action do3() {
        headers.h1.f4 = meta.f1;
        sm.egress_spec = sm.ingress_port;
    }

    action do4() {
        meta.f1 = 1;
        meta.f2 = 2;
    }

    action do5() {
        headers.h1.f1 = meta.f4;
        headers.h1.f2 = meta.f3;
        headers.h1.f3 = meta.f2;
        headers.h1.f4 = meta.f1;
    }

    table t1 {
        key = { headers.h1.f1 : exact; }
        actions = { do1; }
        size = 512;
    }

    table t2 {
        key = { headers.h1.f3 : exact; }
        actions = { do2; }
        size = 512;
    }

    table t3 {
        key = { meta.f2 : exact; }
        actions = { do3; }
        size = 512;
    }

    table t4 {
        key = { headers.h1.f4 : exact; }
        actions = { do4; }
        size = 512;
    }

    table t5 {
        key = { meta.f1 : exact; }
        actions = { do5; }
        size = 512;
    }

    apply {
        t1.apply();
        t2.apply();
        t3.apply();
        t4.apply();
        t5.apply();
    }

    )"));
    ASSERT_TRUE(test);

    DependencyGraph deps;
    PhvInfo phv;
    FieldDefUse defuse(phv);
    PhvUse uses(phv);
    PHV::Pragmas pragmas(phv);
    MauBacktracker entry;
    MetadataLiveRange metaLive(phv, deps, defuse, pragmas, uses, entry);

    auto *pipe = test->pipe;
    pipe = runMockPasses(pipe, phv, defuse, deps, uses, pragmas, entry, metaLive);
    ASSERT_TRUE(pipe);

    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f1")->id), true);
    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f2")->id), true);

    const auto& livemap = metaLive.getMetadataLiveMap();
    auto meta_f1_map = livemap.at(phv.field("ingress::meta.f1")->id);
    EXPECT_EQ(meta_f1_map.first, 2);
    EXPECT_EQ(meta_f1_map.second, 4);
    auto meta_f2_map = livemap.at(phv.field("ingress::meta.f2")->id);
    EXPECT_EQ(meta_f2_map.first, 1);
    EXPECT_EQ(meta_f2_map.second, 4);
    auto meta_f3_map = livemap.at(phv.field("ingress::meta.f3")->id);
    EXPECT_EQ(meta_f3_map.first, 1);
    EXPECT_EQ(meta_f3_map.second, 4);
    auto meta_f4_map = livemap.at(phv.field("ingress::meta.f4")->id);
    EXPECT_EQ(meta_f4_map.first, 4);
    EXPECT_EQ(meta_f4_map.second, 4);
}
}  // namespace Test
