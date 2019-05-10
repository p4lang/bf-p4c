#include <core.p4>
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


parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr,
                 inout metadata meta,
                 in ingress_intrinsic_metadata_t ig_intr_md,
                 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action setb1(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }

    action noop() {

    }

    table df_act1 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1; }
        default_action = setb1(0x77);
    }

    table df_act2 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1;
                    @defaultonly noop; }
        default_action = noop;
    }

    table df_act3 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1;
                    @defaultonly setb2; }
        default_action = setb2(0x88);
    }

    table df_act4 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1; }
        const default_action = setb1(0x55);
    }

    table df_act5 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1;
                    @defaultonly noop; }
        const default_action = noop;
    }

    table df_act6 {
        key = { hdr.data.f1 : exact; }
        actions = { setb1;
                    @defaultonly setb2; }
        const default_action = setb2(0x88);
    }

    table set_port {
        actions = { set_port_act;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
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

control DeparserI(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr,
                inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
