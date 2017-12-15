#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> read;
    bit<8>  c1;
    bit<8>  c2;
    bit<8>  c3;
    bit<8>  c4;
    bit<8>  c5;
    bit<8>  c6;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<32> f1;
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
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".first") action first(bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4, bit<8> byte5, bit<8> byte6, bit<16> half3) {
        hdr.data.c1 = byte1;
        hdr.data.c2 = byte2;
        hdr.data.c3 = byte3;
        hdr.data.c4 = byte4;
        hdr.data.c5 = byte5;
        hdr.data.c6 = byte6;
        hdr.data.h3 = half3;
    }
    @name(".second") action second(bit<16> half1, bit<16> half2, bit<16> half3) {
        hdr.data.h1 = half1;
        hdr.data.h2 = half2;
        hdr.data.h3 = half3;
    }
    @name(".third") action third(bit<8> byte1, bit<8> byte2, bit<16> half1, bit<32> full1) {
        hdr.data.c1 = byte1;
        hdr.data.c2 = byte2;
        hdr.data.h1 = half1;
        hdr.data.f1 = full1;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    @name(".test1") table test1 {
        actions = {
            first;
            second;
            third;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    apply {
        test1.apply();
        setting_port.apply();
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

