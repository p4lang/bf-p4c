#include <tna.p4>

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
}


struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply {
        if (hdr.data.f1 == hdr.data.f2 || hdr.data.f1 == hdr.data.f3) {
            ig_intr_tm_md.ucast_egress_port = 2;
        } else {
            ig_intr_tm_md.ucast_egress_port = 4;
        }
    }
}

#include "common_tna_test.h"
