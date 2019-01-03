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
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".stats1") counter(32w64, CounterType.packets_and_bytes) stats1_0;
    @name(".stats2") counter(32w64, CounterType.packets_and_bytes) stats2_0;
    @name(".action1") action action1() {
        stats1_0.count(32w1);
    }
    @name(".action2") action action2() {
        stats2_0.count(32w1);
    }
    @name(".table1") table table1_0 {
        actions = {
            action1();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name(".table2") table table2_0 {
        actions = {
            action2();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.pkt.b: exact @name("pkt.b") ;
        }
        default_action = NoAction_3();
    }
    apply {
        if (hdr.pkt.isValid()) 
            table1_0.apply();
        if (hdr.pkt.isValid()) 
            table2_0.apply();
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

