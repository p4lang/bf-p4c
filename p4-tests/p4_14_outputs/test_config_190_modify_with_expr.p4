#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<8>  protocol;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
    bit<16> e;
    bit<16> f;
    bit<16> g;
    bit<16> h;
}

struct metadata {
}

struct headers {
    @name("pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.pkt);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".action_0") action action_0(bit<16> param0, bit<16> param1, bit<8> param2) {
        hdr.pkt.a = (bit<32>)(hdr.pkt.b + 32w2);
        hdr.pkt.b = (bit<32>)(32w3 - hdr.pkt.b);
        hdr.pkt.c = (bit<32>)(hdr.pkt.c >> 32w3);
        hdr.pkt.d = (bit<32>)(hdr.pkt.d << 32w7);
        hdr.pkt.e = (bit<16>)(param0 | hdr.pkt.e);
        hdr.pkt.f = (bit<16>)(hdr.pkt.f & param1);
        hdr.pkt.g = (bit<16>)(hdr.pkt.g ^ 16w0xfff);
        hdr.pkt.h = (bit<16>)~param2;
    }
    @name("table_0") table table_0 {
        actions = {
            nop;
            action_0;
            @default_only NoAction;
        }
        key = {
            hdr.pkt.srcPort: exact;
            hdr.pkt.dstPort: ternary;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.pkt);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
