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
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
    bit<16> h7;
    bit<16> h8;
    bit<16> h9;
    bit<16> h10;
    bit<16> h11;
    bit<16> h12;
    bit<8>  color_1;
    bit<8>  color_2;
    bit<8>  color_3;
    bit<8>  color_4;
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
    @name("NoAction_2") action NoAction_5() {
    }
    @name("NoAction_3") action NoAction_6() {
    }
    @name("NoAction_4") action NoAction_7() {
    }
    @name("meter_1") meter(32w12000, CounterType.bytes) meter_1;
    @name("meter_2") meter(32w1024, CounterType.bytes) meter_2;
    @name("meter_3") meter(32w6000, CounterType.bytes) meter_3;
    @name("meter_4") meter(32w1024, CounterType.bytes) meter_4;
    @name("h1_3") action h1_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
        meter_1.execute_meter<bit<8>>(32w7, hdr.data.color_1);
    }
    @name("h4_6") action h4_0(bit<16> val4, bit<16> val5, bit<16> val6) {
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
        meter_2.execute_meter<bit<8>>(32w7, hdr.data.color_2);
    }
    @name("h7_9") action h7_0(bit<16> val7, bit<16> val8, bit<16> val9) {
        hdr.data.h7 = val7;
        hdr.data.h8 = val8;
        hdr.data.h9 = val9;
        meter_3.execute_meter<bit<8>>(32w7, hdr.data.color_3);
    }
    @name("h10_12") action h10_0(bit<16> val10, bit<16> val11, bit<16> val12) {
        hdr.data.h10 = val10;
        hdr.data.h11 = val11;
        hdr.data.h12 = val12;
        meter_4.execute_meter<bit<8>>(32w7, hdr.data.color_4);
    }
    @name("test1") table test1() {
        actions = {
            h1_0();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        size = 6000;
        default_action = NoAction_0();
    }
    @name("test2") table test2() {
        actions = {
            h4_0();
            @default_only NoAction_5();
        }
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        size = 10000;
        default_action = NoAction_5();
    }
    @name("test3") table test3() {
        actions = {
            h7_0();
            @default_only NoAction_6();
        }
        key = {
            hdr.data.f3: exact @name("hdr.data.f3") ;
        }
        size = 1000;
        default_action = NoAction_6();
    }
    @name("test4") table test4() {
        actions = {
            h10_0();
            @default_only NoAction_7();
        }
        key = {
            hdr.data.f4: exact @name("hdr.data.f4") ;
        }
        size = 1000;
        default_action = NoAction_7();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
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
