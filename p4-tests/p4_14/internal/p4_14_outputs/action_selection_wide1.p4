#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> r1;
    bit<32> r2;
    bit<32> r3;
    bit<32> r4;
    bit<32> r5;
    bit<32> r6;
    bit<32> r7;
    bit<32> r8;
    bit<32> r9;
    bit<32> r10;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
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

@name(".set_r1_10") @mode("fair") action_selector(HashAlgorithm.crc16, 32w1024, 32w14) set_r1_10;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setr1_5") action setr1_5(bit<32> val1, bit<32> val2, bit<32> val3, bit<32> val4, bit<32> val5) {
        hdr.data.r1 = val1;
        hdr.data.r2 = val2;
        hdr.data.r3 = val3;
        hdr.data.r4 = val4;
        hdr.data.r5 = val5;
    }
    @name(".setr6_10") action setr6_10(bit<32> val6, bit<32> val7, bit<32> val8, bit<32> val9, bit<32> val10) {
        hdr.data.r6 = val6;
        hdr.data.r7 = val7;
        hdr.data.r8 = val8;
        hdr.data.r9 = val9;
        hdr.data.r10 = val10;
    }
    @name(".test1") table test1 {
        actions = {
            setr1_5;
            setr6_10;
        }
        key = {
            hdr.data.f1: exact;
            hdr.data.h1: selector;
            hdr.data.h2: selector;
            hdr.data.h3: selector;
        }
        size = 10000;
        implementation = set_r1_10;
    }
    apply {
        test1.apply();
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

