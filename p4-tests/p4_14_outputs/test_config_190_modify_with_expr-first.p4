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
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".action_0") action action_0(bit<16> param0, bit<16> param1, bit<16> param2) {
        hdr.pkt.a = hdr.pkt.b + 32w2;
        hdr.pkt.b = 32w3 - hdr.pkt.b;
        hdr.pkt.c = hdr.pkt.c >> 3;
        hdr.pkt.d = hdr.pkt.d << 7;
        hdr.pkt.e = param0 | hdr.pkt.e;
        hdr.pkt.f = hdr.pkt.f & param1;
        hdr.pkt.g = hdr.pkt.g ^ 16w0xfff;
        hdr.pkt.h = ~param2;
    }
    @name(".table_0") table table_0 {
        actions = {
            nop();
            action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.srcPort: exact @name("pkt.srcPort") ;
            hdr.pkt.dstPort: ternary @name("pkt.dstPort") ;
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
        packet.emit<pkt_t>(hdr.pkt);
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

