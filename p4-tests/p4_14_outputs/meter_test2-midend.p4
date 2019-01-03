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
    bit<16> h13;
    bit<8>  color_1;
    bit<8>  color_2;
    bit<8>  color_3;
    bit<8>  color_4;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".NoAction") action NoAction_8() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".meter_1") direct_meter<bit<8>>(MeterType.bytes) meter_0;
    @name(".meter_2") direct_meter<bit<8>>(MeterType.bytes) meter_5;
    @name(".meter_3") meter(32w1000, MeterType.packets) meter_6;
    @name(".meter_4") meter(32w4096, MeterType.packets) meter_7;
    @name(".h7_9") action h7_1(bit<16> val7, bit<16> val8, bit<16> val9) {
        hdr.data.h7 = val7;
        hdr.data.h8 = val8;
        hdr.data.h9 = val9;
        meter_6.execute_meter<bit<8>>(32w7, hdr.data.color_3);
    }
    @name(".h10_12") action h10_1(bit<16> val10, bit<16> val11, bit<16> val12) {
        hdr.data.h10 = val10;
        hdr.data.h11 = val11;
        hdr.data.h12 = val12;
        meter_7.execute_meter<bit<8>>(32w7, hdr.data.color_4);
    }
    @name(".set_port") action set_port(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".seth13") action seth13(bit<16> val13) {
        hdr.data.h13 = val13;
    }
    @name(".h1_3") action h1_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        meter_0.read(hdr.data.color_1);
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
    }
    @name(".test1") table test1_0 {
        actions = {
            h1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 6000;
        meters = meter_0;
        default_action = NoAction_0();
    }
    @name(".h4_6") action h4_0(bit<16> val4, bit<16> val5, bit<16> val6) {
        meter_5.read(hdr.data.color_2);
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
    }
    @name(".test2") table test2_0 {
        actions = {
            h4_0();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 10000;
        meters = meter_5;
        default_action = NoAction_7();
    }
    @name(".test3") table test3_0 {
        actions = {
            h7_1();
            @defaultonly NoAction_8();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        size = 2000;
        default_action = NoAction_8();
    }
    @name(".test4") table test4_0 {
        actions = {
            h10_1();
            @defaultonly NoAction_9();
        }
        key = {
            hdr.data.f4: exact @name("data.f4") ;
        }
        size = 8192;
        default_action = NoAction_9();
    }
    @name(".test5") table test5_0 {
        actions = {
            set_port();
            @defaultonly NoAction_10();
        }
        key = {
            hdr.data.color_1: ternary @name("data.color_1") ;
            hdr.data.color_2: ternary @name("data.color_2") ;
        }
        default_action = NoAction_10();
    }
    @name(".test6") table test6_0 {
        actions = {
            seth13();
            @defaultonly NoAction_11();
        }
        key = {
            hdr.data.color_3: ternary @name("data.color_3") ;
            hdr.data.color_4: ternary @name("data.color_4") ;
        }
        default_action = NoAction_11();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
        test4_0.apply();
        test5_0.apply();
        test6_0.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

