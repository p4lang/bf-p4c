#include <core.p4>
#include <tofino.p4>

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

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("set_port_act") action set_port_act_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("setb1") action setb1_0(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb1") action setb1_6(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb1") action setb1_7(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb1") action setb1_8(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb1") action setb1_9(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb1") action setb1_10(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name("setb2") action setb2_0(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name("setb2") action setb2_2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name("noop") action noop_0() {
    }
    @name("noop") action noop_3() {
    }
    @name("noop") action noop_4() {
    }
    @name("df_act1") table df_act1 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
        }
        default_action = setb1_0(8w0x77);
    }
    @name("df_act2") table df_act2 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_6();
            @default_only noop_0();
        }
        default_action = noop_0();
    }
    @name("df_act3") table df_act3 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_7();
            @default_only setb2_0();
        }
        default_action = setb2_0(8w0x88);
    }
    @name("df_act4") table df_act4 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_8();
        }
        const default_action = setb1_8(8w0x55);
    }
    @name("df_act5") table df_act5 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_9();
            @default_only noop_3();
        }
        const default_action = noop_3();
    }
    @name("df_act6") table df_act6 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_10();
            @default_only setb2_2();
        }
        const default_action = setb2_2(8w0x88);
    }
    @name("set_port") table set_port {
        actions = {
            set_port_act_0();
            noop_4();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_4();
    }
    apply {
        df_act1.apply();
        df_act2.apply();
        df_act3.apply();
        df_act4.apply();
        df_act5.apply();
        df_act6.apply();
        set_port.apply();
    }
}

control DeparserI(packet_out b, in headers hdr, in metadata meta) {
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

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply {
    }
}

control DeparserE(packet_out b, in headers hdr, in metadata meta) {
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

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;
