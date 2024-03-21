#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<2> f1;
    bit<3> f2;
    bit<3> f3;
}

header pkt_t {
    bit<2> f1;
    bit<3> f2;
    bit<3> f3;
}

struct metadata {
    @name(".meta1") 
    meta_t meta1;
    @name(".meta2") 
    meta_t meta2;
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.pkt);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_2") action action_2() {
        hdr.pkt.f2 = meta.meta2.f2;
        hdr.pkt.f1 = 2w2;
        hdr.pkt.f3 = 3w6;
    }
    @name(".action_3") action action_3() {
        hdr.pkt.f3 = meta.meta1.f3;
        hdr.pkt.f2 = 3w4;
        hdr.pkt.f1 = 2w1;
    }
    @name(".table_1") table table_1 {
        actions = {
            action_2;
            action_3;
        }
        key = {
            hdr.pkt.f1: exact;
        }
        size = 1024;
    }
    apply {
        table_1.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".action_0") action action_0(bit<2> a, bit<3> b, bit<3> c) {
        meta.meta1.f1 = hdr.pkt.f1;
        meta.meta1.f2 = hdr.pkt.f2;
        meta.meta1.f3 = hdr.pkt.f3;
        meta.meta2.f1 = a;
        meta.meta2.f2 = b;
        meta.meta2.f3 = c;
    }
    @name(".action_1") action action_1(bit<2> a, bit<3> b, bit<3> c) {
        meta.meta2.f1 = hdr.pkt.f1;
        meta.meta2.f2 = hdr.pkt.f2;
        meta.meta2.f3 = hdr.pkt.f3;
        meta.meta1.f1 = a;
        meta.meta1.f2 = b;
        meta.meta1.f3 = c;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.pkt.f1: exact;
        }
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0;
            action_1;
        }
        key = {
            hdr.pkt.f1: exact;
        }
        size = 1024;
    }
    apply {
        table_0.apply();
        setting_port.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.pkt);
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

