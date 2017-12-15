#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<1>  a;
    bit<32> b;
    bit<3>  c;
    bit<4>  d;
    bit<1>  e;
    bit<16> f;
    bit<1>  g;
    bit<12> h;
    bit<14> i;
    bit<2>  j;
    bit<20> k;
    bit<6>  l;
    bit<32> m;
}

header hdr_0_t {
    bit<8>  a;
    bit<16> b;
    bit<32> c;
    bit<32> d;
    bit<8>  e;
    bit<16> f;
}

header hdr_1_t {
    bit<32> a;
    bit<32> b;
    bit<16> c;
    bit<8>  d;
    bit<8>  e;
    bit<16> f;
    bit<32> g;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".hdr_0") 
    hdr_0_t hdr_0;
    @name(".hdr_1") 
    hdr_1_t hdr_1;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_hdr_0") state parse_hdr_0 {
        packet.extract(hdr.hdr_0);
        transition parse_hdr_1;
    }
    @name(".parse_hdr_1") state parse_hdr_1 {
        packet.extract(hdr.hdr_1);
        transition accept;
    }
    @name(".start") state start {
        transition parse_hdr_0;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_e") action action_e(bit<32> p0) {
        hdr.hdr_1.d = hdr.hdr_0.a;
        hdr.hdr_1.g = p0;
    }
    @name(".table_e0") table table_e0 {
        actions = {
            action_e;
        }
        key = {
            meta.meta.e: exact;
            meta.meta.h: exact;
        }
        size = 4096;
    }
    apply {
        table_e0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_all") action set_all(bit<1> p0, bit<32> p1, bit<3> p2, bit<4> p3, bit<1> p4, bit<16> p5, bit<1> p6, bit<12> p7, bit<14> p8, bit<2> p9, bit<20> p10, bit<6> p11, bit<32> p12) {
        meta.meta.a = p0;
        meta.meta.b = p1;
        meta.meta.c = p2;
        meta.meta.d = p3;
        meta.meta.e = p4;
        meta.meta.f = p5;
        meta.meta.g = p6;
        meta.meta.h = p7;
        meta.meta.i = p8;
        meta.meta.j = p9;
        meta.meta.k = p10;
        meta.meta.l = p11;
        meta.meta.m = p12;
    }
    @name(".action_0") action action_0(bit<1> p0, bit<4> p1) {
        meta.meta.a = p0;
        meta.meta.f = 16w0;
        meta.meta.d = p1;
    }
    @name(".action_1") action action_1(bit<3> p0, bit<16> p1) {
        meta.meta.c = p0;
        meta.meta.e = 1w0;
        meta.meta.f = p1;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_2") action action_2(bit<20> p0) {
        meta.meta.e = meta.meta.a;
        meta.meta.k = p0;
        meta.meta.m = meta.meta.b;
        hdr.hdr_0.f = hdr.hdr_0.f ^ hdr.hdr_1.c;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            set_all;
            action_0;
        }
        key = {
            hdr.hdr_0.b: ternary;
        }
        size = 512;
    }
    @name(".table_i1") table table_i1 {
        actions = {
            action_1;
            do_nothing;
        }
        key = {
            hdr.hdr_1.c: ternary;
        }
        size = 512;
    }
    @name(".table_i2") table table_i2 {
        actions = {
            action_2;
            do_nothing;
        }
        key = {
            meta.meta.a: exact;
            meta.meta.b: exact;
            meta.meta.c: exact;
            meta.meta.d: exact;
            meta.meta.e: exact;
            meta.meta.f: exact;
            meta.meta.g: exact;
            meta.meta.h: exact;
            meta.meta.i: exact;
            meta.meta.j: exact;
            meta.meta.k: exact;
            meta.meta.l: exact;
            meta.meta.m: exact;
        }
        size = 1024;
    }
    apply {
        table_i0.apply();
        table_i1.apply();
        table_i2.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.hdr_0);
        packet.emit(hdr.hdr_1);
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

