#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act1() {
        ig_intr_tm_md.ucast_egress_port = 4;
        @in_hash { hdr.data.h1 = hdr.data.h1 + (bit<16>)hdr.data.b2; }
    }
    action act2() {
        @in_hash { hdr.data.f1 = hdr.data.f1 ^ (hdr.data.f2 & 0xff00ff); }
    }
    action act3() {
        @in_hash { hdr.data.f2 = hdr.data.f2 +
            (6w2 ++ hdr.data.h1[15:5] ++ 5w0 ++ hdr.data.b1[4:0] ++ 5w1); }
    }
    apply {
        act1();
        act2();
        act3();
    }
}

#include "common_tna_test.h"
