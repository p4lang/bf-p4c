#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>

#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

#if HAVE_JBAY
#include "bf-p4c/phv/analysis/mocha.h"
#endif

namespace Test {

class MochaAnalysisTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createMochaAnalysisTest(const std::string& parserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
header H1
{
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
}

struct Headers { H1 h1; }

struct Metadata {
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
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

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

const IR::BFN::Pipe *runMockPasses(const IR::BFN::Pipe* pipe,
                                   PhvInfo& phv,
                                   FieldDefUse& defuse,
                                   PhvUse& uses) {
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new DoInstructionSelection(phv),
        &defuse,
        &uses
    };
    return pipe->apply(quick_backend);
}

}  // namespace

TEST_F(MochaAnalysisTest, AnalyzeMochaCandidates) {
    auto test = createMochaAnalysisTest(
        P4_SOURCE(P4Headers::NONE, R"(
action do1() {
    meta.f1 = headers.h1.f1;
    meta.f2 = headers.h1.f2;
    meta.f3 = headers.h1.f3;
}

action do2() {
    meta.f2 = 2;
}

action do3() {
    headers.h1.f1 = meta.f2;
    headers.h1.f2 = meta.f1;
    headers.h1.f3 = meta.f3;
}

table t1 {
    key = { headers.h1.f1 : exact; }
    actions = { do1; do2; }
}

table t2 {
    key = { meta.f1 : exact;}
    actions = { do3; }
}

apply {
    t1.apply();
    t2.apply();
}
)"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    FieldDefUse defuse(phv);
    PhvUse uses(phv);

    auto* pipe = runMockPasses(test->pipe, phv, defuse, uses);
    ASSERT_TRUE(pipe);

#if HAVE_JBAY
    auto* mocha = new CollectMochaCandidates(phv, uses);
    auto* after_analysis = pipe->apply(*mocha);
    ASSERT_TRUE(after_analysis);

    const PHV::Field* h1f1 = phv.field("ingress::h1.f1");
    const PHV::Field* h1f2 = phv.field("ingress::h1.f2");
    const PHV::Field* h1f3 = phv.field("ingress::h1.f3");
    const PHV::Field* m1f1 = phv.field("ingress::meta.f1");
    const PHV::Field* m1f2 = phv.field("ingress::meta.f2");
    const PHV::Field* m1f3 = phv.field("ingress::meta.f3");

    ASSERT_TRUE(h1f1 && h1f2 && h1f3 && m1f1 && m1f2 && m1f3);

    // Check mocha candidates.
    EXPECT_EQ(h1f1->is_mocha_candidate(), true);
    EXPECT_EQ(h1f2->is_mocha_candidate(), true);
    EXPECT_EQ(h1f3->is_mocha_candidate(), true);
    EXPECT_EQ(m1f1->is_mocha_candidate(), true);
    EXPECT_EQ(m1f2->is_mocha_candidate(), false);
    EXPECT_EQ(m1f3->is_mocha_candidate(), true);

    // Check dark candidates.
    EXPECT_EQ(h1f1->is_dark_candidate(), false);
    EXPECT_EQ(h1f2->is_dark_candidate(), false);
    EXPECT_EQ(h1f3->is_dark_candidate(), false);
    EXPECT_EQ(m1f1->is_dark_candidate(), false);
    EXPECT_EQ(m1f2->is_dark_candidate(), false);
    EXPECT_EQ(m1f3->is_dark_candidate(), true);

#endif
}

}  // namespace Test