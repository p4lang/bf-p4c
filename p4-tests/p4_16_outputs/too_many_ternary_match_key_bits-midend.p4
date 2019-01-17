#include <core.p4>
#include <tofino.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

header data_h {
    bit<128> f1;
    bit<128> f2;
    bit<128> f3;
    bit<128> f4;
}

struct metadata {
    bit<32> w1;
    bit<16> h1;
    bit<8>  b1;
}

struct packet_t {
    data_h data;
}

parser parserI(packet_in b, out packet_t hdrs, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        b.extract<data_h>(hdrs.data);
        meta.w1 = 32w1234;
        meta.h1 = 16w24;
        meta.b1 = 8w9;
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("ingress.setb1") action setb1(bit<9> port, bit<128> val) {
        hdrs.data.f1 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("ingress.noop") action noop() {
    }
    @name("ingress.test1") table test1_0 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
            hdrs.data.f3: ternary @name("hdrs.data.f3") ;
            hdrs.data.f4: ternary @name("hdrs.data.f4") ;
            meta.w1     : ternary @name("meta.w1") ;
            meta.h1     : ternary @name("meta.h1") ;
            meta.b1     : ternary @name("meta.b1") ;
        }
        actions = {
            setb1();
            noop();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    apply {
        test1_0.apply();
    }
}

control deparserI(packet_out b, inout packet_t hdrs, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act() {
        b.emit<data_h>(hdrs.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

parser parserE(packet_in b, out packet_t hdrs, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        b.extract<data_h>(hdrs.data);
        transition accept;
    }
}

control egress(inout packet_t hdrs, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control deparserE(packet_out b, inout packet_t hdrs, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    @hidden action act_0() {
        b.emit<data_h>(hdrs.data);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

Pipeline<packet_t, metadata, packet_t, metadata>(parserI(), ingress(), deparserI(), parserE(), egress(), deparserE()) pipe0;

Switch<packet_t, metadata, packet_t, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

