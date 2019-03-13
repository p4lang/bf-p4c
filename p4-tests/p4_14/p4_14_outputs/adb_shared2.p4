#include <core.p4>
#include <v1model.p4>

header first_hdr_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  c1;
    bit<8>  c2;
    bit<8>  c3;
    bit<8>  c4;
    bit<16> h1;
    bit<16> h2;
    bit<32> f3;
    bit<32> f4;
}

header second_hdr_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  c1;
    bit<8>  c2;
    bit<8>  c3;
    bit<8>  c4;
    bit<16> h1;
    bit<16> h2;
    bit<32> f3;
    bit<32> f4;
}

struct metadata {
}

struct headers {
    @name(".first_hdr") 
    first_hdr_t  first_hdr;
    @name(".second_hdr") 
    second_hdr_t second_hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.first_hdr);
        packet.extract(hdr.second_hdr);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".first_hdr1") action first_hdr1(bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<16> half1) {
        hdr.first_hdr.c1 = byte1;
        hdr.first_hdr.c2 = byte2;
        hdr.first_hdr.c3 = byte3;
        hdr.first_hdr.h1 = half1;
    }
    @name(".first_hdr2") action first_hdr2(bit<32> full1, bit<32> full2) {
        hdr.first_hdr.f3 = full1;
        hdr.first_hdr.f4 = full2;
    }
    @name(".second_hdr1") action second_hdr1(bit<8> byte1, bit<8> byte2, bit<16> half1, bit<16> half2) {
        hdr.second_hdr.c1 = byte1;
        hdr.second_hdr.c2 = byte2;
        hdr.second_hdr.h1 = half1;
        hdr.second_hdr.h2 = half2;
    }
    @name(".second_hdr2") action second_hdr2(bit<32> full1, bit<32> full2) {
        hdr.second_hdr.f3 = full1;
        hdr.second_hdr.f4 = full2;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.first_hdr.f1: exact;
        }
    }
    @name(".test1") table test1 {
        actions = {
            first_hdr1;
            first_hdr2;
        }
        key = {
            hdr.first_hdr.f1: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            second_hdr1;
            second_hdr2;
        }
        key = {
            hdr.second_hdr.f1: exact;
        }
    }
    apply {
        test1.apply();
        test2.apply();
        setting_port.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.first_hdr);
        packet.emit(hdr.second_hdr);
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

