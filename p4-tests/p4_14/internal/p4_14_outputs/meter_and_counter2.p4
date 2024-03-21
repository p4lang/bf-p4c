#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
    bit<16> h7;
    bit<16> h8;
    bit<16> h9;
    bit<8>  color_1;
    bit<8>  color_2;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".counter2") direct_counter(CounterType.packets) counter2;
    @name(".meter1") meter(32w1000, MeterType.bytes) meter1;
    @name(".meter2") meter(32w2000, MeterType.bytes) meter2;
    @name(".h1_3") action h1_3(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
        meter1.execute_meter((bit<32>)32w7, hdr.data.color_1);
    }
    @name(".h4_6") action h4_6(bit<16> val4, bit<16> val5, bit<16> val6) {
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
    }
    @name(".h7_9") action h7_9(bit<16> val7, bit<16> val8, bit<16> val9) {
        hdr.data.h7 = val7;
        hdr.data.h8 = val8;
        hdr.data.h9 = val9;
        meter2.execute_meter((bit<32>)32w7, hdr.data.color_2);
    }
    @name(".test1") table test1 {
        actions = {
            h1_3;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 32000;
    }
    @name(".h4_6") action h4_6_0(bit<16> val4, bit<16> val5, bit<16> val6) {
        counter2.count();
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
    }
    @name(".test2") table test2 {
        actions = {
            h4_6_0;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 2048;
        counters = counter2;
    }
    @name(".test3") table test3 {
        actions = {
            h7_9;
        }
        key = {
            hdr.data.f3: exact;
        }
        size = 10000;
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
        packet.emit(hdr.data);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

