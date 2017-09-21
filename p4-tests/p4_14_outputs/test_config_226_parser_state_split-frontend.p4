#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> a;
    bit<8>  b;
    bit<5>  c;
    bit<3>  d;
}

header hdr0_t {
    bit<8>  a;
    bit<32> b;
}

struct metadata {
    @pa_container_size("ingress", "meta.a", 16) @name(".meta") 
    meta_t meta;
}

struct headers {
    @pa_container_size("ingress", "hdr0.b", 32) @name(".hdr0") 
    hdr0_t hdr0;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        meta.meta.c = 5w0;
        transition accept;
    }
    @name(".start") state start {
        transition p_hdr0;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing_0() {
    }
    @name(".table_i0") table table_i0_0 {
        actions = {
            do_nothing_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr0.a : ternary @name("hdr0.a") ;
            meta.meta.c: exact @name("meta.c") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        table_i0_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
