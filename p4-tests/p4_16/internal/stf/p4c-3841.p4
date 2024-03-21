#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.data.f1[15:0] = (hdr.data.f1[15:0] <= hdr.data.f2[15:0]) ? hdr.data.f1[15:0] : hdr.data.f2[15:0];
    }
}

#include "common_tna_test.h"
