#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

header_type m1_t {
    fields {
        f1  : 1;
        f2  : 1;
        f3  : 1;
        f4  : 1;
        f5  : 1;
        f6  : 1;
        f7  : 1;
        f8  : 1;
        f9  : 1;
        f10 : 1;
        f11 : 1;
        f12 : 1;
        f13 : 1;
        f14 : 1;
        f15 : 1;
        f16 : 1;
    }
}

metadata m1_t m1;

parser start {
    extract(ethernet);
    return ingress;
}

action a1() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f1);      \
}

action a2() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f2);      \
}

action a3() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f3);      \
}

action a4() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f4);      \
}

action a5() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f5);      \
}

action a6() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f6);      \
}

action a7() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f7);      \
}

action a8() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f8);      \
}

action a9() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f9);      \
}

action a10() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f10);      \
}

action a11() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f11);      \
}

action a12() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f12);      \
}

action a13() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f13);      \
}

action a14() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f14);      \
}

action a15() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f15);      \
}

action a16() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f16);      \
}


table t1 {
    reads {
       ethernet.dstAddr : exact;
    }
    actions {
        a1;
        a2;
        a3;
        a4;
        a5;
        a6;
        a7;
        a8;
        a9;
        a10;
        a11;
        a12;
        a13;
        a14;
        a15;
        a16;
    }
}

control ingress {
    apply(t1);
}

control egress {
}
