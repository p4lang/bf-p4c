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
    @name(".meter_1") direct_meter<bit<8>>(MeterType.bytes) meter_1;
    @name(".meter_2") direct_meter<bit<8>>(MeterType.bytes) meter_2;
    @name(".h1_3") action h1_3(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
    }
    @name(".h4_6") action h4_6(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name(".h1_3") action h1_3_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        meter_1.read(hdr.data.color_1);
        hdr.data.h1 = val1;
        hdr.data.h2 = val2;
        hdr.data.h3 = val3;
    }
    @name(".test1") table test1 {
        actions = {
            h1_3_0;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 6000;
        meters = meter_1;
    }
    @name(".h4_6") action h4_6_0(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        meter_2.read(hdr.data.color_2);
        hdr.data.h4 = val4;
        hdr.data.h5 = val5;
        hdr.data.h6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name(".test2") table test2 {
        actions = {
            h4_6_0;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 10000;
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

