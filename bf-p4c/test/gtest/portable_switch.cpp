#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "test/gtest/helpers.h"

namespace Test {

class PortableSwitchTest : public TofinoBackendTest {};

void enable_psa_target() {
    auto& options = BFNContext::get().options();
    options.target = "tofino-psa-barefoot";
}

boost::optional<TofinoPipeTestCase> createPSAIngressTest(const std::string& ingressDecl,
                                                         const std::string& ingressApply) {
    auto source = P4_SOURCE(P4Headers::PSA, R"(
        typedef bit<48>  EthernetAddress;

        header ethernet_t {
            EthernetAddress dstAddr;
            EthernetAddress srcAddr;
            bit<16>         etherType;
        }

        header ipv4_t {
            bit<4>  version;
            bit<4>  ihl;
            bit<8>  diffserv;
            bit<16> totalLen;
            bit<16> identification;
            bit<3>  flags;
            bit<13> fragOffset;
            bit<8>  ttl;
            bit<8>  protocol;
            bit<16> hdrChecksum;
            bit<32> srcAddr;
            bit<32> dstAddr;
        }

        header data_t {
            bit<16> h1;
            bit<16> h2;
            bit<16> h3;
        }

        typedef bit<8> clone_i2e_format_t;

        struct metadata {
            data_t data;
        }

        struct resubmit_metadata_t {
        }

        struct recirculate_metadata_t {
        }

        struct clone_i2e_metadata_t {
        }

        struct clone_e2e_metadata_t {
        }

        struct headers {
            ethernet_t ethernet;
            ipv4_t ipv4;
        }

        error {
            UnknownCloneI2EFormatId
        }

        parser IngressParserImpl(
            packet_in buffer,
            out headers parsed_hdr,
            inout metadata meta,
            in psa_ingress_parser_input_metadata_t istd,
            in resubmit_metadata_t resubmit_meta,
            in recirculate_metadata_t recirculate_meta)
        {
            state start {
                buffer.extract(parsed_hdr.ethernet);
                buffer.extract(parsed_hdr.ipv4);
                transition accept;
            }
        }

        parser EgressParserImpl(
            packet_in buffer,
            out headers parsed_hdr,
            inout metadata meta,
            in psa_egress_parser_input_metadata_t istd,
            in metadata normal_meta,
            in clone_i2e_metadata_t clone_i2e_meta,
            in clone_e2e_metadata_t clone_e2e_meta)
        {
            state start {
                buffer.extract(parsed_hdr.ethernet);
                buffer.extract(parsed_hdr.ipv4);
                transition accept;
            }
        }

        control ingress(inout headers hdr,
                        inout metadata meta,
                        in    psa_ingress_input_metadata_t  istd,
                        inout psa_ingress_output_metadata_t ostd)
        {
%INGRESS_DECL%
            apply {
%INGRESS_APPLY%
            }
        }

        control egress(inout headers hdr,
                       inout metadata meta,
                       in    psa_egress_input_metadata_t  istd,
                       inout psa_egress_output_metadata_t ostd)
        {
            apply { }
        }

        control IngressDeparserImpl(
            packet_out packet,
            out clone_i2e_metadata_t clone_i2e_meta,
            out resubmit_metadata_t resubmit_meta,
            out metadata normal_meta,
            inout headers hdr,
            in metadata meta,
            in psa_ingress_output_metadata_t istd)
        {
            apply { }
        }

        control EgressDeparserImpl(
            packet_out packet,
            out clone_e2e_metadata_t clone_e2e_meta,
            out recirculate_metadata_t recirculate_meta,
            inout headers hdr,
            in metadata meta,
            in psa_egress_output_metadata_t istd,
            in psa_egress_deparser_input_metadata_t edstd)
        {
            apply { }
        }

        IngressPipeline(IngressParserImpl(),
                        ingress(),
                        IngressDeparserImpl()) ip;

        EgressPipeline(EgressParserImpl(),
                       egress(),
                       EgressDeparserImpl()) ep;

        PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
    )");
    boost::replace_first(source, "%INGRESS_DECL%", ingressDecl);
    boost::replace_first(source, "%INGRESS_APPLY%", ingressApply);
    enable_psa_target();
    return TofinoPipeTestCase::create(source);
}


// Counter can be instantiated in a control block;
// its count() method can be invoked in an action.
TEST_F(PortableSwitchTest, CounterInExactMatchTable) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Counter<bit<10>,bit<12>>(1024, CounterType_t.PACKETS) counter;
        action execute() {
          counter.count(1024);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute(); }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// If two counters are instantiated in a control block,
// Both can be invoked in the same action.
TEST_F(PortableSwitchTest, TwoCountersInSameAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Counter<bit<10>,bit<12>>(1024, CounterType_t.PACKETS) counter0;
        Counter<bit<10>,bit<12>>(1024, CounterType_t.PACKETS) counter1;
        action execute() {
          counter0.count(1024);
          counter1.count(1024);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute(); }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// A Counter can be invoked in the apply statement of a control block.
TEST_F(PortableSwitchTest, CounterInApplyBlock) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Counter<bit<10>,bit<12>>(1024, CounterType_t.PACKETS) counter0;
)"),
P4_SOURCE(R"(
        counter0.count(1024);
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// A DirectCounter can be attached to a table without an explicit invocation.
TEST_F(PortableSwitchTest, DirectCounterInTable) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        DirectCounter<bit<12>>(CounterType_t.PACKETS) counter0;

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; }
          psa_direct_counters = { counter0 };
        }
)"),
P4_SOURCE(R"(
         tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// A DirectCounter can be invoked in an action
TEST_F(PortableSwitchTest, DirectCounterInAction) {
    auto test = createPSAIngressTest(
            P4_SOURCE(R"(
        DirectCounter<bit<12>>(CounterType_t.PACKETS) counter0;
        DirectCounter<bit<12>>(CounterType_t.PACKETS) counter1;

        action execute() {
          counter0.count();
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute; }
          psa_direct_counters = { counter0, counter1 };
        }
)"),
            P4_SOURCE(R"(
         tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// DirectCounter cannot be shared between tables,
// however, the check is implemented in the backend.
TEST_F(PortableSwitchTest, DirectCounterNoSharing) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        DirectCounter<bit<12>>(CounterType_t.PACKETS) counter0;

        action execute() {
          counter0.count();
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute; }
          psa_direct_counters = { counter0 };
        }

        table tbl2 {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute; }
          psa_direct_counters = { counter0 };
        }
)"),
P4_SOURCE(R"(
         tbl.apply();
         tbl2.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

// Meter can be invoked in an action, however, it is not possible
// to pass MeterColor_t as a control plane parameter through
// action arguments.
TEST_F(PortableSwitchTest, MeterInAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Meter<bit<12>>(1024, MeterType_t.PACKETS) meter0;

        action execute(bit<12> index, MeterColor_t color) {
          meter0.execute(index, color);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute; }
        }
)"),
P4_SOURCE(R"(
         tbl.apply();
)"));

    EXPECT_FALSE(test);
    //XXX(hanw): I am expecting this errorCount to be 1.
    EXPECT_EQ(::errorCount(), 0u);
}



}  // namespace Test
