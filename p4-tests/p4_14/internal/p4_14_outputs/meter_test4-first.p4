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
    bit<8>  b1;
    bit<8>  color_1;
    bit<8>  color_2;
    bit<8>  color_3;
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
    @name(".meter_1") meter(32w1024, MeterType.bytes) meter_1;
    @name(".meter_2") meter(32w1024, MeterType.bytes) meter_2;
    @name(".meter_3") meter(32w1024, MeterType.bytes) meter_3;
    @name(".h1_2") action h1_2(bit<16> val1, bit<16> val2) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        meter_1.execute_meter<bit<8>>(32w7, hdr.data.color_1);
    }
    @name(".h3_b1") action h3_b1(bit<16> val3, bit<8> val1) {
        hdr.data.h3 = val3;
        hdr.data.b1 = val1;
        meter_2.execute_meter<bit<8>>(32w7, hdr.data.color_2);
    }
    @name(".h4_5") action h4_5(bit<16> val4, bit<16> val5) {
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        meter_3.execute_meter<bit<8>>(32w7, hdr.data.color_3);
    }
    @name(".test1") table test1 {
        actions = {
            h1_2();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            h3_b1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            h4_5();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
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

