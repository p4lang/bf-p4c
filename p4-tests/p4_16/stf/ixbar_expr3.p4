#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act1() {
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.f1 = hdr.data.b1 ++ hdr.data.h1 ++ hdr.data.b2;
    }
    action act2() {
        hdr.data.h1 = (bit<16>)((int<16>)hdr.data.h1 + (int<16>)(int<8>)hdr.data.b1);
    }
    apply {
        act1();
        act2();
    }
}

#include "common_tna_test.h"
