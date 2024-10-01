#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply {
        if (hdr.data.f1[2:2] == 1 && hdr.data.f1[8:8] == 1 && hdr.data.f1[20:20] == 1 &&
            hdr.data.f1[27:27] == 1 && hdr.data.f2[4:4] == 1) {
            ig_intr_tm_md.ucast_egress_port = 2;
        } else {
            ig_intr_tm_md.ucast_egress_port = 4;
        }
    }
}

#include "common_tna_test.h"
