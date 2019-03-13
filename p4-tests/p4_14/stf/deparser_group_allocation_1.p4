#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

/** This test forces PHV allocation to assign non-deparsed INGRESS fields to
 * containers in the same deparser groups as deparsed EGRESS fields.
 *
 * It does this by filling 9 containers in each MAU group with non-packable
 * header fields joined by arithmetic operations in the EGRESS pipeline (each
 * MAU group contains two deparser groups of 8 containers each), and then
 * allocating INGRESS metadata.  One MAU group of each size is hardwired to
 * INGRESS and therefore excluded from header manipulation.  Similarly, one MAU
 * group of each size is hardwired to EGRESS; the amount of metadata is
 * adjusted accordingly.
 *
 * Ingress intrinsic metadata requires 141 bits, accounting for no_pack
 * constraints.  Hence, we reserve 2x32b, 2x16b, and 6x8b containers for them.
 *
 * Egress intrinsic metadata requires 4x8b and 1x16b containers.  ("Containers"
 * because even without no_pack constraints, no other metadata exists in the
 * egress pipeline to pack with egress intrinsic metadata.)  However, these can
 * be allocated in the EGRESS-only MAU groups.
 */

header_type header_b_t {
    fields {
        // 3x8b groups (4 total, with one hardwired to INGRESS)
        field_0_b1 : 8;
        field_0_b2 : 8;
        field_0_b3 : 8;
        field_0_b4 : 8;
        field_0_b5 : 8;
        field_0_b6 : 8;
        field_0_b7 : 8;
        field_0_b8 : 8;
        field_0_b9 : 8;

        field_1_b1 : 8;
        field_1_b2 : 8;
        field_1_b3 : 8;
        field_1_b4 : 8;
        field_1_b5 : 8;
        field_1_b6 : 8;
        field_1_b7 : 8;
        field_1_b8 : 8;
        field_1_b9 : 8;

        field_2_b1 : 8;
        field_2_b2 : 8;
        field_2_b3 : 8;
        field_2_b4 : 8;
        field_2_b5 : 8;
        field_2_b6 : 8;
        field_2_b7 : 8;
        field_2_b8 : 8;
        field_2_b9 : 8;
    }
}

header_type header_h_t {
    fields {
        // 5x16b groups (6 total, with one hardwired to INGRESS)
        field_0_h1 : 16;
        field_0_h2 : 16;
        field_0_h3 : 16;
        field_0_h4 : 16;
        field_0_h5 : 16;
        field_0_h6 : 16;
        field_0_h7 : 16;
        field_0_h8 : 16;
        field_0_h9 : 16;

        field_1_h1 : 16;
        field_1_h2 : 16;
        field_1_h3 : 16;
        field_1_h4 : 16;
        field_1_h5 : 16;
        field_1_h6 : 16;
        field_1_h7 : 16;
        field_1_h8 : 16;
        field_1_h9 : 16;

        field_2_h1 : 16;
        field_2_h2 : 16;
        field_2_h3 : 16;
        field_2_h4 : 16;
        field_2_h5 : 16;
        field_2_h6 : 16;
        field_2_h7 : 16;
        field_2_h8 : 16;
        field_2_h9 : 16;

        field_3_h1 : 16;
        field_3_h2 : 16;
        field_3_h3 : 16;
        field_3_h4 : 16;
        field_3_h5 : 16;
        field_3_h6 : 16;
        field_3_h7 : 16;
        field_3_h8 : 16;
        field_3_h9 : 16;

        field_4_h1 : 16;
        field_4_h2 : 16;
        field_4_h3 : 16;
        field_4_h4 : 16;
        field_4_h5 : 16;
        field_4_h6 : 16;
        field_4_h7 : 16;
        field_4_h8 : 16;
        field_4_h9 : 16;
    }
}

header_type header_w_t {
    fields {
        // 3x32b groups (4 total, with one hardwired to INGRESS)
        field_0_w1 : 32;
        field_0_w2 : 32;
        field_0_w3 : 32;
        field_0_w4 : 32;
        field_0_w5 : 32;
        field_0_w6 : 32;
        field_0_w7 : 32;
        field_0_w8 : 32;
        field_0_w9 : 32;

        field_1_w1 : 32;
        field_1_w2 : 32;
        field_1_w3 : 32;
        field_1_w4 : 32;
        field_1_w5 : 32;
        field_1_w6 : 32;
        field_1_w7 : 32;
        field_1_w8 : 32;
        field_1_w9 : 32;

        field_2_w1 : 32;
        field_2_w2 : 32;
        field_2_w3 : 32;
        field_2_w4 : 32;
        field_2_w5 : 32;
        field_2_w6 : 32;
        field_2_w7 : 32;
        field_2_w8 : 32;
        field_2_w9 : 32;
    }
}

header header_b_t hb;
header header_h_t hh;
header header_w_t hw;

header_type m_t {
    fields {
        // 1 INGRESS group + 7 containers each in 2 INGRESS/EGRESS groups = 30
        // containers - 6 for intrinsic metadata = 24.
        field_8_01  : 8;
        field_8_02  : 8;
        field_8_03  : 8;
        field_8_04  : 8;
        field_8_05  : 8;
        field_8_06  : 8;
        field_8_07  : 8;
        field_8_08  : 8;
        field_8_09  : 8;
        field_8_10  : 8;
        field_8_11  : 8;
        field_8_12  : 8;
        field_8_13  : 8;
        field_8_14  : 8;
        field_8_15  : 8;
        field_8_16  : 8;
        field_8_17  : 8;
        field_8_18  : 8;
        field_8_19  : 8;
        field_8_20  : 8;
        field_8_21  : 8;
        field_8_22  : 8;
        field_8_23  : 8;
        field_8_24  : 8;

        // 1 INGRESS group + 7 containers each in 4 INGRESS/EGRESS groups = 44
        // containers - 4 for intrinsic metadata = 40.
        field_16_01  : 16;
        field_16_02  : 16;
        field_16_03  : 16;
        field_16_04  : 16;
        field_16_05  : 16;
        field_16_06  : 16;
        field_16_07  : 16;
        field_16_08  : 16;
        field_16_09  : 16;
        field_16_10  : 16;
        field_16_11  : 16;
        field_16_12  : 16;
        field_16_13  : 16;
        field_16_14  : 16;
        field_16_15  : 16;
        field_16_16  : 16;
        field_16_17  : 16;
        field_16_18  : 16;
        field_16_19  : 16;
        field_16_20  : 16;
        field_16_21  : 16;
        field_16_22  : 16;
        field_16_23  : 16;
        field_16_24  : 16;
        field_16_25  : 16;
        field_16_26  : 16;
        field_16_27  : 16;
        field_16_28  : 16;
        field_16_29  : 16;
        field_16_30  : 16;
        field_16_31  : 16;
        field_16_32  : 16;
        field_16_33  : 16;
        field_16_34  : 16;
        field_16_35  : 16;
        field_16_36  : 16;
        field_16_37  : 16;
        field_16_38  : 16;
        field_16_39  : 16;
        field_16_40  : 16;

        // 1 INGRESS group + 7 containers each in 2 INGRESS/EGRESS groups = 30
        // containers - 2 for intrinsic metadata = 28.
        field_32_01  : 32;
        field_32_02  : 32;
        field_32_03  : 32;
        field_32_04  : 32;
        field_32_05  : 32;
        field_32_06  : 32;
        field_32_07  : 32;
        field_32_08  : 32;
        field_32_09  : 32;
        field_32_10  : 32;
        field_32_11  : 32;
        field_32_12  : 32;
        field_32_13  : 32;
        field_32_14  : 32;
        field_32_15  : 32;
        field_32_16  : 32;
        field_32_17  : 32;
        field_32_18  : 32;
        field_32_19  : 32;
        field_32_20  : 32;
        field_32_21  : 32;
        field_32_22  : 32;
        field_32_23  : 32;
        field_32_24  : 32;
        field_32_25  : 32;
        field_32_26  : 32;
        field_32_27  : 32;
        field_32_28  : 32;
    }
}

metadata m_t m;

parser start {
    extract(hb);
    extract(hh);
    extract(hw);
    return ingress;
}

action a1() {
}

table t1 {
    reads {
        m.field_8_01 : exact;
        m.field_8_02 : exact;
        m.field_8_03 : exact;
        m.field_8_04 : exact;
        m.field_8_05 : exact;
        m.field_8_06 : exact;
        m.field_8_07 : exact;
        m.field_8_08 : exact;
        m.field_8_09 : exact;
        m.field_8_10 : exact;
        m.field_8_11 : exact;
        m.field_8_12 : exact;
        m.field_8_13 : exact;
        m.field_8_14 : exact;
        m.field_8_15 : exact;
        m.field_8_16 : exact;
        m.field_8_17 : exact;
        m.field_8_18 : exact;
        m.field_8_19 : exact;
        m.field_8_20 : exact;
        m.field_8_21 : exact;
        m.field_8_22 : exact;
        m.field_8_23 : exact;
        m.field_8_24 : exact;
    }
    actions {
        a1;
    }
}

action a2() {
}

table t2 {
    reads {
        m.field_16_01 : exact;
        m.field_16_02 : exact;
        m.field_16_03 : exact;
        m.field_16_04 : exact;
        m.field_16_05 : exact;
        m.field_16_06 : exact;
        m.field_16_07 : exact;
        m.field_16_08 : exact;
        m.field_16_09 : exact;
        m.field_16_10 : exact;
        m.field_16_11 : exact;
        m.field_16_12 : exact;
        m.field_16_13 : exact;
        m.field_16_14 : exact;
        m.field_16_15 : exact;
        m.field_16_16 : exact;
        m.field_16_17 : exact;
        m.field_16_18 : exact;
        m.field_16_19 : exact;
        m.field_16_20 : exact;
        m.field_16_21 : exact;
        m.field_16_22 : exact;
        m.field_16_23 : exact;
        m.field_16_24 : exact;
        m.field_16_25 : exact;
        m.field_16_26 : exact;
        m.field_16_27 : exact;
        m.field_16_28 : exact;
        m.field_16_29 : exact;
        m.field_16_30 : exact;
        m.field_16_31 : exact;
        m.field_16_32 : exact;
    }
    actions {
        a2;
    }
}

action a3() {
}

table t3 {
    reads {
        m.field_16_33 : exact;
        m.field_16_34 : exact;
        m.field_16_35 : exact;
        m.field_16_36 : exact;
        m.field_16_37 : exact;
        m.field_16_38 : exact;
        m.field_16_39 : exact;
        m.field_16_40 : exact;
    }
    actions {
        a3;
    }
}

action a4() {
}

table t4 {
    reads {
        m.field_32_01 : exact;
        m.field_32_02 : exact;
        m.field_32_03 : exact;
        m.field_32_04 : exact;
        m.field_32_05 : exact;
        m.field_32_06 : exact;
        m.field_32_07 : exact;
        m.field_32_08 : exact;
        m.field_32_09 : exact;
        m.field_32_10 : exact;
        m.field_32_11 : exact;
        m.field_32_12 : exact;
        m.field_32_13 : exact;
        m.field_32_14 : exact;
        m.field_32_15 : exact;
        m.field_32_16 : exact;
        m.field_32_17 : exact;
        m.field_32_18 : exact;
        m.field_32_19 : exact;
        m.field_32_20 : exact;
        m.field_32_21 : exact;
        m.field_32_22 : exact;
        m.field_32_23 : exact;
        m.field_32_24 : exact;
        m.field_32_25 : exact;
        m.field_32_26 : exact;
        m.field_32_27 : exact;
        m.field_32_28 : exact;
    }
    actions {
        a4;
    }
}

action fwd() { modify_field(ig_intr_md_for_tm.ucast_egress_port, 2); }
table forward {
    reads { hb.field_1_b1 : exact; }
    actions { fwd; }
    default_action: fwd();
}

action write_b0() {
    add(hb.field_0_b1, hb.field_0_b2, hb.field_0_b3);
    add(hb.field_0_b3, hb.field_0_b4, hb.field_0_b5);
    add(hb.field_0_b5, hb.field_0_b6, hb.field_0_b7);
    add(hb.field_0_b7, hb.field_0_b8, hb.field_0_b9);
}
table tb0 {
    reads { hb.field_0_b1 : exact; }
    actions { write_b0; }
    default_action: write_b0();
}

action write_b1() {
    add(hb.field_1_b1, hb.field_1_b2, hb.field_1_b3);
    add(hb.field_1_b3, hb.field_1_b4, hb.field_1_b5);
    add(hb.field_1_b5, hb.field_1_b6, hb.field_1_b7);
    add(hb.field_1_b7, hb.field_1_b8, hb.field_1_b9);
}
table tb1 {
    reads { hb.field_1_b1 : exact; }
    actions { write_b1; }
    default_action: write_b1();
}

action write_b2() {
    add(hb.field_2_b1, hb.field_2_b2, hb.field_2_b3);
    add(hb.field_2_b3, hb.field_2_b4, hb.field_2_b5);
    add(hb.field_2_b5, hb.field_2_b6, hb.field_2_b7);
    add(hb.field_2_b7, hb.field_2_b8, hb.field_2_b9);
}
table tb2 {
    reads { hb.field_2_b1 : exact; }
    actions { write_b2; }
    default_action: write_b2();
}

action write_h0() {
    add(hh.field_0_h1, hh.field_0_h2, hh.field_0_h3);
    add(hh.field_0_h3, hh.field_0_h4, hh.field_0_h5);
    add(hh.field_0_h5, hh.field_0_h6, hh.field_0_h7);
    add(hh.field_0_h7, hh.field_0_h8, hh.field_0_h9);
}
table th0 {
    reads { hh.field_0_h1 : exact; }
    actions { write_h0; }
    default_action: write_h0();
}

action write_h1() {
    add(hh.field_1_h1, hh.field_1_h2, hh.field_1_h3);
    add(hh.field_1_h3, hh.field_1_h4, hh.field_1_h5);
    add(hh.field_1_h5, hh.field_1_h6, hh.field_1_h7);
    add(hh.field_1_h7, hh.field_1_h8, hh.field_1_h9);
}
table th1 {
    reads { hh.field_1_h1 : exact; }
    actions { write_h1; }
    default_action: write_h1();
}

action write_h2() {
    add(hh.field_2_h1, hh.field_2_h2, hh.field_2_h3);
    add(hh.field_2_h3, hh.field_2_h4, hh.field_2_h5);
    add(hh.field_2_h5, hh.field_2_h6, hh.field_2_h7);
    add(hh.field_2_h7, hh.field_2_h8, hh.field_2_h9);
}
table th2 {
    reads { hh.field_2_h1 : exact; }
    actions { write_h2; }
    default_action: write_h2();
}

action write_h3() {
    add(hh.field_3_h1, hh.field_3_h2, hh.field_3_h3);
    add(hh.field_3_h3, hh.field_3_h4, hh.field_3_h5);
    add(hh.field_3_h5, hh.field_3_h6, hh.field_3_h7);
    add(hh.field_3_h7, hh.field_3_h8, hh.field_3_h9);
}
table th3 {
    reads { hh.field_3_h1 : exact; }
    actions { write_h3; }
    default_action: write_h3();
}

action write_h4() {
    add(hh.field_4_h1, hh.field_4_h2, hh.field_4_h3);
    add(hh.field_4_h3, hh.field_4_h4, hh.field_4_h5);
    add(hh.field_4_h5, hh.field_4_h6, hh.field_4_h7);
    add(hh.field_4_h7, hh.field_4_h8, hh.field_4_h9);
}
table th4 {
    reads { hh.field_4_h1 : exact; }
    actions { write_h4; }
    default_action: write_h4();
}

action write_w0() {
    add(hw.field_0_w1, hw.field_0_w2, hw.field_0_w3);
    add(hw.field_0_w3, hw.field_0_w4, 0x1);

    add(hw.field_0_w5, hw.field_0_w6, hw.field_0_w7);
    add(hw.field_0_w7, hw.field_0_w8, hw.field_0_w9);
}
table tw0 {
    reads { hw.field_0_w1 : exact; }
    actions { write_w0; }
    default_action: write_w0();
}

action write_w1() {
    add(hw.field_1_w1, hw.field_1_w2, hw.field_1_w3);
    add(hw.field_1_w3, hw.field_1_w4, 0x1);

    add(hw.field_1_w5, hw.field_1_w6, hw.field_1_w7);
    add(hw.field_1_w7, hw.field_1_w8, hw.field_1_w9);
}
table tw1 {
    reads { hw.field_1_w1 : exact; }
    actions { write_w1; }
    default_action: write_w1();
}

action write_w2() {
    add(hw.field_2_w1, hw.field_2_w2, hw.field_2_w3);
    add(hw.field_2_w3, hw.field_2_w4, 0x1);

    add(hw.field_2_w5, hw.field_2_w6, hw.field_2_w7);
    add(hw.field_2_w7, hw.field_2_w8, hw.field_2_w9);
}
table tw2 {
    reads { hw.field_2_w1 : exact; }
    actions { write_w2; }
    default_action: write_w2();
}

control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
    apply(t4);
    apply(forward);
}

control egress {
    apply(tb0);
    apply(tb1);
    apply(tb2);
    apply(th0);
    apply(th1);
    apply(th2);
    apply(th3);
    apply(th4);
    apply(tw0);
    apply(tw1);
    apply(tw2);
}
