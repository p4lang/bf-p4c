#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif


#define DATA_T_OVERRIDE 1
header data_t {
    bit<16>     v0;
    bit<16>     v1;
    bit<16>     v2;
    bit<16>     v3;
    bit<16>     v4;
    bit<16>     v5;
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
        if (hdr.data.v0[0:0] == 1) {
            hdr.data.v2 = hdr.data.v2 + hdr.data.v1;
            hdr.data.v2 = hdr.data.v2 + hdr.data.v1;
            hdr.data.v2 = hdr.data.v2 + hdr.data.v1;
            hdr.data.v2 = hdr.data.v2 + hdr.data.v1;
            hdr.data.v2 = hdr.data.v2 + hdr.data.v1; }
        if (hdr.data.v0[1:1] == 1) {
            hdr.data.v3 = hdr.data.v3 + hdr.data.v1;
            hdr.data.v3 = hdr.data.v3 + hdr.data.v1;
            hdr.data.v3 = hdr.data.v3 + hdr.data.v1;
            hdr.data.v3 = hdr.data.v3 + hdr.data.v1;
            hdr.data.v3 = hdr.data.v3 + hdr.data.v1; }
    }
}

#include "common_tna_test.h"
