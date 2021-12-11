#include <tna.p4>

struct metadata { }


#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action s0() {
        hdr.data.f1[7:0] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }
    action s2() {
        hdr.data.f1[9:2] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }
    action s5() {
        hdr.data.f1[12:5] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }
    action s8() {
        hdr.data.f1[15:8] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }
    action s13() {
        hdr.data.f1[20:13] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }
    action s17() {
        hdr.data.f1[24:17] = hdr.data.b1;
        hdr.data.f2 = hdr.data.f1; }

    table t1 {
        actions = { s0; s2; s5; s8; s13; s17; }
        key = { hdr.data.h1: exact; }
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        t1.apply();
    }
}

#include "common_tna_test.h"
