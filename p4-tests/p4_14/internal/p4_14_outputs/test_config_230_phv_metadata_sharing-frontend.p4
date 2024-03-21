#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<8> a_8;
    bit<2> b_2;
    bit<2> c_2;
    bit<4> d_4;
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
    @pa_container_size("ingress", "hdr0.b", 8) @name(".hdr0") 
    hdr0_t hdr0;
    @name(".hdr1") 
    hdr1_t hdr1;
    @name(".hdr2") 
    hdr2_t hdr2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        transition p_hdr1;
    }
    @name(".p_hdr1") state p_hdr1 {
        packet.extract<hdr1_t>(hdr.hdr1);
        transition p_hdr2;
    }
    @name(".p_hdr2") state p_hdr2 {
        packet.extract<hdr2_t>(hdr.hdr2);
        transition accept;
    }
    @name(".start") state start {
        transition p_hdr0;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".do_nothing") action do_nothing_2() {
    }
    @name(".action_0") action action_0() {
        meta.meta.a_8 = 8w255;
        meta.meta.b_2 = 2w1;
        meta.meta.c_2 = 2w3;
        meta.meta.d_4 = 4w15;
    }
    @name(".action_1") action action_1() {
        hdr.hdr2.c = meta.meta.a_8;
    }
    @name(".table_i0") table table_i0_0 {
        actions = {
            do_nothing();
            action_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.hdr0.a: ternary @name("hdr0.a") ;
        }
        size = 512;
        default_action = NoAction_0();
    }
    @name(".table_i1") table table_i1_0 {
        actions = {
            do_nothing_2();
            action_1();
            @defaultonly NoAction_3();
        }
        key = {
            meta.meta.a_8: ternary @name("meta.a_8") ;
            meta.meta.b_2: exact @name("meta.b_2") ;
            meta.meta.c_2: exact @name("meta.c_2") ;
            meta.meta.d_4: exact @name("meta.d_4") ;
        }
        size = 512;
        default_action = NoAction_3();
    }
    apply {
        table_i0_0.apply();
        table_i1_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
        packet.emit<hdr1_t>(hdr.hdr1);
        packet.emit<hdr2_t>(hdr.hdr2);
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

