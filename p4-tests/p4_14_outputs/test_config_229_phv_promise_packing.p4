#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> a;
}

header hdr0_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

header hdr1_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

header hdr2_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @pa_container_size("ingress", "hdr0.a", 32) @name(".hdr0") 
    hdr0_t hdr0;
    @name(".hdr1") 
    hdr1_t hdr1;
    @pa_container_size("ingress", "hdr2.c", 32) @name(".hdr2") 
    hdr2_t hdr2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract(hdr.hdr0);
        transition p_hdr1;
    }
    @name(".p_hdr1") state p_hdr1 {
        packet.extract(hdr.hdr1);
        meta.meta.a = hdr.hdr1.a;
        transition p_hdr2;
    }
    @name(".p_hdr2") state p_hdr2 {
        packet.extract(hdr.hdr2);
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
        hdr.hdr0.a = hdr.hdr2.a;
        hdr.hdr2.c = hdr.hdr1.c;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            do_nothing;
            action_0;
        }
        key = {
            hdr.hdr0.a : ternary;
            meta.meta.a: exact;
        }
        size = 512;
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
        packet.emit(hdr.hdr0);
        packet.emit(hdr.hdr1);
        packet.emit(hdr.hdr2);
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

