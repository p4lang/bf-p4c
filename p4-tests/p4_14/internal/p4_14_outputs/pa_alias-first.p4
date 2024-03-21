#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<8> m1;
    bit<8> m2;
}

@pa_alias("ingress", "pkt.f2", "meta.m1") header pkt_t {
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
}

struct metadata {
    @name(".meta") 
    metadata_t meta;
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_pkt") state parse_pkt {
        packet.extract<pkt_t>(hdr.pkt);
        meta.meta.m2 = 8w0x3;
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
    @name(".first") action first() {
        hdr.pkt.f1 = 8w0x8;
        hdr.pkt.f2 = 8w0x4;
        hdr.pkt.f3 = 8w0x2;
    }
    @name(".second") action second(bit<8> param) {
        hdr.pkt.f1 = param;
        hdr.pkt.f2 = meta.meta.m2;
        hdr.pkt.f3 = 8w0x5;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.f1: exact @name("pkt.f1") ;
        }
        default_action = NoAction();
    }
    @name(".test1") table test1 {
        actions = {
            first();
            second();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.m1: exact @name("meta.m1") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        setting_port.apply();
        test1.apply();
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

