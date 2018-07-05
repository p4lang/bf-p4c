#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/metadata_init.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class PragmaNoInitTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createPragmaNoInitTestCase(const std::string& parserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
header H1
{
    bit<8> f1;
    bit<8> f2;
}

struct Headers { H1 h1; }

@pa_no_init("ingress", "meta.f2")
struct Metadata {
    bit<8> f1;
    bit<8> f2;
}

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
                                   PhvInfo& phv,
                                   FieldDefUse& defuse,
                                   DependencyGraph& deps) {
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        &defuse,
        new FindDependencyGraph(phv, deps),
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(PragmaNoInitTest, InitAction) {
    auto test = createPragmaNoInitTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
action do1() {
    meta.f1 = 1;
}

action do2() {
    meta.f2 = 2;
}

action do3() {
    headers.h1.f1 = meta.f1;
    headers.h1.f2 = meta.f2;
}

table t1 {
    key = { headers.h1.f1 : exact; }
    actions = { do1; do2; }
}

table t2 {
    key = { meta.f1 : exact; meta.f2 : exact; }
    actions = { do3; }
}

apply {
    t1.apply();
    t2.apply();
}
)"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    DependencyGraph deps;

    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);

    auto* pipe = runMockPasses(test->pipe, phv, defuse, deps);
    ASSERT_TRUE(pipe);

    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f1")->id), true);
    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f2")->id), true);

    auto* metadata_init =
        new MetadataInitialization(false, phv, defuse, deps);
    auto* after_init = pipe->apply(*metadata_init);
    ASSERT_TRUE(after_init);
    after_init->apply(defuse);

    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f1")->id), false);
    EXPECT_EQ(defuse.hasUninitializedRead(phv.field("ingress::meta.f2")->id), true);
}

}  // namespace Test
