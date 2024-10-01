#include <tna.p4>

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

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

struct headers {
    data_t data;
}

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("IngressP.set_port_act") action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.setb1") action setb1(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb1") action setb1_6(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb1") action setb1_7(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb1") action setb1_8(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb1") action setb1_9(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb1") action setb1_10(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("IngressP.setb2") action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name("IngressP.setb2") action setb2_2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name("IngressP.noop") action noop() {
    }
    @name("IngressP.noop") action noop_3() {
    }
    @name("IngressP.noop") action noop_4() {
    }
    @name("IngressP.df_act1") table df_act1_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1();
        }
        default_action = setb1(8w0x77);
    }
    @name("IngressP.df_act2") table df_act2_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_6();
            @default_only noop();
        }
        default_action = noop();
    }
    @name("IngressP.df_act3") table df_act3_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_7();
            @default_only setb2();
        }
        default_action = setb2(8w0x88);
    }
    @name("IngressP.df_act4") table df_act4_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_8();
        }
        const default_action = setb1_8(8w0x55);
    }
    @name("IngressP.df_act5") table df_act5_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_9();
            @default_only noop_3();
        }
        const default_action = noop_3();
    }
    @name("IngressP.df_act6") table df_act6_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_10();
            @default_only setb2_2();
        }
        const default_action = setb2_2(8w0x88);
    }
    @name("IngressP.set_port") table set_port_0 {
        actions = {
            set_port_act();
            noop_4();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_4();
    }
    apply {
        df_act1_0.apply();
        df_act2_0.apply();
        df_act3_0.apply();
        df_act4_0.apply();
        df_act5_0.apply();
        df_act6_0.apply();
        set_port_0.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act() {
        b.emit<data_t>(hdr.data);
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

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    @hidden action act_0() {
        b.emit<data_t>(hdr.data);
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

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
