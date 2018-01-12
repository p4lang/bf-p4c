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
        packet.extract<pkt_t>(hdr.pkt);
        packet.extract<pkt_t>(hdr.pkt1);
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_3() {
    }
    @name(".setport") action setport_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".action_0") action action_4(bit<49> p0) {
        hdr.pkt.a = p0;
    }
    @name(".action_1") action action_5(bit<17> p0) {
        hdr.pkt.b = p0;
    }
    @name(".action_2") action action_6() {
        hdr.pkt.a = hdr.pkt1.a;
        hdr.pkt.b = hdr.pkt1.b;
    }
    @name(".action_3") action action_7() {
        hdr.pkt.a = hdr.pkt1.a;
        hdr.pkt.b = hdr.pkt1.b;
        hdr.pkt.c = hdr.pkt1.c;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.c: exact @name("pkt.c") ;
        }
        default_action = NoAction_0();
    }
    @name(".table_0") table table_0 {
        actions = {
            action_4();
            action_5();
            action_6();
            action_7();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.pkt.a: exact @name("pkt.a") ;
            hdr.pkt.b: exact @name("pkt.b") ;
        }
        size = 1024;
        default_action = NoAction_3();
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
        packet.emit<pkt_t>(hdr.pkt);
        packet.emit<pkt_t>(hdr.pkt1);
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

