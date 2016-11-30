#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<8>  b1;
    bit<8>  color_1;
    bit<8>  color_2;
}

struct metadata {
}

struct headers {
    @name("data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_1") action NoAction_0() {
    }
    @name("NoAction_2") action NoAction_3() {
    }
    @name("meter_1") meter(32w1024, CounterType.bytes) meter_1;
    @name("meter_2") meter(32w1024, CounterType.bytes) meter_2;
    @name("h1_2") action h1_0(bit<16> val1, bit<16> val2) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        meter_1.execute_meter<bit<8>>(32w7, hdr.data.color_1);
    }
    @name("h3_b1") action h3_b1_0(bit<16> val3, bit<8> val1) {
        hdr.data.h3 = val3;
        hdr.data.b1 = val1;
        meter_2.execute_meter<bit<8>>(32w7, hdr.data.color_2);
    }
    @name("test1") table test1() {
        actions = {
            h1_0();
            NoAction_0();
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 1024;
        default_action = NoAction_0();
    }
    @name("test2") table test2() {
        actions = {
            h3_b1_0();
            NoAction_3();
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 1024;
        default_action = NoAction_3();
    }
    apply {
        test1.apply();
        test2.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
