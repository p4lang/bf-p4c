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
        packet.extract(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".second") action second(bit<8> param) {
        hdr.pkt.f1 = param;
        hdr.pkt.f3 = meta.meta.m;
    }
    @name(".test2") table test2 {
        actions = {
            second;
        }
        key = {
            meta.meta.m: exact;
        }
    }
    apply {
        test2.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".first") action first() {
        hdr.pkt.f1 = 8w0x8;
        hdr.pkt.f2 = meta.meta.m;
        meta.meta.m = 8w0x2;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport;
        }
        key = {
            hdr.pkt.f1: exact;
        }
    }
    @name(".test1") table test1 {
        actions = {
            first;
        }
        key = {
            hdr.pkt.f2: exact;
        }
        size = 1024;
    }
    apply {
        test1.apply();
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

