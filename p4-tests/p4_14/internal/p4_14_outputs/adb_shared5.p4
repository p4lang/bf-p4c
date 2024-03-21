#include <core.p4>
#include <v1model.p4>

header hdr_t {
    bit<32> read;
    bit<8>  b0;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<8>  b6;
    bit<8>  b7;
    bit<8>  b8;
    bit<8>  b9;
    bit<8>  ba;
    bit<8>  bb;
    bit<8>  bc;
    bit<8>  bd;
    bit<8>  be;
    bit<8>  bf;
    bit<16> h0;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
    bit<16> h7;
    bit<32> f0;
    bit<32> f1;
}

struct metadata {
}

struct headers {
    @name(".hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.hdr);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".a1") action a1(bit<8> byte0, bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4, bit<8> byte5, bit<8> byte6, bit<8> byte7, bit<8> byte8, bit<8> byte9, bit<8> bytea, bit<8> byteb, bit<8> bytec, bit<8> byted, bit<8> bytee, bit<8> bytef) {
        hdr.hdr.b0 = byte0;
        hdr.hdr.b1 = byte1;
        hdr.hdr.b2 = byte2;
        hdr.hdr.b3 = byte3;
        hdr.hdr.b4 = byte4;
        hdr.hdr.b5 = byte5;
        hdr.hdr.b6 = byte6;
        hdr.hdr.b7 = byte7;
        hdr.hdr.b8 = byte8;
        hdr.hdr.b9 = byte9;
        hdr.hdr.ba = bytea;
        hdr.hdr.bb = byteb;
        hdr.hdr.bc = bytec;
        hdr.hdr.bd = byted;
        hdr.hdr.be = bytee;
        hdr.hdr.bf = bytef;
    }
    @name(".a2") action a2(bit<16> half0, bit<16> half1, bit<16> half2, bit<16> half3, bit<16> half4, bit<16> half5, bit<16> half6, bit<16> half7) {
        hdr.hdr.h0 = half0;
        hdr.hdr.h1 = half1;
        hdr.hdr.h2 = half2;
        hdr.hdr.h3 = half3;
        hdr.hdr.h4 = half4;
        hdr.hdr.h5 = half5;
        hdr.hdr.h6 = half6;
        hdr.hdr.h7 = half7;
    }
    @name(".a3") action a3(bit<8> byte0, bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4, bit<8> byte5, bit<8> byte6, bit<8> byte7, bit<8> byte8, bit<8> byte9, bit<16> half5, bit<16> half6, bit<16> half7) {
        hdr.hdr.b0 = byte0;
        hdr.hdr.b1 = byte1;
        hdr.hdr.b2 = byte2;
        hdr.hdr.b3 = byte3;
        hdr.hdr.b4 = byte4;
        hdr.hdr.b5 = byte5;
        hdr.hdr.b6 = byte6;
        hdr.hdr.b7 = byte7;
        hdr.hdr.b8 = byte8;
        hdr.hdr.b9 = byte9;
        hdr.hdr.h5 = half5;
        hdr.hdr.h6 = half6;
        hdr.hdr.h7 = half7;
    }
    @name(".a4") action a4(bit<8> byte0, bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4, bit<8> byte5, bit<16> half0, bit<16> half1, bit<16> half2, bit<32> full0) {
        hdr.hdr.b0 = byte0;
        hdr.hdr.b1 = byte1;
        hdr.hdr.b2 = byte2;
        hdr.hdr.b3 = byte3;
        hdr.hdr.b4 = byte4;
        hdr.hdr.b5 = byte5;
        hdr.hdr.h0 = half0;
        hdr.hdr.h1 = half1;
        hdr.hdr.h2 = half2;
        hdr.hdr.f0 = full0;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.hdr.read: exact;
        }
    }
    @name(".t1") table t1 {
        actions = {
            a1;
            a2;
            a3;
            a4;
        }
        key = {
            hdr.hdr.read: exact;
        }
    }
    apply {
        t1.apply();
        setting_port.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.hdr);
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

