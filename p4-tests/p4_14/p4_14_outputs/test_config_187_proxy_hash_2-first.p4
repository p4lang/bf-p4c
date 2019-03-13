#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<8>  protocol;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> blah;
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
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
    @name(".set_dip") action set_dip() {
        hdr.pkt.blah = 16w8;
    }
    @proxy_hash_width(24) @name(".exm_proxy_hash") table exm_proxy_hash {
        actions = {
            nop();
            set_dip();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.srcAddr : exact @name("pkt.srcAddr") ;
            hdr.pkt.dstAddr : exact @name("pkt.dstAddr") ;
            hdr.pkt.protocol: exact @name("pkt.protocol") ;
            hdr.pkt.srcPort : exact @name("pkt.srcPort") ;
            hdr.pkt.dstPort : exact @name("pkt.dstPort") ;
        }
        size = 400000;
        default_action = NoAction();
    }
    apply {
        exm_proxy_hash.apply();
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

