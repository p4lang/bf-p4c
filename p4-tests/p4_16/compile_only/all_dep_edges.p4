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
    action set_port(bit<9> port) {
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
            hdr.data.b1: exact;
        }
        default_action = noop;
    }

    action t3_act(bit<8> b3) {
        hdr.data.b3 = b3;
    }

    table t3 {
        actions = { t3_act;
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

    apply {
        //////////////////////////////////////////////
        // IXBAR_READ - Table Read After Action Write
        //////////////////////////////////////////////
        t1.apply();
        // Table Read - hdr.data.h1
        // Action: t1_act
        //  Read - imm, Write - hdr.data.b1
        t2.apply();
        // Table Read - hdr.data.b1
        // Action: t2_act
        //  Read - imm, Write - hdr.data.b2
        // Edges -
        //  t1 -> IXBAR_READ -> t2 : Fields - hdr.data.b1
        //  t1 -> ANTI       -> t2 : Fields - hdr.data.b1
        ////////////////

        //////////////////////////////////////////////
        // ACTION_READ = Action Read After Action Write
        //////////////////////////////////////////////
        t3.apply();
        // Table Read - hdr.data.h3
        // Action: t3_act
        //  Read - imm, Write - hdr.data.b3
        t4.apply();
        // Table Read - hdr.data.h4
        // Action: t4_act
        //  Read - hdr.data.b3, Write - hdr.data.b4
        // Edges -
        // t4 -> ACTION_READ -> t5 : Fields - hdr.data.b3
        // t4 -> ANTI        -> t5 : Fields - hdr.data.b3

        //////////////////////////////////////////////
        // OUTPUT = Action Write After Action Write
        //////////////////////////////////////////////
        t5.apply();
        // Table Read - hdr.data.h5
        // Action: t5_act
        //  Read - imm, Write - hdr.data.b5
        t6.apply();
        // Table Read - hdr.data.h6
        // Action: t6_act
        //  Read - imm, Write - hdr.data.b5
        // Edges -
        // t5 -> ACTION_READ -> t6 : Fields - hdr.data.b5
        // t5 -> ANTI        -> t6 : Fields - hdr.data.b5

        ////////////////////////////////////////
        // ANTI = Action Write After Table Read
        ////////////////////////////////////////
        t7.apply();
        // Table Read - hdr.data.h7
        // Action: t7_act
        //  Read - imm, Write - hdr.data.b7
        t8.apply();
        // Table Read - hdr.data.h8
        // Action: t8_act
        //  Read - imm, Write - hdr.data.h7
        // Edges -
        // t7 -> ANTI_TABLE_READ -> t8 : Fields - hdr.data.h7


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

    action noop() {}

    action t9_act() {
        hdr.data.b9 = hdr.data.b10;
    }

    table t9 {
        actions = { t9_act;
                    noop; }
        key = { hdr.data.h9: exact; }
        default_action = noop;
    }

    action t10_act(bit<8> b10) {
        hdr.data.b10 = b10;
    }

    table t10 {
        actions = { t10_act;
                    noop; }
        key = { hdr.data.h10: exact; }
        default_action = noop;
    }

    action t11_act(bit<8> b11) {
        hdr.data.b11 = b11;
    }

    table t11 {
        actions = { t11_act;
                    noop; }
        key = { hdr.data.h11: exact; }
        default_action = noop;
    }

    action t12_act(bit<8> b12) {
        hdr.data.b12 = b12;
    }

    table t12 {
        actions = { t12_act;
                    noop; }
        key = { hdr.data.h12: exact; }
        default_action = noop;
    }

    action t13_act(bit<8> b13) {
        hdr.data.b13 = b13;
    }

    table t13 {
        actions = { t13_act;
                    noop; }
        key = { hdr.data.h13: exact; }
        default_action = noop;
    }

    action t14_act(bit<8> b14) {
        hdr.data.b14 = hdr.data.b12;
    }

    table t14 {
        actions = { t14_act;
                    noop; }
        key = { hdr.data.h14: exact; }
        default_action = noop;
    }

    action t15_act(bit<8> b15) {
        hdr.data.b15 = b15;
    }

    table t15 {
        actions = { t15_act;
                    noop; }
        key = { hdr.data.h15: exact; }
        default_action = noop;
    }

    action t16_act(bit<8> b16) {
        hdr.data.b16 = b16;
    }

    table t16 {
        actions = { t16_act;
                    noop; }
        key = { hdr.data.h16: exact; }
        default_action = noop;
    }

    action t17_act(bit<8> b17) {
        hdr.data.b17 = b17;
    }

    table t17 {
        actions = { t17_act;
                    noop; }
        key = { hdr.data.h17: exact; }
        default_action = noop;
    }

    action t18_act(bit<8> b18) {
        hdr.data.b18 = b18;
    }

    table t18 {
        actions = { t18_act;
                    noop; }
        key = { hdr.data.h18: exact; }
        default_action = noop;
    }

    action t19_act() {
        exit;
    }

    action t19_act2() {
        exit;
    }

    table t19 {
        actions = { t19_act;
                    t19_act2;
                    noop; }
        key = { hdr.data.h19: exact; }
        default_action = noop;
    }

    action t20_act(bit<8> b20) {
        hdr.data.b20 = b20;
    }

    table t20 {
        actions = { t20_act;
                    noop; }
        key = { hdr.data.h20: exact; }
        default_action = noop;
    }

    action t21_act(bit<8> b21) {
        hdr.data.b21 = b21;
    }

    table t21 {
        actions = { t21_act;
                    noop; }
        key = { meta.m21 : exact; }
        default_action = noop;
    }

    action t22_act(bit<8> b22) {
        meta.m21 = b22;
    }

    table t22 {
        actions = { t22_act;
                    noop; }
        key = { hdr.data.h22: exact; }
        default_action = noop;
    }

    apply { 
    
        ////////////////////////////////////////
        // ANTI = Action Write After Action Read
        ////////////////////////////////////////
        t9.apply();
        // Table Read - hdr.data.h9
        // Action: t9_act
        //  Read - hdr.data.b10, Write - hdr.data.b9
        t10.apply();
        // Table Read - hdr.data.h10
        // Action: t10_act
        //  Read - imm , Write - hdr.data.b10
        // Edges -
        // t9 -> ANTI        -> t10 : Fields - hdr.data.b10

        ////////////////////////////////////////
        // ANTI = Next Table Data
        ////////////////////////////////////////
        if (t11.apply().hit) {
            t12.apply();
            // Table Read - hdr.data.h12
            // Action: t12_act
            //  Read - imm, Write - hdr.data.b12
        }
        if (t13.apply().hit) {
            t14.apply();
            // Table Read - hdr.data.h14
            // Action: t14_act
            //  Read - hdr.data.b12, Write - hdr.data.b14
        }
        // Edges -
        // t11 -> CONTROL     -> t12
        // t13 -> CONTROL     -> t14
        // t12 -> ACTION_READ -> t14 : Fields - hdr.data.b12
        // t12 -> ANTI        -> t13 : Fields - hdr.data.b12

        ////////////////////////////////////////
        // ANTI = Next Table Control
        ////////////////////////////////////////
        switch (t15.apply().action_run) {
            default: {
                if (hdr.data.b15 == 0) {
                    t16.apply();
                    switch (t17.apply().action_run) {
                        noop : {
                            t18.apply();
                        }
                    }
                }
            }
            t15_act : {
                t18.apply();
            }
        }
        // Edges -
        // t16 -> ANTI_NEXT_TABLE_CONTROL -> t17 (Before table placement)

        ////////////////////////////////////////
        // ANTI = Exit action
        ////////////////////////////////////////
        if (hdr.data.h19 == 0)
            t19.apply();
            // Action : t18_act has exit
        t20.apply();
        // t19 -> ANTI        -> t20 : Exit Action Name - t19_act
        // Explanation: t18 must be placed before t19 due to exit action in t18
        // which should not run t19 even if there is no dependency
    
    
        // ////////////////////////////////////////
        // // ANTI = Next Table Metadata Field  
        // ////////////////////////////////////////
        // t21.apply();
        // // Table Read - hdr.data.h12
        // // Action: t21_act
        // //  Read - imm, Write - hdr.data.b12
        // t22.apply();
        // // t19 -> ANTI        -> t20 : Exit Action Name - t19_act
    
    }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
