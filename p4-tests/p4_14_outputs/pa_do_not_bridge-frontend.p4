#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<8> m;
}

@pa_do_not_bridge("ingress", "meta.m") @pa_container_size("ingress", "pkt.f1", 8) @pa_container_size("ingress", "pkt.f2", 8) @pa_container_size("ingress", "pkt.f3", 8) @pa_container_size("egress", "pkt.f1", 8) @pa_container_size("egress", "pkt.f2", 8) @pa_container_size("egress", "pkt.f3", 8) @pa_container_size("ingress", "meta.m", 8) @pa_container_size("egress", "meta.m", 8) header pkt_t {
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
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".second") action second(bit<8> param) {
        hdr.pkt.f1 = param;
        hdr.pkt.f3 = meta.meta.m;
    }
    @name(".test2") table test2_0 {
        actions = {
            second();
            @defaultonly NoAction_0();
        }
        key = {
            meta.meta.m: exact @name("meta.m") ;
        }
        default_action = NoAction_0();
    }
    apply {
        test2_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".first") action first() {
        hdr.pkt.f1 = 8w0x8;
        hdr.pkt.f2 = meta.meta.m;
        meta.meta.m = 8w0x2;
    }
    @name(".setting_port") table setting_port_0 {
        actions = {
            setport();
            @defaultonly NoAction_1();
        }
        key = {
            hdr.pkt.f1: exact @name("pkt.f1") ;
        }
        default_action = NoAction_1();
    }
    @name(".test1") table test1_0 {
        actions = {
            first();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.pkt.f2: exact @name("pkt.f2") ;
        }
        size = 1024;
        default_action = NoAction_5();
    }
    apply {
        test1_0.apply();
        setting_port_0.apply();
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

