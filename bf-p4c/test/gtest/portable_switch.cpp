#include <boost/algorithm/string/replace.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include "gtest/gtest.h"

#include "ir/ir.h"
#include "bf-p4c/test/gtest/tofino_gtest_utils.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "test/gtest/helpers.h"

namespace Test {

class PortableSwitchTest : public TofinoBackendTest {};

boost::optional<TofinoPipeTestCase> createPSAIngressTest(const std::string& ingressDecl,
                                                         const std::string& ingressApply,
                                                         const std::string& ingressMeta = "") {
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
%INGRESS_METADATA%
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
    boost::replace_first(source, "%INGRESS_METADATA%", ingressMeta);
    boost::replace_first(source, "%INGRESS_DECL%", ingressDecl);
    boost::replace_first(source, "%INGRESS_APPLY%", ingressApply);

    auto& options = BFNContext::get().options();
    options.target = "tofino-psa-barefoot";

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

// MeterColor_t is not converted to bit<n>
TEST_F(PortableSwitchTest, DISABLED_MeterColorIsEnum) {
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
}

// Expressions whose type is an enum cannot be cast to or from any other type.
// Error message is:
//   cast: Illegal cast from MeterColor_t to bit<16>
TEST_F(PortableSwitchTest, MeterUnableToCastToBit) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Meter<bit<12>>(1024, MeterType_t.PACKETS) meter0;

        action execute(bit<12> index) {
          meta.data.h1 = (bit<16>)meter0.execute(index, MeterColor_t.GREEN);
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
}

// Executing meter in the control flow is not supported (should be).
// Error message is:
//    Method Call meter0_0/meter0.execute(0); not apply
TEST_F(PortableSwitchTest, DISABLED_MeterColorCompareToEnum) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Meter<bit<12>>(1024, MeterType_t.PACKETS) meter0;

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; }
        }
)"),
P4_SOURCE(R"(
        if (meter0.execute(0) == MeterColor_t.GREEN) {
           tbl.apply();
        }
)"));

    EXPECT_FALSE(test);
}

/// Direct meter can be invoked by table without explicit call
/// to execute in action.
TEST_F(PortableSwitchTest, DirectMeterNoInvoke) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        DirectMeter(MeterType_t.PACKETS) meter0;

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; }
          psa_direct_meters = { meter0 };
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

/// Direct meter can be invoked in an action
TEST_F(PortableSwitchTest, DirectMeterInvokedInAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        DirectMeter(MeterType_t.PACKETS) meter0;

        action execute_meter () {
          meter0.execute();
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; }
          psa_direct_meters = { meter0 };
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_EQ(::diagnosticCount(), 0u);
}

/// Direct meter cannot be invoked in the table that does not
/// own it. This test case should fail in the backend.
TEST_F(PortableSwitchTest, DISABLED_DirectMeterInvokedInWrongTable) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        DirectMeter(MeterType_t.PACKETS) meter0;

        action execute_meter () {
          meter0.execute();
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; }
          psa_direct_meters = { meter0 };
        }

        table tbl2 {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute_meter; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
        tbl2.apply();
)"));

    EXPECT_FALSE(test);
}

/// Registers are stateful memory that can be accessed in an action
/// Error message is:
///   Could not find declaration for Register
/// The backend should convert Register extern into StatefulAlu extern
/// that is supported by Tofino.
TEST_F(PortableSwitchTest, RegisterReadInAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Register<bit<10>, bit<10>>(1024) reg;

        action execute_register(bit<10> idx) {
          bit<10> data = reg.read(idx);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute_register; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// Register can be written in an action
TEST_F(PortableSwitchTest, RegisterWriteInAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Register<bit<16>, bit<10>>(1024) reg;

        action execute_register(bit<10> idx) {
          reg.write(idx, meta.data.h1);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute_register; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// Register access may be out-of-bound.
/// PSA specifies an out of bounds write has no effect on the state of the system.
TEST_F(PortableSwitchTest, RegisterOutOfBound) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Register<bit<16>, bit<10>>(512) reg;

        action execute_register(bit<10> idx) {
          reg.write(idx, meta.data.h1);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute_register; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

// An 'Random' extern generates a random number in an action
TEST_F(PortableSwitchTest, RandomInAction) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Random<bit<16>>(200, 400) rand;

        action execute_random() {
          meta.data.h1 = rand.read();
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; execute_random; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// Action profile is used as an implementation to table.
TEST_F(PortableSwitchTest, ActionProfileInTable) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionProfile(1024) ap;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = ap;
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// Multiple action profile in the same table is not supported
TEST_F(PortableSwitchTest, ActionProfileMultiple) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionProfile(1024) ap;
        ActionProfile(1024) ap1;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = { ap, ap1 };
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// Action profile can be shared between tables if all tables
/// implements the same set of actions
TEST_F(PortableSwitchTest, ActionProfileInMultipleTablesWithSameSet) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionProfile(1024) ap;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = ap;
        }

        table tbl2 {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = ap;
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
        tbl2.apply();
)"));

    EXPECT_FALSE(test);
}

/// Action profile cannot be shared between tables if the
/// tables implements a different set of actions
TEST_F(PortableSwitchTest, ActionProfileInMultipleTablesWithDiffSet) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionProfile(1024) ap;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a2; }
          psa_implementation = ap;
        }

        table tbl2 {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; }
          psa_implementation = ap;
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
        tbl2.apply();
)"));

    EXPECT_FALSE(test);
}

/// action selector uses key:selector as selection bits
TEST_F(PortableSwitchTest, ActionSelectorInTableWithSingleKey) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionSelector(HashAlgorithm_t.CRC32, 32w1024, 32w16) as;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
            meta.data.h1 : selector;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = as;
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// multiple selector key can be used in action selector
TEST_F(PortableSwitchTest, ActionSelectorInTableWithMultipleKeys) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        ActionSelector(HashAlgorithm_t.CRC32, 32w1024, 32w16) as;

        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
            meta.data.h1 : selector;
            meta.data.h2 : selector;
          }
          actions = { NoAction; a1; a2; }
          psa_implementation = as;
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    EXPECT_FALSE(test);
}

/// it is illegal to define 'selector' type match field if the
/// table does not have an action selector implementation.
TEST_F(PortableSwitchTest, ActionSelectorIllegalSelectorKey) {
    auto test = createPSAIngressTest(
P4_SOURCE(R"(
        action a1() { }
        action a2() { }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
            meta.data.h1 : selector;
            meta.data.h2 : selector;
          }
          actions = { NoAction; a1; a2; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    // FIXME This test case should fail.
    EXPECT_TRUE(test);
}

// ParserValueSet

// Hash
TEST_F(PortableSwitchTest, HashInAction) {
     auto test = createPSAIngressTest(
P4_SOURCE(R"(
        Hash<bit<16>>(HashAlgorithm_t.CRC16) h;

        action a1() {
          meta.data.h1 = h.get_hash(hdr.ethernet);
        }

        table tbl {
          key = {
            hdr.ethernet.srcAddr : exact;
          }
          actions = { NoAction; a1; }
        }
)"),
P4_SOURCE(R"(
        tbl.apply();
)"));

    // FIXME This test case should pass.
    EXPECT_FALSE(test);
}

boost::optional<TofinoPipeTestCase> createPSAParserTest(const std::string& resubmit_data,
                                                        const std::string& parser_state,
                                                        const std::string& deparser_apply) {
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

        struct fwd_metadata_t {
            bit<9> output_port;
        }

        struct resubmit_metadata_t {
%RESUBMIT_DATA%
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

        struct metadata {
            resubmit_metadata_t resubmit_meta;
            fwd_metadata_t fwd_meta;
        }

        error {
            UnknownCloneI2EFormatId
        }

        parser IngressParserImpl(
            packet_in buffer,
            out headers parsed_hdr,
            inout metadata user_meta,
            in psa_ingress_parser_input_metadata_t istd,
            in resubmit_metadata_t resub_meta,
            in recirculate_metadata_t recirc_meta)
        {
%PARSER_STATE%
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
            apply { }
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
            out resubmit_metadata_t resub_meta,
            out metadata normal_meta,
            inout headers hdr,
            in metadata meta,
            in psa_ingress_output_metadata_t istd)
        {
            apply {
%DEPARSER_APPLY%
            }
        }

        control EgressDeparserImpl(
            packet_out packet,
            out clone_e2e_metadata_t clone_e2e_meta,
            out recirculate_metadata_t recirc_meta,
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
    boost::replace_first(source, "%RESUBMIT_DATA%", resubmit_data);
    boost::replace_first(source, "%PARSER_STATE%", parser_state);
    boost::replace_first(source, "%DEPARSER_APPLY%", deparser_apply);

    auto& options = BFNContext::get().options();
    options.target = "tofino-psa-barefoot";

    return TofinoPipeTestCase::create(source);
}

// base implementation of resubmit in psa, direct struct assignment
TEST_F(PortableSwitchTest, ResubmitHeaderAssignment) {
    auto test = createPSAParserTest(
P4_SOURCE(R"()"),
P4_SOURCE(R"(
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta {
          user_meta.resubmit_meta = resub_meta;
          transition packet_in_parsing;
        }

        state packet_in_parsing {
          transition accept;
        }
)"),
P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// user may manually assign fields in resubmit metadata to fields in user metadata.
TEST_F(PortableSwitchTest, ResubmitFieldAssignment) {
    auto test = createPSAParserTest(
P4_SOURCE(R"(
        bit<8> d1;
        bit<8> d2;
)"),
P4_SOURCE(R"(
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta {
          user_meta.resubmit_meta.d1 = resub_meta.d1;
          user_meta.resubmit_meta.d2 = resub_meta.d2;
          transition packet_in_parsing;
        }

        state packet_in_parsing {
          transition accept;
        }
)"),
    P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// user may NOT reorder fields in resubmit metadata to fields in user metadata.
TEST_F(PortableSwitchTest, ResubmitReorderdFieldAssignment) {
    auto test = createPSAParserTest(
P4_SOURCE(R"(
        bit<8> d1;
        bit<8> d2;
)"),
P4_SOURCE(R"(
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta {
          user_meta.resubmit_meta.d1 = resub_meta.d2;
          user_meta.resubmit_meta.d2 = resub_meta.d1;
          transition packet_in_parsing;
        }

        state packet_in_parsing {
          transition accept;
        }
)"),
    P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// select on istd.packet_path does not have to be in the first state, but
// must be the first thing to check in the parse graph.
TEST_F(PortableSwitchTest, ResubmitEmptyFirstState) {
    auto test = createPSAParserTest(
            P4_SOURCE(R"()"),
            P4_SOURCE(R"(
        state start {
          transition __start;
        }

        state __start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta {
          user_meta.resubmit_meta = resub_meta;
          transition packet_in_parsing;
        }

        state packet_in_parsing {
          transition accept;
        }
)"),
    P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// however, if an extraction happens before checking the packet_path
// metadata, that is an program error.
TEST_F(PortableSwitchTest, ResubmitExtractBeforeCheckPacketPath) {
    auto test = createPSAParserTest(
            P4_SOURCE(R"()"),
            P4_SOURCE(R"(
        state start {
          buffer.extract(parsed_hdr.ethernet);
          transition __start;
        }
        state __start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta {
          user_meta.resubmit_meta = resub_meta;
          transition packet_in_parsing;
        }
        state packet_in_parsing {
          transition accept;
        }
)"),
    P4_SOURCE(R"()"));

    EXPECT_FALSE(test);
}

// user can extract resubmit_metadata in multiple parser states.
TEST_F(PortableSwitchTest, ResubmitMultipleExtractState) {
     auto test = createPSAParserTest(
P4_SOURCE(R"(
        bit<8> d1;
        bit<8> d2;
)"),
P4_SOURCE(R"(
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta_0;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta_0 {
          user_meta.resubmit_meta.d1 = resub_meta.d1;
          transition copy_resubmit_data_1;
        }
        state copy_resubmit_data_1 {
          user_meta.resubmit_meta.d2 = resub_meta.d2;
          transition packet_in_parsing;
        }

        state packet_in_parsing {
          transition accept;
        }
)"),
     P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// user may copy part of the resubmit metadata, select on the copied
// value and branch to next parse state to continue copying resubmit
// metadata
TEST_F(PortableSwitchTest, ResubmitCopyAndSelectOnField) {
     auto test = createPSAParserTest(
P4_SOURCE(R"(
        bit<8> d1;
        bit<8> d2;
)"),
P4_SOURCE(R"(
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta_0;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state copy_resubmit_meta_0 {
          user_meta.resubmit_meta.d1 = resub_meta.d1;
          transition select(user_meta.resubmit_meta.d1) {
             8w0 : resubmit_data_is_0;
             8w1 : resubmit_data_is_1;
          }
        }
        state resubmit_data_is_0 {
          user_meta.resubmit_meta.d2 = resub_meta.d2;
          transition packet_in_parsing;
        }
        state resubmit_data_is_1 {
          user_meta.resubmit_meta.d2 = resub_meta.d2;
          transition packet_in_parsing;
        }
        state packet_in_parsing {
          transition accept;
        }
)"),
    P4_SOURCE(R"()"));

    EXPECT_EQ(::errorCount(), 0u);
}

// user may directly select on the resubmit metadata and branch
// to subsequent parse state.
TEST_F(PortableSwitchTest, ResubmitSelectOnField) {
    auto test = createPSAParserTest(
P4_SOURCE(R"(
        bit<8> d1;
        bit<8> d2;
        bit<8> d3;
)"),
P4_SOURCE(R"(
        state copy_resubmit_meta_0 {
          transition select(resub_meta.d1) {
             8w0 : resubmit_data_is_0;
             8w1 : resubmit_data_is_1;
          }
        }
        state start {
          transition select(istd.packet_path) {
            PacketPath_t.RESUBMIT: copy_resubmit_meta_0;
            PacketPath_t.NORMAL: packet_in_parsing;
          }
        }
        state resubmit_data_is_0 {
          user_meta.resubmit_meta.d2 = resub_meta.d3;
          user_meta.resubmit_meta.d3 = resub_meta.d2;
          transition packet_in_parsing;
        }
        state resubmit_data_is_1 {
          user_meta.resubmit_meta.d2 = resub_meta.d2;
          user_meta.resubmit_meta.d3 = resub_meta.d3;
          transition packet_in_parsing;
        }
        state packet_in_parsing {
          transition accept;
        }
)"),
P4_SOURCE(R"(
        resub_meta = meta.resubmit_meta;
)"));

    EXPECT_EQ(::errorCount(), 0u);
}

// user may use a struct to implement a header union with a selector byte
// to choose sub-field in the struct.

// user may use a header union to support multiple resubmit data type.



}  // namespace Test
