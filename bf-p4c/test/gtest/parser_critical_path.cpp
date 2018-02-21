#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/symbitmatrix.h"
#include "test/gtest/helpers.h"
#include "bf-p4c/common/parser_critical_path.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"

// Changes related to inserting parser states might break
// these tests.

namespace Test {

class ParserCriticalPathTest : public TofinoBackendTest {};

namespace {

boost::optional<TofinoPipeTestCase>
createParserCriticalPathTestCase(const std::string& parserSource) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H1
        {
            bit<8> f1;
            bit<32> f2;
        }
        header H2
        {
            bit<64> f1;
        }
        struct Headers { H1 h1; H2 h2; }
        struct Metadata {
            bit<8> f1;
            H2 f2;
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
    return TofinoPipeTestCase::createWithThreadLocalInstances(source);
}

// In this unit-test, we do not check those inserted states before start (states has $ in name)
// Checking them make this unit-test flaky in that anyone who changes the inserted
// states would have to change this unit-test accrodingly.
std::vector<std::pair<cstring, int>>
transformToComparable(const std::vector<std::pair<const IR::BFN::ParserState*, int>>& path) {
    std::vector<std::pair<cstring, int>> dest(path.size());
    transform(path.begin(), path.end(), dest.begin(),
              [] (const std::pair<const IR::BFN::ParserState*, int>& x) {
                  return std::make_pair(x.first->name, x.second);} );
    dest.erase(std::remove_if(dest.begin(), dest.end(),
                              [] (std::pair<cstring, int> v) {
                                  return v.first.find('$') != nullptr; }),
               dest.end());
    return dest;
}

}  // namespace

TEST_F(ParserCriticalPathTest, SinglePath) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
state start {
    packet.extract(headers.h1);
    transition accept;
}
)"));
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    CalcParserCriticalPath *run = new CalcParserCriticalPath(phv);
    test->pipe->apply(*run);

    std::vector<std::pair<cstring, int>> expectedIngressPath({
            {"ingress::start", 41}
        });
    std::vector<std::pair<cstring, int>> expectedEgressPath({
            {"egress::start", 41}
        });

    EXPECT_EQ(transformToComparable(run->get_ingress_result().path), expectedIngressPath);
    EXPECT_EQ(transformToComparable(run->get_egress_result().path), expectedEgressPath);
}

TEST_F(ParserCriticalPathTest, TwoPath) {
    auto test = createParserCriticalPathTestCase(
        P4_SOURCE(P4Headers::NONE, R"(
state start {
    packet.extract(headers.h1);
    transition select(headers.h1.f1) {
        5 : parseH2;
        6 : parseH2AndMeta;
        default: accept;
    }
}

state parseH2 {
    packet.extract(headers.h2);
    transition accept;
}

state parseH2AndMeta {
    packet.extract(headers.h2);
    meta.f1 = headers.h1.f1;
    transition accept;
}
)"));
    ASSERT_TRUE(test);
    // ingress and egress should be the same here
    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    CalcParserCriticalPath *run = new CalcParserCriticalPath(phv);
    test->pipe->apply(*run);

    std::vector<std::pair<cstring, int>> expectedIngressPath({
            {"ingress::start", 41},
            {"ingress::parseH2AndMeta", 65 + 8}
        });
    std::vector<std::pair<cstring, int>> expectedEgressPath({
            {"egress::start", 41},
            {"egress::parseH2", 65}  // Egress does not extract metadata
        });

    EXPECT_EQ(transformToComparable(run->get_ingress_result().path), expectedIngressPath);
    EXPECT_EQ(transformToComparable(run->get_egress_result().path), expectedEgressPath);
}

TEST_F(ParserCriticalPathTest, Loop) {
    auto source = P4_SOURCE(P4Headers::V1MODEL, R"(
        header H1
        {
            bit<8> f1;
            bit<32> f2;
        }
        header H2
        {
            bit<64> f1;
        }

        struct Headers {
           H1 eth;
           H2[3] mpls;
        }

        struct Metadata {
            bit<8> f1;
            H2 f2;
        }

        parser parse(packet_in packet, out Headers headers, inout Metadata meta,
                     inout standard_metadata_t sm) {
            state start {
                packet.extract(headers.eth);
                transition select(headers.eth.f1) {
                   0x01: accept;
                   0x02: parse_mpls;
                }
            }
            state parse_mpls {
                 packet.extract(headers.mpls.next);
                 transition select(headers.mpls.last.f1) {
                    0: parse_mpls; // This creates a loop
                    1: accept;
                 }
            }
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

    auto test = TofinoPipeTestCase::createWithThreadLocalInstances(source);
    ASSERT_TRUE(test);

    SymBitMatrix mutex;
    PhvInfo phv(mutex);
    CalcParserCriticalPath *run = new CalcParserCriticalPath(phv);
    test->pipe->apply(*run);

    std::vector<std::pair<cstring, int>> expectedIngressPath({
            {"ingress::start", 41},
            {"ingress::parse_mpls", 65},
            {"ingress::parse_mpls.0", 65},
            {"ingress::parse_mpls.1", 65}
        });
    std::vector<std::pair<cstring, int>> expectedEgressPath({
            {"egress::start", 41},
            {"egress::parse_mpls", 65},
            {"egress::parse_mpls.0", 65},
            {"egress::parse_mpls.1", 65}
        });

    EXPECT_EQ(transformToComparable(run->get_ingress_result().path), expectedIngressPath);
    EXPECT_EQ(transformToComparable(run->get_egress_result().path), expectedEgressPath);
}

}  // namespace Test
