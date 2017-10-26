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
    @name("setb2") action setb2_0(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name("noop") action noop_0() {
    }
    @name("df_act1") table df_act1_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
        }
        default_action = setb1_0(8w0x77);
    }
    @name("df_act2") table df_act2_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
            @default_only noop_0();
        }
        default_action = noop_0();
    }
    @name("df_act3") table df_act3_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
            @default_only setb2_0();
        }
        default_action = setb2_0(8w0x88);
    }
    @name("df_act4") table df_act4_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
        }
        const default_action = setb1_0(8w0x55);
    }
    @name("df_act5") table df_act5_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
            @default_only noop_0();
        }
        const default_action = noop_0();
    }
    @name("df_act6") table df_act6_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
            @default_only setb2_0();
        }
        const default_action = setb2_0(8w0x88);
    }
    @name("set_port") table set_port_0 {
        actions = {
            set_port_act_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
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

control DeparserI(packet_out b, in headers hdr, in metadata meta) {
    apply {
        b.emit<data_t>(hdr.data);
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
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;
