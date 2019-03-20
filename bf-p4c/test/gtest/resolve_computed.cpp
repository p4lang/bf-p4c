#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "bf-p4c/common/bridged_metadata_replacement.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/resolve_computed.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

namespace Test {

class ResolveComputedTest : public TofinoBackendTest {};

namespace {

class VerifyRegisterAssigned : public ParserInspector {
    bool preorder(const IR::BFN::Select* select) override {
        if (select->reg_slices.size() == 0) {
            has_unallocated = true;
            _logs << "unallocated select: " << select << "\n"; }
        return true; }

 private:
    std::stringstream _logs;

 public:
    bool has_unallocated = false;
    std::string logs() const { return _logs.str(); }
};

boost::optional<TofinoPipeTestCase>
createParserCriticalPathTestCase(const std::string& parserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
    header H1
    {
        bit<8> f1;
        bit<32> f2;
        bit<8> other;
    }

    header BRG
    {
        bit<8>  f1;
        bit<32> f2;
    }

    header MIR
    {
        bit<8> f1;
    }

    struct Headers {
        H1 h1;
        BRG brg;
        MIR mir;
        H1 junk1;
        H1 junk2;
    }

    struct Metadata {
        bit<8> f1;
    }

    parser parse(packet_in packet, out Headers headers, inout Metadata meta,
        inout standard_metadata_t sm) {
%PARSER_SOURCE%
    }

    control verifyChecksum(inout Headers headers, inout Metadata meta) { apply { } }

    control mau(inout Headers headers, inout Metadata meta,
        inout standard_metadata_t sm) { apply { } }

    control computeChecksum(inout Headers headers, inout Metadata meta) { apply { } }

    control deparse(packet_out packet, in Headers headers) {
        apply { }
    }

    V1Switch(parse(), verifyChecksum(), mau(), mau(),
        computeChecksum(), deparse()) main;

    )");

    boost::replace_first(source, "%PARSER_SOURCE%", parserSource);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

}  // namespace

const IR::BFN::Pipe* runMockPasses(const IR::BFN::Pipe* pipe) {
    auto options = new BFN_Options();  // dummy options used in pass.
    SymBitMatrix overlay;
    PhvInfo phv(overlay);
    DependencyGraph dg;
    FindDependencyGraph deps(phv, dg);
    CollectBridgedFields bridged_fields(phv);
    ordered_map<cstring, ordered_set<cstring>> extracted_together;
    MauBacktracker table_alloc(phv.field_mutex());
    PassManager quick_backend = {
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new DoInstructionSelection(*options, phv),
        new FindDependencyGraph(phv, dg),
        &table_alloc,
        new CollectPhvInfo(phv),
        new FlexiblePacking(phv, dg, bridged_fields, extracted_together, table_alloc),
        new CollectPhvInfo(phv)
    };
    return pipe->apply(quick_backend);
}

TEST_F(ResolveComputedTest, TwoPathSameDef) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    state start {
        packet.extract(headers.h1);
        transition select(headers.h1.f1) {
            0x01: parse_bri;
            0x02: parse_mir;
        }
    }

    state parse_bri {
        packet.extract(headers.brg);
        transition select(headers.brg.f1) {
            0: accept;
            1: parse_end;
        }
    }

    state parse_mir {
        packet.extract(headers.mir);
        transition parse_end;
    }

    state parse_end {
        transition select(headers.h1.other) {
            0: parse_after1;
            1: parse_after2;
        }
    }

    state parse_after1 {
        packet.extract(headers.junk1);
        transition accept;
    }

    state parse_after2 {
        packet.extract(headers.junk2);
        transition accept;
    }

    )"));
    ASSERT_TRUE(test);

    auto* run = new ResolveComputedParserExpressions();
    auto* check = new VerifyRegisterAssigned();
    auto* resolved = test->pipe->apply(*run);
    EXPECT_TRUE(resolved);
    if (resolved) {
        resolved->apply(*check);
        EXPECT_EQ(check->has_unallocated, false) << check->logs(); }
}

TEST_F(ResolveComputedTest, TwoDef) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    state start {
        packet.extract(headers.h1);
        transition select(headers.h1.f1) {
            0x01: parse_bri;
            0x02: parse_mir;
        }
    }

    state parse_bri {
        packet.extract(headers.brg);
        meta.f1 = headers.brg.f1;
        transition select(headers.brg.f1) {
            0: accept;
            1: parse_end;
        }
    }

    state parse_mir {
        packet.extract(headers.mir);
        meta.f1 = headers.mir.f1;
        transition parse_end;
    }

    state parse_end {
        transition select(meta.f1) {
            0: parse_after1;
            1: parse_after2;
        }
    }

    state parse_after1 {
        packet.extract(headers.junk1);
        transition accept;
    }

    state parse_after2 {
        packet.extract(headers.junk2);
        transition accept;
    }
    )"));
    ASSERT_TRUE(test);

    auto* prep = runMockPasses(test->pipe);
    auto* run = new ResolveComputedParserExpressions();
    auto* check = new VerifyRegisterAssigned();
    auto* resolved = prep->apply(*run);
    EXPECT_TRUE(resolved);
    if (resolved) {
        resolved->apply(*check);
        EXPECT_EQ(check->has_unallocated, false) << check->logs(); }
}

TEST_F(ResolveComputedTest, TwoPathSameDefLargeField) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    state start {
        packet.extract(headers.h1);
        transition select(headers.h1.f1) {
            0x01: parse_bri;
            0x02: parse_mir;
        }
    }

    state parse_bri {
        packet.extract(headers.brg);
        transition parse_end;
    }

    state parse_mir {
        packet.extract(headers.mir);
        transition parse_end;
    }

    state parse_end {
        transition select(headers.h1.f2) {
            0: parse_after1;
            1: parse_after2;
        }
    }

    state parse_after1 {
        packet.extract(headers.junk1);
        transition accept;
    }

    state parse_after2 {
        packet.extract(headers.junk2);
        transition accept;
    }

    )"));
    ASSERT_TRUE(test);

    auto* run = new ResolveComputedParserExpressions();
    auto* check = new VerifyRegisterAssigned();
    auto* resolved = test->pipe->apply(*run);
    EXPECT_TRUE(resolved);
    if (resolved) {
        resolved->apply(*check);
        EXPECT_EQ(check->has_unallocated, false) << check->logs(); }
}

TEST_F(ResolveComputedTest, Parent) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
    state start {
        packet.extract(headers.h1);
        meta.f1 = headers.h1.f1;
        transition select(headers.h1.f1) {
            0x01: parse_bri;
            0x02: parse_end;
        }
    }

    state parse_bri {
        packet.extract(headers.brg);
        meta.f1 = headers.brg.f1;
        transition parse_end;
    }

    state parse_end {
        transition select(meta.f1) {
            0: parse_after1;
            1: parse_after2;
        }
    }

    state parse_after1 {
        packet.extract(headers.junk1);
        transition accept;
    }

    state parse_after2 {
        packet.extract(headers.junk2);
        transition accept;
    }

    )"));
    ASSERT_TRUE(test);

    auto* prep = runMockPasses(test->pipe);
    auto* run = new ResolveComputedParserExpressions();
    auto* check = new VerifyRegisterAssigned();
    auto* resolved = prep->apply(*run);
    EXPECT_TRUE(resolved);
    if (resolved) {
        resolved->apply(*check);
        EXPECT_EQ(check->has_unallocated, false) << check->logs(); }
}

}  // namespace Test
