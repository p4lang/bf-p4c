#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<8> f;
}

header pkt_t {
    bit<10> f1;
    bit<10> f2;
    bit<10> f3;
    bit<2>  f4;
}

struct metadata {
    @name(".m") 
    metadata_t m;
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_pkt") state parse_pkt {
        packet.extract<pkt_t>(hdr.pkt);
        meta.m.f = 8w0x4;
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".action_0") action action_0() {
        hdr.pkt.f1 = (bit<10>)meta.m.f;
        hdr.pkt.f2 = 10w0;
        hdr.pkt.f3 = 10w3;
        hdr.pkt.f4 = 2w1;
    }
    @name(".setting_port") table setting_port_0 {
        actions = {
            setport();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.f2: exact @name("pkt.f2") ;
        }
        default_action = NoAction_0();
    }
    @name(".table_0") table table_1 {
        actions = {
            action_0();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.pkt.f1: exact @name("pkt.f1") ;
        }
        size = 1024;
        default_action = NoAction_3();
    }
    apply {
        table_1.apply();
        setting_port_0.apply();
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

