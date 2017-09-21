#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<8>  protocol;
    bit<16> srcPort;
    bit<16> dstPort;
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
    @name(".action1") action action1() {
        hdr.pkt.srcAddr = 32w1;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action2") action action2() {
        hdr.pkt.dstAddr = 32w2;
    }
    @name(".table1") table table1 {
        actions = {
            action1();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.srcPort: ternary @name("pkt.srcPort") ;
        }
        default_action = NoAction();
    }
    @name(".table2") table table2 {
        actions = {
            action2();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.dstPort: exact @name("pkt.dstPort") ;
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.pkt.isValid()) 
            if (hdr.pkt.protocol == 8w0) {
                table1.apply();
                table2.apply();
            }
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
