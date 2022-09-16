#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <boost/optional/optional_io.hpp>

#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/parde/clot/allocate_clot.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/clot/pragma/do_not_use_clot.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

class ClotTest : public JBayBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createClotTest(const std::string& doNotUseClotPragmas,
               const std::string& headerTypes,
               const std::string& headerInstances,
               const std::string& parser,
               const std::string& mau,
               const std::string& deparser) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
%DO_NOT_USE_CLOT_PRAGMAS%

%HEADER_TYPES%

struct Headers {
  %HEADER_INSTANCES%
}

struct Metadata { }

parser parse(packet_in pkt,
             out Headers hdr,
             inout Metadata metadata,
             inout standard_metadata_t sm) {
  %PARSER%
}

control mau(inout Headers hdr, inout Metadata meta, inout standard_metadata_t sm) {
  %MAU%
}

control deparse(packet_out pkt, in Headers hdr) {
  apply {
    %DEPARSER%
  }
}

control verifyChecksum(inout Headers hdr, inout Metadata meta) {
  apply {}
}

control computeChecksum(inout Headers hdr, inout Metadata meta) {
  apply {}
}

V1Switch(parse(), verifyChecksum(), mau(), mau(), computeChecksum(), deparse()) main;)");

    boost::replace_first(source, "%DO_NOT_USE_CLOT_PRAGMAS%", doNotUseClotPragmas);
    boost::replace_first(source, "%HEADER_TYPES%", headerTypes);
    boost::replace_first(source, "%HEADER_INSTANCES%", headerInstances);
    boost::replace_first(source, "%PARSER%", parser);
    boost::replace_first(source, "%MAU%", mau);
    boost::replace_first(source, "%DEPARSER%", deparser);

    auto& options = BackendOptions();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.target = "tofino";
    options.arch = "v1model";
    options.disable_parse_min_depth_limit = true;

    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

}  // namespace

struct SliceSpec {
    std::string fieldName;
    boost::optional<le_bitrange> slice;

    SliceSpec(const char* fieldName) : fieldName(fieldName),  // NOLINT(runtime/explicit)
                                       slice(boost::none) {}
    SliceSpec(const cstring fieldName) : fieldName(fieldName),  // NOLINT(runtime/explicit)
                                         slice(boost::none) {}

    SliceSpec(const char* fieldName, le_bitrange slice) : fieldName(fieldName), slice(slice) {}
    SliceSpec(const cstring fieldName, le_bitrange slice) : fieldName(fieldName), slice(slice) {}

    bool operator<(const SliceSpec other) const {
        if (fieldName != other.fieldName) return fieldName < other.fieldName;
        return slice < other.slice;
    }

    bool operator==(const SliceSpec other) const {
        return fieldName == other.fieldName && slice == other.slice;
    }

    bool operator>(const SliceSpec other) const {
        if (fieldName != other.fieldName) return fieldName > other.fieldName;
        return slice > other.slice;
    }

    bool operator<=(const SliceSpec other) const {
        return !(*this > other);
    }

    bool operator!=(const SliceSpec other) const {
        return !(*this == other);
    }

    bool operator>=(const SliceSpec other) const {
        return !(*this < other);
    }
};

using ExpectedClot = std::vector<SliceSpec>;
using ExpectedAllocation = std::set<ExpectedClot>;

void runTest(boost::optional<TofinoPipeTestCase> test,
             ExpectedAllocation expectedAlloc) {
    PhvInfo phvInfo;
    PhvUse phvUse(phvInfo);
    ClotInfo clotInfo(phvUse);

    CollectHeaderStackInfo collectHeaderStackInfo;
    CollectPhvInfo collectPhvInfo(phvInfo);
    PragmaDoNotUseClot pragmaDoNotUseClot(phvInfo);
    CollectClotInfo collectClotInfo(phvInfo, clotInfo, pragmaDoNotUseClot);
    InstructionSelection instructionSelection(BackendOptions(), phvInfo);
    AllocateClot allocateClot(clotInfo, phvInfo, phvUse, pragmaDoNotUseClot, false);

    PassManager passes = {
      &collectHeaderStackInfo,
      &collectPhvInfo,
      &instructionSelection,
      &pragmaDoNotUseClot,
      &collectClotInfo,
      &allocateClot,
    };

    ASSERT_TRUE(test);
    test->pipe->apply(passes);

    // Specialize each expected CLOT for each gress and populate any missing slice ranges.
    ExpectedAllocation expectedClots;
    for (auto& clot : expectedAlloc) {
        EXPECT_NE(clot.size(), 0UL);
        for (auto gress : {INGRESS, EGRESS}) {
            ExpectedClot specializedClot;
            for (auto& slice : clot) {
                auto fieldName = toString(gress) + "::hdr." + slice.fieldName;
                auto bitrange = slice.slice ? *slice.slice
                                            : StartLen(0, phvInfo.field(fieldName)->size);
                specializedClot.emplace_back(fieldName, bitrange);
            }

            expectedClots.insert(specializedClot);
        }
    }

    // Convert the actual allocation into an ExpectedAllocation.
    ExpectedAllocation actualClots;
    for (const auto* clot : clotInfo.clots()) {
        // Convert the actual CLOT into an ExpectedClot.
        ExpectedClot expectedClot;
        for (const auto& slices : clot->all_slices()) {
            for (const auto& slice : slices) {
                expectedClot.emplace_back(slice->field()->name, slice->range());
            }
        }

        EXPECT_NE(expectedClot.size(), 0UL);
        actualClots.insert(expectedClot);
    }

    if (expectedClots != actualClots) {
        std::cerr << clotInfo.print(&phvInfo);
    }

    EXPECT_EQ(expectedClots, actualClots);
}

TEST_F(ClotTest, Basic1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H {
                bit<64> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H h;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() { hdr.h.f2 = 0; }

            table t1 {
                key = { hdr.h.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h);
        )"));

    // -----
    // h.f1  CLOT
    // h.f2  written
    // -----
    runTest(test, {{"h.f1"}});
}

TEST_F(ClotTest, AdjacentHeaders1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H {
                bit<64> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H h1;
            H h2;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                pkt.extract(hdr.h2);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() { hdr.h2.f2 = 0; }

            table t1 {
                key = { hdr.h2.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2);
        )"));

    // -----
    // h1.f1  CLOT
    // h1.f2  CLOT
    // h2.f1  CLOT
    // -----
    // h2.f2  written
    // -----
    runTest(test, {
        {"h1.f1", "h1.f2", "h2.f1"}
    });
}

TEST_F(ClotTest, HeaderRemoval1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2;
            H3 h3;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                pkt.extract(hdr.h2);
                pkt.extract(hdr.h3);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h2.setInvalid();
                hdr.h3.f2 = 0;
            }

            table t1 {
                key = { hdr.h3.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2);
            pkt.emit(hdr.h3);
        )"));

    // -----------
    // h1.f         CLOT
    // -----------
    // h2.f[63:24]  CLOT
    // h2.f[23:0]   3-byte gap, required by h2's possible removal
    // -----------
    // h3.f1        CLOT
    // h3.f2        written
    // -----------
    runTest(test, {
        {"h1.f"},
        {{"h2.f", FromTo(24, 63)}},
        {"h3.f1"},
    });
}

TEST_F(ClotTest, HeaderRemoval2) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2;
            H3 h3;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                pkt.extract(hdr.h2);
                pkt.extract(hdr.h3);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h2.setInvalid();
                hdr.h3.setInvalid();
            }

            table t1 {
                key = { hdr.h3.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2);
            pkt.emit(hdr.h3);
        )"));

    // -----
    // h1.f   CLOT
    // -----  no gap necessary: h1 always valid
    // h2.f   CLOT
    // -----  no gap necessary: h2 always valid when h3 is valid
    // h3.f1  CLOT
    // h3.f2  CLOT
    // -----
    runTest(test, {
        {"h1.f"},
        {"h2.f"},
        {"h3.f1", "h3.f2"},
    });
}

TEST_F(ClotTest, MutualExclusion1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f1;
                bit<8> f2;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2a;
            H2 h2b;
            H3 h3;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                transition select(hdr.h1.f2) {
                    0: parse2a;
                    1: parse2b;
                }
            }

            state parse2a {
                pkt.extract(hdr.h2a);
                transition parse3;
            }

            state parse2b {
                pkt.extract(hdr.h2b);
                transition parse3;
            }

            state parse3 {
                pkt.extract(hdr.h3);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h3.f2 = 0;
            }

            table t1 {
                key = { hdr.h3.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2b);
            pkt.emit(hdr.h2a);
            pkt.emit(hdr.h3);
        )"));

    // No gaps needed: headers are neither removed, nor rearranged, nor added.
    //           -----
    //           h1.f1  CLOT
    //           h1.f2  CLOT
    //           -----
    // CLOT  h2a.f | h2b.f  CLOT
    //           -----
    //           h3.f1  CLOT
    //           h3.f2  written
    //           -----
    runTest(test, {
        {"h1.f1", "h1.f2"},
        {"h2a.f"},
        {"h2b.f"},
        {"h3.f1"},
    });
}

TEST_F(ClotTest, Insertion1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f1;
                bit<8> f2;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2a;
            H2 h2b;
            H3 h3;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                transition select(hdr.h1.f2) {
                    0: parse2a;
                    1: parse2b;
                }
            }

            state parse2a {
                pkt.extract(hdr.h2a);
                transition parse3;
            }

            state parse2b {
                pkt.extract(hdr.h2b);
                transition parse3;
            }

            state parse3 {
                pkt.extract(hdr.h3);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h2b.setValid();
                hdr.h3.f2 = 0;
            }

            table t1 {
                key = { hdr.h3.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2b);
            pkt.emit(hdr.h2a);
            pkt.emit(hdr.h3);
        )"));

    //           -----
    //           h1.f1[31:16]  CLOT
    //           h1.f1[15:0]   gap, needed because h2b can be inserted between h1 and h2a
    //           h1.f2         gap
    //           -----
    // CLOT  h2a.f | h2b.f     might be added
    //           -----
    //           h3.f1         CLOT
    //           h3.f2         written
    //           -----
    runTest(test, {
        {{"h1.f1", FromTo(16, 31)}},
        {"h2a.f"},
        {"h3.f1"},
    });
}

TEST_F(ClotTest, Insertion2) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f1;
                bit<8> f2;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2a;
            H2 h2b;
            H3 h3;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                transition select(hdr.h1.f2) {
                    0: parse2a;
                    1: parse2b;
                }
            }

            state parse2a {
                pkt.extract(hdr.h2a);
                transition parse3;
            }

            state parse2b {
                pkt.extract(hdr.h2b);
                transition parse3;
            }

            state parse3 {
                pkt.extract(hdr.h3);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h2a.setValid();
                hdr.h3.f2 = 0;
            }

            table t1 {
                key = { hdr.h3.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2b);
            pkt.emit(hdr.h2a);
            pkt.emit(hdr.h3);
        )"));

    // -----
    // h1.f1         CLOT
    // h1.f2         CLOT
    // -----
    // h2b.f[63:24]  CLOT
    // h2b.f[23:0]   3-byte gap, needed because h2a can be inserted between h2b and h3
    // -----
    // h2a.f         might be added
    // -----
    // h3.f1         CLOT
    // h3.f2         written
    // -----
    runTest(test, {
        {"h1.f1", "h1.f2"},
        {{"h2b.f", FromTo(24, 63)}},
        {"h3.f1"},
    });
}

TEST_F(ClotTest, Reorder1) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<96> f;
            }

            header H4 {
                bit<104> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2;
            H3 h3;
            H4 h4;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                pkt.extract(hdr.h2);
                pkt.extract(hdr.h3);
                pkt.extract(hdr.h4);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h4.f2 = 0;
            }

            table t1 {
                key = { hdr.h4.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h3);
            pkt.emit(hdr.h2);
            pkt.emit(hdr.h4);
        )"));

    // -----
    // h1.f[31:24]  CLOT
    // h1.f[23:0]   3-byte gap, needed because h3 is inserted between h1 and h2
    // -----
    // h2.f[63:24]  CLOT
    // h2.f[23:0]   3-byte gap, needed because h2 and h3 are reordered
    // -----
    // h3.f[95:24]  CLOT
    // h3.f[23:0]   3-byte gap, needed because h2 is inserted between h3 and h4
    // -----
    // h4.f1        CLOT
    // h4.f2        written
    // -----
    runTest(test, {
        {{"h1.f", FromTo(24, 31)}},
        {{"h2.f", FromTo(24, 63)}},
        {{"h3.f", FromTo(24, 95)}},
        {"h4.f1"},
    });
}

TEST_F(ClotTest, Reorder2) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<32> f;
            }

            header H2 {
                bit<40> f;
            }

            header H3 {
                bit<64> f;
            }

            header H4 {
                bit<96> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2;
            H3 h3;
            H4 h4;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                pkt.extract(hdr.h2);
                pkt.extract(hdr.h3);
                pkt.extract(hdr.h4);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h4.f2 = 0;
            }

            table t1 {
                key = { hdr.h4.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h3);
            pkt.emit(hdr.h2);
            pkt.emit(hdr.h4);
        )"));

    // -----
    // h1.f         CLOT
    // -----
    // h2.f         gap: slice [39:16] needed because h3 is inserted between h1 and h2
    //                   slice [23:0] needed because h2 and h3 are reordered
    // -----
    // h3.f[63:24]  CLOT
    // h3.f[23:0]   3-byte gap, needed because h2 is inserted between h3 and h4
    // -----
    // h4.f1        CLOT
    // h4.f2        written
    // -----
    runTest(test, {
        {"h1.f"},
        {{"h3.f", FromTo(24, 63)}},
        {"h4.f1"},
    });
}

TEST_F(ClotTest, AdjacentHeaders2) {
    auto test = createClotTest(P4_SOURCE(R"(
        )"), P4_SOURCE(R"(
            header H1 {
                bit<96> f1;
                bit<8> f2;
            }

            header H2 {
                bit<64> f;
            }

            header H3 {
                bit<16> f;
            }

            header H4 {
                bit<32> f1;
                bit<8> f2;
            }
        )"), P4_SOURCE(R"(
            H1 h1;
            H2 h2;
            H3 h3;
            H4 h4;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h1);
                transition select(hdr.h1.f2) {
                    0: parseH2;
                    1: parseH4;
                }
            }

            state parseH2 {
                pkt.extract(hdr.h2);
                pkt.extract(hdr.h3);
                transition parseH4;
            }

            state parseH4 {
                pkt.extract(hdr.h4);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() {
                hdr.h4.f2 = 0;
            }

            table t1 {
                key = { hdr.h4.f2 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h1);
            pkt.emit(hdr.h2);
            pkt.emit(hdr.h3);
            pkt.emit(hdr.h4);
        )"));

    // Before the introduction of multiheader CLOTs, CLOT allocation would have returned the
    // following result:
    //
    // -----
    // h1.f1        CLOT 0
    // h1.f2        CLOT 0
    // -----
    //   | h2.f     CLOT 1
    //   | ----
    //   | h3.f     CLOT 2
    // -----
    // h4.f1[31:8]  3-byte gap. Slice [31:24] needed because h2 and h4 need to be separated by at
    //                          least 3 bytes, and h3 is only 2 bytes long. This induces slice
    //                          [31:8] to satisfy gap requirement between h3 and h4, and h1 and h4.
    // h4.f1[7:0]   CLOT 3
    // h4.f2        written
    // -----
    //
    // However, since h2 and h3 are immediately adjacent in the parser and deparser, they are now
    // grouped in a multiheader CLOT, making the gap unnecessary. This leads to the following
    // CLOT allocation:
    //
    // -----
    // h1.f1        CLOT 0
    // h1.f2        CLOT 0
    // -----
    // h2.f         CLOT 1
    // h3.f         CLOT 1
    // -----
    // h4.f1        CLOT 2
    // h4.f2        written
    runTest(test, {
        {"h1.f1", "h1.f2"},
        {"h2.f", "h3.f"},
        {"h4.f1"}
    });
}

TEST_F(ClotTest, FieldPragma) {
    auto test = createClotTest(P4_SOURCE(R"(
            @do_not_use_clot("ingress", "hdr.h.f1")
            @do_not_use_clot("egress", "hdr.h.f1")
        )"), P4_SOURCE(R"(
            header H {
                bit<64> f1;
                bit<64> f2;
                bit<8> f3;
            }
        )"), P4_SOURCE(R"(
            H h;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() { hdr.h.f3 = 0; }

            table t1 {
                key = { hdr.h.f3 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h);
        )"));

    // -----
    // h.f1  @pragma do_not_use_clot
    // h.f2  CLOT
    // h.f3  written
    // -----
    runTest(test, {{"h.f2"}});
}

TEST_F(ClotTest, HeaderPragma) {
    auto test = createClotTest(P4_SOURCE(R"(
            @do_not_use_clot("ingress", "hdr.h")
            @do_not_use_clot("egress", "hdr.h")
        )"), P4_SOURCE(R"(
            header H {
                bit<64> f1;
                bit<64> f2;
                bit<8> f3;
            }
        )"), P4_SOURCE(R"(
            H h;
        )"), P4_SOURCE(R"(
            state start {
                pkt.extract(hdr.h);
                transition accept;
            }
        )"), P4_SOURCE(R"(
            action act1() { hdr.h.f3 = 0; }

            table t1 {
                key = { hdr.h.f3 : exact; }
                actions = { act1; }
                size = 256;
            }

            apply {
                t1.apply();
            }
        )"), P4_SOURCE(R"(
            pkt.emit(hdr.h);
        )"));

    // -----
    // h.f1  @pragma do_not_use_clot
    // h.f2  @pragma do_not_use_clot
    // h.f3  written, @pragma do_not_use_clot
    // -----
    runTest(test, {});
}

}  // namespace Test
