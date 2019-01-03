#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<8>  protocol;
    bit<16> srcPort;
    bit<16> dstPort;
}

header pkt2_t {
    bit<32> a;
    bit<16> b;
}

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t  pkt;
    @name(".pkt2") 
    pkt2_t pkt2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @terminate_parsing("egress") @name(".parse_1") state parse_1 {
        packet.extract<pkt_t>(hdr.pkt);
        transition parse_2;
    }
    @name(".parse_2") state parse_2 {
        packet.extract<pkt2_t>(hdr.pkt2);
        transition accept;
    }
    @name(".start") state start {
        transition parse_1;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".action1") action action1() {
        hdr.pkt.srcAddr = 32w1;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".table1") table table1_0 {
        actions = {
            action1();
            do_nothing();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.srcPort: ternary @name("pkt.srcPort") ;
        }
        default_action = NoAction_0();
    }
    apply {
        if (hdr.pkt.isValid()) 
            table1_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<pkt_t>(hdr.pkt);
        packet.emit<pkt2_t>(hdr.pkt2);
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

