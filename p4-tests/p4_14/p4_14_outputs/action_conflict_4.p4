#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<49> a;
    bit<17> b;
    bit<14> c;
}

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
    @name(".pkt1") 
    pkt_t pkt1;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_pkt") state parse_pkt {
        packet.extract(hdr.pkt);
        packet.extract(hdr.pkt1);
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".action_0") action action_0(bit<49> p0) {
        hdr.pkt.a = p0;
    }
    @name(".action_1") action action_1(bit<17> p0) {
        hdr.pkt.b = p0;
    }
    @name(".action_2") action action_2() {
        hdr.pkt.a = hdr.pkt1.a;
        hdr.pkt.b = hdr.pkt1.b;
    }
    @name(".action_3") action action_3() {
        hdr.pkt.a = hdr.pkt1.a;
        hdr.pkt.b = hdr.pkt1.b;
        hdr.pkt.c = hdr.pkt1.c;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.pkt.c: exact;
        }
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0;
            action_1;
            action_2;
            action_3;
        }
        key = {
            hdr.pkt.a: exact;
            hdr.pkt.b: exact;
        }
        size = 1024;
    }
    apply {
        table_0.apply();
        setting_port.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.pkt);
        packet.emit(hdr.pkt1);
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

