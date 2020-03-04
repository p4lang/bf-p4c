#include <core.p4>
#include <tna.p4>

header data_t {
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
    bit<16> h7;
    bit<16> h8;
    bit<16> h9;
    bit<16> h10;
    bit<16> h11;
    bit<16> h12;
    bit<16> h13;
    bit<16> h14;
    bit<16> h15;
    bit<16> h16;
    bit<16> h17;
    bit<16> h18;
    bit<16> h19;
    bit<16> h20;
    bit<16> h21;
    bit<16> h22;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<8>  b6;
    bit<8>  b7;
    bit<8>  b8;
    bit<8>  b9;
    bit<8>  b10;
    bit<8>  b11;
    bit<8>  b12;
    bit<8>  b13;
    bit<8>  b14;
    bit<8>  b15;
    bit<8>  b16;
    bit<8>  b17;
    bit<8>  b18;
    bit<8>  b19;
    bit<8>  b20;
    bit<8>  b21;
    bit<8>  b22;
}

struct metadata {
    bit<8> m21;
}

struct headers {
    data_t data;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
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
    action noop() {}
    action set_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table port_setter {
        actions = { set_port;
                    noop; }
        key = { hdr.data.h1 : exact;
                hdr.data.h2 : exact; }
        default_action = noop;
    }

    action t1_act(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    table t1 {
        actions = { t1_act;
                    noop; }
	key = { hdr.data.h1 : exact; }
        default_action = noop;
    }

    action t2_act(bit<8> b2) {
        hdr.data.b2 = b2;
    }

    table t2 {
        actions = { t2_act;
                    noop; }
        key = {
            hdr.data.h2: exact;
        }
        default_action = noop;
    }

    action t3_act1(bit<8> b3) {
        hdr.data.b3 = b3;
    }

    action t3_act2() {
        hdr.data.b3 = 0xFFFF;
    }

    table t3 {
        actions = { t3_act1;
                    t3_act2;
                    noop; }
        key = { hdr.data.h3: exact; }
        default_action = noop;
    }

    action t4_act() {
        hdr.data.b4 = hdr.data.b3;
    }

    table t4 {
        actions = { t4_act;
                    noop; }
        key = { hdr.data.h4: exact; }
        default_action = noop;
    }

    action t5_act(bit<8> b5) {
        hdr.data.b5 = b5;
    }

    table t5 {
        actions = { t5_act;
                    noop; }
        key = { hdr.data.h5: exact; }
        default_action = noop;
    }

    action t6_act(bit<8> b6) {
        hdr.data.b5 = b6;
    }

    table t6 {
        actions = { t6_act;
                    noop; }
        key = { hdr.data.h6: exact; }
        default_action = noop;
    }

    action t7_act(bit<8> b7) {
        hdr.data.b7 = b7;
    }

    table t7 {
        actions = { t7_act;
                    noop; }
        key = { hdr.data.h7: exact; }
        default_action = noop;
    }

    action t8_act(bit<16> h8) {
        hdr.data.h7 = h8;
    }

    table t8 {
        actions = { t8_act;
                    noop; }
        key = { hdr.data.h8: exact; }
        default_action = noop;
    }

    action t9_act() {
        hdr.data.b9 = hdr.data.b10;
    }

    table t9 {
        actions = { t9_act;
                    noop; }
        key = { hdr.data.h9: exact; }
        default_action = noop;
    }

    apply {
        //////////////////////////////////////////////
        // CONTROL - Condition True/ False / Default next table 
        //////////////////////////////////////////////
        if (hdr.data.h1 == 0)
            t1.apply();
        else if (hdr.data.h1 == 1)
            t2.apply();

        //////////////////////////////////////////////
        // CONTROL - Action / Default next table 
        //////////////////////////////////////////////
        switch (t3.apply().action_run) {
            t3_act1 : {
                t4.apply();
            }
            t3_act2 : {
                t5.apply();
            }
            default: {
                t6.apply();
            }
        }

        //////////////////////////////////////////////
        // CONTROL - Table Hit/Miss 
        //////////////////////////////////////////////
        if (t7.apply().hit) {
            t8.apply();
        } else {
            t9.apply();
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
