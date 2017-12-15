#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<8>  d;
    bit<16> e;
}

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_pkt") state parse_pkt {
        packet.extract<pkt_t>(hdr.pkt);
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
    @name(".action_0") action action_0(bit<32> word) {
        hdr.pkt.c = word | hdr.pkt.c;
        hdr.pkt.d = 8w0;
        hdr.pkt.e = 16w0;
    }
    @name(".action_1") action action_1(bit<16> halfword) {
        hdr.pkt.e = hdr.pkt.e | halfword;
        hdr.pkt.c = 32w0;
        hdr.pkt.d = 8w0;
    }
    @name(".action_2") action action_2(bit<8> byte) {
        hdr.pkt.d = hdr.pkt.d + byte;
        hdr.pkt.c = 32w0;
        hdr.pkt.e = 16w0;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.a: exact @name("pkt.a") ;
        }
        default_action = NoAction();
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0();
            action_1();
            action_2();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.b: exact @name("pkt.b") ;
        }
        size = 1024;
        default_action = NoAction();
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

