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
    @name(".counter_0") @min_width(32) counter(32w2048, CounterType.packets_and_bytes) counter_0;
    @name(".action_0") action action_0(bit<32> param0, bit<8> param1, bit<8> param2, bit<8> param3, bit<8> param4) {
        counter_0.count(32w2047);
        hdr.pkt.a = param0;
    }
    @name(".table_0") table table_0 {
        actions = {
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

