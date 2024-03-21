#include <core.p4>
#include <tna.p4>

header data_t {
    bit<32> f1; 
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
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
        b.extract(ig_intr_md);
        b.advance(PORT_METADATA_SIZE);
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {



    action set_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table set_metadata {
        key = { hdr.data.f1 : ternary; }
        actions = { set_port; }
    }

    action nop() {}

    action act(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    table case1 {
        actions = { act; @defaultonly nop; }
        key = { hdr.data.f1 : exact; }
        
        const entries = {
            (0x10101010) : act(0x1);
            (0x20202020) : act(0x2);
            (0x30303030) : act(0x3);
            (0x40404040) : act(0x4);
        }
        size = 4;
        default_action = nop;
    }

    
    table case2 {
        actions = { act; nop; }
        key = { hdr.data.f1 : exact; }
        
        const entries = {
            (0x50505050) : act(0x5);
            (0x60606060) : nop; 
            (0x70707070) : act(0x7);
            (0x80808080) : nop; 
        }
        size = 4;
        default_action = nop;
    }

    action b2_a_act() { hdr.data.b2 = 0xa1; }

    table b2_a {
        actions = { b2_a_act; }
        const default_action = b2_a_act;
    }

    action b2_b_act() { hdr.data.b2 = 0x3c; }

    table b2_b {
        actions = { b2_b_act; }
        const default_action = b2_b_act;
    }

    action act1(bit<4> b1) {
        hdr.data.b1[3:0] = b1;
    }

    action act2(bit<4> b1) {
        hdr.data.b1[7:4] = b1;
    }

    table case3 {
        actions = { act1; act2; nop; }
        key = { hdr.data.f1: exact; }
        
        const entries = {
            (0x90909090) : act1(0x9);
            (0xa0a0a0a0) : act2(0xa);
            (0xb0b0b0b0) : nop;
            (0xc0c0c0c0) : act1(0xc);
        }
        size = 4;
        default_action = nop;
    }

    action b2_c_act() { hdr.data.b3 = 0xdd; }

    table b2_c {
        actions = { b2_c_act; }
        const default_action = b2_c_act;
    }

    action b2_d_act() { hdr.data.b3 = 0x11; }

    table b2_d {
        actions = { b2_d_act; }
        const default_action = b2_d_act;
    }

    action b2_e_act() { hdr.data.b3 = 0x33; }

    table b2_e {
        actions = { b2_e_act; }
        const default_action = b2_e_act;
    }

    apply {
        set_metadata.apply();
        case1.apply();
        if (case2.apply().hit) {
            b2_a.apply();
        } else {
            b2_b.apply();
        }

        switch (case3.apply().action_run) {
            act1 : { b2_c.apply();; }
            act2 : { b2_d.apply(); }
            nop : { b2_e.apply(); }
        }
    }
}

control DeparserI(
        packet_out b,
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
        b.extract(eg_intr_md);
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
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
