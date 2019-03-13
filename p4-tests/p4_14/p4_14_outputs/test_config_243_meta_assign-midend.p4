#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> w;
    bit<16> x;
    bit<16> y;
    bit<16> z;
}

header hdr0_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".hdr0") 
    hdr0_t hdr0;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        transition accept;
    }
    @name(".start") state start {
        transition p_hdr0;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_2") action action_0(bit<8> p) {
        hdr.hdr0.a = meta.meta.z;
    }
    @name(".table_e0") table table_e0_0 {
        actions = {
            do_nothing();
            action_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.meta.y: ternary @name("meta.y") ;
            meta.meta.z: exact @name("meta.z") ;
        }
        size = 512;
        default_action = NoAction_0();
    }
    apply {
        table_e0_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".do_nothing") action do_nothing_2() {
    }
    @name(".do_nothing") action do_nothing_4() {
    }
    @name(".action_0") action action_1(bit<8> p) {
        meta.meta.w = 16w1;
        meta.meta.x = 16w2;
    }
    @name(".action_1") action action_2(bit<8> p) {
        meta.meta.y = meta.meta.w + meta.meta.x;
        meta.meta.z = meta.meta.w ^ meta.meta.x;
    }
    @name(".table_i0") table table_i0_0 {
        actions = {
            do_nothing_2();
            action_1();
            @defaultonly NoAction_1();
        }
        key = {
            hdr.hdr0.a: ternary @name("hdr0.a") ;
        }
        size = 512;
        default_action = NoAction_1();
    }
    @name(".table_i1") table table_i1_0 {
        actions = {
            do_nothing_4();
            action_2();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.hdr0.a: ternary @name("hdr0.a") ;
        }
        size = 1024;
        default_action = NoAction_5();
    }
    apply {
        table_i0_0.apply();
        table_i1_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
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

