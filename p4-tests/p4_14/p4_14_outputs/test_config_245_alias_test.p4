#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> w;
    bit<16> x;
    bit<16> y;
    bit<16> z;
    bit<2>  a;
    bit<4>  b;
    bit<2>  c;
    bit<8>  d;
    bit<8>  e;
    bit<8>  f;
}

header hdr0_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

struct metadata {
    @pa_mutually_exclusive("ingress", "meta.e", "meta.f") @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".hdr0") 
    hdr0_t hdr0;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract(hdr.hdr0);
        meta.meta.e = 8w0;
        meta.meta.f = 8w2;
        transition accept;
    }
    @name(".start") state start {
        transition p_hdr0;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_0") action action_0(bit<8> p) {
        meta.meta.c = 2w3;
    }
    @name(".action_1") action action_1(bit<8> p) {
        meta.meta.y = meta.meta.w + meta.meta.x;
        meta.meta.z = meta.meta.w ^ meta.meta.x;
    }
    @name(".action_2") action action_2(bit<8> p) {
        hdr.hdr0.a = meta.meta.z;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            do_nothing;
            action_0;
        }
        key = {
            hdr.hdr0.a: ternary;
        }
        size = 512;
    }
    @name(".table_i1") table table_i1 {
        actions = {
            do_nothing;
            action_1;
        }
        key = {
            hdr.hdr0.a: ternary;
        }
        size = 1024;
    }
    @name(".table_i2") table table_i2 {
        actions = {
            do_nothing;
            action_2;
        }
        key = {
            meta.meta.y: ternary;
            meta.meta.z: exact;
            meta.meta.e: exact;
            meta.meta.f: exact;
        }
        size = 512;
    }
    apply {
        if (hdr.hdr0.isValid()) {
            table_i0.apply();
        }
        else {
            table_i1.apply();
        }
        if (meta.meta.c == 2w0) {
            table_i2.apply();
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.hdr0);
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

