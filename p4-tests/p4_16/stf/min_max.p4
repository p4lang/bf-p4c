#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    int<8>  b1;
    int<8>  b2;
    int<8>  b3;
    int<8>  b4;
    int<8>  b5;
    int<8>  b6;
}


struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.f1 = min(hdr.data.f2, hdr.data.f3);
        hdr.data.h1 = max(hdr.data.h2, hdr.data.h3);
        hdr.data.b1 = min(hdr.data.b2, hdr.data.b3);
        hdr.data.b4 = max(hdr.data.b5, hdr.data.b6);
    }
}

#include "common_tna_test.h"
