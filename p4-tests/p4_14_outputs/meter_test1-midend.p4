#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_3() {
    }
    @name("meter_1") direct_meter<bit<8>>(CounterType.bytes) meter_1;
    @name("meter_2") direct_meter<bit<8>>(CounterType.bytes) meter_2;
    @name(".h1_3") action h1_1(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
        meter_1.read(hdr.data.color_1);
    }
    @name("test1") table test1 {
        actions = {
            h1_1();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        size = 6000;
        default_action = NoAction_0();
        meters = meter_1;
    }
    @name(".h4_6") action h4_1(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
        standard_metadata.egress_spec = port;
        meter_2.read(hdr.data.color_2);
    }
    @name("test2") table test2 {
        actions = {
            h4_1();
            @default_only NoAction_3();
        }
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        size = 10000;
        default_action = NoAction_3();
        meters = meter_2;
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
