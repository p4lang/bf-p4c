#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<3> a;
}

header hdr0_t {
    bit<1>  pre;
    bit<3>  a;
    bit<12> b;
    bit<32> c;
    bit<16> d;
}

struct metadata {
    @pa_container_size("ingress", "meta.a", 16) @name(".meta") 
    meta_t meta;
}

struct headers {
    @pa_container_size("ingress", "hdr0.a", 16) @name(".hdr0") 
    hdr0_t hdr0;
    @name(".hdr1") 
    hdr0_t hdr1;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        meta.meta.a = hdr.hdr0.a;
        transition p_hdr1;
    }
    @name(".p_hdr1") state p_hdr1 {
        packet.extract<hdr0_t>(hdr.hdr1);
        transition accept;
    }
    @name(".start") state start {
        transition p_hdr0;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_0") action action_0() {
        hdr.hdr0.c = 32w1;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            do_nothing();
            action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr0.a : ternary @name("hdr0.a") ;
            meta.meta.a: exact @name("meta.a") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        table_i0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
        packet.emit<hdr0_t>(hdr.hdr1);
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

