#include <core.p4>
#include <v1model.p4>

header data_t {
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
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".first") action first(bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4, bit<16> half1, bit<16> half2) {
        hdr.data.c1 = byte1;
        hdr.data.c2 = byte2;
        hdr.data.c3 = byte3;
        hdr.data.c4 = byte4;
        hdr.data.h1 = half1;
        hdr.data.h2 = half2;
    }
    @name(".second") action second(bit<32> full1, bit<32> full2) {
        hdr.data.f3 = full1;
        hdr.data.f4 = full2;
    }
    @name(".third") action third(bit<8> byte1, bit<8> byte2, bit<16> half1) {
        hdr.data.c1 = byte1;
        hdr.data.c2 = byte2;
        hdr.data.h1 = half1;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
    }
    @name(".test1") table test1 {
        actions = {
            first();
            second();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            third();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
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

